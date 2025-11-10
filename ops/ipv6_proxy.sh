#!/usr/bin/env bash

set -e
DIR=$(realpath $0) && DIR=${DIR%/*}
cd $DIR
set -x

cd /tmp
if [ -d ipv6_proxy ]; then
  cd ipv6_proxy
  git pull
else
  git clone -b dev --depth=1 git@atomgit.com:js0/ipv6_proxy.git
fi

RUSTFLAGS="-C target-cpu=native -C opt-level=3" cargo install --root /opt --force --path .

jq -r '.[]' "$(dirname $DIR)/nix/vps/host.json" | while read host; do
  if [ "$host" != "$HOSTNAME" ]; then
    rsync -avz /opt/bin/ipv6_proxy $host:/opt/bin
  fi
done
