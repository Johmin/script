#/usr/bin/perl

use warnings;
use strict;
use Net::OpenSSH;
$ENV{'PATH'} = "/usr/kerberos/sbin:/usr/kerberos/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin$ENV{'PATH'}";

if( ! defined $ARGV[0] ) {
        print "Usage: test.pl '1 or 2' \n";
        exit;
}

my $f = $ARGV[0];

if( $f eq 1 ){
	&test("$f");
}else{
	&test1("$f");
	}

sub test {
	my $argx = shift;
	print "$argx\tok\n";
	}
	
sub test1 {
	my $argx = shift;
	print "$argx\tno\n";
	}