#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

#Extract all sources in the current dir
cat $SCRIPT_DIR/wget-list | while read line ; do
  file=$(echo ${line##*/})
  if [ -f $file ] ; then
      case $file in
          *.tar.bz2)   tar xvjf $file    ;;
          *.tar.gz)    tar xvzf $file    ;;
          *.tar.xz)    tar xvJf $file    ;;
          *.bz2)       bunzip2 $file     ;;
          *.rar)       rar x $file       ;;
          *.gz)        gunzip $file      ;;
          *.tar)       tar xvf $file     ;;
          *.tbz2)      tar xvjf $file    ;;
          *.tgz)       tar xvzf $file    ;;
          *.txz)       tar xvJf $file    ;;
          *.zip)       unzip $file       ;;
          *.Z)         uncompress $file  ;;
          *.7z)        7z x $file        ;;
          *.patch)     echo "skip patch file '$file'"  ;;
          *)           echo "don't know how to extract '$file'..." ;;
      esac
  else
      echo "'$file' is not a valid file!"
  fi
done
