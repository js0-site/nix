#!/usr/bin/env bash

set -e
DIR=$(realpath $0) && DIR=${DIR%/*}
cd $DIR
set -x

./sh/init_git.sh

git pull

nixos-rebuild switch \
  --override-input I path:./nix/vps/conf/$(hostname).nix \
  --flake path:.#I
