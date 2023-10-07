#!/usr/bin/perl

use strict;
use warnings;
use File::Basename;

my $local_file = $ARGV[0];
my $remote_file = $ARGV[1];

my $remote_host = $remote_file;
my $remote_path;
if($remote_host =~ /(.*):(.*)/) {
	$remote_host = $1;
	$remote_path = $2;
} else {
	print "Not a remote path\n";
	exit(-1);
}
if(!-e $local_file) {
	print "No local file: $local_file\n";
	exit(-1);
}
my $copy_chuck_size = 1073741824;
my $originaly_file_size = `stat -c %s $local_file`;
print "OG size: $originaly_file_size\n";
my $copied_size = 0;
my $prefix = "wscp_";
my $local_dir = dirname($local_file);
my $base_name = basename($local_file);
my $part_i = 0;
while(1) {
	my $curr_size = $originaly_file_size - $copied_size;
	if($curr_size < $copy_chuck_size) {
		if($curr_size == 0) {
			`rm $local_file`;
		} else {
			# last piece.
			print "Transfer $curr_size\n";
			`mv $local_file $local_dir/$part_i\_$prefix$base_name.part`;
			$part_i++;
		}
		last;
	} else {
		# split the file using tail
		# copy
		# truncate original file
		print "Transfer $copy_chuck_size\n";
		my $new_size = $curr_size - $copy_chuck_size;
		my @file_content = `tail -c $copy_chuck_size $local_file`; # no disk can be as tight as possible 
		`truncate -c -s $new_size $local_file`;
		my $path = "$local_dir/$part_i\_$prefix$base_name.part";
		open(my $fh, '>', $path);
		print $fh @file_content;
		close $fh;
		print "File size should be $new_size\n";
		$copied_size += $copy_chuck_size;
	}
	$part_i++;
}

print "We have $part_i parts\n";
my $transfer_i = $part_i - 1;
while($transfer_i >= 0) {
	`scp $local_dir/$transfer_i\_$prefix$base_name.part $remote_file.$transfer_i.tmp`;
	my $remote_tmp_path = "$remote_file.$transfer_i.tmp";
	print "Handling $remote_tmp_path\n";
	if($remote_tmp_path =~ /(.*):(.*)/) {
		$remote_tmp_path = $2;
	} else {
		exit;
	}
	if($transfer_i ==  $part_i - 1) {
		`ssh $remote_host mv $remote_tmp_path $remote_path`;
	} else {
		print "ssh $remote_host cat $remote_tmp_path >> $remote_path\n";
		`ssh $remote_host "cat $remote_tmp_path >> $remote_path"`;
		print "ssh $remote_host rm $remote_tmp_path\n";
		`ssh $remote_host rm $remote_tmp_path`;
	}
	`rm $local_dir/$transfer_i\_$prefix$base_name.part`;
	$transfer_i--;
}


