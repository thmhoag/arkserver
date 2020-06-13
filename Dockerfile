FROM thmhoag/steamcmd:latest

USER root

RUN apt-get update && \
    apt-get install -y curl cron bzip2 perl-modules lsof libc6-i386 lib32gcc1 sudo

ADD https://github.com/just-containers/s6-overlay/releases/download/v2.0.0.1/s6-overlay-amd64.tar.gz /tmp/
RUN tar xvfz /tmp/s6-overlay-amd64.tar.gz -C /

COPY etc/ /etc/

RUN curl -sL "https://raw.githubusercontent.com/FezVrasta/ark-server-tools/v1.6.52/netinstall.sh" | bash -s steam && \
    ln -s /usr/local/bin/arkmanager /usr/bin/arkmanager

COPY arkmanager/arkmanager.cfg /etc/arkmanager/arkmanager.cfg
COPY arkmanager/instance.cfg /etc/arkmanager/instances/main.cfg
COPY run.sh /home/steam/run.sh
COPY log.sh /home/steam/log.sh
COPY entrypoint.sh /home/steam/entrypoint.sh

RUN mkdir /ark && \
    chown -R steam:steam /home/steam/ /ark

WORKDIR /home/steam

ENV defaultinstance="main" \
    am_ark_SessionName="Ark Server" \
    am_serverMap="TheIsland" \
    am_ark_ServerAdminPassword="k3yb04rdc4t" \
    am_ark_MaxPlayers=70 \
    am_ark_QueryPort=27015 \
    am_ark_Port=7778 \
    am_ark_RCONPort=32330 \
    am_arkwarnminutes=15

VOLUME /ark

ENTRYPOINT [ "./entrypoint.sh" ]
