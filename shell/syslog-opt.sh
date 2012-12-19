#!/bin/bash

today=`date +%Y%m%d`
cf_file="/etc/logrotate.d/syslog"
cp /etc/logrotate.d/syslog /tmp/syslog.bak$today
#judge
grep -A 13 mail.err $cf_file |grep monthly
if [ $? -eq 1 ]
then
	sed -i '/mail.err/ a\    monthly' $cf_file
	sleep 2
	grep -A 13 mail.err $cf_file |grep monthly
	if [ $? -ne 1 ]
	then
		echo "Append 'monthly' field successful"
	else
		echo "Append faild, please check"
	fi
else
	echo "Configure file is already append, do nothing,exit..."
	exit 0
fi

