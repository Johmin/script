#!/bin/sh

file_name=(
a
b
c
d
e
f

)
old_ip=192.168.0.1
new_ip=192.168.0.100
fc(){
if [ `cat $1` = $old_ip  ];then
	sed -i 's/'$old_ip'/'$new_ip'/g' $1
	cat $1
else
	echo "No file can be changed"	
fi
}

for i in ${file_name[*]}
do
	fc $i
	echo "---------------------"
done

