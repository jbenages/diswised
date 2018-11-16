#!/bin/bash

## Start process for put interface in monitor mode and sniff.
function startSniff {
	 
  if [ -f "$CURRENTDIR/data/airmon/monitorinterface" ]; then   
    MONITOR=$( cat "$CURRENTDIR/data/airmon/monitorinterface" )
    logOutput "info" "Charge last used monitor interface $MONITOR \n" 
  fi

  if [ -z "$MONITOR" ];then
    logOutput "info" "1 start mode monitor in interface $INTERFACE \n" 
    startMonitor "$INTERFACE"
    if [ $? != 0 ];then
      logOutput "alert" "Fail to start monitor mode in interface $INTERFACE \n" 
      exit 1
    fi
  fi

  checkIfExistsInterface "$INTERFACE""mon"
  if [ $? == 0 ];then
    logOutput "info" "2 start mode monitor in interface $INTERFACE \n" 
    startMonitor "$INTERFACE"
    if [ $? != 0 ];then
      logOutput "alert" "Fail to start monitor mode in interface $INTERFACE \n" 
      exit 1
    fi
  fi

  MONITOR="$INTERFACE""mon"
  echo "$MONITOR" > "$CURRENTDIR/data/airmon/monitorinterface"

  logOutput "info" "Clear old data of last sniff \n" 
  rm $CURRENTDIR/data/airodump/diswised-* > /dev/null 2>&1

  logOutput "info" "start sniff data on monitor $MONITOR \n" 
  AIRODUMPPID=$( putMonitorToSniff "$MONITOR" "$CURRENTDIR/data/airodump/diswised" )
  storePID "$AIRODUMPPID" "$CURRENTDIR/data/tmp/PID/airodump"

}

## Stop process of sniff and clear monitor mode
function stopSniff {
  logOutput "info" "Kill airodump process \n"
  kill -9 $( cat "$CURRENTDIR/data/tmp/PID/airodump" ) > /dev/null 2>&1
  logOutput "info" "Stop monitor $MONITOR \n" 
  stopMonitor "$MONITOR"
  rm "$CURRENTDIR/data/airmon/monitorinterface"
}
