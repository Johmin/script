#!/usr/bin/perl -w
# This is a Perl program For auto health checking,and output HTML Format.
#Platform: Only SuSE Linux(Current) for ICBC
#Powered by: jsz
#Version: 1.0.0
#Last modify: 2012-03-31

use strict;
use warnings;
use Net::FTP;

#define output and ftp server info
#set output format,if value is yes, output html file to /tmp dir, if value is no, output html is screen print.
#default: yes
my $output_html = "yes";

#define dir path of output file.
my $local_dir_path = "/tmp";

#Is enable use ftp server,default: yes
my $enable_ftp = "yes";
my $ftp_host = "10.235.66.171";
my $ftp_user = "sm01";
my $ftp_pass = "sm01";
my $ftps_work_dir = "/file/liuxinlu/201112";



#set system PATH env
$ENV{'PATH'} = "/sbin:/usr/sbin:/usr/local/sbin:/opt/gnome/sbin:/root/bin:/usr/local/bin:/usr/bin:/usr/X11R6/bin:/bin:/usr/games:/opt/gnome/bin:/opt/kde3/bin:/usr/lib/mit/bin:/usr/lib/mit/sbin$ENV{'PATH'}";
$ENV{'LC_CTYPE'} = "zh_CN.UTF-8";

my %log;
my (@df, @host_messages, @proc);
my ($host_name, $host_top, $host_disk, $host_vmstat, $host_last, $host_free, $host_chconfig, $host_messages, $host_boot_msg);
my %hash;
my $status_normal = "正常";

$host_boot_msg = `grep -i -e warning -e error /var/log/boot.msg`;
if(!$host_boot_msg){
  $host_boot_msg = $status_normal;
}
`tail -n 5000 /var/log/messages |grep -i -E "emerg|alert|crit|err|warning|Unexpected" |grep -v -i newscrit > /tmp/messages`;

#check system messages
open FD, "/tmp/messages" or die "can not open this file $!";
while (<FD>) {
  my($field_1, $field_2) = split /: /;
  push @{ $log{$field_2} }, $field_1;
}

#processes
my @ps = `ps aux |grep -v ps |awk 'BEGIN { print "%CPU %MEM %STAT PID COMMAND" } { if (\$3 > 25 || \$4 > 25 || \$8~/Z/ && \$8!~/Z</) print \$3, \$4, \$8, \$2, \$11}' |sort`;
#my @ps = `ps aux |awk 'BEGIN { print "%CPU %MEM %STAT PID COMMAND" } { if (\$3 > 25 || \$4 > 25 || \$8~/Z/ && \$8!~/Z</) print \$3, \$4, \$8, \$2, \$11}' |sort`;
foreach my $ps(@ps){
  if($ps =~ /\d+/){
    push @proc, $ps;
  } else{
    @proc = $status_normal;
  }
}

#system last check
$host_last = `last|grep -i logout`;
if(!$host_last){
  $host_last=$status_normal;
}

#check memory info
my ($swapf, $swapt);
open MEM, "/proc/meminfo" or die "can not open this file $!";
foreach my $meminfo(<MEM>){
  if($meminfo =~ /SwapTotal:\s+(\d+)/){
    $swapt = $1;
  } elsif($meminfo =~ /SwapFree:\s+(\d+)/){
    $swapf = $1;
  }
}
if(($swapf/$swapt) < 0.7){
  $host_free = `free -m`;
} else{
  $host_free = $status_normal;
}

#check disk quota
my (@host_df, @disk);
@host_df = `df`;
foreach my $host_df(@host_df){
  if($host_df =~ /(\d+)\%/){
    my $host_dk = $1;
    if($host_dk > 80){
      push @disk, $host_df;
    }
  }
}
if(!@disk){
  @disk = $status_normal;
}

#check mount and /etc/fstab
my @mnt;
my @host_mnt = `cat /etc/fstab |grep -v "swap"|grep -v "usb"|grep -v "sysfs"|grep -v "floppy"`;
foreach my $mnt(@host_mnt){
  if($mnt =~ /[^\/\w+?|^\w+?]\s+(.*?)\s+/){
    my $j = $1;
    my $i = `mount |grep $j`;
    if(!$i){
      push @mnt, $mnt;
    }
  }
}
if(!@mnt){
  @mnt = $status_normal;
}

#check NTP time sysnc
#my $host_time = `date`;
my $host_time;
my $time_sync = `ntpq -p|grep \^\*|awk '{print \$1,\$9,\$10}' 2>&1`;

if(!$time_sync){
	$host_time = "不适用";
} else{
	$host_time = $status_normal;
}



#check hosts and profile files
my $host_hosts = `ls -al --time-style=long-iso /etc/hosts`;
if($host_hosts =~ /(\d+-\d+-\d+)/){
  $host_hosts = $1;
}
my $host_profile = `ls -al --time-style=long-iso /etc/profile`;
if($host_profile =~ /(\d+-\d+-\d+)/){
  $host_profile = $1;
}
my $host_grubfile = `ls -al --time-style=long-iso /boot/grub/menu.lst`;
if($host_grubfile =~ /(\d+-\d+-\d+)/){
  $host_grubfile = $1;
}
my $host_fstab = `ls -al --time-style=long-iso /etc/fstab`;
if($host_fstab =~ /(\d+-\d+-\d+)/){
  $host_fstab = $1;
}

#check service xinetd and xntpd
my $host_service_xinetd = `chkconfig -l  xinetd 2>&1`;
chomp $host_service_xinetd;
my $host_service_xntpd = `chkconfig -l  xntpd 2>&1`;
chomp $host_service_xntpd;
my $host_service_ntp = `chkconfig -l  ntp 2>&1`;
chomp $host_service_ntp;

#check server uptime
my $host_uptime;
my $host_uptimes = `uptime`;
if($host_uptimes =~ /up\s+?(\d+?\s+?day)/){
  $host_uptime = $1;
} else {
  $host_uptime = "today";
}


#check file system
my @dumpe2fs_dev;
my @host_fstab = `cat /etc/fstab`;
#print @host_fstab;
foreach (@host_fstab){
  if(/(\/dev\/.*?)\s+(.*?)\s+ext3/){
    my $check_dev = "$1\t\t" . `dumpe2fs $1 |grep -i "last checked" 2>&1`;
    push @dumpe2fs_dev, $check_dev;

  }

}
if(!@dumpe2fs_dev){
  @dumpe2fs_dev = $status_normal;
}


#check system log file size
my @host_log_size;
my @host_log_files = `ls -lh --time-style "+\%s" /var/log`;
foreach (@host_log_files){
  if(/(\d+?\.\d+?)G\s+\d+(.*)?/){
    if($1 >= 2){
	  my $log_file = "$2 is $1G";
	  push @host_log_size, $log_file;
	}
  }
}
if(!@host_log_size){
 @host_log_size = $status_normal;
}


#check network status
my (@ncard_status, @bond0, @bond1);
#my @bond0 = `cat /proc/net/bonding/bond0 |grep Slave|awk -F ":" '{print $2}' 2>&1`;
#my @bond1 = `cat /proc/net/bonding/bond1 |grep Slave|awk -F ":" '{print $2}' 2>&1`;
my $bond0 = "/proc/net/bonding/bond0";
my $bond1 = "/proc/net/bonding/bond1";
if(-e $bond0){
	@bond0 = `cat $bond0 |tail 2>&1`;
} else{
	@bond0="不适用";
}
if(-e $bond1){
	@bond1 = `cat $bond1 |tail 2>&1`;
} else{
	@bond1="不适用";
}
#my @bond0 = `cat /proc/net/bonding/bond0 |tail 2>&1`;
#my @bond1 = `cat /proc/net/bonding/bond1 |tail 2>&1`;
my @network_card = `cat /proc/net/dev |grep eth |cut -d\: -f1 |sed -e 's\/\^\[ \]\*\/\/g' 2>&1`;

foreach my $network_card(@network_card){
	chomp $network_card;
	#print "$network_card\n";
	my $netcard_stat = `ethtool $network_card |grep "Link detected" |awk '{print \$3}' 2>&1`;
	$netcard_stat = "$network_card : $netcard_stat";
	push @ncard_status, $netcard_stat;
	
	
}



# #check skybility HA and Cluster
# my %ha_log;
# my ($ha, $ha_heartbeat, $ha_v, $ha_hainterface_v);
# my (@hastatus, @ha_srv_status, @ha_rpmv, @ha_interface, @ha_log);
# my $skybility_ha = `rpm -q ha`;
# if($skybility_ha =~ /not installed/){
  # @ha_rpmv = "Package is not installed";
  # #%ha_log = "";
  # @hastatus = "";
# } else{
  # @ha_rpmv = `rpm -V ha`;
  # if(!@ha_rpmv){
    # @ha_rpmv = $status_normal;
  # }

  # @ha_interface = `rpm -V hainterface`;
  # if(!@ha_interface){
    # @ha_interface = $status_normal;
  # }


  # @hastatus = `/opt/ha/bin/hastat -a`;
  # #foreach my $hastatus(@hastatus){
  # #  if($hastatus =~ /\<--\>/){
  # #    $ha_heartbeat = $hastatus;
  # #  } elsif($hastatus =~ /(stopped|started)/){
  # #    push @ha_srv_status, $hastatus;
  # #  }
  # #}
  
  # #@ha_log = `grep -e error /var/log/ha|tail -n 20`;
  # `tail -n 2000 /var/log/ha |grep -i -e err -e warn > /tmp/ha_log`;
  # open FD, "/tmp/ha_log" or die "can not open this file $!";
  # while (<FD>) {
    # my($field_1, $field_2) = split /: \</;
    # push @{ $ha_log{$field_2} }, $field_1;
  # }
  
  # if(!%ha_log){
    # %ha_log = $status_normal;
  # }
# }





# my %cluster_log;
# my ($cluster, $cluster_v, $cluster_lbinterface_v);
# my (@cluster_status, @cluster_rpmv, @cluster_lbinterface, @cluster_log);
# my $skybility_cluster = `rpm -q cluster`;
# if($skybility_cluster =~ /not installed/){
  # @cluster_rpmv = "Package is not installed";
  # #%cluster_log = "";
  # @cluster_status = "";
# } else{
  # @cluster_rpmv = `rpm -V cluster`;
  # if(!@cluster_rpmv){
    # @cluster_rpmv = $status_normal;
  # }

  # @cluster_lbinterface = `rpm -V hainterface`;
  # if(!@cluster_lbinterface){
    # @cluster_lbinterface = $status_normal;
  # }


  # @cluster_status = `ipvsadm -Ln`;
  # `tail -n 2000 /var/log/cluster |grep -i -e err -e warn > /tmp/cluster_log`;
  # open FD, "/tmp/cluster_log" or die "can not open this file $!";
  # while (<FD>) {
    # my($field_1, $field_2) = split /: \</;
    # push @{ $cluster_log{$field_2} }, $field_1;
  # }
  
  # if(!%cluster_log){
    # %cluster_log = $status_normal;
  # }
# }


#print hostname and ipaddress
my @host_ip=`ifconfig |grep "inet addr"|grep -v 127|awk -F: '{print \$2}'|awk '{print \$1}' 2>&1`;
my $hosts_name = `hostname 2>&1`;
chomp $hosts_name;
# foreach my $host_ip(@host_ip){
  # chomp $host_ip;
  # print "$host_ip ";

# }




# if rpm -q cluster
# then 
  # output "$HAINFO" 'rpm -V cluster'
  # output "$HAINFO" 'rpm -V lbinterface'
# fi


#Define output contents in here
my $HOST_NAME = `hostname`;
chomp $HOST_NAME;
my $HOST_NAME_FILE=$HOST_NAME.".html";
#warn "$HOST_NAME_FILE\n";
#warn "$HOST_NAME";

if($output_html eq "yes"){
	open(STDOUT, ">$local_dir_path/$HOST_NAME.html");
	&report_html;
	close(STDOUT);
} else {
	&report_html;
}


sub report_html(){
	print "<html>\n";
	print "<head>\n";
	print "<title>Suse系统信息表</title>\n";
	print "<meta http-equiv=\"Content-Type\" content=\"text/html\; charset=UTF-8\">\n";
	print "</head>\n";
	print "";
	print "<body bgcolor=\"#FFFFFF\" text=\"#000000\">\n";
	print "<div align=\"center\">主机名称：<U>$hosts_name</U>";
	print "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;";
	print "主机IP地址：<U>";
	foreach my $host_ip(@host_ip){
		chomp $host_ip;
		print "$host_ip ";
	}
	print "</U>";
	print "</div>";
	print "\<div align=\"center\"\>\n";
	print "  \<table width=\"100\%\" border=\"3\" bordercolor=\"\#666666\" cellspacing=\"0\" align=\"center\" height=\"812\"\>\n";
	print "    \<tr\> \n";
	print "      \<td width=\"12\%\"\> \n";
	print "        \<div align=\"center\"\>类型\<\/div\>\n";
	print "      \<\/td\>\n";
	print "      \<td width=\"28\%\"\> \n";
	print "        \<div align=\"center\"\>检查项目\<\/div\>\n";
	print "      \<\/td\>\n";
	print "      \<td width=\"20\%\"\> \n";
	print "        \<div align=\"center\"\>检查要求\<\/div\>\n";
	print "      \<\/td\>\n";
	print "      \<td width=\"40\%\"\> \n";
	print "        \<div align=\"center\"\>信息结果\<\/div\>\n";
	print "      \<\/td\>\n";
	print "    \<\/tr\>\n";
	print "    \<tr\> \n";
	print "      \<td rowspan=\"20\"\> \n";
	print "        \<div align=\"center\"\>操作系统\<\/div\>\n";
	print "      \<\/td\>\n";
	print "      \<td width=\"28\%\"\> \n";
	print "        \<div align=\"center\"\>检查引导日志\<\/div\>\n";
	print "      \<\/td\>\n";
	print "      \<td width=\"20\%\"\> \n";
	print "        \<div align=\"center\"\>检查\/var\/log\/boot.msg有无错误信息\<\/div\>\n";
	print "      \<\/td\>\n";
	print "      \<td width=\"20\%\"\> \n";
	print "        \<div align=\"left\"\>$host_boot_msg\<\/div\>\n";
	print "      \<\/td\>\n";
	print "    \<\/tr\>\n";
	print "    \<tr\> \n";
	print "      \<td width=\"28\%\"\> \n";
	print "        \<div align=\"center\"\>检查系统日志\<\/div\>\n";
	print "      \<\/td\>\n";
	print "      \<td width=\"20\%\"\> \n";
	print "        \<div align=\"center\"\>检查\/var\/log\/messages有无错误信息\<\/div\>\n";
	print "      \<\/td\>\n";
	print "      \<td width=\"20\%\"\> \n";
	#print "        \<div align=\"center\"\>$host_messages\<\/div\>\n";
	print "        \<div align=\"left\"\>\n";
	foreach (keys %log) {
	  #print "\<p\>";
	  print shift ( @{ $log{$_} } ).": ".$_."\n\<br\>";
	  #print "\<\/p\>";
	}
	print "\<\/div\>\n";
	print "      \<\/td\>\n";
	print "    \<\/tr\>\n";
	print "    \<tr\> \n";
	print "      \<td width=\"28\%\"\> \n";
	print "        \<div align=\"center\"\>检查进程信息\<\/div\>\n";
	print "      \<\/td\>\n";
	print "      \<td width=\"20\%\"\> \n";
	print "        \<div align=\"center\"\>top检查zombie的值是否为0\<\/div\>\n";
	print "      \<\/td\>\n";
	print "      \<td width=\"20\%\"\> \n";
	print "        \<div align=\"center\"\>@proc\<\/div\>\n";
	print "      \<\/td\>\n";
	print "    \<\/tr\>\n";
	print "    \<tr\> \n";
	print "      \<td width=\"28\%\"\> \n";
	print "        \<div align=\"center\"\>用户登录活动检查\<\/div\>\n";
	print "      \<\/td\>\n";
	print "      \<td width=\"20\%\"\> \n";
	print "        \<div align=\"center\"\>last察看登录记录\<\/div\>\n";
	print "      \<\/td\>\n";
	print "      \<td width=\"20\%\"\> \n";
	print "        \<div align=\"center\"\>$host_last\<\/div\>\n";
	print "      \<\/td\>\n";
	print "    \<\/tr\>\n";
	print "    \<tr\> \n";
	print "      \<td width=\"28\%\"\> \n";
	print "        \<div align=\"center\"\>paging space检查交换区使用情况\<\/div\>\n";
	print "      \<\/td\>\n";
	print "      \<td width=\"20\%\"\> \n";
	print "        \<div align=\"center\"\>free -m\<\/div\>\n";
	print "      \<\/td\>\n";
	print "      \<td width=\"20\%\"\> \n";
	print "        \<div align=\"center\"\>$host_free\<\/div\>\n";
	print "      \<\/td\>\n";
	print "    \<\/tr\>\n";
	print "    \<tr\> \n";
	print "      \<td width=\"28\%\"\> \n";
	print "        \<div align=\"center\"\>检查文件系统空间\<\/div\>\n";
	print "      \<\/td\>\n";
	print "      \<td width=\"20\%\"\> \n";
	print "        \<div align=\"center\"\>原则上保证文件系统的使用率不超过80\%\<\/div\>\n";
	print "      \<\/td\>\n";
	print "      \<td width=\"20\%\"\> \n";
	print "        \<div align=\"center\"\>@disk\<\/div\>\n";
	print "      \<\/td\>\n";
	print "    \<\/tr\>\n";
	print "    \<tr\> \n";
	print "      \<td width=\"28\%\"\> \n";
	print "        \<div align=\"center\"\>检查系统加载的文件系统信息\<\/div\>\n";
	print "      \<\/td\>\n";
	print "      \<td width=\"20\%\"\> \n";
	print "        \<div align=\"center\"\>mount结果与\/etc\/fstab比较\<\/div\>\n";
	print "      \<\/td\>\n";
	print "      \<td width=\"20\%\"\> \n";
	print "        \<div align=\"center\"\>@mnt\<\/div\>\n";
	print "      \<\/td\>\n";
	print "    \<\/tr\>\n";
	print "    \<tr\> \n";
	print "      \<td width=\"28\%\"\> \n";
	print "        \<div align=\"center\"\>时间同步\<\/div\>\n";
	print "      \<\/td\>\n";
	print "      \<td width=\"20\%\"\> \n";
	print "        \<div align=\"center\"\>检查时钟同步是否正常\<\/div\>\n";
	print "      \<\/td\>\n";
	print "      \<td width=\"20\%\"\> \n";
	print "        \<div align=\"center\"\>$host_time\<\/div\>\n";
	print "      \<\/td\>\n";
	print "    \<\/tr\>\n";
	print "    \<tr\> \n";
	print "      \<td width=\"28\%\"\> \n";
	print "        \<div align=\"center\"\>\/etc\/hosts是否有变更\<\/div\>\n";
	print "      \<\/td\>\n";
	print "      \<td width=\"20\%\"\> \n";
	print "        \<div align=\"center\"\>查看该系统文件更改日期\<\/div\>\n";
	print "      \<\/td\>\n";
	print "      \<td width=\"20\%\"\> \n";
	print "        \<div align=\"center\"\>$host_hosts\<\/div\>\n";
	print "      \<\/td\>\n";
	print "    \<\/tr\>\n";
	print "    \<tr\> \n";
	print "      \<td width=\"28\%\"\> \n";
	print "        \<div align=\"center\"\>\/etc\/profile是否有变更\<\/div\>\n";
	print "      \<\/td\>\n";
	print "      \<td width=\"20\%\"\> \n";
	print "        \<div align=\"center\"\>查看该系统文件更改日期\<\/div\>\n";
	print "      \<\/td\>\n";
	print "      \<td width=\"20\%\"\> \n";
	print "        \<div align=\"center\"\>$host_profile\<\/div\>\n";
	print "      \<\/td\>\n";
	print "    \<\/tr\>\n";
	print "    \<tr\> \n";
	print "      \<td width=\"28\%\"\> \n";
	print "        \<div align=\"center\"\>\/boot\/grub\/menu.lst是否有变更\<\/div\>\n";
	print "      \<\/td\>\n";
	print "      \<td width=\"20\%\"\> \n";
	print "        \<div align=\"center\"\>查看该系统文件更改日期\<\/div\>\n";
	print "      \<\/td\>\n";
	print "      \<td width=\"20\%\"\> \n";
	print "        \<div align=\"center\"\>$host_grubfile\<\/div\>\n";
	print "      \<\/td\>\n";
	print "    \<\/tr\>\n";
	print "    \<tr\> \n";
	print "      \<td width=\"28\%\"\> \n";
	print "        \<div align=\"center\"\>\/etc\/fstab是否有变更\<\/div\>\n";
	print "      \<\/td\>\n";
	print "      \<td width=\"20\%\"\> \n";
	print "        \<div align=\"center\"\>查看该系统文件更改日期\<\/div\>\n";
	print "      \<\/td\>\n";
	print "      \<td width=\"20\%\"\> \n";
	print "        \<div align=\"center\"\>$host_fstab\<\/div\>\n";
	print "      \<\/td\>\n";
	print "    \<\/tr\>\n";
	print "    \<tr\> \n";
	print "      \<td width=\"28\%\"\> \n";
	print "        \<div align=\"center\"\>检查系统启动服务\<\/div\>\n";
	print "      \<\/td\>\n";
	print "      \<td width=\"20\%\"\> \n";
	print "        \<div align=\"center\"\> \n";
	print "          chkconfig -l|grep xinetd\<br\>\n";
	print "          chkconfig -l|grep xntpd\<br\>\n";
	print "        \<\/div\>\n";
	print "      \<\/td\>\n";
	print "      \<td width=\"20\%\"\> \n";
	print "        \<div align=\"center\">$host_service_xinetd<br>$host_service_xntpd<br>$host_service_ntp</div>\n";
	print "      \<\/td\>\n";
	print "    \<\/tr\>\n";
	print "    \<tr\> \n";
	print "      \<td width=\"28\%\"\> \n";
	print "        \<div align=\"center\"\>系统运行天数\<\/div\>\n";
	print "      \<\/td\>\n";
	print "      \<td width=\"20\%\"\> \n";
	print "        \<div align=\"center\"\>uptime\<\/div\>\n";
	print "      \<\/td\>\n";
	print "      \<td width=\"20\%\"\> \n";
	print "        \<div align=\"center\"\>$host_uptime\<\/div\>\n";
	print "      \<\/td\>\n";
	print "    \<\/tr\>\n";
	print "    \<tr\> \n";
	print "      \<td width=\"28\%\"\> \n";
	print "        \<div align=\"center\"\>文件系统是否需要fsck\<\/div\>\n";
	print "      \<\/td\>\n";
	print "      \<td width=\"20\%\"\> \n";
	print "        \<div align=\"center\"\>dumpe2fs \/dev\/sda*|grep Last checked\<\/div\>\n";
	print "      \<\/td\>\n";
	print "      \<td width=\"20\%\"\> \n";
	print "        \<div align=\"center\"\>\n";
	foreach(@dumpe2fs_dev){
	  print "$_\<br\>\n";
	}
	print "        \<\/div\>\n";
	print "      \<\/td\>\n";
	print "    \<\/tr\>\n";

	print "	  <tr>\n";
	print "	  <td width=\"28\%\" rowspan=\"3\">\n";
	print "	  <div align=\"center\">系统网络状态</div>\n";
	print "   </td>\n";
	print "	  <td width=\"20\%\">\n";
	print "	  <div align=\"center\">bond0</div>\n";
	print "   </td>\n";
	print "   <td width=\"20\%\">\n";
	print "	  <div align=\"center\">\n";
	if(!@bond1){
		print "不适用";
	} else{
		print "$_<br>\n" foreach @bond0;
	}
	print "	  </div>\n";
	print "   </td>\n";
	print "	  </tr>\n";
	print "	  <tr>\n";
	print "	  <td width=\"20\%\">\n";
	print "	  <div align=\"center\">bond1</div>\n";
	print "   </td>\n";
	print "   <td width=\"20\%\">\n";
	print "	  <div align=\"center\">\n";
	if(!@bond1){
		print "不适用";
	} else{
		print "$_<br>\n" foreach @bond1;
	}
	print "	  </div>\n";
	print "	  </td>\n";
	print "	  </tr>\n";
	print "	  <td width=\"20\%\">\n";
	print "	  <div align=\"center\">Ethtool 检查网卡物理状态</div>\n";
	print "   </td>\n";
	print "   <td width=\"20\%\">\n";
	print "	  <div align=\"center\">\n";
	print "$_<br>\n" foreach @ncard_status;
	print "	  </div>\n";
	print "   </td>\n";

	print "    \<tr\> \n";
	print "      \<td width=\"28\%\"\> \n";
	print "        \<div align=\"center\"\>操作系统版本\<\/div\>\n";
	print "      \<\/td\>\n";
	print "      \<td width=\"20\%\"\> \n";
	print "        \<div align=\"center\"\>cat \/etc\/SuSE-release\<\/div\>\n";
	print "      \<\/td\>\n";
	print "      \<td width=\"20\%\"\> \n";
	print "        \<div align=\"center\"\>\n";
	system 'cat /etc/SuSE-release';
	print "        \<\/div\>\n";
	print "      \<\/td\>\n";
	print "    \<\/tr\>\n";
	print "    \<tr\> \n";
	print "      \<td width=\"28\%\"\> \n";
	print "        \<div align=\"center\"\>检查大于2G日志文件\<\/div\>\n";
	print "      \<\/td\>\n";
	print "      \<td width=\"20\%\"\> \n";
	print "        \<div align=\"center\"\>ls -lh \/var\/log\/* -R\<\/div\>\n";
	print "      \<\/td\>\n";
	print "      \<td width=\"20\%\"\> \n";
	print "        \<div align=\"center\"\>\n";
	foreach(@host_log_size){
	  print "$_\<br\>\n";
	}
	print "        \<\/div\>\n";
	print "      \<\/td\>\n";
	print "    \<\/tr\>\n";

	print "  \<\/table\>\n";
	print "\<\/div\>\n";
	my $tm = localtime;
	print "<div align=\"right\">$tm</div>\n";
	print "</body>\n";
	print "</html>\n";
	print "\n\n\n\n";
}


if($enable_ftp eq "yes"){
	#Change work directory
	#use constant DIR => '/file/liuxinlu/201112';

	#Connect to FTP Host
	#Connect and put checking file
	my $ftp = Net::FTP->new("$ftp_host"); #or die "Conldn't connect: $@\n";
	$ftp->login("$ftp_user","$ftp_pass"); # or die $ftp->message;
	$ftp->cwd("$ftps_work_dir"); #or die $ftp->message;
	$ftp->put("$local_dir_path/$HOST_NAME_FILE"); #or die $ftp->message;
	$ftp->quit;
}
