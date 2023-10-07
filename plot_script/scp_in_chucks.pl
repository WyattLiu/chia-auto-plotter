#!/usr/bin/perl

use strict;
use warnings;
use File::Basename;
use Net::OpenSSH;
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
my $originaly_file_size = `stat -c %s $local_file`; chomp $originaly_file_size;
print "OG size: $originaly_file_size\n";
my $copied_size = 0;
my $prefix = "wscp_";
my $local_dir = dirname($local_file);
my $base_name = basename($local_file);
my $part_i = 0;
my $ssh = Net::OpenSSH->new("wyatt\@$remote_host");
my $pid = -1;
while(1) {
	my $curr_size = $originaly_file_size - $copied_size;
	if($curr_size < $copy_chuck_size) {
		if($curr_size == 0) {
			`rm $local_file`;
		} else {
			# last piece.
			print "Transfer $curr_size\n";
			`scp $local_file $remote_file.$part_i.tmp`;	
			`rm $local_file`;
			$part_i++;
		}
		last;
	} else {
		# split the file using tail
		# copy
		# truncate original file
		print "Transfer $copy_chuck_size\n";
		my $new_size = $curr_size - $copy_chuck_size;
		#my @file_content = `tail -c $copy_chuck_size $local_file`; # no disk can be as tight as possible 
		my $file_content;
		open my $local_file_fd, "<", $local_file;
		seek $local_file_fd, -$copy_chuck_size, 2;
		read $local_file_fd, $file_content, $copy_chuck_size;
		close $local_file_fd;
		`truncate -c -s $new_size $local_file`;
		if($pid > 0) {
			waitpid($pid, 0);
		}
		$pid = fork();
		if($pid == 0) {	
			$ssh->system({ stdin_data => $file_content}, "cat > $remote_path.$part_i.tmp");
			exit(0);
		}
		print "File size should be $new_size\n";
		$copied_size += $copy_chuck_size;
	}
	$part_i++;
}
if($pid > 0) {
	waitpid($pid, 0);
}

print "We have $part_i parts\n";
my $transfer_i = $part_i - 1;
while($transfer_i >= 0) {
	# `scp $local_dir/$transfer_i\_$prefix$base_name.part $remote_file.$transfer_i.tmp`;
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
	#`rm $local_dir/$transfer_i\_$prefix$base_name.part`;
	$transfer_i--;
}


