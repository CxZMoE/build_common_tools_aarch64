#!/bin/bash

## This script can be used to build wget for aarch64 linux architecture
## Author: CxZMoE
## This file is maintained in Github

# DEL ALL FILE/DIRS EXCEPT THIS ONE
find ./ -mindepth 1 ! -name 'build.sh' -delete

CC=${CC:-"aarch64-linux-musl-gcc"}
LD=${LD:-"aarch64-linux-musl-ld"}
HOST=${HOST:-"aarch64-linux-musl"}
# JOBS
JOBS=${JOBS:-24}
echo -e "BUILD WGET WITH:\nCC=$CC\nLD=$LD\nHOST=$HOST\nJOBS=$JOBS\n"

# DOWNLOAD URLs
PCRE2_DOWNLOAD=https://github.com/PCRE2Project/pcre2/releases/download/pcre2-10.42/pcre2-10.42.tar.gz
ZLIB_DOWNLOAD=https://www.zlib.net/fossils/zlib-1.2.13.tar.gz
WGET_DOWNLOAD=https://ftp.gnu.org/gnu/wget/wget-1.21.tar.gz
OPENSSL_DOWNLOAD=https://www.openssl.org/source/openssl-3.0.8.tar.gz

# Start downloading items
mkdir -p download
downloads=($PCRE2_DOWNLOAD $ZLIB_DOWNLOAD $WGET_DOWNLOAD $OPENSSL_DOWNLOAD)
for url in ${downloads[@]};
do
    file_name=$(basename $url)

    dest="$PWD/download/$file_name"
    echo "==> Downloading  $url ..."
    wget $url -O $dest

    # Extract
    echo "==> Extracting $dest"
    tar -zxf $dest -C $PWD
    # echo "==> Changing dirname"
    # mv $PWD/$file_name $PWD/${file_name%%.*}
done

echo "==> Preparing files complete"

# Configure and compiling
BUILD_ROOT=$PWD

# BUILD PCRE2
echo "==> BUILD PCRE2"
PCRE2_DIR="$BUILD_ROOT/$(ls $BUILD_ROOT | grep pcre)"
cd $PCRE2_DIR
CC=$CC ./configure --host=$HOST --prefix=$PCRE2_DIR/output
make -j$JOBS
make install
echo "==> BUILD PCRE2 DONE"
sleep 1

# BUILD ZLIB
echo "==> BUILD ZLIB"
ZLIB_DIR="$BUILD_ROOT/$(ls $BUILD_ROOT | grep zlib)"
cd $ZLIB_DIR
CC=$CC ./configure --prefix=$ZLIB_DIR/output
make -j$JOBS
make install
echo "==> BUILD ZLIB DONE"
sleep 1

# BUILD OPENSSL
echo "==> BUILD OPENSSL"
OPENSSL_DIR="$BUILD_ROOT/$(ls $BUILD_ROOT | grep openssl)"
cd $OPENSSL_DIR
CC=$CC AR="$HOST-ar" ./Configure linux-aarch64 --prefix=$OPENSSL_DIR/output
make -j$JOBS
make install
echo "==> BUILD OPENSSL DONE"
sleep 1

# BUILD WGET 1.21
echo "==> BUILD WGET"
WGET_DIR="$BUILD_ROOT/$(ls $BUILD_ROOT | grep wget)"

CFLAGS="-I$ZLIB_DIR/output/include -L$ZLIB_DIR/output/lib \
    -L$PCRE2_DIR/output/lib -I$PCRE2_DIR/output/include \
    -I$OPENSSL_DIR/output/include -L$OPENSSL_DIR/output/lib"
LDFLAGS="-static"

cd $WGET_DIR
make distclean
CFLAGS="$CFLAGS" LDFLAGS="$LDFLAGS" CC="$CC" ./configure --host="$HOST" --prefix=$WGET_DIR/output --with-ssl=openssl
make -j$JOBS
make install
echo "==> BUILD WGET DONE"
sleep 1
echo "Library Output: $WGET_DIR/output"

cp $WGET_DIR/output/bin/wget $BUILD_ROOT
echo "$(file $BUILD_ROOT/wget)"
exit 0
