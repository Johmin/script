#!/usr/bin/perl -w

use strict;
use warnings;
use Net::OpenSSH;

my $argx = shift;
my $user = "root";
my $pass = "111111";
my $host_ip = "$argx";
my $ssh;

$ssh = Net::OpenSSH -> new($host_ip, user => "$user", passwd => "$pass");
$ssh->error and die "Conldn't establish SSH $host_ip connection: " . $ssh->error;
$ssh -> capture("ls 2>&1")  or die "remote command failed: " . $ssh->error;
print "$argx\n";
print "$host_ip\n";