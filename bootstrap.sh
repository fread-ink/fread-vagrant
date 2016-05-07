#!/usr/bin/env bash

printf "\ndeb http://www.emdebian.org/debian/ unstable main\n" >> /etc/apt/sources.list

apt-get update

apt-get install -y build-essential git bison gcc-arm-linux-gnueabihf cpp-arm-linux-gnueabihf g++-arm-linux-gnueabihf binutils-arm-linux-gnueabihf pkg-config-arm-linux-gnueabihf
apt-get install -y libncurses5-dev unzip bc
apt-get install -y u-boot-tools
apt-get install -y uboot-mkimage

apt-get install -y gcc-4.6-arm-linux-gnueabihf

cd /usr/bin
ln -s arm-linux-gnueabihf-gcc-4.6 arm-linux-gnueabihf-gcc
ln -s arm-linux-gnueabihf-cpp-4.6 arm-linux-gnueabihf-cpp
ln -s arm-linux-gnueabihf-gcov-4.6 arm-linux-gnueabihf-gcov

