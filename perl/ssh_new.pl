#!/usr/bin/perl -w 

use strict;
use warnings;
use Expect;

my $obj = new Expect;
$obj=Expect->spawn("ssh root\@172.16.81.131");
$obj->expect(10,
	[ qr/\(yes\/no\)\?\s*$/ => sub { $obj->send("yes\n"); exp_continue; } ],
	[ qr/assword:\s*$/      => sub { $obj->send("111111\n");  } ],
);

$obj->interact();
