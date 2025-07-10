# Author: The Mandalore Project

FROM debian:12-slim

# ARGs need to be placed after the FROM instruction. As per https://docs.docker.com/engine/reference/builder/#arg. As per https://docs.docker.com/engine/reference/builder/#arg.
# If they are placed before, they will be overwritten somehow, and the LABELs below will be filled with empty ARGs
ARG TAG="local"
ARG VERSION="local"
ARG BUILD_DATE="n/a"

LABEL org.mandalore.tag="${TAG}"
LABEL org.mandalore.version="${VERSION}"
LABEL org.mandalore.build_date="${BUILD_DATE}"
LABEL org.mandalore.app="Mandalore"
LABEL org.mandalore.src_repository="https://github.com/ghecko/mandalore-images"

# Set the build type environment variable to bypass temp fix expiry check when building locally
ENV MANDALORE_BUILD_TYPE="${VERSION}"

COPY sources /root/sources/

WORKDIR /root/sources/install

# WARNING: package_most_used can't be used with other functions other than: package_base
# ./entrypoint.sh package_most_used

RUN echo "${TAG}-${VERSION}" > /opt/.mandalore_version
RUN chmod +x entrypoint.sh
RUN ./entrypoint.sh package_base
RUN ./entrypoint.sh package_desktop
RUN ./entrypoint.sh package_misc
RUN ./entrypoint.sh package_c2
RUN ./entrypoint.sh package_wordlists
RUN ./entrypoint.sh package_cracking
RUN ./entrypoint.sh package_osint
RUN ./entrypoint.sh package_web
RUN ./entrypoint.sh package_ad
RUN ./entrypoint.sh package_mobile
RUN ./entrypoint.sh package_iot
RUN ./entrypoint.sh package_rfid
RUN ./entrypoint.sh package_voip
RUN ./entrypoint.sh package_sdr
RUN ./entrypoint.sh package_network
RUN ./entrypoint.sh package_wifi
RUN ./entrypoint.sh package_forensic
RUN ./entrypoint.sh package_cloud
RUN ./entrypoint.sh package_steganography
RUN ./entrypoint.sh package_reverse
RUN ./entrypoint.sh package_crypto
RUN ./entrypoint.sh package_code_analysis
RUN ./entrypoint.sh post_build

WORKDIR /workspace

ENTRYPOINT ["/.mandalore/entrypoint.sh"]
