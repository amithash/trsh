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

if($#ARGV != 0){
	usage();
	exit;
}
my $home = $ENV{HOME} || (getpwuid($<))[7];
print "Your Home is: $home\n";
system("cp ./trsh.pl $home/.trsh.pl");
system("mkdir $home/.Trash") unless(-d "$home/.Trash");
system("touch $home/.Trash/.history") unless (-e "$home/.Trash/.history");

if($ARGV[0] eq "bash"){
	if(check("$home/.bashrc") == 0){
		backup("$home/.bashrc");
		open BASHRC, ">>$home/.bashrc" or die "Could not open $home/.bashrc in append mode\n";
		print BASHRC "################################################################\n";
		print BASHRC "#                          TRSH                                #\n";
		print BASHRC "################################################################\n";
		print BASHRC "export TRASH_DIR=\"$home/.Trash\"\n";
		print BASHRC "alias rm=\"$home/.trsh.pl\"\n";
		print BASHRC "alias undo=\"$home/.trsh.pl -u\"\n";
		print BASHRC "################################################################\n";
		close(BASHRC);
	}
	else{
		print "Entries in $home/.bashrc seems to exist, leaving it alone\n";
	}
	system("./test-trsh.sh > /dev/null");
}
elsif($ARGV[0] eq "csh"){
	if(check("$home/.cshrc") == 0){
		backup("$home/.cshrc");
		open CSHRC, ">>$home/.cshrc" or die "Could not open $home/.cshrc in append mode\n";
		print CSHRC "################################################################\n";
		print CSHRC "#                          TRSH                                #\n";
		print CSHRC "################################################################\n";
		print CSHRC "setenv TRASH_DIR $home/.Trash\n";
		print CSHRC "alias rm \"$home/.trsh.pl\"\n";
		print CSHRC "alias undo \"$home/.trsh.pl -u\"\n";
		print CSHRC "################################################################\n";
		close(CSHRC);
	}
	else{
		print "Entries in $home/.cshrc seems to exist, leaving it alone\n";
	}
}
elsif($ARGV[0] eq "-help" or $ARGV[0] eq "-h"){
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

setup.pl SHELL

SHELL  = \"bash\" for the Bourne again shell,
       = \"csh\" for the C-Shell

NOTE: for bash it is assumed that the .bashrc file in the home
dir is present. and the same goes for the c-shell (.cshrc).
Refer the README for a manual install if you have a different
shell.\n"
}
