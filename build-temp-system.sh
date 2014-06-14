 #!/bin/bash

#
# "init-workspace.sh" must be run first
#

set -e
set -o pipefail

J_ARG="-j8"

if [[ "$LFS" != "/mnt/lfs" ]]; then exit 1; fi

cd $LFS/sources

#remove all "old" build dirs
rm -rf *-build

##
## binutils cross
##

mkdir -v binutils-build
cd binutils-build
../binutils-2.24/configure  \
    --prefix=/tools            \
    --with-sysroot=$LFS        \
    --with-lib-path=/tools/lib \
    --target=$LFS_TGT          \
    --disable-nls              \
    --disable-werror
make $J_ARG
case $(uname -m) in
  x86_64) mkdir -v /tools/lib && ln -sv lib /tools/lib64 ;;
esac
make $J_ARG install

##
## gcc cross
##

cd ../gcc-4.8.3
#Extract other sources
tar -Jxf ../mpfr-3.1.2.tar.xz
mv -v mpfr-3.1.2 mpfr
tar -Jxf ../gmp-5.1.3.tar.xz
mv -v gmp-5.1.3 gmp
tar -zxf ../mpc-1.0.2.tar.gz
mv -v mpc-1.0.2 mpc

#Modify dynamic link
for file in \
 $(find gcc/config -name linux64.h -o -name linux.h -o -name sysv4.h)
do
  cp -uv $file{,.orig}
  sed -e 's@/lib\(64\)\?\(32\)\?/ld@/tools&@g' \
      -e 's@/usr@/tools@g' $file.orig > $file
  echo '
#undef STANDARD_STARTFILE_PREFIX_1
#undef STANDARD_STARTFILE_PREFIX_2
#define STANDARD_STARTFILE_PREFIX_1 "/tools/lib/"
#define STANDARD_STARTFILE_PREFIX_2 ""' >> $file
  touch $file.orig
done

sed -i '/k prot/agcc_cv_libc_provides_ssp=yes' gcc/configure

mkdir -v ../gcc-build
cd ../gcc-build

../gcc-4.8.3/configure                               \
    --target=$LFS_TGT                                \
    --prefix=/tools                                  \
    --with-sysroot=$LFS                              \
    --with-newlib                                    \
    --without-headers                                \
    --with-local-prefix=/tools                       \
    --with-native-system-header-dir=/tools/include   \
    --disable-nls                                    \
    --disable-shared                                 \
    --disable-multilib                               \
    --disable-decimal-float                          \
    --disable-threads                                \
    --disable-libatomic                              \
    --disable-libgomp                                \
    --disable-libitm                                 \
    --disable-libmudflap                             \
    --disable-libquadmath                            \
    --disable-libsanitizer                           \
    --disable-libssp                                 \
    --disable-libstdc++-v3                           \
    --enable-languages=c,c++                         \
    --with-mpfr-include=$(pwd)/../gcc-4.8.3/mpfr/src \
    --with-mpfr-lib=$(pwd)/mpfr/src/.libs

make $J_ARG
make $J_ARG install
ln -sv libgcc.a `$LFS_TGT-gcc -print-libgcc-file-name | sed 's/libgcc/&_eh/'`

##
## linux headers
##

cd ../linux-3.13.11
make $J_ARG mrproper
make $J_ARG headers_check
make $J_ARG INSTALL_HDR_PATH=dest headers_install
cp -rv dest/include/* /tools/include

##
## glibc
##

cd ../glibc-2.19
#Fix rpc headers
if [ ! -r /usr/include/rpc/types.h ]; then
  su -c 'mkdir -pv /usr/include/rpc'
  su -c 'cp -v sunrpc/rpc/*.h /usr/include/rpc'
fi

mkdir -v ../glibc-build
cd ../glibc-build

../glibc-2.19/configure                             \
      --prefix=/tools                               \
      --host=$LFS_TGT                               \
      --build=$(../glibc-2.19/scripts/config.guess) \
      --disable-profile                             \
      --enable-kernel=2.6.32                        \
      --with-headers=/tools/include                 \
      libc_cv_forced_unwind=yes                     \
      libc_cv_ctors_header=yes                      \
      libc_cv_c_cleanup=yes

make $J_ARG
make $J_ARG install

echo 'main(){}' > dummy.c
$LFS_TGT-gcc dummy.c
readelf -l a.out | grep ': /tools'
if [[ "$(readelf -l a.out | grep ': /tools')" != *"Requesting program interpreter"* ]]; then exit 2; fi

rm -vf dummy.c a.out

##
## libstdc++
##

mkdir -pv ../gcc-build
cd ../gcc-build

../gcc-4.8.3/libstdc++-v3/configure \
    --host=$LFS_TGT                      \
    --prefix=/tools                      \
    --disable-multilib                   \
    --disable-shared                     \
    --disable-nls                        \
    --disable-libstdcxx-threads          \
    --disable-libstdcxx-pch              \
    --with-gxx-include-dir=/tools/$LFS_TGT/include/c++/4.8.3

make $J_ARG
make $J_ARG install

##
## binutils (final)
##

rm -rf ../binutils-build
mkdir -v ../binutils-build
cd ../binutils-build

CC=$LFS_TGT-gcc                \
AR=$LFS_TGT-ar                 \
RANLIB=$LFS_TGT-ranlib         \
../binutils-2.24/configure   \
    --prefix=/tools            \
    --disable-nls              \
    --with-lib-path=/tools/lib \
    --with-sysroot

make $J_ARG
make $J_ARG install
make $J_ARG -C ld clean
make $J_ARG -C ld LIB_PATH=/usr/lib:/lib
cp -v ld/ld-new /tools/bin

##
## gcc (final)
##

cd ..
rm -rf gcc-4.8.3 gcc-build
tar xvjf gcc-4.8.3.tar.bz2
cd gcc-4.8.3

#Fix headers
cat gcc/limitx.h gcc/glimits.h gcc/limity.h > \
  `dirname $($LFS_TGT-gcc -print-libgcc-file-name)`/include-fixed/limits.h

case `uname -m` in
  i?86) sed -i 's/^T_CFLAGS =$/& -fomit-frame-pointer/' gcc/Makefile.in ;;
esac

#Fix dynamic link
for file in \
 $(find gcc/config -name linux64.h -o -name linux.h -o -name sysv4.h)
do
  cp -uv $file{,.orig}
  sed -e 's@/lib\(64\)\?\(32\)\?/ld@/tools&@g' \
  -e 's@/usr@/tools@g' $file.orig > $file
  echo '
#undef STANDARD_STARTFILE_PREFIX_1
#undef STANDARD_STARTFILE_PREFIX_2
#define STANDARD_STARTFILE_PREFIX_1 "/tools/lib/"
#define STANDARD_STARTFILE_PREFIX_2 ""' >> $file
  touch $file.orig
done

tar -Jxf ../mpfr-3.1.2.tar.xz
mv -v mpfr-3.1.2 mpfr
tar -Jxf ../gmp-5.1.3.tar.xz
mv -v gmp-5.1.3 gmp
tar -zxf ../mpc-1.0.2.tar.gz
mv -v mpc-1.0.2 mpc

mkdir -v ../gcc-build
cd ../gcc-build

CC=$LFS_TGT-gcc                                      \
CXX=$LFS_TGT-g++                                     \
AR=$LFS_TGT-ar                                       \
RANLIB=$LFS_TGT-ranlib                               \
../gcc-4.8.3/configure                               \
    --prefix=/tools                                  \
    --with-local-prefix=/tools                       \
    --with-native-system-header-dir=/tools/include   \
    --enable-clocale=gnu                             \
    --enable-shared                                  \
    --enable-threads=posix                           \
    --enable-__cxa_atexit                            \
    --enable-languages=c,c++                         \
    --disable-libstdcxx-pch                          \
    --disable-multilib                               \
    --disable-bootstrap                              \
    --disable-libgomp                                \
    --with-mpfr-include=$(pwd)/../gcc-4.8.3/mpfr/src \
    --with-mpfr-lib=$(pwd)/mpfr/src/.libs

make $J_ARG
make $J_ARG install
ln -sv gcc /tools/bin/cc

echo 'main(){}' > dummy.c
cc dummy.c
readelf -l a.out | grep ': /tools'
if [[ "$(readelf -l a.out | grep ': /tools')" != *"Requesting program interpreter"* ]]; then exit 3; fi
rm -v dummy.c a.out

##
## tcl
##

cd ../tcl8.6.1
cd unix
./configure --prefix=/tools
make $J_ARG
#Don't make test, this may fail
#TZ=UTC make test
make $J_ARG install
chmod -v u+w /tools/lib/libtcl8.6.so
make $J_ARG install-private-headers
ln -sv tclsh8.6 /tools/bin/tclsh

##
## expect
##

cd ../../expect5.45
#Force use of /bin/stty
cp -v configure{,.orig}
sed 's:/usr/local/bin:/bin:' configure.orig > configure
./configure --prefix=/tools       \
            --with-tcl=/tools/lib \
            --with-tclinclude=/tools/include
make $J_ARG
make $J_ARG SCRIPTS="" install

##
## dejagnu
##

cd ../dejagnu-1.5.1
./configure --prefix=/tools
make $J_ARG install
make check

##
## check
##

cd ../check-0.9.13
./configure --prefix=/tools
make $J_ARG
make $J_ARG install

##
## ncurses
##

cd ../ncurses-5.9
./configure --prefix=/tools \
            --with-shared   \
            --without-debug \
            --without-ada   \
            --enable-widec  \
            --enable-overwrite
make $J_ARG
make $J_ARG install

##
## bash
##

cd ../bash-4.3
./configure --prefix=/tools --without-bash-malloc
make $J_ARG
make tests
make $J_ARG install
ln -sv bash /tools/bin/sh

##
## bzip2
##

cd ../bzip2-1.0.6
make $J_ARG
make $J_ARG PREFIX=/tools install

##
## coreutils
##

cd ../coreutils-8.22
./configure --prefix=/tools --enable-install-program=hostname
make $J_ARG
make RUN_EXPENSIVE_TESTS=yes check
make $J_ARG install

##
## diffutils
##

cd ../diffutils-3.3
./configure --prefix=/tools
make $J_ARG
make check
make $J_ARG install

##
## file
##

cd ../file-5.19
./configure --prefix=/tools
make $J_ARG
make check
make $J_ARG install

##
## findutils
##

cd ../findutils-4.4.2
./configure --prefix=/tools
make $J_ARG
make check
make $J_ARG install

##
## gawk
##

cd ../gawk-4.1.1
./configure --prefix=/tools
make $J_ARG
#make check
make $J_ARG install

##
## gettext
##

cd ../gettext-0.18.3.2
cd gettext-tools
EMACS="no" ./configure --prefix=/tools --disable-shared
make $J_ARG -C gnulib-lib
make $J_ARG -C src msgfmt
make $J_ARG -C src msgmerge
make $J_ARG -C src xgettext

cp -v src/{msgfmt,msgmerge,xgettext} /tools/bin

##
## grep
##

cd ../../grep-2.20
./configure --prefix=/tools
make $J_ARG
make check
make $J_ARG install

##
## gzip
##

cd ../gzip-1.6
./configure --prefix=/tools
make $J_ARG
make check
make $J_ARG install

##
## m4
##

cd ../m4-1.4.17
sed -i -e '/gets is a/d' lib/stdio.in.h
./configure --prefix=/tools
make $J_ARG
make check
make $J_ARG install

##
## make
##

cd ../make-4.0
./configure --prefix=/tools --without-guile
make $J_ARG
make check
make $J_ARG install

##
## patch
##

cd ../patch-2.7.1
./configure --prefix=/tools
make $J_ARG
make check
make $J_ARG install

##
## perl
##

cd ../perl-5.18.2
patch -Np1 -i ../perl-5.18.2-libc-1.patch
sh Configure -des -Dprefix=/tools
make $J_ARG

cp -v perl cpan/podlators/pod2man /tools/bin
mkdir -pv /tools/lib/perl5/5.18.2
cp -Rv lib/* /tools/lib/perl5/5.18.2

##
## sed
##

cd ../sed-4.2.2
./configure --prefix=/tools
make $J_ARG
make check
make $J_ARG install

##
## tar
##

cd ../tar-1.27.1
./configure --prefix=/tools
make $J_ARG
make check
make $J_ARG install

##
## texinfo
##

cd ../texinfo-5.2
./configure --prefix=/tools
make $J_ARG
make check
make $J_ARG install

##
## util-linux
##

cd ../util-linux-2.24.2
./configure --prefix=/tools                \
            --disable-makeinstall-chown    \
            --without-systemdsystemunitdir \
            PKG_CONFIG=""

make $J_ARG
make $J_ARG install

##
## xz
##

cd ../xz-5.0.5
./configure --prefix=/tools
make $J_ARG
make check
make $J_ARG install

echo -e "\n\n Finish !\n\n"


