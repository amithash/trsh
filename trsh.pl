#!/usr/bin/perl

#*************************************************************************
# Copyright 2008 Amithash Prasad                                         *
#									 *
# this file is part of trsh.						 *
#                                                                        *
# trsh is free software: you can redistribute it and/or modify           *
# it under the terms of the GNU General Public License as published by   *
# the Free Software Foundation, either version 3 of the License, or      *
# (at your option) any later version.                                    *
#                                                                        *
# This program is distributed in the hope that it will be useful,        *
# but WITHOUT ANY WARRANTY; without even the implied warranty of         *
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the          *
# GNU General Public License for more details.                           *
#                                                                        *
# You should have received a copy of the GNU General Public License      *
# along with this program.  If not, see <http://www.gnu.org/licenses/>.  *
#*************************************************************************

use strict;
use warnings;
use Getopt::Long;
use File::Find;
use Cwd;

my $recover = 0;
my $empty = 0;
my $view = 0;
my $force = 0;
my $undo = 0;
my $size = 0;
my $help = 0;
my $warn = 0;
my $recursive = 0;

my @remaining;

if (not defined $ENV{TRASH_DIR}) {
    print "The environment variable TRASH_DIR is not set\n";
    exit;
}
my $trash = $ENV{TRASH_DIR};
my $history = "$ENV{TRASH_DIR}/.history";

Getopt::Long::Configure('bundling');

GetOptions( 'e|empty'      => \$empty, 
            'l|list'       => \$view,
	    'f|force'	   => \$force,
	    'u|undo'	   => \$undo,
	    's|size'	   => \$size,
	    'h|help'       => \$help,
	    'i|interactive'=> \$warn,
    	    'r|recursive'  => \$recursive);

@remaining = @ARGV;

if( !(-e $trash) ) {
	print "Could not find the trash directory, creating it...\n";
        system("mkdir $trash");
}
if( !(-e $history)){
	print "Could not find the history file. Creating it... \n";
	system("touch $history");
}

if($undo == 1 and $#remaining >= 0){
	$recover = 1;
	$undo = 0;
}

if($help == 1){
	usage();
	exit;
}


if($size == 1){
	open SZ,"du -sh $trash |";
	my @sz = split(/\s/,<SZ>);
	print "$sz[0]B\n";
	close(SZ);
	exit;
}

# Restore the last deleted file
if($undo == 1){
	restore_last_file();
	exit;
}

# If the force flag is on, then rm instead of moving to trash.
if($force == 1){
	# If the warn flag is on, delete interactively. 
	my $cmd = "rm -r";
	$cmd = $cmd . "i" if($warn == 1);
	foreach my $this (@remaining){
		system("$cmd $this");
	}
	exit;
}

# If the view flag is on, ls the files
if($view == 1){
	system("ls -l $trash");
	exit;
}

if($empty == 1){
	if(get_response("Are you sure you want to empty the trash?") == 1){
		system ("rm -rf $history");
		system ("rm -rf $trash/*");
		system ("touch $history");
	}
	exit;
}


if($#remaining >= 0){
	my @not_there;
	my $file_with_space = "";
	my $file_with_space_cmd = "";
	foreach my $item_index (@remaining){
		my $i = 0;
		my $item = check_and_replace($item_index);
		if($recover == 1){
			if(does_item_exist_in_history($item) > 0){
				restore_file("$item");
			}
			else{
				print "Item DOes not exist in history\n";
			}
		}
		elsif(-e $item_index){  
			if(-d $item_index){
				if($recursive == 0){
					print STDERR "Cannot remove directory \"$item_index\"\n";
					next;
				}
			}
			elsif($warn == 1){
				next unless(get_response("Are you sure you want to delete file: \"$item_index\"") == 1);
			}
			delete_file("$item");
		}
		else{
			print "Cowardly refused to delete an imaginary file \"$item_index\"\n";
		}	
	}
	if($file_with_space ne ""){
		print "Could not delete $file_with_space\n";
	}
}
else{
	print "Gallantly deleted abslutely nothing!\n";
	exit;
}

#####################################################
# SUBS WHICH MAKE IT SUNNY OUTSIDE
#####################################################

#####################################################
# MISL FUNCTIONS
#####################################################

sub check_and_replace{
	my $f = shift;
	my $x = join("\\ ", split(/\s/,$f));
	return $x;
}

sub usage{
	print "Usage:

rm -r|-recover FILE
\tthis will move the deleted file named FILE from the trash to the current dir

rm -v|-view
\tThis will list the contents of the trash

rm -e|-empty
\tThis will empty the trash bin

rm -u|-undo
\tThis will restore the previously deleted file.

rm FILE
\tThis will delete the file

rm -f|-force FILE
\tThis will permanently delete the FILE

rm -s|-size
\tThis will display the size of the trash folder.

rm -i|-interactively|-w|-warn
\tThis will nag the user for every file

rm -h|-help
\tThis will display this screen
\n";
}

sub get_response{
	my $message = shift;
	my $ret = 0;
	print "$message (y/n):";
	my $response = <STDIN>;
	chomp($response);
	# Any response, other than y,Y is considered as a n. 
	if($response eq "y" or $response eq "Y"){
		$ret = 1;
	}
	return $ret;
}

#############################################################
# HIGH LEVEL TRASH FUNCTIONS
#############################################################

sub delete_file{
	my $item = shift;
	my @item_names = split(/\//, $item);
	my $item_name = $item_names[$#item_names];
	my $count = does_item_exist_in_history($item_name);
	if($count == 0){
		push_to_history($item_name);
		system("mv $item $trash");
	}
	else{
		push_to_history("$item_name\______$count");
		system("mv $item $trash/$item\______$count");
	}
}

sub restore_file{
	my $item = shift;
	my $cwd = cwd();
	my $count = does_item_exist_in_history($item);
	my $index = $count - 1;
	if($count == 0){
		print "Could not restore $item, it does not appear to exist in the trash\n";
		return;
	}
	elsif($count == 1){
		seek_and_destroy_in_history($item);
		system("mv $trash/$item $cwd/$item");
	}
	else{
		seek_and_destroy_in_history("$item\_____$index");
		system("mv $trash/$item\______$index $cwd/$item");
	}
}

sub restore_last_file{
	my $cwd = cwd();
	my $item = pop_from_history();
	my $item_cmd = join(" ", split(/\\\s/,$item));
	if(-e "$trash/$item_cmd"){
		if($item =~ /(.+)______\d+/){
			print "Restoring $1...\n";
			system("mv $trash/$item $cwd/$1");
		}
		else{
			print "Restoring $item...\n";
			system("mv $trash/$item $cwd/$item");
		}
	}
	else{
		print "Something is wrong... $item was in the history, but not in the trash... Raise a bug\n";
	}
}

#############################################################
# BASIC HISTORY FUNCTIONS
#############################################################

sub push_to_history{
	my $item = shift;
	my @contents = get_history();
	$contents[$#contents+1] = $item;
	make_history(@contents);
}

sub does_item_exist_in_history{
	my $item = shift;
	my $count = 0;
	my @contents = get_history();
	foreach my $i (@contents){
		if($i =~ /^$item\______\d+/){
			$count++;
		}
		elsif($i =~ /^$item/){
			$count++;
		}
	}
	return $count;
}

sub pop_from_history{
	my @contents = get_history();
	make_history(@contents[0..($#contents-1)]);
	return $contents[$#contents];
}

sub seek_and_destroy_in_history{
	my $item_name = shift;
	my @contents = get_history();
	my $count = 0;
	foreach my $i (@contents){
		if($i eq "$item_name"){
			my @new_countents = @contents[0..($count-1),($count+1)..$#contents];
			make_history(@new_countents);
			last;
		}
		$count++;
	}
}

sub get_history{
	open HIST, "$history" or die "Could not open history\n";
	my @contents = split(/\n/, join("", <HIST>));
	close(HIST);
	return @contents;
}

sub make_history{
	my @contents = @_;
	system("rm $history");
	open HIST,"+>$history" or die "Could not create history\n";
	my $h = join("\n",@contents);
	print HIST "$h";
	close(HIST);
}


