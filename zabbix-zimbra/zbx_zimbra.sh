#!/bin/sh

# Zabbix script to check Zimbra services and perform service discovery.
# Supports Zimbra 8.6 and "two-worded" service names
# Author: Lorenzo Milesi <maxxer@yetopen.it>
# Copytight: YetOpen S.r.l. 2015
# License: GPLv3

# uncomment for debug
#set -x

COMMAND="sudo -u zimbra /opt/zimbra/bin/zmcontrol"

case "$1" in
    version) 
    # Return zimbra version
    VERS=$($COMMAND -v)
    if [ $? -eq 0 ] ; then
        echo $VERS
        exit 0;
    fi
    # error
    exit 1;
    ;;
    discover) 
    # Return a list of running services in JSON
	echo "{"
	echo -e "\t\"data\":[\n"
    	SRVCS=$($COMMAND status | grep Running | awk '{$(NF--)=""; print}' | sed 's/^/\t{ \"{#ZIMBRASERVICE}\":\"/' | sed 's/\ $/\" },/')
	# Remove last comma from the sting, to make a good JSON
	echo $(echo $SRVCS | sed 's/,\+$//')
	echo -e "\n\t]\n"
	echo "}"
    exit 0;
    ;;
    *)
    # move on...
	check=$1

	if [ "$check" = "" ]; then
	  echo "No Zimbra service specified..."
	  exit 1
	fi

	maxage=120
	file='/var/run/zabbix/zimbra_status'

	# Very basic concurrency check
	x=0
	while [ -f "$file.tmp" ]; do
		sleep 5;
		x=$((x+1))
		# don't wait too long anyway, remove an eventually stale lock. Anyway we have 15s zabbix agent timeout
		if [ $x -ge 3 ]; then
			rm "$file.tmp";
		fi
	done
	#check if cached status file size > 0
	if [ -s ${file} ]; then 
	  OLD=`stat -c %Z $file`
	  NOW=`date +%s`

	  # if older then maxage, update file
	  if [ `expr $NOW - $OLD` -gt $maxage ]; then
	    $COMMAND status > $file.tmp
	    mv $file.tmp $file
	  fi
	else
	    rm -f ${file}
	    $COMMAND status > $file.tmp
	    mv $file.tmp $file
	fi

	STATUS="$(cat $file | grep -w "$check" | awk '{print $NF}')"

	if [ "$STATUS" != "Running" ]; then
	  echo 0
	else
	  echo 1
	fi
    ;;
esac

exit 0;

