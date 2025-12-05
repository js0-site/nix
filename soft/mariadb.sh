#!/usr/bin/env bash

set -e
DIR=$(realpath $0) && DIR=${DIR%/*}
cd $DIR
set -x

nix-shell -p jq cmake jemalloc zstd lz4 curl git bison ncurses flex libxml2 bzip2 snappy llvmPackages.clang \
  --run ./mariadb/setup.sh
