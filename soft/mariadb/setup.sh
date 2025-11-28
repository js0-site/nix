#!/usr/bin/env bash

DIR=$(realpath $0) && DIR=${DIR%/*}

set -ex

# apt-get install -y cmake bison libjemalloc-dev libzstd-dev liblz4-dev libcurl4-gnutls-dev jq

cd /tmp

GITDIR=$(curl -sS "https://api.github.com/repos/MariaDB/server/releases?per_page=100" | jq -r '.[].tag_name' | grep -v -E 'alpha|beta|rc|RC' | grep -P '^mariadb-\d' | sort -V | tail -n 1)

if [ ! -d "$GITDIR" ]; then
  git clone -b $GITDIR --depth=1 https://github.com/MariaDB/server.git $GITDIR
fi

cd $GITDIR

git submodule init
git submodule update

BASE=/opt/mariadb
unset NIX_ENFORCE_NO_NATIVE
FLAG="-O3 -pipe -march=native -Wno-deprecated-non-prototype"
cmake . \
  -DCMAKE_C_COMPILER=clang \
  -DCMAKE_CXX_COMPILER=clang++ \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_CXX_FLAGS="$FLAG" \
  -DCMAKE_C_FLAGS="$FLAG" \
  -DCMAKE_INSTALL_PREFIX=$BASE \
  -DSYSCONFDIR=/etc/mariadb \
  -DINSTALL_PLUGINDIR=lib/plugin \
  -DWITH_ROCKSDB_ZSTD=ON \
  -DWITH_ROCKSDB_LZ4=ON \
  -DCONNECT_WITH_MYSQL=ON \
  -DSKIP_TESTS=ON \
  -DWITH_READLINE=ON \
  -DTMPDIR=/var/tmp \
  -DPLUGIN_ROCKSDB=YES \
  -DMYSQL_TCP_PORT=3306 \
  -DPLUGIN_PARTITION=STATIC \
  -DWITH_INNOBASE_STORAGE_ENGINE=0 \
  -DWITH_SPIDER_STORAGE_ENGINE=0 \
  -DWITH_MROONGA_STORAGE_ENGINE=0 \
  -DWITH_MYISAM_STORAGE_ENGINE=0 \
  -DPLUGIN_SPHINX=NO \
  -DPLUGIN_TOKUDB=NO \
  -DPLUGIN_AUTH_GSSAPI=NO \
  -DPLUGIN_AUTH_GSSAPI_CLIENT=OFF \
  -DEXTRA_CHARSETS=all \
  -DWITH_SSL=system \
  -DWITH_BOOST=boost \
  -DDEFAULT_CHARSET=utf8mb4 \
  -DDEFAULT_COLLATION=utf8mb4_bin \
  -DMYSQL_UNIX_ADDR=/run/mariadb/mariadb.sock \
  -DOWNLOAD_BOOST=1 -DENABLE_DOWNLOADS=1 \
  -DWITH_ROCKSDB_JEMALLOC=yes \
  -DCMAKE_EXE_LINKER_FLAGS='-ljemalloc' \
  -DWITH_SAFEMALLOC=OFF

make -j $(nproc)
make install
