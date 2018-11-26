#!/bin/bash

trap ctrl_c INT

function ctrl_c() {
  #stopSniff
  #stopRAPAttack
  exit 0
}

## Main function
function main(){
  
  LSESSION=""

  declare LSTARTDAEMON=false

  while getopts ":ps:dhi:ut" opt; do
    case $opt in
      i)
        INTERFACE=$OPTARG
        LSTARTDAEMON=true
        ;;
      s)
        LSESSION=$( existsSessions "$OPTARG" )
        if [ -z $LSESSION ];then
          logOutput "done" "Create new session with name: $OPTARG \n"
	else
	  logOutput "done" "Charge session with name: $OPTARG \n"
        fi
        DATETIME=$OPTARG
        DATABASEPATH="$CURRENTDIR/data/db/diswised.$DATETIME.db"
        ;;
      p)
        printf "Previous sessions:\n\n"
        getSessions
        printf "\n\n"
        ;;
      u)
        STARTUI=true
        ;;
      d)
        LSTARTDAEMON=true
        ;;
      h)
        echo -e "$HELPMESSAGE"
        ;;
      t)
        getStats 
        ;;
      \?)
        echo -e "Invalid option: -$OPTARG \n\n" >&2
        printf "$HELPMESSAGE" 
        ;;
      :)
        echo "Option -$OPTARG requires an argument." >&2
        exit 1
        ;;
    esac
  done

  if ( "$LSTARTDAEMON" );then
    startDaemon
  fi

}
