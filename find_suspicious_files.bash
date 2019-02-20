#!/bin/bash

# It is ok to have files with 's' bit set in 
# '/bin' directory, but that's about it
# 
# It is usually a good practice to save 
# the list of files with 's' bit and
# make sure it does not change

IFS=$'\n'
for f in $(find {/bin/,/var/,/etc/}); do
	if [ ! -f $f ]; then
		continue
	fi

    # Look for files that can be executed as root
	s="`ls -l $f | cut -d' ' -f1 | egrep 's|S'`"
	if [ "$s" != "" ]; then
		echo "`ls -l $f`"
	fi

    # TODO: look for files executable by everyone in /var/
done
