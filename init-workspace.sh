#!/bin/bash

export LFS="/mnt/lfs"

sudo mkdir -pv $LFS
#Replace sdc4 with the corresponding partition
sudo mount -v -t ext4 /dev/sdc4 $LFS

#Where sources are stored (tars + extracted dirs)
sudo mkdir -pv $LFS/sources
sudo chmod -v a+wt $LFS/sources

#Output dir for temp system required for the final one
sudo mkdir -pv $LFS/tools
sudo ln -sv $LFS/tools /

#Give right to user "lfs"
sudo chown -v lfs $LFS/tools
sudo chown -v lfs $LFS/sources

#
#Create some dot files
#

if [ -d "/tmp/lfs-dotfiles" ]; then
  rm -v -r /tmp/lfs-dotfiles
fi

mkdir -pv /tmp/lfs-dotfiles

cat > /tmp/lfs-dotfiles/.bash_profile << "EOF"
exec env -i HOME=$HOME TERM=$TERM /bin/bash
EOF

#Create colors file

cat > /tmp/lfs-dotfiles/.colors << "EOF"
RCol='\e[0m'    # Text Reset
# Regular           Bold                Underline           High Intensity      BoldHigh Intens     Background          High Intensity Backgrounds
Bla='\e[0;30m';     BBla='\e[1;30m';    UBla='\e[4;30m';    IBla='\e[0;90m';    BIBla='\e[1;90m';   On_Bla='\e[40m';    On_IBla='\e[0;100m';
Red='\e[0;31m';     BRed='\e[1;31m';    URed='\e[4;31m';    IRed='\e[0;91m';    BIRed='\e[1;91m';   On_Red='\e[41m';    On_IRed='\e[0;101m';
Gre='\e[0;32m';     BGre='\e[1;32m';    UGre='\e[4;32m';    IGre='\e[0;92m';    BIGre='\e[1;92m';   On_Gre='\e[42m';    On_IGre='\e[0;102m';
Yel='\e[0;33m';     BYel='\e[1;33m';    UYel='\e[4;33m';    IYel='\e[0;93m';    BIYel='\e[1;93m';   On_Yel='\e[43m';    On_IYel='\e[0;103m';
Blu='\e[0;34m';     BBlu='\e[1;34m';    UBlu='\e[4;34m';    IBlu='\e[0;94m';    BIBlu='\e[1;94m';   On_Blu='\e[44m';    On_IBlu='\e[0;104m';
Pur='\e[0;35m';     BPur='\e[1;35m';    UPur='\e[4;35m';    IPur='\e[0;95m';    BIPur='\e[1;95m';   On_Pur='\e[45m';    On_IPur='\e[0;105m';
Cya='\e[0;36m';     BCya='\e[1;36m';    UCya='\e[4;36m';    ICya='\e[0;96m';    BICya='\e[1;96m';   On_Cya='\e[46m';    On_ICya='\e[0;106m';
Whi='\e[0;37m';     BWhi='\e[1;37m';    UWhi='\e[4;37m';    IWhi='\e[0;97m';    BIWhi='\e[1;97m';   On_Whi='\e[47m';    On_IWhi='\e[0;107m';
E_RCol="\[$RCol\]"  # Text Reset
# Regular             Bold                   Underline              High Intensity         BoldHigh Intens         Background                 High Intensity Backgrounds
E_Bla="\[$Bla\]";     E_BBla="\[$BBla\]";    E_UBla="\[$BBla\]";    E_IBla="\[$IBla\]";    E_BIBla="\[$BIBla\]";   E_On_Bla="\[$On_Bla\]";    E_On_IBla="\[$On_IBla\]";
E_Red="\[$Red\]";     E_BRed="\[$BRed\]";    E_URed="\[$URed\]";    E_IRed="\[$IRed\]";    E_BIRed="\[$BIRed\]";   E_On_Red="\[$On_Red\]";    E_On_IRed="\[$On_IRed\]";
E_Gre="\[$Gre\]";     E_BGre="\[$BGre\]";    E_UGre="\[$UGre\]";    E_IGre="\[$IGre\]";    E_BIGre="\[$BIGre\]";   E_On_Gre="\[$On_Gre\]";    E_On_IGre="\[$On_IGre\]";
E_Yel="\[$Yel\]";     E_BYel="\[$BYel\]";    E_UYel="\[$UYel\]";    E_IYel="\[$IYel\]";    E_BIYel="\[$BIYel\]";   E_On_Yel="\[$On_Yel\]";    E_On_IYel="\[$On_IYel\]";
E_Blu="\[$Blu\]";     E_BBlu="\[$BBlu\]";    E_UBlu="\[$UBlu\]";    E_IBlu="\[$IBlu\]";    E_BIBlu="\[$BIBlu\]";   E_On_Blu="\[$On_Blu\]";    E_On_IBlu="\[$On_IBlu\]";
E_Pur="\[$Pur\]";     E_BPur="\[$BPur\]";    E_UPur="\[$UPur\]";    E_IPur="\[$IPur\]";    E_BIPur="\[$BIPur\]";   E_On_Pur="\[$On_Pur\]";    E_On_IPur="\[$On_IPur\]";
E_Cya="\[$Cya\]";     E_BCya="\[$BCya\]";    E_UCya="\[$UCya\]";    E_ICya="\[$ICya\]";    E_BICya="\[$BICya\]";   E_On_Cya="\[$On_Cya\]";    E_On_ICya="\[$On_ICya\]";
E_Whi="\[$Whi\]";     E_BWhi="\[$BWhi\]";    E_UWhi="\[$UWhi\]";    E_IWhi="\[$IWhi\]";    E_BIWhi="\[$BIWhi\]";   E_On_Whi="\[$On_Whi\]";    E_On_IWhi="\[$On_IWhi\]";
EOF

#Create bashrc file
cat > /tmp/lfs-dotfiles/.bashrc << "EOF"
set +h
umask 022
LFS=/mnt/lfs
LC_ALL=POSIX
LFS_TGT=$(uname -m)-lfs-linux-gnu
PATH=/tools/bin:/bin:/usr/bin
export LFS LC_ALL LFS_TGT PATH

if [ -f ~/.colors ]; then
    . ~/.colors
fi
PS1="$E_BBlu[\u$E_BCya@$E_BBlu\h] $E_Cya\$ \w $E_BBlu>$E_RCol "

#Colors
alias ls='ls --color=auto'
alias dir='dir --color=auto'
alias vdir='vdir --color=auto'

alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
EOF

#Move files to lfs dir
sudo rm -v /home/lfs/.bash_profile /home/lfs/.bashrc /home/lfs/.colors

sudo cp /tmp/lfs-dotfiles/.* /home/lfs/

sudo chown -v lfs /home/lfs/.bash_profile
sudo chown -v lfs /home/lfs/.bashrc
sudo chown -v lfs /home/lfs/.colors

#Connect to user "lfs"
su - lfs

