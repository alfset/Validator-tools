#!/bin/bash

TARGET_HEIGHT="18944489"
RPC_ADDR="https://rpc.oraichain.comunitynode.my.id"

sudo apt-get install jq -y

for((;;)); do
 HEIGHT=$(curl -s ${RPC_ADDR}/status | jq -r ."result"."sync_info"."latest_block_height")
  if [[ $HEIGHT -ge $TARGET_HEIGHT ]]; then
  eval $(echo 'export PATH=$PATH:/usr/local/go/bin' | sudo tee /etc/profile.d/golang.sh)
  eval $(echo 'export PATH=$PATH:$HOME/go/bin' | tee -a $HOME/.profile)
  go version
  sudo systemctl stop oraid # check your preffered method to run a node
  cd $HOME
  git clone https://github.com/oraichain/orai
  cd orai/orai
  git checkout v0.41.8
  make install
  echo "building orai"
  cd $HOME
  sudo systemctl restart oraid
  echo "restart"
  break
  else
   echo "$HEIGHT --> $TARGET_HEIGHT"
  fi
 sleep 5
done
