#!/usr/bin/perl
use strict;
use warnings;
use Time::HiRes qw(gettimeofday);
our $plot_size = 85253860;
sub get_dir_usable_size {
        my $dir = shift @_;
        my $size = `df $dir | tail -n 1 | awk '{print \$4}'`;
        chomp $size;
        return $size;
}

my $cmd = "/home/wyatt/Downloads/bladebit_cuda -n 32 -f 910921b8558c2878eab9d5c0664955bf613f06e3cbcffa1562096825d622af82b8405d6c6a3290c7c3001ea1fae37ce1 -c xch1s40paqllwnq3pamgqh255z8xyfsnqn7295rllvhed44aprch83ssvn2vcu --compress 5 cudaplot /mnt/tmp_vol/";

my $waited = 0;
while(1) {
	my $disk_size = get_dir_usable_size("/mnt/tmp_vol");
	my $usable_space = $disk_size / $plot_size;
	print "usable_space: $usable_space\n";
	if($usable_space > 0.05) {
		print "Waited: $waited\n";
		my $start_time = gettimeofday;
		`$cmd >> log`;
		`rm /mnt/tmp_vol/*plot.tmp`;
		my $end_time = gettimeofday;
		my $time_taken = $end_time - $start_time;
		print "Time taken: $time_taken seconds\n";
		$waited = 0;
	} else {
		sleep 1;
		$waited++;
	}
}
