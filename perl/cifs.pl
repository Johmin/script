#!/usr/bin/perl -w 

use strict;
use warnings;
use Expect;

my $obj = new Expect;
$obj=Expect->spawn("mount -t cifs //172.16.81.1/ISO -o username=johmin /mnt");
$obj->expect(10,
	[ qr/assword:\s*$/      => sub { $obj->send("abcd!1234\n");  } ],
);

$obj->interact();
