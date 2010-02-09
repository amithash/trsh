#!/usr/bin/perl

use strict;
use warnings;
use Cwd;

my $this_dir = cwd();

my $packages_dir = "/usr/src/packages";
unless(-d $packages_dir) {
	$packages_dir = "/usr/src/redhat";
}

my $verstr = `cat VERSION`;
$verstr =~ /(\d+)\.(\d+)-(\d+)/;
my $main = $1;
my $sub  = $2;
my $rev = $3;

# Make sure there are no modifications. The last thing one needs is
# version strings to not indicate the actual content in the repo!
my $srev = `hg status`;
if($srev =~ /M /){
	print "There are modifications made. Please checkin and then create a package.\n";
	exit;
}

# Make sure to pull any updates in the remote repo.
system("hg pull");

# RUN THE BASH TESTS
if(-e "/bin/bash"){
	if(system("./test-trsh.bash") != 0){
		print "Hey, your changes failed tests on bash.\n";
		print "NO PACKAGE FOR YOU\n";
		exit;
	}
} else {
	print "Tests are not performed for bash as the shell was not found on your system. Please install it for a better package.\n";
}

# Only if these tests pass, allow the person to create the package.

print "version = $main.$sub-$rev\n";
my $name = "trsh-$main.$sub-$rev";
my $home = $ENV{HOME};
system("rm -rf $home/$name") if(-d "$home/$name");
system("rm -rf $home/$name.tar.gz") if(-e "$home/$name.tar.gz");
system("hg archive -X mkpackage.pl -X checkin.pl -X VERSION -X test-trsh.bash $home/$name")
chdir("$home");
system("cp -r $name $name.src");
system("rm $name/trsh.spec");
system("tar -zcf $name.tar.gz $name");
system("rm -rf $name");
system("rm -rf trsh-build") if(-d "trsh-build");
system("mkdir trsh-build");
system("mv $name.tar.gz trsh-build");
system("mv $name.src $name");
system("mv $name/trsh.spec .");
system("rm $name/configure.pl");
system("tar -zcf $name.tar.gz $name");
system("rm -r $name");
if(`id -u` eq "0\n"){
	unless(-d $packages_dir) {
		print "Unknown distribution: neither of /usr/src/packages (SuSE) or /usr/src/redhat (Redhat) exists\n";
		system("rm -r trsh.spec");
		exit;
	}
	system("mv $name.tar.gz $packages_dir/SOURCES") == 0 or die "could not move source to SOURCE dir\n";
	system("rpmbuild -bb trsh.spec") == 0 or die "rpmbuild failed\n";
	system("mv $packages_dir/RPMS/noarch/$name.noarch.rpm trsh-build");
	chdir("$home/trsh-build");
	system("alien -k --scripts $name.noarch.rpm") == 0 or die "Could not create deb package.\n";
} else {
	print "Not a root user, no rpm or deb for you\n";
}
chdir("$home");
system("rm -r trsh.spec");
chdir("$home/trsh-build");
system("cp * $this_dir/");

