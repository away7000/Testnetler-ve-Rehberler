#!/bin/bash

echo -e ''
echo -e '\e[40m\e[92m'
echo ' ██████╗ ██╗      █████╗  ██████╗██╗  ██╗ ██████╗ ██╗    ██╗██╗'     
echo ' ██╔══██╗██║     ██╔══██╗██╔════╝██║ ██╔╝██╔═══██╗██║    ██║██║'
echo ' ██████╔╝██║     ███████║██║     █████╔╝ ██║   ██║██║ █╗ ██║██║'    
echo ' ██╔══██╗██║     ██╔══██║██║     ██╔═██╗ ██║   ██║██║███╗██║██║'
echo ' ██████╔╝███████╗██║  ██║╚██████╗██║  ██╗╚██████╔╝╚███╔███╔╝███████╗'
echo ' ╚═════╝ ╚══════╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝ ╚═════╝  ╚══╝╚══╝ ╚══════╝'
echo -e '\e[0m'
echo ''

sleep 2

echo -e "\e[1m\e[32m1. Downloading Libraries.. \e[0m" && sleep 2
# update and upgrade
sudo apt-get update && apt-get upgrade -y
sudo apt-get -y install libssl-dev && apt-get -y install cmake build-essential git wget jq make gcc

echo -e "\e[1m\e[32m2. Creating a Worker Account... \e[0m" && sleep 2
# Account Creation

if [ -f geth-linux-amd64-1.10.23-d901d853 ]; then
	rm -rf geth-linux-amd64-1.10.23-d901d853.tar.gz
	rm -rf geth-linux-amd64-1.10.23-d901d853
fi

wget "https://gethstore.blob.core.windows.net/builds/geth-linux-amd64-1.10.23-d901d853.tar.gz"
tar -xvzf geth-linux-amd64-1.10.23-d901d853.tar.gz

if [ "$(ls /home/vps212/geth-linux-amd64-1.10.23-d901d853/keystore/ | wc -l)" > 1 ]; then
	rm -rf /home/vps212/geth-linux-amd64-1.10.23-d901d853/keystore
	mkdir /home/vps212/geth-linux-amd64-1.10.23-d901d853/keystore
fi


cd $HOME/geth-linux-amd64-1.10.23-d901d853/
./geth account new --keystore ./keystore

sleep 5

sed -i '/UTC/d' g/home/vps212/.bash_profile
sed -i '/PKEY/d' g/home/vps212/.bash_profile
sed -i '/KEY/d' g/home/vps212/.bash_profile
sed -i '/NULINK_KEYSTORE_PASSWORD/d' g/home/vps212/.bash_profile
sed -i '/NULINK_OPERATOR_ETH_PASSWORD/d' g/home/vps212/.bash_profile

UTC="$(ls /home/vps212/geth-linux-amd64-1.10.23-d901d853/keystore/)"
echo "export UTC="$UTC >> g/home/vps212/.bash_profile
PKEY="0x""$(awk -F \" '{print $4}' /home/vps212/geth-linux-amd64-1.10.23-d901d853/keystore/$UTC)"
echo "export PKEY="$PKEY >> g/home/vps212/.bash_profile
KEY="/home/vps212/geth-linux-amd64-1.10.23-d901d853/keystore/"$UTC
echo "export KEY="$KEY >> g/home/vps212/.bash_profile

sleep 2

unset NULINK_KEYSTORE_PASSWORD
unset NULINK_OPERATOR_ETH_PASSWORD

if [ ! $NULINK_KEYSTORE_PASSWORD ]; then
	read -p "create a password for NULINK_KEYSTORE_PASSWORD: " NULINK_KEYSTORE_PASSWORD
	echo 'export NULINK_KEYSTORE_PASSWORD='$NULINK_KEYSTORE_PASSWORD >> g/home/vps212/.bash_profile
fi

if [ ! $NULINK_OPERATOR_ETH_PASSWORD ]; then
	read -p "create a password for NULINK_OPERATOR_ETH_PASSWORD: " NULINK_OPERATOR_ETH_PASSWORD
	echo 'export NULINK_OPERATOR_ETH_PASSWORD='$NULINK_OPERATOR_ETH_PASSWORD >> g/home/vps212/.bash_profile
fi

source g/home/vps212/.bash_profile

echo -e "Your public address: \e[1m\e[32m$PKEY\e[0m"
echo -e "Your path to secret key file: \e[1m\e[32m$KEY\e[0m"
echo -e "Your Nulink Keystore Password: \e[1m\e[32m$NULINK_KEYSTORE_PASSWORD\e[0m"
echo -e "Your Nulink ETH Operator Password: \e[1m\e[32m$NULINK_OPERATOR_ETH_PASSWORD\e[0m"

sleep 3

docker ps -q --filter "name=ursula" | grep -q . && docker kill ursula && docker rm ursula

echo -e "\e[1m\e[32m3. Installing Docker... \e[0m" && sleep 2
# Docker İnstall
cd /root
sudo apt install docker.io -y
sudo systemctl enable --now docker

sleep 2

echo -e "\e[1m\e[32m4. Taking the latest NuLink image... \e[0m" && sleep 2
docker pull nulink/nulink:latest

sleep 2

# Creating a File
cd /root
rm -rf nulink
mkdir nulink

sleep 2

# Adding a secret keye
cp $KEY /home/vps212/nulink
chmod -R 777 /home/vps212/nulink

sleep 3

echo -e "\e[1m\e[32m4. Initializing Node Configuration... \e[0m" && sleep 2
# Initialize Node Configuration
docker run -it --rm \
-p 9151:9151 \
-v /home/vps212/nulink:/code \
-v /home/vps212/nulink:/home/circleci/.local/share/nulink \
-e NULINK_KEYSTORE_PASSWORD \
nulink/nulink nulink ursula init \
--signer keystore:///code/$UTC \
--eth-provider https://data-seed-prebsc-2-s2.binance.org:8545  \
--network horus \
--payment-provider https://data-seed-prebsc-2-s2.binance.org:8545 \
--payment-network bsc_testnet \
--operator-address $PKEY \
--max-gas-price 100

sleep 5

# Starting a Node
docker run --restart on-failure -d \
--name ursula \
-p 9151:9151 \
-v /home/vps212/nulink:/code \
-v /home/vps212/nulink:/home/circleci/.local/share/nulink \
-e NULINK_KEYSTORE_PASSWORD \
-e NULINK_OPERATOR_ETH_PASSWORD \
nulink/nulink nulink ursula run --no-block-until-ready

sleep 3

source g/home/vps212/.bash_profile

echo '----The Installation was Completed Successfully. Good luck... ----'
echo '---- If you have any questions, you can contact me. Discord id: bobo... ----'
