#!/bin/bash

## Check if exists interface
# 1: name interface
function checkIfExistsInterface {
  local LINTERFACE=$1
  local LRESULT=0
  local LCHECK=$(iw dev | grep $LINTERFACE)
  if [ ! -z "$LCHECK" ];then
    LRESULT=1
  fi
  return $LRESULT
}


