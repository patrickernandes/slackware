# slack2iso

This script converts your Slackware Linux installation into an ISO image to start using a "livecd" system, which can be via pendrive or cdrom.

### Installation:  

You should only run slack2iso as **root!**  

```
chmod +x slack2iso.sh
```

### Options:

- **-help**: Display help.
- **-clean**: Clean the work folder.
- **-create**: Create the iso image.

### Example:

```
./slack2iso.sh -create
```

### Some considerations:

- All necessary folders and files, including the ISO image will be created in the "/iso" work folder.
- Your Slackware must be installed on a single partition. 
- EFI boot support.
- It has been tested on installations with Slackware64-current.
- It's still a development version, so be careful and make a backup first! ;)

----  
   
# Slackware minimal install

This is a minimal packages to install and use Slackware64-14.2 linux:  
You can create tagfiles for make fast install..  

```
aaa_base  
aaa_elflibs  
aaa_terminfo  
acl  
attr  
bash  
bin  
bzip2  
coreutils  
dcron  
devs  
dhcpcd  
dialog  
diffutils  
e2fsprogs  
elvis  
etc  
eudev  
findutils  
gawk  
glibc-solibs  
gnupg  
gptfdisk  
grep  
gzip  
iputils  
kbd  
kernel-firmware  
kernel-huge  
kernel-modules  
kmod  
less  
libgudev  
libunistring  
lilo  
ncurses  
net-tools  
network-scripts  
openssh  
openssl-solibs  
pkgtools  
procps-ng  
sed  
shadow  
slackpkg  
sysklogd  
syslinux  
sysvinit  
sysvinit-scripts  
tar  
usbutils  
util-linux  
wget  
which  
xz  
```

The installation will occupy a space of approximately 750MB.  
After installation, you can use slackpkg to update the system and install the packages as needed.  
For contact: patrickernandes@gmail.com

Thanks..  
+--------------------------+

For Slackware64-current, the future 15.0. I'm testing with the packages below: 
 
```
#a:
aaa_base
aaa_elflibs
aaa_terminfo
acl
attr
bash
bin
bzip2
coreutils
cracklib
dbus
dcron
devs
dialog
e2fsprogs
elvis
etc
eudev
findutils
gawk
glibc-solibs
gptfdisk
grep
gzip
hostname
kbd
kernel-firmware
kernel-huge
kernel-modules
kmod
less
libgudev
libpwquality
lilo
openssl-solibs
pam
pciutils
pkgtools
procps-ng
sed
shadow
sharutils
sysvinit
sysvinit-scripts
sysklogd
syslinux
tar
usbutils
util-linux
which
xz

#ap:
diffutils
slackpkg

#l:
ConsoleKit2
libpsl
libtirpc
libunistring
ncurses
pcre2

#n:
dhcpcd  
gnupg  
iproute2
iputils
libmnl
net-tools  
network-scripts  
openssh
wget
```

Note, the installation with these packages does not support efi.   
Slackware64-current download link: https://bear.alienbase.nl/mirrors/slackware/slackware64-current-iso  
