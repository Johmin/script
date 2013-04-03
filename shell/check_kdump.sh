#!/bin/bash

#check OS version
os_version=`cat /etc/SuSE-release |awk -F "=" '/VERSION/ {print $2}'`


#check magic sysrq
sysrq=`cat /proc/sys/kernel/sysrq`
if [ $sysrq = 1 ];then
	echo "magic sysrq: Yes"
else
	echo "magic sysrq: No"
fi

#check memonr
total=`cat /proc/meminfo |awk  '/MemTotal:/{print $2}'`

#configure function
sles11(){
crash=`cat /boot/grub/menu.lst|awk '/crashkernel/{print $(NF-1)}'|awk -F ":" '{print $2}'`
if [ $total -lt 12582912 ];then
	if [ $crash = 128M ];then
		echo "kdump: Yes"
	else
		echo "crashkernel numerical error"
	fi
elif  (( $total > 12582912 )) && (($total <= 67108864));then
	if  [ $crash = 256M ];then
		echo "Kdump: Yes"
	else
                echo "crashkernel numerical error"
        fi
elif (($total > 67108864 )) && (($total -le 134217728 )) ;then
	if  [ $crash = 512M ];then
		echo "Kdump: Yes"
	else
                echo "crashkernel numerical error"
	fi
elif  [ $total > 134217728 ];then
		if  [ $crash = 1024M ];then
			echo "Kdump: Yes"
		else
                	echo "crashkernel numerical error"
        	fi
else
                	echo "crashkernel numerical error"
fi
exit
}


sles10(){
crash=`cat /boot/grub/menu.lst|awk '/crashkernel/{print $NF}'|awk -F "=" '{print $2}'`
if [ $total -lt 12582912 ];then
	if [ $crash = "64M@16M" ];then
                echo "kdump: Yes"
	else
                echo "crashkernel numerical error"
	fi
elif  (( $total > 12582912 )) && (($total <= 67108864));then
	if  [ $crash = "128M@16M" ];then
                echo "Kdump: Yes"
	else
                echo "crashkernel numerical error"
	fi
elif (($total > 67108864 )) && (($total -le 134217728 )) ;then
	if  [ $crash = "256M@16M" ];then
		echo "Kdump: Yes"
	else
		echo "crashkernel numerical error"
	fi
elif  [ $total > 134217728 ];then
                if  [ $crash = "512M@16M" ];then
                        echo "Kdump: Yes"
                else
                        echo "crashkernel numerical error"
                fi
else
                        echo "crashkernel numerical error"
fi
}

#check kdump RPM
rpm -qa|grep ^kdump- >/dev/null
if [ $? = 0 ];then
	cat /boot/grub/menu.lst |grep crashkernel >/dev/null
	if [ $? = 0 ];then
		if [ $os_version = 10 ];then
			sles10
		elif [ $os_version = 11 ];then
			sles11
		else
			echo " OS VERSION = SuSE $os_version"
		fi
	else
		echo "kdump: No"
	fi
else
	echo "RPM Not Installed: kdump"
fi
