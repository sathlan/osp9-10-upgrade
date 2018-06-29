#!/usr/bin/env bash

set -eu
. instance.txt

IP="$fip"
ID="$instance"                      # free form string
STATUS='unknown'
LOG=current_state_${IP}_${ID}.log

[ ! -e "$LOG" ] || exit 0

current_state_for()
{
    local ip=$1
    if [ -e $LOG ]; then
        STATUS=$(tail -n -1 $LOG | cut -d: -f1)
    fi
}

(
    while true; do
        current_state_for $IP
        if ping -c 1 $IP; then
            if [ "${STATUS}" != 'up' ]; then
                echo up:$(date '+%s'):$(date) >> $LOG
            fi
        else
            if [ "${STATUS}" != 'down' ]; then
                echo down:$(date '+%s'):$(date) >> $LOG
            fi
        fi
        sleep 1
    done
) </dev/null >/dev/null &

disown
exit 0
