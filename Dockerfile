FROM rust:1.84.0 AS builder
WORKDIR /tmp/acars-bridge
# hadolint ignore=DL3008,DL3003,SC1091
RUN set -x && \
    apt-get update && \
    apt-get install -y --no-install-recommends libzmq3-dev

FROM ghcr.io/sdr-enthusiasts/docker-baseimage:soapy-full

COPY iridium-toolkit.patch /tmp/iridium-toolkit.patch

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# hadolint ignore=DL3008,SC2086,DL4006,SC2039
RUN set -x && \
    TEMP_PACKAGES=() && \
    KEPT_PACKAGES=() && \
    TEMP_PACKAGES+=() && \
    # temp
    TEMP_PACKAGES+=(build-essential) && \
    TEMP_PACKAGES+=(cmake) && \
    TEMP_PACKAGES+=(git) && \
    TEMP_PACKAGES+=(libusb-1.0-0-dev) && \
    TEMP_PACKAGES+=(gnuradio-dev) && \
    TEMP_PACKAGES+=(libsndfile1-dev) && \
    # keep
    KEPT_PACKAGES+=(python3) && \
    KEPT_PACKAGES+=(python3-prctl) && \
    KEPT_PACKAGES+=(python3-pip) && \
    KEPT_PACKAGES+=(libusb-1.0-0) && \
    KEPT_PACKAGES+=(gnuradio) && \
    KEPT_PACKAGES+=(gr-osmosdr) && \
    KEPT_PACKAGES+=(libsndfile1) && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    "${KEPT_PACKAGES[@]}" \
    "${TEMP_PACKAGES[@]}" && \
    # install pip dependencies
    ln -s /usr/bin/python3 /usr/bin/pypy3 && \
    pypy3 -m pip install --break-system-packages crcmod zmq pyproj && \
    # install iridium-toolkit
    git clone https://github.com/muccc/iridium-toolkit /opt/iridium-toolkit && \
    pushd /opt/iridium-toolkit && \
    mv html/map.html html/index.html && \
    mkdir html2 && \
    mv html/mtmap.html html2/index.html && \
    mv html/mtheatmap.html html2 && \
    cp html/favicon.ico html2 && \
    rm html/example.sh && \
    git apply --3way /tmp/iridium-toolkit.patch && \
    popd && \
    # install gr-iridium
    git clone https://github.com/muccc/gr-iridium.git /src/gr-iridium && \
    pushd /src/gr-iridium && \
    cmake -B build && \
    cmake --build build -j`nproc` && \
    cmake --install build && \
    ldconfig && \
    popd && \
    # install tbg-send-sats
    git clone https://gist.github.com/efccc60079bf05391a9032dadf188c86.git /opt/tbg-send-sats && \
    # Clean up
    apt-get remove -y "${TEMP_PACKAGES[@]}" && \
    apt-get autoremove -y && \
    rm -rf /src/* /tmp/* /var/lib/apt/lists/*

COPY rootfs /
