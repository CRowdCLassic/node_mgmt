#!/bin/bash
TMP_FOLDER=$(mktemp -d)
ROOT_FOLDER=/opt/nodes
MAX_NODE=100

dt=$(date '+%Y%m%d_%H%M%S');

COIN_VERSION='v1.1.0'
COIN_NAME='Crowdcoin'
COIN_URL='https://github.com/crowdcoinChain/Crowdcoin/releases/download/1.1.0/Crowdcoin_command_line_binaries_linux_1.1.tar.gz'
COIN_TGZ=$(echo $COIN_URL | awk -F'/' '{print $NF}')
COIN_DIR='Crowdcoin_command_line_binaries_linux_1.1'
COIN_DAEMON='crowdcoind'
COIN_CLI='crowdcoin-cli'

RPC_PORT=11998
MIN_RPC_PORT=11998
MAX_RPC_PORT=12098

COIN_PORT=12875
MIN_COIN_PORT=12875
MAX_COIN_PORT=12876

SENTINEL_REPO='https://github.com/crowdcoinChain/sentinelLinux.git'

MNSCRIPT_URL='https://github.com/Robin-73/node_mgmt/archive/sun-0.1.tar.gz'
MNSCRIPT_TGZ=$(echo $MNSCRIPT_URL | awk -F'/' '{print $NF}')
MNSCRIPT_DIR='node_mgmt-sun-0.1'

COIN_ROOT=$ROOT_FOLDER/$COIN_NAME
COIN_BIN=$COIN_ROOT/bin
COIN_CONF=$COIN_ROOT/etc
COIN_BLOCKCHAIN=$COIN_ROOT/blockchain
COIN_PID=$COIN_ROOT/var/run

LOG_FOLDER=$COIN_ROOT/log

BLUE="\033[0;34m"
YELLOW="\033[0;33m"
CYAN="\033[0;36m"
PURPLE="\033[0;35m"
RED="033[0;31m"
GREEN="\033[0;32m"
NC="\033[0m"
MAG='\e[1;35m'

export LC_ALL=C


adddate() {
    while IFS= read -r line; do
        echo "$(date) $line"
    done
}

################################
#       Init Log file
################################
LOG_FILE=$LOG_FOLDER'/Log-'$COIN_NAME'-install-'$dt'.log'
echo log file in $LOG_FILE
mkdir -p $LOG_FOLDER
echo Starting $COIN_NAME Masternode installation | adddate >>$LOG_FILE

function prepare_system() {
 echo "=== STEP 1 === : Preparing system" >>$LOG_FILE 2>&1
 echo -e "Preparing the VPS to setup: ${RED}$COIN_NAME masternode${NC}"
 apt-get update | adddate >>$LOG_FILE 2>&1
 DEBIAN_FRONTEND=noninteractive apt-get update | adddate >>$LOG_FILE 2>&1
 DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" -y -qq upgrade | adddate >>$LOG_FILE 2>&1
 apt install -y software-properties-common | adddate >>$LOG_FILE 2>&1
 echo -e "${PURPLE}Adding bitcoin PPA repository"
 apt-add-repository -y ppa:bitcoin/bitcoin | adddate >>$LOG_FILE 2>&1
 echo -e "Installing required packages, it may take some time to finish.${NC}"
 apt-get update | adddate >>$LOG_FILE 2>&1
 apt-get install | adddate >>$LOG_FILE 2>&1
 apt-get install libzmq3-dev -y | adddate >>$LOG_FILE 2>&1
 apt-get install -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" make software-properties-common \
 build-essential libtool autotools-dev autoconf libssl-dev libboost-dev libboost-chrono-dev libboost-filesystem-dev libboost-program-options-dev \
 libboost-system-dev libboost-test-dev libboost-thread-dev libboost-all-dev sudo automake git wget curl libdb4.8-dev bsdmainutils libdb4.8++-dev \
 libminiupnpc-dev libgmp3-dev ufw pkg-config libevent-dev  libdb5.3++ unzip libzmq5 | adddate >>$LOG_FILE 2>&1
 if [ "$?" -gt "0" ];
  then
    echo -e "${RED}Not all required packages were installed properly. Try to install them manually by running the following commands:${NC}\n"
    echo "apt-get update"
    echo "apt -y install software-properties-common"
    echo "apt-add-repository -y ppa:bitcoin/bitcoin"
    echo "apt-get update"
    echo "apt install -y make build-essential libtool autotools-dev software-properties-common autoconf libssl-dev libboost-dev libboost-chrono-dev libboost-filesystem-dev \
          libboost-program-options-dev libboost-system-dev libboost-test-dev libboost-thread-dev libboost-all-dev sudo automake git curl libdb4.8-dev \
          bsdmainutils libdb4.8++-dev libminiupnpc-dev libgmp3-dev ufw pkg-config libevent-dev libdb5.3++ unzip libzmq5"
 exit 1
fi
}


function download_node() {
  echo -e "${GREEN}Downloading and installing $COIN_NAME daemon${NC}"
  echo "=== STEP 2 === : Download and install $COIN_NAME" >>$LOG_FILE 2>&1
  echo Creating folder | adddate >>$LOG_FILE 2>&1
  mkdir -p $COIN_CONF | adddate >>$LOG_FILE 2>&1
  mkdir -p $COIN_BIN | adddate >>$LOG_FILE 2>&1
  mkdir -p $COIN_BLOCKCHAIN | adddate >>$LOG_FILE 2>&1
  mkdir -p $COIN_PID | adddate >>$LOG_FILE 2>&1

  echo Go to TEMP FOLDER | adddate >>$LOG_FILE 2>&1
  cd $TMP_FOLDER
  pwd | adddate >>$LOG_FILE 2>&1
  echo Get Binary and MNScript | adddate >>$LOG_FILE 2>&1
  
  wget -q $COIN_URL | adddate >>$LOG_FILE 2>&1
  if [ $? -eq 0 ]; then
  	tar -zxvf $COIN_TGZ | adddate >>$LOG_FILE 2>&1
  else
	echo error while downloading $COIN_URL : $?  
	return 2
  fi
  wget -q $MNSCRIPT_URL | adddate >>$LOG_FILE 2>&1
  if [ $? -eq 0 ]; then
  	tar -zxvf $MNSCRIPT_TGZ | adddate >>$LOG_FILE 2>&1
  else
	echo error while downloading $MNSCRIPT_URL : $?  
	return 4
  fi

  ls -alh| adddate >>$LOG_FILE 2>&1

  echo go to $COIN_DIR | adddate >>$LOG_FILE 2>&1
  cd $COIN_DIR
  pwd | adddate >>$LOG_FILE 2>&1
  ls -alh | adddate >>$LOG_FILE 2>&1

  cp $COIN_DAEMON $COIN_CLI $COIN_BIN | adddate >>$LOG_FILE 2>&1

  cd ../$MNSCRIPT_DIR
  pwd | adddate >>$LOG_FILE 2>&1
  cp *.sh $COIN_BIN | adddate >>$LOG_FILE 2>&1

  echo go to $COIN_BIN | adddate >>$LOG_FILE 2>&1
  cd "$COIN_BIN" 
  pwd | adddate >>$LOG_FILE 2>&1
  chmod u+x $COIN_DAEMON $COIN_CLI | adddate >>$LOG_FILE 2>&1
  chmod u+x *.sh | adddate >>$LOG_FILE 2>&1
  ls -alh| adddate >>$LOG_FILE 2>&1

  rm -rf $TMP_FOLDER | adddate >>$LOG_FILE 2>&1
}


function configure_systemd() {
echo "=== STEP 3 === Setup Systemd "| adddate >>$LOG_FILE 2>&1
  cat << EOF > /etc/systemd/system/$COIN_NAME.service
[Unit]
Description=$COIN_NAME service
After=network.target
[Service]
User=root
Group=root
Type=forking
PIDFile=$COIN_PID/$COIN_NAME.pid
ExecStart=$COIN_BIN/mn_control.sh start -s
ExecStop=$COIN_BIN/mn_control.sh stop -s
Restart=always
PrivateTmp=true
TimeoutStopSec=60s
TimeoutStartSec=10s
StartLimitInterval=120s
StartLimitBurst=5
[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  sleep 3
  systemctl enable $COIN_NAME.service >/dev/null 2>&1
}


function get_port() {
 IP=$1
 TEST_PORT=$MIN_COIN_PORT
 while [ $TEST_PORT -le $MAX_COIN_PORT ]
  do
        if lsof -Pi @$IP:$TEST_PORT -sTCP:LISTEN -t >/dev/null ; then
                #printf  "."
                echo "$IP:$TEST_PORT in use" >>$LOG_FILE 2>&1

        else
                echo "IP_$TEST_PORT free" >>$LOG_FILE 2>&1
                COIN_PORT=$TEST_PORT
                return 0
        fi
        let "TEST_PORT++"
  done
echo "No more port available for IP $IP" >>$LOG_FILE 2>&1
return 1

}


function get_rpcport() {
 echo "=== STEP 4 === Get RPC Port "| adddate >>$LOG_FILE 2>&1
 TEST_RPC_PORT=$MIN_RPC_PORT
 IP="127.0.0.1"
 while [ $TEST_RPC_PORT -le $MAX_RPC_PORT ]
  do
        if lsof -Pi @$IP:$TEST_RPC_PORT -sTCP:LISTEN -t >/dev/null ; then
                #printf  "."
                echo "$IP:$TEST_RPC_PORT in use...try next" | adddate >>$LOG_FILE 2>&1

        else
                echo "RPC_PORT : $TEST_RPC_PORT ok free" | adddate >>$LOG_FILE 2>&1
                RPC_PORT=$TEST_RPC_PORT
                return 0
        fi
        let "TEST_RPC_PORT++"
done
return 1
}


function get_ip() {
 echo "=== STEP 5 === Get IP:PORT "| adddate >>$LOG_FILE 2>&1
  # Define NODE_IPS as an Array 
  declare -a INT_IPS
  declare -a NODE_IPS

  for ips in $(ip -4 -o addr | awk '!/^[0-9]*: ?lo|link\/ether/ {gsub("/", " "); print $4}')
  do
    INT_IPS+=$ips
    NODE_IPS+=($(curl --interface $ips --connect-timeout 2 -s4 icanhazip.com))
  done

  if [ ${#NODE_IPS[@]} -gt 1 ]
    then
      echo "More than one IP found..." | adddate >>$LOG_FILE 2>&1
      for idx in "${NODE_IPS[@]}"
      do
	INTIP=${INT_IPS[$idx]}
	EXTIP=${NODE_IPS[$idx]}
        echo "checking ip :$INTIP" | adddate >>$LOG_FILE 2>&1
        get_port $INTIP
        if [ $? -eq 0 ]; then
                NODEIP=$EXTIP
        	echo "Internal IP: $INTIP External IP: $NODEIP Port: $COIN_PORT" | adddate >>$LOG_FILE 2>&1
                return 0
        fi
      done
      return 1

  else
    INTIP=${INT_IPS[0]}
    NODEIP=${NODE_IPS[0]}
    get_port $INTIP
    if [ $? -eq 0 ]; then
        echo "Internal IP: $INTIP External IP: $NODEIP Port: $COIN_PORT" | adddate >>$LOG_FILE 2>&1
        return 0
    else
        return 1
    fi
  fi
}

function get_node_conf () {
 echo "=== STEP 6 === Get Next conf file" | adddate >>$LOG_FILE 2>&1
 for ((i=0;i<=$MAX_NODE;i++)); do
   CONF_FILE=$COIN_CONF/node$i.conf
   if [ -f $CONF_FILE ]; then
        echo "File $CONF_FILE already exists" | adddate >>$LOG_FILE 2>&1
   else
        echo "File $CONF_FILE is available" | adddate >>$LOG_FILE 2>&1
        NODE_IDX=$i
        return 0
   fi
 done
 return 1
}


function create_config() {
 echo "=== STEP 7 === Create config" | adddate >>$LOG_FILE 2>&1
  mkdir -p $COIN_CONF | adddate >>$LOG_FILE 2>&1
  RPCUSER=$(tr -cd '[:alnum:]' < /dev/urandom | fold -w10 | head -n1)
  RPCPASSWORD=$(tr -cd '[:alnum:]' < /dev/urandom | fold -w22 | head -n1)
  cat << EOF > $COIN_CONF/node$NODE_IDX.conf
rpcuser=$RPCUSER
rpcpassword=$RPCPASSWORD
rpcport=$RPC_PORT
rpcthreads=8
rpcbind=127.0.0.1
rpcallowip=127.0.0.1
bind=$INTIP:$COIN_PORT
externalip=$NODEIP
listen=1
server=1
maxconnections=16
daemon=1
port=$COIN_PORT
staking=0
discover=1
logintimestamps=1
EOF
}


function enable_firewall() {
  echo "=== STEP 8 === Enable Firewall" | adddate >>$LOG_FILE 2>&1
  echo -e "Installing and setting up firewall to allow port ${GREEN}$COIN_PORT${NC}"
  ufw allow $COIN_PORT/tcp comment "$COIN_NAME MN port" | adddate >>$LOG_FILE 2>&1
  ufw allow ssh comment "SSH" | adddate >>$LOG_FILE 2>&1
  ufw limit ssh/tcp | adddate >>$LOG_FILE 2>&1
  ufw default allow outgoing | adddate >>$LOG_FILE 2>&1
  echo "y" | ufw enable | adddate >>$LOG_FILE 2>&1
  ufw status | adddate >>$LOG_FILE 2>&1
}

function install_sentinel() {
  echo "Install Sentinel Linux"
  echo "=== STEP 9 === Installing sentinel" | adddate >>$LOG_FILE 2>&1
  
  apt-get -y install python-virtualenv virtualenv >/dev/null 2>&1
  git clone $SENTINEL_REPO $COIN_ROOT/sentinelLinux/node$NODE_IDX >/dev/null 2>&1
  
  cd $COIN_ROOT/sentinelLinux/node$NODE_IDX
  
  export LC_ALL=C
  virtualenv ./venv >/dev/null 2>&1
  ./venv/bin/pip install -r requirements.txt >/dev/null 2>&1
  
  # modify sentinel.conf
  sed -i "s|dash_conf=/home/YOURUSERNAME/.crowdcoincore/crowdcoin.conf|crowdcoin_conf=$CONF_FILE|g" sentinel.conf
  
  # Add line in crontab
  crontab -l > $COIN_CONF/$COIN_NAME.cron
  echo  "* * * * * cd $COIN_ROOT/sentinelLinux/node$NODE_IDX && ./venv/bin/python bin/sentinel.py >> sentinel.log 2>&1" >>$COIN_CONF/$COIN_NAME.cron
  crontab $COIN_CONF/$COIN_NAME.cron
  rm $COIN_CONF/$COIN_NAME.cron >/dev/null 2>&1
}


function update_config() {
  cat << EOF >> $COIN_CONF/$CONFIG_FILE
masternode=1
masternodeprivkey=$COINKEY
EOF
}

function setup_coin() {
 # STEP 1
 prepare_system
 if [ ! $? -eq 0 ]; then
  echo Error while preparing the system, please check log
  exit 1
 fi
 # STEP 2
 download_node
 if [ ! $? -eq 0 ]; then
  echo Error while downloading software, please check log
  exit 2
 fi
 # STEP 3
 configure_systemd
 if [ ! $? -eq 0 ]; then
  echo Error while configuring systemd, please check log
  exit 3
 fi
}

function deploy_node() {
 # STEP 4 - Get Free RPC port
 get_rpcport
 if [ $? -eq 0 ]; then
 	echo "RPC Port :$RPC_PORT"
 else
 	echo "Error while select RPC port, please check log"
 	exit 1
 fi

 # STEP 5 - Get ip:port
 get_ip
 if [ $? -eq 0 ]; then
 	echo "INTERNAL IP: $INTIP IP: $NODEIP Port: $COIN_PORT"
 else
 	echo "Error while select IP:port, please check log"
 	exit 1
 fi
 # STEP 6 - Get Next conf file
 get_node_conf

 # STEP 7  - Create Conf File
 create_config

 # STEP 8 - Update firewall
 enable_firewall

 # STEP 9 - Setup  sentinel
 install_sentinel

 # STEP 10 - Start Node
 $COIN_BIN/mn_control.sh -n=$NODE_IDX start
}


function activate_node() {
  #ask_freenode
  #create_key
  update_config
  #activate_node
}

#setup_coin
deploy_node
