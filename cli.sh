#!/bin/bash
# This script is a cli wrapper to control multiple Masternode on 1 machine
#

#Loading configuration
basedir=`echo $(dirname $0)`
. $basedir/configuration.sh

if [[ ! "$CONF_FLAG" == 1 ]]; then
 echo "Error loading configuration"
 exit 1
fi

#Display usage
function cli_usage()
{
	echo "usage : $0 [-n|--node=idx] <cli command>"
	echo ""
	echo "idx is the index matching the node[idx].conf"
	echo "if no idx provided, <cli command> will apply to all nodes !!"
}

#init variable
TMPCMD=""
LINE=$1

#Read the command to run
while [ "$1" != "" ]; do
    PARAM=`echo $1 | awk -F'=' '{print $1}'`
    VALUE=`echo $1 | awk -F'=' '{print $2}'`
    case $PARAM in
        -n|--node)
            NODE=node$VALUE
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

#Cleaning the command from whitespace - trim
CMD="$(echo -e "${TMPCMD}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

if [[ $CMD = "" ]] ;then
	echo "==== Missing Cli Command ===="
	echo ""
	cli_usage
	echo ""
        exit 1
fi

#Get scope of the command
if [[ ${NODE:+1} ]] ; then
        CONF_FILES="$MN_DIR/etc/$NODE.conf"
else
        CONF_FILES="$MN_DIR/etc/node*.conf"
	while true; do
		read -p "Are you sure you want to run the command on all nodes ? [Y] | N : " yn
		case $yn in
			[Yy]* ) 
			break;;
			[Nn]* ) 
			cli_usage
			echo ""
			exit;;
			* ) 
			break;;

		esac
	done

fi

#display command scope
echo "This command will apply on $CONF_FILES"

#Running the command
for CONF in $CONF_FILES
   do
   	NODE=`basename $CONF.conf`
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
        $BIN_DIR/$MN_CLI -pid=$PIDFILE -conf=$CONF -datadir=$DATA_DIR $CMD
  done


