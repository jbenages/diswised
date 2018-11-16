#!/bin/bash

## Do print of output
# params: $1 = output
function doPrint(){
    local OUTPUT=$1
    printf "$OUTPUT"
}

## Put output in log file
# params: $1 = filePath | $2 = output
function outputToFile(){
   local OUTPUT=$2
   local LOGPATH=$1
   printf "$OUTPUT" >> "$LOGPATH"
}

## Log differents outputs in different levels
# params: $1 = type | $2 = output | $3 = doLogHTML
function logOutput(){

    local TYPELOG=$1
    local OUTPUT=$2
    local DOLOGHTML=$3

    local -A symbol=( [alert]="!" [info]="i" [done]="+" [nodone]="-" [input]="?" )
    local -A color=( [alert]="31" [info]="34" [done]="32" [nodone]="33" [input]="35" )
    local -A colorHTML=( [alert]="red" [info]="blue" [done]="green" [nodone]="yellow" )
    local SHOWLOG=true

    local LDATE=`date '+%Y%m%d%H%M%S'`
    
    if [[ "$GLOBALVERBOSE" == 0 ]];then
      SHOWLOG=false
    fi

    if [[ "$GLOBALVERBOSE" == 1 ]];then
      if [ "$TYPELOG" != "alert" ];then
        SHOWLOG=false
      fi
    fi

    if ( $SHOWLOG );then

      local OUTPUTCONSOLE="$LDATE \e[${color[$TYPELOG]}m\e[1m[${symbol[$TYPELOG]}]\e[0m $OUTPUT"
      doPrint "$OUTPUTCONSOLE"

      if [ ! -z "$GLOBALLOGPATH" ];then
        local OUTPUTFILE="$LDATE [${symbol[$TYPELOG]}] $OUTPUT"	
        outputToFile "$GLOBALLOGPATH" "$OUTPUTFILE"
      fi

      if ( $DOLOGHTML );then
        local OUTPUTHTML="$LDATE <b style='color:${colorHTML[$TYPELOG]}'>[${symbol[$TYPELOG]}]</b> $OUTPUT" 
        LOGHTML="$OUTPUTHTML<br/>"
      fi
   
    fi
	
}
