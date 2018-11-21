#!/bin/bash

# Path of excecution script
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
CURRENTDIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

# Charge system configuration
source $CURRENTDIR"/conf/conf.cfg"

# Chrage global variables
source "$CURRENTDIR/conf/vars.cfg"

# Libraries
. $CURRENTDIR/lib/array.sh
. $CURRENTDIR/lib/network.sh
. $CURRENTDIR/lib/system.sh
. $CURRENTDIR/lib/aircrack.sh
. $CURRENTDIR/lib/sqlite.sh
. $CURRENTDIR/lib/hostapd.sh
. $CURRENTDIR/lib/dnsmasq.sh
. $CURRENTDIR/lib/xmllint.sh
. $CURRENTDIR/lib/nmap.sh

# Functions
. $CURRENTDIR/func/log.sh
. $CURRENTDIR/func/system.sh
. $CURRENTDIR/func/db.sh
. $CURRENTDIR/func/sniff.sh
. $CURRENTDIR/func/rogueap.sh
. $CURRENTDIR/func/scan.sh
. $CURRENTDIR/func/server.sh
. $CURRENTDIR/func/webui.sh
. $CURRENTDIR/func/main.sh

main $@
