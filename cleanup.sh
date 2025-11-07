#!/usr/bin/env bash

set -e
DIR=$(realpath $0) && DIR=${DIR%/*}
cd $DIR
set -x

nix-collect-garbage -d
journalctl --vacuum-time=7d
rm -rf ~/.cache/nix
exec nix store gc
