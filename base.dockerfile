# syntax=docker/dockerfile:1
# Author: The Mandalore Project
FROM debian:13-slim

ARG TAG
ARG VERSION
ARG BUILD_DATE

LABEL org.mandalore.tag="${TAG}"
LABEL org.mandalore.version="${VERSION}"
LABEL org.mandalore.build_date="${BUILD_DATE}"
LABEL org.mandalore.app="Mandalore"
LABEL org.mandalore.src_repository="https://github.com/ghecko/mandalore-images"

ENV MANDALORE_BUILD_TYPE="${VERSION}"

COPY sources /root/sources/

WORKDIR /root/sources/install

RUN echo "${TAG}-${VERSION}" > /opt/.mandalore_version
RUN chmod +x entrypoint.sh
RUN --mount=type=secret,id=github_token,env=GITHUB_TOKEN ./entrypoint.sh package_base
RUN --mount=type=secret,id=github_token,env=GITHUB_TOKEN ./entrypoint.sh package_desktop
RUN --mount=type=secret,id=github_token,env=GITHUB_TOKEN ./entrypoint.sh package_network
RUN --mount=type=secret,id=github_token,env=GITHUB_TOKEN ./entrypoint.sh post_build

WORKDIR /workspace

ENTRYPOINT ["/.mandalore/entrypoint.sh"]