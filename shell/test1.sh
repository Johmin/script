#!/bin/sh

PXE_PATH=/tftpboot/pxelinux.cfg
CFG_PATH=/srv/www/htdocs/kickstart

fa(){
#Config esx4 host kickstart config file
                cd $PXE_PATH/templates/
                cp esx4_a.menu $host_name.menu
                sed -i 's/esx4_a/'$host_name'/g' $host_name.menu
                cd $CFG_PATH
				mkdir $host_name
                cp  esx4_a/default $host_name/
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
}

fb(){
#Config esxi5 host kickstart config file
		cd $PXE_PATH/templates/
		cp esxi5_a.menu $host_name.menu
		sed -i 's/esxi5_a/'$host_name'/g' $host_name.menu
		cd $CFG_PATH
		mkdir $host_name
		cp  esxi5_a/default $host_name/
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
}

fc(){
parameter=`cat $2|grep -v ^#`
for i in $parameter
do
#Set variables
	SUBTEMPLATE=`echo $i|awk -F ";" '{print $1}'`
	VLANID=`echo $i|awk -F ";" '{print $2}'`
	IPADDR=`echo $i|awk -F ";" '{print $3}'`
	NETMASK=`echo $i|awk -F ";" '{print $4}'`
	GATEWAY=`echo $i|awk -F ";" '{print $5}'`
	host_name=`echo $i |awk -F ";" '{print $6}'`
	STORAGENAME=`echo $i |awk -F ";" '{print $7}'`
	VMKERNELNAME=`echo $i|awk -F ";" '{print $8}'`
	VMOTIONIP=`echo $i|awk -F ";" '{print $9}'`
	NTPIP=`echo $i|awk -F ";" '{print $10}'`
	MAC=`echo $i|awk -F ";" '{print $11}'|sed 's/:/-/g'`

	#Config pxelinux.cfg/default
	if [ -z '$MAC' ];then
		cp $PXE_PATH/temp $PXE_PATH/01-$MAC
		cat >> $PXE_PATH/01-$MAC <<EOF
			[SEPARATOR]
			label $host_name
			menu label $host_name
			[PXEPASSWD]
			kernel vesamenu.c32
			append pxelinux.cfg/templates/$host_name.menu
EOF 
	else
		cat >> $PXE_PATH/default <<EOF
			[SEPARATOR]
			label $host_name
			menu label $host_name
			[PXEPASSWD]
			kernel vesamenu.c32
			append pxelinux.cfg/templates/$host_name.menu
EOF
	fi

#Config host kickstart config file
		if [ $1 -eq 4 ];then
			fa
		elif [ $1 -eq 5 ];then
			fb
		else
			exit
		fi
done
}

case $1 in
4)
		fc $1 $2 
		exit 0
		;;
5)
		fc $1 $2
		exit 0
		;;
*)
        echo "Usage: $0 [OPTION]...[FILE]..."
		echo "option: {4|5}"
esac	
