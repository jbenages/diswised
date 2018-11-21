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

  while getopts ":ps:dhi:u" opt; do
    case $opt in
      i)
        INTERFACE=$OPTARG
        LSTARTDAEMON=true
        ;;
      s)
        LSTARTDAEMON=true
        LSESSION=$( existsSessions "$OPTARG" )
        if [ -z $LSESSION ];then
          logOutput "alert" "Not exists session: $OPTARG \n"
          exit 1
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
