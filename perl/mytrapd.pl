use NetSNMP::TrapReceiver;
use Socket;
use IO::Socket;



#������������Ӧ����Ҫ����ı������飬��ͬ�ı������Դ���ͬ���飬Ҳ��������ͬ��
#��һ���ֶΣ�snmp OID������snmp OID���ƣ����������е���ʾ����
#�����ֶ�: �Ƿ�Ҫ��Ϊ���������ֶ�
our @var01 = (
['.1.3.6.1.4.1.3375.2.4.1.1' , 'bigipNotifyObjMsg',  ,'MSG','N'],
['.1.3.6.1.4.1.3375.2.4.1.2' , 'bigipNotifyObjNode',  ,'NODE','Y'],
['.1.3.6.1.4.1.3375.2.4.1.3' , 'bigipNotifyObjPort',  ,'PORT','Y'],
);

#���屨�����ͺ͹�����hash
# hash key Ϊ��������snmp OID
# hash valueΪ st:�Ƿ񱨾� id:�������ͱ�� lv:�������� nm: snmp OID����Ӧ������
# nt: ������ϸ������Ϣ var: ��������Ҫ����Щsnmp����Ϣ����һͬ����ȥ����Ӧһ�����飬��ͬ�ı������Դ���ͬ���� 
our %hk = (   
'.1.3.6.1.4.1.3375.2.4.0.10' => {'st' => 'ON','id'  => '3001','lv' =>  '0005','nm' => 'bigipServiceDown','nt' => 'POOL Memberֹͣ','var' => \@var01 },
'.1.3.6.1.4.1.3375.2.4.0.11' => {'st' => 'OFF','id'  => '3002','lv' =>  '0001','nm' => 'bigipServiceUp','nt' => 'POOL Member����','var' => \@var01}   
);  

our $systemtype = "���ؾ�����";
our $warnip = "10.237.128.171";


sub my_receiver {
      print "********** PERL RECEIVED A NOTIFICATION:\n";

     my ($sec,$min,$hour,$mday,$mon,$year)=localtime(time);

     my $report_ts = sprintf("%4d%02d%02d^%02d%02d%02d", $year+1900, $mon + 1, $mday, $hour, $min, $sec);

     # print the PDU info (a hash reference)
#      print "PDU INFO:\n";
       my $receivedfrom;
       foreach my $k(keys(%{$_[0]})) {
       if ($k eq "securityEngineID" || $k eq "contextEngineID") {
           printf "  %-30s 0x%s\n", $k, unpack('h*', $_[0]{$k});
       }
       else {
         if($k eq "receivedfrom")
         {
             $receivedfrom = $_[0]{$k};
         }
         printf  "  %-30s %s\n", $k, $_[0]{$k};
       }
     }

     my $hostname;

     if($receivedfrom =~ /UDP:\s+\[(.*?)\]:/)
     {
         if($hostname = gethostbyaddr(inet_aton($1),AF_INET))
         {
#               print "HOSTNAME::".$hostname."\n";

         }
         else
         {
#               print "HOSTIP::".$1."\n";
               $hostname  = $1;
         }
     }

     my $logfilename = "/home/sm01/snmp/log/".$hostname.sprintf("%4d%02d%02d",$year+1900, $mon +1, $mday).".log";
     print $logfilename."\n";
     open(FD,">>$logfilename")||die("Can not open the file!\n");
     print FD "-----------------------------------------------\n";
     print FD $report_ts."\n";
     my $detilmsg;
     my $key;
     foreach my $x (@{$_[1]})
     {
        printf FD "  %-30s type=%-2d value=%s\n", $x->[0], $x->[2], $x->[1];
        $detilmsg = $detilmsg.sprintf("%-30s type=%-2d value=%s,", $x->[0], $x->[2], $x->[1]);
         if(($x->[0] =~ /snmpTrapOID/)|| ($x->[0] =~ /.1.3.6.1.6.3.1.1.4.1.0/))
         {
              if($x->[1] =~ /OID:\s+(.*?)$/)
              {
                   $key = $1;
                   #last;
              }
         }
     }

     my $st,$id,$lv,$nm,$nt,$vr;
     my $msg;
     if(exists $hk{$key})
     {
         $st = $hk{$key}{'st'};
         $id = $hk{$key}{'id'};
         $lv = $hk{$key}{'lv'};
         $nm = $hk{$key}{'nm'};
         $nt = $hk{$key}{'nt'};
         $vr = $hk{$key}{'var'};
     }
     else
     {
         $st = "ON";
         $id = "9999";
         $lv = "0001";
         $nm = "Not Define";
         $nt = "Not Define";
         $vr = NULL;
     }


     if($st eq "OFF")
     {
         close(FD);
         return;
     }
     my $servername = "";
     $msg = $systemtype.":".$hostname."����".$nt.",��ϸ��Ϣ:KEY=".$nm.",";

     if($vr != NULL)
     {
          foreach my $y (@$vr)
          {
               foreach my $x (@{$_[1]})
               {
                   if(($x->[0] =~ /$y->[0]/) || ($x->[0] =~ /$y->[1]/))
                   {
                        if($x->[1] =~ /:\s+?\"(.*?)\"$/)
                        {
                             my $tmp = $y->[2]."=".$1.",";
                             $msg = $msg.$tmp;
                             #print $msg."\n";
                             if($y->[3] eq "Y")
                             {
                                 $servername = $servername.$tmp;
                             }
                        }
                        last;
                   }
              }

          }
     }
     else
     {

         foreach my $x (@{$_[1]})
         {
             if(($x->[0] =~ /bigipNotifyObjMsg/) || ($x->[0] =~ /.1.3.6.1.4.1.3375.2.4.1.1/))
             {
                  if($x->[1] =~ /STRING:\s+?\"(.*?)\"$/)
                  {
                       $msg = $msg."MSG=".$1.",";
                  }
             }
             if(($x->[0] =~ /bigipNotifyObjNode/) || ($x->[0] =~ /.1.3.6.1.4.1.3375.2.4.1.2/))
             {
                  if($x->[1] =~ /STRING:\s+?\"(.*?)\"$/)
                  {
                       $msg = $msg."NODE=".$1.",";
                       $servername = $servername.$1.":";
                  }
             }
             if($x->[0] =~ /.1.3.6.1.4.1.3375.2.4.1.3/)
             {
                  if($x->[1] =~ /STRING:\s+?\"(.*?)\"$/)
                  {
                       $msg = $msg."PORT=".$1.",";
                       $servername = $servername.$1;
                  }
             }
         #printf "  %-30s type=%-2d value=%s\n", $x->[0], $x->[2], $x->[1];
         }
    }
         if(length($servername) <= 0)
         {
              $servername = $hostname;
         }
         $msg = "CUSTOM^99^$report_ts^^$hostname^$servername^^OPENIMIS^^$id^$lv^^$msg^$detilmsg^^^^";
#CUSTOM^��������^��������(8λ)^����ʱ��(6λ)^��ˮ��^HostID(������32������ַ�)^S erverID(������100������ַ�)^������Ŀ(������80������ַ�)^����Դ(������9�����,> ��BMC,MYAME,SCOM,OPMS��)^����ֵ^�������ͱ��(4λ����)^��������(4λ,��0001)^����> ����˵��(������32������ַ�,��һ�㱨��!)^��������(������640������ַ�)^������ϸ> ��Ϣ^�������ͣ���ѯ�ã�����գ�^����ID����ѯ�ã�����գ�^����˵������ѯ�ã�����> �գ�
          #my $msgx = sprintf("%09d%s",length($msg),$msg);
          print FD $msg."\n";
          my $s = IO::Socket::INET->new(PeerPort =>'31820',
                       Proto =>'udp',
                       PeerAddr =>$warnip) || die "socket error!\n";

          print $msg."\n";
         # $s->send("$msg");

         close $s;
         close FD;
}
  NetSNMP::TrapReceiver::register("all", \&my_receiver) || 
    warn "failed to register our perl trap handler\n";

  print STDERR "Loaded the example perl snmptrapd handler\n";
