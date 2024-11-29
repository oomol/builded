Setup a bootable alpine disk using qemu and [alpine-virt-3.20.3-aarch64.iso](https://dl-cdn.alpinelinux.org/alpine/v3.20/releases/aarch64/alpine-virt-3.20.3-aarch64.iso)

```bash
$ truncate -s 64m varstore.img
$ truncate -s 64m efi.img
dd if=/usr/share/qemu-efi-aarch64/QEMU_EFI.fd of=efi.img conv=notrunc
```

```bash
$ qemu-system-aarch64 \
-nographic -enable-kvm -cpu max -smp 4 -m 8G \
-machine virt,gic-version=host \
-netdev "user,id=net0,restrict=n,hostfwd=tcp:127.0.0.1:10024-:22" -device "e1000,netdev=net0" \
-device virtio-balloon-pci,id=balloon0 \
-drive if=pflash,format=raw,file=efi.img,readonly=on \
-drive if=pflash,format=raw,file=varstore.img  \
-drive file=alpine_disk.img,format=raw,if=virtio
```

Setup alpine bootable disk:  https://wiki.alpinelinux.org/wiki/Installation.

```bash
# DISABLE SWAP
export SWAP_SIZE=0
# BOOT PART SIZE 128MB
export BOOT_SIZE=128
setup-alpine # scripts will asks few question
```

```
 ALPINE LINUX INSTALL
----------------------

 Hostname
----------
Enter system hostname (fully qualified form, e.g. 'foo.example.org') [localhost]

 Interface
-----------
Available interfaces are: eth0.
Enter '?' for help on bridges, bonding and vlans.
Which one do you want to initialize? (or '?' or 'done') [eth0]
Ip address for eth0? (or 'dhcp', 'none', '?') [dhcp]
Do you want to do any manual network configuration? (y/n) [n] n
udhcpc: started, v1.36.1
udhcpc: broadcasting discover
udhcpc: broadcasting select for 10.0.2.15, server 10.0.2.2
udhcpc: lease of 10.0.2.15 obtained from 10.0.2.2, lease time 86400

 Root Password
---------------
Changing password for root
New password:
Retype password:
passwd: password for root changed by root

 Timezone
----------
Africa/            Egypt              Iran               Poland
America/           Eire               Israel             Portugal
Antarctica/        Etc/               Jamaica            ROC
Arctic/            Europe/            Japan              ROK
Asia/              Factory            Kwajalein          Singapore
Atlantic/          GB                 Libya              Turkey
Australia/         GB-Eire            MET                UCT
Brazil/            GMT                MST                US/
CET                GMT+0              MST7MDT            UTC
CST6CDT            GMT-0              Mexico/            Universal
Canada/            GMT0               NZ                 W-SU
Chile/             Greenwich          NZ-CHAT            WET
Cuba               HST                Navajo             Zulu
EET                Hongkong           PRC                leap-seconds.list
EST                Iceland            PST8PDT            posixrules
EST5EDT            Indian/            Pacific/

Which timezone are you in? [UTC]

 * Seeding random number generator ...
 * Saving 256 bits of creditable seed for next boot
 [ ok ]
 * Starting busybox acpid ...
 [ ok ]
 * Starting busybox crond ...
 [ ok ]

 Proxy
-------
HTTP/FTP proxy URL? (e.g. 'http://proxy:8080', or 'none') [http://192.168.1.210:2020]

 Network Time Protocol
-----------------------
Fri Nov 29 03:33:34 UTC 2024
Which NTP client to run? ('busybox', 'openntpd', 'chrony' or 'none') [chrony] busybox
 * service ntpd added to runlevel default
 * Starting busybox ntpd ...
 [ ok ]

 APK Mirror
------------
 (f)    Find and use fastest mirror
 (s)    Show mirrorlist
 (r)    Use random mirror
 (e)    Edit /etc/apk/repositories with text editor
 (c)    Community repo enable
 (skip) Skip setting up apk repositories

Enter mirror number or URL: [1]

Added mirror dl-cdn.alpinelinux.org
Updating repository indexes... done.

 User
------
Setup a user? (enter a lower-case loginname, or 'no') [no]
Which ssh server? ('openssh', 'dropbear' or 'none') [openssh]
Allow root ssh login? ('?' for help) [prohibit-password] yes
Enter ssh key or URL for root (or 'none') [none]
 * service sshd added to runlevel default
 * Caching service dependencies ...
 [ ok ]
ssh-keygen: generating new host keys: RSA ECDSA ED25519
 * Starting sshd ...
 [ ok ]

 Disk & Install
----------------
Available disks are:
  vdb   (1.1 GB 0x1af4 )

Which disk(s) would you like to use? (or '?' for help or 'none') [none]
Enter where to store configs ('floppy', 'usb' or 'none') [none]
Enter apk cache directory (or '?' or 'none') [/var/cache/apk]
fetch http://dl-cdn.alpinelinux.org/alpine/v3.20/main/aarch64/ncurses-terminfo-base-6.4_p20240420-r2.apk
fetch http://dl-cdn.alpinelinux.org/alpine/v3.20/main/aarch64/libncursesw-6.4_p20240420-r2.apk
localhost:~# setup-disk
Available disks are:
  vdb   (1.1 GB 0x1af4 )

Which disk(s) would you like to use? (or '?' for help or 'none') [vdb] vdb

The following disk is selected:
  vdb   (1.1 GB 0x1af4 )

How would you like to use it? ('sys', 'data', 'crypt', 'lvm' or '?' for help) [?] sys

WARNING: The following disk(s) will be erased:
  vdb   (1.1 GB 0x1af4 )

WARNING: Erase the above disk(s) and continue? (y/n) [n] y
Creating file systems...
mkfs.fat 4.2 (2021-01-31)
Installing system on /dev/vdb2:
Installing for arm64-efi platform.
Installation finished. No error reported.
100% ████████████████████████████████████████████==> initramfs: creating /boot/initramfs-virt for 6.6.63-0-virt
Generating grub configuration file ...
Found linux image: /boot/vmlinuz-virt
Found initrd image: /boot/initramfs-virt
Warning: os-prober will not be executed to detect other bootable partitions.
Systems on them will not be added to the GRUB boot configuration.
Check GRUB_DISABLE_OS_PROBER documentation entry.
Adding boot menu entry for UEFI Firmware Settings ...
done

Installation is complete. Please reboot.
localhost:~# halt
localhost:~#  * Stopping sshd ... [ ok ]
 * Saving random number generator seed ... * Seeding 256 bits and crediting
 * Saving 256 bits of creditable seed for next boot
 [ ok ]
 * Stopping busybox ntpd ... [ ok ]
 * Stopping busybox crond ... [ ok ]
 * Stopping busybox syslog ... [ ok ]
 * Stopping busybox acpid ... [ ok ]
 * Unmounting loop devices
 *   Remounting /.modloop read only ... [ ok ]
 * Unmounting filesystems
 *   Unmounting /media/vda ... [ ok ]
 * Setting hardware clock using the system clock [UTC] ... [ ok ]
 * Stopping busybox mdev ... [ ok ]
 [ ok ]
 * Terminating remaining processes ...[  218.842408] reboot: System halted
QEMU: Terminated
```
