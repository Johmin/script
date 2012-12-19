#!/usr/bin/perl -w
#
#Auth: Jsz
#Time: 2012-03-31
#Version: 1.0.5

use warnings;
use strict;

#self defined EVN
$ENV{'PATH'} = "/sbin:/usr/sbin:/usr/local/sbin:/opt/gnome/sbin:/root/bin:/usr/local/bin:/usr/bin:/usr/X11R6/bin:/bin:/usr/games:/opt/gnome/bin:/opt/kde3/bin:/usr/lib/mit/bin:/usr/lib/mit/sbin$ENV{'PATH'}";
my $resul_normal = "Yes";
my $resul_none = "No";
my (undef,$min,$hour,$mday,$mon,$year)=localtime(time);
my $report_ts = sprintf("%2d.%2d.%4d %02d:%02d", $mday, $mon, $year+1900, $hour, $min);

#system info
my ($sys_version, $resolv_status, $resolv_conf, $msg_perm, $abc_log, $abc_log_perm, );
my ($ssh_timeout, $ssh_tmo_status);
my ($ntp_status, $ntp_server_info);
my ($bonding, $bonding_info);
my ($user_info, $hosts_deny);

sub sysinfo{
    #my ($sys_version, $bonding, $bonding_info, $ntp_info, $resolv_conf, $ssh_timeout, $msg_perm, $abc_log, $abc_log_perm, );
    #my (@user_info, @host_deny, @crontab_info);
    
    $sys_version = `cat /etc/SuSE-release`;
    chomp $sys_version;
    my $bond = "/proc/net/bonding";
    if(-d $bond){
        $bonding = $resul_normal;
        $bonding_info = `grep eth /proc/net/bonding/bond* 2>&1`;
    } else {
        $bonding = $resul_none;
        $bonding_info = $resul_none;
    }
    
    my $ntp_service_status = "/var/run/ntp/ntpd.pid";
    if(-f $ntp_service_status){
        $ntp_status = $resul_normal;
        $ntp_server_info = `ntpq -p|grep [0-9]$|grep "10.23"|awk '{print \$1}' 2>&1`;
        chomp $ntp_server_info;
        #$ntp_server_info = 
    }else{
        $ntp_status = $resul_none;
	$ntp_server_info = $resul_none;
    }
    
    my $resolv_conf_file = `cat /etc/resolv.conf|grep -v ^#  |grep -v ^\$ 2>&1`;
    if(!$resolv_conf_file){
        $resolv_status = $resul_normal;
        $resolv_conf = $resul_normal;
    }else {
        $resolv_status = $resul_none;
        $resolv_conf = $resul_none;
    }
    $ssh_timeout = `cat /etc/profile |grep -v ^#|grep "TMOUT" 2>&1`;
    chomp $ssh_timeout;
    if($ssh_timeout){
        $ssh_tmo_status = $resul_normal;
        $ssh_timeout = $resul_normal;
    }else{
        $ssh_tmo_status = $resul_none;
        $ssh_timeout = $resul_none;
    }
    $msg_perm = `ls -l /var/log/messages|awk '{print \$1}' 2>&1`;
	chomp $msg_perm;
    $abc_log = "/var/log/abcsys.log";
    if(-f $abc_log){
        $abc_log = $resul_normal;
        $abc_log_perm = `ls -l /var/log/abcsys.log|awk '{print \$1}' 2>&1`;
		chomp $abc_log_perm;
    }else{
	    $abc_log = $resul_none;
	    $abc_log_perm = $resul_none;
	}
    
	$hosts_deny = $resul_none;
    open HDENY, "/etc/hosts.deny" or die "can not open $! file";
    foreach my $host_deny(<HDENY>){
        if($host_deny =~ /^sshd:\s+ALL/){
            $hosts_deny = $resul_normal;
			last;
        }
		
    }
    close HDENY;
    
    #check user for sm01/sm02
    my @users = `cat /etc/passwd|grep -E "sm01|sm02" 2>&1`;
	my $user_cnt = @users;
	if($user_cnt ne 2){
	    $user_info = $resul_none;
	
	}else{
	    $user_info = $resul_normal;
	}
    
    
    &init_html_table;
    print HTML <<EOT
    <tr><td>OS</td><td>Linux</td><td>$sys_version</td>
          <td></td></tr>
    <tr><td>Bonding</td><td>$bonding</td><td>$bonding_info</td>
          <td></td></tr>
    <tr><td>NTP Status</td><td>$ntp_status</td><td>$ntp_server_info</td>
          <td></td></tr>
    <tr><td>Name Resolv</td><td>$resolv_status</td><td>$resolv_conf</td>
          <td></td></tr>
    <tr><td>SSH Login TMOUT</td><td>$ssh_tmo_status</td><td>$ssh_timeout</td>
          <td></td></tr>
	<tr><td>Messages Perm</td><td></td><td>$msg_perm</td>
          <td></td></tr>
	<tr><td>abcsys.log Perm</td><td>$abc_log</td><td>$abc_log_perm</td>
          <td></td></tr>
	<tr><td>SSH Login deny</td><td></td><td>$hosts_deny</td>
          <td></td></tr>
	<tr><td>user: sm01 sm02</td><td></td><td>$user_info</td>
          <td></td></tr>
EOT
    


    
}


#abc application checkout
my $sybase_iq_status;
my $sybase_iq_version = $resul_none;
my ($ctg_status, $ctg_version);
my ($was_status, $was_version);
my ($bmc_status, $bmc_version);
my $sybase_client_status = $resul_none;
my $sybase_server_status = $resul_none;
my ($sybase_client_version, $sybase_server_version);


sub abc_app_check{
    my ($was_mq, $sybase, $was, $sybase_iq, $ctg, $bmc, );
    
    #sysIQ
    my $sysiq_status = `ps aux |grep sybiq|grep -v grep|grep iqsrv 2>&1`;
    chomp $sysiq_status;
    if($sysiq_status){
        $sybase_iq_status = $resul_normal;
        if($sysiq_status =~ /IQ-(\d+).(\d+)?\/bin(\d+)?/){
            my $bit = $3;
            my $bits;
            if($bit eq 64){
                $bits = "X64";
            }else{
                $bits = "X86";
            }
            $sybase_iq_version = "$1.$2 $bits";
        }
    }else{
	$sybase_iq_status = $resul_none;
	$sybase_iq_version = $resul_none;
    }
    
    #was
    my $was_dir = "/soft/IBM/WebSphere/AppServer/bin";
    #my $was_ps = `ps aux |grep was|grep node|grep -v grep 2>&1`;
    if(-d $was_dir){
        $was_status = $resul_normal;
        $was_version = `/soft/IBM/WebSphere/AppServer/bin/versionInfo.sh |grep Version|grep [0-9]\$|awk '{print \$2}' 2>&1`;
        chomp $was_version;
    }else{
        $was_status = $resul_none;
	$was_version = $resul_none;
    }
    
    #CTG
    my $ctg_dir = "/opt/ibm/cicstg";
    if(-d $ctg_dir){
        $ctg_status = $resul_normal;
        #my $ctg_v = `/opt/ibm/cicstg/bin/cicscli -V |grep CICS |grep Linux |awk '{print \$8}'`;
        #chomp $ctg_v;
	my $ctg_version = `/opt/ibm/cicstg/bin/cicscli -V |grep CICS |grep Linux |awk '{print \$8}'`;
        chomp $ctg_version;
        #if($ctg_v =~ /Version\s+?(\d\..*?\d)$/){
        #    $ctg_version = $1;
        #}
    }else{
	    $ctg_status = $resul_none;
		$ctg_version = $resul_none;
	}
    
    #patrol
    my $patrol_ps = `ps -ef|grep Patrol|grep -v grep 2>&1`;
    if($patrol_ps){
        $bmc_status = $resul_normal;
        
    }else{
        $bmc_status = $resul_none;
    }
    
    
    #sybase client & Server
    my $home = "/sybase";
    if(-d $home){
	opendir(DIR, $home) or die "can't open this directory $!";
	my @syb_dir = readdir(DIR);
	foreach (@syb_dir){
	    if(/(^OCS-.*?)/){
		$sybase_client_status = $resul_normal;
		#my $client_dir = $1;
		#my $syb_v_file = "$home/$client_dir/lib/libsybdb.so";
		my $syb_v_file = "$home/$_/lib/libsybdb.so";
		if(-f $syb_v_file){
		    #$sybase_client_version = `strings $home/$client_dir/lib/libsybdb.so |grep Common-Library|awk -F "/" '{print \$2}' 2>&1`;
			$sybase_client_version = `strings $home/$_/lib/libsybdb.so |grep Common-Library|awk -F "/" '{print \$2}' 2>&1`;
		    chomp $sybase_client_version;
		}else{
		    $sybase_client_version = $resul_none;
		}
		
		
		
	    }elsif(/(^ASE.*?)/){
		$sybase_server_status = $resul_normal;
		#my $server_dir = $1;
		my $sybase_server_v = `su - sybase -c "dataserver -v" 2>&1`;
		chomp $sybase_server_v;
		if($sybase_server_v =~ /Enterprise\/(\d+.*?)\/Enterprise/){
		    $sybase_server_version = $1;
		}
	    }
    
	}
	closedir DIR;
    }else{
	$sybase_server_version = $resul_none;
	$sybase_client_version = $resul_none;
    }
    
    
    &init_html_table;
    print HTML <<EOT
    <tr><td>SybaseIQ</td><td>$sybase_iq_status</td><td>$sybase_iq_version</td>
          <td></td></tr>
    <tr><td>WAS Node</td><td>$was_status</td><td>$was_version</td>
          <td></td></tr>
    <tr><td>Install CTG</td><td>$ctg_status</td><td>$ctg_version</td>
          <td></td></tr>
    <tr><td>Install Patrol</td><td>$bmc_status</td><td></td>
          <td></td></tr>
    <tr><td>Install SybaseS</td><td>$sybase_server_status</td><td>$sybase_server_version</td>
          <td></td></tr>
	<tr><td>Install SybaseC</td><td>$sybase_client_status</td><td>$sybase_client_version</td>
          <td></td></tr>
EOT

	
	
    
}



#crontab checking
my (@crontab_info, $crontab_status, $crond_status, $root_cron_status);
my $gc_clear = $resul_none;
my $udpjobsts = $resul_none;
my $ctg_check = $resul_none;
my $osac_check = $resul_none;
my $bmc_check = $resul_none;
my $was_node_boot = $resul_none;
sub cron_check{
        
    #check crontab
    my $cron_pid = "/var/run/cron.pid";
    my $cron_file = "/var/spool/cron/tabs/root";
    if(-f $cron_pid){
        $crond_status = $resul_normal;
        if(-f $cron_file){
            $root_cron_status = $resul_normal;
	    open(SCRON, $cron_file) or die "can't open the file $!";
            foreach my $cron_tab_ent(<SCRON>){
                if($cron_tab_ent =~ /^#/){
                    next;
                }elsif($cron_tab_ent =~ /clear_gc_log\.sh/){
                    $gc_clear = $resul_normal;
                }elsif($cron_tab_ent =~ /clear_pidjob\.sh/){
                    $udpjobsts = $resul_normal;
                }elsif($cron_tab_ent =~ /test_ctg\.sh/){
                    $ctg_check = $resul_normal;
                }elsif($cron_tab_ent =~ /Chk32145\.sh/){
                    $osac_check = $resul_normal;
                }elsif($cron_tab_ent =~ /PACheck\.sh/){
                    $bmc_check = $resul_normal;
                }
            }
            close SCRON;
        }else{
            $root_cron_status = "No root crontab";
        }
    }else{
        $crond_status = "The Crond is unused";
    };
    
	#was boot check
	my $was_boot = `chkconfig -l|grep was 2>&1`;
	chomp $was_boot;
	if($was_boot =~ /3:on\s+.*?5:on/){
		$was_node_boot = $resul_normal;
	
	}
    
	
	&cron_html_table;
	print HTML <<EOT
	<tr><td>Crond Status</td><td>$crond_status</td><td></td></tr>
	<tr><td>Root Crontab</td><td>$root_cron_status</td><td></td></tr>
	<tr><td>WAS's GC Clear</td><td>$gc_clear</td><td></td></tr>
	<tr><td>UdpJobSts</td><td>$udpjobsts</td><td></td></tr>
	<tr><td>CTG Monitor</td><td>$ctg_check</td><td></td></tr>
	<tr><td>OSAC Onboot</td><td>$osac_check</td><td></td></tr>
	<tr><td>BMC Onboot</td><td>$bmc_check</td><td></td></tr>
	<tr><td>WAS's Node boot level</td><td>$was_node_boot</td><td></td></tr>
	
	
EOT
	

    
}





#HTML format output
sub init_html() {
    print HTML <<EOT
<html><head>
<title>Before Status Checkout Of Project Online</title>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<script>
function showhide(button,id) {
    var but=document.getElementById(button);
    var el=document.getElementById(id);
    if(but.innerHTML.match(/show/)) {
        el.style.display='';
        but.innerHTML='[hide]';
    } else {
        el.style.display='none';
        but.innerHTML='[show]';
    }
    return false;
}
</script>
</head>
<body>
EOT
}
sub init_html_table {
    #my ($tabid) = @_;
    print HTML <<EOT
    <table id="tabid" cellspacing=0 border=1 align="center">
      <thead>
        <th>Name</th><th>Install Status</th><th>status/version</th>
          <th>comment</th>
      </thead>
      <tbody>
EOT
}

sub cron_html_table {
    #my ($tabid) = @_;
    print HTML <<EOT
    <table id="tabid" cellspacing=0 border=1 align="center">
      <thead>
        <th>Name</th><th>Install Status</th><th>comment</th>
      </thead>
      <tbody>
EOT
}

sub none_table{
    print HTML <<EOT
    <table cellspacing=0 border=0 align="center">
    <thead>
      <th></th>
    </thead>    
EOT
}

sub finish_html() {
    print HTML <<EOT
    <table cellspacing=0 border=0 align="center">
    <thead>
      <th>$report_ts</th>
    </thead>
  </body>
</html>
EOT
}


my @host_ip=`ifconfig |grep "inet addr"|grep -v 127|awk -F: '{print \$2}'|awk '{print \$1}' 2>&1`;
my $hosts_name = `hostname 2>&1`;
chomp $hosts_name;
sub print_hostname {
    #my ($tabid) = @_;
    print (HTML '<table id="tabid" cellspacing=0 border=0 align="center">');
    print (HTML  "<thead>");
    print (HTML "<th>HostName: <U>$hosts_name</U>");
    print (HTML "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;");
    print (HTML "Host_IP: <U>");
    foreach my $host_ip(@host_ip){
	chomp $host_ip;
	print (HTML "$host_ip ");
    }
    print (HTML "</th></thead><tbody>");
}


open(HTML,     "> /tmp/$hosts_name.html")   || Die(1, "open(HTML): $!\n");
&init_html; &print_hostname; &sysinfo; &none_table; &abc_app_check; &none_table; &cron_check; &finish_html;