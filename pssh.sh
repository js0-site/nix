#!/usr/bin/env bash

set -e
if [ -z "$1" ]; then
  echo "$0 <cmd>"
  exit 1
fi
DIR=$(realpath $0) && DIR=${DIR%/*}
cd $DIR
set -x

exec pssh -P -H "c1 c2 c3 g0" $@
