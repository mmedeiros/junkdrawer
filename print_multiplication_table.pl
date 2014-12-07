#!/usr/bin/perl 

my $max;

if (defined $ARGV[0] ) { 
	$max = $ARGV[0];
} else { 
	$max = 12; 
}

my @numbers = (1..$max);
my @numbers2 = (1..$max);

foreach $i (@numbers) {
    foreach $j (@numbers2) {
        $out = ($i*$j);
        print "$out";
        if ($j == $max) {
            print "\n"; 
        } else { 
            print "\t";
        }
    }
}
