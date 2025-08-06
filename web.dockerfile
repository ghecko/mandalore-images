# Author: The Mandalore Project
FROM lksec/mandalore-base

LABEL org.mandalore.tag="${TAG}"
LABEL org.mandalore.version="${VERSION}"
LABEL org.mandalore.build_date="${BUILD_DATE}"
LABEL org.mandalore.app="Mandalore"
LABEL org.mandalore.src_repository="https://github.com/ghecko/mandalore-images"

COPY sources /root/sources/
WORKDIR /root/sources/install

RUN echo "${TAG}-${VERSION}" > /opt/.mandalore_version
RUN chmod +x entrypoint.sh
RUN ./entrypoint.sh package_base
RUN ./entrypoint.sh package_desktop
RUN ./entrypoint.sh package_misc
RUN ./entrypoint.sh package_wordlists
RUN ./entrypoint.sh package_cracking
RUN ./entrypoint.sh package_osint
RUN ./entrypoint.sh package_web
RUN ./entrypoint.sh package_code_analysis
RUN ./entrypoint.sh post_build

WORKDIR /workspace

ENTRYPOINT ["/.mandalore/entrypoint.sh"]
