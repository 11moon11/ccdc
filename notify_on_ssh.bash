#!/bin/bash

prev=$(ls -A /tmp/users/)

while true; do
    curr=$(ls -A /tmp/users/)
    if [[ "$(diff <(echo "$prev") <(echo "$curr"))" != "" ]]; then
        echo -e "Someonce logged in using SSH!"
        prev=$(ls -A /tmp/users/)
    fi
    sleep 2
done
