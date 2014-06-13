#!/bin/bash

#Commands to add user "lfs".
#Execute this script only one time on you first build.

sudo groupadd lfs
sudo useradd -s /bin/bash -g lfs -m -k /dev/null lfs
sudo passwd lfs

#To connect use:
#su - lfs
