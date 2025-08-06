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