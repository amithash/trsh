#!/usr/bin/perl

##############################################################################
#			           TRSH 3.x                                  #
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
use File::Spec;
use Cwd 'abs_path'; 
use Getopt::Long;
use Fcntl;
use Term::ANSIColor;
use Term::ReadKey;

my $VERSION = "3.6-9";

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
sub Version();
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
sub Crop($$);
sub PrintTrashSizeLine($$);
sub PrintColored($$);

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
my $color = 1;
my $ldate = 1;
my $human = 0;
my $regex = 0;
my $no_count = 0;
my $vers = 0;
my $permanent = 0;

# Session information
my $user_name;
my $user_id;
my $home;
my $home_trash;
my $current_date;
my @dlist;
my $name_width;
my $date_width;
my $size_width;
my $path_width;
my $sz_width;
my $dev_width;
my %TypeColors;
my %AttrColors;

# Constants 
my $name_width_perc = 25;
my $date_width_perc = 25;
my $size_width_perc = 10;
my $path_width_perc = 40;
my $sz_width_perc   = 20;
my $dev_width_perc  = 80;

##############################################################################
#				   MAIN		                             #
##############################################################################

SetEnvirnment();

if($help > 0) {
	Usage();
}

if($vers > 0) {
	Version();
}

# List specific files
if($view > 0 and $regex > 0 and scalar(@ARGV) > 0) {
	foreach my $reg (@ARGV) {
		ListRegexTrashContents($reg);
	}
	exit;
}

if($view > 0) {
	ListTrashContents();
	exit;
}

# Empty trash
if($empty > 0 and scalar(@ARGV) == 0) {
	EmptyTrash();
	exit;
}

# Remove specific files from trash
if($empty > 0) {
	foreach my $file (@ARGV) {
		if($regex == 1) {
			RemoveFromTrashRegex($file);
			next;
		}
		RemoveFromTrash($file);
	}
	exit;
}

# Undo Latest file.
if($undo > 0 and scalar(@ARGV) == 0) {
	UndoLatestFiles();
	exit;
}

# Undo specific files
if($undo > 0) {
	foreach my $file (@ARGV) {
		if($regex == 1) {
			UndoRegex($file);
			next;
		}
		UndoFile($file);
	}
	exit;
}

# Trash size
if($size > 0) {
	PrintTrashSize();
	exit;
}

# Error Condition: no arguments
if(scalar(@ARGV) == 0) {
	print "$0 (Aliased to rm): missing operand\n";
	print "Try `$0 (Or rm) --help' for more information.\n";
	exit;
}

# Delete files
foreach my $file (@ARGV) {
	if($regex == 1) {
		DeleteRegex($file);
		next;
	}
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
	if($force == 0 and GetUserPermission("Completely empty the trash?") == 0) {
		exit;
	}

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

	if(not(-l $path) and not(-e $path)){
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


	if($warn > 0 and GetUserPermission("Delete $path? ") == 0) {
		next;
	}

	# Always ask for permission for write-protected files
	unless(-w $path) {
		my $what_file = FileTypeString($path);
		if($force == 0 and GetUserPermission("trsh: delete write-protected $what_file `$path'?") == 0) {
			return;
		}
	}

	# If dirname is not writable, you cannot delete this file.
	unless(-w $dirname) {
		print "trsh: cannot delete `$path': Permission denied\n";
		return;
	}


	# if force is on pass to rm.
	if($permanent > 0) {
		my $flag = "";
		$flag = $flag . "-r " if($recursive > 0);
		$flag = $flag . "-f " if($force > 0);
		SysDelete($path,$flag);
		print "Permanently removed: `$path'\n" if($verbose > 0);
		return;
	}

	PutTrashinfo({
			PATH=>$path, 
			DATE=>$current_date, 
			NAME=>$name, 
			TRASH=>$trsh });

	print "Deleted: `$path'\n" if($verbose > 0);
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
	my %dates;
	foreach my $p (@List) {
		$dates{$p->{DATE}} = $p;
	}

	printf("%-${name_width}s| ", "Trash Entry");
	printf("%-${date_width}s| ", "Deletion Date") if($ldate > 0);
	printf("%-${size_width}s| ", "Size") if($size > 0);
	printf("%s\n", "Restore Path");
	printf("%-${name_width}s| ", "-----------");
	printf("%-${date_width}s| ", "-------------") if($ldate > 0);
	printf("%-${size_width}s| ", "----") if($size > 0);
	printf("%s\n", "------------");

	foreach my $date (sort keys %dates) {
		my $p = $dates{$date};
		PrintTrashinfo($p);
	}
}

##############################################################################
#		                    Trash Size                               #
##############################################################################

sub PrintTrashSize()
{
	my $sz  = GetTrashSize($home_trash);

	PrintTrashSizeLine("Home Trash", $sz);

	my @devs = GetDeviceList();
	foreach my $dev (@devs) {
		next if($dev eq "/" or $dev eq "/home");
		$sz = GetTrashSize(GetDeviceTrash($dev));
		PrintTrashSizeLine("$dev Trash", $sz);
	}
}

sub PrintTrashSizeLine($$)
{
	my $dev		=	shift;
	my $sz		=	shift;

	my $sz_color = SizeColor($sz);

	$dev = Crop(sprintf("%-${dev_width}s", $dev), $dev_width);
	$sz  = Crop(sprintf("%-${sz_width}s",$sz), $sz_width);

	PrintColored("$sz", $sz_color);
	PrintColored("| ", "reset");
	PrintColored("$dev\n", "reset");
}

sub SizeColor($)
{
	my $sz		=	shift;
	if($human == 0) {
		$sz = HumanReadable($sz);
	}
	if($sz =~ /P/) {
		return "Red";
	} elsif($sz =~ /T/) {
		return "Red";
	} elsif($sz =~ /G/) {
		return "Red";
	} elsif($sz =~ /M/) {
		return "Blue";
	} elsif($sz =~ /k/) {
		return "Cyan";
	} else {
		return "Green";
	}
	return "reset";
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
			print "WARNING BAD metadata file. Fixing it\n";
			SysDelete("$trash_path/metadata","-f");
			return GetTrashSIze($trash_path);
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
	my $name = Crop(sprintf("%-${name_width}s", $p->{NAME}), $name_width);
	my $date = Crop(sprintf("%-${date_width}s", $p->{DATE}), $date_width);
	my $path = Crop(sprintf("%-${path_width}s", $p->{PATH}), $path_width);
	my $sz   = Crop(sprintf("%-${size_width}s", $p->{SIZE}), $size_width);

	PrintColored("$name", FileTypeColor($p->{IN_TRASH_PATH}));
	PrintColored(" |", "reset");
	if($ldate > 0) {
		PrintColored(" $date", "Yellow");
		PrintColored(" |", "reset");
	}
	if($size > 0) {
		my $sz_color = SizeColor($p->{SIZE});
		PrintColored(" $sz", SizeColor($p->{SIZE}));
		PrintColored(" |", "reset");
	}
	PrintColored(" $path\n", "reset");
}

sub RemoveTrashinfo
{
	my $entry	=	shift;

	if($force == 0 and GetUserPermission("Remove $entry->{NAME} for trash?") == 0) {
		return;
	}
	print "Removing from trash: `$entry->{PATH}'\n" if($verbose > 0);
	SysDelete($entry->{IN_TRASH_PATH}, "-rf");
	SysDelete($entry->{INFO_PATH}, "-rf");
}

sub UndoTrashinfo($)
{
	my $entry	=	shift;

	my $from_path = $entry->{IN_TRASH_PATH};
	my $to_path   = $entry->{PATH};
	my $info_path = $entry->{INFO_PATH};

	if($warn > 0 and GetUserPermission("Restore $to_path?") == 0) {
		return;
	}

	if(-e $to_path) {
		if($force == 0 and GetUserPermission("Overwrite file $to_path?") == 0) {
			return;
		}
	}

	SysMkdir(dirname($to_path)) unless(-d dirname($to_path));


	my $success = SysMove($from_path, $to_path);
	if($success == 0) {
		SysDelete($info_path,"-f");
	} else {
		print "Error restoring $to_path\n";
		return;
	}
	print "Restored: $to_path\n" if($verbose > 0);
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
			'e|empty'	  => \$empty,
			'l|list'	  => \$view,
			'f|force+'	  => \$force,
			'r|recursive'	  => \$recursive,
			'R|recursive'	  => \$recursive,
			'u|undo'	  => \$undo,
			'help'		  => \$help,
			'i|interactive'	  => \$warn,
			'p|permanent'	  => \$permanent,
			'v|verbose'	  => \$verbose,
			'x|regex'         => \$regex,
			'color!'	  => \$color,
			'date!'		  => \$ldate,
			's|size'	  => \$size,
			'h|human-readable'=> \$human,
			'version'         => \$vers,
	) == 1 or Usage();

	$Term::ANSIColor::AUTORESET = 1;

	if($force > 0) {
		$warn = 0;
	}

	# Allow -h to stand for help.
	if($size == 0 and $human > 0) {
		$human = 0;
		$help = 1;
	}

	# Do not reserve space without -s option.
	if($size == 0) {
		$path_width_perc += $size_width_perc;
		$size_width_perc = 0;
	}

	if($ldate == 0) {
		$name_width_perc += $date_width_perc;
		$date_width_perc = 0;
	}

	my $screen_width = (GetTerminalSize())[0];

	# Adjust for each character '| '
	$screen_width = $screen_width - 4;

	$name_width = int($screen_width * $name_width_perc / 100);
	$date_width = int($screen_width * $date_width_perc / 100);
	$size_width = int($screen_width * $size_width_perc / 100);
	$path_width = int($screen_width * $path_width_perc / 100);

	if($ldate != 0 and $date_width > 22) {
		my $overflow = $date_width - 22;
		$name_width += (int($overflow / 2));
		$path_width += ($overflow - int($overflow / 2));
		$date_width = 22;
	}
	if($size != 0 and $size_width > 15) {
		$path_width += ($size_width - 15);
		$size_width = 15;
	}

	$sz_width   = int($screen_width * $sz_width_perc   / 100);
	$dev_width  = int($screen_width * $dev_width_perc  / 100);

	if($sz_width > 15) {
		$dev_width += ($sz_width - 15);
		$sz_width = 15;
	}

	# FileTypeColors
	InitFileTypeColors();
}


##############################################################################
#		                   Help!                                     #
##############################################################################

sub Version()
{
	print "TRASH VERSION: $VERSION\n";
	exit;
}

sub Usage()
{
	print <<USAGE
TRSH VERSION $VERSION
AUTHOR: Amithash Prasad <amithash\@gmail.com>

USAGE: rm [OPTIONS]... [FILES]...
FILES: A list of files to recover or delete.
rm FILES just moves FILES to the trash. By default, directories are not deleted.

OPTIONS:

-u|--undo [FILES]
Undo's a delete (Restores FILES or files matching REGEX from trash). 
Without arguments, the latest deleted file is restored.

-p|--permanent FILES
Instructs trsh to permanently delete FILES and completely bypass the trash

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

-f|--force
Forces any operation:
	deletion   : overrides -i and does not prompt the user for any action.
	             with -p passes the -f flag to /bin/rm
	restore    : will force overwrites of files and will not ask for user permission.
	empty file : will not ask the user's permission for each file.
	empty trash: will not ask for confirmation from the user.

-l|--list
Display the contents of the trash.

--color (Default)
Print listings (Refer -l) using the terminal's support for colored text.
--nocolor
Print listings normally without color.

--date (Default)
Print the deletion date with the trash listing (-l)

--nodate
Do not print the deletion date with the trash listing (-l)

-x|--regex
Considers input as perl regex rather than names or paths.
rm -x REGEX # Delete files matching REGEX
rm -ux REGEX # Recover files in trash matching regex.
rm -ex REGEX # Remove files in trash matching regex.
rm -lx REGEX # List trash contents matching regex.
Note REGEX can be expressed multiple times.
REGEX can be a path with the file name being a regex.
example: "/home/user/test_\\d"

-s|--size
Display the size in bytes of the trash. 
If used along with -l, the trash listing will also display each file's size.

-h|--human-readable
If used along with -s, the file size displayed will be human readable
(KB, MB etc) rather than in bytes.

--help
Displays this help and exits.

Please read the README for more information
USAGE
;
exit;
}

##############################################################################
#		    Coloring and Printing Functions                          #
##############################################################################

sub PrintColored($$) 
{
	my $string	=	shift;
	my $col		=	shift;
	if($color > 0) {
		print colored($string,$col);
	} else {
		print "$string"
	}
}

sub InitFileTypeColors()
{
	my %Num2Col = (
		30	=>	"Black",
		31	=>	"Red",
		32	=>	"Green",
		33	=>	"Yellow",
		34	=>	"Blue",
		35	=>	"Magenta",
		36	=>	"Cyan",
		37	=>	"White",
	);
	my @dircolors = split(/\n/,`dircolors -p`);
	foreach my $entry (@dircolors) {
		next if($entry =~ /^\s*#/); # Ignore comments
		next if($entry =~ /^TERM/); # Ignore terminals
		# Remove Trailing comments.
		if($entry =~ /([^#]+)\s*#.+$/) {
			$entry = $1;
		}
		if($entry =~ /\.(.+) (\d+)[;:](\d+)$/)  {
			my $ft  = $1;
			my $att = int($2);
			my $fg  = int($3);
			if($fg >= 30 and $fg <= 37) {
				# Valid Col
				$TypeColors{$ft} = $Num2Col{$fg};
			}
			next;
		}
		if($entry =~ /(.+)\s+(\d\d);(\d\d)/)  {
			my $ft  = $1;
			my $att = int($2);
			my $fg  = int($3);
			if($fg >= 30 and $fg <= 37) {
				# Valid Col
				$AttrColors{$ft} = $Num2Col{$fg};
			}
			next;
		}
	}
}


sub Crop($$)
{
	my $string	=	shift;
	my $width	=	shift;
	$width = $width - 2;
	if(length($string) <= $width) {
		return $string;
	}
	my @tmp = split(//,$string);
	my $ret = join("", @tmp[0..$width]);
	return $ret;
}

sub HumanReadable($)
{
	my $sz = shift;
	my $kb = 1024;
	my $mb = 1024 * $kb;
	my $gb = 1024 * $mb;
	my $tb = 1024 * $gb;
	my $pb = 1024 * $tb;
	if($sz > $pb) {
		$sz = $sz / $pb;
		return sprintf("%.3f PB", $sz);
	} elsif($sz > $tb) {
		$sz = $sz / $tb;
		return sprintf("%.3f TB", $sz);
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


##############################################################################
#		            File Type Functions                              #
##############################################################################

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

sub FileTypeColor($)
{
	my $name	=	shift;

	my $ft = "";

	my $base = basename($name);
	if($base =~ /^(.+)-\d+$/) {
		$base = $1;
	}
	if($base =~ /^.+\.(.+)$/) {
		$ft = $1;
	}

	if(-l $name) {
		return $AttrColors{LINK};
	} elsif(-d $name) {
		return $AttrColors{DIR};
	} elsif(-x $name) {
		return $AttrColors{EXEC};
	} elsif(defined($TypeColors{$ft})) {
		return $TypeColors{$ft};
	} else {
		return "reset";
	}
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
	return File::Spec->rel2abs( $in ) ;
}

sub InHome($)
{
	my $path	=	shift;

	if($path =~ /$home.+/) {
		return 1;
	}
	return 0;
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

