#!/usr/bin/perl

use strict;
use warnings;
use Cwd;





my $this_dir = cwd();
my $home = $ENV{HOME};

if(RepoClean() == 0) {
	print "Repo is modified. Please checkin changes or revert changes before making a package.\n";
	exit;
}

my ($main,$sub,$rev) = GetVersion();
my $name = "trsh-$main.$sub-$rev";

if(RunTests() == 0) {
	print "Tests failed. No point in making a package.\n";
	exit;
}

print "version = $main.$sub-$rev\n";

# Clean junk.
system("rm -rf $home/$name") if(-d "$home/$name");
system("rm -rf $home/$name.tar.gz") if(-e "$home/$name.tar.gz");

# Get an archive from the repo
system("hg archive -X mkpackage.pl -X checkin.pl -X VERSION -X test-trsh.bash $home/$name");

chdir($home);
system("rm -rf trsh-build") if(-d "trsh-build");
system("mkdir trsh-build");
system("mv $name $name.src");

MakeTGZ();

MakeRPM();

MakeDEB();

system("rm -rf $name.src");
chdir("$home");
system("rm -r trsh.spec");
chdir("$home/trsh-build");
system("cp * $this_dir/");

#############################################################################################
##################################### FUNCTIONS #############################################
#############################################################################################

sub GetVersion
{
	my $verstr = `cat VERSION`;
	if($verstr =~ /(\d+)\.(\d+)-(\d+)/) {
		return ($1,$2,$3);
	}
	print "ERROR In reading VERSION File.\n";
	exit;
}

sub RepoClean
{
	my $srev = `hg status`;
	if($srev =~ /[MAD] / ){
		return 0;
	}
	system("hg pull");
	return 1;
}

sub RunTests
{
	if(-e "/bin/bash"){
		if(system("./test-trsh.bash") != 0){
			return 0;
		}
	} else {
		print "Tests are not performed for bash as the shell was not found on your system. Please install it for a better package.\n";
		return 0;
	}
	system("hg revert --all");
	return 1;
}

sub MakeTGZ
{
	system("cp -r $name.src $name");
	system("rm $name/trsh.spec $name/control $name/postinst $name/postrm $name/prerm");
	system("tar -zcf $name.tar.gz $name");
	system("rm -rf $name");
	system("mv $name.tar.gz trsh-build");
}

sub MakeRPM
{
	my $packages_dir = "/usr/src/packages";

	# If not opensuse, redhat.
	unless(-d $packages_dir) {
		$packages_dir = "/usr/src/redhat";
	}

	# If neither, not a rpm based system. Do not know how to make a package.
	unless(-d $packages_dir) {
		print "Unknown distribution: neither of /usr/src/packages (SuSE) or /usr/src/redhat (Redhat) exists\n";
		return;
	}

	# Check if rpmbuild exists.
	if(`which rpmbuild` =~ /no rpmbuild in/) {
		print "rpmbuild is not installed on the system. Skipping rpm generation.\n";
		return;
	}

	# Right now, I need root privs to make a build.
	if(`id -u` ne "0\n"){
		print "Cannot produce rpm package without root permission. Skipping rpm generation\n";
		return;
	}

	system("cp -r $name.src $name");
	system("mv $name/trsh.spec .");
	system("rm $name/configure.pl $name/control $name/postinst $name/postrm $name/prerm");
	system("tar -zcf $name.tar.gz $name");
	system("rm -rf $name");
	system("mv $name.tar.gz $packages_dir/SOURCES") == 0 or die "could not move source to SOURCE dir\n";
	system("rpmbuild -bb trsh.spec") == 0 or die "rpmbuild failed\n";
	system("mv $packages_dir/RPMS/noarch/$name.noarch.rpm trsh-build");
	system("rm -rf $name");
}

sub MakeDEB
{
	if(`which dpkg` =~ /no dpkg in/) {
		print "dpkg is not installed on the system. Skipping deb generation.\n";
		return;
	}

	system("mkdir $name");
	system("mkdir $name/DEBIAN");
	Create_File("$name/DEBIAN/control", DEB_control());
	Create_File("$name/DEBIAN/postinst", DEB_postinst());
	Create_File("$name/DEBIAN/prerm", DEB_prerm());
	system("mkdir -p $name/usr/bin");
	system("mkdir -p $name/usr/share/doc/trsh");
	system("mkdir -p $name/usr/share/man/man1");
	system("cp $name.src/trsh.pl $name/usr/bin");
	system("chmod +x $name/usr/bin/trsh.pl");
	system("cp $name.src/trsh.1.gz $name/usr/share/man/man1");
	system("cp $name.src/README $name/usr/share/doc/trsh");
	system("cp $name.src/COPYING.GPL $name/usr/share/doc/trsh/copyright");
	system("dpkg -b $name");
	system("mv $name.deb trsh-build");
	system("rm -rf $name");
}

sub GetDescString
{

return "A Trash manager aliased to rm.Trsh is a trash manager
  with an attitude! Once aliased to rm
  it provides a full wrapper to rm enabling the user to use it
  just like he/she would with rm, with extra features like trash
  listing, undo, recover, etc etc.";
}

sub Create_File
{
	my $file	=	shift;
	my $cont	=	shift;
	open OUT,"+>$file" or die "Could not create $file\n";
	print OUT "$cont\n";
	close(OUT);
}

sub DEB_control
{
	return "Package: trsh
Version: $main.$sub-$rev
Architecture: all
Maintainer: Amithash Prasad <amithash\@gmail.com>
Installed-Size: 100
Section: utils
Priority: extra
Description: " . GetDescString();
}

sub DEB_postinst
{
	return "#!/bin/bash\n\n" . CheckRC() . AddAlias() . "\nexit 0\n";
}

sub DEB_prerm
{
	return "#!/bin/bash\n\n" . CheckRC() . RemoveAlias() . "\nexit 0\n";
}

sub RemoveAlias
{
	return '
sed -e \'/.* # TRSH/d\' $RC_FILE > $RC_FILE.new
mv $RC_FILE.new $RC_FILE
';
}

sub AddAlias
{
	return '
if [[ $SHELL_NAME -eq "bash" ]]
	ALIAS_RM="alias rm=\"/usr/bin/trsh.pl\" # TRSH"
	ALIAS_UNDO="alias undo=\"/usr/bin/trsh.pl -u\" # TRSH"
elif [[ $SHELL_NAME -eq "csh" ]] || [[ $SHELL_NAME -eq "tcsh" ]]
then
	ALIAS_RM="alias rm \"/usr/bin/trsh.pl\" # TRSH"
	ALIAS_UNDO="alias undo \"/usr/bin/trsh.pl -u\" # TRSH"
else
	exit 
fi
sed -e \'/.* # TRSH/d\' $RC_FILE > $RC_FILE.new
echo $ALIAS_RM >> $RC_FILE.new
echo $ALIAS_UNDO >> $RC_FILE.new
mv $RC_FILE.new $RC_FILE
';
}

sub CheckRC
{
	return '
TRSH_SHELL=$SHELL
SHELL_NAME=${TRSH_SHELL##/bin/}
for rc in $( ls /etc/*rc* | grep $SHELL_NAME | grep -vP "\.bac$" | grep -vP "\.new$" )
do
	RC_FILE=$rc
done
if [ -z $RC_FILE ]
then
	echo "ERROR! No RC FILE Found"
	exit -127
fi
'
}

