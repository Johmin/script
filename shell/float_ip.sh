#!/bin/sh

ip_port=eth2
ip_address=10.235.131.207
ip_netmask=255.255.255.224
ip_gw=10.235.131.222
ip_route=(

)


case $1 in

start)
        ifconfig |grep "$ip_address" >/dev/null
        if [ $? -ne 0 ];then
            ifconfig $ip_port $ip_address  netmask $ip_netmask up
			ip_mac=`ifconfig -a|grep $ip_port|awk '{print $5}'`
            arp -i $ip_port -s $ip_address $ip_mac
			if	[ -n $ip_route ];then
				for i in ${ip_route[*]}
				do
					route |grep $i >/dev/null
					if [ $? -ne 0 ];then
						route add -host $i gw $ip_gw dev $ip_port
					else
						exit 0
					fi
                done
			fi
			echo "$ip_address has to $ip_port"
			ifconfig $ip_port
        else
            exit 0
        fi
        ;;
stop)
        ifconfig -a|grep "$ip_address" >/dev/null
        if [ $? -eq 0 ];then
            ifdown $ip_port -o force
			echo "$ip_port has stoped"
        else
                exit 0
        fi
        ;;
*)
        echo "Usage: $0 {start|stop}"
esac
