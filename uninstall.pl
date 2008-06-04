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

my $home = $ENV{HOME};
my @temp = split(/\//, $ENV{SHELL});
my $shell = $temp[$#temp];
if(not defined($shell)){
	die "Env variable SHELL is not defined!\n";
}
if(not defined($home)){
	die "Env variable HOME is not defined!\n";
}
open UID,"id -u |";
my $uid = <UID>;
chomp($uid);
$uid = $uid + 0;

print "Are you sure you want to uninstall trsh? [y/n]: ";
my $res = <STDIN>;
chomp($res);
if(not($res eq "y" or $res eq "Y")){
	exit;
}

if($shell eq "bash"){
	if($uid == 0){
		check_and_remove("/etc/bash.bashrc");
		check_and_remove("/etc/bashrc");
	}
	check_and_remove("$home/.bashrc");
}
else{
	if($uid == 0){
		check_and_remove("/etc/csh.cshrc");
		check_and_remove("/etc/cshrc");
	}
	check_and_remove("$home/.cshrc");
}


if($uid == 0){
	if(-e "/usr/bin/trsh.pl"){
		system("rm /usr/bin/trsh.pl");
	}
	if(-e "/usr/share/man/man1/trsh.1.gz"){
		system("rm /usr/share/man/man1/trsh.1.gz");
	}
}

if(-e "$home/.trsh.pl"){
	system("rm $home/.trsh.pl");
}
if(-e "$home/.trsh.1.gz"){
	system("rm $home/.trsh.1.gz");
}
if(-e "$home/.Trash"){
	print "Do you want to delete the trash and its contents? (y/n) :";
	my $res = <STDIN>;
	chomp($res);
	if($res eq "y" or $res eq "Y"){
		system("rm -rf $home/.Trash");
	}
	else{
		print "Trash is at $home/.Trash. Delete its contents at your convienence\n";
	}
}
if($uid != 0){
	print "Just performed an user uninstallation. \n";
	print "If you needed a system wide uninstall, do it as root.\n";
}

sub check_and_remove{
	my $file = shift;
	if(-e $file){
		open RC,"$file" or die "Could not open $file to read\n";
		open NRC,"+>$file.new" or die "Could not create $file.new\n";
		my @contents = ();
		while(my $line = <RC>){
			if($line =~ /TRSH/){
				next;
			}
			print NRC "$line";
		}
		close(RC);
		close(NRC);
		system("mv $file.new $file");
	}
}

