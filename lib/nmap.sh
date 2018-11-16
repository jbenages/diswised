#!/bin/bash

function scanNmap {
  local LIP=$1
  local LPATHFILE=$2
  nmap -F -O "$LIP" -oX "$LPATHFILE" > /dev/null 2>&1
}
