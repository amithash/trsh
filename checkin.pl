#!/usr/bin/perl

use strict;
use warnings;
my $verstr = `cat VERSION`;
$verstr =~ /(\d+)\.(\d+)/;
my $main = $1;
my $sub  = $2;
my $rev  = `svnversion`;

if($rev =~ /^(\d+)M/){
	# modification has occured.
	$rev = $1 + 1;
}
elsif($rev =~ /^\d+\:(\d+)M/){
	print "WARNING: You need to do a svn update.\n";
	$rev = $1 + 1;
}
else{
	print "No modifications, checkin not required.\n";
	exit;
}
open TRSH,"trsh.pl" or die "Could not find trsh.pl";
my @trsh = <TRSH>;
close(TRSH);
system("mv trsh.pl trsh.pl.orig");
open TRSH, "+>trsh.pl" or die "Could not create trsh.pl\n";
foreach my $entry (@trsh){
	$entry =~ s/TRSH VERSION \d+\.\d+\-\d+/TRSH VERSION $main\.$sub-$rev/;
	print TRSH $entry;
}

open README,"README" or die "Could not find README";
my @readme = <README>;
close(README);
system("mv README README.orig");
open README, "+>README" or die "Could not create README\n";
foreach my $entry (@readme){
	$entry =~ s/Version \d+\.\d+-\d+/Version $main\.$sub-$rev/;
	print README $entry;
}
close(README);
system("rm -f README.orig trsh.pl.orig");

open SPEC, "trsh.spec" or die "Could not open spec file\n";
open SPECM, "+>trsh.spec.n" or die "Could not create new spec file\n";
while(my $entry = <SPEC>){
	$entry =~ s/Version\s*:\s+\d+\.\d+/Version: $main\.$sub/;
	$entry =~ s/Release\s*:\s+\d+/Release: $rev/;
	print SPECM "$entry";
}
system("rm trsh.spec");
system("mv trsh.spec.n trsh.spec");

print "Checking Message (Single line):\n";
my $message = <STDIN>;
chomp($message);
system("svn ci -m \"$message\"");

