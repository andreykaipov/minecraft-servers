#!/bin/sh

set -eu
: "${version?}"

zip="bedrock-server-$version.zip"

cd /opt/minecraft
curl -LO "https://minecraft.azureedge.net/bin-linux/$zip"
busybox unzip -n "$zip"
rm "$zip"

for s in service socket; do
        systemctl enable "minecraft.$s"
        systemctl start "minecraft.$s"
done
