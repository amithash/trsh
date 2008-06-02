#!/usr/bin/perl

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

if($shell eq "bash"){
	check_and_remove("/etc/bash.bashrc");
	check_and_remove("/etc/bashrc");
	check_and_remove("$home/.bashrc");
}
else{
	check_and_remove("/etc/csh.cshrc");
	check_and_remove("/etc/cshrc");
	check_and_remove("$home/.cshrc");
}

if(-e "/usr/bin/trsh.pl"){
	system("rm /usr/bin/trsh.pl");
}
if(-e "/usr/share/man/man1/trsh.1.gz"){
	system("rm /usr/share/man/man1/trsh.1.gz");
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

sub check_and_remove{
	my $file = shift;
	if(-e $file){
		open RC,"$file" or die "Could not open $file to read\n";
		open NRC,"+>$file.new" or die "Could not create $file\n";
		my @contents = ();
		while(my $line = <RC>){
			if($line =~ /TRSH/){
				next;
			}
			print NRC "$line";
		}
		close(RC);
		close(NRC);
		system("cp $file.new $file");
	}
}

