#!/bin/bash
#last modify: 2012-11-18

#global variable
file_path="/home/"
time=`date -d "180 days ago" +"%Y%m%d"`

#remove file
file_name=`ls -lR --time-style="+%Y%m%d" $file_path/* |awk -v time="$time" '{if($1!~/^d/) if($7!~/^\.|\//) if($6<=time)print $7}'`
for i in $file_name
do
        find $file_path -name $i -ctime +180 -exec rm -rf {} \;
done

#remove folder
folder=`ls -lR --time-style="+%Y%m%d" $file_path/* |awk -v time="$time" '{if($1~/^d/) if($7!~/^\.|\//) if($6<=time)print $7}'`
for i in $folder
do
	find $file_path -empty -name $i -ctime +180 -exec rm -rf {} \;
done
