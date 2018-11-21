#!/bin/bash

function startDnsmasq {
  local LCONF=$1
  local LLOGPATH=$2
  local LDNSMASQLEASEFILE=$3
  dnsmasq --clear-on-reload -l "$LDNSMASQLEASEFILE" -C <( printf "$LCONF" ) > "$LLOGPATH" 2>&1 &
  sleep 1
  cat /var/run/dnsmasq.pid
}
