#!/usr/bin/env bash

set -e
DIR=$(realpath $0) && DIR=${DIR%/*}
cd $DIR
set -x

if command -v alejandra 2>/dev/null; then
  fd -e nix -x bash -c 'echo -e "\n→ {}" && alejandra {}'
fi

export NIX_CONFIG="extra-experimental-features = nix-command flakes"

if [ ! -d "nix/vps" ]; then
  ./sh/init_git.sh
fi

conf=$(find nix/vps/conf -maxdepth 1 -type f -name '*.nix' | head -n 1)

nix flake check path:. \
  --override-input I path:./$conf --no-build
