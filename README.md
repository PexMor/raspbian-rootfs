# Raspbian rootfs

An automated script to build Raspbian root filesystem. To be used for docker or cross-platform builds.

Inspired by a dozen other repositories intended to build rootfs usable for cross platform builds.
Mainly for x86 to armhf (Raspberry Pi) builds.

## Docker repos:

* [sdt/docker-raspberry-pi-cross-compiler](https://github.com/sdt/docker-raspberry-pi-cross-compiler) - docker with debian 8 (jessie) and raspbian 8 (jessie) rootfs with updates for both but old
* [dockcross/dockcross](https://github.com/dockcross/dockcross) - just a cross compiler with libc for armhf
* [skarbat/sdl2-raspberrypi](https://github.com/skarbat/sdl2-raspberrypi) - sdl2 only cross compilation
* [schachr/docker-raspbian-stretch](https://github.com/schachr/docker-raspbian-stretch) - rootfs builder but have to run on armhf platform (in this case orange pi)
