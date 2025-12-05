#!/usr/bin/env bash

set -e
DIR=$(realpath $0) && DIR=${DIR%/*}
cd $DIR
set -x

cd /tmp

NAME=smtp_srv

rm -rf bin/$NAME
RUSTFLAGS="-C target-cpu=native -C opt-level=3" cargo install $NAME --force --root .

cd bin
$DIR/sh/rsync.sh smtp $NAME /opt/bin
$DIR/sh/restart.sh smtp
