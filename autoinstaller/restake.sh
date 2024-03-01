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
if [ ! $MNEMONIC ]; then
        read -p "Enter Mnemonic: " MNEMONIC
        echo 'export MNEMONIC='$MNEMONIC >> $HOME/.bash_profile
fi

if [ ! $VALOPER ]; then
        read -p "Enter Valoper: " VALOPER
        echo 'export VALOPER='$VALOPER >> $HOME/.bash_profile
fi

echo '================================================='
echo -e "Your VALOPER: \e[1m\e[32m$VALOPER\e[0m"
echo '================================================='
sleep 2

# Clone Repository
cd $HOME
git clone https://github.com/eco-stake/restake
cd restake
sudo tee $HOME/restake/.env > /dev/null <<EOF
MNEMONIC=$MNEMONIC
EOF

rm $HOME/restake/src/networks.json
wget -O $HOME/restake/src/networks.json https://raw.githubusercontent.com/alfset/Validator-Auto-Installer/main/networks.json 
sudo tee $HOME/restake/src/networks.json > /dev/null <<EOF
[
  {
    "name": "planq",
    "ownerAddress": "$VALOPER"
  }
]
EOF

git pull
docker compose run --rm app npm install
docker compose build --no-cache

#try running
docker compose run --rm app npm run autostake

#create restake service
sudo tee /etc/systemd/system/restake.service > /dev/null <<EOF
[Unit]
Description=restake service with docker compose
Requires=docker.service
After=docker.service
Wants=restake.timer

[Service]
Type=oneshot
WorkingDirectory=/$HOME/restake
ExecStart=/usr/bin/docker compose run --rm app npm run autostake

[Install]
WantedBy=multi-user.target

EOF

#create timer
sudo tee /etc/systemd/system/restake.timer > /dev/null <<EOF
[Unit]
Description=Restake bot timer

[Timer]
AccuracySec=1min
OnCalendar=*-*-* 21:00:00

[Install]
WantedBy=timers.target
EOF

#Enable Service
sudo systemctl enable restake.service
sudo systemctl enable restake.timer
sudo systemctl start restake.timer && sudo journalctl -u restake.service -f -o cat

echo '=============== SETUP FINISHED ==================='
echo -e 'Please create Pull request on https://github.com/eco-stake/validator-registry'
echo -e 'You will see not operator address in log until your pull request being merge by Eco-stake in validator registry'
echo -e 'To check logs: \e[1m\e[32mjournalctl -fu restake.service \e[0m'
echo -e 'To check timer: \e[1m\e[32mjournalctl -fu restake.timer \e[0m'
