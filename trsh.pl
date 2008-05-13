#!/usr/bin/perl

#*************************************************************************
# Copyright 2008 Amithash Prasad                                         *
#                                                                        *
# This file is part of trsh                                              *
#                                                                        *
# Seeker is free software: you can redistribute it and/or modify         *
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

my $recover = 'NULL';
my $empty = 0;
my $remaining;
my $view = 0;
my $force = 0;
my $undo = 0;

if (not defined $ENV{TRASH_DIR}) {
    print "The environment variable TRASH_DIR is not set\n";
    exit;
}
my $trash = $ENV{TRASH_DIR};
my $history = "$ENV{TRASH_DIR}/.history";

GetOptions( 'recover=s' => \$recover,
            'empty'     => \$empty, 
            'view'      => \$view,
	    'force'	=> \$force,
	    'undo'	=> \$undo);

$remaining = join(' ', @ARGV);

if( !(-e $trash) ) {
	print "Could not find the trash directory, creating it...\n";
        system("mkdir $trash");
}
if( !(-e $history)){
	print "Could not find the history file. Creating it... \n";
	system("touch $history");
}

if($undo == 1){
	my $line;
	my $last_line = '';
	open HISTORY,"<$history" or die "Could not open the .history file in the TRSH DIR\n";
	open HISTORY_NEW,"+>$history.new";
	while ($line = <HISTORY>){
		$last_line = $line;
	}
	chomp($last_line);
	close HISTORY;
	open HISTORY,"<$history" or die "Could not open the .history file in the TRSH DIR\n";
	while($line = <HISTORY>){
		chomp($line);
		if($last_line ne $line){
			print HISTORY_NEW "$line\n";
		}
	}
	close HISTORY;
	close HISTORY_NEW;
	system("mv $history.new $history");
	if($last_line eq ''){
		print "History empty\n";
		exit;
	}
	print "Restoring $last_line\n";
	$recover = "$last_line";
}


if($force == 1){
	system("rm -rf $remaining");
	exit;
}

if($view == 1){
	system("ls $trash");
	exit;
}


if($recover ne 'NULL'){
	if($recover ne ''){
		if(-e "$trash/$recover"){
			my $i = 0;
			while(-e "$trash/$recover\@$i"){
				$i = $i + 1;
			}
			if($i == 0){
				system("mv \'$trash/$recover\' .");
			}
			else{
				$i = $i-1;
				system("mv \'$trash/$recover\@$i\' \'$recover\'");
			}
		}
		else{
			print "Sorry cannot find $recover in the trash. Try rm -v to check if it exists\n";
		}
	}
	else{
		print "You must provide (a) file/s to recover\n";
		exit;
	}
}

elsif($empty == 1){
	system ("rm -rf $history");
	system ("rm -rf $trash/*");
	system ("touch $history");
}
else{
	if($remaining ne ''){
		my @rem = split(/\s/,$remaining);
		my @not_there;
		my $file_with_space = "";
		my $file_name_with_space = "";
		open HISTORY,">>$history" or die "Could not open the .history file in TRSH DIR\n";
		foreach my $item (@rem){
			my $i = 0;
			if(-e $item){
				my @items = split(/\//,$item);
				my $item_name = $items[$#items];
				if(-e "$trash/$item_name"){
					while(-e "$trash/$item_name\@$i"){
						$i = $i + 1;
					}
					system("mv $item $trash/$item_name\@$i");
				}
				else{
					system("mv $item $trash/$item_name");
				}
				print HISTORY "$item_name\n";
			}
			else{
				my @items = split(/\//,$item);
				my $item_name = $items[$#items];
				if($file_with_space eq ""){
					$file_with_space = $item;
					$file_name_with_space = $item_name;
				}
				else{
					$file_with_space = $file_with_space . " " . $item_name;
					$file_name_with_space = $file_name_with_space . " " . $item_name;
				}
				if(-e "$file_with_space"){
					if(-e "$trash/$file_name_with_space"){
						while(-e "$trash/$file_name_with_space\@$i"){
							$i = $i + 1;
						}
						system("mv \'$file_with_space\' \'$trash/$file_name_with_space\@$i\'");
					}
					else{
						system("mv \'$file_with_space\' \'$trash/$file_name_with_space\'");
					}
					print HISTORY "$file_name_with_space\n";
					$file_with_space = "";
				}
			}	
		}
		if($file_with_space ne ""){
			print "$file_with_space could not be deleted\n";
		}
		close HISTORY;
	}
	else{
		print "Nothing to be deleted\n";
		exit;
	}
}

