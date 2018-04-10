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

chroot $ROOTFS $QEMU_PATH /bin/sh
