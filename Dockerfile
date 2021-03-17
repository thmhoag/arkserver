FROM thmhoag/steamcmd:latest

USER root

RUN apt-get update \
    && apt-get install -y curl cron bzip2 perl-modules lsof libc6-i386 lib32gcc1 sudo \
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/* \
    && rm -rf /var/tmp/*

RUN curl -sL https://git.io/arkmanager | bash -s steam && \
    ln -s /usr/local/bin/arkmanager /usr/bin/arkmanager

COPY arkmanager/arkmanager.cfg /etc/arkmanager/arkmanager.cfg
COPY arkmanager/instance.cfg /etc/arkmanager/instances/main.cfg
COPY run.sh /home/steam/run.sh
COPY log.sh /home/steam/log.sh

RUN mkdir /ark && \
    chown -R steam:steam /home/steam/ /ark

RUN echo "%sudo   ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers && \
    usermod -a -G sudo steam && \
    touch /home/steam/.sudo_as_admin_successful

WORKDIR /home/steam
USER steam

ENV am_ark_SessionName=Ark\ Server \
    am_serverMap=TheIsland \
    am_ark_ServerAdminPassword=k3yb04rdc4t \
#    am_ark_ServerPassword= \
    am_ark_MaxPlayers=70 \
    am_ark_QueryPort=27015 \
    am_ark_Port=7778 \
    am_ark_RCONPort=32330 \
    am_ark_AltSaveDirectoryName=SavedArks \
    am_arkwarnminutes=15 \
    am_arkAutoUpdateOnStart=false
#   am_ark_GameModIds= \
#   am_arkopt_clusterid=mycluster \
#   am_arkflag_crossplay= \
#   am_arkflag_NoTransferFromFiltering= \
#   am_arkflag_servergamelog= \
#   am_arkflag_ForceAllowCaveFlyers= \

ENV VALIDATE_SAVE_EXISTS=false \
    BACKUP_ONSTART=false \
    LOG_RCONCHAT=false \
    # ARKSERVER_SHARED requires to disable staging directory!
#    am_arkStagingDir= \
#    ARKSERVER_SHARED=/arkserver \
    ARKCLUSTER=false

# only mount the steamapps directory
VOLUME /home/steam/.steam/steamapps
VOLUME /ark
# separate server files -> shared between servers in the cluster
VOLUME /arkserver
VOLUME /arkclusters

CMD [ "./run.sh" ]
