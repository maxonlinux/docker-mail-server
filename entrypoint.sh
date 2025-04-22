#!/bin/sh
set -e

echo "🔧 Rendering config files from templates..."

# Dovecot
echo "Setting up Dovecot..."
cp /dovecot/conf.d/10-auth.conf /etc/dovecot/conf.d/10-auth.conf
cp /dovecot/conf.d/10-master.conf /etc/dovecot/conf.d/10-master.conf

dovecot

# Postfix
echo "Setting up Postfix..."
# Generate main.cf from env vars
envsubst \$MAIL_HOSTNAME,\$MAIL_DOMAIN </postfix/main.cf >/etc/postfix/main.cf
cp /postfix/master.cf /etc/postfix/master.cf

# DKIM key generation
echo "🔐 Generating DKIM key..."
DKIM_SELECTOR="default"
DKIM_DIR="/etc/dkim/$MAIL_DOMAIN"

if [ ! -f "$DKIM_DIR/$DKIM_SELECTOR.private" ]; then
    mkdir -p "$DKIM_DIR"
    opendkim-genkey -b 1024 -D "$DKIM_DIR" -d "$MAIL_DOMAIN" -s "$DKIM_SELECTOR"
    echo "📁 DKIM key generated at $DKIM_DIR"

    # Read the DKIM TXT file to extract the value of p
    input=$(cat "$DKIM_DIR/$DKIM_SELECTOR.txt")

    # Extract the values of v, h, k, and p
    v=$(echo "$input" | grep -oP 'v=\K[^;]*')
    h=$(echo "$input" | grep -oP 'h=\K[^;]*')
    k=$(echo "$input" | grep -oP 'k=\K[^;]*')
    p=$(echo "$input" | grep -oP 'p=\K[^"]*')

    # Define colors for the output
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    NO_COLOR='\033[0m'

    echo "📤 DNS TXT record to add (selector: $DKIM_SELECTOR):"
    echo ""
    echo "$DKIM_SELECTOR._domainkey.$MAIL_DOMAIN. IN TXT ${YELLOW}\"v=$v; h=$h; k=$k; p=$p\"${NO_COLOR}"
    echo ""
else
    echo "DKIM key already exists, skipping generation."
fi

echo "✅ Configs applied. Starting: $@"
exec "$@"
