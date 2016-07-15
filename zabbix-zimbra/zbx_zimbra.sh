#!/bin/sh

# Zabbix script to check Zimbra services and perform service discovery.
# Supports Zimbra 8.6 and "two-worded" service names
# Author: Lorenzo Milesi <maxxer@yetopen.it>
# Copytight: YetOpen S.r.l. 2016
# License: GPLv3

# uncomment for debug
#set -x

COMMAND="sudo -u zimbra /opt/zimbra/bin/zmcontrol"
FILE='/var/run/zabbix/zimbra_status'
DISCOVER_FILE='/var/run/zabbix/zimbra_discover'

fork_get_status() {
    maxage=100

    # Very basic concurrency check
    x=0
    while [ -f "$FILE.tmp" ]; do
        sleep 5;
        x=$((x+1))
        # don't wait too long anyway, remove an eventually stale lock. Anyway we have 15s zabbix agent timeout
        if [ $x -ge 3 ]; then
            rm "$FILE.tmp";
        fi
    done
    #check if cached status file size > 0
    if [ -s ${FILE} ]; then
        OLD=`stat -c %Z $FILE`
        NOW=`date +%s`

    # if older then maxage, update file
    if [ `expr $NOW - $OLD` -gt $maxage ]; then
        $COMMAND status > $FILE.tmp
        mv $FILE.tmp $FILE
    fi
    else
        rm -f ${FILE}
        $COMMAND status > $FILE.tmp
        mv $FILE.tmp $FILE
    fi
}

fork_discover() {
    # Return a list of running services in JSON
    SRVCS=$($COMMAND status | grep -v ^Host | awk '{$(NF--)=""; print}' | sed 's/^/\t{ \"{#ZIMBRASERVICE}\":\"/' | sed 's/\ $/\" },/')
    echo "{"
    echo "\t\"data\":[\n"
    # Remove last comma from the sting, to make a good JSON
    echo $(echo $SRVCS | sed 's/,\+$//')
    echo "\n\t]\n"
    echo "}"
}

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
	[ -f "$DISCOVER_FILE" ] &&  cat $DISCOVER_FILE
	fork_discover > $DISCOVER_FILE &
    exit 0;
    ;;
    *)
    # move on...
        check=$1

	if [ "$check" = "" ]; then
	  echo "No Zimbra service specified..."
	  exit 1
	fi

        fork_get_status &

	STATUS="$(cat $FILE | grep "$check" | awk '{print $NF}')"

	if [ "$STATUS" != "Running" ]; then
	  echo 0
	else
	  echo 1
	fi
    ;;
esac

exit 0;
