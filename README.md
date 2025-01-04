# docker-gr-iridium-toolkit + TBG + libacars
[![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/jkrasuk/docker-gr-iridium-toolkit/deploy.yml?branch=master)](https://github.com/rpatel3001/docker-gr-iridium-toolkit/actions/workflows/deploy.yml)
[![Discord](https://img.shields.io/discord/734090820684349521)](https://discord.gg/sTf9uYF)

A Docker image to use the [gr-iridium](https://github.com/muccc/gr-iridium) and [iridium-toolkit](https://github.com/muccc/iridium-toolkit) software from the [Chaos Computer Club München](https://muc.ccc.de/) to parse ACARS messages on the Iridium network.

It is possible to send ACARS and map data to [TBG](https://thebaldgeek.github.io) making the following steps:
1. Set the `ACARS_ADDITIONAL_OUTPUTS` variable in `docker-compose.yaml` to include "udp:thebaldgeek.net:XXXX". Contact him to get a port.
3. Set the `LIVEMAP_TO_TBG` variable to true
2. Make a copy of `thebaldgeek-send-sats.py.example`, setup your neareast airport ICAO code in "uid" and specify the port where you will send the satellites beams data.


This was made using Kevin's [script](https://gist.github.com/kevinelliott/8bfbcc5555624082f743a7620322ee5c) to manage MUCCC Iridium Toolkit and Rajan's docker image to wrap it.

Under active development, everything is subject to change without notice.

---

## Docker Compose

```
services:
  irdm:
    container_name: irdm
    hostname: irdm
    image: ghcr.io/jkrasuk/docker-gr-iridium-toolkit
#    build: docker-gr-iridium-toolkit
    restart: always
    tty: true # actually needed, for iridium-parser.py
    ports:
      - 8888:8888 # for beam map
      - 8889:8889 # for mt map
    device_cgroup_rules:
      - 'c 189:* rwm'
    volumes:
      - /dev:/dev:rw
      - ./irdm.conf:/opt/irdm.conf:ro
      - ./thebaldgeek-send-sats.py:/opt/thebaldgeek-send-sats.py
      - ./logs:/opt/logs
    environment:
      - ENABLE_BEAM_MAP=true
#      - ENABLE_MTPOS_MAP=true
#      - ENABLE_MTPOS_MAP_LOG=true
#      - DISABLE_EXTRACTOR=true
      - LOG_EXTRACTOR_STATS=true
#      - LOG_MAP=true
      - EXTRACTOR_ARGS= -D 4 --multi-frame # Valid values when running high sample rate are 1, 2, 4, 8 and 16
      - STATION_ID=XX-YYYY-IRDM
      - LIVEMAP_TO_TBG=true
      - ACARS_ADDITIONAL_OUTPUTS=udp:acarshub:5558,udp:thebaldgeek.net:XXXX
#      - LOG_ACARS=true
#      - PARSER_ARGS= --harder --uw-ec --stats # remove --uw-ec then --harder if CPU usage is too high. --stats is required until an upstream bug is fixed

```

irdm.conf has details of your SDR device. Full details can be found [here](https://github.com/muccc/gr-iridium?tab=readme-ov-file#configuration-file). An example for using an RTL-SDR with max gain and bias-tee enabled:

```
[osmosdr-source]
sample_rate=2500000
center_freq=1625600000

# Uncomment to use the RTL-SDR's Bias Tee if available
device_args='rtl=0,bias=1'

# Automatic bandwidth
bandwidth=0

# LNA gain
gain=49.6
```
