#!/bin/bash

source cfg

if [ "$ROOTFS" == "" ]; then
    echo "No directory to install to given."
    exit 1
fi

if [ $EUID -ne 0 ]; then
    echo "This tool must be run as root."
    exec sudo /bin/bash "$0" "$@"
    # exit 1
fi

NOWVER=$(date +"%Y%m%d-%H%M")
CFG="$HOME/.github-release.json"
VERFN="$HOME/.github-release.ver"

if [ -f "$VERFN" ]; then
    VER=$(cat "$VERFN")
else
    VER=$NOWVER
    echo $VER >"$VERFN"
fi

tar --remove-files --numeric-owner -cJvf "raspbian-$VER.tar.xz" -C "$ROOTFS" .
