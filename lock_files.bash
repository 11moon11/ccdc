#!/bin/bash

# Good directories to monitor:
# /tmp/
# /etc/
# /home/user/.shh/

rec() { 
    local dir="`realpath $1`"
    local dest="$backup_dir$dir"

    # Need to avoid backing up backup directory
    if [ "$dir" != "$backup_dir" ]; then
        # Re-Create folder structure in backup folder
        if [ -d $dir ]; then
            if [ ! -d $dest ]; then
                mkdir -p $dest
            fi
        fi

        # can be refactored, but due to the lack of time I did not
        # if individual file is specified (not a folder)
        if [ -f $dir ]; then
            local b_file="$dest"

            # if file exists in the backup directory - get hash from backup dir
            if [ -f $b_file ]; then
                local old_hash="`sha256sum $b_file | cut -d' ' -f1`"
                files["$dir"]="$old_hash"

                local curr_hash="`sha256sum $dir | cut -d' ' -f1`"
                # if hash of the file does not match to the hash of the backup file
                if [ "$old_hash" != "$curr_hash" ]; then
                    echo "[!!!] File '$dir' has been modified"

                    # if recover flag is set - attempt to recover
                    if [ "$recover_flag" == "yes" ]; then
                        cp $b_file $dir

                        # if hashes still do not match after recovery - display an error message
                        if [ "$old_hash" != "`sha256sum $dir | cut -d' ' -f1`" ]; then
                            echo "[-] Failed to recover file '$dir' from backup"
                        else
                            echo "[+] Successfully recovered file '$dir' from backup"
                        fi
                    fi
                fi
            else
                echo "I have not seen this file before: '$dir'"
                files["$dir"]="`sha256sum $dir | cut -d' ' -f1`"
                mkdir -p "`dirname $b_file`" 
                cp $dir $b_file
            fi

            return
        fi

        # if it's a directory - do recursion
        for i in `ls -A $dir`; do 
            f="$dir/$i"
            
            if [ -f $f ]; then # If it's a file
                local b_file="$dest/$i"

                # if file exists in the backup directory - get hash from backup dir
                if [ -f $b_file ]; then
                    local old_hash="`sha256sum $b_file | cut -d' ' -f1`"
                    files["$f"]="$old_hash"

                    local curr_hash="`sha256sum $f | cut -d' ' -f1`"
                    # if hash of the file does not match to the hash of the backup file
                    if [ "$old_hash" != "$curr_hash" ]; then
                        echo "[!!!] File '$f' has been modified"

                        # if recover flag is set - attempt to recover
                        if [ "$recover_flag" == "yes" ]; then
                            cp $b_file $f

                            # if hashes still do not match after recovery - display an error message
                            if [ "$old_hash" != "`sha256sum $f | cut -d' ' -f1`" ]; then
                                echo "[-] Failed to recover file '$f' from backup"
                            else
                                echo "[+] Successfully recovered file '$f' from backup"
                            fi
                        fi
                    fi
                else # if file does not exist in the backup directory - get hash of the original file and copy original to backup
                    echo "I have not seen this file before: '$f'"
                    files["$f"]="`sha256sum $f | cut -d' ' -f1`"
                    cp $f $b_file
                    #echo "File: $f"
                    #echo "`sha256sum $f`"
                fi
            elif [[ -d $f ]]; then # If it's a directory
                rec "$f"
            fi 
        done
    fi 
} 

usage() {
    echo "Usage: sudo $0 [-rd yes/no] [-f infile1] [-f infile2] ..."
    echo "  -d        Delete all backed up files (default: no)"
    echo "  -r        Enable recovery mode (default: no)"
    echo "  -f        Folder/File to backup"
    exit 1
}

backup_dir="`realpath .`/backup"
declare -A files

recover_flag="no"
delete_backup="no"
folders_to_backup=()

if [ $# -eq 0 ]; then
    usage
fi

while getopts r:d:h:f: option; do
    case "${option}"
    in
        d) delete_backup=${OPTARG} ;;
        r) recover_flag=${OPTARG} ;;
        h) usage ;;
        f) folders_to_backup+=("${OPTARG}") ;;
    esac
done

if [ "$delete_backup" == "yes" ]; then
    rm -rf "$backup_dir"
    exit 0
fi

if [ ! -d $backup_dir ]; then
    mkdir $backup_dir
fi

for i in ${folders_to_backup[@]}; do
    echo "Working on '$i'..."
    rec $i
done

#for file in "${!files[@]}"; do 
#    echo "File: $file"
#    echo "Hash: ${files[$file]}"
#done
