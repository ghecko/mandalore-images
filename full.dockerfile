# syntax=docker/dockerfile:1
# Author: The Mandalore Project
FROM lksec/mandalore-base

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

RUN chmod +x entrypoint.sh
RUN --mount=type=secret,id=github_token,env=GITHUB_TOKEN ./entrypoint.sh package_misc
RUN --mount=type=secret,id=github_token,env=GITHUB_TOKEN ./entrypoint.sh package_c2
RUN --mount=type=secret,id=github_token,env=GITHUB_TOKEN ./entrypoint.sh package_wordlists
RUN --mount=type=secret,id=github_token,env=GITHUB_TOKEN ./entrypoint.sh package_cracking
RUN --mount=type=secret,id=github_token,env=GITHUB_TOKEN ./entrypoint.sh package_osint
RUN --mount=type=secret,id=github_token,env=GITHUB_TOKEN ./entrypoint.sh package_web
RUN --mount=type=secret,id=github_token,env=GITHUB_TOKEN ./entrypoint.sh package_ad
RUN --mount=type=secret,id=github_token,env=GITHUB_TOKEN ./entrypoint.sh package_mobile
RUN --mount=type=secret,id=github_token,env=GITHUB_TOKEN ./entrypoint.sh package_iot
RUN --mount=type=secret,id=github_token,env=GITHUB_TOKEN ./entrypoint.sh package_rfid
RUN --mount=type=secret,id=github_token,env=GITHUB_TOKEN ./entrypoint.sh package_voip
RUN --mount=type=secret,id=github_token,env=GITHUB_TOKEN ./entrypoint.sh package_sdr
RUN --mount=type=secret,id=github_token,env=GITHUB_TOKEN ./entrypoint.sh package_wifi
RUN --mount=type=secret,id=github_token,env=GITHUB_TOKEN ./entrypoint.sh package_forensic
RUN --mount=type=secret,id=github_token,env=GITHUB_TOKEN ./entrypoint.sh package_cloud
RUN --mount=type=secret,id=github_token,env=GITHUB_TOKEN ./entrypoint.sh package_steganography
RUN --mount=type=secret,id=github_token,env=GITHUB_TOKEN ./entrypoint.sh package_reverse
RUN --mount=type=secret,id=github_token,env=GITHUB_TOKEN ./entrypoint.sh package_crypto
RUN --mount=type=secret,id=github_token,env=GITHUB_TOKEN ./entrypoint.sh package_code_analysis
RUN --mount=type=secret,id=github_token,env=GITHUB_TOKEN ./entrypoint.sh post_build

WORKDIR /workspace

ENTRYPOINT ["/.mandalore/entrypoint.sh"]