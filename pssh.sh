#!/usr/bin/env bash

set -e
DIR=$(realpath $0) && DIR=${DIR%/*}
cd $DIR
set -x

exec pssh -P -H "c1 c2 c3 g0" $@
