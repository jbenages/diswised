#!/bin/bash

function generateUIConfigHostapd {
  export CINTERFACE=$1 CESSID=$2 CCHANNEL=$3 CPASSWORD=$4
  envsubst < "$CURRENTDIR/conf/hostapd/diswisedui.conf"
}

function generateConfigDnsmasqUI {
  export CINTERFACE=$1 CIPRANGE=$2 CIPMASK=$3 CIP=$4
  envsubst < "$CURRENTDIR/conf/dnsmasq/diswised.conf"
}


function startWebUI {
  
  declare LHOSTAPDCONF=""
  declare LDNSMASQCONF=""

  LHOSTAPDCONF=$( generateUIConfigHostapd "$INTERFACEUI" "$ESSIDUI" "$CHANNELUI" "$PASSWORDUI" )
  HOSTAPDUIPID=$( startHostapd "$LHOSTAPDCONF" "$CURRENTDIR/data/tmp/log/hostapd-ui.log" )
  storePID "$HOSTAPDUIPID" "$CURRENTDIR/data/tmp/PID/hostapd-ui"
  logOutput "info" "Start UI hostapd service \n" 

  asignIPInterface "$INTERFACEUI" "$IPAPUI"

}
