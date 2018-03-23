#!/bin/bash
# Author: Sjors101 <https://github.com/sjors101/>, 16/02/2017
# Setting up an ssh tunnel easily. 
# This can be used to centralize your ssh communication and connect via jump nodes.
#
# After the gateway is created you can use this port for your ssh communication, see examples:
# EXAMPLE SSH: ssh remote_user@127.0.0.1 -i /root/.ssh/remote_key.pem -p 12345
# EXAMPLE SCP: scp -i /root/.ssh/remote_key.pem -P 12345 documents.tar.gz  remote_user@127.0.0.1:/tmp/

SSHKEY='/root/.ssh/gateway_key.pem'  # add key for connection to gateway / jumpnode
SSHUSER='gateway_user' # add user for connection to gateway / jumpnode
PORT='12345' # no need to change this port

create(){ # Create a new Tunnel
    while :
        do
            check_port_status=`netstat -tulpn | grep $PORT`

            if [ -n "$check_port_status" ]; then
                PORT=$((PORT + 1))
                continue
            fi
        break
    done

    read -p "Enter Gateway adress: " G_address
    read -p "Enter Remote adress: " R_address

    if [ -n $G_address ] && [ -n $R_address ] && [ -n $PORT ]; then
        echo Seting up SSH-Tunnel to $R_address via $G_address with port: $PORT
        ssh -f -N -o ConnectTimeout=5 -L $PORT:$R_address:22 $SSHUSER@$G_address -i $SSHKEY
    else
        echo 'ERROR: something is missing'
    fi
}

destroy(){ # Kill process with port number
    read -p "Enter the localport of the tunnel, which you want to destroy: " L_PORT
    GET_PID=`ps aux | grep -m 1 "ssh -f -N -o ConnectTimeout=5 -L $L_PORT:" | grep -v grep | awk '{print $2}'`
    
    if [ -z $GET_PID ]; then
        echo No tunnel with port $L_PORT
    else
        kill $GET_PID
        echo Destroyed PID: $GET_PID
    fi
}

list(){ # List all open tunnels with ps
    OPEN_TUNNELS=`ps aux | grep -v grep | grep "ssh -f -N" | awk '{ for(i=17; i<NF; i++) printf "%s",$i OFS; if(NF) printf "%s",$NF; printf ORS}'`
    if [ ${#OPEN_TUNNELS} -ge 1 ]; then   
        echo 'PORT - REMOTE-IP - GATEWAY'
        for ((i = 0; i < ${#OPEN_TUNNELS[@]}; i++)); do
            echo "${OPEN_TUNNELS[$i]}" 
        done
    else
        echo No open tunnels, use -c to create
    fi
}

usage(){ # Show usage of the script
    echo "usage: sshtunnel.sh [-l list] [-c create] [-d destroy]"
}

# Check if params are specified
if [ -z "$*" ]; then
    usage # If no params are specified show usage
else
    # Loop through given params
    while getopts ":cdl" opt; do
        case $opt in
            c) # create new Tunnel
		create
                ;;
            d) # Destroy Tunnel
		destroy
                ;;
	    l) # List open tunnels
                list
                ;;
            *) # Other
                usage # If invalid params are specified show usage
                ;;
        esac
    done
fi
