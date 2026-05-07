#!/bin/bash
# Substitute env vars in hooks.json, then start webhook
envsubst < /etc/webhook/hooks.json.template > /etc/webhook/hooks.json
chmod +x /scripts/*.sh
exec /usr/local/bin/webhook -hooks=/etc/webhook/hooks.json -verbose
