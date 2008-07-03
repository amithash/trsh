#!/usr/bin/perl

my ($main,$sub,$rev) = (2,0,`svnversion`);
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
if(system("./test-trsh.bash") != 0){
	print "Hey, your changes failed tests on bash.\n";
	print "NO PACKAGE FOR YOU\n";
	exit;
}
# RUN THE CSH TESTS
if(system("./test-trsh.csh") != 0){
	print "Hey, your changes failed tests on csh.\n";
	print "NO PACKAGE FOR YOU\n";
	exit;
}

# Only if these tests pass, allow the person to create the package.

print "version = $main.$sub.$rev\n";
my $name = "trsh-$main.$sub.$rev";
system("rm -rf ../$name") if(-d "../$name");
system("rm -rf ../$name.tar.gz") if(-e "../$name.tar.gz");
system("svn export . ../$name");

# Remove checkin.pl and mkpackage.pl from it.

# These scripts are not required for the user.
system("rm ../$name/checkin.pl");
system("rm ../$name/mkpackage.pl");
system("rm ../$name/test-trsh.bash");
system("rm ../$name/test-trsh.csh");

chdir("..");

system("tar -zcf $name.tar.gz $name");
system("rm -rf $name");

my $pwd = `pwd`;
print "PACKAGE IS: $pwd/$name.tar.gz\n";
print "Do you want to upload the package now? (y/n)[y]: ";
my $reply = <STDIN>;
$reply = "y" if($reply eq "\n");
chomp($reply);
exit unless($reply eq "y" or $reply eq "Y");

system("googlecode_upload.py -s \"$main.$sub.$rev\" -p trsh -u amithash -l FEATURED $name.tar.gz");

