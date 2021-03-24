#!/bin/bash

IMAGE=drpsychick/arkcluster
TAG=focal
(cd ..; docker build --build-arg STEAMCMD_VERSION=$TAG --tag $IMAGE:$TAG .)
#docker pull $IMAGE:$TAG

function testDirectoriesExist() {
  nok=0
  if [ ! -d "$1/backup" ]; then nok=$((nok+1)); echo "/backup is missing!"; fi
  if [ ! -d "$1/config" ]; then nok=$((nok+1)); echo "/config is missing!"; fi
  if [ ! -d "$1/log" ]; then nok=$((nok+1)); echo "/log is missing!"; fi

  if [ $nok -gt 0 ]; then
    echo "FAIL: $nok errors"
  fi
}

function testNewSimpleServer() {
  echo "====> TEST $FUNCNAME"
  mkdir -p ark-theisland

  serverdir=ark-theisland
  docker run --rm -it --name $serverdir \
    --env-file $serverdir.env \
    -v $PWD/$serverdir:/ark \
    -e ARKCLUSTER=false \
    -e ARKSERVER_SHARED= \
    -e LIST_MOUNTS=true \
    $IMAGE:$TAG
  [ $? -ne 0 ] && echo "FAIL: docker exec failed"

  testDirectoriesExist $serverdir

  rm -rf ark-theisland
}

function testNewSharedServerFail() {
  echo "====> TEST $FUNCNAME"
  mkdir -p ark-theisland arkserver arkclusters

  serverdir=ark-theisland
  docker run --rm -it --name $serverdir \
    --env-file $serverdir.env \
    -v $PWD/$serverdir:/ark \
    -v $PWD/arkclusters:/arkclusters \
    -v $PWD/arkserver:/arkserver \
    -e LIST_MOUNTS=true \
    $IMAGE:$TAG
  [ $? -eq 0 ] && echo "FAIL: docker failure expected!"

  testDirectoriesExist $serverdir

  rm -rf ark-theisland arkserver arkclusters
}
function testNewSharedServer() {
  echo "====> TEST $FUNCNAME"
  mkdir -p ark-theisland/saved arkserver arkclusters

  serverdir=ark-theisland
  docker run --rm -it --name $serverdir \
    --env-file $serverdir.env \
    -v $PWD/$serverdir:/ark \
    -v $PWD/$serverdir/saved:/arkserver/ShooterGame/Saved \
    -v $PWD/arkclusters:/arkserver/ShooterGame/Saved/clusters \
    -v $PWD/arkserver:/arkserver \
    -e LIST_MOUNTS=true \
    $IMAGE:$TAG
  [ $? -ne 0 ] && echo "FAIL: docker failed!"

  testDirectoriesExist $serverdir

  rm -rf ark-theisland arkserver arkclusters
}

function testMigratedServer() {
  echo "====> TEST $FUNCNAME"
  mkdir -p ark-theisland arkserver arkclusters
  mkdir -p ark-theisland/server/ShooterGame/Binaries
  mkdir -p ark-theisland/server/ShooterGame/Saved/SavedArks
  mkdir -p ark-theisland/saved/SavedArks
  touch ark-theisland/server/ShooterGame/Saved/SavedArks/savegame-dead.dat
  touch ark-theisland/saved/SavedArks/savegame-good.dat

  serverdir=ark-theisland
  docker run --rm -it --name $serverdir \
    --env-file $serverdir.env \
    -v $PWD/$serverdir:/ark \
    -v $PWD/$serverdir/saved:/arkserver/ShooterGame/Saved \
    -v $PWD/arkclusters:/arkserver/ShooterGame/Saved/clusters \
    -v $PWD/arkserver:/arkserver \
    -e LIST_MOUNTS=true \
    $IMAGE:$TAG
  [ $? -ne 0 ] && echo "FAIL: docker exec failed"

  testDirectoriesExist $serverdir

  rm -rf ark-theisland arkserver arkclusters
}

###
function testSharedMount() {
  echo "====> TEST $FUNCNAME"
  mkdir -p ark-theisland arkserver arkclusters
  mkdir -p ark-theisland/server/ShooterGame/Binaries
  mkdir -p ark-theisland/saved/SavedArks
  touch ark-theisland/saved/SavedArks/savegame.dat

  serverdir=ark-theisland
  docker run --rm -it --name $serverdir \
    --env-file $serverdir.env \
    -v $PWD/$serverdir:/ark \
    -v $PWD/$serverdir/saved:/arkserver/ShooterGame/Saved \
    -v $PWD/arkclusters:/arkserver/ShooterGame/Saved/clusters \
    -v $PWD/arkserver:/arkserver \
    -e LIST_MOUNTS=true \
    $IMAGE:$TAG
  [ $? -ne 0 ] && echo "FAIL: docker exec failed"

  testDirectoriesExist $serverdir

  rm -rf ark-theisland arkserver arkclusters
}

testNewSimpleServer
testNewSharedServerFail
testNewSharedServer
testMigratedServer
testSharedMount

