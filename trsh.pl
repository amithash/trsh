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
use Term::ANSIColor;
use Cwd;
use POSIX 'floor';
$Term::ANSIColor::AUTORESET = 1;


my $usage_string = "
TRSH VERSION 2.1.148

USAGE: rm [OPTIONS]... [FILES]...

FILES: A list of files to recover or delete.

OPTIONS:

-u|--undo [FILES | REGEX]
Undo's a delete (Restores FILES or files matching REGEX from trash). 
Without arguments, the latest deleted file is restored.

-f|--force FILES
Instructs trsh to permanently delete FILES and completely bypass the trash

-i|--interactively
Prompt the user before any operation.

-r|--recursive
Allows directories to be deleted.

-v|--verbose
Provide verbose output.

-e|--empty [FILES | REGEX]
Removed FILES or files matching REGEX from the trash (Permanently).
Without arguments, the trash is emptied.

-l|--list
Display the contents of the trash.

-s|--size
This displays the size of the Trash directory. (-s with -l makes the listing contain 
sizes of individual entries in the trash)

-h|--human-readable
If provided with the -s option, the size will be printed in a human readable form.

--help
Displays this help and exits.

-x|--force-regex
This forces trsh to assume that the provided arguments are regex's. (Not needed, refer the README for more)

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
my $human = 0;

Getopt::Long::Configure('bundling');

GetOptions( 'e|empty'          => \$empty, 
            'l|list'           => \$view,
	    'f|force'	       => \$force,
	    'u|undo'	       => \$undo,
	    's|size'	       => \$size,
	    'help'             => \$help,
	    'h|human-readable' => \$human,
	    'i|interactive'    => \$warn,
	    'v|verbose'        => \$verbose,
	    'x|force-regex'    => \$regex_force,
    	    'r|recursive'      => \$recursive);

my @remaining = @ARGV;

if (not defined $ENV{HOME}) {
    print "The environment variable HOME is not set\n";
    exit;
}
my $trash = "$ENV{HOME}/" . trash();
my $history = "$trash/.history";


if( !(-e $trash) ) {
	print "Could not find the trash directory, creating it...\n";
        system("mkdir -p $trash");
	system("chmod 0700 $trash");
}
if( !(-e $history)){
	print "Could not find the history file. Creating it... \n";
	system("touch $history");
}
if($undo == 1 and $#remaining >= 0){
	$recover = 1;
	$undo = 0;
}

my %file_size;
my %file_count;
my @hist_raw = get_history();
my $dirty = 0;

# From now on, we catch signals because, the history is corrupted.
# We will HAVE to exit cleanly.

$SIG{'INT'} = 'exit_routine';
$SIG{'TERM'} = 'exit_routine';

# If the view flag is on, ls the files
if($view == 1){
	display_trash();
	exit_routine();
}

if($size == 1){
	my $sz = get_size($human);
	print "$sz\n";
	exit_routine();
}

if($help == 1){
	print $usage_string;
	exit_routine();
}

# Restore the last deleted file
if($undo > 0){
	restore_last_file();
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

# If the force flag is on, then rm instead of moving to trash.
if($force == 1){
	my $cmd = "rm ";
	$cmd = $cmd . "-r " if($recursive == 1); # Pass the recursive flag to rm
	$cmd = $cmd . "-i " if($warn == 1); # Pass the interactive flag to rm
	foreach my $this (@remaining){
		print "Removing \"$this\" permanently\n" if($verbose == 1);
		system("$cmd \"$this\"") == 0 or print "Could not delete $this\n";
	}
	exit_routine();
}

# Nothing else, try normal delete! :-) Speak of the common use case in the last.
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
# USER FUNCTIONS
#####################################################

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

sub print_colored{
	my $uncolored_text = shift;
	my $colored_text = shift;
	my $color = shift;
	my $size_rec = shift;
	print "($uncolored_text) ";
	print color($color), "$colored_text";
	if($size == 1){
		my $sz = $size_rec;
		if($human == 1){
			$sz = kb2hr($size_rec);
		}
		print color("Yellow"), " $sz";
	}
	print color("reset"), "\n";
}


#############################################################
# HIGH LEVEL TRASH FUNCTIONS
#############################################################

sub delete_file{
	my $item = shift;
	my @temp = split(/\//, $item);
	my $item_name = pop(@temp);
	my $count = does_item_exist_in_history($item_name);
	if(system("mv \"$item\" \"$trash/$item_name\______$count\"") == 0){
		push_to_history("$item_name\______$count");
	}
	else{
		print "Could not delete $item_name, check its permissions\n";
	}
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
			my $out = "$cwd/$entry";
			print "Restoring file $entry...\n" if($verbose == 1);
			while(-e "$out"){
				print "$out already exists. Here are your options:\n";
				print "(1) Overwrite the file\n";
				print "(2) Rename new file\n";
				print "Your choice: (1/2) [1]:";
				my $inp = <STDIN>;
				$inp = 1 if($inp eq "");
				$inp += 0;
				if($inp == 1){
					system("rm -rf \"$out\"");
				}
				else{
					print "Enter the new name of the file: ";
					my $name = <STDIN>;
					chomp($name);
					$out = "$cwd/$name";
				}
			}

			if(system("mv \"$trash/${entry}______$index\" \"$out\"") == 0){
				seek_and_destroy_in_history("$entry\______$index");
			}
			else{
				print "Could not restore $entry. Check if you have write permissions in $cwd\n";
			}
		}
	}
}

sub restore_last_file{
	my $item = pop_from_history();
	my $name;
	if($item eq "NULL______NULL"){
		print "Nothing to restore!\n";
		exit;
	}
	push_to_history($item);
	$item =~ /(.+)______\d+/;
	restore_file($1);
}

sub remove_from_trash{
	my $item = shift;
	my $f = shift;
	$f = $force unless(defined($f));
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
			if($f == 1 or get_response("Are you sure you want to remove $entry from the trash?") == 1){
				print "Removing $entry from the trash...\n" if($verbose == 1);
				for(my $i=0;$i<$count;$i++){
					system("rm -rf \"$trash/$entry\______$i\"") != 0 or seek_and_destroy_in_history("$entry\______$i");
				}
			}
		}
	}
}

sub empty_trash{
	if(get_response("Are you sure you want to empty the trash?") == 1){
		foreach my $entry (keys %file_count){
			remove_from_trash($entry,1);
		}
		my $list = `ls -a $trash`;
		my @tmp = split(/\n/,$list);
		my @ls;
		foreach my $ent (@tmp){
			if($ent ne "." and $ent ne ".." and $ent ne ".history"){
				push @ls, $ent;
			}
		}
		$list = join("\n",@ls);
		if($list ne ""){	
			print "Stray files still exist in trash. Here is its listing:\n$list\n";
			if(get_response("Are you sure you want to permanently delete them?") == 1){
				foreach my $entry (@ls){
					system("rm -rf \"$trash/$entry\"") == 0 or print "Could not remove $trash/$entry. You need to remove it yourself.\n";
				}
			}
		}
	}
}

sub display_trash{
	if($#hist_raw >= 0){
		if($size == 1){
			my $sz;
			$sz = get_size($human);
			print color("Yellow"),"Total Trash Size: $sz";
			print color("reset"), "\n";
		}
		my $fsz = 0;
		foreach my $entry (keys %file_count){
			my $file = "$trash/${entry}______0";
			$fsz = get_accumilated_size($entry) if($size == 1);
			if(-d $file){
				print_colored($file_count{$entry},$entry,"Blue",$fsz);
			}
			elsif(-x $file){
				print_colored($file_count{$entry},$entry,"Green",$fsz);
			}
			elsif(-l $file){
				print_colored($file_count{$entry},$entry,"Cyan",$fsz);
			}
			elsif($entry =~ /\.tar$/ or $entry =~ /\.gz$/){
				print_colored($file_count{$entry},$entry,"Red",$fsz);
			}
			else{
				print_colored($file_count{$entry},$entry,"reset",$fsz);
			}
		}
	}
	else{
		print "Trash is empty!\n";
	}
}


#############################################################
# BASIC HISTORY FUNCTIONS
#############################################################

sub push_to_history{
	my $item = shift;
	push(@hist_raw,$item);
	$dirty = 1;
}

sub does_item_exist_in_history{
	my $item = shift;
	my $count = 0;
	if(defined($file_count{$item})){
		$count = $file_count{$item};
	}
	return $count;
}

sub pop_from_history{
	if($#hist_raw >= 0){
		my $last = pop(@hist_raw);
		$dirty = 1;
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
			@hist_raw = @hist_raw[0..($count-1),($count+1)..$#hist_raw];
			$dirty = 1;
			last;
		}
		$count++;
	}
}

# SIDE EFFECTS: file_count hash is populated
# 		if the file size exists in history, %file_size is also populated.
sub get_history{
	open HIST, "$history" or die "Could not open history\n";
	my @contents = split(/\n/, join("", <HIST>));
	my @raw_contents = ();
	foreach my $item (@contents){
		my $name;
		# Populate the file name, and the size hash
		if($item =~ /^(.+)::::::(\d+)$/){
			$file_size{$1} = $2;
			$name = $1;
		}
		else{
			$name = $item;
		}
		push @raw_contents, $name;
		# populate the count hash.
		if($name =~ /^(.+)______(\d+)$/){
			if(not defined($file_count{$1})){
				$file_count{$1} = 1;
			}
			else{
				$file_count{$1} += 1;
			}
		}
		else{
			print "Something Bad happened in get_history... Raise a bug\n";
		}
	}
	close(HIST);
	return @raw_contents;
}

sub make_history{
	my @contents = @_;
	system("rm $history");
	open HIST,"+>$history" or die "Could not create history\n";
	my @new_contents = ();
	foreach my $item (@contents){
		my $line;
		if(defined($file_size{$item})){
			$line = "$item\::::::$file_size{$item}";
		}
		else{
			$line = "$item";
		}
		push @new_contents, $line;
	}
	my $h = join("\n",@new_contents);
	print HIST "$h";
	close(HIST);
}


############### FUNCTIONS RELATED TO SIZE ###################

sub get_size{
	my $h = shift;
	my $sz = 0;
	foreach my $entry (@hist_raw){
		if(not defined($file_size{$entry})){
			$file_size{$entry} = get_file_size("$trash/$entry");
			$dirty = 1;
		}
		$sz += $file_size{$entry};
	}
	$sz = kb2hr($sz) if($h == 1);
	return $sz;

}

sub get_file_size{
	my $file = shift;
	my @tmp = split /\s/, `du -s "$file"`;
	return $tmp[0] + 0;
}

sub get_accumilated_size{
	my $file = shift;
	my $count = $file_count{$file};
	my $sz = 0;
	for(my $i=0;$i<$count;$i++){
		my $entry = "${file}______$i";
		if(not defined($file_size{$entry})){
			$file_size{$entry} = get_file_size("$trash/$entry");
			$dirty = 1;
		}
		$sz += $file_size{$entry};
	}
	return $sz;
}

sub kb2hr{
	my $kb = shift;
	$kb = $kb * 1.0;
	my $multi = 0;
	while($kb >= 1024){
		$multi++;
		$kb = $kb / 1024;
	}
	my $kbf = sprintf("%.1f",$kb);
	my $mstr = exp2str($multi);
	my $ret = "${kbf} ${mstr}";
	return $ret;
}

sub exp2str{
	my $multi = shift;
	if($multi == 0){
		return "KB";
	}
	elsif($multi == 1){
		return "MB";
	}
	elsif($multi == 2){
		return "GB";
	}
	elsif($multi == 3){
		return "TB";
	}
	else{
		my $exp = ($multi+1)*3;
		return "10^${exp}B";
	}
}	

############## USER REGEX FUNCTIONS ######################

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

############# THE EXIT ROUTINE ############################

sub exit_routine{
	my $error = shift;
	if(defined($error)){
		print STDERR $error;
	}
	if($dirty == 1){
		make_history(@hist_raw);
	}
	exit;
}

# Configure script creates the sub to the trash path here...
sub trash{ return ".Trash"; }

