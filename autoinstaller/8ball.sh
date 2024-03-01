#!/bin/bash

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
8ball_PORT=26
if [ ! $WALLET ]; then
	echo "export WALLET=wallet" >> $HOME/.bash_profile
fi
echo "export PLANQ_CHAIN_ID=planq_7070-2" >> $HOME/.bash_profile
echo "export PLANQ_PORT=${PLANQ_PORT}" >> $HOME/.bash_profile
source $HOME/.bash_profile

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
wget https://8ball.info/8ball.tar.gz
tar -xvzf 8ball.tar.gz
sudo chmod +x 8ball
sudo mv 8ball $HOME/go/bin/8ball
rm 8ball.tar.gz

# config

# init
8ball init $NODENAME --chain-id eightball-1

# download genesis and addrbook
wget -O genesis.json https://snapshots.nodeist.net/8ball/genesis.json --inet4-only
mv genesis.json ~/.8ball/config
wget -O addrbook.json https://snapshots.nodeist.net/8ball/addrbook.json --inet4-only
mv addrbook.json ~/.8ball/config


# set peers, gas prices and seeds
PEERS=fca96d0a1d7357afb226a49c4c7d9126118c37e9@one.8ball.info:26656,aa918e17c8066cd3b031f490f0019c1a95afe7e3@two.8ball.info:26656,98b49fea92b266ed8cfb0154028c79f81d16a825@three.8ball.info:26656
sed -i.bak -e "s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.8ball/config/config.toml

# set custom ports
#sed -i.bak -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:33658\"%; s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://127.0.0.1:33657\"%; s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:33060\"%; s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:33656\"%; s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":33660\"%" $HOME/.planqd/config/config.toml
#sed -i.bak -e "s%^address = \"tcp://0.0.0.0:1317\"%address = \"tcp://0.0.0.0:33317\"%; s%^address = \":8080\"%address = \":33080\"%; s%^address = \"0.0.0.0:9090\"%address = \"0.0.0.0:33090\"%; s%^address = \"0.0.0.0:9091\"%address = \"0.0.0.0:33091\"%" $HOME/.planqd/config/app.toml



echo -e "\e[1m\e[32m4. Starting service... \e[0m" && sleep 1
# create service
sudo tee /etc/systemd/system/8balld.service > /dev/null <<EOF
[Unit]
Description=8ball
After=network-online.target
[Service]
User=$USER
ExecStart=$(which 8ball) start
Restart=on-failure
RestartSec=3
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

# start service
sudo systemctl daemon-reload
sudo systemctl enable 8balld
sudo systemctl restart 8balld && sudo journalctl -u 8balld -f -o cat

echo '=============== SETUP FINISHED ==================='
echo -e 'To check logs: \e[1m\e[32mjournalctl -u 8balld -f -o cat\e[0m'
