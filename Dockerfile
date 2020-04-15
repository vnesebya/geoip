############################################################
# Dockerfile to create GeoLite2 Country and City databases
# with automatic weekly updates.
#
# Adapted from tkrs/maxmind-lite2-db and 
# tkrs/maxmind-geoipupdate by Takeru Sato.
############################################################

FROM alpine

MAINTAINER Alex Moskalenko <maintainer@ammonix.ru>

### DOWNLOAD DATABASES

ENV GEOIP_BASE_URL      . 
ENV GEOIP_CNTR_DB       GeoLite2-Country.mmdb
ENV GEOIP_CITY_DB       GeoLite2-City.mmdb
ENV GEOIP_DB_DIR        /usr/local/share/GeoIP
ENV GEOIPUPDATE_VER     "4.2.2"
# Fix for alpine.
ENV GEOIPUPDATE_ARCH    "386"

RUN mkdir -p ${GEOIP_DB_DIR}

VOLUME ${GEOIP_DB_DIR}

# copy geoipupdate settings
COPY GeoIP.conf /usr/local/etc/GeoIP.conf

COPY ./GeoIP2/${GEOIP_CNTR_DB} ${GEOIP_DB_DIR}
COPY ./GeoIP2/${GEOIP_CITY_DB} ${GEOIP_DB_DIR}

# install geoipupdate
RUN BUILD_DEPS='gcc make libc-dev libtool automake autoconf git' \
 && apk --no-cache add curl-dev ${BUILD_DEPS} \
 && apk update \
 && apk add ca-certificates \
 && update-ca-certificates \
 && apk add openssl \
 && wget -O /tmp/geoipupdate.tgz https://github.com/maxmind/geoipupdate/releases/download/v${GEOIPUPDATE_VER}/geoipupdate_${GEOIPUPDATE_VER}_linux_${GEOIPUPDATE_ARCH}.tar.gz \
 && tar -zxpvf /tmp/geoipupdate.tgz -C /opt/ \
 && cp /opt/geoipupdate_${GEOIPUPDATE_VER}_linux_${GEOIPUPDATE_ARCH}/geoipupdate /usr/bin/geoipupdate \
 && apk del --purge ${BUILD_DEPS} \
 && rm -rf /var/cache/apk/* \
 && rm -rf /tmp/geoipupdate.tgz \
 && rm -rf /opt/geoipupdate_${GEOIPUPDATE_VER}_linux_${GEOIPUPDATE_ARCH} 

### CONFIGURE AUTOMATIC UPDATES

# copy crontab for running updates
COPY cronfile /var/spool/cron/crontabs/root

# run crond in foreground
ENTRYPOINT ["crond", "-f"]

# set crond options: log to stderr with log level 8
CMD ["-d", "8"]
