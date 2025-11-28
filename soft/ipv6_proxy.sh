#!/usr/bin/env bash

set -e
DIR=$(realpath $0) && DIR=${DIR%/*}
cd $DIR
set -x

cd /tmp

NAME=ipv6_proxy

cd $($DIR/sh/clone_or_pull.sh git@atomgit.com:js0/$NAME.git)

RUSTFLAGS="-C target-cpu=native -C opt-level=3" cargo install --root . --force --path .

cd bin
$DIR/sh/rsync.sh $NAME $NAME /opt/bin
$DIR/sh/restart.sh $NAME
