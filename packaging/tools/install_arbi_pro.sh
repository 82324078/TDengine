#!/bin/bash
#
# This file is used to install database on linux systems. The operating system
# is required to use systemd to manage services at boot

set -e
#set -x

# -----------------------Variables definition---------------------
script_dir=$(dirname $(readlink -f "$0"))

bin_link_dir="/usr/bin"
#inc_link_dir="/usr/include"

#install main path
install_main_dir="/usr/local/tarbitrator"

# old bin dir
bin_dir="/usr/local/tarbitrator/bin"

service_config_dir="/etc/systemd/system"

# Color setting
RED='\033[0;31m'
GREEN='\033[1;32m'
GREEN_DARK='\033[0;32m'
GREEN_UNDERLINE='\033[4;32m'
NC='\033[0m'

csudo=""
if command -v sudo > /dev/null; then
    csudo="sudo"
fi

update_flag=0

initd_mod=0
service_mod=2
if pidof systemd &> /dev/null; then
    service_mod=0
elif $(which service &> /dev/null); then    
    service_mod=1
    service_config_dir="/etc/init.d" 
    if $(which chkconfig &> /dev/null); then
         initd_mod=1 
    elif $(which insserv &> /dev/null); then
        initd_mod=2
    elif $(which update-rc.d &> /dev/null); then
        initd_mod=3
    else
        service_mod=2
    fi
else 
    service_mod=2
fi


# get the operating system type for using the corresponding init file
# ubuntu/debian(deb), centos/fedora(rpm), others: opensuse, redhat, ..., no verification
#osinfo=$(awk -F= '/^NAME/{print $2}' /etc/os-release)
if [[ -e /etc/os-release ]]; then
  osinfo=$(cat /etc/os-release | grep "NAME" | cut -d '"' -f2)   ||:
else
  osinfo=""
fi
#echo "osinfo: ${osinfo}"
os_type=0
if echo $osinfo | grep -qwi "ubuntu" ; then
#  echo "This is ubuntu system"
  os_type=1
elif echo $osinfo | grep -qwi "debian" ; then
#  echo "This is debian system"
  os_type=1
elif echo $osinfo | grep -qwi "Kylin" ; then
#  echo "This is Kylin system"
  os_type=1
elif  echo $osinfo | grep -qwi "centos" ; then
#  echo "This is centos system"
  os_type=2
elif echo $osinfo | grep -qwi "fedora" ; then
#  echo "This is fedora system"
  os_type=2
else
  echo " osinfo: ${osinfo}"
  echo " This is an officially unverified linux system," 
  echo " if there are any problems with the installation and operation, "
  echo " please feel free to contact hanatech.com.cn for support."
  os_type=1
fi

function kill_tarbitrator() {
  pid=$(ps -ef | grep "tarbitrator" | grep -v "grep" | awk '{print $2}')
  if [ -n "$pid" ]; then
    ${csudo} kill -9 $pid   || :
  fi
}

function install_main_path() {
    #create install main dir and all sub dir
    ${csudo} rm -rf ${install_main_dir}    || :
    ${csudo} mkdir -p ${install_main_dir}
    ${csudo} mkdir -p ${install_main_dir}/bin  
    #${csudo} mkdir -p ${install_main_dir}/include
    ${csudo} mkdir -p ${install_main_dir}/init.d
}

function install_bin() {
    # Remove links
    ${csudo} rm -f ${bin_link_dir}/rmtarbitrator   || :
    ${csudo} rm -f ${bin_link_dir}/tarbitrator     || :
    ${csudo} cp -r ${script_dir}/bin/* ${install_main_dir}/bin && ${csudo} chmod 0555 ${install_main_dir}/bin/*

    #Make link
    [ -x ${install_main_dir}/bin/remove_arbi_prodb.sh ] && ${csudo} ln -s ${install_main_dir}/bin/remove_arbi_prodb.sh ${bin_link_dir}/rmtarbitrator  || :
    [ -x ${install_main_dir}/bin/tarbitrator ] && ${csudo} ln -s ${install_main_dir}/bin/tarbitrator ${bin_link_dir}/tarbitrator || :
}

function install_header() {
    ${csudo} rm -f ${inc_link_dir}/taos.h ${inc_link_dir}/taosdef.h ${inc_link_dir}/taoserror.h    || :
    ${csudo} cp -f ${script_dir}/inc/* ${install_main_dir}/include && ${csudo} chmod 644 ${install_main_dir}/include/*    
    ${csudo} ln -s ${install_main_dir}/include/taos.h ${inc_link_dir}/taos.h
    ${csudo} ln -s ${install_main_dir}/include/taosdef.h ${inc_link_dir}/taosdef.h
    ${csudo} ln -s ${install_main_dir}/include/taoserror.h ${inc_link_dir}/taoserror.h
}

function clean_service_on_sysvinit() {
    if pidof tarbitrator &> /dev/null; then
        ${csudo} service tarbitratord stop || :
    fi

    if ((${initd_mod}==1)); then
      if [ -e ${service_config_dir}/tarbitratord ]; then 
        ${csudo} chkconfig --del tarbitratord || :
      fi
    elif ((${initd_mod}==2)); then
      if [ -e ${service_config_dir}/tarbitratord ]; then
        ${csudo} insserv -r tarbitratord || :
      fi
    elif ((${initd_mod}==3)); then
      if [ -e ${service_config_dir}/tarbitratord ]; then
        ${csudo} update-rc.d -f tarbitratord remove || :
      fi
    fi    

    ${csudo} rm -f ${service_config_dir}/tarbitratord || :
    
    if $(which init &> /dev/null); then
        ${csudo} init q || :
    fi
}

function install_service_on_sysvinit() {
    clean_service_on_sysvinit
    sleep 1

    # Install prodbs service

    if ((${os_type}==1)); then
        ${csudo} cp -f ${script_dir}/init.d/tarbitratord.deb ${install_main_dir}/init.d/tarbitratord
        ${csudo} cp    ${script_dir}/init.d/tarbitratord.deb ${service_config_dir}/tarbitratord && ${csudo} chmod a+x ${service_config_dir}/tarbitratord
    elif ((${os_type}==2)); then
        ${csudo} cp -f ${script_dir}/init.d/tarbitratord.rpm ${install_main_dir}/init.d/tarbitratord
        ${csudo} cp    ${script_dir}/init.d/tarbitratord.rpm ${service_config_dir}/tarbitratord && ${csudo} chmod a+x ${service_config_dir}/tarbitratord
    fi
    
    if ((${initd_mod}==1)); then
        ${csudo} chkconfig --add tarbitratord || :
        ${csudo} chkconfig --level 2345 tarbitratord on || :
    elif ((${initd_mod}==2)); then
        ${csudo} insserv tarbitratord || :
        ${csudo} insserv -d tarbitratord || :
    elif ((${initd_mod}==3)); then
        ${csudo} update-rc.d tarbitratord defaults || :
    fi
}

function clean_service_on_systemd() {
  tarbitratord_service_config="${service_config_dir}/tarbitratord.service"
  if systemctl is-active --quiet tarbitratord; then
      echo "tarbitrator is running, stopping it..."
      ${csudo} systemctl stop tarbitratord &> /dev/null || echo &> /dev/null
  fi
  ${csudo} systemctl disable tarbitratord &> /dev/null || echo &> /dev/null

  ${csudo} rm -f ${tarbitratord_service_config}
}

function install_service_on_systemd() {
    clean_service_on_systemd

    tarbitratord_service_config="${service_config_dir}/tarbitratord.service"

    ${csudo} bash -c "echo '[Unit]'                                  >> ${tarbitratord_service_config}"
    ${csudo} bash -c "echo 'Description=ProDB arbitrator service' >> ${tarbitratord_service_config}"
    ${csudo} bash -c "echo 'After=network-online.target'             >> ${tarbitratord_service_config}"
    ${csudo} bash -c "echo 'Wants=network-online.target'             >> ${tarbitratord_service_config}"
    ${csudo} bash -c "echo                                           >> ${tarbitratord_service_config}"
    ${csudo} bash -c "echo '[Service]'                               >> ${tarbitratord_service_config}"
    ${csudo} bash -c "echo 'Type=simple'                             >> ${tarbitratord_service_config}"
    ${csudo} bash -c "echo 'ExecStart=/usr/bin/tarbitrator'          >> ${tarbitratord_service_config}"
    ${csudo} bash -c "echo 'TimeoutStopSec=1000000s'                 >> ${tarbitratord_service_config}"
    ${csudo} bash -c "echo 'LimitNOFILE=infinity'                    >> ${tarbitratord_service_config}"
    ${csudo} bash -c "echo 'LimitNPROC=infinity'                     >> ${tarbitratord_service_config}"
    ${csudo} bash -c "echo 'LimitCORE=infinity'                      >> ${tarbitratord_service_config}"
    ${csudo} bash -c "echo 'TimeoutStartSec=0'                       >> ${tarbitratord_service_config}"
    ${csudo} bash -c "echo 'StandardOutput=null'                     >> ${tarbitratord_service_config}"
    ${csudo} bash -c "echo 'Restart=always'                          >> ${tarbitratord_service_config}"
    ${csudo} bash -c "echo 'StartLimitBurst=3'                       >> ${tarbitratord_service_config}"
    ${csudo} bash -c "echo 'StartLimitInterval=60s'                  >> ${tarbitratord_service_config}"
    ${csudo} bash -c "echo                                           >> ${tarbitratord_service_config}"
    ${csudo} bash -c "echo '[Install]'                               >> ${tarbitratord_service_config}"
    ${csudo} bash -c "echo 'WantedBy=multi-user.target'              >> ${tarbitratord_service_config}"
    ${csudo} systemctl enable tarbitratord
}

function install_service() {
    if ((${service_mod}==0)); then
        install_service_on_systemd
    elif ((${service_mod}==1)); then
        install_service_on_sysvinit
    else
        kill_tarbitrator
    fi
}

function update_prodb() {
    # Start to update
    echo -e "${GREEN}Start to update ProDB's arbitrator ...${NC}"
    # Stop the service if running
    if pidof tarbitrator &> /dev/null; then
        if ((${service_mod}==0)); then
            ${csudo} systemctl stop tarbitratord || :
        elif ((${service_mod}==1)); then
            ${csudo} service tarbitratord stop || :
        else
            kill_tarbitrator
        fi
        sleep 1
    fi
    
    install_main_path
    #install_header
    install_bin
    install_service
		
    echo
    if ((${service_mod}==0)); then
        echo -e "${GREEN_DARK}To start arbitrator     ${NC}: ${csudo} systemctl start tarbitratord${NC}"
    elif ((${service_mod}==1)); then
        echo -e "${GREEN_DARK}To start arbitrator     ${NC}: ${csudo} service tarbitratord start${NC}"
    else
        echo -e "${GREEN_DARK}To start arbitrator     ${NC}: ./tarbitrator${NC}"
    fi                
    echo
    echo -e "\033[44;32;1mProDB's arbitrator is updated successfully!${NC}"
}

function install_prodb() {
    # Start to install
    echo -e "${GREEN}Start to install ProDB's arbitrator ...${NC}"
    
    install_main_path	   
    #install_header
    install_bin
    install_service
    echo
    if ((${service_mod}==0)); then
        echo -e "${GREEN_DARK}To start arbitrator     ${NC}: ${csudo} systemctl start tarbitratord${NC}"
    elif ((${service_mod}==1)); then
        echo -e "${GREEN_DARK}To start arbitrator     ${NC}: ${csudo} service tarbitratord start${NC}"
    else
        echo -e "${GREEN_DARK}To start arbitrator     ${NC}: tarbitrator${NC}"
    fi

    echo -e "\033[44;32;1mProDB's arbitrator is installed successfully!${NC}"
    echo
}


## ==============================Main program starts from here============================
# Install server and client
if [ -x ${bin_dir}/tarbitrator ]; then
    update_flag=1
    update_prodb
else
    install_prodb
fi

