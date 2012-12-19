#!/bin/sh

PXE_PATH=/tftpboot/pxelinux.cfg
CFG_PATH=/srv/www/htdocs


fc(){
SUBTEMPLATE=`cat $1|grep -v ^# |awk -F ";" '{print $1}'`
VLANID=`cat $1|grep -v ^# |awk -F ";" '{print $2}'`
IPADDR=`cat $1|grep -v ^# |awk -F ";" '{print $3}'`
NETMASK=`cat $1|grep -v ^# |awk -F ";" '{print $4}'`
GATEWAY=`cat $1|grep -v ^# |awk -F ";" '{print $5}'`
host_name=`cat $1|grep -v ^# |awk -F ";" '{print $6}'`
STORAGENAME=`cat $1|grep -v ^# |awk -F ";" '{print $7}'`
VMKERNELNAME=`cat $1|grep -v ^# |awk -F ";" '{print $8}'`
VMOTIONIP=`cat $1|grep -v ^# |awk -F ";" '{print $9}'`
NTPIP=`cat $1|grep -v ^# |awk -F ";" '{print $10}'`
}

case $1 in
4)
		fc $2
		#Config pxelinux.cfg/default
		for i in $host_name
		do
		cat >> $PXE_PATH/default <<EOF
		[SEPARATOR]
		label $host_name
		menu label $host_name
		[PXEPASSWD]
		kernel vesamenu.c32
		append pxelinux.cfg/templates/$host_name.menu
EOF
		#Config host kickstart config file
		cd $PXE_PATH/templates/
		cp esx4_a.menu $host_name.menu
		sed -i 's/esx4_a/'$host_name'/g' $host_name.menu
		cd $CFG_PATH
		mkdir $host_name
		cp esx4_a/default $host_name/
		cd $host_name
		sed -i 's/\[VLANID\]/'$VLANID'/g' default
		sed -i 's/\[IPADDR\]/'$IPADDR'/g' default
		sed -i 's/\[NETMASK\]/'$NETMASK'/g' default
		sed -i 's/\[GATEWAY\]/'$GATEWAY'/g' default
		sed -i 's/\[HOSTNAME\]/'$host_name'/g' default
		sed -i 's/\[DISKTYPE\]/'$DISKTYPE'/g' default
		sed -i 's/\[STORAGENAME\]/'$STORAGENAME'/g' default
		sed -i 's/\[VMKERNELNAME\]/'$VMKERNELNAME'/g' default
		sed -i 's/\[VMOTIONIP\]/'$VMOTIONIP'/g' default
		sed -i 's/\[NTPIP\]/'$NTPIP'/g' default
		sed -i 's/\[SUBTEMPLATE\]/'$SUBTEMPLATE'/g' default
		done
		exit 0
		;;
5)
		fc $2
		#Config pxelinux.cfg/default
		for i in $host_name
		do
		cat >> $PXE_PATH/default <<EOF
		[SEPARATOR]
		label $host_name
		menu label $host_name
		[PXEPASSWD]
		kernel vesamenu.c32
		append pxelinux.cfg/templates/$host_name.menu
EOF
		#Config host kickstart config file
		cd $PXE_PATH/templates/
		cp esxi5_a.menu $host_name.menu
		sed -i 's/esxi5_a/'$host_name'/g' $host_name.menu
		cd $CFG_PATH
		mkdir $host_name
		cp esxi5_a/default $host_name/
		cd $host_name
		done
		exit 0
		;;
*)
        echo "Usage: $0 [OPTION]...[FILE]..."
		echo "option: {4|5}"
esac