#!/bin/bash
# This script permit to stop or start one or several Masternodes
# it also display curent status of the masternode with color output
# 

#Loading configuration
basedir=`echo $(dirname $0)`
. $basedir/configuration.sh

if [[ ! "$CONF_FLAG" == 1 ]]; then
 echo "Error loading configuration"
 exit 1
fi

#display usage
function mn_usage() {
	echo  "Usage: $0  [-n|--node=<nodeid>] { start | stop | restart | status }" 
}

#grab json value
function jsonValue() {
	KEY=$1
	num=1
	temp=`awk -F"[,:}]" '{for(i=1;i<=NF;i++){if($i~/\042'$KEY'\042/){print $(i+1)}}}' | tr -d '"' | sed -n ${num}p`
	echo ${temp//[[:blank:]]/}
}

#start function
function d_start () 
{ 
	for CONF in $CONF_FILES
	do
	 NODE=`basename $CONF .conf`
	 DATA_DIR=$DBROOT_DIR/$NODE
	 PIDFILE=$RUN_DIR/$NODE.pid
	 cd $MN_DIR
	 #Create database folder if not exist
         if [[ ! -e $DATA_DIR ]]; then
                mkdir -p $DATA_DIR
         fi

         if [[ ! -e $RUN_DIR ]]; then
                mkdir -p $RUN_DIR
         fi
	 echo  "Masternode $MN_NAME $NODE : starting..."
	 #echo "$BIN_DIR/$MN_PROG -pid=$PIDFILE -conf=$CONF -datadir=$DATA_DIR $REINDEX"
	 $BIN_DIR/$MN_PROG -pid=$PIDFILE -conf=$CONF -datadir=$DATA_DIR $REINDEX
	 sleep  1 
	done
}

#stop function
function d_stop () 
{ 
	for CONF in $CONF_FILES
	do
	 NODE=`basename $CONF .conf`
	 DATA_DIR=$DBROOT_DIR/$NODE
	 PIDFILE=$RUN_DIR/$NODE.pid
	 echo  "Masternode $MN_NAME $NODE : stopping (PID = $(cat $PIDFILE) )" 
	 $BIN_DIR/$MN_CLI -conf=$CONF -datadir=$DATA_DIR stop
	done
}

#status function
function d_status () 
{ 
	for CONF in $CONF_FILES
	do
	 NODE=`basename $CONF .conf`
	 DATA_DIR=$DBROOT_DIR/$NODE
	 PIDFILE=$RUN_DIR/$NODE.pid
	 MN_DEBUG=`$BIN_DIR/$MN_CLI -conf=$CONF -datadir=$DATA_DIR masternode debug 2>&1`
	 if [[ $? = 0 ]] ; then
		MN_CONF="OK"
		if [[ $MN_DEBUG = "Masternode successfully started"  ]]; then
			MN_DEBUG=`echo -e "${On_IGreen}${MN_DEBUG}${Color_Off}"`
		else
			MN_DEBUG=`echo -e "${On_IYellow}${MN_DEBUG}${Color_Off}"`
		fi
	 else 
		MN_CONF="Error";
		MN_DEBUG=`echo -e "${Red}${MN_DEBUG}${Color_Off}"`
	 fi

	 MNSYNC=`$BIN_DIR/$MN_CLI -conf=$CONF -datadir=$DATA_DIR mnsync status 2>&1`
	 if [[ $? = 0 ]] ; then
		MN_SYNC="OK"
		SYNC_STATUS=`echo $MNSYNC | jsonValue "AssetName"`
	 else 
		MN_SYNC="Error";
		SYNC_STATUS="NA";
	 fi
	 
	 GETINFO=`$BIN_DIR/$MN_CLI -conf=$CONF -datadir=$DATA_DIR getinfo 2>&1`
	 if [[ $? = 0 ]] ; then
		MN_GETINFO="OK"
	 	BLOCKS=`echo $GETINFO | jsonValue blocks`
		NODEVERSION=`echo $GETINFO | jsonValue version 1`
	 	WALLETVERSION=`echo $GETINFO | jsonValue walletversion`
	 	PROTOCOLVERSION=`echo $GETINFO | jsonValue protocolversion`
	 	PEERS=`echo $GETINFO | jsonValue "connections"`
	 else   
		MN_SYNC="Error";
		NODEVERSION="NA";
		WALLETVERSION="NA";
		PROTOCOLVERSION="NA";
		PEERS="NA";
	 fi
	 echo "------------------------------------"
	 echo "Masternode $MN_NAME  - $NODE" 
	 echo "------------------------------------"
	 echo "Masternode Debug : $MN_DEBUG" 
	 echo "Masternode Sync  : $SYNC_STATUS"
	 echo "Peers connected  : $PEERS"
	 echo "Current Block    : $BLOCKS" 
	 echo "Node Version     : $NODEVERSION" 
	 echo "Wallet Version   : $WALLETVERSION" 
	 echo "Protocol Version : $PROTOCOLVERSION" 
	done
}
 
#Init variable
TMPCMD=""
MODE=""

#Read the command to run
while [ "$1" != "" ]; do
    PARAM=`echo $1 | awk -F= '{print $1}'`
    VALUE=`echo $1 | awk -F= '{print $2}'`
    case $PARAM in
        -n|--node)
            NODE=node$VALUE
            ;;
        -r|--reindex)
            REINDEX="-reindex"
            ;;
        -s|--silent)
            MODE="silent"
            ;;
        *)
	    if [[ ! -z $VALUE ]]; then
		TMPCMD+=" ${PARAM} ${VALUE}"
	    else
		TMPCMD+=" ${PARAM}"
	    fi
	    ;;
    esac
    shift
done

#cleaning the command from whitespace - trim
CMD="$(echo -e "${TMPCMD}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

if [[ $CMD = "" ]] ;then
	echo "==== Missing Cli Command ===="
	echo ""
	mn_usage
	echo ""
	exit 1
fi

#Get scope of the command 
if [[ ${NODE:+1} ]] ; then
	CONF_FILES="$MN_DIR/etc/$NODE.conf"
else 
	CONF_FILES="$MN_DIR/etc/node*.conf"
	if [[ $MODE != "silent"  ]]; then 
	  while true; do
		read -p "Are you sure you want to run the command on all nodes ? [Y] | N : " yn
		case $yn in
			[Yy]* )
				break;;
			[Nn]* )
				mn_usage
				echo ""
				exit;;
			* )
				break;;
		esac
	  done
	fi
fi
 
# Management instructions of the service 
case  "$CMD"  in 
	start )
		d_start
		;; 
	stop )
		d_stop
		;; 
	restart )
		d_stop
		sleep  1
		d_start
		;; 
	status )
		d_status
		;; 
	* ) 
	mn_usage
	exit  1 
	;; 
esac

exit  0
