#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

my $major = 0;
my $minor = 0;
GetOptions(
	'M|major' => \$major,
	'm|minor' => \$minor
) == 1 or die "Error in options.\n";

my $hgstatus = `hg status`;
if($hgstatus !~ /[AMD] /) {
	print "No changes observed. Skipping checking in.\n";
	exit;
}

my ($main,$sub,$rel) = GetVersion();

if($major == 1) {
	$main = $main + 1;
	$sub = 0;
	$rel = 0;
} elsif($minor == 1) {
	$sub = $sub + 1;
	$rel = 0;
} else {
	$rel = $rel + 1;
}

# Make version change in VERSION file
open VER,"+>VERSION" or die "Could not write to VERSION\n";
print VER "$main.$sub-$rel\n";
close(VER);

# Make version change in trsh.pl
open TRSH,"trsh.pl" or die "Could not find trsh.pl";
my @trsh = <TRSH>;
close(TRSH);
system("mv trsh.pl trsh.pl.orig");
open TRSH, "+>trsh.pl" or die "Could not create trsh.pl\n";
foreach my $entry (@trsh){
	$entry =~ s/\$VERSION = \"\d+\.\d+\-\d+\"/\$VERSION = \"$main\.$sub-$rel\"/;
	print TRSH $entry;
}
system("rm -f trsh.pl.orig");

# Make version change in README
open README,"README" or die "Could not find README";
my @readme = <README>;
close(README);
system("mv README README.orig");
open README, "+>README" or die "Could not create README\n";
foreach my $entry (@readme){
	$entry =~ s/Version \d+\.\d+-\d+/Version $main\.$sub-$rel/;
	print README $entry;
}
close(README);
system("rm -f README.orig");

print "REVISION($main.$sub-$rel) Checking Message (Single line):\n";
my $message = <STDIN>;
chomp($message);
system("hg commit -m \"$message\"");
system("hg push");

sub GetVersion
{
	my $verstr = `cat VERSION`;
	if($verstr =~ /(\d+)\.(\d+)-(\d+)/) {
		return ($1,$2,$3);
	}
	print "ERROR In reading VERSION File.\n";
	exit;
}
