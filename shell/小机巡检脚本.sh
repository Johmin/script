#!/usr/bin/ksh

sysdate=`date +"%m/%d"`
HOSTNAME=`hostname`
REPORT="/tmp/report.txt"

function if_error
{
if [[ $? -ne 0 ]]; then # check return code passed to function
    echo "$1" >>$REPORT # if rc > 0 then print error msg and quit
#exit $?
fi
}
echo "********************************系统基本状态检查*********************************\n" >$REPORT
echo "系统主机名 $HOSTNAME\n" >>$REPORT
echo "系统IP配置\n" >>$REPORT
ifconfig -a >>$REPORT
echo "系统运行时间\n" >>$REPORT
uptime >>$REPORT
echo "脚本检查执行时间\n" >>$REPORT
echo "$sysdate" >>$REPORT
echo "********************************检查文件系统使用情况*****************************\n" >>$REPORT
FS=`df -k|sed '1d'|awk 'sub("%","",$4) {if ($4 > 80) print $7}'|xargs`
for i in $FS
do
echo "The $i filesystem percent more than %80 \n" >>$REPORT
done

echo "********************************检查文件系统状态*********************************\n" >>$REPORT
echo "****************************ACTIVE VG********************************************\n" >>$REPORT   
ACVG=`lsvg -o|xargs`                                                                   
echo "Active VG is: $ACVG\n" >>$REPORT                                                 
echo "********************************检查系统LV状态***********************************\n" >>$REPORT 
BLV=`lsvg -l rootvg|grep -E "jfs|jfs2|raw"|grep -v 'N/A'|awk '{print $1}'|xargs`       
for i in $BLV                                                                          
do                                                                                     
lv_stat=`lslv $i | grep "LV STATE"|awk -F ":" '{print $3}'|xargs`                      
if [ $lv_stat == closed/stale ]                                                        
then                                                                                   
echo "逻辑卷 $i 状态有问题\n" >>$REPORT                                                
else                                                                                   
echo "逻辑卷$i状态正常\n" >>$REPORT                                                    
fi                                                                                     
done                                                                                   
                                                                                       
echo "********************************检查磁盘状况*************************************\n" >>$REPORT
disk=`lsvg -o|lsvg -ip|awk '$1~/hdisk/ && $2!~/active/ {print $1}'|xargs`
if [ "$disk" != "" ]
then
for i in $disk
do
echo "磁盘 $disk 有问题!!!\n" >>$REPORT
done
else
echo "磁盘运行正常\n" >>$REPORT
fi

echo "********************************检查HBA卡连接状态********************************\n" >>$REPORT
fget_config -Av|grep -i dacnone >>$REPORT
if [ $? -eq 0 ]
then
echo "HBA卡连接盘阵有问题\n" >>$REPORT
else
echo "HBA卡连接盘阵正常!\n" >>$REPORT
fi

echo "********************************检查内存使用情况*********************************\n" >>$REPORT
PS=`lsps -a|grep 'MB'|awk '{print $5}'|xargs`
for i in $PS
do
if [ $i -gt 50 ]
then
echo " $i 虚拟内存使用率超过 %50 \n" >>$REPORT
else
echo "内存使用正常" >>$REPORT
fi
done
echo "********************************检查CPU使用情况**********************************\n" >>$REPORT
vmstat 1 10 | awk '{print $0;if($1 ~ /^[0-9].*/)(totalcpu+=$16);(avecpu=100-totalcpu/10)}; END {print "The average usage of cpu is :"avecpu}'
if [ "$avecpu" -gt 80 ]
then
    echo "LOG-Warnning:`date +%Y'-'%m'-'%d' '%H':'%M':'%S`, CPU负载超过80%，请检查系统!!\n" >>$REPORT
else
     echo "CPU负载正常!!\n" >>$REPORT
fi

echo "********************************检查网络流量情况*********************************\n" >>$REPORT
      extnetstats=$(no -a | grep extendednetstats | sed -e 's/[^01]//g')
      if [[ $debug = 1 ]]; then
             print \\n "exdendednetstats=$extnetstats"
        if [[ $extnetstats = 1 ]]; then
            netstat -m 2>&1 | grep denied >>$REPORT
          else
            echo "AIX 4.3.2+ and extendednetstats NOT enabled!" >>$REPORT
        fi
     else
        netstat -m 2>&1 | grep denied >>$REPORT
     fi
   echo "network stats" >>$REPORT
   netstat -v 2>&1 | grep -E "STAT|S/W Transmit" >>$REPORT
echo "********************************检查TSM备份情况**********************************\n" >>$REPORT
echo "********************************检查磁盘IO情况***********************************\n" >>$REPORT
if [[ -f "/usr/bin/iostat" ]]
then 
       numdisk=`lsdev -Cc disk | grep hdisk |wc -l | awk '{print $1}'`
      let anyhd=0 
      iostat 2 2 |grep "^hdisk" |tail -$numdisk |while read dsk tm k t kbr kbw
      do {
         if [ $tm -ge 25 ] ; then
         echo $(date +%T) $dsk $tm $k $kbr $kbw >>$REPORT
         let anyhd=1
         fi
         }
      done
      if [ $anyhd -eq 0 ] ; then
         print \\n "没有发现热点盘使用" >>$REPORT
      fi
   else
      print \\n "No iostat file found" >>$REPORT
   fi
echo "********************************检查日志情况**************************************\n" >>$REPORT
errpt | head -10 >>$REPORT
day=`date +%D |awk -F "/" '{print $1$2}'`
errpt | awk '{print $2}' | grep ^$day
if [ $? -eq 0 ]
then
    echo "LOG-Warnning: `date +%Y'-'%m'-'%d' '%H':'%M':'%S`,The system has found a error today.Please check the error report." >>$REPORT
else
     echo "今天系统没有报警日志,系统运行正常!!\n" >>$REPORT
fi

echo "********************************检查HACMP组件安装情况****************************\n" >>$REPORT
lslpp -L|grep cluster >>$REPORT                                                        
if [ $? -eq 0 ]                                                                        
then                                                                                   
echo "系统安装有HACMP组件，请注意下面的HA状态检测" >> $REPORT                          
else                                                                                   
echo "系统没有安装HACMP组件" >> $REPORT                                                
fi                                                                                     
                                                                                       
echo "********************************检查HACMP运行配置情况****************************\n" >>$REPORT
    if [[ -f "/usr/es/sbin/cluster/clstat" ]]                                          
then                                                                                   
    /usr/es/sbin/cluster/clstat -o >>$REPORT
lssrc -g cluster >>$REPORT
cat $REPORT
cat $REPORT| grep "Node:" |awk -F ':' '{print $2,$3}' | awk '{print $1,$3}' | while read line 
do
node=$(echo $line | awk '{print $1}')"'s"
echo $line |grep UP$ >/dev/null
if [ "$?" -eq 0 ]
then 
     echo "The node $node is OK!!"  >>$REPORT
else
     echo "`date +%Y'-'%m'-'%d' '%H':'%M':'%S`,LOG-Warnning: The node $node status is DOWN ,it was terminated ." >>$REPORT
fi
done
else
echo "本机器未安装HACMP组件\n" >>$REPORT
fi

#======================开始对检查记录进行处理===================
if [ -e /tmp/report1.txt ]
then
rm /tmp/report1.txt
fi
cat /tmp/report.txt | while read line
do
echo $line\<\/br\> >> /tmp/report1.txt
done
