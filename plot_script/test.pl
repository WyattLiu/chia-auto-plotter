#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
use File::Basename;
use File::stat;

our $plot_size = 85253860;
sub get_dir_usable_size {
	my $dir = shift @_;
	my $size = `df $dir | tail -n 1 | awk '{print \$4}'`;
	chomp $size;
	return $size;
}

our %plots_in_flight;

sub send_from_to { # we fork here
	my $from = shift @_;
	chomp $from;
	my $to = shift @_;
	chomp $to;
	$plots_in_flight{$from} = 0;
	my $pid = fork();
       	if($pid == 0){
		print "cp $from $to\n";
		my $base_name = basename($from);
		my $destination_file = `readlink -f $to/$base_name`; chomp $destination_file; 
		my $source_stat = stat($from);
		my $size_in_bytes = $source_stat->size;
		# print "fallocate -l $size_in_bytes $destination_file.tmp\n";
		# `fallocate -l $size_in_bytes $destination_file.tmp`;
		`cp $from $destination_file.tmp`;
		`mv $destination_file.tmp $destination_file`;
		if($to ne "") {
			print "rm $from\n";
			`rm $from`;
		}
		exit(0);
	}
	$plots_in_flight{$from} = 1;
}
sub get_first_non_C5 {
	my $target_disk = shift @_;
	my @plots = `find $target_disk -name "*plot"`;
	foreach my $plot (@plots) {
		if($plot =~ /plot-k32-c05/) {
			next;
		} else {
			chomp $plot;
			return $plot;
		}
	}
	return "";
}

sub get_tmp {
	my $target_disk = shift @_;
	my @plots = `find $target_disk -name "*plot.tmp" | egrep plot`; chomp @plots;
	my $num_plots = scalar @plots;
	foreach my $debug (@plots) {
		$plots_in_flight{$debug} = 0;
		print "tmp plot: $debug\n";
	}
	print "$target_disk has $num_plots tmp\n";
	return $num_plots;
}

sub main {
	my @buffer_plots_raw = `find /mnt/tmp_vol/ -name "*plot"`;
	chomp @buffer_plots_raw;
	my @buffer_plots;
	foreach my $buffer_plot (@buffer_plots_raw) {
		if(!exists $plots_in_flight{$buffer_plot}) {
			push @buffer_plots, $buffer_plot;
		}
	}
	my $num_plot = scalar @buffer_plots;
	print "ramdisk has $num_plot\n";
	if($num_plot == 0) {
		#sleep 10;
		#return;
	}
	my @plots = `find /mnt -maxdepth 3 -mindepth 3 -name "*.plot" | egrep CHIA`; chomp @plots;
	my %disks;
	foreach my $plot (@plots) {
		$disks{dirname($plot)} ++;
	}
	print Dumper(\%disks);
	my @free_dir;
	my @need_to_delete_dir;
	foreach my $disk (keys %disks) {
		my $disk_size = get_dir_usable_size($disk);
		my $usable_space = int($disk_size / $plot_size);
		if($usable_space > 0) {
			if(get_tmp($disk)) {
				print "$disk: cannot use it as a free disk as plot is transfering\n";
			} else {
				print "Free space: $disk\n";
				my $i = 0;
				while($i < $usable_space) {
					push @free_dir, $disk;
					$i++;
				}
			}
		} else {
			push @need_to_delete_dir, $disk;
		}
	}
	foreach my $dir (@free_dir) {
		print "mv target free_dir: $dir\n";
	}
	exit(0);
	my $i = 0;
	while($i < $num_plot) {
		foreach my $target (@free_dir) {
			print "Send to free_dir: $target, src: $buffer_plots[$i]\n";
			send_from_to($buffer_plots[$i], $target);
			$i++;
			if($i >= $num_plot) {
				last;
			}
		}
		if($i >= $num_plot) {
 	               last;
                }
		foreach my $target (@need_to_delete_dir) {
			my $file_to_delete = get_first_non_C5($target);
			if($file_to_delete eq "") {
				next;
			} else {
				print "delete $file_to_delete\n";
				`rm $file_to_delete`;
				print "Send to need_to_delete_dir: $target, src: $buffer_plots[$i]\n";
				send_from_to($buffer_plots[$i], $target);
				$i++;
				if($i >= $num_plot) {
                                	last;
                        	}
			}
		}
	}
	print Dumper(\%plots_in_flight);
	sleep(10);
}

while(1) {
	main();
}
