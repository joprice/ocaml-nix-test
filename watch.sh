#!/usr/bin/env bash

source_dirs="lib bin"
args=${*:-"bin/main.exe"}
cmd="dune exec ${args}"

function sigint_handler() {
  kill "$(jobs -pr)"
  exit 1
}

trap sigint_handler SIGINT SIGTERM

pid=""

function run() {
  dune build
  $cmd &
  pid=$!
}

function restart() {
  printf "\nRestarting server.exe due to filesystem change\n"
  echo "$pid"
  kill "$pid"
  run
}

run
fswatch -ot -r $source_dirs | (while read; do restart; done)
