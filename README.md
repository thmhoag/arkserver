[![Travis CI Build Status](https://img.shields.io/travis/thmhoag/arkserver/master?label=Travis%20CI&style=flat-square)](https://travis-ci.org/github/thmhoag/arkserver)
[![Docker Build Status](https://img.shields.io/docker/cloud/build/thmhoag/arkserver?style=flat-square)](https://hub.docker.com/r/thmhoag/arkserver/builds/)
[![Docker Pulls](https://img.shields.io/docker/pulls/thmhoag/arkserver.svg?style=flat-square)](https://hub.docker.com/r/thmhoag/arkserver/) 
[![License](https://img.shields.io/dub/l/vibe-d.svg?style=flat-square)](https://github.com/thmhoag/arkserver/blob/master/LICENSE)


# arkserver
```
Docker image for a dedicated ARK Server with arkmanager.
```

## Overview

This is an image for running an ARK: Survival Evolved server in a Docker container. It is heavily based off of [TuRz4m](https://github.com/TuRz4m)'s work located here: [TuRz4m/Ark-docker](https://github.com/TuRz4m/Ark-docker). It uses [FezVrasta](https://github.com/FezVrasta)'s [arkmanager](https://github.com/FezVrasta/ark-server-tools) (ark-server-tools) to managed a single-instance ARK: Survival Evolved server inside a docker container.

This image inherits from the [thmhoag/steamcmd](https://github.com/thmhoag/steamcmd) image to include the latest version of `steamcmd`.

For more information on `arkmanager`, see the repo here: https://github.com/FezVrasta/ark-server-tools

### Features
* Automated install (pull the image and run, no additional commands necessary)
* Configuration via Environment Variables
* Easy crontab manipulation for automated backups, updates, daily restarts, weekly dino wipes, etc
* Simple volume structure for server files, config, logs, backups, etc
* Inherently includes all features present in `arkmanager`

### Tags
| Tag | Description |
|--|--|
| latest | most recent build from the master branch |
| x.x.x (semver) | release builds |

## Usage

### Installing the image

Pull the latest (or any other desired version):
```bash
docker pull thmhoag/arkserver:latest
```

### Running the server

To run a generic server with no configuration modifications:
```bash
$ docker run -d \
    -v steam:/home/steam/.steam/steamapps \  # mounted so that workshop (mod) downloads are persisted
    -v ark:/ark \  # mounted as the directory to contain the server/backup/log/config files
    -p 27015:27015 -p 27015:27015/udp \  # steam query port
    -p 7778:7778 -p 7778:7778/udp \  # gameserver port
    -p 7777:7777 -p 7777:7777/udp \ # gameserver port
    thmhoag/arkserver
```

If the exposed ports are modified (in the case of multiple containers/servers on the same host) the `arkmanager` config will need to be modified to reflect the change as well. This is required so that `arkmanager` can properly check the server status and so that the ARK server itself can properly publish its IP address and query port to steam.

## Environment Variables

A set of required environment variables have default values provided as part of the image:

| Variable | Value | Description |
| - | - | - |
| am_ark_SessionName | `Ark Server` | Server name as it will show on the steam server list |
| am_serverMap | `TheIsland` | Game map to load |
| am_ark_ServerAdminPassword | `k3yb04rdc4t` | Admin password to be used via ingame console or RCON |
| am_ark_MaxPlayers | `70` | Max concurrent players in the game |
| am_ark_QueryPort | `27015` | Steam query port (allows the server to show up on the steam list) |
| am_ark_Port | `7778` | Game server port (allows clients to connect to the server) |
| am_ark_RCONPort | `32330` | RCON port |
| am_arkwarnminutes | `15` | Number of minutes to wait/warn players before updating/restarting |
| am_arkflag_crossplay | `false` | Allow crossyplay with Players on Epic |
| ARKCLUSTER | `false` | If true, requires `ShooterGame/Saved/clusters` to be mounted |
| ARKSERVER_SHARED | `` | To optionally share server binary files, use `/arkserver` volume, see below |
| LOG_RCONCHAT | `0` | Fetch chat commands every X seconds and log them to stdout, `0` = disabled |

### Adding Additional Variables

Any configuration value that is available via `arkmanager` can be set using an environment variable. This works by taking any environment variable on the container that is prefixed with `am_` and mapping it to the corresponding environment variable in the `arkmanager.cfg` file. 

For a complete list of configuration values available, please see [FezVrasta](https://github.com/arkmanager)'s great documentation here: [arkmanager Configuration Files](https://github.com/arkmanager/ark-server-tools#configuration-files)

Some examples:
```shell script
am_ark_ServerPassword=s3cr3t
am_ark_GameModIds=889745138,731604991
am_arkopt_clusterid=mycluster
am_arkflag_NoTransferFromFiltering=
am_arkflag_servergamelog=
am_arkflag_ForceAllowCaveFlyers=
```

## Volumes

This image has two main volumes that should be mounted as named volumes or host directories for the persistence of the server install and all related configuration files. More information on Docker volumes here: [Docker: Use Volumes](https://docs.docker.com/storage/volumes/)
The optional volumes can be used to share the server binary files or `clusters` files required to run an ARK cluster and be able to jump from one map to another. 

| Path | Description |
| - | - |
| /home/steam/.steam/steamapps | Directory of steamapps and workshop files. Should be mounted so that mod installs are persisted between container runs/restarts |
| /ark | Directory that will contain the server files, config files, logs and backups. More information below |
| /arkserver | (optional, $ARKSERVER_SHARED) Directory that contains the server binary files from steam, shared for multiple instances |
| /arkserver/ShooterGame/Saved | (depends) Directory that contains the game save files - must be mounted if using shared server files |
| /arkserver/ShooterGame/Saved/clusters | (depends) Directory that contains the shared cluster files required to jump from one ARK server to another - must be mounted if using shared server files |

### Subdirectories of /ark

Inside the `/ark` volume there are several directories containing server related files:

| Path | Description |
| - | - |
| /ark/backup | Location of the zipped backups genereated from the `arkmaanger backup` command. Compressed using bz2. |
| /ark/config | Location of server config files. More information: |
| /ark/log | Location of the arkmanager and arkserver log files |
| /ark/server | Location of the server installation performed by `steamcmd`. This will contain the ShooterGame directory and the actual server binaries. |
| /ark/staging | Default directory for staging game and mod updates. Can be changed using in `arkmanager.cfg` |

## Running a cluster
In order to run an ARK cluster, all you need are multiple servers sharing the `clusters` directory and using a shared, 
unique `clusterid` - and a lot of RAM.
Additionally you can share the server files, so that all servers use the same version and you don't have to 
store identical files twice on disk.

Example: (using the .env files in `/test`)
```shell script
IMAGE=thmhoag/arkcluster
TAG=bionic
mkdir -p theisland ragnarok arkserver arkclusters theisland/saved ragnarok/saved

# start server 1 with am_arkAutoUpdateOnStart=true
serverdir=theisland
docker run --rm -it --name $serverdir \
  --env-file test/ark-$serverdir.env \
  -v $PWD/$serverdir:/ark \
  -v $PWD/$serverdir/saved:/arkserver/ShooterGame/Saved \
  -v $PWD/arkclusters:/arkserver/ShooterGame/Saved/clusters \
  -v $PWD/arkserver:/arkserver \
  -p 27015:27015/udp -p 7778:7778/udp -p 32330:32330 \
  $IMAGE:$TAG

# wait for the server to be up, it should download all mods and the game

# start server 2+ with am_arkAutoUpdateOnStart=false
# using the SAME `arkserver` and `arkclusters` directory
serverdir=ragnarok
docker run --rm -it --name $serverdir \
  --env-file test/ark-$serverdir.env \
  -v $PWD/$serverdir:/ark \
  -v $PWD/$serverdir/saved:/arkserver/ShooterGame/Saved \
  -v $PWD/arkclusters:/arkserver/ShooterGame/Saved/clusters \
  -v $PWD/arkserver:/arkserver \
  -p 27016:27016/udp -p 7780:7780/udp -p 32331:32331 \
  $IMAGE:$TAG

# now you can reach your servers on 27015 and 27016 respectively

# cleanup
rm -rf theisland ragnarok arkserver arkclusters
```