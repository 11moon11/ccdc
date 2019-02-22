#!/bin/bash

if [ $# -lt 1 ]; then
	echo "Please specify the domain (ex: CCDC)"
	exit 0
fi

for u in $(wbinfo -u); do mkdir -p /home/$1/$u; chown $u:"Domain Users" /home/$1/$u; done
