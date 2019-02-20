#!/bin/bash

#
# This will block all non-essential services
#   Usage: config_iptables.bash 
# 
# To restore iptables back to default allow
#   Restore: config_iptables.bash default
#

#TODO: add help

default_allow() {
    iptables -P INPUT ACCEPT
    iptables -P OUTPUT ACCEPT
    iptables -P FORWARD ACCEPT
}

default_deny() {
    iptables -P INPUT DROP
    iptables -P FORWARD DROP
    iptables -P OUTPUT DROP
}

allow_established() {
    iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
    iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
}

flush() {
    iptables -F
    iptables --delete-chain
}

display() {
    echo "Final iptables look like this:"
    echo "`iptables -L`"
}

if [[ $EUID -ne 0 ]]
then
    echo "This script must be run as root" 
	exit 1
fi

network="172.20.240.1/24"
echo "Using following network: $network"
#prot="$(netstat -tln | tr -s ' ' | egrep "(tcp|udp) " | cut -d' ' -f1)"
#port="$(netstat -tln | tr -s ' ' | egrep "(tcp|udp) " | cut -d' ' -f4 | cut -d':' -f2)"

# Flush current iptables
flush

if [ "$1" = "default" ]; then
    default_allow
    exit 0
fi

# Set default policies for all three default chains
default_deny

# Allow already established connections
#allow_established

# Block outgoing ICMP requests
iptables -A OUTPUT -p icmp --icmp-type 8 -j DROP

#-------------------------------------------------------------------------------------------------
# Loopback traffic
#-------------------------------------------------------------------------------------------------

# Allows all loopback (lo0) traffic
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT ! -i lo -d 127.0.0.0/8 -j REJECT
iptables -A OUTPUT -o lo -j ACCEPT

#-------------------------------------------------------------------------------------------------
# Outgoing traffic (if we want to access following services on a remote server)
#-------------------------------------------------------------------------------------------------

# $1 -> protocol
# $2 -> port
add_out() {
    iptables -A INPUT -p "$1" --sport "$2" -m state --state ESTABLISHED -j ACCEPT
    iptables -A OUTPUT -p "$1" --dport "$2" -m state --state NEW,ESTABLISHED -j ACCEPT
}

# SSH
add_out tcp 22

# DNS (UDP and TCP)
add_out udp 53
add_out tcp 53

# HTTP
add_out tcp 80

# HTTPS
add_out tcp 443

#-------------------------------------------------------------------------------------------------
# Incoming traffic (we are running services on a local machine and want others to have access)
#-------------------------------------------------------------------------------------------------

# $1 -> protocol
# $2 -> port
add_in() {
    iptables -A INPUT -p "$1" --dport "$2" -m state --state NEW,ESTABLISHED -j ACCEPT
    iptables -A OUTPUT -p "$1" --sport "$2" -m state --state ESTABLISHED -j ACCEPT
}

# SSH
add_in tcp 22022
#iptables -A INPUT -p tcp --dport 22022 -m state --state NEW,ESTABLISHED -j ACCEPT
#iptables -A OUTPUT -p tcp --sport 22022 -m state --state ESTABLISHED -j ACCEPT

# DNS
#add_in udp 53
#add_in tcp 53
#iptables -A INPUT -p udp --dport 53 -m state --state NEW,ESTABLISHED -j ACCEPT
#iptables -A OUTPUT -p udp --sport 53 -m state --state ESTABLISHED -j ACCEPT
##iptables -A INPUT -p tcp --dport 53 -m state --state NEW,ESTABLISHED -j ACCEPT
##iptables -A OUTPUT -p tcp --sport 53 -m state --state ESTABLISHED -j ACCEPT

# HTTP
#iptables -A INPUT -p tcp --dport 80 -m state --state NEW,ESTABLISHED -j ACCEPT
#iptables -A OUTPUT -p tcp --sport 80 -m state --state ESTABLISHED -j ACCEPT

# HTTPS
#iptables -A INPUT -p tcp --dport 443 -m state --state NEW,ESTABLISHED -j ACCEPT
#iptables -A OUTPUT -p tcp --sport 443 -m state --state ESTABLISHED -j ACCEPT

#-------------------------------------------------------------------------------------------------

display
