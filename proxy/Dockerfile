# syntax=docker/dockerfile:1
#
# nas01-claude-proxy: Squid from Debian's own packages, run as Debian's "proxy"
# user. The config and allowlist are NOT in the image: they are mounted
# read-only from the host at /etc/squid/nas01/.
FROM debian:trixie-slim@sha256:a72b4433de1cf7d6bae0c4cee74d0547f58601a643b3375f070c51600d63b6b2

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get -y upgrade \
 && apt-get install -y --no-install-recommends squid ca-certificates tini \
 && rm -rf /var/lib/apt/lists/*

USER proxy
EXPOSE 3128

ENTRYPOINT ["/usr/bin/tini", "--", "/usr/sbin/squid", "-N", "-f", "/etc/squid/nas01/squid.conf"]
