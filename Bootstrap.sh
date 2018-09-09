#!/bin/bash

COIN="Crowdcoin"

#Get current folder
basedir=$(echo $(dirname $0))

root=/Users/cedric/Masternode
ssh_key_folder=$root/sshkey
ssh_key=$ssh_key_folder/masternode.rsa
bootstrap_folder=$root/bootstrap


function Bootstrap_Usage() {
  echo  "Usage: $0  -h|--host=<nodeid> -u|--user=<username> [-p|--port=<ssh_port>] { install_key | install_base }"
}


function check_sshkey() {

 username=$1
 remote_host=$2
 port=${3:-"22"}
 mkdir -p $ssh_key_folder 
 chg_right=$(chmod 700 $ssh_key_folder)

 if [ ! -f $ssh_key ]; then
   ssh-keygen -t rsa -N '' -f $ssh_key
   chg_right=$(chmod 700 $ssh_key_folder/* )
 else
   echo "SSH Private key $ssh_key exist"
 fi

 #deploy ssh pub key on remote host if not already existing
 echo Deploying $ssh_key.pub on $remote_host

 KEY=$(cat $ssh_key.pub) 

 #--------------------
 # Run ssh bash script
 #--------------------
 ssh -p $port $username@$remote_host -i $ssh_key bash -s <<EOF
    echo Checking if ~/.ssh/authorized_keys exit on $remote_host
    if [ ! -f ~/.ssh/authorized_keys  ]; then 
	mkdir -p ~/.ssh/
	echo ~/.ssh/authorized_keys does not exist... creating the file 
        echo adding key...
	echo $KEY >> ~/.ssh/authorized_keys
	if [ \$? -eq 0 ]; then
		echo key added.
		exit 0
	else 
        	echo "error while adding ssh pub key"
		exit 1
	fi 
    else
	echo "OK :  ~/.ssh/authorized_keys file exist" 
	echo checking in ssh pub key need to be added...
	key_check=\$(grep -q "$KEY" ~/.ssh/authorized_keys)
	if [ \$? -eq 0 ]; then
		echo ssh pub key already exist nothing to do.
		exit 0
	else
		echo Adding pub key because it does not exist on $remote_host
		echo $KEY >> ~/.ssh/authorized_keys
		if [ \$? -eq 0 ]; then
			echo ssh pub key added. 
			exit 0
		else 
        		echo "error while adding ssh pub key"
			exit 2
		fi
	fi
    fi
EOF
 #--------------------
 # End of Bash Script
 #--------------------
 local exit_code=$?
 if [ ! $exit_code -eq 0 ]; then
        echo "error while deploying ssh key : $exist_code"
 fi
 return $exit_code
 echo End of SSH key installation
}


function create_folder () {
 Echo "Creating folder /opt/nodes/$COIN/Bootstrap on $remote_host"
 ssh -p $port $username@$remote_host -i $ssh_key "mkdir -p /opt/nodes/$COIN/Bootstrap"
 local exit_code=$?
 if [ $exit_code -ne 0 ]; then
        echo "error while creating bootstrap folder : $exit_code"
	return $exit_code
 fi
 scp -P $port -i $ssh_key ./install.sh $username@$remote_host:/opt/nodes/$COIN/Bootstrap/install.sh
 local exit_code=$?
 if [ $exit_code -ne 0 ]; then
        echo "error while copying install.sh in bootstrap folder : $exit_code"
 	return $exit_code
 fi

}


##### Main #####

#Init variable
TMPCMD=""
MODE=""
: ${MODE:="interactive"}
: ${username:="root"}
: ${port:="22"}
username=root
port=22


#Read the command to run
while [ "$1" != "" ]; do
    PARAM=`echo $1 | awk -F= '{print $1}'`
    VALUE=`echo $1 | awk -F= '{print $2}'`
    case $PARAM in
        -h|--host)
            remote_host=$VALUE
            ;;
        -u|--user)
            username=$VALUE
            ;;
        -p|--port)
            port=$VALUE
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
username="$(echo -e "${username}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
remote_host="$(echo -e "${remote_host}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
port="$(echo -e "${port}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
CMD="$(echo -e "${TMPCMD}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

if [[ $CMD = "" || $username = "" || $remote_host = "" ]] ;then
	echo "==== Missing argument ===="
	echo ""
	Bootstrap_Usage
	echo ""
	exit 1
else
	echo "Running Command : $CMD"
fi

case $CMD in
	install_key*)
		check_sshkey $username $remote_host $port
		if [ ! $? -eq 0 ]; then
			echo "Error while installing ssh_key"
 			exit 1
		fi
	;;
	install_base*)
		check_sshkey $username $remote_host $port
		if [ ! $? -eq 0 ]; then
			echo "Error while installing ssh_key"
 			exit 1
		fi
		create_folder
	;;
	add_node*)
	;;
	check*)
	;;
	activate*)
	;;
esac 
