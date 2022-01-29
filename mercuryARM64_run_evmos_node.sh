#!/bin/sh
STATESYNC=${STATESYNC:-0}
VERSION=${VERSION:-0.4.2}
CHAIN=evmos_9000-2
FORCE_RESET=${FORCE_RESET:-0}

echo "-----------------------------------------------------------------------------------"
echo "HELLO THERE! This is one-liner script to install and run your Evmos validator node"
echo "-----------------------------------------------------------------------------------"
echo

(which jq && which sudo && which curl && which wget && which tar ) > /dev/null || \
	(apt update && apt install -y curl wget tar sudo jq)

# Check for ubuntu 20.04
grep -q 'DISTRIB_CODENAME=focal' /etc/lsb-release 2>&1 > /dev/null
if [ $? -ne 0 ]; then
  echo "ERROR! You should run this script on Ubuntu 20.04!"
fi;

#apt update
#apt upgrade -y
#apt install -y curl
service evmosd stop
pkill evmod
rm -f /usr/local/bin/evmosd.bak
mv -f /usr/local/bin/evmosd /usr/bin/evmosd.bak
mkdir /tmp/evmos-tmp
echo Downloading BINARY file
curl -sL https://github.com/tharsis/evmos/releases/download/v${VERSION}/evmos_${VERSION}_Linux_arm64.tar.gz | tar -xzvf - -C /tmp/evmos-tmp
cp /tmp/evmos-tmp/bin/evmosd /usr/local/bin/
chmod +x /usr/local/bin/evmosd
rm -rf /tmp/evmos-tmp

if [ ! -d $HOME/.evmosd -o $FORCE_RESET -gt 0 ]; then
	NODENAME=${1:-`hostname`}

	if [ "x$NODENAME" == "x" ]; then
	 NODENAME=`hostname`
	fi

	echo "Initialize your fresh EVMOS instalation"
	echo "Your node name is: $NODENAME"
	echo ---------------------------------
	echo

	rm -rf $HOME/.evmosd/config/genesis.json

	/usr/local/bin/evmosd init $NODENAME --chain-id $CHAIN

	echo Adding seeds
	SEEDS=`curl -sL https://raw.githubusercontent.com/tharsis/testnets/main/olympus_mons/seeds.txt | awk '{print $1}' | paste -s -d, -`
	sed -i -e "s/^seeds =.*/seeds = \"$SEEDS\"/" ~/.evmosd/config/config.toml
	echo Set empty persistent peers
	#PEERS=`curl -sL https://raw.githubusercontent.com/tharsis/testnets/main/olympus_mons/peers.txt | sort -R | head -n 10 | awk '{print $1}' | paste -s -d, -`
	PEERS=""
	sed -i -e "s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" ~/.evmosd/config/config.toml

	echo Downloading GENESIS file
	curl -sL https://raw.githubusercontent.com/tharsis/testnets/main/olympus_mons/genesis.json > ~/.evmosd/config/genesis.json
	/usr/local/bin/evmosd validate-genesis || exit

	if [ $STATESYNC -gt 0 ]; then
		SNAP_RPC1="http://167.86.86.48:26657" #KuatCapital
		SNAP_RPC2="https://evmos-rpc.mercury-nodes.net:443"
		LATEST_HEIGHT=$(curl -s $SNAP_RPC2/block | jq -r .result.block.header.height);
		BLOCK_HEIGHT=$((LATEST_HEIGHT - 500)); \
		TRUST_HASH=$(curl -s "$SNAP_RPC2/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)

		sed -i.bak -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
			s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC1,$SNAP_RPC2\"| ; \
			s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
			s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"|" $HOME/.evmosd/config/config.toml
	fi

	echo RESET EVMOS DATA
	/usr/local/bin/evmosd unsafe-reset-all
fi

echo Set default chain-id to $CHAIN
/usr/local/bin/evmosd config chain-id $CHAIN

echo Change max inbound and outbound peers in config
sed -i 's/^max_num_inbound_peers =.*/max_num_inbound_peers = 200/' $HOME/.evmosd/config/config.toml
sed -i 's/^max_num_outbound_peers =.*/max_num_outbound_peers = 100/' $HOME/.evmosd/config/config.toml

[ -f /etc/systemd/system/evmosd.service ] || cat > /etc/systemd/system/evmosd.service << EOF
[Unit]
Description=Evmos Validator Node
After=network-online.target
Wants=network-online.target

[Service]
User=$USER
WorkDir=$HOME
ExecStart=/usr/local/bin/evmosd start
Restart=always
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable evmosd
systemctl restart evmosd
echo -n Starting node 5 sec .
for i in 1 2 3 4; do sleep 1; echo -n '.'; done; echo 
systemctl status evmosd

echo "-----------------------------------------------------------------------------------"
echo "DONE!"
echo 
echo "Best Regards! Mercury nodes team"
echo "-----------------------------------------------------------------------------------"
