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
use Term::ANSIColor;
$Term::ANSIColor::AUTORESET = 1;

my $shell = "";
my $rc_file;

########## USER VALIDATION #################

open UID, "id -u |";
my $uid = <UID>;
$uid = $uid + 0;
close(UID);

print color("Green"), "Hi, welcome to the installation script of trsh. I will ask few quick questions, and then we are done.\n";
print color("Green"), "Just hit Enter (Return) to accept the default value. For most cases, this will be just fine.\n\n";
my $yes = "yes";
get_from_user("Do you want to continue?",\$yes);
if(not($yes eq "yes" or $yes eq "y" or $yes eq "Y")){
	print "Goodbye\n";
	exit1();
}
print "\n";

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
if(not ($trash =~ /^\//)){   # Check if it has a trailing forward slash, if it does not add it!
	$trash = "/$trash";
}

############# KIND OF INSTALL and USER VALIDATION #############


my $user_or_system = "system";
get_from_user("Type of Install? (user / system)",\$user_or_system);
if($uid != 0 and $user_or_system eq "system"){
	$user_or_system = "exit";
	get_from_user("Cannot perform system install as a regular user. Select user to perform a user install instead. (exit | user)? ",\$user_or_system);
	if($user_or_system eq "exit"){
		exit1();
	}
}

# Open trsh.pl and make changes with the user entered configuration.

open TRSH,"trsh.pl" or die "Wierd, your installation dir does not contain the main component (trsh)!\n";
my @trsh_contents = <TRSH>;
close(TRSH);

if($trash ne "/.Trash"){
	search_and_replace(\@trsh_contents, qr/my \$trash = "\$ENV{HOME}\/.Trash"/, "my \$trash = \"\$ENV{HOME}$trash\""); 
}

my $dest;
my $man_dest;

if($user_or_system eq "user"){
	$dest = "$home/.trsh.pl";
	get_from_user("Where do you trsh to be installed?", \$dest);
	$man_dest = "$home/.trsh.1.gz";
	get_from_user("Where do you want the man pages to be installed? ", \$man_dest);
}
else{
	$dest = "/usr/bin/trsh.pl";
	get_from_user("Where do you trsh to be installed?", \$dest);
	$man_dest = "/usr/share/man/man1/trsh.1.gz";
	get_from_user("Where do you want the man pages to be installed? ", \$man_dest);
}

if($shell eq "bash"){
	if($user_or_system eq  "system"){
		if(-e "/etc/bash.bashrc"){
			$rc_file = "/etc/bash.bashrc";
		}
		elsif(-e "/etc/bashrc"){
			$rc_file = "/etc/bashrc";
		}
		get_from_user("What is your system wide RC file?",\$rc_file);
		if(! -e $rc_file){
			print "$rc_file does not exist. Exiting\n";
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
	if($user_or_system eq "system"){
		if(-e "/etc/csh.cshrc"){
			$rc_file = "/etc/csh.cshrc";
		}
		elsif(-e "/etc/cshrc"){
			$rc_file = "/etc/cshrc";
		}
		get_from_user("What is your system wide RC file?",\$rc_file);
		if(! -e $rc_file){
			print "$rc_file does not exist. Exiting\n";
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
	exit1();
}

open TRSH_NEW, "+>$dest" or die "Could not create $dest, either the path does not exist, or you do not have write permissions there.\n";
foreach my $line (@trsh_contents){
	print TRSH_NEW "$line";
}
close(TRSH_NEW);
system("cp ./trsh.1.gz $man_dest");
system("chmod +x $dest");

print color("Green"), "\n\nCongratulations, trsh is installed. Restart all current terminal sessions and try it out!\n";
print color("Green"), "Report bugs to http://code.google.com/p/trsh/issues\n";
if($user_or_system eq "system"){
	print color("Red"),"You have installed trsh for all users. Please inform all your users the same. An uninformed feature is as dangerious as a buggy feature!\n";
}

exit1();

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

sub get_from_user{
	my $msg = shift;
	my $ref_var = shift;
	print color("White"), $msg;
	print color("Red"), " [$$ref_var]";
	print color("White"), ": ";
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
	for(my $i=0;$i<=$#$arr_ref;$i++){
		$$arr_ref[$i] =~ s/$what/$with/;
	}
}
sub exit1{
	print color("reset"), "\n";
	exit;
}
