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

echo "Executing debootstrap..."
debootstrap --arch armhf --foreign --variant minbase --no-check-gpg \
    --include 'apt-utils,symlinks,iproute,iputils-ping' $DIST $ROOTFS $MIRROR

echo "Preparing for ARM emulation..."
if [ ! -f $QSRC ]; then
    echo "Please install 'apt install qemu-user-static'"
    exit -1
fi
cp $QSRC $ROOTFS/usr/bin


echo "Executing second stage debootstrap..."
chroot $ROOTFS /debootstrap/debootstrap --second-stage

##################################################################
##################################################################
# prevent init scripts from running during install/update
echo "--==[ make /usr/sbin/policy-rc.d"
cat > "$ROOTFS/usr/sbin/policy-rc.d" <<'EOF'
#!/bin/sh

# For most Docker users, "apt-get install" only happens during "docker build",
# where starting services doesn't work and often fails in humorous ways. This
# prevents those failures by stopping the services from attempting to start.

exit 101
EOF
chmod +x "$ROOTFS/usr/sbin/policy-rc.d"

echo "--==[ make autoclean script /etc/apt/apt.conf.d/docker-clean"
aptGetClean='"rm -f /var/cache/apt/archives/*.deb /var/cache/apt/archives/partial/*.deb /var/cache/apt/*.bin || true";'
cat > "$ROOTFS/etc/apt/apt.conf.d/docker-clean" <<-EOF
# Since for most Docker users, package installs happen in "docker build" steps,
# they essentially become individual layers due to the way Docker handles
# layering, especially using CoW filesystems.  What this means for us is that
# the caches that APT keeps end up just wasting space in those layers, making
# our layers unnecessarily large (especially since we'll normally never use
# these caches again and will instead just "docker build" again and make a brand
# new image).

# Ideally, these would just be invoking "apt-get clean", but in our testing,
# that ended up being cyclic and we got stuck on APT's lock, so we get this fun
# creation that's essentially just "apt-get clean".
DPkg::Post-Invoke { ${aptGetClean} };
APT::Update::Post-Invoke { ${aptGetClean} };

Dir::Cache::pkgcache "";
Dir::Cache::srcpkgcache "";

# Note that we do realize this isn't the ideal way to do this, and are always
# open to better suggestions (https://github.com/docker/docker/issues).
EOF

echo "--==[ no laguages /etc/apt/apt.conf.d/docker-no-languages"
cat > "$rootfsDir/etc/apt/apt.conf.d/docker-no-languages" <<-'EOF'
# In Docker, we don't often need the "Translations" files, so we're just wasting
# time and space by downloading them, and this inhibits that.  For users that do
# need them, it's a simple matter to delete this file and "apt-get update". :)

Acquire::Languages "none";
EOF

echo "--==[ gzipped indexes /etc/apt/apt.conf.d/docker-gzip-indexes"
cat > "$rootfsDir/etc/apt/apt.conf.d/docker-gzip-indexes" <<-'EOF'
# Since Docker users using "RUN apt-get update && apt-get install -y ..." in
# their Dockerfiles don't go delete the lists files afterwards, we want them to
# be as small as possible on-disk, so we explicitly request "gz" versions and
# tell Apt to keep them gzipped on-disk.

# For comparison, an "apt-get update" layer without this on a pristine
# "debian:wheezy" base image was "29.88 MB", where with this it was only
# "8.273 MB".

Acquire::GzipIndexes "true";
Acquire::CompressionTypes::Order:: "gz";
EOF

echo "--==[ prevent installation of unnecessary packages"
cat > $ROOTFS/etc/apt/apt.conf <<-EOF
APT::Install-Recommends "0";
APT::Install-Suggests "0";
EOF
##################################################################
##################################################################

echo "Configuring ROOTFS..."
echo -e $APT_SRCS > $ROOTFS/etc/apt/sources.list

# prevent upstart scripts from running during install/update
echo "--==[ divert init to null script"
chroot "$ROOTFS" dpkg-divert --local --rename --add /sbin/initctl
cp -a "$ROOTFS/usr/sbin/policy-rc.d" "$ROOTFS/sbin/initctl"
sed -i 's/^exit.*/exit 0/' "$ROOTFS/sbin/initctl"

echo "--==[ clean fs"
chroot "$ROOTFS" apt-get clean

echo "--==[ add ip config"
mkdir -p $ROOTFS/etc/network
cat > $ROOTFS/etc/network/interfaces <<-EOF
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
EOF

echo "--==[ configure DNS"
mkdir -p "$ROOTFS/etc"
cat > "$ROOTFS/etc/resolv.conf" <<-EOF
nameserver 8.8.8.8
nameserver 8.8.4.4
EOF

echo "--==[ add few more utils and redirect absolute to relative symlinks"
chroot $ROOTFS $QEMU_PATH /bin/sh -c '\
    apt update \
    && dpkg-reconfigure apt-utils \
    && apt dist-upgrade -y \
    && symlinks -cors /'

echo "--==[ remove cached files"
rm -rf "$ROOTFS/var/lib/apt/lists"/*
mkdir "$ROOTFS/var/lib/apt/lists/partial"

# echo "--==[ remove /dev and /proc fs"
# rm -rf "$ROOTFS/dev" "$ROOTFS/proc"
# mkdir -p "$ROOTFS/dev" "$ROOTFS/proc"

echo "ROOTFS installation into '$ROOTFS' completed."
du -sh $ROOTFS