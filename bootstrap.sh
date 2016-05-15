#!/usr/bin/env bash

apt-get update
apt-get install emdebian-archive-keyring

printf "\ndeb http://www.emdebian.org/debian/ unstable main\n" >> /etc/apt/sources.list

apt-get update

apt-get install -y build-essential git bison autoconf gperf flex texinfo help2man gawk libtool libncurses5-dev unzip bc
apt-get install -y pkg-config-arm-linux-gnueabihf
apt-get install -y u-boot-tools uboot-mkimage

# from emdebian
apt-get install -y gcc-4.6-arm-linux-gnueabihf 

cd /usr/bin
ln -s arm-linux-gnueabihf-gcc-4.6 arm-linux-gnueabihf-gcc
ln -s arm-linux-gnueabihf-cpp-4.6 arm-linux-gnueabihf-cpp
ln -s arm-linux-gnueabihf-gcov-4.6 arm-linux-gnueabihf-gcov

