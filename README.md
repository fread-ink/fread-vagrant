THIS IS A WORK IN PROGRESS. NOTHING WORKS YET!

This is guide for how to compile fread from scratch using a vagrant machine. This may be of use to developers but if you're looking to get started using fread you should look at the precompiled images (ToDo) instead. All of the components described here are also available individually as pre-compiled packages. See the "Pre-compiled" section near the bottom of this document.

# Overview

What you need to compile:

* The fread initrd
* The fread kernel
* The fread userland

The initrd (initial ramdisk) is a very minimal linux userland that has just enough functionality to mount what needs mounting, chroot and boot into the real userland which is a complete, but minimal, debian-based system.

Hardware:

* Kindle 4 NT (non-touch) with serial console
* USB to 1.8v serial cable

Currently only the Kindle 4 NT has been tested.

Getting a serial console requires opening the Kindle and a bit of soldering. Do not try to use a 3.3v serial cable, it _will_ fry your kindle.

Currently the only tested method for booting into fread is to let the Kindle boot into the normal Kindle operating system and then issue commands via serial console.

It is certainly possible to boot fread without serial console but this has not yet been implemented.

# Compiling the kernel

For some reason many of the cross compilers I've tried create a kernel that simply won't boot on my Kindle 4 NT. No error messages so hard to debug. If anyone has any idea why this could be, please let me know!

The cross-compilation toolchain built into Ubuntu 12.04 generates a bootable kernel so for now that's what we're using. For other parts of the system you can use whichever cross compiler you prefer.

## Cross-compile environment using vagrant

The version of vagrant in Ubuntu 14.04 is a bit old and won't actually work for our purposes. If you have a newer Ubuntu then you may be able to just do:

```
sudo apt-get install vagrant
```

If it doesn't work then install the newest version:

```
sudo bash -c 'echo deb http://vagrant-deb.linestarve.com/ any main > /etc/apt/sources.list.d/wolfgang42-vagrant.list'
sudo apt-key adv --keyserver pgp.mit.edu --recv-key AD319E0F7CFFA38B4D9F6E55CE3F3DE92099F7A4
sudo apt-get update
sudo apt-get install vagrant
```

The following will install a Ubuntu 12.04 32-bit virtual machine with everything needed to compile the fread kernel:

```
git clone https://github.com/fread-ink/fread-vagrant
cd fread-vagrant/
vagrant up
```

To get a shell on the virtual machine just ensure that you're in the fread-vagrant dir and run:

```
vagrant ssh
```

and make sure you're NOT working in the vagrant dir (/vagrant) since that directory does not support hard links.

If you need to get back into the machine after rebooting just:

```
cd /where/you/put/fread-vagrant/
vagrant up
vagrant ssh
```

## but I don't like vagrant!

Alright just look at the bootstrap.sh file in the [fread vagrant repo](https://github.com/fread-ink/fread-kernel-vagrant) and set up your own Ubuntu 12.04 system with the right depdencies installed :)


## Compiling initrd

The first thing to do is compile the initrd (initial ramdisk) since we'll be compiling a kernel with a built-in initrd.

We'll use buildroot to compile a minimal buildroot that uses uclibc and busybox. 

First you need a buildroot that's been configured to build an iMX 5 initrd:

```
cd ~/
git clone https://github.com/fread-ink/fread-initrd
cd fread-initrd/
./fetch.sh 
```

Now compile the initrd. This will cause buildroot to download several packages and will take several hours:

```
cd buildroot-2016.02/
make
```

# Compiling the kernel

First download the kernel:

```
cd ~/
git clone https://github.com/fread-ink/fread-kernel-k4
cd fread-kernel-k4/
```

Now compile it:

```
./build.sh
```

This will take a while but not nearly as long as the buildroot compile.

# Compiling kexec

kexec is the tool used to load a new linux kernel without rebooting. This is currently the method used for booting into fread from the original kindle operating system. This has the advantage of not having to modify anything related to the original operating system so you don't brick your device during development.

Unfortunately kexec has to be compiled with the same glibc version, kernel headers and compile-time parameters used in the original Kindle operating system since it will be executed before fread has loaded.

Fortunately [NiLuJe](https://github.com/NiLuJe) has documented how to do this. See their latest "Cross-compilation ToolChain & patches" in [this thread](http://www.mobileread.com/forums/showthread.php?t=225030).

This requires a special cross-compile environment.

To set it up first get the required packages:

```
git clone https://github.com/fread-ink/fread-kexec-k4
cd fread-kexec-k4/
./fetch.sh
```

# Building the userland

The userland is based on Debian. While source code is available for all packages via the debian repository it is outside the scope of this document to explain how to compile a minimal debian-based distribution from scratch. The original fread distro was created using debootstrap and then removing unnecessary packages and files.

See the (fread-userland)[https://github.com/fread-ink/fread-userland] readme file for info on how to compile the few packages that are not included in debian. This should also give you enough info to compile the entire fread userland from scratch by compiling every single debian source package from scratch for arm. You should then be able to assemble the built packages into a working fread distro by using e.g. multistrap. Maybe some day we'll have an automated build system for the userland.

# Thanks to

* [NiLuJe](https://github.com/NiLuJe) for KindleTool and for his amazing work on Kindle cross-compilation!
* The mobileread e-reader hacking community!

# Pre-compiled

The code described in this document is available as pre-compiled packages here:

* initrd (ToDo)
* kernel (ToDo)
* kexec (ToDo)
* userland (ToDo)

or you can download the entire operating system in a ready-to-use package:

* fread (ToDo)

# Copyright and license

Unless otherwise stated everything in this repository Copyright 2016 Marc Juul and licensed under the [GPLv3](https://www.gnu.org/licenses/gpl-3.0.en.html)

# Disclaimer

Kindle and Lab126 are registered trademarks of Amazon Inc. 

Kobo is a registered trademark of Kobo Inc. Nook is a registered trademark of Barnes & Noble Booksellers Inc. 

E Ink is a registered trademark of the E Ink Corporation. 

None of these organizations are in any way affiliated with fread nor this git project and neither fread nor this git project is in any way endorsed by these corporations.

