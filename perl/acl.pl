#!/usr/bin/perl -w

use strict;
use warnings;

my %seen=();
my $acl_log = "/var/log/acl.log"; 
my $cmd_list = "./cmd_list.cfg";
my (@errlist,@log,@cmd,@cmd_new,@succeed);
my (undef,$min,$hour,$mday,$mon,$year)=localtime(time);
my $date_time = sprintf("%4d%02d%02d%02d%02d", $year+1900, $mon+1, $mday, $hour, $min);
$ENV{'PATH'} = "/usr/kerberos/sbin:/usr/kerberos/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin$ENV{'PATH'}";

if( ! defined $ARGV[0] ) {
        print "Usage: acl.pl <command_list> <file_list> \n";
        exit;
}

unless ( -e $acl_log ){
	system("setfacl -m g:abc:--- /bin/*");
	system("setfacl -m g:abc:--- /sbin/*");
	system("setfacl -m g:abc:--- /usr/bin/*");
	system("setfacl -m g:abc:--- /usr/sbin/*");
	system("setfacl -b /usr/bin");
	&cmd_list;
	&execute;
}else{
	&diff;
	&execute;
}

sub acl_log{
	if ( -e $acl_log ){
		open HD,$acl_log or die "can't open the file $!";
		while($a=<HD>){
		chomp $a;
		if ( $a=~/.*\/(\w+)/){
			push @succeed,$1;
        }
		}
        close HD;
	}
	foreach(@succeed){
        $seen{$_}=1;
	}
	@succeed=keys %seen;
}

sub cmd_list{
	if( -e $cmd_list){
		open FD,$cmd_list or die "can't open the file $!";
		while(<FD>){
		chomp $_;
		@cmd = split(/,/,$_);
		@cmd_new = @cmd;
		}
		close FD;
	}
}

sub diff{
	&cmd_list;
	&acl_log;
	undef @cmd_new;
	print "###Command successful list###\n";
	foreach my $cmd(@cmd){
        chomp $cmd;
        my $f=0;
        foreach (@succeed){
			chomp $_;
			if ( $_ eq $cmd ){
				print "($cmd) is find!\n";
				$f=1;
			}
        }
        if ($f == 0){
			push @cmd_new,$cmd;
        }
	}
}

sub execute{
	my $f=0;
	my $h=0;
	foreach (@cmd_new){
	my $path = `which $_ 2>&1`;
	chomp $path;
	if( -e $path){
		system("setfacl -b $path");
		push @log, "$date_time setfacl -b $path";
		$h=1;
	}else{
		$f=1;
		push @errlist,$_;
	}
	}

	open LOG,">>$acl_log" || Die (1, "open(LOG): $!\n");
	foreach (@log){
		print (LOG "$_\n");
	}
	close LOG;
	
	if ( $h == 1 ){
	print "\n\n###New command successful list###\n";	
	print "$_\n" foreach @log;
	}
	
	if ( $f == 1 ){
		print "\n\n###Command failed to perform list###\n";
		print "$_\n" foreach @errlist;
	}
}
