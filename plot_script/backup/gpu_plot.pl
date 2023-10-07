#!/usr/bin/perl
use strict;
use warnings;

our $plot_size = 85253860;
sub get_dir_usable_size {
        my $dir = shift @_;
        my $size = `df $dir | tail -n 1 | awk '{print \$4}'`;
        chomp $size;
        return $size;
}

my $cmd = "~/proj/bladebit/build/bladebit_cuda -f 910921b8558c2878eab9d5c0664955bf613f06e3cbcffa1562096825d622af82b8405d6c6a3290c7c3001ea1fae37ce1 -c xch1s40paqllwnq3pamgqh255z8xyfsnqn7295rllvhed44aprch83ssvn2vcu --compress 5 cudaplot /mnt/tmp_vol/";

while(1) {
	my $disk_size = get_dir_usable_size("/mnt/tmp_vol");
	my $usable_space = int($disk_size / $plot_size);
	print "usable_space: $usable_space\n";
	if($usable_space > 1) {
		`$cmd`;
	} else {
		sleep 1;
	}
}
