killssh() {
    for pts in /dev/pts/*; do
        fuser -u $pts -k
    done
}

showtty() {
    ps -aux | grep tty
}

showfaillog() {

    if [ "`sudo ls /var/log/audit/audit.log 2>/dev/null`" != "" ]; then
        sudo tail /var/log/audit/audit.log -n 40 | grep fail
    fi

    if [ "`sudo ls /var/log/auth.log 2>/dev/null`" != "" ]; then
        sudo tail /var/log/auth.log -n 40 | grep fail
    fi
}

if [ "`which chattr 2>/dev/null`" != "" ]; then
    sudo mv /usr/bin/chattr /usr/bin/ttr 
fi

alias chattr=/usr/bin/ttr
