#!/usr/bin/perl -w

use strict;
use warnings;

my $file_path = '/test/';
my $time = `date -d "180 days ago" +"%Y%m%d"`;
my @file_name = `ls -l --time-style="+%Y%m%d" $file_path |grep -v ".tar.gz"`;
foreach(@file_name){
	chomp $_;
	if ($_=~/\s(\d{8})\s+(data.*)/ ){
		if ( $1 <= $time ){
			`cd $file_path && tar -zcvf $2.tar.gz $2 && rm $2`;
		}
	}
}
