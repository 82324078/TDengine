#!/bin/bash
#
# Generate tar.gz package for all os system

set -e
#set -x

curr_dir=$(pwd)
compile_dir=$1
version=$2
build_time=$3
cpuType=$4
osType=$5
verMode=$6
verType=$7
pagMode=$8
versionComp=$9

script_dir="$(dirname $(readlink -f $0))"
top_dir="$(readlink -f ${script_dir}/../..)"

# create compressed install file.
build_dir="${compile_dir}/build"
code_dir="${top_dir}/src"
release_dir="${top_dir}/release"

#package_name='linux'
if [ "$verMode" == "cluster" ]; then
    install_dir="${release_dir}/TQ-enterprise-server-${version}"
else
    install_dir="${release_dir}/TQ-server-${version}"
fi

lib_files="${build_dir}/lib/libtaos.so.${version}"
header_files="${code_dir}/inc/taos.h ${code_dir}/inc/taosdef.h ${code_dir}/inc/taoserror.h"
if [ "$verMode" == "cluster" ]; then
  cfg_dir="${top_dir}/../enterprise/packaging/cfg"
else
  cfg_dir="${top_dir}/packaging/cfg"
fi
install_files="${script_dir}/install_tq.sh"
nginx_dir="${code_dir}/../../enterprise/src/plugins/web"

# make directories.
mkdir -p ${install_dir}
mkdir -p ${install_dir}/inc && cp ${header_files} ${install_dir}/inc
mkdir -p ${install_dir}/cfg && cp ${cfg_dir}/taos.cfg ${install_dir}/cfg/tq.cfg

mkdir -p ${install_dir}/bin
if [ "$pagMode" == "lite" ]; then
  strip ${build_dir}/bin/taosd
  strip ${build_dir}/bin/taos
  cp ${build_dir}/bin/taos          ${install_dir}/bin/tq
  cp ${build_dir}/bin/taosd         ${install_dir}/bin/tqd
  cp ${script_dir}/remove_tq.sh  ${install_dir}/bin
else
  cp ${build_dir}/bin/taos          ${install_dir}/bin/tq
  cp ${build_dir}/bin/taosd         ${install_dir}/bin/tqd
  cp ${script_dir}/remove_tq.sh  ${install_dir}/bin
  cp ${build_dir}/bin/taosadapter          ${install_dir}/bin/taosadapter ||:
  cp ${build_dir}/bin/taosdemo      ${install_dir}/bin/tqdemo
  cp ${build_dir}/bin/tarbitrator   ${install_dir}/bin
  cp ${script_dir}/set_core.sh      ${install_dir}/bin
  cp ${script_dir}/get_client.sh    ${install_dir}/bin
  cp ${script_dir}/startPre.sh      ${install_dir}/bin
  cp ${script_dir}/taosd-dump-cfg.gdb  ${install_dir}/bin
fi
chmod a+x ${install_dir}/bin/* || :

if [ "$verMode" == "cluster" ]; then
    sed 's/verMode=edge/verMode=cluster/g' ${install_dir}/bin/remove_tq.sh >> remove_tq_temp.sh
    mv remove_tq_temp.sh ${install_dir}/bin/remove_tq.sh

    mkdir -p ${install_dir}/nginxd && cp -r ${nginx_dir}/* ${install_dir}/nginxd
    cp ${nginx_dir}/png/taos.png ${install_dir}/nginxd/admin/images/taos.png
    rm -rf ${install_dir}/nginxd/png

    sed -i "s/TDengine/TQ/g"   ${install_dir}/nginxd/admin/*.html
    sed -i "s/TDengine/TQ/g"   ${install_dir}/nginxd/admin/js/*.js

    sed -i '/dataDir/ {s/taos/tq/g}'  ${install_dir}/cfg/tq.cfg
    sed -i '/logDir/  {s/taos/tq/g}'  ${install_dir}/cfg/tq.cfg
    sed -i "s/TDengine/TQ/g"        ${install_dir}/cfg/tq.cfg

    if [ "$cpuType" == "aarch64" ]; then
        cp -f ${install_dir}/nginxd/sbin/arm/64bit/nginx ${install_dir}/nginxd/sbin/
    elif [ "$cpuType" == "aarch32" ]; then
        cp -f ${install_dir}/nginxd/sbin/arm/32bit/nginx ${install_dir}/nginxd/sbin/
    fi
    rm -rf ${install_dir}/nginxd/sbin/arm
fi

cd ${install_dir}
tar -zcv -f tq.tar.gz * --remove-files  || :
exitcode=$?
if [ "$exitcode" != "0" ]; then
    echo "tar tq.tar.gz error !!!"
    exit $exitcode
fi

cd ${curr_dir}
cp ${install_files} ${install_dir}
if [ "$verMode" == "cluster" ]; then
    sed 's/verMode=edge/verMode=cluster/g' ${install_dir}/install_tq.sh >> install_tq_temp.sh
    mv install_tq_temp.sh ${install_dir}/install_tq.sh
fi
if [ "$pagMode" == "lite" ]; then
    sed 's/pagMode=full/pagMode=lite/g' ${install_dir}/install.sh >> install_tq_temp.sh
    mv install_tq_temp.sh ${install_dir}/install_tq.sh
fi
chmod a+x ${install_dir}/install_tq.sh

# Copy example code
mkdir -p ${install_dir}/examples
examples_dir="${top_dir}/tests/examples"
cp -r ${examples_dir}/c      ${install_dir}/examples
sed -i '/passwd/ {s/taosdata/tqueue/g}'  ${install_dir}/examples/c/*.c
sed -i '/root/   {s/taosdata/tqueue/g}'  ${install_dir}/examples/c/*.c

if [[ "$pagMode" != "lite" ]] && [[ "$cpuType" != "aarch32" ]]; then
  cp -r ${examples_dir}/JDBC   ${install_dir}/examples
  cp -r ${examples_dir}/matlab ${install_dir}/examples
  sed -i '/password/ {s/taosdata/tqueue/g}'  ${install_dir}/examples/matlab/TDengineDemo.m
  cp -r ${examples_dir}/python ${install_dir}/examples
  sed -i '/password/ {s/taosdata/tqueue/g}'  ${install_dir}/examples/python/read_example.py
  cp -r ${examples_dir}/R      ${install_dir}/examples
  sed -i '/password/ {s/taosdata/tqueue/g}'  ${install_dir}/examples/R/command.txt
  cp -r ${examples_dir}/go     ${install_dir}/examples
  sed -i '/root/ {s/taosdata/tqueue/g}'  ${install_dir}/examples/go/taosdemo.go
fi
# Copy driver
mkdir -p ${install_dir}/driver && cp ${lib_files} ${install_dir}/driver && echo "${versionComp}" > ${install_dir}/driver/vercomp.txt

# Copy connector
connector_dir="${code_dir}/connector"
mkdir -p ${install_dir}/connector
if [[ "$pagMode" != "lite" ]] && [[ "$cpuType" != "aarch32" ]]; then
  cp ${build_dir}/lib/*.jar      ${install_dir}/connector ||:

  if find ${connector_dir}/go -mindepth 1 -maxdepth 1 | read; then
    cp -r ${connector_dir}/go ${install_dir}/connector
  else
    echo "WARNING: go connector not found, please check if want to use it!"
  fi
  cp -r ${connector_dir}/python  ${install_dir}/connector/

  sed -i '/password/ {s/taosdata/tqueue/g}'  ${install_dir}/connector/python/taos/cinterface.py

  sed -i '/password/ {s/taosdata/tqueue/g}'  ${install_dir}/connector/python/taos/subscription.py

  sed -i '/self._password/ {s/taosdata/tqueue/g}'  ${install_dir}/connector/python/taos/connection.py
fi

cd ${release_dir}

if [ "$verMode" == "cluster" ]; then
  pkg_name=${install_dir}-${osType}-${cpuType}
elif [ "$verMode" == "edge" ]; then
  pkg_name=${install_dir}-${osType}-${cpuType}
else
  echo "unknow verMode, nor cluster or edge"
  exit 1
fi

if [ "$pagMode" == "lite" ]; then
  pkg_name=${pkg_name}-Lite
fi

if [ "$verType" == "beta" ]; then
  pkg_name=${pkg_name}-${verType}
elif [ "$verType" == "stable" ]; then
  pkg_name=${pkg_name}
else
  echo "unknow verType, nor stabel or beta"
  exit 1
fi

tar -zcv -f "$(basename ${pkg_name}).tar.gz" $(basename ${install_dir}) --remove-files || :
exitcode=$?
if [ "$exitcode" != "0" ]; then
    echo "tar ${pkg_name}.tar.gz error !!!"
    exit $exitcode
fi

cd ${curr_dir}
