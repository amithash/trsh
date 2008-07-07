#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

# Finding the home
my $home = $ENV{"HOME"} || "NULL";
die "HOME Env variable is not declared\n" if($home eq "NULL");

my %opts;
foreach my $opt (@ARGV){
	$opt =~ /(.+)=(.+)/;
	$opts{$1} = $2;
}

$opts{"USER"} = 0 unless($opts{"USER"});
$opts{"RPATH"} = "" unless($opts{"RPATH"});
$opts{"TPATH"} = ".Trash" unless($opts{"TPATH"});
$opts{"IPATH"} = "" unless($opts{"IPATH"});

# Configuring shell
print "Looking for shell.... ";
my $shell = $ENV{"SHELL"} || die "SHELL Env variable is not delclared\n";
print "[$shell]\n";


# Finding RC File
print "Looking for RC file... ";
my $temp1;
if($opts{USER} == 0){
	$temp1 = `ls /etc/*rc*`;
}else{
	$temp1 = `ls $home/.*rc`;
}

my @rc = split(/\n/, $temp1);
my $possible = "";
if($shell =~ /bash/){
	$possible = "bash";
}
elsif($shell =~ /csh/){
	$possible = "csh";
}
elsif($shell =~ /tcsh/){
	$possible = "tcsh";
}
else{
	die "Unsupported shell. Refer wiki pages on manual installation\n";
}
my $rc_file = "NULL";
foreach my $entry (@rc){
	if($entry =~ /$possible/){
		$rc_file = "$entry";
		last;
	}
}

die "Could not find suitable rc file\n" if($rc_file eq "NULL");
print "[$rc_file]\n";

print "Choosing path of installation.... ";
my $path;
if($opts{IPATH} eq ""){
	$path = "/usr/bin/trsh.pl" if($opts{USER} == 0);
	$path = "$home/.trsh.pl" if($opts{USER} == 1);
}
else{
	$path = $opts{IPATH};
}

print "[$path]\n";

# Man path...
print "Choosing location for man pages... ";
my $man_path = "";
$man_path = "/usr/share/man/man1" if($opts{USER} == 0);
if($opts{USER} == 0){
	die "Cannot find Man location $man_path\n" unless(-d $man_path);
}
print "[$man_path]\n";

# $path = Place to copy trsh.pl
# $rc_file = rc to modify
# $man_path = place to copy trsh.1

# Create MAKEFILE
system("rm makefile") if(-e "makefile");
open MK, "+>makefile" or die "Could not create makefile\n";

# Start writing makefile default
print MK "default:\n";
print MK "\tcat trsh.pl > trsh.pl.o\n";
print MK "\techo \"sub trash{ return \\\".KAKKA\\\"; }\" >> trsh.pl.o\n\n";

# Start writing install path
print MK "install:\n";
print MK "\tmv trsh.pl.o $path\n";
print MK "\tcp trsh.1.gz $man_path\n" if($opts{USER} == 0);
print MK "\tchmod +x $path\n";
# ADD RC CONTENT

print MK "\n";
# start writing uninstall path
print MK "uninstall:\n";
print MK "\trm $path\n";
print MK "\trm $man_path/trsh.1.gz\n" if($opts{USER} == 0);
# REMOVE RC CONTENT

close(MK);

