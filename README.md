# docker-gr-iridium-toolkit + TBG
[![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/jkrasuk/docker-gr-iridium-toolkit/deploy.yml?branch=master)](https://github.com/rpatel3001/docker-gr-iridium-toolkit/actions/workflows/deploy.yml)
[![Discord](https://img.shields.io/discord/734090820684349521)](https://discord.gg/sTf9uYF)

A Docker image to use the [gr-iridium](https://github.com/muccc/gr-iridium) and [iridium-toolkit](https://github.com/muccc/iridium-toolkit) software from the [Chaos Computer Club München](https://muc.ccc.de/) to parse ACARS messages on the Iridium network.
This was made using Kevin's [script to manage MUCCC Iridium Toolkit](https://gist.github.com/kevinelliott/8bfbcc5555624082f743a7620322ee5c) and Rajan's Docker image to wrap it. 

This fork allows you to send ACARS and map data to [TBG](https://thebaldgeek.github.io).

## Table of Contents

- [docker-gr-iridium-toolkit + TBG](#docker-gr-iridium-toolkit--tbg)
  - [Table of Contents](#table-of-contents)
  - [Prerequisites](#prerequisites)
  - [Docker Compose](#docker-compose)
  - [Quick setup](#docker-compose)
  - [Environment Variables](#environment-variables)
  - [Configuration file](#configuration-file)
      - [RTL-SDR](#rtl-sdr)
      - [Airspy R2](#airspy-r2)
  - [What does it look like when it's running?](#what-does-it-look-like-when-its-running)
  - [Getting Help](#getting-help)
  
## Prerequisites

We expect you to have the following:

- A dedicated SDR dongle that can receive at 1622 MHz, with an appropriate antenna. The recommended setup is the 33-HC610-28 antenna paired with an Airspy R2.
- Docker must be installed on your system. If you don't know how to do that, please read [here](https://github.com/sdr-enthusiasts/docker-install).
- Some basic knowledge on how to use Linux and how to configure Docker containers with `docker-compose`.
- If you want to process the full spectrum (10 MHz) of data, you need a more powerful computer than a Raspberry Pi. Intel N95 or N100 mini PCs have been proven to work.
  
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
        max-size: "10k"
        max-file: "1"
```

It is possible to send ACARS and map data to [TBG](https://thebaldgeek.github.io) by performing the following steps:
1. Set the `STATION_ID` (used for ACARSHub and Airframes.io): The recommendation is to use the XX-YYYY-IRDM format, where XX is a two-digit representation of your initials or other personal id (mine is JK), YYYY is the nearest airport to you (mine is SADP) and IRDM means it is an Iridium feed.
2. Set the `ACARS_ADDITIONAL_OUTPUTS` variable to include "udp:thebaldgeek.net:NNNN". Contact him to get the port number.
3. Specify the port to which you will send the satellite beam data `TBG_SATS_PORT`.
4. Set the ICAO code of your nearby airport to `AIRPORT_ICAO_CODE`.

## Configuration file

irdm.conf has details of your SDR device. Full details can be found [here](https://github.com/muccc/gr-iridium?tab=readme-ov-file#configuration-file). 

**This file must be in the same folder where the YAML file is located**. 

Remember to play with the gain to get the best signal to noise ratio.

### RTL-SDR

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

### Airspy R2

An example for using an Airspy R2 with bias-tee enabled (required for the 33-HC610-28 antenna):

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

---

## Environment Variables

| Environment Variable | Purpose | Default value if omitted |
| ---------------------- | ------------------------------- | --- |
| `LOG_EXTRACTOR_STATS`| If set to `true`, it displays the extractor statistics in the container logs | `false` |
| `EXTRACTOR_ARGS` | Any additional command line parameters you wish to pass to `iridium-extractor` | Empty |
| `PARSER_ARGS` | Any additional command line parameters you wish to pass to `iridium-parser` | Empty |
| `STATION_ID` | Used to identify the feed on Airframes and ACARSHub | Empty |
| `ACARS_ADDITIONAL_OUTPUTS` | Additional output destinations for ACARS messages | Empty |
| `REASSEMBLER_EXTRA` | Any additional command line parameters you wish to pass to `reassembler` | Empty |
| `ENABLE_BEAM_MAP` | If set to `true`, the beam map function will be enabled | `false` |
| `LOG_MAP` | If set to `true`, the access logs of the beam map function will be enabled | `false` |
| `ENABLE_MTPOS_MAP` |  If set to `true`, the MT map function will be enabled | `false` |
| `LOG_MTMAP` | If set to `true`, the access logs of the MT map function will be enabled | `false` |
| `LIVEMAP_TO_TBG` | If set to `true`, the TBG feed function will be enabled | `false` |
| `AIRPORT_ICAO_CODE` | ICAO code used by TBG to identify your data | Empty |
| `TBG_SATS_PORT` | Port to which the satellite beam data will be sent | Empty |


## What does it look like when it's running?

You can check the extractor statistics by running `docker logs irdm -f`

![Image](https://github.com/user-attachments/assets/88794444-8896-4db0-8627-b4b251a55aca)

Also, if you enabled the beam map, you should see a map with the satellite beams on [http://localhost:8888](http://localhost:8888/). 

![Satellite Beam Map](https://i.imgur.com/qsjIVfP.png)

The approximate location of the SBD and GSM terminals can be found on [http://localhost:8889](http://localhost:8889/).

The MT heatmap can be found on [http://localhost:8889/mtheatmap.html](http://localhost:8889/mtheatmap.html).

## Getting Help

You can [log an issue](https://github.com/jkrasuk/docker-gr-iridium-toolkit/issues) on the project's GitHub.

I am also available on [Airframes](https://discord.gg/airframes) (#aoi-iridium) and [SDR Enthusiasts](https://discord.gg/sTf9uYF) (#satcom) Discord channels.

