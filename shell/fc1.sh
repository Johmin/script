#!/bin/sh

file_name=default
old_ip=`cat $file_name |awk -F '//' '{print $2}' |awk -F '/|:' '/192/{print $1}'`
new_ip=192.168.0.100
fc(){
if [ $1 != $new_ip  ];then
	sed -i 's/'$1'/'$new_ip'/g' $file_name
	echo $1
else
	echo "No file can be changed"	
fi
}

for i in ${old_ip[*]}
do
	fc $i
	echo "---------------------"
done

