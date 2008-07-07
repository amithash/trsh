#!/usr/bin/perl
#*************************************************************************
# Copyright 2008 Amithash Prasad                                         *
#                                                                        *
# This file is part of trsh                                              *
#                                                                        *
# trsh is free software: you can redistribute it and/or modify         *
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

# Finding the home
my $home = $ENV{"HOME"} || "NULL";
die "HOME Env variable is not declared\n" if($home eq "NULL");
if($#ARGV >= 0){
	if($ARGV[0] eq "--help" or $ARGV[0] eq "-help" or $ARGV[0] eq "-h"){
		usage();
	}
}

my %opts;
foreach my $opt (@ARGV){
	$opt =~ /(.+)=(.+)/;
	$opts{$1} = $2;
}

$opts{"USER"} = 0 unless($opts{"USER"});
$opts{"IPATH"} = "" unless($opts{"IPATH"});
$opts{"RPATH"} = "" unless($opts{"RPATH"});
$opts{"TPATH"} = ".Trash" unless($opts{"TPATH"});
$opts{"SHELL"} = $ENV{SHELL} unless($opts{SHELL});

# Configuring shell
print "Looking for shell.... ";
my $shell = $opts{SHELL};
print "[$shell]\n";
die "$shell does not seem to exist on your system... Check your SHELL option. Example: SHELL=/bin/bash\n" unless(-e $shell);

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
else{
	die "Unsupported shell. Refer wiki pages or README on manual installation\n";
}

my $rc_file = "NULL";
foreach my $entry (@rc){
	next if($entry =~ /\.bac$/);
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
if(-d $path){
	$path = "$path/trsh.pl";
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

print "TRASH will be located in.... ";
while($opts{TPATH} =~ /^\/(.+)/){
	$opts{TPATH} = $1;
}
print "[\$HOME/$opts{TPATH}]\n";

# Generate known aliases.
my $alias_rm = "";
my $alias_undo = "";
if($shell =~ /bash/){
	$alias_rm = "alias rm=\\\"$path\\\"";
	$alias_undo = "alias undo=\\\"$path -u\\\"";
}
elsif($shell =~ /csh/){
	$alias_rm = "alias rm \\\"$path\\\"";
	$alias_undo = "alias undo \\\"$path -u\\\"";
}
else{
	die "Unsupported shell: $shell\n";
}

# Create MAKEFILE
system("rm makefile") if(-e "makefile");
open MK, "+>makefile" or die "Could not create makefile\n";

# DEFAULT
print MK "default:\n";
$opts{TPATH} =~ s/\//\\\//g;
print MK "\tsed -e 's/sub trash{ return \".Trash\"; }/sub trash{ return \"$opts{TPATH}\"; }/g' trsh.pl > trsh.pl.o\n";
print MK "\n";

# INSTALL
print MK "install:\n";
print MK "\tsed -e 's/.* # TRSH//g' $rc_file > $rc_file.new\n";
print MK "\techo \"$alias_rm # TRSH\" >> $rc_file.new\n";
print MK "\techo \"$alias_undo # TRSH\" >> $rc_file.new\n";
print MK "\tcp $rc_file $rc_file.bac\n";
print MK "\tmv $rc_file.new $rc_file\n";
print MK "\tcp trsh.pl.o $path\n";
print MK "\tcp trsh.1.gz $man_path\n" if($opts{USER} == 0);
print MK "\tchmod +x $path\n";
print MK "\n";

# UNINSTALL
print MK "uninstall:\n";
print MK "\trm $path\n";
print MK "\trm $man_path/trsh.1.gz\n" if($opts{USER} == 0);
print MK "\tsed -e 's/.* # TRSH//g' $rc_file > $rc_file.new\n";
print MK "\tmv $rc_file.new $rc_file\n";
print MK "\n";

# CLEAN
print MK "clean:\n";
print MK "\trm trsh.pl.o\n";
print MK "\n";
close(MK);
print "Configuring done....\n";
print "\nperform a 'make' followed by a 'make install'\n";
print "If you did not like trsh, you can uninstall it by 'make uninstall'\n";
print "\n";

sub usage{
	print "USAGE:\n";
	print "./configure.pl [OPTIONS]\n\n";
	print "OPTIONS:\n";
	print "USER=1 -- User install, USER=0 (Default) -- System Install\n";
	print "SHELL=/path/to/shell. Default: Determined from \$SHELL env variable\n";
	print "IPATH=/path/to/place/trsh.pl. Default /usr/bin/trsh.pl (USER=0) \$HOME/.trsh.pl (USER=1)\n";
	print "RPATH=/path/to/rcOfShell. Default: Determined from SHELL and naming scheme of files on system\n";
	print "\tConfigure looks in /etc/ (USER=0) or \$HOME/ (USER=1)\n";
	print "MPATH=/path/to/place/manpage. Default: /usr/share/man/man1 (USER=0) Not performed for USER=1\n";
	print "TPATH=RelativePath/of/trash/in/home. (Trash = \$HOME/TPATH) Default: .Trash\n";
	print "\n";
	exit;
}

