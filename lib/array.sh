#!/bin/bash

## Exists key in array
# params: $1 = key | $2 = array
# return: 1 = exists | 0 = not exists
# print: Integer - position in array.
function keyArray(){
    local LKEY=$1
    local arraySearch=( $2 )
    local i
    for (( i=0; i<${#arraySearch[@]}; i++ ));do
        if [ "$LKEY" == "${arraySearch[$i]}" ];then
            printf $i
            return 0
        fi
    done
    return 1

}

## Search if value exists in array
# params: $1 = value | $2 = array
# return: 1 = exists | 0 = not exists 
function inArray(){
    local LVALUE=$1
    local arraySearch=( $2 )
    local i=0
    for (( i=0; i<=${#arraySearch[@]}; i++ ));do
	if [ "$LVALUE" == "${arraySearch[$i]}" ];then
            return 1
        fi
    done
    return 0

}
