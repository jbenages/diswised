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

  checkIfExistsInterface "$INTERFACE"
  if [ $? == 0 ];then
    logOutput "alert" "Not exists interface $INTERFACE \n"
    exit 0
  fi

  if ( "$STARTUI" );then
    checkIfExistsInterface "$INTERFACEUI"
    if [ $? == 0 ];then
      logOutput "alert" "Not exists WiFi $INTERFACEUI, can't start UI interface \n"
      exit 0
    fi
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
    if [ -z "$FIXEDTARGET" ];then
      findClientToAudit
    else
      findFixedTarget  
    fi
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
      if ( $FIXEDTARGETCATCHED );then
        logOutput "objective" "Catch target client ($FIXEDTARGET)\n"
	exit 0
      fi
      startSniff
      sleep 20
    fi 
  done

}
