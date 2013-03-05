#!/usr/bin/perl
use English;
#check HA
#
#

my @output_1 = "";
my @output_2 = "";
my $os = $^O;
if($os =~ /aix/)
{
   @output_1 = `lssrc -g cluster|grep clinfoES`;
   if(@output_1 < 1)
     {
        print "异常\n";
        print "未配置HA或者HA进程异常\n";
        exit;
     }
   else
     {
        @output_2 = ` /usr/sbin/cluster/clstat -o|grep  State|grep -v UP|grep -v STABLE|grep -v \"On line\"|grep -v grep`;
        if(@output_2 = 0)
        {
              print "正常\n";
              print "HA状态正常\n";
              exit;
        }
        else
        {
              print "异常\n";
              print "HA状态异常\n";
              exit;
        }
     }
}

elsif($os =~ /hpux/)
{
   @output_1 = `cmviewcl`;
   if(@output_1 < 1)
     {
        print "异常\n";
        print "未配置MC或者MC进程异常\n";
        exit;
     }
   else
     {
        @output_2 = `cmviewcl |grep -i -e DOWN -e halt -e unknow|grep -v grep`;
        if(@output_2 = 0)
        {
              print "正常\n";
              print "HA状态正常\n";
              exit;
        }
        else
        {
              print "异常\n";
              print "HA状态异常\n";
              exit;
        }
     }
}

elsif($os =~ /linux/ )
{
   my ($ha_status,$ha_service_status);
   my $ha_release=`rpm -qa|grep ^ha-`;

   if ($ha_release=~/ha-/){
	$ha_status=`/etc/init.d/hadaemons status`;
		if ($ha_status=~/.*stopped./){
			print "HAdaemons stopped.\n";
		}else{
			$ha_service_status=`/opt/ha/bin/hastat -a`;
			if ($ha_service_status=~/.*\s+started/){
				print "HA services started.\n";
			}else{
				print "HA services stopped.\n"
			}
		}
   }else{
		print "未配置HA\n";
   }   
}
