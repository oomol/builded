# Qemu binary

## Build qemu
```
$ git clone https://gitlab.com/qemu-project/qemu ~/qemu_src
$ cd ~/qemu_src && CFLAGS=-march=native CXXFLAG=-march=native ../configure \
    --prefix=/home/ihexon/qemu_bins \
    --disable-xen --disable-xen-pci-passthrough; 
$ http_proxy= https_proxy= bear -- make -j4; 
$ http_proxy= https_proxy= make install
```

