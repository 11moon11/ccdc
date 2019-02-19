#!/bin/bash

while [ "$1" != "" ]; do  
    pass=$(openssl rand -base64 10)
    echo "Username: '$1' Password: '$pass'"
    
    useradd $1
    echo "$1:$pass" | chpasswd

    shift
done
