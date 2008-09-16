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

my %opts;
my $help = 0;
GetOptions( 
	'user!'         => \$opts{USER},
	'install-path=s'=> \$opts{IPATH},
	'man-path=s'    => \$opts{IPATH},
	'perl-path=s'   => \$opts{PPATH},
	'shell-path=s'  => \$opts{SHELL},
	'trash-path=s'  => \$opts{TPATH},
	'rcfile-path=s' => \$opts{RPATH},
	'ktrsh!'	=> \$opts{KTRSH},
	'help'          => \$help
) or exit 1;

$help == 0 || usage();

$opts{"KTRSH"} = 1 unless(defined($opts{"KTRSH"}));
$opts{"USER"} = 0 unless($opts{"USER"});
$opts{"IPATH"} = "" unless($opts{"IPATH"});
$opts{"RPATH"} = "" unless($opts{"RPATH"});
$opts{"TPATH"} = ".Trash" unless($opts{"TPATH"});
$opts{"SHELL"} = $ENV{SHELL} unless($opts{SHELL});

# No KDE Integration if User.
$opts{"KTRSH"} = 0 if($opts{"USER"} == 1); 


my $no_man = $opts{"USER"};
my $service_menu_dir_kde4 = "/usr/share/kde4/services/ServiceMenus";
my $service_menu_dir_kde3 = "/usr/share/kde4/services/ServiceMenus";

# Configuring shell
print "Looking for shell.... ";
my $shell = $opts{SHELL};
print "[$shell]\n";
die "$shell does not seem to exist on your system... Check your SHELL option. Example: SHELL=/bin/bash\n" unless(-e $shell);

# Finding RC File
print "Looking for RC file... ";
my $rc_file = "NULL";
if($opts{RPATH} eq ""){
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

	foreach my $entry (@rc){
		next if($entry =~ /\.bac$/);
		if($entry =~ /$possible/){
			$rc_file = "$entry";
			last;
		}
	}
	
	die "Could not find suitable rc file\n" if($rc_file eq "NULL");
}
else{
	$rc_file = $opts{RPATH};
}
die "$rc_file is not valid\n" unless(-e $rc_file);

print "[$rc_file]\n";

print "Choosing path of installation.... ";
my $path;
my $ipath;
$ipath = "/usr/bin";
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
my $man_path = `manpath`;
chomp($man_path);
if($man_path =~ /\:*\/usr\/share\/man\:*/){
	$man_path = "/usr/share/man/man1";
}
else{
	my @temp = split(/:/,$man_path);
	$man_path = pop(@temp);
	$man_path = "$man_path/man1";
}
print "Could not find the path to the man pages. Man pages will not be installed\n" unless(-d $man_path);
$no_man = 1 unless(-d $man_path);
$man_path = "/usr/share/man/man1" if($opts{USER} == 0);
if($opts{USER} == 0){
	die "Cannot find Man location $man_path\n" unless(-d $man_path);
}
print "[$man_path]\n";

# Perl
print "Checking if perl is installed... ";
my $perl_path = `which perl`;
chomp($perl_path);
if($perl_path =~ /no perl/){
	undef $perl_path;
}

$perl_path = $opts{PPATH} if($opts{PPATH});
die "Perl executable not found [$perl_path]\n" unless(-e $perl_path);
print "[$perl_path]\n";

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
$perl_path =~ s/\//\\\//g;
print MK "\t\@sed -e 's/sub trash{ return \".Trash\"; }/sub trash{ return \"$opts{TPATH}\"; }/g' -e 's/#!\\/usr\\/bin\\/perl/#!$perl_path/g' trsh.pl > trsh.pl.o\n";
print MK "\t+make -C ktrsh\n" if($opts{KTRSH} == 1);
print MK "\t\@exit 0\n";
print MK "\n";

# INSTALL
print MK "install:\n";
print MK "\t\@sed -e '/.* # TRSH/d' $rc_file > $rc_file.new\n";
print MK "\t\@echo \"$alias_rm # TRSH\" >> $rc_file.new\n";
print MK "\t\@echo \"$alias_undo # TRSH\" >> $rc_file.new\n";
print MK "\t\@cp $rc_file $rc_file.bac\n";
print MK "\t\@mv $rc_file.new $rc_file\n";
print MK "\t\@cp trsh.pl.o $path\n";
print MK "\t\@cp trsh.1.gz $man_path\n" if($no_man == 0);
print MK "\t\@chmod +x $path\n";
print MK "\t\@cp ktrsh/ktrsh /usr/bin\n" if($opts{KTRSH} == 1);
print MK "\t\@cp ktrsh.desktop $service_menu_dir_kde4\n" if($opts{KTRSH} == 1 and -d $service_menu_dir_kde4);
print MK "\t\@cp ktrsh.desktop $service_menu_dir_kde3\n" if($opts{KTRSH} == 1 and -d $service_menu_dir_kde3);
print MK "\t\@exit 0\n";
print MK "\n";

# UNINSTALL
print MK "uninstall:\n";
print MK "\t\@rm $path\n";
print MK "\t\@rm $man_path/trsh.1.gz\n" if($no_man == 0);
print MK "\t\@sed -e '/.* # TRSH/d' $rc_file > $rc_file.new\n";
print MK "\t\@mv $rc_file.new $rc_file\n";
print MK "\t\@rm /usr/bin/ktrsh\n" if($opts{KTRSH} == 1);
print MK "\t\@rm $service_menu_dir_kde4/ktrsh.desktop" if($opts{KTRSH} == 1 and -d $service_menu_dir_kde4);
print MK "\t\@rm $service_menu_dir_kde3/ktrsh.desktop" if($opts{KTRSH} == 1 and -d $service_menu_dir_kde3);
print MK "\t\@exit 0\n";
print MK "\n";

# CLEAN
print MK "clean:\n";
print MK "\t\@rm trsh.pl.o\n";
print MK "\t+make -C ktrsh clean\n" if($opts{KTRSH} == 1);
print MK "\t\@exit 0\n";
print MK "\n";
close(MK);
print "Configuring completed successfully....\n";
print "\nperform a 'make' followed by a 'make install'\n";
print "If you did not like trsh, you can uninstall it by 'make uninstall'\n";
print "\n";

sub usage{
	print "USAGE:\n";
	print "./configure.pl [OPTIONS]\n\n";
	print "OPTIONS:\n";
	print "--perl-path=/path/to/perl Default: got from 'which perl'\n";
	print "--user => User install (or --nouser => System Install) Default: --nouser\n";
	print "--shell-path=/path/to/shell. Default: Determined from \$SHELL env variable (Shell currently used)\n";
	print "--install-path=/path/to/place/trsh.pl. Default /usr/bin/trsh.pl (--nouser) \$HOME/.trsh.pl (--nouser)\n";
	print "--rcfile-path=/path/to/rcOfShell. Default: Determined from SHELL and naming scheme of files on system\n";
	print "\tConfigure looks in /etc/ (--nouser) or \$HOME/ (--user)\n";
	print "--man-path=/path/to/place/manpage. Default: got from 'manpath' and preference given to /usr/share/man Not performed for --user\n";
	print "--trash-path=RelativePath/of/trash/in/home. (Trash = \$HOME/TrashPath) Default: .Trash\n";
	print "\n";
	exit;
}

