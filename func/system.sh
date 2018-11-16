#!/bin/bash

function storePID {
  local LPID=$1
  local LPATH=$2
  printf "$LPID" > "$LPATH"
}

function stopZombieProcess {
  shopt -s nullglob
  for file in "$CURRENTDIR"/data/tmp/PID/*
  do
    kill -9 $( cat "$file" ) > /dev/null 2>&1
  done

}
