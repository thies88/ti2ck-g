# Runtime stage
FROM 1-base-ubuntu:focal

#Env vars
ARG BUILD_DATE
ARG VERSION
LABEL build_version="version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="Thies88"

#Define install variables
ARG APT_DEPS="wget grafana telegraf"
# to read snmp, add to deps: inetutils-ping snmp snmp-mibs-downloader
ENV APP_DEBUGMODE=0

ENV INFLUXDB_VERSION="2.1.1" \
INFLUX_CLI_VERSION="2.2.0" \
#INFLUX_BUCKET="" \
#INFLUXDB_USERNAME="" \
#INFLUXDB_PASSWORD="" \
DOCKER_INFLUXDB_INIT_MODE=setup \
DOCKER_INFLUXDB_INIT_USERNAME=admin \
DOCKER_INFLUXDB_INIT_PASSWORD=changeme \
DOCKER_INFLUXDB_INIT_ORG=initorg \
DOCKER_INFLUXDB_INIT_BUCKET=telegraf \
DOCKER_INFLUXDB_INIT_ADMIN_TOKEN=Hr0j1gyIweWHFLUg70C1_fK4IZ3YFXKtLahSh7FeuOmaYKqyGI4ljy0cqG0hvhPUIklQrN_sRqgaIXhUlaJ-mg== \
DOCKER_INFLUXDB_INIT_RETENTION=0s \
DOCKER_INFLUXDB_INIT_CLI_CONFIG_NAME=default \
INFLUXD_INIT_PORT=9999 \
INFLUXD_HTTP_BIND_ADDRESS=:8086 \
INFLUXD_TLS_CERT=/config/keys/cert.crt \
INFLUXD_TLS_KEY=/config/keys/cert.key \
INFLUXD_TLS_MIN_VERSION=1.2 \
INFLUXD_TLS_STRICT_CIPHERS=true \
INFLUXD_STORAGE_VALIDATE_KEYS=true \
INFLUXD_REPORTING_DISABLED=true \
INFLUXD_PROFILING_DISABLED=true \
INFLUXD_LOG_LEVEL=ERROR \
INFLUXD_CONFIG_PATH=/config/influxdbv2 \
INFLUXD_BOLT_PATH=/config/influxdbv2/influxd.bolt \
INFLUXD_ENGINE_PATH=/config/influxdbv2/engine

ENV HOST="0.0.0.0"

# @change: remember to also edit /etc/services.d/appname/run if needed
ENV APP1="influxd --tls-cert ${INFLUXD_TLS_CERT} --tls-key ${INFLUXD_TLS_KEY} --reporting-disabled"
ENV APP2="telegraf --config /config/telegraf/telegraf.conf --config-directory /config/telegraf/telegraf.d --pidfile /config/telegraf/telegraf.pid"
ENV APP3="grafana-server -config /config/grafana/conf/grafana.ini -homepath /config/grafana -pidfile /config/grafana/grafana.pid"
ENV LOG=""

RUN \
 echo "**** install application and needed packages ****" && \
 echo "deb https://packages.grafana.com/oss/deb stable main" > /etc/apt/sources.list.d/grafana.list && \
 curl -o /tmp/gpg.key https://packages.grafana.com/gpg.key && \
 apt-key add /tmp/gpg.key && \
 echo "deb https://repos.influxdata.com/ubuntu ${REL} stable" > /etc/apt/sources.list.d/influxdb.list && \
 curl -o /tmp/influxdb.key https://repos.influxdata.com/influxdb.key && \
 apt-key add /tmp/influxdb.key && \
 apt-get update && \
 apt-get install -y --no-install-recommends \
	${APT_DEPS} && \
 echo "**** install influxd ****" && \
 curl -s https://repos.influxdata.com/influxdb2.key | gpg --import - && \
 wget --no-verbose https://dl.influxdata.com/influxdb/releases/influxdb2-${INFLUXDB_VERSION}-linux-${ARCH}.tar.gz.asc && \
 wget --no-verbose https://dl.influxdata.com/influxdb/releases/influxdb2-${INFLUXDB_VERSION}-linux-${ARCH}.tar.gz && \
 gpg --batch --keyserver keys.openpgp.org --recv-keys 8C2D403D3C3BDB81A4C27C883C3E4B7317FFE40A && \ 
 gpg --batch --verify influxdb2-${INFLUXDB_VERSION}-linux-${ARCH}.tar.gz.asc influxdb2-${INFLUXDB_VERSION}-linux-${ARCH}.tar.gz && \
 tar xzf influxdb2-${INFLUXDB_VERSION}-linux-${ARCH}.tar.gz && \
 cp influxdb2-${INFLUXDB_VERSION}-linux-${ARCH}/influx* /usr/local/bin/ && \
 rm -rf "$GNUPGHOME" influxdb2.key influxdb2-${INFLUXDB_VERSION}-linux-${ARCH}* && \
 influxd version && \
 echo "**** install influx-cli ****" && \
 wget --no-verbose https://dl.influxdata.com/influxdb/releases/influxdb2-client-${INFLUX_CLI_VERSION}-linux-amd64.tar.gz && \
 tar xvzf influxdb2-client-${INFLUX_CLI_VERSION}-linux-${ARCH}.tar.gz && \
 cp influxdb2-client-${INFLUX_CLI_VERSION}-linux-${ARCH}/influx* /usr/local/bin/ && \
echo "**** cleanup ****" && \
rm -rf "$GNUPGHOME" influxdb2.key influxdb2-${INFLUXDB_VERSION}-linux-${ARCH}* influxdb2-${INFLUX_CLI_VERSION}-linux-${ARCH}/influx* && \
apt-get autoremove -y --purge wget curl && \
apt-get clean && \
 rm -rf \
	/tmp/* \
	/var/lib/apt/lists/* \
	/var/cache/apt/* \
	/var/tmp/* \
	/var/log/* \
	/usr/share/doc/* \
	/usr/share/info/* \
	/var/cache/debconf/* \
	/usr/share/man/* \
	/etc/telegraf \
	/etc/influxdb \
	/etc/grafana \
	/etc/default/grafana-server \
	&& touch /etc/default/grafana-server
	
# add local files
COPY root/ /

VOLUME ["/config"]

# ickg # 9092/tcp # kapacitor Chronograf: 8888/tcp
EXPOSE 8086/tcp 3000/tcp 9999/tcp

ENTRYPOINT ["/init"]
