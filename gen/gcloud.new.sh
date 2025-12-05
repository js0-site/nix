#!/usr/bin/env bash

set -e
DIR=$(realpath $0) && DIR=${DIR%/*}
cd $DIR
if [ -z "$1" ]; then
  echo "$0 <NAME>"
  exit 1
fi

NAME=$1
set -x

gcloud compute instances create $NAME \
  --metadata=ssh-keys="root:$(cat $(dirname $DIR)/nix/vps/ssh/id_ed25519.pub | tr -d '\n' | xargs)" \
  --zone=us-west1-c \
  --machine-type=e2-small \
  --no-shielded-vtpm \
  --no-shielded-integrity-monitoring \
  --boot-disk-size=30GB \
  --boot-disk-type=pd-standard \
  --image-family=ubuntu-minimal-2404-lts-amd64 \
  --image-project=ubuntu-os-cloud \
  --network-interface=network=default,subnet=default,network-tier=STANDARD \
  --tags=allopen

if ! gcloud compute firewall-rules describe allopen &>/dev/null; then
  echo "Creating firewall rule 'allopen'."
  gcloud compute firewall-rules create allopen \
    --direction=INGRESS \
    --action=ALLOW \
    --rules=tcp:0-65535,udp:0-65535,icmp \
    --source-ranges=0.0.0.0/0 \
    --target-tags=allopen \
    --priority=1000
fi

./vps.sh
