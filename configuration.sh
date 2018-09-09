#!/bin/bash
CONF_FLAG=1
ROOT_DIR="/opt/nodes"
MN_NAME="Crowdcoin"

#Short Name should not contain space
MN_SHORTNAME="CRC"
MN_FULLNAME="Crowdcoin (CRC) Masternode"
MN_PROG="crowdcoind"
MN_CLI="crowdcoin-cli"

MN_USER=crowdcoin_user
MN_GROUP=crowdcoin_group

MN_DIR="$ROOT_DIR/$MN_NAME"
BIN_DIR="$MN_DIR/bin"
CONF_DIR="$MN_DIR/etc"
DBROOT_DIR="$MN_DIR/blockchain"
RUN_DIR="$MN_DIR/var/run"
CONF_FILES="$CONF_DIR/node*.conf"


#Loading color
basedir=`echo $(dirname $0)`
. $basedir/color.sh
