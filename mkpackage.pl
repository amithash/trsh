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
my $home = $ENV{HOME};
system("rm -rf $home/$name") if(-d "$home/$name");
system("rm -rf $home/$name.tar.gz") if(-e "$home/$name.tar.gz");
system("svn export . $home/$name");

# Remove checkin.pl and mkpackage.pl from it.

# These scripts are not required for the user.
system("rm $home/$name/checkin.pl");
system("rm $home/$name/mkpackage.pl");
system("rm $home/$name/test-trsh.bash");
system("rm $home/$name/test-trsh.csh");
system("rm $home/$name/VERSION");
chdir("$home");
system("cp -r $name $name.src");
system("rm $name/trsh.sh");
system("rm $name/trsh.csh");
system("rm $name/trsh.spec");
system("tar -zcf $name.tar.gz $name");
system("rm -rf $name");
system("rm -rf trsh-build") if(-d "trsh-build");
system("mkdir trsh-build");
system("mv $name.tar.gz trsh-build");
system("mv $name.src $name");
system("mv $name/trsh.spec .");
system("tar -zcf $name.tar.gz $name");
system("rm -r $name");
if(`id -u` eq "0\n"){
	system("mv $name.tar.gz /usr/src/redhat/SOURCE") == 0 or die "could not move source to SOURCE dir\n";
	system("rpmbuild -bb trsh.spec") == 0 or die "rpmbuild failed\n";
	system("mv /usr/src/redhat/RPMS/noarch/$name.rpm trsh-build");
} else {
	print "Not a root user, no rpm for you\n";
}
system("rm -r trsh.spec");

my $pwd = `pwd`;
chomp($pwd);
print "PACKAGES ARE IN: $pwd/trsh-build\n";

