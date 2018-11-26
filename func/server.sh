#!/bin/bash

function startDaemon {

  local LASTTIMERAPATTACK=0
  local LRESULT=""
  local LAUXILIARYSOFT=""
  
  stopZombieProcess

  LAUXILIARYSOFT=${AUXILIARYSOFT[@]}
  LRESULT=$(checkExistsPrograms "$LAUXILIARYSOFT")
  if [ $? != 0 ];then
    logOutput "alert" "Program($LRESULT) Not installed. Plz install these programs: apt install aircrack-ng sqlite3 nmap hostapd dnsmasq macchanger libxml2-utils  \n"
    exit 1
  fi

  if ( "$STARTUI" );then
    GLOBALDOLOGHTML=true
    startWebUI
  fi
  
  if [ ! -f "$OUIFILEPATH" ];then
    logOutput "info" "Download OUI file\n"
    downloadOUIFile  
  fi
  
  createDirectory

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
