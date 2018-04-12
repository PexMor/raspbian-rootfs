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

echo "Executing debootstrap..."
debootstrap --arch armhf --foreign --variant minbase --no-check-gpg \
    --include $INCLUDE $DIST $ROOTFS $MIRROR

echo "Preparing for ARM emulation..."
if [ ! -f $QSRC ]; then
    echo "Please install 'apt install qemu-user-static'"
    exit -1
fi
cp $QSRC $ROOTFS/usr/bin

echo "Executing second stage debootstrap..."
chroot $ROOTFS /debootstrap/debootstrap --second-stage

echo "Configuring ROOTFS..."
echo -e $APT_SRCS > $ROOTFS/etc/apt/sources.list

cat > $ROOTFS/etc/apt/apt.conf << EOF
APT::Install-Recommends "0";
APT::Install-Suggests "0";
EOF

cat > $ROOTFS/etc/network/interfaces << EOF
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
EOF


chroot $ROOTFS $QEMU_PATH /bin/sh -c '\
    apt-get update \
    && apt-get install -y apt-utils \
    && dpkg-reconfigure apt-utils \
    && apt-get upgrade -y \
    && apt-get install -y \
        libc6-dev \
        symlinks \
    && symlinks -cors /'

echo "ROOTFS installation into '$ROOTFS' completed."
