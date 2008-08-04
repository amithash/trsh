#!/usr/bin/perl

my $verstr = `cat VERSION`;
$verstr =~ /(\d+)\.(\d+)/;
my $main = $1;
my $sub  = $2;

my $rev = `svnversion`;
if($rev =~ /M/){
	print "There are modifications made. Please checkin and then create a package.\n";
	exit;
}
system("svn update");
$rev = `svnversion`;
if($rev =~ /^(\d+)/){
	$rev = $1 + 0;
}
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
# RUN THE CSH TESTS
if(-e "/bin/csh" or -e "/bin/tcsh"){
	if(system("./test-trsh.csh") != 0){
		print "Hey, your changes failed tests on csh.\n";
		print "NO PACKAGE FOR YOU\n";
		exit;
	}
} else {
	print "Tests are not performed for csh/tcsh as the shell was not found on your system. Please install it for a better package.\n";
}

# Only if these tests pass, allow the person to create the package.

print "version = $main.$sub-$rev\n";
my $name = "trsh-$main.$sub-$rev";
system("rm -rf ../$name") if(-d "../$name");
system("rm -rf ../$name.tar.gz") if(-e "../$name.tar.gz");
system("svn export . ../$name");

# Remove checkin.pl and mkpackage.pl from it.

# These scripts are not required for the user.
system("rm ../$name/checkin.pl");
system("rm ../$name/mkpackage.pl");
system("rm ../$name/test-trsh.bash");
system("rm ../$name/test-trsh.csh");
system("rm ../$name/VERSION");
chdir("..");
system("cp -r $name $name.src");
system("rm $name/trsh.sh");
system("rm $name/trsh.csh");
system("rm $name/trsh.spec");
system("tar -zcf $name.tar.gz $name");
system("rm -rf $name");
system("mkdir trsh-build");
system("mv $name.tar.gz trsh-build");
system("mv $name.src $name");
system("mv $name/trsh.spec .");
system("tar -zcf $name.tar.gz $name");
system("rm -r $name");
if(`id -u` ne "0"){
	print "Could not generate rpms. Run as root.\n";
	system("rm -r $name.tar.gz");
} else {
	system("mv $name /usr/src/redhat/SOURCE");
	system("rpmbuild -bb trsh.spec");
	system("mv /usr/src/redhat/RPMS/noarch/$name.rpm trsh-build");
}

my $pwd = `pwd`;
chomp($pwd);
print "PACKAGES ARE IN: $pwd/trsh-build\n";

