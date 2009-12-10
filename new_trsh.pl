#!/usr/bin/perl

##############################################################################################
#					TRSH - 3.x					     #
##############################################################################################

use strict;
use warnings;
use File::Basename;
use Cwd 'abs_path'; 
use Getopt::Long;
use Fcntl;

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
sub PrintTrashinfo($$);
sub Usage();
sub DeleteFile($);
sub EmptyTrash();
sub RemoveFromTrash($);

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
	    'no-color'         => \$no_color,
    	    'r|recursive'      => \$recursive,
) == 1 or Usage();

SetEnvirnment();

if($view > 0) {
	ListTrashContents();
	exit;
}

if($empty > 0) {
	if(scalar(@ARGV) == 0) {
		EmptyTrash();
	} else {
		foreach my $file(@ARGV) {
			RemoveFromTrash($file);
		}
	}
	exit;
}

foreach my $file (@ARGV) {
	DeleteFile($file);
}

sub EmptyTrash()
{
	# Empty Home Trash
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
		system("rm -rf $trsh/info/*");
		system("rm -rf $trsh/files/*");
	}
}

sub RemoveFromTrash($)
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
		system("rm -rf \"$trsh_dir/files/$name_in_trash\"");
		system("rm -rf \"$trsh_dir/info/$name_in_trash.trashinfo\"");
		last;
	}
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
		system("rm $flag $path");
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
	# I need to do the same to handle special chars.... ???
	$success = system("mv \"$path\" \"$trsh/files/$in_trash_name\"");
	if($success != 0) {
		print "Recovering from failed delete\n";
		system("rm $info_dir/$infoname");
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
		PrintTrashinfo(GetTrashinfo($l),"");
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
			PrintTrashinfo(GetTrashinfo($l), "$dev/");
		}
	}
}

sub PrintTrashinfo($$)
{
	my $p		=	shift;
	my $prefix	=	shift;

	if(defined($p->{PATH}) and defined($p->{DATE})) {
		printf("%-40s : %-40s\n",$prefix . $p->{PATH},$p->{DATE});
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
	print "USAGE:\n";
}
