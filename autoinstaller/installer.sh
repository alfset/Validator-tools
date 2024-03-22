#!/bin/bash
install_cosmos() {
    echo "Installing Cosmos ($NETWORK_TYPE)..."
    if [ "$NETWORK_TYPE" == "mainnet" ]; then
        GAIA_VERSION="v6.0.0"
        CHAIN_ID="cosmoshub-4"
        GENESIS_JSON_URL="https://raw.githubusercontent.com/cosmos/launch/master/genesis.json"
    else
        GAIA_VERSION="v6.0.0"
        CHAIN_ID="theta-testnet-001"
        GENESIS_JSON_URL="https://path.to/testnet/genesis.json"
    fi
    mkdir -p $HOME/go/bin
    git clone https://github.com/cosmos/gaia.git
    cd gaia
    git checkout $GAIA_VERSION
    make install

    gaiad init your-validator-moniker --chain-id $CHAIN_ID

    curl -s $GENESIS_JSON_URL > $HOME/.gaia/config/genesis.json
    SEEDS="<comma-separated-list-of-seed-nodes>"
    sed -i.bak -e "s/seeds = \"\"/seeds = \"$SEEDS\"/" $HOME/.gaia/config/config.toml

    gaiad start
}
echo "Which network type would you like to install?"
echo "1) Mainnet"
echo "2) Testnet"
read -p "Enter your choice (1-2): " network_choice

NETWORK_TYPE="mainnet" #(Default Network)
if [ "$network_choice" == "2" ]; then
    NETWORK_TYPE="testnet"
fi
echo "Which blockchain node would you like to install?"
echo "1) Cosmos"
echo "2) Osmosis"
echo "3) Planq"
echo "4) Oraichain"
echo "5) Celestia"
read -p "Enter your choice (1-5): " choice
install_blockchains
