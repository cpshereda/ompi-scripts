#!/bin/bash

ifaketty () { script -qfc "$(printf "%q " "$@")"; }
export PATH=/usr/bin:$PATH
export PATH=${HOME}/edison_root/bin:${PATH}
echo $PATH
echo $SHELL
echo "SHA1 -"${sha1}
echo "On login node:"
hostname
if [ ! -d /tmp/hpp ]; then
    mkdir /tmp/hpp
fi
# 
# we do this funny business because right now need gni header
# files only available on CLE 5.2UP03 or higher
#
if [ "$NERSC_HOST" == "hopper" ]
then
    export PKG_CONFIG_PATH=/global/homes/h/hpp/opt/cray/gni-headers/default/lib64/pkgconfig:${PKG_CONFIG_PATH}
    export PKG_CONFIG_PATH=/global/homes/h/hpp/opt/cray/ugni/default/lib64/pkgconfig:${PKG_CONFIG_PATH}
    echo $PKG_CONFG_PATH
    pkg-config --cflags cray-gni-headers
fi
module unload cray-mpich
if $( echo ${LOADEDMODULES} | grep --quiet 'PrgEnv-intel' ); then
    module swap PrgEnv-intel PrgEnv-gnu
fi
module list
export CFLAGS="-Wall -Wno-deprecated-declarations"
./autogen.sh
if [ $? != 0 ]; then
    echo "autogen failed"
    exit -1
fi
echo "CONFIGURE WITHOUT KDREG"
#./configure --prefix=${PWD}/libfabric_install 
./configure --prefix=${PWD}/libfabric_install --disable-verbs --disable-usnic --with-criterion=${HOME}/criterion_2.3.1
if [ $? != 0 ]; then
    echo "Configure failed"
    exit -1
fi
make clean
make -j 4 V=1 install
if [ $? != 0 ]; then
    echo "Build failed"
    exit -1
fi
pushd ${PWD}/libfabric_install/bin
ls
#srun -N1 --exclusive -t00:20:00 --ntasks=1  ./gnitest -j1 --verbose < /dev/null
#if [ $? != 0 ]; then
#    echo "Criterion test failed"
#    exit -1
#fi
popd
make clean 
make distclean
./configure --prefix=${PWD}/libfabric_install --disable-verbs --disable-usnic --with-kdreg=${HOME}/kdreg --with-criterion=${HOME}/criterion_2.3.1
if [ $? != 0 ]; then
    echo "Configure failed"
    exit -1
fi
make -j 4 V=1 install
if [ $? != 0 ]; then
    echo "Build failed"
    exit -1
fi
make -j 4 distcheck
if [ $? != 0 ]; then
    echo "distcheck failed"
    exit -1
fi
pushd ${PWD}/libfabric_install/bin
ls
exit 0
echo "TRYING TO GET AN ALLOCATION TO RUN CRITERION"
if [ "$NERSC_HOST" == "cori" ]
then
salloc -I300  -t 20:00 -N 1 --exclusive --cpus-per-task=8 -p debug -C haswell ~/bin/jenkins_helper.sh
elif [ "$NERSC_HOST" == "edison" ]
then
#
# edison has stupid interposer script that's looking for a tty
#
script_hpp -c "salloc -I300  -t 20:00 -N 1 --exclusive --cpus-per-task=8 -p debug ~/bin/jenkins_helper.sh" /dev/null
else
salloc -I300  -t 20:00 -N 1 --exclusive --cpus-per-task=8 ~/bin/jenkins_helper.sh
fi
if [ -f fi_info_failed ]; then
    echo "fi_info failed"
    exit -1
fi
if [ -f criterion_failed ]; then
    echo "criterion failed"
    exit -1
fi
exit 0
