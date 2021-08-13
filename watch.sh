#!/usr/bin/env bash

set -x

source_dirs="lib bin"
args=${*:-"bin/main.exe"}
cmd="dune exec ${args}"
pidfile="pidfile"

sig_handler() {
  pid=$(<pidfile)
  kill "$pid"
  exit 0
}

run() {
  $cmd &
  echo $! > $pidfile
}

restart() {
  printf "\nRestarting server.exe due to filesystem change\n"
  child=$(<$pidfile)
  kill "$child"
  run
}

trap sig_handler SIGINT SIGTERM SIGEXIT

run
#fswatch -0 -x -or $source_dirs)
fswatch -or $source_dirs | (while read; do restart; done)
