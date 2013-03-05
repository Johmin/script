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
        print "�쳣\n";
        print "δ����HA����HA�����쳣\n";
        exit;
     }
   else
     {
        @output_2 = ` /usr/sbin/cluster/clstat -o|grep  State|grep -v UP|grep -v STABLE|grep -v \"On line\"|grep -v grep`;
        if(@output_2 = 0)
        {
              print "����\n";
              print "HA״̬����\n";
              exit;
        }
        else
        {
              print "�쳣\n";
              print "HA״̬�쳣\n";
              exit;
        }
     }
}

elsif($os =~ /hpux/)
{
   @output_1 = `cmviewcl`;
   if(@output_1 < 1)
     {
        print "�쳣\n";
        print "δ����MC����MC�����쳣\n";
        exit;
     }
   else
     {
        @output_2 = `cmviewcl |grep -i -e DOWN -e halt -e unknow|grep -v grep`;
        if(@output_2 = 0)
        {
              print "����\n";
              print "HA״̬����\n";
              exit;
        }
        else
        {
              print "�쳣\n";
              print "HA״̬�쳣\n";
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
		print "δ����HA\n";
   }   
}
