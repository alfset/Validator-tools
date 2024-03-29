#!/bin/bash
install_cosmos() {
    echo "Installing Cosmos ($NETWORK_TYPE)..."
}

install_osmosis() {
    echo "Installing Osmosis ($NETWORK_TYPE)..."
}

install_planq() {
   echo "Installing Planq ($NETWORK_TYPE)..."
    
   
    if [ "$NETWORK_TYPE" == "mainnet" ]; then
        PLANQ_CHAIN_ID="planq_7070-2" 
        GENESIS_FILE_URL="https://path.to/mainnet/genesis.json" 
       
    else
        echo "not supported yet "
        exit 1
    fi

echo "Still Preparing"
echo "=================================================="
echo -e "\033[0;35m"
echo " ░█████╗░░█████╗░███╗░░░███╗██╗░░░██╗███╗░░██╗██╗████████╗██╗░░░██╗░░░░░░███╗░░██╗░█████╗░██████╗░███████╗░██████╗";
echo " ██╔══██╗██╔══██╗████╗░████║██║░░░██║████╗░██║██║╚══██╔══╝╚██╗░██╔╝░░░░░░████╗░██║██╔══██╗██╔══██╗██╔════╝██╔════╝";
echo " ██║░░╚═╝██║░░██║██╔████╔██║██║░░░██║██╔██╗██║██║░░░██║░░░░╚████╔╝░█████╗██╔██╗██║██║░░██║██║░░██║█████╗░░╚█████╗░";
echo " ██║░░██╗██║░░██║██║╚██╔╝██║██║░░░██║██║╚████║██║░░░██║░░░░░╚██╔╝░░╚════╝██║╚████║██║░░██║██║░░██║██╔══╝░░░╚═══██╗";
echo " ╚█████╔╝╚█████╔╝██║░╚═╝░██║╚██████╔╝██║░╚███║██║░░░██║░░░░░░██║░░░░░░░░░██║░╚███║╚█████╔╝██████╔╝███████╗██████╔╝";
echo " ░╚════╝░░╚════╝░╚═╝░░░░░╚═╝░╚═════╝░╚═╝░░╚══╝╚═╝░░░╚═╝░░░░░░╚═╝░░░░░░░░░╚═╝░░╚══╝░╚════╝░╚═════╝░╚══════╝╚═════╝";
echo -e "\e[0m"
echo "=================================================="



sleep 2

# set vars
if [ ! $NODENAME ]; then
	read -p "Enter node name: " NODENAME
	echo 'export NODENAME='$NODENAME >> $HOME/.bash_profile
fi
PLANQ_PORT=33
if [ ! $WALLET ]; then
	echo "export WALLET=wallet" >> $HOME/.bash_profile
fi
echo "export PLANQ_PORT=${PLANQ_PORT}" >> $HOME/.bash_profile
source $HOME/.bash_profile
echo "Chain ID: $PLANQ_CHAIN_ID"
echo '================================================='
echo -e "Your node name: \e[1m\e[32m$NODENAME\e[0m"
echo -e "Your wallet name: \e[1m\e[32m$WALLET\e[0m"
echo -e "Your chain name: \e[1m\e[32m$PLANQ_CHAIN_ID\e[0m"
echo -e "Your planq port: \e[1m\e[32m$PLANQ_PORT\e[0m"
echo '================================================='
sleep 2

echo -e "\e[1m\e[32m1. Updating packages... \e[0m" && sleep 1
# update
sudo apt update && sudo apt upgrade -y

echo -e "\e[1m\e[32m2. Installing dependencies... \e[0m" && sleep 1
# packages
sudo apt install curl tar wget clang pkg-config libssl-dev jq build-essential bsdmainutils git make ncdu gcc git jq chrony liblz4-tool -y

# install go
sudo rm -rf /usr/local/go
curl -Ls https://go.dev/dl/go1.19.5.linux-amd64.tar.gz | sudo tar -xzf - -C /usr/local
eval $(echo 'export PATH=$PATH:/usr/local/go/bin' | sudo tee /etc/profile.d/golang.sh)
eval $(echo 'export PATH=$PATH:$HOME/go/bin' | tee -a $HOME/.profile)
go version

echo -e "\e[1m\e[32m3. Downloading and building binaries... \e[0m" && sleep 1
# download binary
cd $HOME
git clone https://github.com/planq-network/planq.git
cd planq
git fetch
git checkout v1.0.3
make install

# config
planqd config chain-id $PLANQ_CHAIN_ID
planqd config keyring-backend os
planqd config node tcp://localhost:${PLANQ_PORT}657

# init
planqd init $NODENAME --chain-id $PLANQ_CHAIN_ID

# download genesis and addrbook
wget -qO $HOME/.planqd/config/genesis.json "https://raw.githubusercontent.com/planq-network/networks/main/mainnet/genesis.json"
wget -O $HOME/.planqd/config/addrbook.json "https://raw.githubusercontent.com/nodexcapital/testnet/main/planq/addrbook.json"

# set peers, gas prices and seeds
sed -i.bak -e "s/^minimum-gas-prices *=.*/minimum-gas-prices = \"0.0aplanq\"/;" ~/.planqd/config/app.toml
seeds=`curl -sL https://raw.githubusercontent.com/planq-network/networks/main/mainnet/seeds.txt | awk '{print $1}' | paste -s -d, -`
sed -i.bak -e "s/^seeds =.*/seeds = \"$seeds\"/" ~/.planqd/config/config.toml
sed -i 's/max_num_inbound_peers =.*/max_num_inbound_peers = 100/g' $HOME/.planqd/config/config.toml
sed -i 's/max_num_outbound_peers =.*/max_num_outbound_peers = 100/g' $HOME/.planqd/config/config.toml

# set custom ports
sed -i.bak -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:33658\"%; s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://127.0.0.1:33657\"%; s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:33060\"%; s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:33656\"%; s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":33660\"%" $HOME/.planqd/config/config.toml
sed -i.bak -e "s%^address = \"tcp://0.0.0.0:1317\"%address = \"tcp://0.0.0.0:33317\"%; s%^address = \":8080\"%address = \":33080\"%; s%^address = \"0.0.0.0:9090\"%address = \"0.0.0.0:33090\"%; s%^address = \"0.0.0.0:9091\"%address = \"0.0.0.0:33091\"%" $HOME/.planqd/config/app.toml


# config pruning
pruning="custom"
pruning_keep_recent="100"
pruning_keep_every="0"
pruning_interval="10"
sed -i -e "s/^pruning *=.*/pruning = \"$pruning\"/" $HOME/.planqd/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"$pruning_keep_recent\"/" $HOME/.planqd/config/app.toml
sed -i -e "s/^pruning-keep-every *=.*/pruning-keep-every = \"$pruning_keep_every\"/" $HOME/.planqd/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"$pruning_interval\"/" $HOME/.planqd/config/app.toml

#set null indexer
indexer="null" && \
sed -i -e "s/^indexer *=.*/indexer = \"$indexer\"/" $HOME/.planqd/config/config.toml

#reset
planqd tendermint unsafe-reset-all --home $HOME/.planqd

echo -e "\e[1m\e[32m4. Starting service... \e[0m" && sleep 1
# create service
sudo tee /etc/systemd/system/planqd.service > /dev/null <<EOF
[Unit]
Description=planqd
After=network-online.target
[Service]
User=$USER
ExecStart=$(which planqd) start
Restart=on-failure
RestartSec=3
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

# start service
sudo systemctl daemon-reload
sudo systemctl enable planqd
sudo systemctl restart planqd && sudo journalctl -u planqd -f -o cat

echo '=============== SETUP FINISHED ==================='
echo -e 'To check logs: \e[1m\e[32mjournalctl -u planqd -f -o cat\e[0m'

}

install_oraichain() {
    echo "Installing Oraichain ($NETWORK_TYPE)..."
   
}

install_celestia() {
    echo "Installing Celestia ($NETWORK_TYPE)..."
    
}


install_blockchains() {
    case $choice in
        1)
            install_cosmos
            ;;
        2)
            install_osmosis
            ;;
        3)
            install_planq
            ;;
        4)
            install_oraichain
            ;;
        5)
            install_celestia
            ;;
        *)
            echo "Invalid choice. Exiting..."
            exit 1
            ;;
    esac
}

echo "Which network type would you like to install?"
echo "1) Mainnet"
echo "2) Testnet"
read -p "Enter your choice (1-2): " network_choice

NETWORK_TYPE="mainnet" 
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
