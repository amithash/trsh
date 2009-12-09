#!/usr/bin/perl

##############################################################################################
#					TRSH - 3.x					     #
##############################################################################################

use strict;
use warnings;
use File::Basename;

sub SetEnvirnment();
sub InHome($);

my $user_name;
my $user_id;
my $home;

SetEnvirnment();
my @dlist = GetDeviceList();
foreach my $tmp (@dlist) {
	print "$tmp\n";
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
	my @dlist = GetDeviceList();
	foreach my $device (@dlist) {
		if($path =~ /$device.+/) {
			return $device;
		}
	}
	return "NULL";
}

sub GetDeviceList
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

sub SetEnvirnment()
{
	my $user_name = `id -un`;
	chomp($user_name);
	my $user_id   = int(`id -u`);
	my $home = $ENV{HOME};
}

