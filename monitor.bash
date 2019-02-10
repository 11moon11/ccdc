#!/bin/bash
# ------------------------------------------------------------
# Date created: 12/17/2018
# Created by: Kirill Kozlov (kkozlov42@students.tntech.edu)
# Description: Following script monitors currently open shells
#   and provides basic information about them
# ------------------------------------------------------------

# How to use:
# 1) Run the script ./monitor.bash
# 2) Use arrow keys to naviage between shell session
# 3) Press 'k' to kill the shell
#

ALARM='\e[41m\e[30m'
SELECT='\e[107m\e[30m'
WARNING='\e[43m\e[30m'
DEFAULT='\e[49m\e[39m'

# TODO: --help | -h

clean_exit() {
    if [ -t 0 ]; then stty sane; fi
    
    echo -e "\n$ALARM*** Thank you for using my monitoring script :)                                               "
    echo -e "*** If you have any suggestions/comments, feel free to email me: kkozlov42@students.tntech.edu$DEFAULT"

    exit 0
}

# Will clear all visible lines on the screen
cls() {
    delete_lines $(tput lines)
}

# Will delete given number of lines above current position
delete_lines() {
    for i in `seq 1 $1`; do
        tput cuu1   # move up
        tput el     # clear line
    done
}

# Given the session information will echo it in the right format
format_sessions() {
    local max_len=$(($(tput cols)-65))    # Account for long strings
    local tmp_num_sessions=$(($num_sessions-1))

    echo -e "$WARNING\
        Number of active shell sessions: $num_sessions\
        $DEFAULT\n"
    for s in `seq 0 $tmp_num_sessions`; do
        local tmp_pid=("${pid_arr[$s]}")
        local tmp_tty=("${tty_arr[$s]}")
        local tmp_user=("${user_arr[$s]}")
        local tmp_procs=("${procs_arr[$s]}")
        
        # Cut processes if they do not fit in 1 line
        if [ $(echo "$tmp_procs" | wc -c) -ge "$max_len" ]; then
            tmp_procs="$(echo "$tmp_procs" | cut -c 1-$max_len) ..."
        fi

        if [ "$s" -eq "$sel_sess" ]; then
            echo -ne "$SELECT[*]$DEFAULT "
        else
            echo -ne "$SELECT[ ]$DEFAULT "
        fi
      
        if [[ "${warnings[@]}" == *"$tmp_pid"* ]]; then
            echo -ne "$ALARM" 
        fi

        echo -e "pid: $tmp_pid\tTTY: $tmp_tty \tuser: $tmp_user \tprocs: $tmp_procs$DEFAULT"
    done
}

# Returns "yes" if new shell was opened, "no" otherwise
has_new_shell() {
    warnings=()
    local tmp_pid_arr=("$@")
    local cop_pid_arr=("${pid_arr[@]}")

    for i in "${tmp_pid_arr[@]}"; do
        local found=0
        for j in "${pid_arr[@]}"; do
           if [ "$i" -eq "$j" ]; then
               found=1
               break
           fi
        done
        
        if [ "$found" -eq 0 ]; then
            warnings+=("$i")   
        fi
    done
}

# Will obtain information about currently open shells
# TODO: Allow user to choose what information to display
update_sess() {
    local pids=$(pgrep "sh")
    local tmp_num_sessions=0

    local new_pid_arr=()
    local new_tty_arr=()
    local new_user_arr=()
    local new_procs_arr=()

    for pid in $pids; do
        shell=$(ps -e | grep $pid | tr -s ' ' | sed -e 's/^[[:space:]]*//' | cut -d' ' -f2)

        # Discard current shell and graphical sessions
        # TODO: Also monitor graphical sessions
        if [ "$acti" != "$shell" -a "$shell" != "" -a "$shell" != "?" ]; then
            local user=$(ps -u -p $pid | grep $pid | tr -s ' ' | sed -e 's/^[[:space:]]*//' | cut -d' ' -f1)
            local procs=$(ps -e | grep "$shell" | tr -s ' ' | sed -e 's/^[[:space:]]*//' | cut -d' ' -f4 | grep -v bash | tr '\n' ' ')
           
            # Store full information about each session
            local sess=("$procs")
            new_pid_arr+=("$pid")
            new_tty_arr+=("$shell")
            new_user_arr+=("$user")
            new_procs_arr+=("${sess[@]}")
        
            let tmp_num_sessions+=1
        fi
    done

    # TODO: Monitor changes in running processes
     
    has_new_shell "${new_pid_arr[@]}"

    num_sessions="$tmp_num_sessions"
    # Discard old session information
    pid_arr=("${new_pid_arr[@]}")
    tty_arr=("${new_tty_arr[@]}")
    user_arr=("${new_user_arr[@]}")
    procs_arr=("${new_procs_arr[@]}")
}

# Will update 'key' and other variables depending on key pressed
check_key_press() {
    key="`cat -v`"

    if [ "$key" = "q" ]; then
        clean_exit
    elif [ "$key" = "^[[B" -a "$sel_sess" -lt "$(($num_sessions-1))" ]; then
        let sel_sess+=1
        delete_lines $(($num_sessions+3))
        format_sessions
    elif [ "$key" = "^[[A" -a "$sel_sess" -ge 0 ]; then
        let sel_sess-=1
        delete_lines $(($num_sessions+3))
        format_sessions
    elif [ "$key" = "k" ]; then
        kill -9 "${pid_arr[$sel_sess]}"
        delete_lines $(($num_sessions+3))
        let sel_sess-=1
    fi
    # TODO: implement more features (ex: ban users, lockdown mode, increase/decrease refresh rate)
}

# Array containing shell pids that can be ignored
# Initialized to current pid by default
ignore_pids=($$)

# Array containing line ids with warnings
warnings=()

# Array containing information about currently open shell sessions
sessions=()
pid_arr=()
tty_arr=()
user_arr=()
procs_arr=()

# Used to track number of sessions active
num_sessions=0

# TTY of of session current monitoring script is open in
acti=$(tty | cut -d'/' -f3,4)

# Variable used to keep track of keys pressed
key=''

# Graceful exit on Ctrl-C
trap clean_exit INT

if [ -t 0 ]; then stty -echo -icanon -icrnl time 0 min 0; fi

cls

# Main event loop
timer=20
sel_sess=-1
while : ; do
    if [ "$timer" -eq 20 ]; then # Update session information every 2 sec
        update_sess
        timer=0
        delete_lines $(($num_sessions+3))
        format_sessions
    fi
    
    check_key_press

    sleep 0.1 # sleep for 100 ms
    let timer+=1
done

clean_exit

read -p "Clear? (yes/no): " val
if [ $val = "yes" ]; then
    delete_lines 4
fi
