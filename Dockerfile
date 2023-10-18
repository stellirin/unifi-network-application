#
# UniFi Network Application
#
ARG IMAGE_TAG=21
FROM ghcr.io/bell-sw/liberica-openjre-debian:${IMAGE_TAG} as installer

ARG UNIFI_VER=7.5.187
ARG UNIFI_URL=https://dl.ui.com/unifi/${UNIFI_VER}/unifi_sysvinit_all.deb

ARG DEBIAN_FRONTEND=noninteractive

RUN curl -L -o /unifi.deb ${UNIFI_URL} \
    && dpkg --unpack /unifi.deb \
    && rm -rf /unifi.deb

# usr/lib/unifi/lib/ace.jar
# sudo apt-get install binutils xz-utils
# PROTIP: unzip -p usr/lib/unifi/lib/ace.jar logback.xml > logback.new.xml
# PROTIP: unzip -p usr/lib/unifi/lib/ace.jar logback-access.xml > logback-access.new.xml
COPY logback/*.xml /usr/lib/unifi/

FROM ghcr.io/bell-sw/liberica-openjre-debian:${IMAGE_TAG}

ARG UNIFI_USER=10017

# Set the product installation directory
ENV BASEDIR=/usr/lib/unifi \
    DATADIR=/var/lib/unifi \
    LOGDIR=/var/log/unifi \
    RUNDIR=/var/run/unifi

COPY --from=installer ${BASEDIR}/ ${BASEDIR}/

# https://github.com/moby/moby/issues/38710
# Set permissions on folders, add default user to /etc/passwd
RUN useradd -u ${UNIFI_USER} -g root -d /nonexistent -s /usr/sbin/nologin -c unifi -M -N unifi \
 && mkdir -p ${DATADIR} \
 && chmod g=u ${DATADIR} \
 && ln -s ${DATADIR} ${BASEDIR}/data \
 && mkdir -p ${LOGDIR} \
 && chmod g=u ${LOGDIR} \
 && ln -s ${LOGDIR} ${BASEDIR}/logs \
 && mkdir -p ${RUNDIR} \
 && chmod g=u ${RUNDIR} \
 && ln -s ${RUNDIR} ${BASEDIR}/run

COPY scripts/*.sh /

WORKDIR ${BASEDIR}
USER ${UNIFI_USER}:0
ENTRYPOINT ["/entrypoint.sh"]
