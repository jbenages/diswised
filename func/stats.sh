#!/bin/bash

function getStats {

  declare LRESULT=""
  declare LTOTALCLIENTS=0
  declare LTOTALVULNERABLECLIENTS=0
  declare LPERCENTAGE=""
  declare LCLIENTANDROID=0

  LRESULT=$( query "select count(*) from client;" )
  if [ $? != 0 ];then
    logOutput "alert" "Fail extract percentage of clients and vulnerable clients ($LRESULT) \n"
    exit 1
  fi

  LTOTALCLIENTS=$LRESULT
  
  LRESULT=$( query "select count(*) from client where hostname != '';" )
  if [ $? != 0 ];then
    logOutput "alert" "Fail extract percentage of clients and vulnerable clients ($LRESULT) \n"
    exit 1
  fi

  LTOTALVULNERABLECLIENTS=$LRESULT
  LPERCENTAGE=$(( LTOTALVULNERABLECLIENTS*100/LTOTALCLIENTS ))

  LRESULT=$( query "select count(*) from client where hostname like 'android%%';" )
  if [ $? != 0 ];then
    logOutput "alert" "Fail extract clients with android ($LRESULT) \n"
    exit 1
  fi
  LCLIENTANDROID=$LRESULT

  echo ' ____  _              _              _ '
  echo '|  _ \(_)_____      _(_)___  ___  __| |'
  echo '| | | | / __\ \ /\ / / / __|/ _ \/ _` |'
  echo '| |_| | \__ \\ V  V /| \__ \  __/ (_| |'
  echo '|____/|_|___/ \_/\_/ |_|___/\___|\__,_|'
  echo ''
  echo -e "\e[1mGeneral Stats\e[0m"
  echo -e "\tTotal audited clients: \e[1m$LTOTALCLIENTS\e[0m"
  echo -e "\tTotal vulnerable clients: \e[1m$LTOTALVULNERABLECLIENTS\e[0m"
  echo -e "\tPercentage vulnerable clients: \e[91m$LPERCENTAGE%\e[0m"
  echo -e "\tTotal vulnerable clients with android: \e[1m$LCLIENTANDROID\e[0m\n"

  LRESULT=$( prettyQuery "select manufacturer as Manufacturer,count(*) as 'Number clients' from client where hostname != '' and manufacturer != '' group by manufacturer order by count(*) desc;" )
  if [ $? != 0 ];then
    logOutput "alert" "Fail extract vulnerable clients by manufacturer ($LRESULT) \n"
    exit 1
  fi

  echo -e "\e[1mTable of manufacturer and number of vulnerable client\e[0m\n" 
  echo -e "$LRESULT\n"

  LRESULT=$( prettyQuery "select attack.description as 'Type attack',count(client_attack.client_id) as 'Number clients' from client inner join client_attack on client.id = client_attack.client_id inner join attack on client_attack.attack_id = attack.id where client.hostname != '' group by attack.description;" )
  if [ $? != 0 ];then
    logOutput "alert" "Fail extract vulnerable clients number by type attack ($LRESULT) \n"
    exit 1
  fi

  echo -e "\e[1mTable of type of attacks and affected clients\e[0m\n" 
  echo -e "$LRESULT"

}
