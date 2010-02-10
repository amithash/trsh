#!/usr/bin/perl

use strict;
use warnings;
my $hgstatus = `hg status`;
if($hgstatus =~ /M /) {
	goto CONTINUE;
}
if($hgstatus =~ /A /) {
	goto CONTINUE;
}
if($hgstatus =~ /D /) {
	goto CONTINUE;
}

CONTINUE:

my $verstr = `cat VERSION`;
$verstr =~ /(\d+)\.(\d+)-(\d+)/;
my $main = $1;
my $sub  = $2;
my $rel = $3;
$rel = $rel + 1;
open VER,"+>VERSION" or die "Could not write to VERSION\n";
print VER "$main.$sub-$rel\n";
close(VER);

open TRSH,"trsh.pl" or die "Could not find trsh.pl";
my @trsh = <TRSH>;
close(TRSH);
system("mv trsh.pl trsh.pl.orig");
open TRSH, "+>trsh.pl" or die "Could not create trsh.pl\n";
foreach my $entry (@trsh){
	$entry =~ s/\$VERSION = \"\d+\.\d+\-\d+\"/\$VERSION = \"$main\.$sub-$rel\"/;
	print TRSH $entry;
}

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
system("rm -f README.orig trsh.pl.orig");

print "REVISION($main.$sub-$rel) Checking Message (Single line):\n";
my $message = <STDIN>;
chomp($message);
system("hg commit -m \"$message\"");
system("hg push");

