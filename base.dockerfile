# Author: The Mandalore Project
FROM debian:12-slim

ARG TAG
ARG VERSION
ARG BUILD_DATE
# Optional GitHub PAT to avoid api.github.com rate-limiting during build.
# Pass with: docker build --build-arg GITHUB_TOKEN=<pat> ...
ARG GITHUB_TOKEN=""
ENV GITHUB_TOKEN="${GITHUB_TOKEN}"

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
RUN ./entrypoint.sh package_base
RUN ./entrypoint.sh package_desktop
RUN ./entrypoint.sh package_network
RUN ./entrypoint.sh post_build

WORKDIR /workspace

ENTRYPOINT ["/.mandalore/entrypoint.sh"]