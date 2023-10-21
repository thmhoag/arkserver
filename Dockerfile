FROM cm2network/steamcmd
# this finishes some steamcmd first time setup things, so that we don't have to run them everytime we start the container
# ,originally done by old init parent container
RUN /home/steam/steamcmd/steamcmd.sh +quit
LABEL maintainer="https://github.com/Gornoka"
LABEL org.opencontainers.image.source="https://github.com/Gornoka/arkserver"
LABEL org.opencontainers.image.documentation="https://github.com/Gornoka/arkserver"
LABEL org.opencontainers.image.url="https://github.com/Gornoka/arkserver"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.description="Steam CMD based ark server with arkmanager and ark-server-tools"

USER root
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y perl-modules \
    curl \
    lsof \
    libc6-i386 \
    libgcc1 \
    bzip2 \
    dos2unix \
    sudo \
    findutils \
    perl\
    rsync\
    sed\
    tar\
    cron

COPY ark-server-tools ./ark-server-tools-install

RUN find . -type f -print0 | xargs -0 dos2unix &&\
    cd ./ark-server-tools-install/tools && \
    bash ./install.sh steam && \
    ln -s /usr/local/bin/arkmanager /usr/bin/arkmanager &&\
    ln -s   /home/steam/steamcmd /usr/local/bin &&\
    cd ../.. &&\
    rm -r ./ark-server-tools-install


COPY arkmanager/arkmanager.cfg /etc/arkmanager/arkmanager.cfg
RUN dos2unix  /etc/arkmanager/arkmanager.cfg

COPY arkmanager/instance.cfg /etc/arkmanager/instances/main.cfg
RUN dos2unix /etc/arkmanager/instances/main.cfg

COPY run.sh /home/steam/run.sh
RUN dos2unix /home/steam/run.sh

COPY log.sh /home/steam/log.sh
RUN dos2unix /home/steam/log.sh

RUN mkdir /ark && \
    chown -R steam:steam /home/steam/ /ark

RUN echo "%sudo   ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers && \
    usermod -a -G sudo steam && \
    touch /home/steam/.sudo_as_admin_successful

WORKDIR /home/steam
USER steam

ENV am_ark_SessionName="Ark Server" \
    am_serverMap="TheIsland" \
    am_ark_ServerAdminPassword="k3yb04rdc4t" \
    am_ark_MaxPlayers=70 \
    am_ark_QueryPort=27015 \
    am_ark_Port=7778 \
    am_ark_RCONPort=32330 \
    am_arkwarnminutes=15

VOLUME /ark

CMD [ "./run.sh" ]
