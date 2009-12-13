#!/usr/bin/perl

##############################################################################
#			           TRSH 3,x                                  #
##############################################################################

##############################################################################
# Copyright 2008-2009 Amithash Prasad                                        *
#									     *
# this file is part of trsh.						     *
#                                                                            *
# trsh is free software: you can redistribute it and/or modify               *
# it under the terms of the GNU General Public License as published by       *
# the Free Software Foundation, either version 3 of the License, or          *
# (at your option) any later version.                                        *
#                                                                            *
# This program is distributed in the hope that it will be useful,            *
# but WITHOUT ANY WARRANTY; without even the implied warranty of             *
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the              *
# GNU General Public License for more details.                               *
#                                                                            *
# You should have received a copy of the GNU General Public License          *
# along with this program.  If not, see <http://www.gnu.org/licenses/>.      *
##############################################################################

use strict;
use warnings;
use File::Basename;
use Cwd 'abs_path'; 
use Getopt::Long;
use Fcntl;
use Term::ANSIColor;

##############################################################################
#			   Function Declarations                             #
##############################################################################

sub SetEnvirnment();
sub InHome($);
sub InDevice($);
sub GetDeviceList();
sub AbsolutePath($);
sub GetTrashDir($);
sub ListTrashContents();
sub GetTrashinfoPath($);
sub GetLatestDeleted();
sub PrintTrashinfo($);
sub Usage();
sub DeleteFile($);
sub EmptyTrash();
sub RemoveFromTrash($);
sub UndoLatestFiles();
sub UndoFile($);
sub GetLatestMatchingFile($);
sub GetUserPermission($);
sub FileTypeColor($);
sub SysMove($$);
sub SysMkdir($);
sub SysDelete($$);
sub AddEscapes($);
sub RemoveFromTrashRegex($);
sub DeleteRegex($);
sub UndoRegex($);
sub HumanReadable($);
sub DirSize($);
sub FileSize($);
sub EntrySize($);
sub PrintTrashSize();
sub ListRegexTrashContents($);

##############################################################################
#				Global Variables                             #
##############################################################################

# Parameters
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
my $no_color = 0;
my $human = 0;
my $regex = 0;
my $no_count = 0;

# Session information
my $user_name;
my $user_id;
my $home;
my $home_trash;
my $current_date;
my @dlist;

# Constants 
my $name_width = 50;
my $date_width = 20;
my $size_width = 10;

##############################################################################
#				   MAIN		                             #
##############################################################################

SetEnvirnment();

if($help > 0) {
	Usage();
}

if($view > 0) {
	if($regex > 0) {
		foreach my $reg (@ARGV) {
			ListRegexTrashContents($reg);
		}
		exit;
	}
	ListTrashContents();
	exit;
}

if($empty > 0) {
	if(scalar(@ARGV) == 0) {
		if(GetUserPermission("Completely empty the trash?") == 0) {
			exit;
		}
		EmptyTrash();
	} else {
		foreach my $file (@ARGV) {
			if($regex == 1) {
				RemoveFromTrashRegex($file);
				next;
			}
			if($force == 0 and GetUserPermission("Remove $file from the trash?") == 0) {
				next;
			}
			print "Removing $file from Trash\n" if($verbose > 0);
			RemoveFromTrash($file);
		}
	}
	exit;
}

if($undo > 0) {
	if(scalar(@ARGV) == 0) {
		UndoLatestFiles();
	} else {
		foreach my $file (@ARGV) {
			if($regex == 1) {
				UndoRegex($file);
				next;
			}
			print "Restoring $file from Trash\n" if($verbose > 0);
			UndoFile($file);
		}
	}
	exit;
}

if($size > 0) {
	PrintTrashSize();
	exit;
}

foreach my $file (@ARGV) {
	if($regex == 1) {
		DeleteRegex($file);
		next;
	}

	if($warn > 0 and GetUserPermission("Delete $file? ") == 0) {
		next;
	}
	print "Deleting $file from Trash\n" if($verbose > 0);
	DeleteFile($file);
}

##############################################################################
#		             Trash Functions                                 #
##############################################################################

##############################################################################
#		                Undo delete                                  #
##############################################################################

sub UndoLatestFiles()
{
	my @list = GetLatestDeleted();

	foreach my $entry (@list) {
		UndoTrashinfo($entry);
	}
}

sub UndoFile($)
{
	my $file	=	shift;
	my $entry = GetLatestMatchingFile($file);

	if(not defined($entry)) {
		print "$file does not exist in the Trash\n";
		return;
	}
	UndoTrashinfo($entry);
}

sub UndoTrashinfo($)
{
	my $entry	=	shift;

	my $from_path = $entry->{IN_TRASH_PATH};
	my $to_path   = $entry->{PATH};
	my $info_path = $entry->{INFO_PATH};

	if(-e $to_path) {
		if(GetUserPermission("Overwrite file $to_path?") == 0) {
			return;
		}
	}

	SysMkdir(dirname($to_path)) unless(-d dirname($to_path));

	my $success = SysMove($from_path, $to_path);
	if($success == 0) {
		SysDelete($info_path,"-f");
	}
}

sub UndoRegex($)
{
	my $reg		=	shift;
	my @List = GetRegexMatchingFiles($reg);
	foreach my $p (@List) {
		print "Restoring $p->{PATH}\n" if($verbose > 0);
		UndoTrashinfo($p);
	}
}

##############################################################################
#		         Removing from trash                                 #
##############################################################################

sub EmptyTrash()
{
	# Empty Home Trash
	print "Removing all files in home trash\n" if($verbose > 0);
	system("rm -rf $home_trash/info/*");
	system("rm -rf $home_trash/files/*");

	# Empty Devices Trash
	my @devs = GetDeviceList();
	foreach my $dev (@devs) {
		# Ignore these two as they go 
		# to the home trash
		if($dev eq "/" or $dev eq "/home") {
			next;
		}
		my $trsh = GetDeviceTrash($dev);
		unless(-d $trsh) {
			next;
		}
		print "Removing all files in trash for device: $dev\n" if($verbose > 0);
		system("rm -rf $trsh/info/*");
		system("rm -rf $trsh/files/*");
	}
}

sub RemoveFromTrash($)
{
	my $file	=	shift;

	my $entry = GetLatestMatchingFile($file);

	if(not defined($entry)) {
		print "$file does not exist in the Trash\n";
		return;
	}
	RemoveTrashinfo($entry);
}

sub RemoveFromTrashRegex($)
{
	my $reg		=	shift;
	my @List = GetRegexMatchingFiles($reg);
	foreach my $p (@List) {
		RemoveTrashinfo($p);
	}
}

##############################################################################
#		                  Deleting                                   #
##############################################################################

sub DeleteFile($)
{
	my $path	=	shift;
	$path = AbsolutePath($path);
	my $trsh = GetTrashDir($path);
	my $info_dir = "$trsh/info";
	my $name= basename($path);
	my $infoname;
	my $success = 0;

	unless(-e $path) {
		print "Cowardly refused to delete non-existant file $path\n";
		return;
	}

	if($path =~ /$trsh.*/) {
		print "Cannot delete $path in the trash. Please use -e to remove the file\n";
		return;
	}

	my $dirname = dirname($path);

	# Error on directories without -r flag.
	if(-d $path and $recursive == 0) {
		print "trsh: cannot remove `$path': Is a directory\n";
		return;
	}

	# Always ask for permission for write-protected files
	unless(-w $path) {
		my $what_file = FileTypeString($path);
		if(GetUserPermission("trsh: delete write-protected $what_file `$path'?") == 0) {
			return;
		}
	}
		
	# If dirname is not writable, you cannot delete this file.
	unless(-w $dirname) {
		print "trsh: cannot delete `$path': Permission denied\n";
		return;
	}


	# if force is on pass to rm.
	if($force > 0) {
		my $flag = "";
		$flag = $flag . "-r " if($recursive > 0);
		$flag = $flag . "-f " if($force > 1);
		SysDelete($path,$flag);
		return;
	}

	PutTrashinfo({
			PATH=>$path, 
			DATE=>$current_date, 
			NAME=>$name, 
			TRASH=>$trsh });

}

sub DeleteRegex($)
{
	my $reg		=	shift;
	my $dir = dirname($reg);
	if($dir eq ""){
		$dir = cwd();
	}
	$reg = PrepareRegex(basename($reg));
	foreach my $file (<$dir/*>) {
		if($file =~ $reg) {
			if($warn > 0 and GetUserPermission("Delete $file? ") == 0) {
				next;
			}
			print "Deleting $file from Trash\n" if($verbose > 0);
			DeleteFile($file);
		}
	}
}


##############################################################################
#		                  Listing                                    #
##############################################################################

sub ListTrashContents()
{
	my @List = GetTrashContents();
	ListArrayContents(\@List);
}

sub ListRegexTrashContents($)
{
	my $reg		=	shift;
	my @List = GetRegexMatchingFiles($reg);
	ListArrayContents(\@List);
}

sub ListArrayContents($)
{
	my $ref		=	shift;
	my @List = @{$ref};

	if(scalar(@List) == 0) {
		return;
	}

	printf("%-${name_width}s | %-${date_width}s | ", "Trash Entry", "Deletion Date");
	printf("%-${size_width}s | ", "Size") if($size > 0);
	printf("%s\n", "Restore Path");
	printf("%-${name_width}s | %-${date_width}s | ", "-----------", "-------------");
	printf("%-${size_width}s | ", "----") if($size > 0);
	printf("%s\n", "------------");

	foreach my $p (@List) {
		PrintTrashinfo($p);
	}
}

##############################################################################
#		                    Trash Size                               #
##############################################################################

sub PrintTrashSize()
{
	my $sz = GetTrashSize($home_trash);
	printf("%-40s | $sz\n", "Home Trash");
	my @devs = GetDeviceList();
	foreach my $dev (@devs) {
		next if($dev eq "/" or $dev eq "/home");
		$sz = GetTrashSize(GetDeviceTrash($dev));
		print("%-40s | $sz\n", "$dev Trash");
	}
}

sub GetTrashSize($)
{
	my $trash_path	=	shift;
	
	my $calculate_trash = 0;

	my $sz = "";

	my $info_mtime = (stat("$trash_path/info"))[9];
	my $metadata_mtime = (stat("$trash_path/metadata"))[9];

	# If info was modified after metadata
	if(! -e "$trash_path/metadata" or $info_mtime > $metadata_mtime) {
		$sz = DirSize($trash_path);
		open OUT, "+>$trash_path/metadata" or die "Could not open $trash_path/metadata for write\n";
		print OUT "[Cached]\n";
		print OUT "Size=$sz\n";
		close(OUT);
		$sz = HumanReadable($sz) if($human > 0);
	} else {
		open IN, "$trash_path/metadata" or die "Could not open $trash_path/metadata for read\n";
		while(my $line = <IN>) {
			chomp($line);
			if($line =~ /^Size=(\d+)$/) {
				$sz = $1;
				last;
			}
		}
		close(IN);
		if($sz eq "") {
			print "WARNING BAD metadata file. Deleting it\n";
			SysDelete("$trash_path/metadata","-f");
			$sz = 0;
			$sz = "0 B" if($human > 0);
		}
	}

	$sz = HumanReadable($sz) if($human > 0);

	return $sz;
}

##############################################################################
#		          Relating to files in trash                         #
##############################################################################

sub GetLatestMatchingFile($)
{
	my $file	=	shift;

	my @List = GetTrashContents();
	my @dates;
	my $search_path = 0;

	if($file =~ /\//) {
		$search_path = 1;
	}

	my @remove_list = ();

	foreach my $p (@List) {
		if($search_path == 1) {
			if($p->{PATH} eq $file) {
				push @remove_list, $p;
				push @dates, $p->{DATE};
			}
		} else {
			if($p->{NAME} eq $file) {
				push @remove_list, $p;
				push @dates, $p->{DATE};
			}
		}
	}

	@dates = sort @dates;
	my $date_to_remove = $dates[$#dates];
	my $return;
	foreach my $remove (@remove_list) {
		next if($remove->{DATE} ne $date_to_remove);
		$return  = $remove;
	}
	return $return;
}

sub GetRegexMatchingFiles($) {
	my $reg		=	shift;
	my $dir = "";
	if($reg =~ /\//) {
		$dir = dirname($reg);
	}
	$reg = PrepareRegex(basename($reg));
	my @List = GetTrashContents();
	my @Matched = ();
	foreach my $p (@List) {
		if($dir ne "") {
			my $d = dirname($p->{PATH});
			next if($dir ne "$d");
		}
		if($p->{NAME} =~ $reg) {
			push @Matched, $p;
		}
	}
	return @Matched;
}

sub GetTrashContents()
{
	my $trsh = $home_trash;
	my @List = ();
	push @List, GetSpecificTrashContents($trsh);
	my @devs = GetDeviceList();
	foreach my $dev (@devs) {
		next if($dev eq "/" or $dev eq "/home");
		push @List, GetSpecificTrashContents(GetDeviceTrash($dev));
	}
	return @List;
}

sub GetSpecificTrashContents($) {
	my $trash_dir	=	shift;
	my @list = <$trash_dir/info/*.trashinfo>;
	my @TrashList = ();
	foreach my $info (@list) {
		my $name = basename($info);
		if($name =~ /^(.+).trashinfo$/) {
			$name = $1;
		} else {
			# This should never happen
			print "REGEX ERROR!\n";
			return ();
		}
		my $p = GetTrashinfo($info);
		$p->{TRASH} = $trash_dir;
		$p->{IN_TRASH_NAME} = $name;
		$p->{INFO_PATH} = "$trash_dir/info/$name.trashinfo";
		$p->{IN_TRASH_PATH} = "$trash_dir/files/$name";
		if($trash_dir eq $home_trash) {
			$p->{DEV} = "HOME";
		} else {
			$p->{DEV} = InDevice($trash_dir);
			$p->{PATH} = $p->{DEV} . "/" . $p->{PATH};
		}
		$p->{NAME} = basename($p->{PATH});
		if($size > 0) {
			$p->{SIZE} = EntrySize($p->{IN_TRASH_PATH});
			$p->{SIZE} = HumanReadable($p->{SIZE}) if($human > 0);
		} else {
			$p->{SIZE} = 0;
		}
		push @TrashList, $p;
	}
	return @TrashList;
}

sub GetLatestDeleted()
{
	my @List  = GetTrashContents();
	my @dates = ();

	foreach my $p (@List) {
		push @dates, $p->{DATE};
	}

	if(scalar(@dates) == 0) {
		return ();
	}

	@dates = sort @dates;
	my $latest = $dates[$#dates];
	my @latest_info;
	foreach my $p (@List) {
		if($p->{DATE} eq $latest) {
			push @latest_info, $p;
		}
	}
	return @latest_info;
}

##############################################################################
#		            Trash info files                                 #
##############################################################################

sub GetTrashinfo($)
{
	my $trashinfo	=	shift;
	open IN, "$trashinfo" or return "ERROR: Could not open $trashinfo";
	my %ret;
	while(my $line = <IN>) {
		chomp($line);
		if($line =~ /^Path=(.+)$/) {
			my $path = $1;
			if(not defined($ret{PATH})) {
				$ret{PATH} = $path;
			}
		}
		if($line =~ /^DeletionDate=(.+)$/) {
			my $date = $1;
			if(not defined($ret{DATE})) {
				$ret{DATE} = $date;		
			}
		}
	}
	return \%ret;
}

sub PutTrashinfo($)
{
	my $entry	=	shift;
	my $success = 0;
	my $infoname;
	my $infodir = "$entry->{TRASH}/info";
	while($success == 0) {
		$infoname = GetInfoName($infodir, $entry->{NAME});
		$success = sysopen INFO, "$infodir/$infoname",  O_RDWR|O_EXCL|O_CREAT;
	}
	print INFO "[Trash Info]\n";
	my $infile_path = $entry->{PATH};
	if($entry->{TRASH} ne $home_trash) {
		my $dev = InDevice($entry->{PATH});
		if($entry->{PATH} =~ /^$dev\/(.+)$/) {
			$infile_path = $1;
		}
	}
	print INFO "Path=$infile_path\n";
	print INFO "DeletionDate=$current_date\n";

	close(INFO);

	my $in_trash_name;
	if($infoname =~ /^(.+)\.trashinfo$/) {
		$in_trash_name = $1;
	} else {
		# THIS SHOULD NEVER HAPPEN!
		print "REGEX FAILED!\n";
	}
	$success = SysMove($entry->{PATH}, "$entry->{TRASH}/files/$in_trash_name");
	if($success != 0) {
		print "Recovering from failed delete\n";
		SysDelete("$infodir/$infoname","-f");
	}
}

sub GetInfoName($$)
{
	my $info	=	shift;
	my $name	=	shift;

	my $postfix = "";
	my $infoname = $name . $postfix . ".trashinfo";
	my $info_path = "$info/$infoname";
	my $ind = 0;
	while(-e $info_path) {
		$ind++;
		$postfix = "-$ind";
		$infoname = $name . $postfix . ".trashinfo";
		$info_path = "$info/$infoname";
	}
	return $infoname;
}

sub PrintTrashinfo($)
{
	my $p		=	shift;

	# Check for invalid calls.
	if(not defined($p->{PATH})) {
		return;
	}

	my $name = sprintf("%-${name_width}s", $p->{NAME});
	my $date = sprintf("%-${date_width}s", $p->{DATE});
	my $path = $p->{PATH};
	my $sz = sprintf("%-${size_width}s", $p->{SIZE});
	if($no_color == 0) {
		print color(FileTypeColor($p->{IN_TRASH_PATH})), "$name";
		print color("reset"), " |";
		print color("Yellow"), " $date";
		print color("reset"), " |";
		if($size > 0) {
			print color("Red"), " $sz";
			print color("reset"), " |";
		}
		print color("reset"), " $path\n";
	} else {
		print "$name";
		print " | $date | ";
		print "$sz | " if($size > 0);
		print "$path\n";
	}
}

sub RemoveTrashinfo
{
	my $entry	=	shift;

	if($force == 0 and GetUserPermission("Remove $entry->{NAME} for trash?") == 0) {
		return;
	}
	SysDelete($entry->{IN_TRASH_PATH}, "-rf");
	SysDelete($entry->{INFO_PATH}, "-rf");
}


##############################################################################
#		        Trash directory location                             #
##############################################################################

sub GetDeviceTrash($)
{
	my $dev		=	shift;
	return GetTrashDir("$dev/DUMMY");
}

sub GetTrashDir($)
{
	my $path	=	shift;
	$path = AbsolutePath($path);
	if(InHome($path)) {
		return $home_trash;
	}
	my $dev = InDevice($path);
	if($dev eq "/" or $dev eq "/home") {
		return $home_trash;
	}
	my $trash = "$dev/.Trash";
	if(-d $trash and -k $trash and !-l $trash and -w $trash) {
		$trash = "$trash/$user_id";
		unless(-d "$trash") {
			mkdir "$trash";
			mkdir "$trash/files";
			mkdir "$trash/info";
			system("touch $trash/metadata");
		}
		return $trash;
	}
	$trash = "$dev/.Trash-$user_id";
	unless(-d $trash) {
		mkdir "$trash";
		mkdir "$trash/files";
		mkdir "$trash/info";
		system("touch $trash/metadata");
	}
	return $trash;
}


##############################################################################
#		        Mounted Device Handling                              #
##############################################################################

sub InDevice($)
{
	my $path	=	shift;
	my @matched;
	foreach my $device (@dlist) {
		if($path =~ /$device.+/) {
			push @matched, $device;
		}
	}
	my $outermost = "NULL";
	foreach my $match (@matched) {
		if($outermost eq "NULL") {
			$outermost = $match;
			next;
		}
		if($match =~ /$outermost.+/) {
			$outermost = $match;
		}
	}
	return $outermost;
}

sub GetDeviceList()
{
	my @list = split(/\n/,`df`);
	my @dlist;
	foreach my $e (@list) {
		my @tmp = split(/\s+/,$e);
		if($tmp[0] =~ /\/dev\/.+/) {
			push @dlist, $tmp[$#tmp];
		}
	}
	return @dlist;
}

##############################################################################
#		             Environment                                     #
##############################################################################

sub SetEnvirnment()
{
	$user_name = `id -un`;
	chomp($user_name);
	$user_id   = int(`id -u`);
	$home = $ENV{HOME};
	@dlist = GetDeviceList();
	unless(-d "$home/.local/share/Trash") {
		SysMkdir("$home/.local/share/Trash");
		SysMkdir("$home/.local/share/Trash/files");
		SysMkdir("$home/.local/share/Trash/info");
		system("touch $home/.local/share/Trash/metadata");
	}
	$home_trash = "$home/.local/share/Trash";
	my $x = `date --rfc-3339=seconds`;
	my @tmp = split(/ /, $x);
	my $date = $tmp[0];
	my $time = $tmp[1];
	@tmp = split(/-/,$time);
	$time = "$tmp[0]";
	$current_date = "${date}T$time";

	chomp($current_date);

	Getopt::Long::Configure('bundling');

	GetOptions( 
			'e|empty'	=> \$empty,       # IMPL
			'l|list'	=> \$view,        # IMPL
			'f|force+'	=> \$force,       # IMPL
			'r|recursive'	=> \$recursive,   # IMPL
			'u|undo'	=> \$undo,        # IMPL
			'help'		=> \$help,        # IMPL
			'i|interactive'	=> \$warn,        # IMPL
			'v|verbose'	=> \$verbose,     # IMPL
			'x|regex'       => \$regex,       # IMPL
			'no-color'	=> \$no_color,    # IMPL
			's|size'	=> \$size,        # IMPL
			'h|human-readable'=> \$human,     # IMPL
	) == 1 or Usage();

	$Term::ANSIColor::AUTORESET = 1;
}


##############################################################################
#		                   Help!                                     #
##############################################################################

sub Usage()
{
	print <<USAGE
TRSH VERSION 3.2-287
AUTHOR: Amithash Prasad <amithash\@gmail.com>

USAGE: rm [OPTIONS]... [FILES]...
FILES: A list of files to recover or delete.
rm FILES just moves FILES to the trash. By default, directories are not deleted.

OPTIONS:

-u|--undo [FILES]
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

-e|--empty [FILES]
Removed FILES or files matching REGEX from the trash (Permanently).
Without arguments, the trash is emptied. --force option causes trsh
to empty the trash without prompting the user.

-l|--list
Display the contents of the trash.

--no-color
An option for listing which turns of term colors.

--help
Displays this help and exits.

\n
USAGE
;
exit;
}

##############################################################################
#		           System Level Functions                            #
##############################################################################

sub SysMove($$)
{
	my $from = shift;
	my $to = shift;

	$from = AddEscapes($from);
	$to   = AddEscapes($to);

	my $ret = system("mv \"$from\" \"$to\"");
	return $ret;
}

sub SysMkdir($)
{
	my $dir = shift;

	$dir = AddEscapes($dir);

	my $ret = system("mkdir -p \"$dir\"");
	return $ret;
}

sub SysDelete($$)
{
	my $file   = shift;
	my $flags  = shift;

	$file = AddEscapes($file);

	my $ret = system("rm $flags \"$file\"");
	return $ret;
}

sub AddEscapes($)
{
	my $in = shift;
	$in =~ s/\\/\\\\/g; # back slash in file names cause problems.
	$in =~ s/\`/\\\`/g; # Back ticks in file names cause problems.
	$in =~ s/"/\\"/g;   # Double quotes in file names cause problems.
	return $in;
}

sub AbsolutePath($)
{
	my $in		=	shift;
	return abs_path($in);
}

sub InHome($)
{
	my $path	=	shift;

	if($path =~ /$home.+/) {
		return 1;
	}
	return 0;
}

sub FileTypeColor($)
{
	my $name	=	shift;

	my $ft = "";

	# XXX It would be nice to build this from
	# dircolors
	my %TypeColors = (
		"gz"	=>	"Red",
		"zip"	=>	"Red",
		"rpm"	=>	"Red",
		"deb"	=>	"Red",
		"bz2"	=>	"Red",
		"tar.gz"=>	"Red",
	);
	my $base = basename($name);
	if($base =~ /^(.+)-\d+$/) {
		$base = $1;
	}
	if($base =~ /^.+\.(.+)$/) {
		$ft = $1;
	}

	if(-l $name) {
		return "Cyan";
	} elsif(-d $name) {
		return "Blue";
	} elsif(-x $name) {
		return "Green";
	} elsif(defined($TypeColors{$ft})) {
		return $TypeColors{$ft};
	} else {
		return "reset";
	}
}

sub GetUserPermission($)
{
	my $question	=	shift;
	my $success = 0;
	my $ans;
	while($success == 0) {
		print "$question (y/n): ";
		$ans = <STDIN>;
		chomp($ans);
		if($ans eq "y") {
			return 1;
		}
		if($ans eq "n") {
			return 0;
		}
	}
}

sub FileTypeString($)
{
	my $path	=	shift;
	my $what;
	if(-d $path) {
		$what = "directory";
	} if(-f $path and -s $path == 0) {
		$what = "regular empty file";
	} else {
		$what = "regular file";
	}
	return $what;
}

sub DirSize($)
{
	my $path = shift;
	my $size = 0;
	my $fd;
	opendir($fd, $path) or die "$!\n";
	for my $item (readdir($fd)) {
		next if($item =~ /^\.\.?$/);
		my $path = "$path/$item";
		$size += ((-d $path) ? DirSize($path) : FileSize($path));
	}
	closedir($fd);

	return $size;
}

sub FileSize($)
{
	my $path = shift;
	return (-f $path) ? (stat($path))[7] : 0;
}

sub EntrySize($)
{
	my $path = shift;
	return (-d $path) ? DirSize($path) : FileSize($path);
}

sub HumanReadable($)
{
	my $sz = shift;
	my $kb = 1024;
	my $mb = 1024 * $kb;
	my $gb = 1024 * $mb;
	my $pb = 1024 * $gb;
	if($sz > $pb) {
		$sz = $sz / $pb;
		return sprintf("%.3f PB", $sz);
	} elsif($sz > $gb) {
		$sz = $sz / $gb;
		return sprintf("%.3f GB", $sz);
	} elsif($sz > $mb) {
		$sz = $sz / $mb;
		return sprintf("%.3f MB", $sz);
	} elsif($sz > $kb) {
		$sz = $sz / $kb;
		return sprintf("%.3f kB", $sz);
	} else {
		return sprintf("%.3f B", $sz);
	}
}

sub PrepareRegex($)
{
	my $reg		=	shift;
	$reg =~ s/\$$//;
	my $regex = eval { qr/($reg)$/ };
	if($@) {
		print "ERROR: Invalid regex: $reg\n$@\n";
		exit;
	}
	return $regex;
}
