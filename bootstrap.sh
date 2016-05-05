#!/usr/bin/env bash

apt-get update
apt-get install -y build-essential git bison gcc-arm-linux-gnueabihf cpp-arm-linux-gnueabihf g++-arm-linux-gnueabihf binutils-arm-linux-gnueabihf pkg-config-arm-linux-gnueabihf
apt-get install -y libncurses5-dev unzip bc
apt-get install -y u-boot-tools
apt-get install -y uboot-mkimage

