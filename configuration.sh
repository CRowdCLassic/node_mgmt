#!/bin/bash
CONF_FLAG=1
ROOT_DIR="/opt/node"
MNNAME="Crowdcoin"

#Short Name should not contain space
MNSHORTNAME="CRC"
MNFULLNAME="Crowdcoin (CRC) Masternode"
MNPROG="crowdcoind"
MNCLI="crowdcoin-cli"

MNUSER=sysadmin
MNGROUP=sysadmin

MN_DIR="$ROOT_DIR/$MNNAME"
BIN_DIR="$MN_DIR/bin"
CONF_DIR="$MN_DIR/etc"
DBROOT_DIR="$MN_DIR/var/lib"
RUN_DIR="$MN_DIR/var/run"
CONF_FILES="$CONF_DIR/node*.conf"


#Loading color
basedir=`echo $(dirname $0)`
. $basedir/color.sh
