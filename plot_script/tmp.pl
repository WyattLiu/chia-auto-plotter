#!/usr/bin/perl
use strict;
use warnings;

my $str = "/mnt/222_media/CHIA-IRONWOLF2/plot-k32-c05-2023-08-28-04-08-1f4018068c9fc042c5aabedfc9077da4c04dfe6048993fcf82150f6a93e165d2.plot.tmp";

$str =~ s/\/mnt\//192.168.1./;
$str =~ s/_media/:\/media\/wyatt/;
print "$str\n";
