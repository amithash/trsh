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
TRSH VERSION 2.3-222
AUTHOR: Amithash Prasad <amithash\@gmail.com>

USAGE: rm [OPTIONS]... [FILES]...
FILES: A list of files to recover or delete.
rm FILES just moves FILES to the trash. By default, directories are not deleted.

OPTIONS:

-u|--undo [FILES | REGEX]
Undo's a delete (Restores FILES or files matching REGEX from trash). 
Without arguments, the latest deleted file is restored.

-f|--force FILES
Instructs trsh to permanently delete FILES and completely bypass the trash
-ff or --force --force causes trsh to permanently delete files, and also pass
the force option on to rm.

-i|--interactively
Prompt the user before any operation.

-r|--recursive
Allows directories to be deleted.

-v|--verbose
Provide verbose output.

-e|--empty [FILES | REGEX]
Removed FILES or files matching REGEX from the trash (Permanently).
Without arguments, the trash is emptied. --force option causes trsh
to empty the trash without prompting the user.

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

-p|--perl-regex
This assumes that the passed regex is a perl-regex, and also turns on force-regex. If you do not
know what a perl-regex is, you do not need this.
\n";

# Pre-compiled regex's to improve performance and managability.
my $regex_file_count = qr/^(.+)______(\d+)$/;
my $regex_file_size  = qr/^(.+)::::::(\d+)$/;
my $regex_tar        = qr/\.tar$/;
my $regex_gz         = qr/\.gz$/;
my $regex_rpm        = qr/\.rpm$/;
my $regex_deb        = qr/\.deb$/;

# Global option varaibles.
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
my $perl_regex = 0;

Getopt::Long::Configure('bundling');

GetOptions( 'e|empty'          => \$empty, 
            'l|list'           => \$view,
	    'f|force+'	       => \$force,
	    'u|undo'	       => \$undo,
	    's|size'	       => \$size,
	    'help'             => \$help,
	    'h|human-readable' => \$human,
	    'i|interactive'    => \$warn,
	    'v|verbose'        => \$verbose,
	    'x|force-regex'    => \$regex_force,
	    'p|perl-regex'     => \$perl_regex,
    	    'r|recursive'      => \$recursive);

# Remaining args go into @remaining.
my @remaining = @ARGV;

# -h will be used as help if -s is not provided.
# That is -h option has two faces based on context.
if($size == 0 and $human == 1){
	$help = 1;
	$human = 0;
}

# If using perl_regex, force regex, as the user 
# has already communicated that he/she wants to
# use regular expressions.
if($perl_regex == 1){
	$regex_force = 1;
}

# If HOME is not set, die!
if (not defined $ENV{HOME}) {
    print "The environment variable HOME is not set\n";
    exit;
}

# trash is always in Home. and history is in trash.
my $trash = "$ENV{HOME}/" . trash();
my $history = "$trash/.history";

# Create Trash dir if it does not exist.
if( !(-e $trash) ) {
	print "Could not find the trash directory, creating it...\n";
        system("mkdir -p $trash") == 0 or print "Could not create Trash directory: $trash, aborting.\n";
	system("chmod 0700 $trash") == 0 or print "Could not change permissions for $trash, your trash is not secure.\n";
}

# Create history if it does not exist.
if( !(-e $history)){
	print "Could not find the history file. Creating it... \n";
	system("touch $history");
}

# If undo option is set and there are extra parameters,
# go into recover mode, else stay in undo mode.
if($undo == 1 and $#remaining >= 0){
	$recover = 1;
	$undo = 0;
}

# Hash associating size to files (Internal file names). 
# Read from the history file, if undefined, created 
# when needed (-s option is provided) and saved to the 
# history file on exit if defined.
my %file_size; 

# Hash associating the count of files to its actual name.
my %file_count;

# Array of files in the history (Internal file names).
my @hist_raw = get_history();

# Flag indicating that the history is changed. If set, the @hist_raw
# along with the %file_size is written to the history file. This avoids
# unnecessay writes to history when not needed.
my $dirty = 0;

# From now on, we catch signals because, the history is possibly corrupted.
# We will HAVE to exit cleanly.
$SIG{'INT'} = 'exit_routine';
$SIG{'TERM'} = 'exit_routine';

# If the view flag is on, ls the files
if($view == 1){
	display_trash();
	exit_routine();
}

# If size flag is on print size.
if($size == 1){
	my $sz = get_size($human);
	print color('YELLOW'), "$sz";
	print color('reset'), "\n";
	exit_routine();
}

# The help catcher.
if($help == 1){
	print $usage_string;
	exit_routine();
}

# Restore the last deleted file
if($undo > 0){
	restore_last_file();
	exit_routine();
}

# Empty or remove files from trash.
if($empty == 1){
	# If file names/regex's are provided, just
	# remove those from trash
	if($#remaining >= 0){
		foreach my $entry (@remaining){
			remove_from_trash($entry);
		}
	}
	# Else empty the whole trash.
	else{
		empty_trash();
	}
	exit_routine();
}

# If the force flag is on, then rm instead of moving to trash.
if($force > 0){
	my $cmd = "rm ";
	$cmd = $cmd . "-f " if($force > 1); # A double -f means pass -f on to rm.
	$cmd = $cmd . "-r " if($recursive == 1); # Pass the recursive flag to rm
	$cmd = $cmd . "-i " if($warn == 1); # Pass the interactive flag to rm
	$cmd = $cmd . "-v " if($verbose == 1); # Pass the verbose flag onto rm
	foreach my $this (@remaining){
		print "$cmd \"$this\"\n" if($verbose == 1);
		system("$cmd \"$this\"") == 0 or print "Could not delete $this\n";
	}
	exit_routine();
}

# Nothing else, try normal delete! Speak of the common use case in the last. :-)
if($#remaining >= 0){
	# Before continuing, check if the user wants a perl regex. if so get the 
	# file names matching the format.
	if($perl_regex == 1 and $recover == 0){
		print "WARNING: Deleting files:\n";
		my @files = ();
		foreach my $entry (@remaining){
			my ($path,$reg) = parentDir($entry);
			$reg = eval { qr/$reg/ };
			exit_routine("ERROR WITH REGEX:\n $@") if($@);
			my @AllFiles = split(/\n/,`ls $path`);
			foreach my $file (@AllFiles){
				if($file =~ $reg){
					push @files,"$path/$file";
					print "$path/$file\n";
				}
			}
		}
		@remaining = @files
	}

	foreach my $item (@remaining){
		if($recover == 1){
			restore_file("$item");
		}
		elsif(-e $item){  
			print "Deleting \"$item\"\n" if($verbose == 1);
			if(-d $item and $recursive == 0){
				print STDERR "Cannot remove directory \"$item\"\n";
				next;
			}
			elsif($warn == 1){
				next unless(get_response("Are you sure you want to delete file: \"$item\"") == 1);
			}
			delete_file("$item");
		}
		else{
			print "Cowardly refused to delete an imaginary file \"$item\"\n";
		}	
	}
}
else{
	print "Gallantly deleted abslutely nothing!\n";
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
	my $escaped = add_escapes($item);
	my @temp = split(/\//, $item);
	my $item_name = pop(@temp);
	my $escaped_name = add_escapes($item_name);
	my $count = does_item_exist_in_history($item_name);
	if(system("mv \"$escaped\" \"$trash/${escaped_name}______$count\"") == 0){
		push_to_history("$item_name\______$count");
	}
	else{
		print "Could not delete $item_name, check its permissions\n";
	}
}

sub restore_file{
	my $item = shift;
	my @matched;
	if((not defined $file_count{$item}) or $regex_force == 1){ # Only match of file is not there.
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
				chomp($inp);
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
			my $escaped_out = add_escapes($out);
			my $escaped_entry = add_escapes($entry);
			if(system("mv \"$trash/${escaped_entry}______$index\" \"$escaped_out\"") == 0){
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
	$item =~ $regex_file_count;
	restore_file($1);
}

sub remove_from_trash{
	my $item = shift;
	my $f = shift || $force;
	my @matched;
	if((not defined($file_count{$item})) or $regex_force == 1){ # Only match if file does not exist.
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
					my $escaped_entry = add_escapes($entry);
					# Remove entry from history only when system() was successful.
					system("rm -rf \"$trash/$escaped_entry\______$i\"") != 0 or 
					seek_and_destroy_in_history("$entry\______$i");
				}
			}
		}
	}
}

sub empty_trash{
	# Do not nag user if -f is set. 
	if($force > 0 or get_response("Are you sure you want to empty the trash?") == 1){
		foreach my $entry (keys %file_count){
			# Remove entries one by one, and send force (Parm 2 = 1), 
			# as the user has already given us his balls. :-)
			remove_from_trash($entry,1);
		}

		# Once complete, check for stray files.
		my @ls = stray_trash_files();
		my $list = join("\n",@ls);

		# Nag user if stray files exist.
		if($list ne ""){	
			print "Stray files still exist in trash. Here is its listing:\n$list\n";
			if(get_response("Are you sure you want to permanently delete them?") == 1){
				foreach my $entry (@ls){
					my $escaped_entry = add_escapes($entry);
					system("rm -rf \"$trash/$escaped_entry\"") == 0 or 
					print "Could not remove $trash/$entry. You need to remove it yourself.\n";
				}
			}
		}
	}
}

sub stray_trash_files{
	my $list = `ls -a $trash`;
	my @tmp = split(/\n/,$list);
	my @lst = ();
	# Add everything to the listing except ., .. and .history.
	foreach my $ent (@tmp){
		if($ent ne "." and $ent ne ".." and $ent ne ".history"){
			push @lst, $ent;
		}
	}
	return @lst;
}

sub display_trash{
	if($#hist_raw >= 0){
		my @sorted_files;
		my %fsz_dict;
		if($size == 1){
			my $sz;
			$sz = get_size($human);
			print color("Yellow"),"Total Trash Size: $sz";
			print color("reset"), "\n";

			# Generate a hash for each entry and its size.
			foreach my $entry (keys %file_count){
				$fsz_dict{$entry} = get_accumilated_size($entry) + 0;
			}
			# generate a sorted list based on descending order of size.
			@sorted_files = sort { $fsz_dict{$b} <=> $fsz_dict{$a};} keys(%fsz_dict);
		}
		else{
			@sorted_files = sort {lc($a) cmp lc($b)} (keys %file_count);
		}
		my $fsz = 0;
		foreach my $entry (@sorted_files){
			my $file = "$trash/${entry}______0";
			$fsz = $fsz_dict{$entry} if($size == 1);
			if(-d $file){
				print_colored($file_count{$entry},$entry,"Blue",$fsz);
			}
			elsif(-x $file){
				print_colored($file_count{$entry},$entry,"Green",$fsz);
			}
			elsif(-l $file){
				print_colored($file_count{$entry},$entry,"Cyan",$fsz);
			}
			elsif($entry =~ $regex_tar or $entry =~ $regex_gz or $entry =~ $regex_rpm or $entry =~ $regex_deb){
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

# SIDE EFFECTS: %file_count is populated
# 		%file_size  is populated for elements with size specified in history.
sub get_history{
	open HIST, "$history" or die "Could not open history\n";
	my @contents = split(/\n/, join("", <HIST>));
	my @raw_contents = ();
	foreach my $item (@contents){
		my $name;
		# Populate the file name, and the size hash
		if($item =~ $regex_file_size){
			$file_size{$1} = $2;
			$name = $1;
		}
		else{
			$name = $item;
		}
		push @raw_contents, $name;
		# populate the count hash.
		if($name =~ $regex_file_count){
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
	# Only do the conversion if using regular regex's, if the user wants 
	# regular perl regex's, then just build the regex and pass on.
	if($perl_regex == 0){
		$reg =~ s/\\/\\\\/g; # First of all escape the escape char!
		$reg =~ s/\./\\\./g; # . has a different meaning in perl regexes..
		$reg =~ s/\*/\.\*/g; # Convert the * usage to perl regex form
		$reg =~ s/\?/\.\?/g; # Convert the ? usage to perl regex form
		$reg =~ s/\[/\\\[/g; # [] has a different meaning in perl regex.
		$reg =~ s/\]/\\\]/g; 
		$reg =~ s/\(/\\\(/g; # () has a different meaning in perl regex
		$reg =~ s/\)/\\\)/g;
		$reg =~ s/\{/\\\{/g; # {} has a different meaning in perl regex
		$reg =~ s/\}/\\\}/g;
		$reg =~ s/\^/\\\^/g; # escape ^
		$reg =~ s/\$/\\\$/g; # escape $
		$reg =~ s/\|/\\\|/g; # escape |
		$reg = qr/^(${reg})______\d+$/; # Build the search regex.
		return $reg;
	}
	else{		
		# $ causes a problem as we use it here, so we just remove
		# a $ from the end if it exists.
		$reg =~ s/\$$//;
		my $regex = eval { qr/($reg)______\d+$/ };
		exit_routine("ERROR: Your regex doesn't seem valid : \n$@") if $@;
		return $regex;
	}
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

sub add_escapes{
	my $in = shift;
	$in =~ s/\\/\\\\/g; # back slash in file names cause problems.
	$in =~ s/\`/\\\`/g; # Back ticks in file names cause problems.
	$in =~ s/"/\\"/g;   # Double quites in file names cause problems.
	return $in;
}

sub parentDir{
	my $path = shift;
	my $reg;
	# If $path starts with /, it is an absolute path.
	if($path =~ /^\//){
		my @p = split(/\//,$path);
		$reg = pop @p;
		my $par = join("/",@p);
		return ($par,$reg);
	}
	# Else, if it still contains /, it is some path from the
	# current directory.
	elsif($path =~ /\//){
		my @p = split(/\//,$path);
		$reg = pop @p;
		my $par = join("/",@p);
		my $cwd = cwd();
		return ("$cwd/$par",$reg);
	}
	# Else it is a file in the current directory.
	else{
		my $cwd = cwd();
		return ($cwd,$path);
	}
}


############# THE EXIT ROUTINE ############################

# This is called whenever we want to exit, and also called
# when we are interrupted. If the dirty flag is set, history
# is written. If a parameter is passed, it prints it on stderr.
# and finally quits.
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

# Configure script changes the sub to the trash path here...
sub trash{ return ".Trash"; }

