#!/bin/bash

function stopServices {
  service hostapd stop > /dev/null 2>&1
  service dnsmasq stop > /dev/null 2>&1
  airmon-ng check kill > /dev/null 2>&1
}

function startRAPAttack {
 
  local LCLIENTMAC=$1
  local LROUTERESSID=$2
  local LROUTERMAC=$3
  local LROUTERCHANNEL=$4
  local LHOSTAPDCONF=""
  local LDNSMASQCONF=""

  changeMAC "$INTERFACE" "$LROUTERMAC" 

  if [ "$LROUTERCHANNEL" == 0 ];then
    LROUTERCHANNEL=$(( ( RANDOM % 11 )  + 1 )) 
  fi

  LHOSTAPDCONF=$( generateConfigHostapd "$INTERFACE" "$LROUTERESSID" "$LROUTERCHANNEL" )
  HOSTAPDPID=$( startHostapd "$LHOSTAPDCONF" "$CURRENTDIR/data/tmp/log/hostapd.log" )
  storePID "$HOSTAPDPID" "$CURRENTDIR/data/tmp/PID/hostapd"
  logOutput "info" "Start hostapd service \n" 

  echo "" > "$DNSMASQLEASEFILE" 
  LDNSMASQCONF=$( generateConfigDnsmasq "$INTERFACE" "$IPRANGE" "$IPMASK" "$IPAP" )
  DNSMASQPID=$( startDnsmasq "$LDNSMASQCONF" "$CURRENTDIR/data/tmp/log/dnsmasq.log" "$DNSMASQLEASEFILE" )
  storePID "$DNSMASQPID" "$CURRENTDIR/data/tmp/PID/dnsmasq"
  logOutput "info" "Start dnsmasq service \n" 

  asignIPInterface "$INTERFACE" "$IPAP"

}

function findTargets {
  local LCLIENTMAC=$1
  local LCLIENTSHOSTAPD=()
  local LCLIENTSDNSMASQ=()
  local LARRAYTOSTRING=""
  local i=""
  
  LARRAYTOSTRING="${LISTTARGETSMACHOST[@]}"

  LCLIENTSHOSTAPD=( $( extractClientsHostapdLog ) ) 
  for i in "${LCLIENTSHOSTAPD[@]}";do
    inArray "$i" "$LARRAYTOSTRING"
    if [ $? = 0 ];then
      if [ "$GLOBALVERBOSE" = 2 ];then
        if [ "$i" == "$LCLIENTMAC" ];then
          logOutput "info" "Find expected client ($LCLIENTMAC) in hostapd \n" 
        else
          logOutput "info" "Find unexpected client ($i) in hostapd \n"
	fi
      fi
      LISTTARGETSMACHOST+=( $i )
      TIMERAPATTACKINCREASE=5
    fi
  done

  LARRAYTOSTRING="${LISTTARGETSMAC[@]}"

  LCLIENTSDNSMASQ=( $( extractClientsMACDnsmasq ) )
  for i in "${LCLIENTSDNSMASQ[@]}";do
    inArray "$i" "$LARRAYTOSTRING"
    if [ $? = 0 ];then
      if [ "$i" = "$LCLIENTMAC" ];then
        logOutput "info" "Find expected client ($LCLIENTMAC) in dnsmasq \n" 
      else
        logOutput "info" "Find unexpected client ($i) in dnsmasq \n" 
      fi
      LISTTARGETSMAC+=( $i )
    fi
  done

}

function extractClientsHostapdLog {
  grep "AP-STA-CONNECTED" "$CURRENTDIR/data/tmp/log/hostapd.log" 2> /dev/null | cut -d" " -f3 | tr '[:lower:]' '[:upper:]' 2> /dev/null
}

function extractClientsMACDnsmasq {
  cut -d" " -f2 "$DNSMASQLEASEFILE" | tr '[:lower:]' '[:upper:]'
}

function asignIPInterface {
  local LINTERFACE=$1
  local LIP=$2
  ifconfig "$LINTERFACE" "$LIP"
}

function stopRAPAttack {
  LISTTARGETSMAC=()
  LISTTARGETSMACHOST=()
  kill -9 "$HOSTAPDPID" > /dev/null 2>&1
  kill -9 "$DNSMASQPID" > /dev/null 2>&1
}

function generateConfigHostapd {
  export CINTERFACE=$1 CESSID=$2 CCHANNEL=$3
  envsubst < "$CURRENTDIR/conf/hostapd/diswised.conf"
}

function generateConfigDnsmasq {
  export CINTERFACE=$1 CIPRANGE=$2 CIPMASK=$3 CIP=$4 
  envsubst < "$CURRENTDIR/conf/dnsmasq/diswised.conf"
}

function changeMAC {
  local LINTERFACE=$1
  local LMAC=$2
  ifconfig "$LINTERFACE" down
  if [ -z $LMAC ];then
    macchanger -r "$LINTERFACE" > /dev/null 2>&1
  else
    macchanger -m "$LMAC" "$LINTERFACE" > /dev/null 2>&1
  fi
  ifconfig "$LINTERFACE" up
}

function markAttackTargets {
  
  local ATTACKSUCCESS="true"
  local MARKTARGET=0
  local ATTACKTYPE=0
  local i=""

  for i in "${LISTTARGETSMAC[@]}";do
    if [ "$CLIENTTOAUDIT" != "$i" ];then
      ATTACKTYPE=$ATTACKOPENWIFI
      LRESULT=$( createClientAttackRelation  "$i" "$ATTACKTYPE" "true" )
      if [ $? != 0 ];then
        logOutput "alert" "SGDB error ($LRESULT)\n"
      fi
    else
      if [ -z "$ROUTERMAC" ];then
        ATTACKTYPE=$ATTACKRAP
      else
	echo "ROUTERMAC: $ROUTERMAC"
        ATTACKTYPE=$ATTACKRAPASSOC
      fi 
      LRESULT=$( createClientAttackRelation  "$CLIENTTOAUDIT" "$ATTACKTYPE" "true" )
      if [ $? != 0 ];then
        logOutput "alert" "SGDB error ($LRESULT)\n"
      fi
      MARKTARGET=1
      if [ ! -z "$FIXEDTARGET" ];then
        FIXEDTARGETCATCHED=true
      fi
    fi
  done

  if [ $MARKTARGET == 0 ];then
    if [ -z "$ROUTERMAC" ];then
      ATTACKTYPE=$ATTACKRAP
    else
      ATTACKTYPE=$ATTACKRAPASSOC
    fi 
    LRESULT=$( createClientAttackRelation  "$CLIENTTOAUDIT" "$ATTACKTYPE" "false" )
    if [ $? != 0 ];then
      logOutput "alert" "SGDB error ($LRESULT)\n"
    fi
  fi

}

