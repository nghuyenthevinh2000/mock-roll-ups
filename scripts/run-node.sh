#!/bin/bash

CONTINUE=${CONTINUE:-"false"}
HOME_DIR=mytestnet/soliz
ENV=${ENV:-""}

# flag for celestia
ONLY_CELESTIA=false

# Initialize BINARY with a default value if you have one
BINARY=

# Loop through all arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --only-celestia)
        ONLY_CELESTIA=true
        shift # Move to next argument
        ;;
        --binary)
        BINARY="$2"
        shift # Skip the value of --binary
        shift # Move to next argument
        ;;
        *) # Unknown option
        shift # Move to next argument
        ;;
    esac
done

# check DENOM is set. If not, set to usoliz
DENOM=${2:-usoliz}

COMMISSION_RATE=0.01
COMMISSION_MAX_RATE=0.02
MIN_GAS_PRICES="1000usoliz"

SED_BINARY=sed
# check if this is OS X
if [[ "$OSTYPE" == "darwin"* ]]; then
    # check if gsed is installed
    if ! command -v gsed &> /dev/null
    then
        echo "gsed could not be found. Please install it with 'brew install gnu-sed'"
        exit
    else
        SED_BINARY=gsed
    fi
fi

# check BINARY is set. If not, build terrad and set BINARY
if [ -z "$BINARY" ]; then
    make build
    BINARY=build/solizd
fi

if [ "$CONTINUE" == "true" ]; then
    $BINARY start --home $HOME_DIR --log_level debug
    exit 0
fi

rm -rf mytestnet
mkdir mytestnet

# run celestia process
if [[ "$OSTYPE" == "darwin"* ]]; then
    touch mytestnet/da-log.txt
    screen -L -Logfile mytestnet/da-log.txt -dmS da-test bash scripts/run-celestia.sh
else
    screen -L -Logfile mytestnet/da-log.txt -dmS da-test bash scripts/run-celestia.sh
fi

# if ONLY_CELESTIA is true, run script run-celestia.sh
if [ "$ONLY_CELESTIA" = true ]; then
    exit 0
fi

echo "sleeping for few seconds"
sleep 15

CHAIN_ID="soliz-simapp"
KEYRING="test"
KEY="test0"
KEY1="test1"
KEY2="test2"

# Function updates the config based on a jq argument as a string
update_test_genesis () {
    # update_test_genesis '.consensus_params["block"]["max_gas"]="100000000"'
    cat $HOME_DIR/config/genesis.json | jq "$1" > $HOME_DIR/config/tmp_genesis.json && mv $HOME_DIR/config/tmp_genesis.json $HOME_DIR/config/genesis.json
}

cleanup() {
    echo "Cleanup function called upon exit"
    # Place your cleanup commands here
    pkill $BINARY
    pkill -f 'celestia.*'
    sleep 10
}

# Trap the EXIT signal
trap cleanup EXIT

$BINARY init --chain-id $CHAIN_ID moniker --home $HOME_DIR

$BINARY keys add $KEY --keyring-backend $KEYRING --home $HOME_DIR
$BINARY keys add $KEY1 --keyring-backend $KEYRING --home $HOME_DIR
$BINARY keys add $KEY2 --keyring-backend $KEYRING --home $HOME_DIR

# Allocate genesis accounts (cosmos formatted addresses)
$BINARY genesis add-genesis-account $KEY "1000000000000${DENOM}" --keyring-backend $KEYRING --home $HOME_DIR
$BINARY genesis add-genesis-account $KEY1 "1000000000000${DENOM}" --keyring-backend $KEYRING --home $HOME_DIR
$BINARY genesis add-genesis-account $KEY2 "1000000000000${DENOM}" --keyring-backend $KEYRING --home $HOME_DIR

update_test_genesis '.app_state["gov"]["voting_params"]["voting_period"]="50s"'
update_test_genesis '.app_state["mint"]["params"]["mint_denom"]="'$DENOM'"'
update_test_genesis '.app_state["gov"]["params"]["min_deposit"]=[{"denom":"'$DENOM'","amount": "1000000"}]'
update_test_genesis '.app_state["gov"]["params"]["expedited_min_deposit"]=[{"denom":"'$DENOM'","amount": "50000000"}]'
update_test_genesis '.app_state["crisis"]["constant_fee"]={"denom":"'$DENOM'","amount":"1000"}'
update_test_genesis '.app_state["staking"]["params"]["bond_denom"]="'$DENOM'"'
# add centralized sequencer (validator)
ADDRESS=$(jq -r '.address' $HOME_DIR/config/priv_validator_key.json)
PUB_KEY=$(jq -r '.pub_key.value' $HOME_DIR/config/priv_validator_key.json)
update_test_genesis '.consensus["validators"]=[{"address":"'$ADDRESS'","pub_key":{"type":"tendermint/PubKeyEd25519","value":"'$PUB_KEY'"},"power":"1","name":"Rollkit centralized sequencer"}]'

# enable rest server and swagger
$SED_BINARY -i '0,/enable = false/s//enable = true/' $HOME_DIR/config/app.toml
$SED_BINARY -i 's/swagger = false/swagger = true/' $HOME_DIR/config/app.toml

# Sign genesis transaction
$BINARY genesis gentx $KEY "1000000${DENOM}" --commission-rate=$COMMISSION_RATE --commission-max-rate=$COMMISSION_MAX_RATE --keyring-backend $KEYRING --chain-id $CHAIN_ID --home $HOME_DIR

# Collect genesis tx
$BINARY genesis collect-gentxs --home $HOME_DIR

# Run this to ensure everything worked and that the genesis file is setup correctly
$BINARY genesis validate --home $HOME_DIR

DA_BLOCK_HEIGHT=$(curl -s http://localhost:36657/block | jq -r '.result.block.header.height')
echo -e "\n DA_BLOCK_HEIGHT is $DA_BLOCK_HEIGHT \n"

$BINARY start --cpu-profile cpu.pprof --rollkit.aggregator --rollkit.da_address=":36650" --rollkit.da_start_height $DA_BLOCK_HEIGHT --home $HOME_DIR --minimum-gas-prices $MIN_GAS_PRICES
