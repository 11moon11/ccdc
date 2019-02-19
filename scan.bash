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

echo -e "\n$WARNING\tCurrently open ports:\t$DEFAULT"
sudo netstat -tlpn

# ====================================================
# ================== Notify On SSH  ==================

#for tty in $(ps -e | tail -n +2 | sed "s/^[ \t]*//" | cut -d" " -f2 | sort | uniq | grep -v ?); do
#    echo "`tty` just connected via SSH!" >> /dev/$tty
#done

#f_n="/tmp/users/${USER}_`date +%F-%R:%S`.log"; echo "$SSH_CONNECTION - `tty` - just connected via SSH" > $f_n

mkdir /tmp/users
chmod 777 -R /tmp/users
# Below seting is a base64 of the commented code above
echo "Zl9uPSIvdG1wL3VzZXJzLyR7VVNFUn1fYGRhdGUgKyVGLSVSOiVTYC5sb2ciOyBlY2hvICIkU1NIX0NPTk5FQ1RJT04gLSBgdHR5YCAtIGp1c3QgY29ubmVjdGVkIHZpYSBTU0giID4gJGZfbg==" | base64 -d > /etc/ssh/sshrc
