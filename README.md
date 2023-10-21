![Latest Docker Build](https://img.shields.io/github/actions/workflow/status/gornoka/arkserver/docker-build.yaml)
![Docker Pulls](https://img.shields.io/docker/pulls/gornoka/arkserver) 
[![License](https://img.shields.io/dub/l/vibe-d.svg?style=flat-square)](https://github.com/gornoka/arkserver/blob/master/LICENSE)


# arkserver
```
Docker image for a dedicated ARK Server with ARK manager.
```

## Overview

This is an image for running an ARK: Survival Evolved server in a Docker container, 
and some compose files to make cluster hosting easier.

This is based upon the work of [thmhoag](https://github.com/thmhoag/arkserver).

It is heavily based off of [TuRz4m](https://github.com/TuRz4m)'s work located here: [TuRz4m/Ark-docker](https://github.com/TuRz4m/Ark-docker). It uses [FezVrasta](https://github.com/FezVrasta)'s [arkmanager](https://github.com/FezVrasta/ark-server-tools) (ark-server-tools) to managed a single-instance ARK: Survival Evolved server inside a docker container.

This image inherits from the [cm2network/steamcmd](https://github.com/CM2Walki/steamcmd) image to include the latest version of `steamcmd`.

For more information on `arkmanager`, see the repo here: https://github.com/FezVrasta/ark-server-tools

### Features
* Automated install (pull the image and run, no additional commands necessary)
* Configuration via Environment Variables
* Easy crontab manipulation for automated backups, updates, daily restarts, weekly dino wipes, etc
* Simple volume structure for server files, config, logs, backups, etc
* Inherently includes all features present in `arkmanager`

### Tags
| Tag            | Description                                                    |
|----------------|----------------------------------------------------------------|
| latest         | most recent build from the master branch                       |
| x.x.x (semver) | release builds                                                 |
| master         | latest version immediately triggered after push to main branch |
| YYYYMM         | most recent daily build of that month                          |



## Usage

### Installing the image

Pull the latest (or any other desired version):
```bash
docker pull gornoka/arkserver:latest
```

### Running with bare Docker
This is not recommended for actual usage, but is useful for testing and development

To run a generic server with no configuration modifications:
```bash
$ docker run -d \
    -v steam:/home/steam/Steam \  # mounted so that workshop (mod) downloads are persisted
    -v ark:/ark \  # mounted as the directory to contain the server/backup/log/config files
    -p 27015:27015 -p 27015:27015/udp \  # steam query port
    -p 7778:7778 -p 7778:7778/udp \  # gameserver port
    -p 7777:7777 -p 7777:7777/udp \ # gameserver port
    --ulimit nofile=10000:10000 \  # reduce ulimit to prevent lsof from taking forever
    gornoka/arkserver
```

If the exposed ports are modified (in the case of multiple containers/servers on the same host) the `arkmanager` config will need to be modified to reflect the change as well. This is required so that `arkmanager` can properly check the server status and so that the ARK server itself can properly publish its IP address and query port to steam.

### Running with Docker compose
clone the repository 
```bash
git clone https://github.com/gornoka/arkserver   
```
before running the server it is advised that you check the configuration, 
especially the volume mappings inside the container, 
since the downloaded files are very big.

Treat this compose file as an example, you can create your own compose files from this one.
To run multiple Ark servers on one server you can create multiple services in the compose file.
Change ports and volume mappings accordingly. 
There is an example for this in the [cluster compose file](./docker-compose-cluster.yaml).


#### Run a single ARK server
```bash
# changing to the new directory
cd arkserver
# start server interactively (shuts down when console is closed)
docker compose up 
# start server and run in background 
docker compose up -d
```
This server now operates with default parameters, to change those open the 
[docker compose file](/docker-compose.yaml) and adapt the parameters to your needs.
After that, you can run the server again with the start command of your liking

#### Run an ARK cluster
starting the example config :
```bash
cd arkserver
docker compose -f docker-compose-cluster.yaml up -d

```
ports for ARK are a little weird, so you have to use the following ports for the servers:

| port  | usage                                                                                |
|-------|--------------------------------------------------------------------------------------|
| 27015 | Steam query port                                                                     |
| 7778  | primary port                                                                         |
| 7777  | secondary port, this port is inferred by ARK servermanager it is the primary port -1 |
| 32340 | rcon port, only forward this if you need the RCON                                    |

if you have multiple ARK servers in your cluster you must assign unique ports to each server,do not use the docker compose
ports parameter to change the host and container ports, steams server browser relies on you configuring the same port
once in the env param for the ARK server manager 'am_ark_Port: 7791' and once in the ports section '7791:7791/udp'.
Do not forge the UDP part, it is important for the server to work.


#### specific troubleshooting
ensure correct file parameters for the docker user in the parameter where you save your files ( see the docker compose - volumes value)

## Environment Variables

A set of required environment variables have default values provided as part of the image:

| Variable                   | Value         | Description                                                       |
|----------------------------|---------------|-------------------------------------------------------------------|
| am_ark_SessionName         | `Ark Server`  | Server name as it will show on the steam server list              |
| am_serverMap               | `TheIsland`   | Game map to load                                                  |
| am_ark_ServerAdminPassword | `k3yb04rdc4t` | Admin password to be used via ingame console or RCON              |
| am_ark_MaxPlayers          | `70`          | Max concurrent players in the game                                |
| am_ark_QueryPort           | `27015`       | Steam query port (allows the server to show up on the steam list) |
| am_ark_Port                | `7778`        | Game server port (allows clients to connect to the server)        |
| am_ark_RCONPort            | `32330`       | RCON port                                                         |
| am_arkwarnminutes          | `15`          | Number of minutes to wait/warn players before updating/restarting |
| am_arkflag_crossplay       | `false`       | Allow crossyplay with Players on Epic                             |

### Adding Additional Variables

Any configuration value that is available via `arkmanager` can be set using an environment variable. This works by taking any environment variable on the container that is prefixed with `am_` and mapping it to the corresponding environment variable in the `arkmanager.cfg` file. 

For a complete list of configuration values available, please see [FezVrasta](https://github.com/FezVrasta)'s great documentation here: [arkmanager Configuration Files](https://github.com/FezVrasta/ark-server-tools#configuration-files)

## Volumes

This image has two main volumes that should be mounted as named volumes or host directories for the persistence of the server install and all related configuration files. More information on Docker volumes here: [Docker: Use Volumes](https://docs.docker.com/storage/volumes/)

| Path              | Description                                                                                                                                     |
|-------------------|-------------------------------------------------------------------------------------------------------------------------------------------------|
| /home/steam/Steam | Directory of steam cache and other steamcmd-related files. Should be mounted so that mod installs are persisted between container runs/restarts |
| /ark              | Directory that will contain the server files, config files, logs and backups. More information below                                            |

### Subdirectories of /ark

Inside the `/ark` volume there are several directories containing server related files:

| Path         | Description                                                                                                                              |
|--------------|------------------------------------------------------------------------------------------------------------------------------------------|
| /ark/backup  | Location of the zipped backups genereated from the `arkmaanger backup` command. Compressed using bz2.                                    |
| /ark/config  | Location of server config files. More information:                                                                                       |
| /ark/log     | Location of the arkmanager and arkserver log files                                                                                       |
| /ark/server  | Location of the server installation performed by `steamcmd`. This will contain the ShooterGame directory and the actual server binaries. |
| /ark/staging | Default directory for staging game and mod updates. Can be changed using in `arkmanager.cfg`                                             |
