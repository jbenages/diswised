#!/bin/bash

function putCaptureDataToDB {

  local LFRAGMENTCLIENT=""
  local LFRAGMENTCLIENT1=""
  local LFRAGMENTCLIENT2=""
  local LLINENUMBER=0
  local LRESULT=""

  LFRAGMENTCLIENT=$( sed -n '/Station MAC, First time seen/,$p' "$CURRENTDIR/data/airodump/diswised-01.csv" | sed -e '$ d' | sed '1d' )
  LFRAGMENTCLIENT1=$( printf "$LFRAGMENTCLIENT" | cut -d, -f7-100 | sed -E 's/,/;/g' )
  LFRAGMENTCLIENT2=$( printf "$LFRAGMENTCLIENT" | cut -d, -f1-6 | sed -E 's/,\ /,/g' | sed -E 's/\)\ /)/g' )
  paste <( echo "$LFRAGMENTCLIENT2" ) <( echo "$LFRAGMENTCLIENT1" ) --delimiter=',' > "$CURRENTDIR/data/tmp/csv/$DATETIME.client.diswised.csv"

  LLINENUMBER=$(grep -n 'Station MAC' $CURRENTDIR/data/airodump/diswised-01.csv | cut -d':' -f1)
  LLINENUMBER=$((LLINENUMBER-2))
  sed -n "3,"$LLINENUMBER"p" "$CURRENTDIR/data/airodump/diswised-01.csv" | sed -E 's/,\ /,/g' | sed -E 's/\ ,/,/g' > "$CURRENTDIR/data/tmp/csv/$DATETIME.router.diswised.csv"

  if [ ! -f "$DATABASEPATH" ];then
    createDB "$CURRENTDIR/conf/db_schema/create.sql"
    if [ $? != 0 ];then
      logOutput "alert" "Fail to create database \n" 
      exit 1
    fi    
  fi

  LRESULT=$( query "delete from rawclientsignal;" )
  if [ $? != 0 ];then
    logOutput "alert" "Fail on delete rawclientsignal table data ($LRESULT) \n" 
    exit 1
  fi
  LRESULT=$( importCSVToTable "$CURRENTDIR/data/tmp/csv/$DATETIME.client.diswised.csv" "rawclientsignal" )
  if [ $? != 0 ];then
    logOutput "alert" "Fail import csv to table rawclientsignal ($LRESULT) \n" 
    exit 1
  fi
  LRESULT=$( query "delete from rawroutersignal;" )
  if [ $? != 0 ];then
    logOutput "alert" "Fail delete data on table rawroutersignal ($LRESULT) \n" 
    exit 1
  fi
  LRESULT=$( importCSVToTable "$CURRENTDIR/data/tmp/csv/$DATETIME.router.diswised.csv" "rawroutersignal" )
  if [ $? != 0 ];then
    logOutput "alert" "Fail import csv data on table rawroutersignal ($LRESULT) \n" 
    exit 1
  fi

  rm $CURRENTDIR/data/tmp/csv/*.diswised.csv

}

function findClientToAudit {

  local LCLIENTID=0
  local LROUTERID=0
  local LCLIENTLASTATTACK=""
  local LCLIENTPROBEDESSID=""
  local LCLIENTTOAUDIT=""
  local LROUTERCHANNEL=0
  local LROUTERMAC=""
  local LROUTERESSID=""
  local LARRAYTOSTRING=""
  local LASSOC=true
  local LRESULT=""

  CLIENTTOAUDIT=""

  LARRAYTOSTRING="${EXCLUDEDCLIENTSMAC[@]}"
  LCLIENTTOAUDIT=$( query "select station_mac from rawclientsignal where bssid = '(not associated)' and probed_essids != '' and power != -1 and station_mac not in (select client.station_mac from client_attack inner join client on client.id = client_attack.client_id where attack_id != 2 ) and probed_essids != '$EXCLUDEDROUTERESSID' order by power desc,last_time_seen asc limit 1;" )
  if [ ! -z "$LCLIENTTOAUDIT" ];then
    existsLastAttackClient "$LCLIENTTOAUDIT"
    if [ $? = 1 ];then
      LCLIENTTOAUDIT=""
    else
      LASSOC=false
      logOutput "info" "Find client not associated ($LCLIENTTOAUDIT) \n" 
    fi
  fi
  
  if [ -z "$LCLIENTTOAUDIT" ];then
    LCLIENTTOAUDIT=$( query "select rawclientsignal.station_mac from rawclientsignal inner join rawroutersignal on rawclientsignal.bssid = rawroutersignal.bssid where rawclientsignal.bssid != '(not associated)' and rawclientsignal.power != -1 and rawclientsignal.station_mac not in (select client.station_mac from client_attack inner join client on client.id = client_attack.client_id where attack_id != 1 ) and rawclientsignal.bssid != '$EXCLUDEDROUTERMAC' and rawroutersignal.essid != '' order by rawclientsignal.power desc,rawclientsignal.last_time_seen asc limit 1;" ) 
    existsLastAttackClient "$LCLIENTTOAUDIT"
    if [ $? = 1 ];then
      LCLIENTTOAUDIT=""
    fi
  fi
  
  if [ ! -z "$LCLIENTTOAUDIT" ];then
    LRESULT=$( createClientRow "$LCLIENTTOAUDIT" )
    if [ $? != 0 ];then
      logOutput "alert" "Error create client SGDB ($LRESULT) \n" 
      exit 1
    fi

    if [ "$LASSOC" = false ];then
      LCLIENTPROBEDESSID=$( query "select probed_essids from rawclientsignal where station_mac = '$LCLIENTTOAUDIT';" )
      LCLIENTPROBEDESSID=$( echo $LCLIENTPROBEDESSID | cut -d';' -f1 )
      LRESULT=$( createRouterRow "$LCLIENTPROBEDESSID" "" "" )
      if [ $? != 0 ];then
        logOutput "alert" "Fail database query ($LRESULT) when extract probed essids\n"
	exit 1
      fi
      LRESULT=$( createRelationClientRouterDB "$LCLIENTTOAUDIT" "$LCLIENTPROBEDESSID" "" "false" "false" )
      if [ $? != 0 ];then
        logOutput "alert" "2 Fail database query ($LRESULT) \n"
	exit 1
      fi
      LROUTERESSID=$LCLIENTPROBEDESSID
      ROUTERESSID=$LCLIENTPROBEDESSID
      LROUTERMAC=""
      ROUTERCHANNEL=""
    else
      LROUTERMAC=$( query "select bssid from rawclientsignal where station_mac = '$LCLIENTTOAUDIT' and bssid != '(not associated)';" )
      LROUTERESSID=$( query "select essid from rawroutersignal where bssid = '$LROUTERMAC';" )
      LROUTERCHANNEL=$( query "select channel from rawroutersignal where bssid = '$LROUTERMAC';" )
      if [ ! -z $LROUTERMAC ];then
        LRESULT=$( createRouterRow "$LROUTERESSID" "$LROUTERMAC" "$LROUTERCHANNEL" )
        if [ $? != 0 ];then
          logOutput "alert" "3 Fail database query ($LRESULT) \n"
	  exit 1
        fi
	LRESULT=$( createRelationClientRouterDB "$LCLIENTTOAUDIT" "$ROUTERESSID" "$LROUTERMAC" "true" "false" )
        if [ $? != 0 ];then
          logOutput "alert" "Error SGDB when create realtion with client and router ($LRESULT) \n"
	  exit 1
        fi
      fi
    fi
    CLIENTTOAUDIT=$LCLIENTTOAUDIT
    ROUTERMAC=$LROUTERMAC
    ROUTERCHANNEL=$LROUTERCHANNEL
    ROUTERESSID=$LROUTERESSID
    logOutput "done" "Find target client_mac ($CLIENTTOAUDIT) router_mac($LROUTERMAC) router_essid ($LROUTERESSID) \n"
  fi

}

function findFixedTarget {

  LROUTERMAC=""
  LROUTERCHANNEL=""
  LROUTERESSID=""
  LASSOC="false"
  
  LRESULT=$( query "select bssid from rawclientsignal where station_mac = '$FIXEDTARGET'" )
  if [ $? != 0 ];then
    logOutput "alert" "Fail database query ($LRESULT) \n"
    exit 1
  fi

  if [ ! -z "$LRESULT" ];then
    LROUTERMAC=$LRESULT
    LROUTERESSID=$( query "select essid from rawroutersignal where bssid = '$LROUTERMAC';" )
    if [ $? != 0 ];then
      logOutput "alert" "Fail database query ($LRESULT) \n"
      exit 1
    fi
    LROUTERCHANNEL=$( query "select channel from rawroutersignal where bssid = '$LROUTERMAC';" )
    if [ $? != 0 ];then
      logOutput "alert" "Fail database query ($LRESULT) \n"
      exit 1
    fi
    LASSOC="true"
  else
    LROUTERESSID=$( query "select probed_essids from rawclientsignal where station_mac = '$FIXEDTARGET';" )
    LROUTERESSID=$( echo "$LROUTERESSID" | cut -d';' -f1 )
    LASSOC="false"
  fi  

  ROUTERMAC=$LROUTERMAC
  ROUTERCHANNEL=$LROUTERCHANNEL
  ROUTERESSID=$LROUTERESSID

  if [ ! -z "$ROUTERMAC" ] || [ ! -z "$ROUTERESSID" ];then
    CLIENTTOAUDIT=$FIXEDTARGET

    LRESULT=$( createClientRow "$CLIENTTOAUDIT" )
    if [ $? != 0 ];then
      logOutput "alert" "Error SGDB when create user row ($LRESULT) \n" 
      exit 1
    fi
    LRESULT=$( createRouterRow "$ROUTERESSID" "$ROUTERMAC" "$ROUTERCHANNEL" )
    if [ $? != 0 ];then
      logOutput "alert" "Error SGDB when create router row ($LRESULT)\n"
      exit 1
    fi
    LRESULT=$( createRelationClientRouterDB "$CLIENTTOAUDIT" "$ROUTERESSID" "$LROUTERMAC" "$LASSOC" "false" )
    if [ $? != 0 ];then
      logOutput "alert" "Error SGDB when create realtion client router ($LRESULT) \n"
      exit 1
    fi
    logOutput "done" "Find target client_mac ($CLIENTTOAUDIT) router_mac($ROUTERMAC) router_essid ($ROUTERESSID) \n"
  fi

}

function existsLastAttackClient {
  
  local LCLIENTMAC=$1
  local LRETURN=0
  local LCLIENTID=0
  local LCLIENTLASTATTACK=0
 
  LCLIENTID=$( query "select id from client where station_mac = '$LCLIENTMAC';" )
  LCLIENTLASTATTACK=$( query "select id from client_attack where client_id = '$LCLIENTID';" )
  if [ ! -z $LCLIENTLASTATTACK ];then
    LRETURN=1
  fi
  return $LRETURN

}

## Create router row in table router if not exists
# 1: (String) Router essid | 2: (String) Router MAC | 3: Router channel
# print Result if exist error
# return 0: NO errors | != 0: SGDB error.
function createRouterRow {
  
  local LROUTERESSID=$1
  local LROUTERMAC=$2
  local LROUTERDATARAW=""
  local LROUTERCHANNEL=$3
  local LSQLROUTER="select essid from router where bssid = '$LROUTERMAC';"
  local LSQLINSERT=""
  local LRETURN=0
  local LRESULT=""
  local LMANUFACTURER=""

  if [ -z "$LROUTERCHANNEL" ];then
    LROUTERCHANNEL=0
  fi

  if [ ! -z "$LROUTERESSID" ];then
    LSQLROUTER="select essid from router where essid = '$LROUTERESSID';"
  fi

  LRESULT=$( query "$LSQLROUTER" )
  LRETURN=$?
  if [ $LRETURN == 0 ];then

    if [ -z "$LRESULT" ];then
      LRESULT=$( query "select essid,channel from rawroutersignal where bssid = '$LROUTERMAC';" )
      LRETURN=$?
      if [ $LRETURN == 0 ];then
        if [ ! -z "$LRESULT" ];then
          LROUTERESSID=$( echo "$LRESULT" | cut -d"|" -f1 )
          LROUTERCHANNEL=$( echo "$LRESULT" | cut -d"|" -f2 )
        fi
        if [ ! -z "$LROUTERMAC"  ];then
          LMANUFACTURER=$( getManufacturerFromMAC "$LROUTERMAC" )
        fi
        echo "insert into router (essid,bssid,date_in,manufacturer,channel) values ('$LROUTERESSID','$LROUTERMAC','`date '+%Y-%m-%d %H:%M:%S'`','$LMANUFACTURER','$LROUTERCHANNEL');"
        LRESULT=$( query "insert into router (essid,bssid,date_in,manufacturer,channel) values ('$LROUTERESSID','$LROUTERMAC','`date '+%Y-%m-%d %H:%M:%S'`','$LMANUFACTURER','$LROUTERCHANNEL');" )
        LRETURN=$?
      fi
    fi

  fi
 
  ROUTERESSID=""
  ROUTERESSID="$LROUTERESSID"

  printf "$LRESULT"
  return $LRETURN

}

## Update data of client
# 1: (String) Client mac | 2: (String) client OS | 3: (String) Client hostname scan | 4: (String) Client ports info | 5: (String) Client hostname.
# print Error SGDB
# return 0: No errors | != 0: SGDB error
function updateClientRow {

  local LSTATIONMAC=$1
  local LSCANOS=$2
  local LSCANHOSTNAME=$3
  local LSCANPORT=$4
  local LHOSTNAME=$5
  query "update client set scan_os = '$LSCANOS', scan_port = '$LSCANPORT', scan_hostname = '$LSCANHOSTNAME', hostname = '$LHOSTNAME' where station_mac = '$LSTATIONMAC';"
  return $?
   
}

## Check if exists client
# 1 : Mac of client
# print id of client or null if not exist
# return 0: no errors | != 0 : SGDB error
function existsClient {
  local LCLIENTMAC=$1
  query "select id from client where station_mac = '$LCLIENTMAC';" 
  return $?
}

## Create new client in clien table if not exist.
# 1: Mac of client
# print id of new client or old id if exist client
# return 0: no errors | != 0: SGDB error.
function createClientRow {
 
  local LCLIENTMAC=$1
  local LRESULTINSERT=""
  local LRETURN=0
  local LMANUFACTURER=""
  
  LCLIENTID=$( query "select id from client where station_mac = '$LCLIENTMAC';" )
  LRETURN=$?

  if [ $LRETURN = 0 ];then
   
    if [ ! -z $LCLIENTID ] ;then
      printf "$LCLIENTID"
    else
      LMANUFACTURER=$( getManufacturerFromMAC "$LCLIENTMAC" )
      LRESULTINSERT=$( query "insert into client (station_mac,date_in,date_scan,manufacturer,hostname,scan_os,scan_port,scan_hostname) values ('$LCLIENTMAC','`date '+%Y-%m-%d %H:%M:%S'`','','$LMANUFACTURER','','','','')" )
      LRETURN=$?
      if [ $? = 0 ];then
        existsClient "$LCLIENTMAC"
        LRETURN=$? 
      fi
    fi
  else
    print $LCLIENTID
  fi

  return $LRETURN
}

## Creation relation between client and router if not exists
# 1: (String) Client MAC | 2: (String) Router essid | 3: (String) Router MAC | 4: (Boolean) if exist association between client router | 5: (boolean) if exist association between client and router in rap attack.
# print id of row client router table.
# return 0: No errors | 1: SGDB error
function createRelationClientRouterDB {

  local LCLIENTMAC=$1
  local LROUTERESSID=$2
  local LROUTERMAC=$3
  local LASSOCIED=$4
  local LRAPASSOC=$5
  local LCLIENTID=0
  local LROUTERID=0
  local LCLIENTROUTERID=0
  local LRETURN=0
  local LPRINT=""
  local LSQLROUTER="select id from router where essid='$LROUTERESSID';"

  if [ -z "$LROUTERESSID" ];then
    LSQLROUTER="select id from router where bssid='$LROUTERMAC';"
  fi

  LCLIENTID=$( query "select id from client where station_mac = '$LCLIENTMAC';" )
  LRETURN=$?
  if [ $LRETURN != 0 ];then
    LPRINT=$LCLIENTID
  fi
  LROUTERID=$( query "$LSQLROUTER" )
  LRETURN=$?
  if [ $LRETURN != 0 ];then
    LPRINT=$LROUTERID
  fi

  if [ $LRETURN = 0 ];then  
    if [ -z $LCLIENTID ] || [ -z $LROUTERID ];then
      LRETURN=1
      LPRINT=""
    else
      LCLIENTROUTERID=$( query "select id from client_router where router_id = '$LROUTERID' and client_id = '$LCLIENTID';" )
      if [ -z "$LCLIENTROUTERID" ];then
        LPRINT=$( query "insert into client_router (associate,rap_assoc,client_id,router_id) values ('$LASSOCIED','$LRAPASSOC','$LCLIENTID','$LROUTERID');" )
	LRETURN=$?
        if [ $LRETURN == 0 ];then
          LPRINT=$( query "select id from client_router where router_id = '$LROUTERID' and client_id = '$LCLIENTID';" )
        fi
      fi
    fi
  fi

  printf "$LPRINT"

  return $LRETURN
 
}

## Update client router assoc
# 1: (String) Client mac | 2: (String) Router MAC | 3: (String) ESSID Router | 4: (Boolean) Associate with router | 5: (Boolean) RAP Associate
# print Error SGDB
# return 0: No errors | != 0: SGDB error
function updateRelationClientRouter {

  local LCLIENTMAC=$1
  local LROUTERMAC=$2
  local LROUTERESSID=$3
  local LASSOC=$4
  local LRAPASSOC=$5
  local LCLIENTID=0
  local LROUTERID=0
  local LRESULT=""
  local LRETURN=0
  local LSQLROUTER="select id from router where essid='$LROUTERESSID';"
  local LSQLUPDATE=""
  
  if [ -z "$LROUTERESSID" ];then
    LSQLROUTER="select id from router where bssid='$LROUTERMAC';"
  fi

  LRESULT=$( query "select id from client where station_mac = '$LCLIENTMAC'" )
  LRETURN=$?
  if [ $LRETURN == 0 ];then
    LCLIENTID=$LRESULT
    LRESULT=$( query "$LSQLROUTER" )
    LRETURN=$?
    if [ $LRETURN == 0 ];then
      LROUTERID=$LRESULT
      if [ -z $LASSOC ];then
        LSQLUPDATE="update client_router set associate = '$LASSOC' where client_id = '$LCLIENTID' and router_id = '$LROUTERID';" 
      fi

      if [ -z $LRAPASSOC ];then 
        LSQLUPDATE="update client_router set rap_assoc = '$LRAPASSOC' where client_id = '$LCLIENTID' and router_id = '$LROUTERID';" 
      fi

      LRESULT=$( query "$LSQLUPDATE" )
      LRETURN=$?
    fi
  fi

  printf "$LRESULT"
  return $LRETURN
   
}

function createClientAttackRelation {
  
  local LCLIENTMAC=$1
  local LATTACKID=$2
  local LSUCCESS=$3
  local LCLIENTID=""
  local LRESULT=""
  local LRETURN=0
  
  LRESULT=$( query "select id from client where station_mac = '$LCLIENTMAC'" )
  LRETURN=$?
  if [ $LRETURN == 0 ];then
    LCLIENTID=$LRESULT
    if [ ! -z $LCLIENTID ]; then
      LRESULT=$( query "select id from client_attack where client_id = '$LCLIENTID' and attack_id = '$LATTACKID';" )
      LRETURN=$?
      if [ $LRETURN == 0 ];then
        if [ -z $RESULT ];then
          LRESULT=$( query "insert into client_attack (success,date_in,client_id,attack_id) values ('$LSUCCESS','`date '+%Y-%m-%d %H:%M:%S'`','$LCLIENTID','$LATTACKID');" )
          LRETURN=$?
        fi
      fi
    fi 
  fi

  printf "$LRESULT"
  return $LRETURN

}
