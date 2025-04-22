# docker-gr-iridium-toolkit + TBG
[![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/jkrasuk/docker-gr-iridium-toolkit/deploy.yml?branch=master)](https://github.com/rpatel3001/docker-gr-iridium-toolkit/actions/workflows/deploy.yml)
[![Discord](https://img.shields.io/discord/734090820684349521)](https://discord.gg/sTf9uYF)

A Docker image to use the [gr-iridium](https://github.com/muccc/gr-iridium) and [iridium-toolkit](https://github.com/muccc/iridium-toolkit) software from the [Chaos Computer Club München](https://muc.ccc.de/) to parse ACARS messages on the Iridium network.

It is possible to send ACARS and map data to [TBG](https://thebaldgeek.github.io) by performing the following steps:
1. Set the `ACARS_ADDITIONAL_OUTPUTS` variable in `docker-compose.yaml` to include "udp:thebaldgeek.net:XXXX". Contact him to get the port number.
2. Set the `LIVEMAP_TO_TBG` variable to true.
3. Specify the port to which you will send the satellite beam data `TBG_SATS_PORT`.
4. Set the ICAO code of your nearby airport `AIRPORT_ICAO_CODE`.


This was made using Kevin's [script to manage MUCCC Iridium Toolkit](https://gist.github.com/kevinelliott/8bfbcc5555624082f743a7620322ee5c) and Rajan's docker image to wrap it.

Under active development, everything is subject to change without notice.

---

## Docker Compose

```
services:
  irdm:
    container_name: irdm
    hostname: irdm
    image: ghcr.io/jkrasuk/docker-gr-iridium-toolkit
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
      - ./logs:/opt/logs
    environment:
      - ENABLE_BEAM_MAP=true
      - ENABLE_MTPOS_MAP=true
      - LOG_EXTRACTOR_STATS=true
      - EXTRACTOR_ARGS= -D 8 --multi-frame # Valid values when running high sample rate are 1, 2, 4, 8 and 16
      - STATION_ID=XX-YYYY-IRDM
      - LIVEMAP_TO_TBG=true
      - TBG_SATS_PORT=ZZZZ
      - AIRPORT_ICAO_CODE=YYYY
      - ACARS_ADDITIONAL_OUTPUTS=udp:acarshub:5558,udp:thebaldgeek.net:NNNN
      - PARSER_ARGS= --uw-ec --stats # remove --uw-ec if CPU usage is too high. --stats is required until an upstream bug is fixed
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "5"
```

irdm.conf has details of your SDR device. Full details can be found [here](https://github.com/muccc/gr-iridium?tab=readme-ov-file#configuration-file). This file must be in the same folder where the yaml file is located. 

An example for using an RTL-SDR with max gain and bias-tee enabled:

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

Airspy R2 example:

```
[osmosdr-source]

# Uncomment the following line to turn on the antenna bias
device_args='airspy=0,bias=1,pack=1'

sample_rate=10000000
center_freq=1622000000
bandwidth=10000000

# Linearity Gain
gain=18
```
