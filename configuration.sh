#!/bin/bash
ROOT_FOLDER="/opt/wallet"

MAX_NODE=10

COIN_VERSION='v1.1.0'
COIN_NAME='Crowdcoin'
COIN_URL='https://github.com/crowdcoinChain/Crowdcoin/releases/download/1.1.0/Crowdcoin_command_line_binaries_linux_1.1.tar.gz'
COIN_TGZ=$(echo $COIN_URL | awk -F'/' '{print $NF}')
COIN_DIR='Crowdcoin_command_line_binaries_linux_1.1'
COIN_DAEMON='crowdcoind'
COIN_CLI='crowdcoin-cli'
NODE_PREFIX=node

RPC_PORT=11998
MIN_RPC_PORT=11998
let "MAX_RPC_PORT=MIN_RPC_PORT+MAX_NODE"

COIN_PORT=12875
MIN_COIN_PORT=12875
let "MAX_COIN_PORT=MIN_COIN_PORT+MAX_NODE"

SENTINEL_REPO='https://github.com/crowdcoinChain/sentinelLinux.git'

MNSCRIPT_URL='https://github.com/Robin-73/node_mgmt/archive/sun-0.1.tar.gz'
MNSCRIPT_TGZ=$(echo $MNSCRIPT_URL | awk -F'/' '{print $NF}')
MNSCRIPT_DIR='node_mgmt-sun-0.1'

CONF_FILES="$CONF_DIR/$NODE_PREFIX*.conf"
COIN_ROOT="$ROOT_FOLDER/$COIN_NAME"
COIN_BIN="$COIN_ROOT/bin"
COIN_CONF="$COIN_ROOT/etc"
COIN_BLOCKCHAIN="$COIN_ROOT/blockchain"
COIN_PID="$COIN_ROOT/var/run"


#Loading color
basedir=`echo $(dirname $0)`
. $basedir/color.sh

CONF_FLAG=1
