#!/bin/bash

function storePID {
  local LPID=$1
  local LPATH=$2
  printf "$LPID" > "$LPATH"
}

function stopZombieProcess {
  shopt -s nullglob
  for file in "$CURRENTDIR"/data/tmp/PID/*
  do
    kill -9 $( cat "$file" ) > /dev/null 2>&1
  done

}

function getManufacturerFromMAC {
  
  local LMAC=$1
  local LPREFIX=""  

  LPREFIX=$LMAC
  LPREFIX="${LPREFIX//:/}"
  LPREFIX="${LPREFIX// /}"
  LPREFIX="${LPREFIX:0:6}"
  grep "$LPREFIX" "$OUIFILEPATH" | cut -d$'\t' -f3 | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'
  
}

function downloadOUIFile {
  wget --quiet --output-document "$OUIFILEPATH" "$OUIURL" > /dev/null 2>&1
}
 
