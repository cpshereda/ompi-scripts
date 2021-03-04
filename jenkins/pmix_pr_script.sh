#!/bin/bash
ifaketty () { script -qfc "$(printf "%q " "$@")"; }
echo $PATH
echo $SHELL
echo "SHA1 -"${sha1}
echo "On login node:"
hostname

#
# Start by figuring out what we are...
#
os=`uname -s`
if test "${os}" = "Linux"; then
    eval "PLATFORM_ID=`sed -n 's/^ID=//p' /etc/os-release`"
    eval "VERSION_ID=`sed -n 's/^VERSION_ID=//p' /etc/os-release`"
else
    PLATFORM_ID=`uname -s`
    VERSION_ID=`uname -r`
fi

echo "--> platform: $PLATFORM_ID"
echo "--> version: $VERSION_ID"

./autogen.pl
if [ $? != 0 ]; then
    echo "autogen failed"
    exit -1
fi

./configure --prefix=${PWD}/install_dir --with-libevent=/usr --with-hwloc=/usr
if [ $? != 0 ]; then
    echo "Configure failed"
    exit -1
fi
make clean
make check
if [ $? != 0 ]; then
    echo "make check failed"
    exit -1
fi
make -j 4 V=1 install
if [ $? != 0 ]; then
    echo "make install failed"
    exit -1
fi
export PMIX_INSTALLDIR=$PWD/install_dir
pushd ${PWD}/test/test_v2
make clean
make
if [ $? != 0 ]; then
    echo "make of tests failed"
    exit -1
fi
for test in test_get_basic test_get_peers
do
timeout -s SIGSEGV 10m ./pmix_test -n 4 -e ./$test
if [ $? != 0 ]; then
    echo "$test failed"
    exit -1
fi
done
exit 0
