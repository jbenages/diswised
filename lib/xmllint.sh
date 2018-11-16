#!/bin/bash

function extractOSXML {
  local LPATHFILE="$1"
  xmllint "$LPATHFILE" --xpath 'string(//osmatch[1]/@name)' > /dev/null 2>&1
}

function extractHostnameXML {
  xmllint "$LPATHFILE" --xpath 'string(//hostname[1]/@name)' > /dev/null 2>&1
}

function extractPortsXML {
  local LRESULT=""
  local LPATHFILE="$1"
  LRESULT=$( xmllint "$LPATHFILE" --xpath '//port/@portid' ) > /dev/null 2>&1
  LRESULT="$LRESULT $( xmllint "$LPATHFILE" --xpath '//port/state/@state' > /dev/null 2>&1 )" 
  LRESULT="$LRESULT $( xmllint "$LPATHFILE" --xpath '//port/service/@name' > /dev/null 2>&1 ) " 
}
