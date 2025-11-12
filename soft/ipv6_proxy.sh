#!/usr/bin/env bash

set -e
DIR=$(realpath $0) && DIR=${DIR%/*}
cd $DIR
set -x

cd /tmp

cd $($DIR/sh/clone_or_pull.sh git@atomgit.com:js0/ipv6_proxy.git)

RUSTFLAGS="-C target-cpu=native -C opt-level=3" cargo install --root . --force --path .

cd bin
$DIR/sh/rsync.sh ipv6_proxy ipv6_proxy /opt/bin
