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

# TODO:
# 1. Get a history in the start as an array, and write on exit.
#    Currently this is done very badly, by opening and closing history
#    too many times.... This can create considerable load.
#
# 2. The size of each file must be in the history. This allows quick 
#    file size display. 
#
# 3. Due to '1', I need to create a single exit point with the dump to
#    file. And also find out a way to catch a term/abort signal to dump 
#    to history.... Else, a term may cause corruption and incoherence
#    to the history file. BOTH 1 and 3 must be implemented together...
#
# 4. Along with an array, create a hash. This will definately 
#    speed up lookups (Linear to O1) when a lot of files are deleted.
#    And the regex is done only once.
#
# 5. With '2', I can then display the cumilative ( 3 * 4KB) kinda display
#    on a trsh.pl -l.
#
# 6. Usage should not display a man page!!! Now that the usage has setteled
#    down, remove them... Creates confusion. And hence remove that install
#    change thing. And a user install will not get a man page! :-)
#
# 7. Optimize: Replace all open to execute kinda stuff with back ticks...
#
# 8. Wait till this reaches 15 points atleast to start making changes.
#    So trsh 1.1 will be one tested release! :-)

use strict;
use warnings;
use Getopt::Long;
use File::Find;
use Term::ANSIColor;
use Cwd;
$Term::ANSIColor::AUTORESET = 1;

my $usage_string = "
USAGE: rm [OPTIONS]... [FILES]...

FILES:
This is a list of files to recover or delete.

OPTIONS:
-u|--undo [FILES]
This option instructs trsh to recover FILES from the trash and place them into the current working directory.
If FILES is not provided, the last deleted file is recovered and placed into the current working directory.

-f|--force
This option instructs trsh to permanently delete FILES and completely bybass the trash

-i|--interactively
This option will instruct trsh to prompt the user before deleting each and every file.

-v|--verbose
This option will instruct trsh to talk about whatever it is doing.

-e|--empty
This empties the trash.

-r|--recursive
This option if provided will allow directories to be deleted.

-l|--list
This will display the contents of the trash.

-s|--size
This displays the size of the Trash directory. 

-h|--help
Displays this help and exits.

rm FILES just moves FILES to the trash. By default, directories are not deleted.
\n";


my $recover = 0;
my $empty = 0;
my $view = 0;
my $force = 0;
my $undo = 0;
my $size = 0;
my $help = 0;
my $warn = 0;
my $verbose = 0;
my $recursive = 0;
my $regex_force = 0;

Getopt::Long::Configure('bundling');

GetOptions( 'e|empty'      => \$empty, 
            'l|list'       => \$view,
	    'f|force'	   => \$force,
	    'u|undo'	   => \$undo,
	    's|size'	   => \$size,
	    'h|help'       => \$help,
	    'i|interactive'=> \$warn,
	    'v|verbose'    => \$verbose,
	    'x|force-regex'=> \$regex_force,
    	    'r|recursive'  => \$recursive);


my @remaining = @ARGV;

if (not defined $ENV{HOME}) {
    print "The environment variable HOME is not set\n";
    exit_routine();
}
my $trash = "$ENV{HOME}/.Trash";
my $history = "$trash/.history";
my @hist_raw = get_history();


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


if($size == 1){
	my $sz;
	if($help == 1){
		$sz = get_size_human_readable();
		print "$sz" . "B\n";
	}
	else{
		$sz = get_size();
		print "$sz\n";
	}
	exit_routine();
}

if($help == 1){
	usage();
	exit_routine();
}

# Restore the last deleted file
if($undo > 0){
	restore_last_file();
	exit_routine();
}

# If the force flag is on, then rm instead of moving to trash.
if($force == 1){
	my $cmd = "rm ";
	$cmd = $cmd . "-r " if($recursive == 1); # Pass the recursive flag to rm
	$cmd = $cmd . "-i " if($warn == 1); # Pass the interactive flag to rm
	foreach my $this (@remaining){
		print "Removing \"$this\" permanently\n" if($verbose == 1);
		system("$cmd \"$this\"");
	}
	exit_routine();
}

# If the view flag is on, ls the files
if($view == 1){
	display_trash();
	exit_routine();
}

if($empty == 1){
	if($#remaining >= 0){
		foreach my $entry (@remaining){
			remove_from_trash($entry);
		}
	}
	else{
		empty_trash();
	}
	exit_routine();
}


if($#remaining >= 0){
	foreach my $item_index (@remaining){
		if($recover == 1){
			restore_file("$item_index");
		}
		elsif(-e $item_index){  
			print "Deleting \"$item_index\"\n" if($verbose == 1);
			if(-d $item_index and $recursive == 0){
				print STDERR "Cannot remove directory \"$item_index\"\n";
				next;
			}
			elsif($warn == 1){
				next unless(get_response("Are you sure you want to delete file: \"$item_index\"") == 1);
			}
			delete_file("$item_index");
		}
		else{
			print "Cowardly refused to delete an imaginary file \"$item_index\"\n";
		}	
	}
}
else{
	print "Gallantly deleted abslutely nothing!\n";
	exit_routine();
}

exit_routine();

#####################################################
# SUBS WHICH MAKE IT SUNNY OUTSIDE
#####################################################

#####################################################
# MISL FUNCTIONS
#####################################################

sub usage{
	if(-e "/usr/share/man/man1/trsh.1.gz"){
		system("man trsh");
	}
	elsif(-e "$ENV{HOME}/.trsh.1.gz"){
		system("man $ENV{HOME}/.trsh.1.gz");
	}
	else{
		print $usage_string;
	}
}

sub get_response{
	my $message = shift;
	my $ret = 0;
	my $response = "n";
	print "$message (y/n):";
	$response = <STDIN>;
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
	my @temp = split(/\//, $item);
	my $item_name = pop(@temp);
	my $count = does_item_exist_in_history($item_name);
	push_to_history("$item_name\______$count");
	system("mv \"$item\" \"$trash/$item_name\______$count\"");
}

sub restore_file{
	my $item = shift;
	my @matched;
	if((! -e "$trash/${item}______0") or $regex_force == 1){ # Only match of file is not there.
		@matched = get_matched_files($item);
	}
	$matched[0] = $item if($#matched < 0); # Deffer error reporting if there are no matches.
	my $cwd = cwd();
	foreach my $entry (@matched){
		my $count = does_item_exist_in_history($entry);
		my $index = $count - 1;
		if($count == 0){
			# Nothing like that found. 
			print "$entry does not exist in the trash.\n";
		}
		else{
			print "Restoring file $entry...\n" if($verbose == 1);
			seek_and_destroy_in_history("$entry\______$index");
			system("mv \"$trash/${entry}______$index\" \"$cwd/$entry\"");
		}
	}
}

sub restore_last_file{
	my $cwd = cwd();
	my $item = pop_from_history();
	if($item eq "NULL______NULL"){
		print "Nothing to restore\n";
		exit_routine();
	}
	my $item_cmd = join(" ", split(/\\\s/,$item));
	if(-e "$trash/$item_cmd"){
		if($item =~ /(.+)______\d+$/){
			print "Restoring $1...\n";
			system("mv $trash/$item $cwd/$1");
		}
		else{
			print "ERROR! Something wierd happened. This should never happen\n";
		}
	}
	else{
		print "Something is wrong... $item was in the history, but not in the trash... Raise a bug\n";
	}
}

sub remove_from_trash{
	my $item = shift;
	my @matched;
	if((! -e "$trash/${item}______0") or $regex_force == 1){ # Only match if file does not exist.
		@matched = get_matched_files($item);
	}
	$matched[0] = $item if($#matched < 0); # Deffer error reporting if there are no matches.
	foreach my $entry (@matched){
		my $count = does_item_exist_in_history($entry);
		if($count == 0){
			# Nothing like that found. 
			print "$entry does not exist in the trash.\n";
		}
		else{
			if(get_response("Are you sure you want to remove $entry from the trash?") == 1){
				print "Removing $entry from the trash...\n" if($verbose == 1);
				for(my $i=0;$i<$count;$i++){
					seek_and_destroy_in_history("$entry\______$i");
					system("rm -rf \"$trash/$entry\______$i\"");
				}
			}
		}
	}
}


#############################################################
# BASIC HISTORY FUNCTIONS
#############################################################

sub push_to_history{
	my $item = shift;
	push(@hist_raw,$item);
	#make_history(@contents);
}

sub does_item_exist_in_history{
	my $item = shift;
	my $count = 0;
	foreach my $i (@hist_raw){
		# Now we do exact matching as we know that __0 has to come before __1
		# and there is no point of a regex match (Screws if a filename has a * in it)
		if($i eq "${item}______$count"){ 
			$count++;
		}
	}
	return $count;
}

sub pop_from_history{
	if($#hist_raw >= 0){
		my $last = pop(@hist_raw);
		return $last;
	}
	else{
		return "NULL______NULL";
	}
}

sub seek_and_destroy_in_history{
	my $item_name = shift;
	my $count = 0;
	foreach my $i (@hist_raw){
		if($i eq "$item_name"){
			my @hist_raw = @hist_raw[0..($count-1),($count+1)..$#hist_raw];
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

################# MISL TRASH FUNCTIONS ######################

sub get_size_human_readable{
	my $sz = `du -sh $trash`;
	close(SZ);
	chomp($sz);
	my @temp = split(/\s/, $sz);
	$sz = $temp[0];
	return $sz;
}

sub get_size{
	open SZ,"du -s $trash |";
	my $sz = <SZ>;
	close(SZ);
	chomp($sz);
	my @temp = split(/\s/, $sz);
	$sz = $temp[0] + 0;
	return $sz;
}

sub empty_trash{
	if(get_response("Are you sure you want to empty the trash?") == 1){
		system ("rm -rf $history");
		my @contents = split(/\n/, `ls -a $trash`);
		foreach my $entry (@contents){
			chomp($entry);
			if($entry ne "." and $entry ne ".."){
				system("rm -rf $trash/$entry");
			}
		}
		system ("touch $history");
	}
}

sub display_trash{
	my %cont;
	if($#hist_raw >= 0){
		my $sz = get_size_human_readable();
		print color("Yellow"),"Trash Size: $sz";
		print color("reset"), "\n";
		foreach my $entry (@hist_raw){
			if($entry =~ /(.+)______\d+$/){
				my $name = $1;
				if(defined($cont{$name})){
					$cont{$name} += 1;
				}
				else{
					$cont{$name} = 1;
				}
			}
		}
		foreach my $entry (keys %cont){
			my $file = "$trash/${entry}______0";
			if(-d $file){
				print_colored($cont{$entry},$entry,"Blue");
			}
			elsif(-x $file){
				print_colored($cont{$entry},$entry,"Green");
			}
			elsif(-l $file){
				print_colored($cont{$entry},$entry,"Cyan");
			}
			else{
				print_colored($cont{$entry},$entry,"reset");
			}
		}
	}
	else{
		print "Trash is empty!\n";
	}
}
sub print_colored{
	my $uncolored_text = shift;
	my $colored_text = shift;
	my $color = shift;
	print "($uncolored_text) ";
	print color($color), "$colored_text";
	print color("reset"), "\n";
}

sub dom{
	open DATE, "date +%d |";
	my $dt = <DATE>;
	close(DATE);
	$dt += 0;
	return $dt;
}

sub convert_regex{
	my $reg = shift;
	$reg =~ s/\./\\\./g;
	$reg =~ s/\*/\.\*/g; # Convert the * usage to perl regex form
	$reg =~ s/\?/\.\?/g; # Convert the ? usage to perl regex form
	$reg = qr/^(${reg})______\d+/; # Build the search regex.
	return $reg;
}

sub get_matched_files{
	my $reg = shift;
	$reg = convert_regex($reg);
	my %matched;
	foreach my $entry (@hist_raw){
		if($entry =~ $reg){
			$matched{$1} = 1;
		}
	}
	return keys(%matched);
}

sub exit_routine{
	my $error = shift;
	if(defined($error)){
		print STDERR $error;
	}
	make_history(@hist_raw);
	exit;
}

