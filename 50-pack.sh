#!/bin/bash

source cfg

if [ "$ROOTFS" == "" ]; then
    echo "No directory to install to given."
    exit 1
fi

if [ $EUID -ne 0 ]; then
    echo "This tool must be run as root."
    exit 1
fi

DT=$(date +"%Y%m%d-%H%M%S")
tar --remove-files --numeric-owner -cJvf "raspbian-$DT.tar.xz" -C "$ROOTFS" .
