#
# UniFi Network Application
#
FROM ibm-semeru-runtimes:open-11-jre-jammy

ARG UNIFI_VER=7.3.83
ARG UNIFI_URL=https://dl.ui.com/unifi/${UNIFI_VER}/unifi_sysvinit_all.deb
ARG UNIFI_USER=10017

ARG DEBIAN_FRONTEND=noninteractive

# Set the product installation directory
ENV BASEDIR=/usr/lib/unifi \
    DATADIR=/var/lib/unifi \
    LOGDIR=/var/log/unifi \
    RUNDIR=/var/run/unifi

RUN curl -L -o /unifi.deb ${UNIFI_URL} \
    && dpkg --unpack /unifi.deb \
    && rm -rf /unifi.deb

# usr/lib/unifi/lib/ace.jar
# sudo apt-get install binutils xz-utils
# PROTIP: unzip -p usr/lib/unifi/lib/ace.jar log4j2.xml > log4j2.new.xml
COPY log4j2.xml /usr/lib/unifi/

COPY scripts/*.sh /

# https://github.com/moby/moby/issues/38710
# Set permissions on folders, add default user to /etc/passwd
RUN echo "unifi:x:${UNIFI_USER}:0:unifi:${BASEDIR}:/usr/sbin/nologin" >> /etc/passwd \
    && mkdir -p ${DATADIR} \
    && chmod g=u ${DATADIR} \
    && ln -s ${DATADIR} ${BASEDIR}/data \
    && mkdir -p ${LOGDIR} \
    && chmod g=u ${LOGDIR} \
    && ln -s ${LOGDIR} ${BASEDIR}/logs \
    && mkdir -p ${RUNDIR} \
    && chmod g=u ${RUNDIR} \
    && ln -s ${RUNDIR} ${BASEDIR}/run

WORKDIR ${BASEDIR}
USER ${UNIFI_USER}:0
ENTRYPOINT ["/entrypoint.sh"]
