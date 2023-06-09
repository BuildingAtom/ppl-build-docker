#!/usr/bin/env bash

## Initial variables and checks
NAME="ppl-build"
USE_UNIQUE=false
ADD_UNAME=true
IMAGE="buildingatom/ppl-build-docker:latest"
if $USE_UNIQUE;then
    NAME+="-$(cat /proc/sys/kernel/random/uuid)"
fi
if $ADD_UNAME;then
    NAME="$(id -un)-$NAME"
fi

# If cleaning, stop container and delete image
if [ ${1:-""} == "clean" ]; then
    echo "Cleaning Container"
    [ "$(docker ps -aq -f name=$NAME)" ] && docker rm -f $NAME
    # Delete all related images
    [ "$(docker images -q $IMAGE)" ] && docker images --filter label=stage=buildingatom-ppl-builder --format {{.ID}} | xargs docker image rm
    exit 0
fi

## First build the docs container
PRE_BUILD_ID=
POST_BUILD_ID=
if [ ! "$(docker images -q $IMAGE)" ] || [ ${1:-""} == "rebuild" ]; then
    PRE_BUILD_ID=$(docker inspect --format {{.Id}} $IMAGE 2>/dev/null)
    echo "Building Image"
    docker build -t $IMAGE -f Dockerfile .
    POST_BUILD_ID=$(docker inspect --format {{.Id}} $IMAGE)
fi
# If image changed, delete the container
if [ "$PRE_BUILD_ID" != "$POST_BUILD_ID" ] && [ "$(docker ps -aq -f name=$NAME)" ]; then 
    echo "Deleting Container for Rebuilt Image"
    docker rm -f $NAME
fi
# If restarting, just stop the container
if [ ${1:-""} == "restart" ] && [ "$(docker ps -aq -f name=$NAME)" ]; then
    echo "Stopping Container for Restart"
    docker stop $NAME
fi

## Configuration for script vars
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
MOUNT_DIR=$SCRIPT_DIR
STARTING_DIR=$SCRIPT_DIR

## Setup uid requirements and workdir for temporaries
if [ -z "$HOME" ];then
    HOME=/tmp
fi
if [ -z "$ID" ];then
    ID=$(id -u)
fi
WORKDIR="$HOME/.docker"
mkdir -p "$WORKDIR"
getent passwd $(id -u) > "$WORKDIR/.$ID.passwd"
getent group $(id --groups) > "$WORKDIR/.$ID.group"
#DOCKER_HOME="$WORKDIR/$NAME"
#mkdir -p "$DOCKER_HOME"

## Build out the Docker options
DOCKER_OPTIONS=""
DOCKER_OPTIONS+="-itd "
#DOCKER_OPTIONS+="--rm "

## USER ACCOUNT STUFF
DOCKER_OPTIONS+="--user $(id -u):$(id -g) "
DOCKER_OPTIONS+="$(id --groups | sed 's/\(\b\w\)/--group-add \1/g') "
DOCKER_OPTIONS+="-v $WORKDIR/.$ID.passwd:/var/lib/extrausers/passwd:ro "
DOCKER_OPTIONS+="-v $WORKDIR/.$ID.group:/var/lib/extrausers/group:ro "

## PROJECT
DOCKER_OPTIONS+="-v $MOUNT_DIR:$MOUNT_DIR "
#DOCKER_OPTIONS+="-v $DOCKER_HOME:$HOME "
DOCKER_OPTIONS+="--mount type=tmpfs,destination=$HOME,tmpfs-mode=1777 "
DOCKER_OPTIONS+="--name $NAME "
DOCKER_OPTIONS+="--workdir=$MOUNT_DIR "
#DOCKER_OPTIONS+="--entrypoint make "
DOCKER_OPTIONS+="--net=host "

## Launch
# Determine if we are launching anything
COMMAND=/bin/bash
if [ ${1:-""} == "--" ]; then
    COMMAND="/bin/bash -l -c ${@:2}"
elif [ ${2:-""} == "--" ]; then
    COMMAND="/bin/bash -l -c ${@:3}"
fi

# Determin if we need to restart the container
if [ ! "$(docker ps -q -f name=$NAME)" ]; then # If container isn't running
    # If it exists, but needs to be started
    if [ "$(docker ps -aq -f name=$NAME)" ]; then
        echo "Resuming Container"
        docker start $NAME
    else
        echo "Launching Container"
        docker run $DOCKER_OPTIONS $IMAGE
    fi
fi

echo "Running in Container"
docker exec -it $NAME $COMMAND

