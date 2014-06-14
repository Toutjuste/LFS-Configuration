#!/bin/bash

#Use after build-temp-system.sh

#Remove unused symbols
strip --strip-debug /tools/lib/*
/usr/bin/strip --strip-unneeded /tools/{,s}bin/*

#Remove docs
rm -rf /tools/{,share}/{info,man,doc}

#Give right to root
sudo chown -R root:root $LFS/tools

#Create .bzip2 archive
sudo tar cvjf $LFS/tools.tar.bz2 $LFS/tools/


