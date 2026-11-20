# syntax=docker/dockerfile:1
# Author: The Mandalore Project
FROM ghcr.io/ghecko/mandalore-base

ARG TAG
ARG VERSION
ARG BUILD_DATE

LABEL org.mandalore.tag="${TAG}"
LABEL org.mandalore.version="${VERSION}"
LABEL org.mandalore.build_date="${BUILD_DATE}"
LABEL org.mandalore.app="Mandalore"
LABEL org.mandalore.src_repository="https://github.com/ghecko/mandalore-images"

COPY sources /root/sources/
WORKDIR /root/sources/install

RUN echo "${TAG}-${VERSION}" > /opt/.mandalore_version
RUN chmod +x entrypoint.sh
RUN --mount=type=secret,id=github_token,env=GITHUB_TOKEN ./entrypoint.sh package_base
RUN --mount=type=secret,id=github_token,env=GITHUB_TOKEN ./entrypoint.sh package_desktop
RUN --mount=type=secret,id=github_token,env=GITHUB_TOKEN ./entrypoint.sh package_misc
RUN --mount=type=secret,id=github_token,env=GITHUB_TOKEN ./entrypoint.sh package_c2
RUN --mount=type=secret,id=github_token,env=GITHUB_TOKEN ./entrypoint.sh package_wordlists
RUN --mount=type=secret,id=github_token,env=GITHUB_TOKEN ./entrypoint.sh package_cracking
RUN --mount=type=secret,id=github_token,env=GITHUB_TOKEN ./entrypoint.sh package_web
RUN --mount=type=secret,id=github_token,env=GITHUB_TOKEN ./entrypoint.sh package_ad
RUN --mount=type=secret,id=github_token,env=GITHUB_TOKEN ./entrypoint.sh post_build

WORKDIR /workspace

ENTRYPOINT ["/.mandalore/entrypoint.sh"]