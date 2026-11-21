#!/usr/bin/env bash
# Publish locally built Mandalore images as one multi-arch image on the registry.
#
# Two phases:
#   1. push      run on each build machine, after `make <image>`. Pushes the local image to a temporary
#                per-arch tag (staging-<image>-<arch>) in the main repository. Public tags are not touched.
#   2. assemble  run once, from any machine, when every architecture has been pushed. Creates the multi-arch
#                index and points <image> and <image>-<version> to it in a single step.
#
# Why: GHCR cannot mount blobs across repositories, so per-arch images must be pushed in the main
# repository directly; and publishing all architectures at once avoids a new index digest per added
# architecture (which the wrapper would report as an update). The staging-* tags are ignored by the
# wrapper and are overwritten at each release.
#
# Requires: docker with buildx, python3, and `docker login ghcr.io` with a token having write:packages.

set -euo pipefail

REPO="${MANDALORE_REPO:-ghcr.io/ghecko/mandalore}"
ARCHS="${MANDALORE_ARCHS:-amd64 arm64}"
STAGING_PREFIX="staging"
ASSUME_YES=false
FORCE=false

info() { echo -e "\033[1;34m[*]\033[0m $*"; }
ok() { echo -e "\033[1;32m[+]\033[0m $*"; }
warn() { echo -e "\033[1;33m[!]\033[0m $*" >&2; }
die() { echo -e "\033[1;31m[-]\033[0m $*" >&2; exit 1; }

usage() {
  cat <<EOF
Usage: $0 [-y] [--force] [--arch "amd64 arm64"] <command> <image>

Commands:
  push <image>       Push the local ${REPO}:<image> to ${REPO}:${STAGING_PREFIX}-<image>-<arch>
  assemble <image>   Publish ${REPO}:<image> and ${REPO}:<image>-<version> from the staging tags
  status <image>     Show what is currently on the registry for <image>

Options:
  -y, --yes          Do not ask for confirmation
  --force            assemble: allow re-pointing an existing <image>-<version> tag
  --arch "LIST"      assemble: architectures to include (default: "${ARCHS}")

Environment:
  MANDALORE_REPO     Image repository (default: ghcr.io/ghecko/mandalore)
  MANDALORE_ARCHS    Default architecture list for assemble

Example (version comes from the VERSION used by make, stored in the image label):
  amd64 box:  make full VERSION=2.1.0 && ./publish.sh push full
  arm64 box:  make full VERSION=2.1.0 && ./publish.sh push full
  any box:    ./publish.sh assemble full
EOF
  exit "${1:-0}"
}

confirm() {
  $ASSUME_YES && return 0
  local answer
  read -r -p "$1 [y/N] " answer
  [[ "$answer" =~ ^[yY]$ ]] || die "Aborted."
}

staging_tag() { echo "${STAGING_PREFIX}-$1-$2"; }

# Print the digest of the linux/<arch> manifest behind a registry reference (index or single manifest).
# Prints nothing if the reference does not exist or has no such platform.
registry_digest() {
  local ref="$1" arch="$2" manifest
  manifest=$(docker buildx imagetools inspect "$ref" --format '{{json .Manifest}}' 2>/dev/null) || return 0
  python3 -I -c '
import json, sys
arch = sys.argv[1]
m = json.load(sys.stdin)
if "manifests" in m:
    for e in m["manifests"]:
        p = e.get("platform") or {}
        if p.get("os") == "linux" and p.get("architecture") == arch:
            print(e["digest"]); break
else:
    print(m.get("digest", ""))
' "$arch" <<<"$manifest"
}

# Print "<architecture> <org.mandalore.version> <org.mandalore.tag>" of a single-platform registry reference.
registry_labels() {
  docker buildx imagetools inspect "$1" --format '{{json .Image}}' | python3 -I -c '
import json, sys
c = json.load(sys.stdin)
labels = (c.get("config") or {}).get("Labels") or {}
print(c.get("architecture", "?"), labels.get("org.mandalore.version", "?"), labels.get("org.mandalore.tag", "?"))
'
}

# List the platforms of a registry reference, one "os/arch" per line (attestations excluded).
registry_platforms() {
  docker buildx imagetools inspect "$1" --format '{{json .Manifest}}' 2>/dev/null | python3 -I -c '
import json, sys
m = json.load(sys.stdin)
for e in m.get("manifests", []):
    p = e.get("platform") or {}
    if p.get("os") not in (None, "unknown"):
        print(p["os"] + "/" + p["architecture"])
' || true
}

cmd_push() {
  local image="$1" local_ref="${REPO}:$1"
  docker image inspect "$local_ref" >/dev/null 2>&1 || die "Local image ${local_ref} not found (build it first: make ${image})."

  local arch version tag
  arch=$(docker image inspect "$local_ref" --format '{{.Architecture}}')
  version=$(docker image inspect "$local_ref" --format '{{index .Config.Labels "org.mandalore.version"}}')
  tag=$(docker image inspect "$local_ref" --format '{{index .Config.Labels "org.mandalore.tag"}}')
  [[ -n "$version" && "$version" != "<no value>" ]] || die "${local_ref} has no org.mandalore.version label."
  [[ "$tag" == "$image" ]] || die "${local_ref} was built as '${tag}', not '${image}'."

  local staging_ref="${REPO}:$(staging_tag "$image" "$arch")"
  info "Local image: ${local_ref} (${arch}, version ${version})"
  info "Target:      ${staging_ref}"
  confirm "Push it?"

  docker tag "$local_ref" "$staging_ref"
  local rc=0
  docker push "$staging_ref" || rc=$?
  docker image rm "$staging_ref" >/dev/null 2>&1 || true  # only removes the temporary local tag
  [[ $rc -eq 0 ]] || die "Push failed (rc=${rc}). Check 'docker login ghcr.io' and the token scopes (write:packages), then retry."

  local digest pushed
  digest=$(registry_digest "$staging_ref" "$arch")
  [[ -n "$digest" ]] || die "Pushed, but no linux/${arch} manifest found behind ${staging_ref}."
  pushed=$(registry_labels "${REPO}@${digest}")
  [[ "$pushed" == "${arch} ${version} ${image}" ]] || die "Registry content mismatch: expected '${arch} ${version} ${image}', got '${pushed}'."
  ok "${image} ${version} (${arch}) staged: ${REPO}@${digest}"
}

cmd_assemble() {
  local image="$1" arch digest labels l_arch l_version l_tag version=""
  local -a sources=()

  for arch in $ARCHS; do
    local staging_ref="${REPO}:$(staging_tag "$image" "$arch")"
    digest=$(registry_digest "$staging_ref" "$arch")
    [[ -n "$digest" ]] || die "${staging_ref} not found on the registry (run './publish.sh push ${image}' on the ${arch} machine)."
    labels=$(registry_labels "${REPO}@${digest}")
    read -r l_arch l_version l_tag <<<"$labels"
    [[ "$l_arch" == "$arch" ]] || die "${staging_ref} is ${l_arch}, expected ${arch}."
    [[ "$l_tag" == "$image" ]] || die "${staging_ref} was built as '${l_tag}', not '${image}'."
    if [[ -z "$version" ]]; then
      version="$l_version"
    elif [[ "$l_version" != "$version" ]]; then
      die "Version mismatch between architectures: ${version} vs ${l_version} (${arch}). Rebuild with the same VERSION."
    fi
    info "${arch}: ${REPO}@${digest} (version ${l_version})"
    sources+=("${REPO}@${digest}")
  done

  local version_ref="${REPO}:${image}-${version}"
  if docker buildx imagetools inspect "$version_ref" >/dev/null 2>&1; then
    if $FORCE; then
      warn "${version_ref} already exists and will be re-pointed (users will see an update for an unchanged version)."
    else
      die "${version_ref} already exists. Bump VERSION and rebuild, or use --force."
    fi
  fi

  info "Will publish ${REPO}:${image} and ${version_ref} -> [${ARCHS}]"
  confirm "Publish?"
  docker buildx imagetools create -t "${REPO}:${image}" -t "$version_ref" "${sources[@]}"

  local platforms
  platforms=$(registry_platforms "${REPO}:${image}")
  for arch in $ARCHS; do
    grep -qx "linux/${arch}" <<<"$platforms" || die "linux/${arch} missing from ${REPO}:${image} after publish:"$'\n'"${platforms}"
  done
  ok "Published ${REPO}:${image} = ${version_ref} [$(echo $platforms)]"
}

cmd_status() {
  local image="$1" ref arch digest
  for ref in "${REPO}:${image}" $(for arch in $ARCHS; do echo "${REPO}:$(staging_tag "$image" "$arch")"; done); do
    echo "${ref}"
    for arch in $ARCHS; do
      digest=$(registry_digest "$ref" "$arch")
      if [[ -n "$digest" ]]; then
        echo "  linux/${arch}: ${digest} ($(registry_labels "${REPO}@${digest}" | cut -d' ' -f2))"
      fi
    done
  done
}

main() {
  local -a args=()
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -y|--yes) ASSUME_YES=true ;;
      --force) FORCE=true ;;
      --arch) shift; [[ $# -gt 0 ]] || usage 1; ARCHS="$1" ;;
      -h|--help) usage 0 ;;
      *) args+=("$1") ;;
    esac
    shift
  done
  [[ ${#args[@]} -eq 2 ]] || usage 1
  [[ "${args[1]}" =~ ^[a-z0-9]+$ ]] || die "Invalid image name: ${args[1]}"
  command -v python3 >/dev/null || die "python3 is required."
  docker buildx version >/dev/null 2>&1 || die "docker buildx is required."

  case "${args[0]}" in
    push) cmd_push "${args[1]}" ;;
    assemble) cmd_assemble "${args[1]}" ;;
    status) cmd_status "${args[1]}" ;;
    *) usage 1 ;;
  esac
}

main "$@"
