Remember that fread is a work in progress. Some documentation is still missing for how to compile Xorg drivers and how to bundle the userland into an ext4 file.

This is guide for how to compile fread from scratch using a vagrant machine. This may be of use to developers but if you're looking to get started using fread you should look at the precompiled images (ToDo) instead. All of the components described here are also available individually as pre-compiled packages. See the "Pre-compiled" section near the bottom of this document.

# Table of contents

  * [Table of contents](#table-of-contents)
  * [Overview](#overview)
  * [Cross-compile environment using vagrant](#cross-compile-environment-using-vagrant)
    * [but I don't like vagrant!](#but-i-dont-like-vagrant)
  * [Compiling initrd](#compiling-initrd)
  * [Compiling the kernel](#compiling-the-kernel)
  * [Compiling kexec](#compiling-kexec)
  * [Building the userland](#building-the-userland)
  * [Installing fread](#installing-fread)
  * [Thanks to](#thanks-to)
  * [Pre-compiled](#pre-compiled)
  * [Copyright and license](#copyright-and-license)
  * [Disclaimer](#disclaimer)

# Overview

What you need to cross-compile:

* The fread initrd
* The fread kernel
* The kexec tool
* The fread userland

The initrd (initial ramdisk) is a very minimal linux userland that has just enough functionality to mount what needs mounting, chroot and boot into the real userland which is a complete, but minimal, debian-based system.

Hardware:

* Kindle 4 NT (non-touch) with serial console
* USB to 1.8v serial cable

Currently only the Kindle 4 NT has been tested.

Getting a serial console requires opening the Kindle and a bit of soldering. Do not try to use a 3.3v serial cable, it _will_ fry your kindle.

Currently the only tested method for booting into fread is to let the Kindle boot into the normal Kindle operating system and then issue commands via serial console.

It is certainly possible to boot fread without serial console but it would require modification to the kindle's original operating system and has not yet been implemented.

# Cross-compile environment using vagrant

We're using a vagrant vm to compile everything. It greatly simplifies things when all developers are building on the same system.

For some reason many of the cross compilers I've tried create a kernel that simply won't boot on my Kindle 4 NT. No error messages appear after running `kexec -e`, just... nothing. If anyone has any idea why this could be please let me know!

The cross-compilation toolchain built into Ubuntu 12.04 generates a bootable kernel so for now that's what we're using. For other parts of the system you can use whichever cross compiler you prefer.

The version of vagrant in Ubuntu 14.04 is a bit old and won't actually work for our purposes. If you have a newer Ubuntu system then you may be able to just do:

```
sudo apt-get install vagrant
```

If you get errors when running `vagrant up` then install the newest version instead:

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

__Note for Fedora users.__ The virtual machine requires the _virtualbox_ provider. Vagrant on Fedora comes with a different default provider _libvirt_, which will fail running the virtual machine. You need to append `--provider=virtualbox` to have a successful start:

```
vagrant up --provider=virtualbox
```

If this fails because the virtualbox hashicorp/pecise32 image is no longer available from hashicorp's website then you can find a backup of it [here](https://github.com/fread-ink/fread-vm-backup/releases/tag/v0.0.1).

If the package repository for Ubuntu 12.04 is unavailable then you can find a backup of the required packages [here](https://github.com/fread-ink/fread-vm-backup/tree/master/fread-vagrant).

To get a shell on the virtual machine just ensure that you're in the fread-vagrant dir and run:

```
vagrant ssh
```

The `/vagrant` dir is shared between the VM and your actual system such that any changes to `/vagrant/` happens in the `fread-vagrant/` dir.

For the rest of this guide make sure you're NEVER actually compiling anything directly in the `/vagrant` dir since that directory does not support hard links.

If you need to get back into the machine after rebooting just:

```
cd /where/you/put/fread-vagrant/
vagrant up
vagrant ssh
```

If you need to stop the VM use:

```
vagrant halt
```

## but I don't like vagrant!

Alright just look at the bootstrap.sh file in the [fread vagrant repo](https://github.com/fread-ink/fread-vagrant) and set up your own Ubuntu 12.04 system with the right dependencies installed :)

# Compiling the initramfs

The first thing to do is compile the initramfs (initial ram filesystem) since we'll be compiling a kernel with a built-in initramfs.

We'll use buildroot to compile a minimal buildroot that uses uclibc and busybox. 

First you need a buildroot that's been configured to build an iMX 5 initramfs:

```
cd ~/
git clone https://github.com/fread-ink/fread-initrd
cd fread-initrd/
./fetch.sh 
```

Compile the initramfs. This will cause buildroot to download several packages and will probably take several hours:

```
./build.sh
```

Now create the initramfs file:

```
sudo ./bundle_initramfs.sh
```

The generated initrd will be at `~/fread-initrd/initrd.cpio`.

# Compiling the kernel

First download the kernel:

```
cd ~/
git clone https://github.com/fread-ink/fread-kernel-k4
cd fread-kernel-k4/linux-2.6.31
```

Copy the config file and configure it with the initrd that you have just built.

```
cp ../config .config
sed -i '/^CONFIG_INITRAMFS_SOURCE=/s@=.*$@='"\"~/fread-initrd/initrd.cpio\""@g .config
```

Now compile the kernel:

```
./build.sh
```

This will take a while but not nearly as long as the buildroot compile. You will need to copy the compiled kernel and modules out from the virtual machine. Copy the entire `OUTPUT/` directory to `/vagrant/KERNEL`. The files will then be available in `fread-vagrant/KERNEL` after logging out from the virtual machine.

# Compiling kexec

kexec is the tool used to load a new linux kernel without rebooting. This is currently the method used for booting into fread from the original kindle operating system. This has the advantage of not having to modify anything related to the original operating system so you don't brick your device during development.

Unfortunately kexec has to be compiled with the same glibc version, kernel headers and compile-time parameters used in the original Kindle operating system since it will be executed before fread has loaded.

Compiling kexec requires a different cross-compile toolchain.

To build this toolchain:

```
git clone https://github.com/fread-ink/fread-native-cross-compile
cd fread-native-cross-compile/
./build_k4.sh
```

again this will take a long time. If you encounter odd build errors that just say something "killed" with no reason given then your VM is running out of memory. Use `vagrant halt` to shut down the VM, then edit the line `vb.customize ["modifyvm", :id, "--memory", "1024"]` to e.g. 2048 instead of 1024, restart the VM with `vagrant up` and try again.

Then build kexec using the toolchain:

```
source env_k4.sh
./build_kexec.sh
```

Log out and then log back in before continuing.

# Building the userland

See the [fread-userland](https://github.com/fread-ink/fread-userland) readme file for info on how to build a working userland. 

# Installing fread

## Copying the files

Put the following files in a directory called `fread/`:

* uImage: The fread kernel (including initramfs)
* kexec: The command line utility used to switch the running kernel
* fread.ext4: The fread userland

Connect your e-reader using USB, mount it as a storage device and copy the `fread/` directory to the root of the e-reader's filesystem.

NOTE: THE NAMING AND LOCATIONS OF THE FILES AND DIRECTORY IS IMPORTANT!

## Enabling usb networking

You can enable usb networking by adding a file named `config.txt` to the `fread/` directory with the contents:

```
USB="ethernet"
```

WARNING: There is currently a bug in usb networking that causes the system to crash if the usb cable is not plugged into a computer when usb networking initializes. Remember to plug in the usb cable before booting to fread.

If you are on a Debian/Ubuntu (and probably on many others) then everything should auto-configure (assuming you have a DHCP client enabled) and after bootup is complete you should see a new network interface appear (possibly called `usb0`) with an assigned IP address in the `192.168.1.x` range. You can then connect over ssh:

```
ssh root@192.168.1.1
```

The default root password is `fread`.

## Booting into fread using the KUAL extension

This method only works if [KUAL](https://www.mobileread.com/forums/showthread.php?t=203326) is already installed in your kindle.

Somewhere on your computer, clone the [fread KUAL extension](https://github.com/fread-ink/fread-kual-extension):

```
git clone https://github.com/fread-ink/fread-kual-extension
```

Then copy the `extensions/` directory to the root of your kindle's fat32 filesystem:

```
cp -a fread-kual-extension/extensions /path/where/e-reader/is/mounted/
```

Now on your kindle, access the KUAL app and select the "Switch to fread" menu entry to boot fread.

## Booting into fread using root console

If you have console access, log in as root on the e-reader. Ensure that the e-reader has been unmounted/ejected from your computer (if it is plugged into usb) and then boot into fread like so:

```
cd /mnt/us/fread/
./kexec --type=uImage -f ./uImage
```

If the `/mnt/us` directory is empty then cd out of it, unmount/eject your kindle from the computer to which it's attached and cd back into `/mnt/us`.

## Logging in

The default root password is `fread`.

## Loading the eink kernel modules

```
modprobe eink_fb_waveform
modprobe eink_fb_hal
modprobe mxc_epdc_fb dont_register_fb=1
modprobe eink_fb_hal_fslepdc bootstrap=0
modprobe eink_fb_shim
```

Manually triggering a display update:

```
echo "1" > /proc/eink_fb/update_display
```

# Thanks to

* [NiLuJe](https://github.com/NiLuJe) for KindleTool and for his amazing work on Kindle cross-compilation!
* The mobileread e-reader hacking community!

# Pre-compiled

The code described in this document is available as pre-compiled packages here:

* [initrd](https://github.com/fread-ink/fread-initrd/tree/master/bin)
* [kernel](https://github.com/fread-ink/fread-kernel-k4/tree/master/bin)
* [kexec](https://github.com/fread-ink/fread-native-cross-compile/tree/master/bin)
* userland (ToDo)

or you can download the entire operating system in a ready-to-use package:

* fread (ToDo)

# Copyright and license

Unless otherwise stated everything in this repository Copyright 2016 Marc Juul and licensed under the [GPLv3](https://www.gnu.org/licenses/gpl-3.0.en.html).

# Disclaimer

Kindle and Lab126 are registered trademarks of Amazon Inc. 

Kobo is a registered trademark of Kobo Inc. 

Nook is a registered trademark of Barnes & Noble Booksellers Inc. 

E Ink is a registered trademark of the E Ink Corporation. 

None of these organizations are in any way affiliated with fread nor this git project nor any of the authors of this project and neither fread nor this git project is in any way endorsed by these corporations.
