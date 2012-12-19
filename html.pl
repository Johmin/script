#！/bin/usr/perl -w

use strict;
use warnings;

my @file_name = `ls *.html`;
my $file_name;
my $i = 0;

foreach $file_name (@file_name){
	chomp $file_name;
	$i = $i+1;
	open FD,$file_name or die "can't open the file $!";
	while(<FD>){
		chomp $_;
		if ($_=~/.*主机名称：<U>(.*)<\/U>.*主机IP地址：<U>(.*)<\/U>/){
			print "$1\t$2\n";
		}
	}
	close FD;
}
print "主机数量：$i\n";
