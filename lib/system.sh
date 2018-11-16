#!/bin/bash

trap ctrl_c INT

function ctrl_c() {
        echo "** Trapped CTRL-C"
}

## Check if exists the programs in system
# params: $1 = programs names
# return: 1 = Error | 0 = Done
# print: String - Name program not exist
function checkExistsPrograms(){

    local programs=( $1 )
    local j
    
    for (( j=0; j<${#programs[@]}; j++ ))
    do
        if [ ! $(type -P ${programs[$j]} ) ]; then
            echo "${programs[$j]}"
            return 1
        fi
    done

    return 0
}
