 #!/bin/bash

#
# "finish-temp-system.sh" must be called first
#

set -e
set -o pipefail

sudo mkdir -pv $LFS/{dev,proc,sys,run}

sudo mknod -m 600 $LFS/dev/console c 5 1
sudo mknod -m 666 $LFS/dev/null c 1 3

sudo mount -v --bind /dev $LFS/dev

sudo mount -vt devpts devpts $LFS/dev/pts -o gid=5,mode=620
sudo mount -vt proc proc $LFS/proc
sudo mount -vt sysfs sysfs $LFS/sys
sudo mount -vt tmpfs tmpfs $LFS/run

if [ -h $LFS/dev/shm ]; then
  mkdir -pv $LFS/$(readlink $LFS/dev/shm)
fi

#Enter in chroot mode
sudo chroot "$LFS" /tools/bin/env -i \
    HOME=/root \
    TERM="$TERM" \
    PS1='\[\e[1;32m\][\u\[\e[1;35m\]@\[\e[1;32m\]\h] \[\e[0;32m\]\$ \w \[\e[1;32m\]>\[\e[0m\] ' \
    PATH=/bin:/usr/bin:/sbin:/usr/sbin:/tools/bin \
    /tools/bin/bash --login +h

# Aliases for colored commands
alias ls='ls --color=auto' && \
    alias dir='dir --color=auto' && \
    alias vdir='vdir --color=auto' && \
    alias grep='grep --color=auto' && \
    alias fgrep='fgrep --color=auto' && \
    alias egrep='egrep --color=auto' && \
    alias ll='ls -alF' && \
    alias la='ls -A' && \
    alias l='ls -CF'

#
# Create directories hierarchy
#

mkdir -pv /{bin,boot,etc/{opt,sysconfig},home,lib,mnt,opt}
mkdir -pv /{media/{floppy,cdrom},sbin,srv,var}
install -dv -m 0750 /root
install -dv -m 1777 /tmp /var/tmp
mkdir -pv /usr/{,local/}{bin,include,lib,sbin,src}
mkdir -pv /usr/{,local/}share/{color,dict,doc,info,locale,man}
mkdir -v  /usr/{,local/}share/{misc,terminfo,zoneinfo}
mkdir -v  /usr/libexec
mkdir -pv /usr/{,local/}share/man/man{1..8}

case $(uname -m) in
 x86_64) ln -sv lib /lib64     &&
         ln -sv lib /usr/lib64 &&
         ln -sv lib /usr/local/lib64 ;;
esac

mkdir -v /var/{log,mail,spool}
ln -sv /run /var/run
ln -sv /run/lock /var/lock
mkdir -pv /var/{opt,cache,lib/{color,misc,locate},local}


