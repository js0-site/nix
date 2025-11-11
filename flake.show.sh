#!/usr/bin/env bash

set -e
DIR=$(realpath $0) && DIR=${DIR%/*}
cd $DIR
set -x

export NIX_CONFIG="extra-experimental-features = nix-command flakes"

conf=$(find nix/vps/conf -maxdepth 1 -type f -name '*.nix' | head -n 1)

exec nix flake show path:. --override-input I path:./$conf $@
