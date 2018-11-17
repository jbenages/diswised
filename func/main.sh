#!/bin/bash

trap ctrl_c INT

function ctrl_c() {
  #stopSniff
  #stopRAPAttack
  exit 0
}

function createDirectory {
  mkdir -p $CURRENTDIR/data/{tmp,airmon,airodump,csv,db,oui}
  mkdir -p $CURRENTDIR/data/tmp/{log,PID,csv,nmap}
}

## Main function
function main(){
 
  local LASTTIMERAPATTACK=0
  local LRESULT=""
  local LAUXILIARYSOFT=""
 
  LAUXILIARYSOFT=${AUXILIARYSOFT[@]}
  LRESULT=$(checkExistsPrograms "$LAUXILIARYSOFT")
  if [ $? != 0 ];then
    logOutput "alert" "Program($LRESULT) Not installed. Plz install these programs: apt install aircrack-ng sqlite3 nmap hostapd dnsmasq macchanger libxml2-utils  \n"
    exit 1
  fi
  
  if [ ! -f "$OUIFILEPATH" ];then
    logOutput "info" "Download OUI file\n"
    downloadOUIFile  
  fi  
  
  createDirectory
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
