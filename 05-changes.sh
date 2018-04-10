#!/bin/bash

curl -sL http://archive.raspbian.org/raspbian/dists/stretch/main/binary-armhf/Packages.xz | \
    xzcat - | grep "^Filename:" | cut -d" " -f2- | sort >packages.new

diff -u packages.list packages.new | tail -n+4 >tmp-packages.diff

echo
echo "Packages added :"
echo "----------------"
grep "^\+" tmp-packages.diff | cut -c2- | tee tmp-packages.add
echo
echo "Packages removed : "
echo "------------------"
grep "^\-" tmp-packages.diff | cut -c2- | tee tmp-packages.del
