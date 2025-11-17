#!/usr/bin/env bash

set -e
DIR=$(realpath $0) && DIR=${DIR%/*}
set -a
. $(dirname $DIR)/nix/vps/disk/etc/kvrocks/conf.sh
set +a
set -x

NAME=$(basename $0) && NAME=${NAME%.*}

send() {
  $DIR/sh/rsync.sh $NAME $@
}

TMP=$(mktemp -d)
cleanup() {
  rm -rf $TMP
}
trap cleanup EXIT
cd $TMP
mkdir -p $NAME
cd $NAME
curl https://raw.githubusercontent.com/redis/redis/refs/heads/unstable/sentinel.conf -o conf

rconf() {
  sd "$1" "$2" conf
}

rconf '^#?\s*requirepass .*' "requirepass $R_SENTINEL_PASSWORD"
rconf '^#?\s*sentinel auth-pass\s+<.*' "sentinel auth-pass $R_SENTINEL_NAME $R_PASSWORD"
rconf '^#?\s*sentinel sentinel-pass mymaster\s.*' "sentinel sentinel-pass $R_SENTINEL_PASSWORD"
LOGDIR=/var/log/$NAME
rconf '^dir .*' "dir $LOGDIR"
rconf '^logfile .*' "logfile $LOGDIR/$NAME.log"
rconf '^port .*' "port $R_SENTINEL_PORT"
rconf '^sentinel down-after-milliseconds mymaster .*' "sentinel down-after-milliseconds $R_SENTINEL_NAME 6000"
rconf '^sentinel parallel-syncs mymaster .*' "sentinel parallel-syncs $R_SENTINEL_NAME 2"
rconf '^protected-mode .*' 'protected-mode no'
rconf '^pidfile .*' "pidfile /var/run/$NAME/$NAME.pid"
sed -i '/^sentinel monitor /d' conf

rconf mymaster $R_SENTINEL_NAME
# rconf '^sentinel failover-timeout mymaster .*' "sentinel failover-timeout $R_SENTINEL_NAME 180000"
# 将第一个IP设为monitor（主节点），其余IP设为known-slave
# 在Redis哨兵的配置文件中，sentinel monitor命令的最后一个参数是quorum，它表示需要多少个哨兵节点同意才能执行故障转移。如果你有3个哨兵节点，那么你应该将quorum设置为2。这是因为在一个3节点的哨兵集群中，只有当至少2个哨兵节点同意主节点已经掉线时，才会触发故障转移。这样设置可以确保在故障转移过程中，即使有一个哨兵节点出现故障或者网络分区，也不会误判主节点的状态，从而避免不必要的故障转移。
echo "sentinel monitor $R_SENTINEL_NAME ${KVROCKS_IP_LI%% *} $R_PORT 2" >>conf

cd ..
id $NAME &>/dev/null && chown -R $NAME $NAME
send $NAME /etc

cd $($DIR/sh/clone_or_pull.sh https://github.com/js0-dep/nixos_redis_sentinel.git)
./build.sh
send result/bin/ /opt/bin
