#!/bin/bash

function startHostapd {
  local LCONF=$1
  local LLOGPATH=$2
  hostapd <( printf "$LCONF" ) >  "$LLOGPATH" 2>&1 &
  printf $!
}

