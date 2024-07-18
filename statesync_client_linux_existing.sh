#!/bin/bash
# Based on the work of Joe (Chorus-One) for Microtick - https://github.com/microtick/bounties/tree/main/statesync
# You need config in two peers (avoid seed servers) this values in app.toml:
#     [state-sync]
#     snapshot-interval = 1000
#     snapshot-keep-recent = 10
# Pruning should be fine tuned also, for this testings is set to nothing
#     pruning = "nothing"

# Let's check if JQ tool is installed
FILE=$(which jq)
 if [ -f "$FILE" ]; then
   echo "JQ is present"
 else
   echo "$FILE JQ tool does not exist, install with: sudo apt install jq"
   exit 1
 fi
clear
set -e
echo
echo "Welcome to the StateSync script."
echo "This script will give you the info to configure StateSync in your validator"
echo "You should have a encrypted backup of your wallet keys, your node keys and your validator keys."
echo "Ensure that you can restore your wallet keys if is needed."
echo "Also ensure that bcnad/cosmovisor service is stopped."
echo ""
read -p "ATTENTION! This script will clear the data folder (unsafe-reset-all) & the Address Book PROCEED (y/n)? " -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]]
then
  echo "\nClearing the data folder & P2P Address Book"
  bcnad tendermint unsafe-reset-all --keep-addr-book --home $HOME/.bcna || cosmovisor tendermint unsafe-reset-all --keep-addr-book --home $HOME/.bcna

  NODE1_IP="95.216.242.82"
  RPC1="http://$NODE1_IP"
  P2P_PORT1=36656
  RPC_PORT1=36657

  NODE2_IP="95.216.242.82"
  RPC2="http://$NODE2_IP"
  RPC_PORT2=36657
  P2P_PORT2=36656

  #If you want to use a third StateSync Server...
  #DOMAIN_3=seed1.bitcanna.io     # If you want to use domain names
  #NODE3_IP=$(dig $DOMAIN_1 +short
  #RPC3="http://$NODE3_IP"
  #RPC_PORT3=26657
  #P2P_PORT3=26656

  INTERVAL=1000

  LATEST_HEIGHT=$(curl -s $RPC1:$RPC_PORT1/block | jq -r .result.block.header.height);
  BLOCK_HEIGHT=$((LATEST_HEIGHT - $INTERVAL))

  if [ $BLOCK_HEIGHT -eq 0 ]; then
    echo "Error: Cannot state sync to block 0; Latest block is $LATEST_HEIGHT and must be at least $INTERVAL; wait a few blocks!"
    exit 1
  fi

  TRUST_HASH=$(curl -s "$RPC1:$RPC_PORT1/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)
  if [ "$TRUST_HASH" == "null" ]; then
    echo "Error: Cannot find block hash. This shouldn't happen :/"
    exit 1
  fi

  NODE1_ID=$(curl -s "$RPC1:$RPC_PORT1/status" | jq -r .result.node_info.id)
  NODE2_ID=$(curl -s "$RPC2:$RPC_PORT2/status" | jq -r .result.node_info.id)
  #NODE3_ID=$(curl -s "$RPC3:$RPC_PORT3/status" | jq -r .result.node_info.id)
  echo ""
  echo "##################################################################"
  echo "#     Parameters to change in: .bcna/config/config.toml          #"
  echo "##################################################################"
  echo "#  Temporaly search and replace this params with this values     #"
  echo "##################################################################"
  echo ""
  echo "persistent_peers = \"${NODE1_ID}@${NODE1_IP}:${P2P_PORT1},${NODE2_ID}@${NODE2_IP}:${P2P_PORT2}\""
  echo ""
  echo "Go to -StateSync section-"
  echo "========================="
  echo 'enable = true'
  echo "rpc_servers = \"http://$NODE1_IP:$RPC_PORT1,http://$NODE2_IP:$RPC_PORT2\""
  echo "trust_height = $BLOCK_HEIGHT"
  echo "trust_hash = \"$TRUST_HASH\""
  echo ""
  echo '##################################################################################'
  echo "#           Start the daemon with this new settings, when is synced              #"
  echo "##################################################################################"
  echo "# 1) Stop it again and change in the same file: config.toml this param again!!!  #"
  echo '#     enable = false                                                             #'
  echo '#                                                                                #'
  echo '##################################################################################'
  echo '#                Now you can start the daemon again! Good luck!                  #'
  echo '##################################################################################'
  sleep 2
fi
