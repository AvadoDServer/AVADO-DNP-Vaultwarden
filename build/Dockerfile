# Vaultwarden 1.37.5 (Alpine), the official image, pinned by digest.
FROM --platform=linux/amd64 vaultwarden/server:1.37.5-alpine@sha256:bbe684a02d6b0db54256ff88eac9754f4519284a7b26314afc241fd7d0918191

RUN apk add --no-cache nginx openssl

# HTTPS front: the *.my.ava.do certificate, refreshed at start from the box.
RUN mkdir -p /etc/avado/certs \
 && wget -q -O /etc/avado/certs/build.crt http://iso.ava.do/my.ava.do.crt \
 && wget -q -O /etc/avado/certs/build.key http://iso.ava.do/my.ava.do.key \
 && openssl x509 -in /etc/avado/certs/build.crt -noout -subject
COPY avado/ /etc/avado/
RUN chmod +x /etc/avado/*.sh

# Vaultwarden listens on the container's loopback only; nginx serves 80/443.
ENV ROCKET_ADDRESS=127.0.0.1 \
    ROCKET_PORT=8080 \
    DOMAIN=https://vaultwarden.my.ava.do \
    IP_HEADER=X-Real-IP

ENTRYPOINT ["/etc/avado/avado-start.sh"]
CMD ["/start.sh"]
