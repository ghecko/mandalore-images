#!/bin/bash
# Author: The Mandalore Project

# Functions and commands that will be retried multiple times to counter random network issues when building
CATCH_AND_RETRY_COMMANDS=("curl" "wget" "apt-fast" "git" "go" "apt-get" "nvm" "npm" "pip" "pipx" "pip2" "pip3" "cargo" "gem" "uv")

export RED='\033[1;31m'
export BLUE='\033[1;34m'
export GREEN='\033[1;32m'
export NOCOLOR='\033[0m'

### Echo functions

function colorecho () {
    echo -e "${BLUE}[MANDALORE] $*${NOCOLOR}"
}

function criticalecho () {
    echo -e "${RED}[MANDALORE ERROR] $*${NOCOLOR}" 2>&1
    exit 1
}

function criticalecho-noexit () {
    echo -e "${RED}[MANDALORE ERROR] $*${NOCOLOR}" 2>&1
}

### GitHub API helper

function gh_api() {
    # Wrapper around curl for api.github.com calls.
    # Injects Authorization header if GITHUB_TOKEN is set (raises rate-limit
    # from 60 req/h unauth to 5000 req/h auth).
    # Usage: gh_api "https://api.github.com/repos/..."  [extra curl args]
    #
    # SECURITY: the token is passed via a curl --config file (not -H on the
    # command line) so it never appears in catch_and_retry's '[MANDALORE DEBUG] $*'
    # echo, in shell history, or in process listings. The config file is created
    # with 0600 and removed immediately after the call.
    local cfg rc
    cfg=$(mktemp)
    chmod 600 "$cfg"
    {
        echo 'silent'
        echo 'location'
        echo 'header = "Accept: application/vnd.github+json"'
        echo 'header = "X-GitHub-Api-Version: 2022-11-28"'
        if [[ -n "${GITHUB_TOKEN:-}" ]]; then
            echo "header = \"Authorization: Bearer ${GITHUB_TOKEN}\""
        fi
    } > "$cfg"
    curl --config "$cfg" "$@"
    rc=$?
    rm -f "$cfg"
    return $rc
}

function gh_release_binary() {
    # Download the latest release asset of a GitHub repo matching the current
    # architecture and install it as an executable.
    # Usage: gh_release_binary <owner/repo> <asset-name-prefix> <destination>
    #   The asset must be named "<asset-name-prefix>-linux-<amd64|arm64>".
    local repo="$1" prefix="$2" dest="$3" arch tmp url
    case "$(uname -m)" in
        x86_64)  arch="amd64" ;;
        aarch64) arch="arm64" ;;
        *) criticalecho-noexit "gh_release_binary: unsupported architecture $(uname -m)"; return 1 ;;
    esac
    tmp=$(mktemp)
    gh_api "https://api.github.com/repos/${repo}/releases/latest" -o "$tmp"
    url=$(jq --raw-output --arg n "${prefix}-linux-${arch}" '.assets[] | select(.name == $n) | .browser_download_url' "$tmp")
    rm -f "$tmp"
    if [[ -z "$url" ]]; then
        criticalecho-noexit "gh_release_binary: no asset ${prefix}-linux-${arch} in ${repo} latest release"
        return 1
    fi
    curl -sSL --fail -o "$dest" "$url"
    chmod +x "$dest"
}

### Support functions

function add-to-list() {
  echo "$1" >> "/.mandalore/installed_tools.csv"
}

function add-aliases() {
    colorecho "Adding aliases for: $*"
    # Removing add empty lines and the last trailing newline if any, and adding a trailing newline.
    local alias_file="/root/sources/assets/shells/aliases.d/$*"
    if [[ -f "$alias_file" ]]; then
        grep -vE "^\s*$" "$alias_file" | tee -a /opt/.mandalore_aliases
    else
        # Not critical, just warn
        echo "Alias file not found: $alias_file" | tee -a /.mandalore/missing_assets.log
    fi
}

function add-history() {
    colorecho "Adding history commands for: $*"
    # Removing add empty lines and the last trailing newline if any, and adding a trailing newline.
    local hist_file="/root/sources/assets/shells/history.d/$*"
    if [[ -f "$hist_file" ]]; then
        grep -vE "^\s*$" "$hist_file" | tee -a /opt/.mandalore_history
    else
        # Not critical, just warn
        echo "History file not found: $hist_file" | tee -a /.mandalore/missing_assets.log
    fi
}

function add-test-command() {
    colorecho "Adding build pipeline test command: $*"
    echo "$*" >> "/.mandalore/unit_tests_all_commands.txt"
}

function add-test-gui-command() {
    colorecho "Adding build pipeline test gui command: $*"
    echo "$*" >> "/.mandalore/unit_tests_gui_commands.txt"
}

function fapt() {
    colorecho "Installing apt package(s): $*"
    # Do apt-get update only when no list are found
    if [ -z "$( ls -A '/var/lib/apt/lists/' )" ]; then
      apt-get update
    fi
    apt-fast install -y --no-install-recommends "$@"
}

function set_cargo_env() {
    colorecho "Setting cargo environment"
    source "$HOME/.cargo/env"
}

function set_ruby_env() {
    colorecho "Setting ruby environment"
    source /usr/local/rvm/scripts/rvm
    rvm use 3.2.2@default
}

function set_python_env() {
    colorecho "Setting python environment (uv)"
    # Add uv tools path
    export PATH="$HOME/.local/bin:$PATH"
    # Ensure system python3 is available if needed, but uv should handle venvs
}

function set_bin_path() {
    colorecho "Adding /opt/tools/bin to PATH"
    export PATH="/opt/tools/bin:$PATH"
}

function set_asdf_env(){
    colorecho "Setting asdf environment"
    export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"
}

function set_build_only_env(){
    # Here you can set environment variables that are only needed during the build process
    colorecho "Setting build only environment"
    
    # Make curl fails on HTTP errors (4xx and 5xx) because it doesn't by default
    export CURL_HOME="/root/sources/assets/shells/" # Curl will search for .curlrc in this directory
    # Make wget a bit less verbose
    export WGETRC="/root/sources/assets/shells/wgetrc"
}

function set_env() {
    colorecho "Setting env (caller)"
    set_bin_path
    set_cargo_env
    set_ruby_env
    set_python_env
    set_asdf_env
    set_build_only_env
}

### Catch & retry definitions

function is_network_error() {
    # Checks if the given output contains patterns indicating a network-related failure
    # Returns 0 if network error detected, 1 otherwise
    local output="$1"
    local network_patterns=(
        "Could not resolve host"
        "Connection refused"
        "Connection timed out"
        "Connection reset"
        "Network is unreachable"
        "No route to host"
        "SSL_ERROR"
        "TLS handshake"
        "Operation timed out"
        "Failed to connect"
        "Temporary failure in name resolution"
        "server certificate verification failed"
        "unable to access"
        "Could not connect to"
        "transfer closed"
        "Connection closed"
        "Recv failure"
        "Failed connect"
        "fatal: unable to access"
        "Error: ENOTFOUND"
        "Error: ETIMEDOUT"
        "Error: ECONNRESET"
        "Error: ECONNREFUSED"
        "error: could not download"
        "socket hang up"
        "Connection was reset"
        "unable to resolve"
    )
    for pattern in "${network_patterns[@]}"; do
        if echo "$output" | grep -qi "$pattern"; then
            return 0
        fi
    done
    return 1
}

function catch_and_retry() {
  local retries=5
  local i
  # wait time = scale_factor x (base_exponent ^ retry)
  local scale_factor=2  # scaling factor
  local base_exponent=4 # base of the exponent
  # 1st retry: 2×4^1 = 2×4    = 8 seconds
  # 2nd retry: 2×4^2 = 2×16   = 32 seconds
  # 3rd retry: 2×4^3 = 2×64   = 128 seconds
  # 4th retry: 2×4^4 = 2×256  = 512 seconds
  # 5th retry: 2×4^5 = 2×1024 = 2048 seconds
  local max_wait_time=600

  # We use 'command' to bypass the shell function wrapper and call the binary directly
  # This avoids the infinite loop without needing 'sh -c' and complex escaping

  local stderr_file
  stderr_file=$(mktemp)

  for ((i=1; i<=retries; i++)); do
    echo "[MANDALORE DEBUG] $*" >&2
    # If command exits successfully, no need for more retries
    command "$@" 2> >(tee "$stderr_file" >&2) && { rm -f "$stderr_file"; return 0; }

    local exit_code=$?
    local captured_stderr
    captured_stderr=$(cat "$stderr_file")

    # Only retry if this looks like a network error
    if ! is_network_error "$captured_stderr"; then
      criticalecho-noexit "Command failed (non-network error, no retry): $*"
      rm -f "$stderr_file"
      return $exit_code
    fi

    # Calculate the exponential backoff time
    local wait_time=$((scale_factor * (base_exponent ** i)))
    # Cap it at max_wait_time
    wait_time=$(( wait_time > max_wait_time ? max_wait_time : wait_time ))
    criticalecho-noexit "Command failed with network error (attempt $i/$retries). Retrying in $wait_time seconds..."
    sleep "$wait_time"
  done
  criticalecho-noexit "Command failed definitively after $retries attempts."
  rm -f "$stderr_file"
  return 1
}

function define_retry_function() {
  local original_command=$1
  eval "
  function $original_command() {
    colorecho 'Catch & retry function for: $1'
    catch_and_retry \"$original_command\" \"\$@\"
  }
  "
}

# Dynamically create wrappers
for CMD in "${CATCH_AND_RETRY_COMMANDS[@]}"; do
  define_retry_function "$CMD"
done

### Failure tracking & resilient install

# Directory for failure logs (one file per failed tool)
MANDALORE_FAIL_LOG_DIR="/.mandalore/build_failures"

# Associative array: package_name -> space-separated list of failed tool names
declare -A MANDALORE_FAILED_TOOLS

function init_failure_tracking() {
    mkdir -p "$MANDALORE_FAIL_LOG_DIR"
    MANDALORE_FAILED_TOOLS=()
}

function log_tool_failure() {
    local package_name="$1"
    local tool_name="$2"
    local error_log="$3"
    # Write per-tool failure log file
    local log_file="${MANDALORE_FAIL_LOG_DIR}/${package_name}__${tool_name}.log"
    echo "$error_log" > "$log_file"
    # Track in associative array for the summary
    MANDALORE_FAILED_TOOLS["$package_name"]+="${tool_name} "
}

function safe_install() {
    # Wrapper that runs an install_* function, catches failures,
    # logs them, and continues the build instead of aborting.
    # Usage: safe_install <package_name> <install_function> [args...]
    local package_name="$1"
    local install_func="$2"
    shift 2
    local tool_name="${install_func#install_}"

    colorecho ">>> Installing tool: $tool_name (package: $package_name)"

    local error_log_file
    error_log_file=$(mktemp)
    local exit_code

    # Temporarily disable exit-on-error so we can catch failures
    set +e
    # Run the command in a subshell with pipefail enabled so the pipeline fails if the command fails.
    # We pipe stderr to both the log file and the console (via tee /dev/stderr usually, but here we capture to file and cat it).
    # Wait, tee /dev/stderr causes output to appear on stderr.
    # Using ( set -o pipefail; command 2>&1 | tee "$error_log_file" ) allows capturing output while still seeing it.
    ( set -e; set -o pipefail; "$install_func" "$@" 2>&1 | tee "$error_log_file" )
    exit_code=$?
    set -e

    if [[ $exit_code -ne 0 ]]; then
        local error_output
        error_output=$(cat "$error_log_file")
        criticalecho-noexit "Tool '$tool_name' FAILED (exit code: $exit_code) — skipping and continuing build"
        log_tool_failure "$package_name" "$tool_name" "$error_output"
        rm -f "$error_log_file"
        return 0  # return 0 so the build continues
    fi

    rm -f "$error_log_file"
    colorecho "<<< Tool '$tool_name' installed successfully"
}

function print_failure_summary() {
    # Prints a colored summary of all tools that failed during the current package build.
    # Also writes a summary to the failure log directory.
    if [[ ${#MANDALORE_FAILED_TOOLS[@]} -eq 0 ]]; then
        colorecho "All tools installed successfully!"
        return 0
    fi

    echo ""
    echo -e "${RED}╔══════════════════════════════════════════════════╗${NOCOLOR}"
    echo -e "${RED}║         BUILD FAILURE SUMMARY                   ║${NOCOLOR}"
    echo -e "${RED}╚══════════════════════════════════════════════════╝${NOCOLOR}"

    local total_failures=0
    for package in "${!MANDALORE_FAILED_TOOLS[@]}"; do
        IFS=' ' read -ra tools <<< "${MANDALORE_FAILED_TOOLS[$package]}"
        local count=${#tools[@]}
        total_failures=$((total_failures + count))
        echo ""
        echo -e "${RED}Package '${package}': ${count} tool(s) failed:${NOCOLOR}"
        local i=1
        for tool in "${tools[@]}"; do
            echo -e "${RED}  ${i}. ${tool}${NOCOLOR}"
            echo -e "${BLUE}     Log: ${MANDALORE_FAIL_LOG_DIR}/${package}__${tool}.log${NOCOLOR}"
            ((i++))
        done
    done

    echo ""
    echo -e "${RED}Total: ${total_failures} tool(s) failed across ${#MANDALORE_FAILED_TOOLS[@]} package(s).${NOCOLOR}"
    echo -e "${BLUE}Detailed logs are in: ${MANDALORE_FAIL_LOG_DIR}/${NOCOLOR}"
    echo ""

    # Also write a machine-readable summary file
    local summary_file="${MANDALORE_FAIL_LOG_DIR}/SUMMARY.txt"
    {
        echo "=== BUILD FAILURE SUMMARY ==="
        echo "Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
        for package in "${!MANDALORE_FAILED_TOOLS[@]}"; do
            IFS=' ' read -ra tools <<< "${MANDALORE_FAILED_TOOLS[$package]}"
            echo ""
            echo "Package '${package}': ${#tools[@]} tool(s) failed:"
            local i=1
            for tool in "${tools[@]}"; do
                echo "  ${i}. ${tool}"
                ((i++))
            done
        done
    } >> "$summary_file"
}

function post_install() {
    # Function used to clean up post-install files
    colorecho "Cleaning..."
    updatedb
    rm -rf /root/.asdf/installs/golang/*/packages/pkg/mod
    rm -rf /root/.bundle/cache
    rm -rf /root/.cache
    rm -rf /root/.cargo/registry
    rm -rf /root/.gradle/caches
    rm -rf /root/.npm/_cacache
    rm -rf /root/.nvm/.cache
    rm -rf /tmp/*
    rm -rf /var/lib/apt/lists/*

    colorecho "Stop listening processes"
    local listening_processes
    listening_processes=$(ss -lnpt | awk -F"," 'NR>1 {split($2,a,"="); print a[2]}')
    if [[ -n $listening_processes ]]; then
        echo "Listening processes detected"
        ss -lnpt
        echo "Kill processes"
        # shellcheck disable=SC2086
        kill -9 $listening_processes
    fi
}

function print_global_failure_summary() {
    # Prints the accumulated failure summary from ALL packages across the entire build.
    # This reads the SUMMARY.txt file that was appended to by each package's print_failure_summary.
    local summary_file="${MANDALORE_FAIL_LOG_DIR}/SUMMARY.txt"
    if [[ ! -f "$summary_file" ]]; then
        echo ""
        echo -e "${GREEN}╔══════════════════════════════════════════════════╗${NOCOLOR}"
        echo -e "${GREEN}║     ALL TOOLS INSTALLED SUCCESSFULLY             ║${NOCOLOR}"
        echo -e "${GREEN}╚══════════════════════════════════════════════════╝${NOCOLOR}"
        echo ""
        return 0
    fi

    echo ""
    echo -e "${RED}╔══════════════════════════════════════════════════╗${NOCOLOR}"
    echo -e "${RED}║     GLOBAL BUILD FAILURE SUMMARY                ║${NOCOLOR}"
    echo -e "${RED}╠══════════════════════════════════════════════════╣${NOCOLOR}"

    # Count total failed tools across all log files
    local total_logs
    total_logs=$(find "$MANDALORE_FAIL_LOG_DIR" -name '*.log' 2>/dev/null | wc -l)
    echo -e "${RED}║  Total failed tools: ${total_logs}${NOCOLOR}"
    echo -e "${RED}╚══════════════════════════════════════════════════╝${NOCOLOR}"
    echo ""

    # Print the accumulated summary content
    cat "$summary_file"

    echo ""
    echo -e "${BLUE}Detailed per-tool logs are in: ${MANDALORE_FAIL_LOG_DIR}/${NOCOLOR}"
    echo -e "${RED}Review the logs above, fix the broken tools, and rebuild.${NOCOLOR}"
    echo ""
}

function post_build() {
    colorecho "Post build..."
    rm -rfv /root/sources
    add-test-command "if [[ $(sudo ss -lnpt | tail -n +2 | wc -l) -ne 0 ]]; then ss -lnpt && false;fi"
    colorecho "Sorting tools list"
    (head -n 1 /.mandalore/installed_tools.csv && tail -n +2 /.mandalore/installed_tools.csv | sort -f ) | tee /tmp/installed_tools.csv.sorted
    mv /tmp/installed_tools.csv.sorted /.mandalore/installed_tools.csv
    colorecho "Adding end-of-preset in zsh_history"
    echo "# -=-=-=-=-=-=-=- YOUR COMMANDS BELOW -=-=-=-=-=-=-=- #" >> /opt/.mandalore_history
    cp /opt/.mandalore_history ~/.zsh_history
    cp /opt/.mandalore_history ~/.bash_history
    colorecho "Removing desktop icons"
    if [ -d "/root/Desktop" ]; then rm -r /root/Desktop; fi
    # Print the global failure summary as the LAST thing in the build
    print_global_failure_summary
}

function check_temp_fix_expiry() {
    # This function checks if a temporary fix has expired
    # Parameters:
    # $1: expiry date in YYYY-MM-DD format
    # Returns:
    # 0 if the fix should be applied (not expired or local build)
    # 1 if the fix has expired (and not a local build)
    
    local expiry_date="$1"
    
    # Apply the fix if it's a local build regardless of expiry
    if [[ "$MANDALORE_BUILD_TYPE" == "local" ]]; then
        return 0
    fi
    
    # Check if the current date is past the expiry date
    if [[ "$(date +%Y%m%d)" -gt "$(date -d "$expiry_date" +%Y%m%d)" ]]; then
        criticalecho "Temp fix expired. Exiting."
    fi
    
    # Not expired, apply the fix
    return 0
}