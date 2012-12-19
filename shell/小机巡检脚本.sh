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
echo "********************************ϵͳ����״̬���*********************************\n" >$REPORT
echo "ϵͳ������ $HOSTNAME\n" >>$REPORT
echo "ϵͳIP����\n" >>$REPORT
ifconfig -a >>$REPORT
echo "ϵͳ����ʱ��\n" >>$REPORT
uptime >>$REPORT
echo "�ű����ִ��ʱ��\n" >>$REPORT
echo "$sysdate" >>$REPORT
echo "********************************����ļ�ϵͳʹ�����*****************************\n" >>$REPORT
FS=`df -k|sed '1d'|awk 'sub("%","",$4) {if ($4 > 80) print $7}'|xargs`
for i in $FS
do
echo "The $i filesystem percent more than %80 \n" >>$REPORT
done

echo "********************************����ļ�ϵͳ״̬*********************************\n" >>$REPORT
echo "****************************ACTIVE VG********************************************\n" >>$REPORT   
ACVG=`lsvg -o|xargs`                                                                   
echo "Active VG is: $ACVG\n" >>$REPORT                                                 
echo "********************************���ϵͳLV״̬***********************************\n" >>$REPORT 
BLV=`lsvg -l rootvg|grep -E "jfs|jfs2|raw"|grep -v 'N/A'|awk '{print $1}'|xargs`       
for i in $BLV                                                                          
do                                                                                     
lv_stat=`lslv $i | grep "LV STATE"|awk -F ":" '{print $3}'|xargs`                      
if [ $lv_stat == closed/stale ]                                                        
then                                                                                   
echo "�߼��� $i ״̬������\n" >>$REPORT                                                
else                                                                                   
echo "�߼���$i״̬����\n" >>$REPORT                                                    
fi                                                                                     
done                                                                                   
                                                                                       
echo "********************************������״��*************************************\n" >>$REPORT
disk=`lsvg -o|lsvg -ip|awk '$1~/hdisk/ && $2!~/active/ {print $1}'|xargs`
if [ "$disk" != "" ]
then
for i in $disk
do
echo "���� $disk ������!!!\n" >>$REPORT
done
else
echo "������������\n" >>$REPORT
fi

echo "********************************���HBA������״̬********************************\n" >>$REPORT
fget_config -Av|grep -i dacnone >>$REPORT
if [ $? -eq 0 ]
then
echo "HBA����������������\n" >>$REPORT
else
echo "HBA��������������!\n" >>$REPORT
fi

echo "********************************����ڴ�ʹ�����*********************************\n" >>$REPORT
PS=`lsps -a|grep 'MB'|awk '{print $5}'|xargs`
for i in $PS
do
if [ $i -gt 50 ]
then
echo " $i �����ڴ�ʹ���ʳ��� %50 \n" >>$REPORT
else
echo "�ڴ�ʹ������" >>$REPORT
fi
done
echo "********************************���CPUʹ�����**********************************\n" >>$REPORT
vmstat 1 10 | awk '{print $0;if($1 ~ /^[0-9].*/)(totalcpu+=$16);(avecpu=100-totalcpu/10)}; END {print "The average usage of cpu is :"avecpu}'
if [ "$avecpu" -gt 80 ]
then
    echo "LOG-Warnning:`date +%Y'-'%m'-'%d' '%H':'%M':'%S`, CPU���س���80%������ϵͳ!!\n" >>$REPORT
else
     echo "CPU��������!!\n" >>$REPORT
fi

echo "********************************��������������*********************************\n" >>$REPORT
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
echo "********************************���TSM�������**********************************\n" >>$REPORT
echo "********************************������IO���***********************************\n" >>$REPORT
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
         print \\n "û�з����ȵ���ʹ��" >>$REPORT
      fi
   else
      print \\n "No iostat file found" >>$REPORT
   fi
echo "********************************�����־���**************************************\n" >>$REPORT
errpt | head -10 >>$REPORT
day=`date +%D |awk -F "/" '{print $1$2}'`
errpt | awk '{print $2}' | grep ^$day
if [ $? -eq 0 ]
then
    echo "LOG-Warnning: `date +%Y'-'%m'-'%d' '%H':'%M':'%S`,The system has found a error today.Please check the error report." >>$REPORT
else
     echo "����ϵͳû�б�����־,ϵͳ��������!!\n" >>$REPORT
fi

echo "********************************���HACMP�����װ���****************************\n" >>$REPORT
lslpp -L|grep cluster >>$REPORT                                                        
if [ $? -eq 0 ]                                                                        
then                                                                                   
echo "ϵͳ��װ��HACMP�������ע�������HA״̬���" >> $REPORT                          
else                                                                                   
echo "ϵͳû�а�װHACMP���" >> $REPORT                                                
fi                                                                                     
                                                                                       
echo "********************************���HACMP�����������****************************\n" >>$REPORT
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
echo "������δ��װHACMP���\n" >>$REPORT
fi

#======================��ʼ�Լ���¼���д���===================
if [ -e /tmp/report1.txt ]
then
rm /tmp/report1.txt
fi
cat /tmp/report.txt | while read line
do
echo $line\<\/br\> >> /tmp/report1.txt
done
