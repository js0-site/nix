#!/usr/bin/env bash

set -e
DIR=$(realpath $0) && DIR=${DIR%/*}
cd $DIR
set -a
. conf.sh
set +a
set -x

bun reconf.js
