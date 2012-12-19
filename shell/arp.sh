#!/bin/sh

ip_port=eth2
ip_address=10.235.131.207
ip_netmask=255.255.255.224
ip_gw=10.235.131.222
hostname1=sles11
hostname1_mac=00:0C:29:5D:35:39
hostname2=sles10
hostname2_mac=00:0C:29:DB:BA:50
ip_route=(
10.235.138.145
10.235.138.146
10.235.138.147
10.235.138.148
10.235.138.149
10.235.138.150
10.235.138.151
10.235.138.152
10.235.138.153
10.235.138.155
10.235.139.209
10.235.139.210
)

fb(){
cat >>/tmp/mac.cfg <<EOF
$hostname1_mac $hostname1
$hostname2_mac $hostname2
EOF
}

fc(){
    for i in ${ip_route[*]}
    do
      route |grep $i >/dev/null
      if [ $? -ne 0 ];then
         route add -host $i gw $ip_gw dev $ip_port
      else
         exit 0
      fi
    done
}

case $1 in

start)
	arp -d $ip_address >/dev/null 2>&1  
	received=`ping -c 4 $ip_address |awk '/received/{print $4}' 2>&1`
	if [ $received -eq 0 ];then
		ifconfig $ip_port $ip_address  netmask $ip_netmask up
		fc
	else
		ifconfig |grep "$ip_address" >/dev/null
		if [ $? -eq 0 ];then
			echo "$ip_address on the run in localhost"
			fc
		else
			fb
			ip_mac=`arp |awk /$ip_address/'{print $3}'`
			host_mac=`cat /tmp/mac.cfg|grep -i "$ip_mac"`
			if [ $? -eq 0 ];then
				echo "$ip_address on the run in `echo $host_mac |awk '{print $2}'`"
				exit 0
			else
				echo "$ip_address is exist,Correspondence MAC address is $ip_mac,exit..."
				exit 0
			fi
		fi
	fi
	;;
stop)
        ifconfig |grep "$ip_address" >/dev/null
        if [ $? -eq 0 ];then
                ifconfig $ip_port $ip_address down
        else
                exit 0
        fi
        ;;
*)
        echo "Usage: $0 {start|stop}"
esac
