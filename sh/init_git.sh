#!/usr/bin/env bash

set -e
DIR=$(realpath $0) && DIR=${DIR%/*/*}
cd $DIR
set -x

giturl() {
  local GIT_URL=$(git -C $DIR config --get remote.origin.url) && echo ${GIT_URL%.*}
}

cd nix

if [ -d vps ]; then
  cd vps
  git pull
else
  git clone --depth=1 $(giturl).vps.git vps
fi
