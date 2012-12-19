#!/bin/bash

#指定目录
file_path="/tmp"

#当前时间的前180天
time=`date -d "180 days ago" +"%Y%m%d"`

#过滤超过180天的文件或目录
file_name=`ls -l --time-style="+%Y%m%d" $file_path|awk -v time="$time" 'NR==2,0 {if ($6<time)print $7;}'`

#判断是否存在超过180天的文件或目录
if [ -z "$file_name" ];then
	#没有就打印"No more than 180 days of file or directory"
	echo "No more than 180 days of file or directory"
else
	#有的话就删除并打印"delete File or directory of more than 180 days"
	echo "delete File or directory of more than 180 days:"
	for i in $file_name
	do
		cd $file_path;rm -rf $i	
		echo "$i"
	done
fi
