FROM debian:bookworm AS base

RUN apt update && \
    DEBIAN_FRONTEND=noninteractive apt install -y \
    postfix \
    ssl-cert \
    dovecot-core \
    gettext

RUN apt install -y \
    opendkim \
    opendkim-tools

COPY postfix/ /postfix/
COPY dovecot/ /dovecot/
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

EXPOSE 25/TCP

VOLUME ["/var/spool/postfix", "/etc/postfix", "/etc/dovecot"]

ENTRYPOINT ["/entrypoint.sh"]

CMD cp /etc/resolv.conf /var/spool/postfix/etc/resolv.conf && postfix start-fg
