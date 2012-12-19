#!/usr/bin/perl -w 

use strict;
use warnings;
use Expect;

my $obj = new Expect;
$obj=Expect->spawn("ftp root\@192.168.56.111");
$obj->expect(10,
	[ qr/assword:\s*$/      => sub { $obj->send("111111\n");  } ],
);

$obj->interact();
