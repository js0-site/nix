#!/usr/bin/env bash

set -e
DIR=$(realpath $0) && DIR=${DIR%/*}
set -a
cd $(dirname $DIR)/nix/vps/disk/etc/kvrocks
. conf.sh
. sentinel.sh
set +a
set -x

NAME=$(basename $0) && NAME=${NAME%.*}

send() {
  $DIR/sh/rsync.sh $NAME $@
}

cd /tmp

rconf() {
  sd "$1" "$2" $NAME.conf
}

curl https://raw.githubusercontent.com/redis/redis/refs/heads/unstable/sentinel.conf -o $NAME.conf

LOGDIR=/var/log/$NAME

rconf '^#?\s*requirepass .*' "requirepass $R_SENTINEL_PASSWORD"
rconf '^#?\s*sentinel auth-pass\s.*' "sentinel auth-pass $R_SENTINEL_NAME $R_PASSWORD"
rconf '^#?\s*sentinel sentinel-pass mymaster\s.*' "sentinel sentinel-pass $R_SENTINEL_PASSWORD"
rconf '^port .*' "port $R_SENTINEL_PORT"
rconf '^dir .*' "dir $LOGDIR"
rconf '^logfile .*' "logfile $LOGDIR/$NAME.log"

# 在Redis哨兵的配置文件中，sentinel monitor命令的最后一个参数是quorum，它表示需要多少个哨兵节点同意才能执行故障转移。如果你有3个哨兵节点，那么你应该将quorum设置为2。这是因为在一个3节点的哨兵集群中，只有当至少2个哨兵节点同意主节点已经掉线时，才会触发故障转移。这样设置可以确保在故障转移过程中，即使有一个哨兵节点出现故障或者网络分区，也不会误判主节点的状态，从而避免不必要的故障转移。

rconf '^sentinel monitor mymaster .*' "sentinel monitor $R_SENTINEL_NAME $R_MASTER_IP $R_PORT 2"
rconf '^protected-mode .*' 'protected-mode no'
rconf "s/mymaster/$R_SENTINEL_NAME/g"

send $NAME.conf /etc

cd $($DIR/clone_or_pull.sh https://github.com/js0-dep/nixos_redis_sentinel.git)
./build.sh
send result/bin/ /opt/bin
