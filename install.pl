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
use Cwd;
use Getopt::Long;

my $user = 0;
my $shell = "";
my $uid;
my $rc_file;

GetOptions("user" => \$user);


########## USER VALIDATION #################

open UID, "id -u |";
$uid = <UID>;
$uid = $uid + 0;
close(UID);

if($uid != 0 and $user == 0){
	print STDERR "\nSorry, you need to be root to make a system wide install.\n";
	print STDERR "Login as root and try again, or you can use sudo.\n";
	print STDERR "If you want/can do neither, try a user install with a -u option\n\n";
	exit;
}

########## WHICH SHELL? ######################

if(defined $ENV{SHELL}){
	my @temp = split(/\//, $ENV{SHELL});
	$shell = $temp[$#temp];
	print "Shell Used: $shell\n";
}
else{
	$shell = ask_user("Please enter the name of your shell");
}

my $home = $ENV{HOME} || (getpwuid($<))[7];
my $trash_dir = $home . "/.Trash";

print "Your Home is: $home\n";
print "Trash dir choosen: $trash_dir\n";

if($user == 1){
	system("cp ./trsh.pl $home/.trsh.pl");
	system("cp ./trsh.1.gz $home/.trsh.1.gz");
}
else{
	system("cp ./trsh.pl /usr/bin");
	system("cp trsh.1.gz /usr/share/man/man1");
}
system("mkdir $home/.Trash") unless(-d "$home/.Trash");
system("touch $home/.Trash/.history") unless (-e "$home/.Trash/.history");

if($shell eq "bash"){
	if($user == 0){
		if(-e "/etc/bash.bashrc"){
			$rc_file = "/etc/bash.bashrc";
		}
		elsif(-e "/etc/bashrc"){
			$rc_file = "/etc/bashrc";
		}
		else{
			$rc_file = ask_user("Please enter the system wide rc file (defaults do not exist");
			if(! -e $rc_file){
				die "$rc_file does not exist. Try an user install\n";
			}
		}
	}
	else{
		if(-e "$home/.bashrc"){
			$rc_file = "$home/.bashrc";
		}
		else{
			$rc_file = ask_user("Enter the path to the user bashrc file");
		}
	}	
	print "Using RC file: $rc_file\n";

	if(check($rc_file) == 0){
		backup($rc_file);
		open BASHRC, ">>$rc_file" or die "Could not open $rc_file in append mode\n";
		print BASHRC "################################################################\n";
		print BASHRC "#                          TRSH                                #\n";
		print BASHRC "################################################################\n";
		print BASHRC "export TRASH_DIR=\"$home/.Trash\"\n";
		if($user == 1){
			print BASHRC "alias rm=\"$home/.trsh.pl\"\n";
			print BASHRC "alias undo=\"$home/.trsh.pl -u\"\n";
		}
		else{
			print BASHRC "alias rm=\"trsh.pl\"\n";
			print BASHRC "alias undo=\"trsh.pl -u\"\n";
		}
		print BASHRC "################################################################\n";
		close(BASHRC);
	}
	else{
		print "Entries in $rc_file seems to exist, leaving it alone\n";
	}
}
elsif($shell eq "csh"){
	print "RC File: $home/.cashrc\n";
	print "Due to lack of support, full system install for c-shell does not exist.\n";
	print "please ask your users to add to their cshrc the changes made to your cshrc\n";
	if(check("$home/.cshrc") == 0){
		backup("$home/.cshrc");
		open CSHRC, ">>$home/.cshrc" or die "Could not open $home/.cshrc in append mode\n";
		print CSHRC "################################################################\n";
		print CSHRC "#                          TRSH                                #\n";
		print CSHRC "################################################################\n";
		print CSHRC "setenv TRASH_DIR $home/.Trash\n";
		if($user == 1){
			print CSHRC "alias rm \"$home/.trsh.pl\"\n";
			print CSHRC "alias undo \"$home/.trsh.pl -u\"\n";
		}
		else{
			print CSHRC "alias rm \"trsh.pl\"\n";
			print CSHRC "alias undo \"trsh.pl -u\"\n";
		}
		print CSHRC "################################################################\n";
		close(CSHRC);
	}
	else{
		print "Entries in $home/.cshrc seems to exist, leaving it alone\n";
	}
}
elsif($shell eq "-help" or $shell eq "-h"){
	usage();
	exit;
}
else{
	usage();
	exit;
}

sub backup{
	my $file = shift;
	open FIRST,"<$file" or die "could not open $file\n";
	open BAC, "+>$file.bac" or die "Could not create $file.bac\n";
	my @f = <FIRST>;
	close(FIRST);
	foreach my $line (@f){
		print BAC "$line";
	}
	close(BAC);
}
sub check{
	my $file = shift;
	open RC,"$file" or die "Could not open $file\n";
	my $exist = 0;
	while(my $line = <RC>){
		if($line =~ /TRSH/){
			$exist = 1;
			last;
		}
	}
	close(RC);
	return $exist;
}

sub usage{
	print "USAGE:

setup.pl [-u] SHELL

SHELL  = \"bash\" for the Bourne again shell,
       = \"csh\" for the C-Shell
-u     = If provided, a user installation is performed and you
	 do not need root permissions, but you do not get a man 
	 page!

NOTE: for bash it is assumed that the .bashrc file in the home
dir is present. and the same goes for the c-shell (.cshrc).
Refer the README for a manual install if you have a different
shell.\n"
}

sub ask_user{
	my $msg = shift;
	print "$msg :";
	my $inp = <STDIN>;
	chomp($inp);
	return $inp;
}

