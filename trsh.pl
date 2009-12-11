#!/usr/bin/perl

##############################################################################################
#					TRSH - 3.x					     #
##############################################################################################

#*************************************************************************
# Copyright 2009 Amithash Prasad                                         *
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
use File::Basename;
use Cwd 'abs_path'; 
use Getopt::Long;
use Fcntl;
use Term::ANSIColor;
$Term::ANSIColor::AUTORESET = 1;

# DECLARATIONS
sub SetEnvirnment();
sub InHome($);
sub InDevice($);
sub GetDeviceList();
sub AbsolutePath($);
sub GetTrashDir($);
sub ListTrashContents();
sub GetTrashinfoPath($);
sub GetLatestDeleted();
sub PrintTrashinfo($$$);
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

#GLOBALS
my $user_name;
my $user_id;
my $home;
my $home_trash;
my $current_date;
my @dlist;

#OPTIONS
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
my $perl_regex = 0;
my $no_count = 0;

Getopt::Long::Configure('bundling');

GetOptions( 'e|empty'          => \$empty,       # IMPL
            'l|list'           => \$view,        # IMPL
	    'f|force+'	       => \$force,       # IMPL
    	    'r|recursive'      => \$recursive,   # IMPL
	    'u|undo'	       => \$undo,        # IMPL
	    'help'             => \$help,        # IMPL
	    'i|interactive'    => \$warn,        # IMPL
	    'v|verbose'        => \$verbose,     # IMPL
	    'no-color'         => \$no_color,    # IMPL
) == 1 or Usage();

SetEnvirnment();

if($help > 0) {
	Usage();
}

if($view > 0) {
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
		foreach my $file(@ARGV) {
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
			print "Restoring $file from Trash\n" if($verbose > 0);
			UndoFile($file);
		}
	}
	exit;
}

foreach my $file (@ARGV) {
	if($warn > 0 and GetUserPermission("Delete $file? ") == 0) {
		next;
	}
	print "Deleting $file from Trash\n" if($verbose > 0);
	DeleteFile($file);
}

sub UndoLatestFiles()
{
	my @list = GetLatestDeleted();

	foreach my $entry (@list) {
		my $info = $entry->{INFO};
		my $to_path = $entry->{PATH};
		my $trsh = $entry->{TRASH};
		my $basename = basename($info);
		if($basename =~ /^(.+)\.trashinfo$/) {
			$basename = $1;
		} else {
			# This should never happen
			print "REGEX ERROR!\n";
		}
		if(-e $to_path) {
			if(GetUserPermission("Overwrite file $to_path?") != 1) {
				next;
			}
		}
		unless(-d dirname($to_path)) {
			my $dir = dirname($to_path);
			SysMkdir($dir);
		}

		print "Restoring $to_path from Trash\n" if($verbose > 0);
		my $success = SysMove("$trsh/files/$basename", $to_path);
		if($success == 0) {
			SysDelete("$trsh/info/$basename.trashinfo","");
		}
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

	my $name_in_trash = $entry->{NAME};
	my $trsh_dir      = $entry->{TRASH};
	my $to_path       = $entry->{PATH};

	if(-e $to_path) {
		if(GetUserPermission("Overwrite file $to_path?") == 0) {
			return;
		}
	}

	unless(-d dirname($to_path)) {
		my $dir = dirname($to_path);
		SysMkdir($dir);
	}

	$name_in_trash =~ s/"/\\"/g;
	$to_path =~ s/"/\\"/g;
	my $success = SysMove("$trsh_dir/files/$name_in_trash", $to_path);
	if($success == 0) {
		SysDelete("$trsh_dir/info/$name_in_trash.trashinfo","");
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
	my $name_in_trash = $entry->{NAME};
	my $trsh_dir      = $entry->{TRASH};

	SysDelete("$trsh_dir/files/$name_in_trash","");
	SysDelete("$trsh_dir/info/$name_in_trash.trashinfo","");
}

sub GetLatestMatchingFile($)
{
	my $file	=	shift;

	my $info = "$home_trash/info";
	my @remove_list;
	my @dates;
	my @list = <$info/*.trashinfo>;
	for my $l (@list) {
		my $p = GetTrashinfo($l);
		my $name = basename($p->{PATH});
		if($name eq $file) {
			$p->{TRASH} = $home_trash;
			$p->{INFO} = $l;
			push @remove_list, $p;
			push @dates, $p->{DATE};
		}
	}
	my @devs = GetDeviceList();
	foreach my $dev (@devs) {
		# Ignore these two as they go 
		# to the home trash
		if($dev eq "/" or $dev eq "/home") {
			next;
		}
		my $trsh = GetDeviceTrash($dev);
		my @list = <$trsh/info/*.trashinfo>;
		foreach my $l (@list) {
			my $p = GetTrashinfo($l);
			my $name = basename($p->{PATH});
			if($name eq $file) {
				$p->{TRASH} = $home_trash;
				$p->{INFO} = $l;
				push @remove_list, $p;
				push @dates, $p->{DATE};
			}
		}
	}
	@dates = sort @dates;
	my $date_to_remove = $dates[$#dates];
	my $return;
	foreach my $remove (@remove_list) {
		if($remove->{DATE} ne $date_to_remove) {
			next;
		}
		my $trsh_dir = $remove->{TRASH};
		my $info     = $remove->{INFO};
		my $name_in_trash = basename($info);
		if($name_in_trash =~ /^(.+)\.trashinfo$/) {
			$name_in_trash = $1;
		} else {
			# This should never happen.
			print "REGEX ERROR!\n";
		}
		$remove->{NAME} = $name_in_trash;
		$return  = $remove;
	}
	return $return;
}

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

	my $dirname = dirname($path);

	# If dirname is not writable, you cannot delete this file.
	unless(-w $dirname) {
		print "Do not have permissions to delete $path\n";
		return;
	}

	# if force is on pass to rm.
	if($force > 0) {
		my $flag = "";
		$flag = $flag . "-r " if($recursive > 0);
		$flag = $flag . "-f " if($force > 1);
		$path =~ s/"/\\"/g;
		SysDelete($path,$flag);
		return;
	}
	if(-d $path and $recursive == 0) {
		print "Could not delete directory $path\n";
		return;
	}


	while($success == 0) {
		$infoname = GetInfoName($info_dir, $name);
		$success = sysopen INFO, "$info_dir/$infoname",  O_RDWR|O_EXCL|O_CREAT;
	}
	print INFO "[Trash Info]\n";
	my $infile_path = $path;
	if($trsh ne $home_trash) {
		my $dev = InDevice($path);
		if($path =~ /^$dev\/(.+)$/) {
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
	$success = SysMove($path, "$trsh/files/$in_trash_name");
	if($success != 0) {
		print "Recovering from failed delete\n";
		SysDelete("$info_dir/$infoname","");
	}
}

sub SysMove($$)
{
	my $from = shift;
	my $to = shift;
	$from =~ s/"/\\"/g;
	$to =~ s/"/\\"/g;
	my $ret = system("mv \"$from\" \"$to\"");
	return $ret;
}

sub SysMkdir($)
{
	my $dir = shift;
	$dir =~ s/"/\\"/g;
	my $ret = system("mkdir -p \"$dir\"");
	return $ret;
}

sub SysDelete($$)
{
	my $file   = shift;
	my $flags  = shift;
	$file =~ s/"/\\"/g;
	my $ret = system("rm $flags \"$file\"");
	return $ret;
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

sub GetLatestDeleted()
{
	my $info = "$home_trash/info";
	my @list = <$info/*.trashinfo>;
	my @dates;
	my @infos;
	foreach my $l (@list) {
		my $p = GetTrashinfo($l);
		if(defined($p->{DATE})) {
			push @dates, $p->{DATE};
			$p->{TRASH} = $home_trash;
			$p->{PREFIX} = "";
			$p->{INFO} = $l;
			push @infos, $p;
		}
	}
	my @devs = GetDeviceList();
	foreach my $dev (@devs) {
		# Ignore these two as they go 
		# to the home trash
		if($dev eq "/" or $dev eq "/home") {
			next;
		}
		my $trsh = GetDeviceTrash($dev);
		my @list = <$trsh/info/*.trashinfo>;
		foreach my $l (@list) {
			my $p = GetTrashinfo($l);
			if(defined($p->{DATE})) {
				push @dates, $p->{DATE};
				$p->{TRASH} = $trsh;
				$p->{PREFIX} = "$dev/";
				$p->{INFO} = $l;
				push @infos, $p;
			}
		}
	}

	if(scalar(@dates) == 0) {
		return ();
	}

	@dates = sort @dates;
	my $latest = $dates[$#dates];
	my @latest_info;
	foreach my $p (@infos) {
		if($p->{DATE} eq $latest) {
			push @latest_info, $p;
		}
	}
	return @latest_info;
}

sub ListTrashContents()
{
	# HOME
	my $info = "$home_trash/info";
	my @list = <$info/*.trashinfo>;
	for my $l (@list) {
		my $p = GetTrashinfo($l);
		$p->{TRASH} = $home_trash;
		PrintTrashinfo($p, "",$l);
	}
	my @devs = GetDeviceList();
	foreach my $dev (@devs) {
		# Ignore these two as they go 
		# to the home trash
		if($dev eq "/" or $dev eq "/home") {
			next;
		}
		my $trsh = GetDeviceTrash($dev);
		my @list = <$trsh/info/*.trashinfo>;
		foreach my $l (@list) {
			my $p = GetTrashinfo($l);
			$p->{TRASH} = $trsh;
			PrintTrashinfo($p, "$dev",$l);
		}
	}
}

sub PrintTrashinfo($$$)
{
	my $p		=	shift;
	my $prefix	=	shift;
	my $info        =       shift;

	my $dir = dirname($info);
	$dir = dirname($dir); # GET TRSH;
	$dir = $dir . "/files";
	my $nm = basename($info);
	$nm =~ s/\.trashinfo//g;
	my $trash_path = "$dir/$nm";

	if(defined($p->{PATH}) and defined($p->{DATE})) {
		my $name = sprintf("%-50s", basename($p->{PATH}));
		my $date = sprintf("%-20s", $p->{DATE});
		my $path = $p->{PATH};
		if($prefix ne "") {
			$path = $prefix . "/" . "$path";
		}
		
		if($no_color == 0) {
			print color(FileTypeColor($trash_path)), "$name";
			print color("Yellow"), " : $date : ";
			print color("reset"), "$path\n";
		} else {
			print "$name";
			print " : $date : ";
			print "$path\n";
		}
		# DATE PATH
	}
}

sub FileTypeColor($)
{
	my $name	=	shift;

	my $ft = "";

	my %TypeColors = (
		"gz"	=>	"Red",
		"zip"	=>	"Red",
		"rpm"	=>	"Red",
		"deb"	=>	"Red",
		"bz2"	=>	"Red",
		"tar.gz"=>	"Red",
	);
	my $base = basename($name);
	if($base =~ /^(.+)\s*$/) {
		$base = $1;
	}
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

sub GetDeviceTrash($)
{
	my $dev		=	shift;
	return GetTrashDir("$dev/DUMMY");
}

sub InHome($)
{
	my $path	=	shift;

	if($path =~ /$home.+/) {
		return 1;
	}
	return 0;
}

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

sub AbsolutePath($)
{
	my $in		=	shift;
	return abs_path($in);

}

sub SetEnvirnment()
{
	$user_name = `id -un`;
	chomp($user_name);
	$user_id   = int(`id -u`);
	$home = $ENV{HOME};
	@dlist = GetDeviceList();
	unless(-d "$home/.local/share/Trash") {
		mkdir "$home/.local/share/Trash";
		mkdir "$home/.local/share/Trash/files";
		mkdir "$home/.local/share/Trash/info";
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
}

sub Usage()
{
	print <<USAGE
TRSH VERSION 3.1-271
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
