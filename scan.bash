#!/bin/bash

ALARM='\e[41m\e[30m'
SELECT='\e[107m\e[30m'
WARNING='\e[43m\e[30m'
DEFAULT='\e[49m\e[39m'

if [ $EUID -ne 0 ]; then
    echo "Usage: sudo $0"
    exit 0
fi

# =====================================================
# ================ Existing User Perms ================

echo -e "$WARNING\tAll loginable users:\t$DEFAULT"
for u in $(egrep -v "nologin|sync|shutdown|halt" /etc/passwd); do
    echo "$u"
done

echo -e "\n$WARNING\tAll users with a password:\t$DEFAULT"
for u in $(grep "\\$" /etc/shadow); do
    echo $u
done

echo -e "\n$WARNING\tUsers with EUID 0:\t$DEFAULT"
for u in $(cut -d":" -f1,3 /etc/passwd | grep :0); do
    if [ "$u" != "root:0" ]; then
        echo -e "$ALARM$u$DEFAULT"
    else
        echo $u
    fi
done

# =====================================================
# ================ Authorised SSH Keys ================

auth_keys_path=()
for p in $(grep AuthorizedKeysFile /etc/ssh/sshd_config | sed 's/\t/ /g' | cut -d' ' -f2); do
    auth_keys_path+=("$p")
done

# if not set, default to .ssh/authorized_keys and .ssh/authorized_keys2
if [[ "${auth_keys_path[0]}" == "" ]]; then
    auth_keys_path+=(".ssh/authorized_keys")
    auth_keys_path+=(".ssh/authorized_keys2")
fi
echo -e "\n$SELECT\tSearching for authorised keys:\t$DEFAULT"

home_dirs=()
home_dirs+=("/root")
for h in $(cut -d":" -f6 /etc/passwd | sort | uniq); do
    home_dirs+=("$h")
done

for home in ${home_dirs[@]}; do
    for key_path in ${auth_keys_path[@]}; do
        path="$home/$key_path"
        if [ -f $path ] && [ -s $path ]; then
            echo -e "${ALARM}Found an auth key: '$path'\t$DEFAULT"
            cat $path
        fi
    done
done

# =====================================================
# ================ Sudoers Config File ================

echo -e "\n$WARNING\tContents of '/etc/sudoers' file:\t$DEFAULT"
egrep -v "^#|^$" /etc/sudoers
for f in $(ls -A /etc/sudoers.d/); do
    echo -e "\n$WARNING\tContents of '/etc/sudoers.d/$f' file:\t$DEFAULT"
    egrep -v "^#|^$" "/etc/sudoers.d/$f"
done

# =====================================================
# ================== Curr Open Ports ==================

sudo netstat -tlpn

# ====================================================
# ================== Notify On SSH

#for tty in $(ps -e | tail -n +2 | sed "s/^[ \t]*//" | cut -d" " -f2 | sort | uniq | grep -v ?); do
#    echo "`tty` just connected via SSH!" >> /dev/$tty
#done

mkdir /root/.ssh
for home in ${home_dirs[@]}; do
    if [ -d "$home/.ssh" ]; then
        file="$home/.ssh/rc"
        # Below seting is a base64 of the commented code above
        echo "Zm9yIHR0eSBpbiAkKHBzIC1lIHwgdGFpbCAtbiArMiB8IHNlZCAicy9eWyBcdF0qLy8iIHwgY3V0IC1kIiAiIC1mMiB8IHNvcnQgfCB1bmlxIHwgZ3JlcCAtdiA/KTsgZG8gZWNobyAiYHR0eWAganVzdCBjb25uZWN0ZWQgdmlhIFNTSCEiID4+IC9kZXYvJHR0eTsgZG9uZQ==" | base64 -d > $file
    fi
done
