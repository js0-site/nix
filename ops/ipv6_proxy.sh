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
  cd ipv6_proxy
fi

RUSTFLAGS="-C target-cpu=native -C opt-level=3" cargo install --root /opt --force --path .

$DIR/rsync.sh /opt/bin/ipv6_proxy
