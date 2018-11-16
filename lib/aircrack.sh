#!/bin/bash

## Start sniff WiFi data network
# 1: Monitor interface name | 2: Path where store data
# print: PID of airdodump command
function putMonitorToSniff {
  local LMONITOR=$1
  local LPATHDATA=$2
  airodump-ng -w "$LPATHDATA" "$LMONITOR" > /dev/null 2>&1 &
  printf $!
}

## Start monitor interface
# 1: interface name 
function startMonitor {
  local INTERFACETOMONITOR=$1
  airmon-ng start $INTERFACETOMONITOR > /dev/null 2>&1
}

## Stop monitor interface
# 1: monitor interface name 
function stopMonitor {
  local MONITORTOSTOP=$1
  airmon-ng stop $MONITORTOSTOP > /dev/null 2>&1
}

## Kill process osbtruct monitor in interfaces
function killProcessInterface {
  airmon-ng check kill
}
