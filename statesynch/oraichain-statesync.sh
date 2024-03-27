#stoping service
sudo systemctl stop oraid


#add rpc, blockhash, block height, and seed
SNAP_RPC="https://rpc.oraichain.comunitynode.my.id:443"
LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height); \
BLOCK_HEIGHT=$((LATEST_HEIGHT - 2000)); \
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)
sed -i 's/seeds = ""/seeds = "5def5084545f5bf0c8a8b4e7693d90fb43226305@194.163.150.181:11256"/' ~/.oraid/config/config.toml
sed -i.bak -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"|" $HOME/.oraid/config/config.toml

#start service again
sudo systemctl restart oraid && journalctl -fu oraid
