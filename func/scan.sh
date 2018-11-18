#!/bin/bash

function scanTargets {
  local LHOSTNAME=""
  local LOS=""
  local LPORT=""
  local LIP=""
  local LHOSTNAMEDNS=""
  local i=""
  local LDOSCAN=true
  local LRESULT=""
  local LMACLOWER="" 

  for i in "${LISTTARGETSMAC[@]}";do

    LIP=( $( grep "$i" /var/lib/misc/dnsmasq.leases | cut -d" " -f3 ) )
    LMACLOWER=$( echo "$i" | tr '[:upper:]' '[:lower:]' )
    LHOSTNAMEDNS=( $( grep "$LMACLOWER" /var/lib/misc/dnsmasq.leases | cut -d" " -f4 ) )
    scanNmap "$LIP" "$CURRENTDIR/data/tmp/nmap/$i.nmap.xml"
    LHOSTNAME=$( extractHostnameXML "$CURRENTDIR/data/tmp/nmap/$i.nmap.xml" )
    if [ ! -z $LHOSTNAME ] && [ $LHOSTNAME != "XPath set is empty" ];then
      LOS=$( extractOSXML "$CURRENTDIR/data/tmp/nmap/$i.nmap.xml" )
      LPORT=$( extractPortsXML "$CURRENTDIR/data/tmp/nmap/$i.nmap.xml" )
    fi
    
    LRESULT=$( updateClientRow "$i" "$LOS" "$LHOSTNAME" "$LPORT" "$LHOSTNAMEDNS" )
    if [ $? != 0 ];then 
      logOutput "alert" "SGDB error ($LRESULT) \n"
       exit 0 
    fi
  done

}	

function checkExistScanClient {
  local LCLIENTMAC=$1
  local LCLIENTID=""
 
  LCLIENTID=$( existsClient "$LCLIENTMAC" )
  if [ $? != 0 ];then
    logOutput "alert" "Database error ($LCLIENTID) \n"  
    exit 0
  fi

  if [ -z $LCLIENTID  ];then
    insertClientDB "$LCLIENTMAC" 
  fi
  
}

function storeTargets {	

  local LHOSTNAMEDNS=""
  local i=""
  local LRESULT=""
  local LASSOC=""
  local LRAPASSOC=""
  local LMACLOWER=""
  
  for i in "${LISTTARGETSMAC[@]}";do

    LRESULT=$( createClientRow "$i" )
    if [ $? != 0 ];then
      logOutput "alert" "Error in SGDB ($LRESULT) \n"
      exit 0
    fi
    
    if [ "$CLIENTTOAUDIT" == "$i" ];then
      LASSOC="true"
      LRAPASSOC="true"
    else
      LASSOC=""
      LRAPASSOC="true"
    fi

    LRESULT=$( createRelationClientRouterDB "$i" "$ROUTERESSID" "" "$LASSOC" "$LRAPASSOC" )
    if [  $? != 0 ];then
      logOutput "alert" "Error in SGDB ($LRESULT) \n"
      exit 0
    fi

    LRESULT=$( updateRelationClientRouter  "$i" "" "$ROUTERESSID" "$LASSOC" "$LRAPASSOC" )
    if [  $? != 0 ];then
      logOutput "alert" "Error in SGDB ($LRESULT) \n"
      exit 0
    fi
    
    LMACLOWER=$( echo "$i" | tr '[:upper:]' '[:lower:]' )
    LHOSTNAMEDNS=( $( grep "$LMACLOWER" /var/lib/misc/dnsmasq.leases | cut -d" " -f4 ) )
    LRESULT=$( updateClientRow "$i" "" "" "" "$LHOSTNAMEDNS" )
    if [ $? != 0 ];then
      logOutput "alert" "Error in SGDB ($LRESULT) \n"
      exit 0
    fi
    logOutput "objective" "Store target($i) with hostname($LHOSTNAMEDNS) associated($LASSOC) rap_assoc($LRAPASSOC) \n"
  done

}
