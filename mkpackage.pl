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
if(system("./test-trsh.bash") != 0){
	print "Hey, your changes failed tests.\n";
	print "NO PACKAGE FOR YOU\n";
	exit;
}

print "version = $main.$sub.$rev\n";
my $name = "trsh-$main.$sub.$rev";
system("rm -rf ../$name") if(-d "../$name");
system("rm -rf ../$name.tar.gz") if(-e "../$name.tar.gz");
system("svn export . ../$name");

# Remove checkin.pl and mkpackage.pl from it.

system("rm ../$name/checkin.pl");
system("rm ../$name/mkpackage.pl");

chdir("..");

system("tar -zcf $name.tar.gz $name");
system("rm -rf $name");

my $pwd = `pwd`;
print "PACKAGE IS: $pwd/$name.tar.gz\n";


