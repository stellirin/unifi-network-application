#!/bin/bash

# usage: file_env VAR [DEFAULT]
#    ie: file_env 'XYZ_DB_PASSWORD' 'example'
# (will allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of
#  "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature)
file_env() {
    local var="$1"
    local fileVar="${var}_FILE"
    local def="${2:-}"
    if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
        echo >&2 "ERROR: both $var and $fileVar are set but are exclusive"
        exit 1
    fi
    local val="$def"
    if [ "${!var:-}" ]; then
        val="${!var}"
    elif [ "${!fileVar:-}" ]; then
        val="$(< "${!fileVar}")"
    fi
    export "$var"="$val"
    unset "$fileVar"
}

# Configure TLS
set_tls_keystore() {
    if [ -n "${UNIFI_CA_CERTIFICATE}" ] && [ -n "${UNIFI_TLS_CERTIFICATE}" ]
    then
        if [ ! -f "${UNIFI_CA_CERTIFICATE}" ]
        then
            echo "ERROR: path to CA certificate supplied but file not found"
            exit 1
        fi

        if [ ! -f "${UNIFI_TLS_CERTIFICATE}" ]
        then
            echo "ERROR: path to TLS certificate supplied but file not found"
            exit 1
        fi

        echo "INFO: creating intermediate TLS full chain certificate"
        cat "${UNIFI_TLS_CERTIFICATE}" > /tmp/fullchain.pem
        cat "${UNIFI_CA_CERTIFICATE}" >> /tmp/fullchain.pem

        UNIFI_TLS_FULLCHAIN=/tmp/fullchain.pem
    fi

    if [ -n "${UNIFI_TLS_FULLCHAIN}" ] && [ -n "${UNIFI_TLS_PRIVKEY}" ]
    then
        if [ ! -f "${UNIFI_TLS_FULLCHAIN}" ]
        then
            echo "ERROR: path to full chain of TLS certificates supplied but file not found"
            exit 1
        fi

        if [ ! -f "${UNIFI_TLS_PRIVKEY}" ]
        then
            echo "ERROR: path to TLS private key supplied but file not found"
            exit 1
        fi

        echo "INFO: creating intermediate PKCS12 keystore"
        openssl pkcs12 \
            -export \
            -in ${UNIFI_TLS_FULLCHAIN} \
            -inkey ${UNIFI_TLS_PRIVKEY} \
            -out /tmp/keystore.p12 \
            -name unifi \
            -password pass:unifi

        UNIFI_PKCS12_KEYSTORE=/tmp/keystore.p12
    fi

    if [ -n "${UNIFI_PKCS12_KEYSTORE}" ]
    then
        if [ ! -f "${UNIFI_PKCS12_KEYSTORE}" ]
        then
            echo "ERROR: path to intermediate PKCS12 keystore supplied but file not found"
            exit 1
        fi

        rm -f /var/lib/unifi/keystore

        echo "INFO: creating final TLS keystore"
        keytool \
            -noprompt \
            -importkeystore \
            -srckeystore ${UNIFI_PKCS12_KEYSTORE} \
            -srcstoretype PKCS12 \
            -srcstorepass unifi \
            -destkeystore /var/lib/unifi/keystore \
            -deststorepass aircontrolenterprise \
            -destkeypass aircontrolenterprise \
            -alias unifi

        if [ ! -f "/var/lib/unifi/keystore" ]
        then
            echo "ERROR: final TLS keystore not created"
            exit 1
        fi

        echo "INFO: final TLS keystore created"

        # Certificates installed, watch for changes
        /certwatch.sh &
    fi
}

# Set up the UniFi system properties
set_system_property() {
    property=$(echo $1 | cut -d '=' -f 1)
    value=$(echo $1 | cut -d '=' -f 2-)

    # Initialize property file on first start
    property_file="${DATADIR}/system.properties"
    touch ${property_file}

    # Test if value is empty
    if [ -z "${value}" ]
    then
        # Fully remove empty property
        sed -i -r "s|^${property}.*$||g" ${property_file}
    else
        # Test if property is already set
        if grep -q ^"${property}" "${property_file}"
        then
            # Replace value of existing property
            sed -i -r "s|^${property}.*$|${property}=${value}|g" ${property_file}
        else
            # Append new property
            echo "${property}=${value}" >>  ${property_file}
        fi
    fi
}

JVM_EXTRA_OPTS=
JVM_MAX_HEAP_SIZE=${JVM_MAX_HEAP_SIZE:-"1024M"}

# Set up the UniFi JVM options
set_jvm_extra_opts() {
    option=$(echo $1 | cut -d '=' -f 1)
    value=$(echo $1 | cut -d '=' -f 2-)

    JVM_EXTRA_OPTS="${JVM_EXTRA_OPTS} -D${option}=${value}"
}

UNIFI_JVM_OPTS="-XX:+UseParallelGC -XX:+ExitOnOutOfMemoryError -XX:+CrashOnOutOfMemoryError -XX:ErrorFile=/usr/lib/unifi/logs/unifi_crash.log -Xlog:gc:logs/gc.log:time:filecount=2,filesize=5M"
UNIFI_JVM_ADD_OPENS="--add-opens=java.base/java.io=ALL-UNNAMED --add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/java.time=ALL-UNNAMED --add-opens=java.base/sun.security.util=ALL-UNNAMED --add-opens=java.rmi/sun.rmi.transport=ALL-UNNAMED"

# Start UniFi
unifi_start() {
    JVM_OPTS="-Xmx${JVM_MAX_HEAP_SIZE} ${UNIFI_JVM_OPTS} ${UNIFI_JVM_ADD_OPENS} ${JVM_EXTRA_OPTS} ${UNIFI_JVM_EXTRA_OPTS}"
    java ${JVM_OPTS} -jar ${BASEDIR}/lib/ace.jar start &

    # Return code is UniFi PID
    return $!
}

# Stop UniFi
unifi_stop() {
    JVM_OPTS="-Xmx${JVM_MAX_HEAP_SIZE} ${UNIFI_JVM_OPTS} ${UNIFI_JVM_ADD_OPENS} ${JVM_EXTRA_OPTS} ${UNIFI_JVM_EXTRA_OPTS}"
    java ${JVM_OPTS} -jar ${BASEDIR}/lib/ace.jar stop

    # Container exit code is UniFi exit code
    exit $?
}

# Ensure files are written as writable by all users in the root group
umask 002

file_env 'MONGO_DB_USER'
file_env 'MONGO_DB_PASS'
file_env 'MONGO_DB_HOST' 'localhost'
file_env 'MONGO_DB_PORT' '27017'

file_env 'MONGO_DB_NAME' 'unifi'
file_env 'MONGO_DB_URI'

# Generate the MongoDB connection URI
if [ -z "${MONGO_DB_URI}" ]
then
    if [ -n "${MONGO_DB_USER}" ] && [ -n "${MONGO_DB_PASS}" ]
    then
        MONGO_DB_URI=mongodb://${MONGO_DB_USER}:${MONGO_DB_PASS}@${MONGO_DB_HOST}:${MONGO_DB_PORT}
    else
        MONGO_DB_URI=mongodb://${MONGO_DB_HOST}:${MONGO_DB_PORT}
    fi

    if [ -n "${MONGO_DB_ARGS}" ]
    then
        MONGO_DB_URI=${MONGO_DB_URI}/?${MONGO_DB_ARGS}
    fi
fi

file_env 'MONGO_DB_STAT_URI' "${MONGO_DB_URI}"

set_tls_keystore

set_system_property "db.mongo.local=false"
set_system_property "db.mongo.uri=${MONGO_DB_URI}"
set_system_property "statdb.mongo.uri=${MONGO_DB_STAT_URI}"
set_system_property "unifi.db.name=${MONGO_DB_NAME}"

set_system_property "unifi.https.port=${UNIFI_HTTPS_PORT:-"8443"}"
set_system_property "unifi.https.sslEnabledProtocols=+TLSv1.2"
set_system_property "unifi.https.ciphers=TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256,TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA384,TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384,TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_DHE_RSA_WITH_AES_128_CBC_SHA256,TLS_DHE_RSA_WITH_AES_128_GCM_SHA256,TLS_DHE_RSA_WITH_AES_256_CBC_SHA256,TLS_DHE_RSA_WITH_AES_256_GCM_SHA384"

set_jvm_extra_opts "file.encoding=UTF-8"
set_jvm_extra_opts "java.awt.headless=true"
[ -n "${JAVA_ENTROPY_GATHER_DEVICE}" ] && set_jvm_extra_opts "java.security.egd=${JAVA_ENTROPY_GATHER_DEVICE}"
set_jvm_extra_opts "logback.configurationFile=${BASEDIR}/logback.xml"
set_jvm_extra_opts "unifi.datadir=${DATADIR}"
set_jvm_extra_opts "unifi.logdir=${LOGDIR}"
set_jvm_extra_opts "unifi.rundir=${RUNDIR}"

unifi_start
PID=$?

# Try to perform a graceful shutdown
trap unifi_stop INT KILL TERM

# Keep PID 1 alive until UniFi exits
while true
do
    # This doesn't actually kill the process, it just tests if $PID is something that _could_ be killed (meaning: the process actually exists)
    kill -0 $PID
    if [ $? -gt 0 ]
    then
        unifi_stop
    else
        sleep 1
    fi
done
