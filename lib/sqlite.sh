#!/bin/bash

## Create database to store data execution
# 1: Path of db file | 2: Path to sql scheme
function createDB {
  local LDBSCHEMAFILE=$1
  sqlite3 "$DATABASEPATH" < "$LDBSCHEMAFILE"
}

## Import from CSV to table
# 1: Path to csv file | 2: Table name to import | 3: Path to db file
function importCSVToTable {
  local LPATHTOCSV=$1
  local LTABLE=$2
  printf ".mode csv\n.import $LPATHTOCSV $LTABLE \n" | sqlite3 $DATABASEPATH
  return $?
}

## Query to sqlite
# 1: sql string
# print: Result of query
function query {
  local LSQL=$1
  printf "$LSQL" | sqlite3 "$DATABASEPATH" 
  return $?
}

## Query to sqlite with spaces and headers
# 1: sql string
# print: Result of query
function prettyQuery {
  local LSQL=$1
  printf "$LSQL" | sqlite3 -column -header "$DATABASEPATH" 
  return $?
}

