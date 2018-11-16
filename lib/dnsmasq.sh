#!/bin/bash

function startDnsmasq {
  local LCONF=$1
  local LLOGPATH=$2
  dnsmasq --clear-on-reload -C <( printf "$LCONF" ) > "$LLOGPATH" 2>&1 &
  sleep 1
  cat /var/run/dnsmasq.pid
}
