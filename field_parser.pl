#!/usr/bin/perl 

my $IN_FILE = '/Users/me/Desktop/test.txt';

open (USERS, $IN_FILE) or die "can't open data file \n";

while (<USERS>) { 
	chomp $_ ; 
	my @fields = (split/\t/=>$_);
	
	if ($fields[4] =~m/tech/i) { 
		print "$fields[5] is a tech\n";
			}
}
