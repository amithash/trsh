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
my $help = 0;
my $rm;
my $undo;

GetOptions("user" => \$user,
	   "help" => \$help);

if($help == 1){
	usage();
	exit;
}
########## USER VALIDATION #################

open UID, "id -u |";
$uid = <UID>;
$uid = $uid + 0;
close(UID);


########## WHICH SHELL? ######################

if(defined $ENV{SHELL}){
	my @temp = split(/\//, $ENV{SHELL});
	$shell = $temp[$#temp];
}

do{
	get_from_user("What is your default shell? ",\$shell);
}while($shell eq "");

my $home = $ENV{HOME} || (getpwuid($<))[7];
my $trash = "/.Trash";

get_from_user("What is your home directory? ", \$home);
get_from_user("Where do you like your trash (Relative to your home directory)? ",\$trash);
system("mkdir $home"."$trash");
if(! -e "$home/$trash"){
	print "Invalid TRASH DIRECTORY: $home$trash selection. Please choose a valid trash directory. Exiting installation...\n";
	exit;
}

my $user_or_system = "system";
get_from_user("Type of Install? ",\$user_or_system);
if($uid != 0 and $user_or_system eq "system"){
	$user_or_system = "exit";
	get_from_user("Cannot perform system install as a regular user. Select user to perform a user install instead. (exit | user)? ",\$user_or_system)
	if($user_or_system eq "exit"){
		exit;
	}
}
open TRSH,"trsh.pl" or die "Wierd, your installation dir does not contain the main component (trsh)!\n";
my @trsh_contents = <TRSH>;
close(TRSH);

if($trash ne "/.Trash"){
	search_and_replace(\@trsh_contents, "my \$trash = \"\$ENV{HOME}\/.Trash\"", "my |$trash = \"\$ENV{HOME}$trash\""); 
}

my $dest;
my $man_dest;

if($user == 1){
	$dest = "$home/.trsh.pl";
	get_from_user("Where do you trsh to be installed?", \$dest);
	$man_dest = "$home/.trsh.1.gz";
	get_from_user("Where do you want the man pages to be installed? ", \$man_dest);
	if($man_dest ne "$home/.trsh.1.gz"){
		search_and_replace(\@trsh_contents, "\$ENV{HOME}/.trsh.1.gz",$man_dest);
	}
}
else{
	$dest = "/usr/bin/trsh.pl";
	get_from_user("Where do you trsh to be installed?", \$dest);
	$man_dest = "/usr/share/man/man1/trsh.1.gz";
	get_from_user("Where do you want the man pages to be installed? ", \$man_dest);
}



$rm = $dest;
$undo = "$rm -u";

if($shell eq "bash"){
	if($user == 0){
		if(-e "/etc/bash.bashrc"){
			$rc_file = "/etc/bash.bashrc";
		}
		elsif(-e "/etc/bashrc"){
			$rc_file = "/etc/bashrc";
		}
		get_from_user("What is your system wide RC file?",\$rc_file);
		if(! -e $rc_file){
			print "$rc_file does not exist. Exiting\n":
		}
	}
	else{
		if(-e "$home/.bashrc"){
			$rc_file = "$home/.bashrc";
		}
		get_from_user("What is the local RC file?", \$rc_file);
		if(! -e $rc_file){
			print "$rc_file does not exist. Exiting\n";
		}
	}	

	if(check($rc_file) == 0){
		backup($rc_file);
		open BASHRC, ">>$rc_file" or die "Could not open $rc_file in append mode\n";
		print BASHRC "alias rm=\"$dest\" # TRSH\n";
		print BASHRC "alias undo=\"$dest -u\" # TRSH\n";
		close(BASHRC);
	}
	else{
		print "Entries in $rc_file seems to exist, leaving it alone\n";
	}
}
elsif($shell eq "csh" or $shell eq "tcsh"){
	if($user == 0){
		if(-e "/etc/csh.cshrc"){
			$rc_file = "/etc/csh.cshrc";
		}
		elsif(-e "/etc/cshrc"){
			$rc_file = "/etc/cshrc";
		}
		get_from_user("What is your system wide RC file?",\$rc_file);
		if(! -e $rc_file){
			print "$rc_file does not exist. Exiting\n":
		}

	}
	else{
		if(-e "$home/.cshrc"){
			$rc_file = "$home/.cshrc";
		}
		get_from_user("What is the local RC file?", \$rc_file);
		if(! -e $rc_file){
			print "$rc_file does not exist. Exiting\n";
		}
	}	
	if(check($rc_file) == 0){
		backup($rc_file);
		open CSHRC, ">>$rc_file" or die "Could not open $rc_file in append mode\n";
		print CSHRC "alias rm \"$dest\" # TRSH\n"; 
		print CSHRC "alias undo \"$dest -u\" # TRSH\n"; 
		close(CSHRC);
	}
	else{
		print "Entries in $rc_file seems to exist, leaving it alone\n";
	}
}
else{
	print "Sorry, it seems that your shell: $shell is not supported by this installation. (not bash, csh or tcsh)\n";
	print "Exiting\n";
	exit;
}
open TRSH_NEW, "+>./trsh.pl.new" or die "Could not create trsh.pl.new\n";
foreach my $line (@trsh_contents){
	print TRSH_NEW "$line";
}
close(TRSH_NEW);
system("mv ./trsh.pl.new $dest");
system("cp ./trsh.1.gz $man_dest");
system("chmod +x $dest");

########### SUBS ##################

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

setup.pl [-u]

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

sub get_from_user{
	my $msg = shift;
	my $ref_var = shift;
	my $message = $msg . "[$$ref_var]: ";
	print $message;
	my $res = <STDIN>;
	chomp($res);
	if($res ne ""){
		$$ref_var = $res;
	}
}

sub search_and_replace{
	my $arr_ref = shift;
	my $what = shift;
	my $with = shift;
	my $len = $#$arr_ref;
	for(my $i=0;$i<=$len;$i++){
		$$arr_ref[$i] =~ s/$what/$with/;
	}
}
