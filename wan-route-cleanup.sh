#!/bin/sh

LOG_TAG="wan-route-cleanup"

WAN_IF=$(netstat -rn -f inet | awk '$1 == "default" {print $NF; exit}')

if [ -z "$WAN_IF" ]; then
    logger -t "$LOG_TAG" "ERROR: default route not found"
    exit 1
fi

# echo "WAN interface: $WAN_IF"

ROUTES=$(netstat -rn -f inet | awk -v wan="$WAN_IF" '$NF == wan && $3 ~ /G/ && $3 ~ /H/ && $1 ~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/ {print $1}')

for IP in $ROUTES
do
    # echo "Deleting: $IP"
    logger -t "$LOG_TAG" "Deleting WAN host route: $IP"
    route delete -host "$IP"
done
