# UniFi Network Application

Build powerful home and enterprise networks with high-performance UniFi Switches, Gateways, and Wireless Access Points. Monitor client usage, set custom traffic rules, and much more.

## Supported tags and respective `Dockerfile` links

- [`latest`](https://github.com/stellirin/unifi-network-application/blob/main/Dockerfile)
- [`8.1, 8.1.113`](https://github.com/stellirin/unifi-network-application/blob/v8.1.113/Dockerfile)

NOTE: `latest` may contain a beta release. If you wish for stability use a specific tag!

## Unsupported tags

- [`8.0, 8.0.28`](https://github.com/stellirin/unifi-network-application/blob/v8.0.28/Dockerfile)
- [`8.0.24`](https://github.com/stellirin/unifi-network-application/blob/v8.0.24/Dockerfile)
- [`8.0.7`](https://github.com/stellirin/unifi-network-application/blob/v8.0.7/Dockerfile)
- [`7.5, 7.5.187`](https://github.com/stellirin/unifi-network-application/blob/v7.5.187/Dockerfile)
- [`7.5.174`](https://github.com/stellirin/unifi-network-application/blob/v7.5.174/Dockerfile)
- [`7.4, 7.4.162`](https://github.com/stellirin/unifi-network-application/blob/v7.4.162/Dockerfile)
- [`7.4.156`](https://github.com/stellirin/unifi-network-application/blob/v7.4.156/Dockerfile)
- [`7.3, 7.3.83`](https://github.com/stellirin/unifi-network-application/blob/v7.3.76/Dockerfile)
- [`7.3.76`](https://github.com/stellirin/unifi-network-application/blob/v7.3.76/Dockerfile)

*Earlier versions were known as UniFi Network Controller*

- [`7.2, 7.2.95`](https://github.com/stellirin/unifi-controller/blob/v7.2.95/Dockerfile)
- [`7.2.92`](https://github.com/stellirin/unifi-controller/blob/v7.2.92/Dockerfile)
- [`7.2.91`](https://github.com/stellirin/unifi-controller/blob/v7.2.91/Dockerfile)
- [`7.1, 7.1.68`](https://github.com/stellirin/unifi-controller/blob/v7.1.68/Dockerfile)
- [`7.1.67`](https://github.com/stellirin/unifi-controller/blob/v7.1.67/Dockerfile)
- [`7.1.66`](https://github.com/stellirin/unifi-controller/blob/v7.1.66/Dockerfile)
- [`7.1.65`](https://github.com/stellirin/unifi-controller/blob/v7.1.65/Dockerfile)
- [`7.1.61`](https://github.com/stellirin/unifi-controller/blob/v7.1.61/Dockerfile)
- [`7.0, 7.0.25`](https://github.com/stellirin/unifi-controller/blob/v7.0.25/Dockerfile)
- [`7.0.23`](https://github.com/stellirin/unifi-controller/blob/v7.0.23/Dockerfile)
- [`6.5, 6.5.55`](https://github.com/stellirin/unifi-controller/blob/v6.5.55/Dockerfile)
- [`6.5.54`](https://github.com/stellirin/unifi-controller/blob/v6.5.54/Dockerfile)
- [`6.4, 6.4.54`](https://github.com/stellirin/unifi-controller/blob/v6.4.54/Dockerfile)
- [`6.2, 6.2.26`](https://github.com/stellirin/unifi-controller/blob/v6.2.26/Dockerfile)
- [`6.2.25`](https://github.com/stellirin/unifi-controller/blob/v6.2.25/Dockerfile)
- [`6.2.23`](https://github.com/stellirin/unifi-controller/blob/v6.2.23/Dockerfile)

## Quick reference

- **Where to get help**: [The UniFi Community Forums](https://community.ui.com/)
- **Where to file issues**: [https://github.com/stellirin/unifi-network-application/issues](https://github.com/stellirin/unifi-network-application/issues)
- **Maintained by**: [Adam Farden](https://github.com/stellirin/unifi-network-application)
- **Supported architectures**: `amd64`

## Disclaimer

This project is not an official container image, nor is it associated with Ubiquiti in any way. It was created by reverse engineering the original UniFi scripts.

Motivation for this project comes from the limitations of the source DEB. Specifically, the DEB is restricted to use obsolete versions of MongoDB because of how the UniFi scripts connect to a locally installed DB. However, UniFi runs perfectly fine with newer versions of MongoDB (currently tested up to v7.0) when connecting to a 'remote' MongoDB installation (i.e. via URI instead of socket).

By default, the container will generate untrusted TLS certificates. This container can also use trusted certificates, for example from Cert Manager or Let's Encrypt. The container will also watch any provided certificates for changes and trigger a restart.

### **TODO**

- Aarch64 for Raspberry Pi

## How to use this image

This container image must be used in conjunction with an existing MongoDB installation. Despite the DEB provided by Ubiquiti being limited to MongoDB 3.6, the UniFi Network Application works fine with newer versions of MongoDB (currently tested up to v7.0).

The simplest method is to use a MongoDB container image. See the [examples folder](https://github.com/stellirin/unifi-network-application/tree/main/examples) for tested methods of running this image.

### Environment Variables

When you start the image, you can adjust the initialization of the instance by passing one or more environment variables.

#### `MONGO_DB_HOST`

Host name of the MongoDB installation.

Default value is `localhost`.

#### `MONGO_DB_PORT`

Port of the MongoDB installation.

Default value is `27017`.

#### `MONGO_DB_NAME`

The database name on the MongoDB installation.

Default value is `unifi`.

#### `MONGO_DB_USER`

Username for authentication on the MongoDB installation.

No default value.

#### `MONGO_DB_PASS`

Password for authentication on the MongoDB installation.

No default value.

#### `MONGO_DB_ARGS`

Additional MongoDB connection arguments.

No default value.

#### `MONGO_DB_URI`

Full URI for the MongoDB installation. For more complex installations. It can be a single host or multiple hosts in a Replica Set.

Default value will be generated as `mongodb://localhost:27017` unless other MongoDB variables are specified above.

#### `MONGO_DB_STAT_URI`

Full URI to the MongoDB stat installation. For more complex installations. It can be a single host or multiple hosts in a Replica Set.

Default is to take the same value as `MONGO_DB_URI`.

#### `UNIFI_HTTPS_PORT`

The port used for the application UI. By default, a container runs without the required privileges to bind to the default HTTPS port. If your container runs with privileges you can change this to use port `443`.

Typically port `443` is achieved at the container platform level (bind external port `443` to internal port `8443`) but this is useful if you are using Docker with `--network="host"` and `--cap-add="NET_BIND_SERVICE"`.

Default value is `8443`.

#### `UNIFI_CA_CERTIFICATE`

The path to a ca certificate that is used for TLS connections to the UI. If no value is supplied then UniFi will generate an untrusted certificate for testing purposes.

No default value.

#### `UNIFI_TLS_CERTIFICATE`

The path to a tls certificate that is used for TLS connections to the UI. If no value is supplied then UniFi will generate an untrusted certificate for testing purposes.

No default value.

#### `UNIFI_TLS_FULLCHAIN`

The path to a full chain certificate that is used for TLS connections to the UI. If no value is supplied then UniFi will generate an untrusted certificate for testing purposes.

No default value.

#### `UNIFI_TLS_PRIVKEY`

The path to a private key that is used for TLS connections to the UI. If no value is supplied then UniFi will generate an untrusted certificate for testing purposes.

No default value.

#### `UNIFI_PKCS12_KEYSTORE`

The path to a PKCS12 keystore that is used for TLS connections to the UI. If no value is supplied then UniFi will generate an untrusted certificate for testing purposes.

The keystore must have the password `unifi`.

No default value.

### Advanced Environment Variables

#### `JAVA_ENTROPY_GATHER_DEVICE`

Provide an alternative source of randomness. Java will use `/dev/random` on some linux systems, which is a blocking function and may cause slowdowns. A good alternative is to use `/dev/./urandom` which will not block.

No default value.

#### `UNIFI_JVM_EXTRA_OPTS`

Provide additional JVM options.

No default value.

### Container Secrets

As an alternative to passing sensitive information via environment variables, `_FILE` may be appended to some of the previously listed environment variables, causing the initialization script to load the values for those variables from files present in the container. In particular, this can be used to load passwords from secrets stored in `/run/secrets/<secret_name>` files. For example:

```sh
docker run --name unifi-network-application -e MONGO_DB_PASS_FILE=/run/secrets/mongo-db-password -d stellirin/unifi-network-application:latest
```

Currently, this is only supported for `MONGO_DB_HOST`, `MONGO_DB_PORT`, `MONGO_DB_NAME`, `MONGO_DB_USER`, `MONGO_DB_PASS`, `MONGO_DB_URI`, and `MONGO_DB_STAT_URI`.
