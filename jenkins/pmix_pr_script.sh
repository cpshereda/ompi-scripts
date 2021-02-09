#!/bin/bash
ifaketty () { script -qfc "$(printf "%q " "$@")"; }
echo $PATH
echo $SHELL
echo "SHA1 -"${sha1}
echo "On login node:"
hostname
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
make -j 4 V=1 install
if [ $? != 0 ]; then
    echo "Build failed"
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
./pmix_test -n 4 -e ./$test
if [ $? != 0 ]; then
    echo "$test failed"
    exit -1
fi
done
exit 0
