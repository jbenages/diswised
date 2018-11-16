#!/bin/bash

trap ctrl_c INT

function ctrl_c() {
  #stopSniff
  #stopRAPAttack
  exit 0
}

function createDirectory {
  mkdir -p $CURRENTDIR/data/tmp/{log,PID,csv,nmap}
}

## Main function
function main(){
 
  local LASTTIMERAPATTACK=0
  
  createDirectory

  ## Software needed: aircrack-ng, hostapd, dnsmasq, macchanger, sqlite3, libxml2-utils
  
  stopZombieProcess

  startSniff
  sleep 20
  
  while true; do
    putCaptureDataToDB
    findClientToAudit
    if [ ! -z "$CLIENTTOAUDIT" ];then
      stopSniff
      stopServices
      startRAPAttack "$CLIENTTOAUDIT" "$ROUTERESSID" "$ROUTERMAC" "$ROUTERCHANNEL"
      LASTTIMERAPATTACK=$(date +%s)
      while [ $(( LASTTIMERAPATTACK+TIMERAPATTACK+TIMERAPATTACKINCREASE )) -ge $( date +%s ) ];do
        findTargets "$CLIENTTOAUDIT"
	TIMERAPATTACKINCREASE=0
      done
      storeTargets
      scanTargets
      markAttackTargets
      stopRAPAttack
      startSniff
      sleep 20
    fi 
  done

}
