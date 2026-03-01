#!/usr/bin/env bash

set -e

if [ -z "$1" ]; then
  echo "❌ $0 git_url"
  exit 1
fi

NAME=$(basename "${1%.git}")

if [ -d "$NAME" ]; then
  cd $NAME
  git pull -q
else
  clone="git clone --depth=1 -q"
  $clone -b dev "$1" || $clone "$1"
fi

echo $NAME
