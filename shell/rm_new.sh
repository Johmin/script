#!/bin/bash

#指定目录
file_path="/home"

#过滤$file_path是否有子目录
ls -l $file_path |grep ^d >/dev/null

#判断是否存在字目录
if [ $? -eq 0 ];then
	#存在就进行过滤，以当前时间为准，将180天以前的空目录和文件删除
	for ((i=1;i=i+1;i++))
	do
        	find $file_path/*/* -empty -ctime +180 -exec rm -rf {} \;>/dev/null
        	if [ $? = 0 ];then
			echo "$IFS-------------$IFS Completed"
                	exit 0
        	fi
	done
else
	#如果不存在，直接退出
	exit 0
fi
