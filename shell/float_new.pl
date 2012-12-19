#!/usr/bin/perl
use strict;
use warnings;

my $ip_dev = "eth2";
my $ip_address = "10.235.131.207";
my $ip_netmask = "255.255.255.224";
my $ip_gw= "10.235.131.222";
my @ip_route = ("10.235.138.145","10.235.138.146","10.235.138.147","10.235.138.148","10.235.138.149","10.235.138.150","10.235.138.151","10.235.138.152","10.235.138.153","10.235.138.155","10.235.139.209","10.235.139.210");

my $argc = scalar(@ARGV);
if($argc != 1){
	&usage;;
	exit;
}

my $f = $ARGV[0];
if($f eq "start"){
	&start;

}elsif($f eq "stop"){
	&stop;

}else{
	&usage;
	exit;
}

sub start(){
	my $ping_pack = `ping -c 4 $ip_address 2>&1`;
        	if ($? == 0){
           		print "$ip_address Has already been used\n";
        	}elsif($? == 1){
			system("ifconfig $ip_dev $ip_address netmask $ip_netmask up");
			foreach (@ip_route) {
				system("route add -host $_ gw $ip_gw dev $ip_dev");	
			}
			print "Has started\n";
		}else{
			print "Float ip address error\n";
		}
}


sub stop(){
	system("ifdown $ip_dev >/dev/null");
	print "Has stopped\n";
}

sub usage{
	print "Usage: perl $0 {start|stop}\n";
}
