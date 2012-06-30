#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

my $home = $ENV{HOME};

my $upload = 1;
my $rpm = 1;
my $deb = 1;
my $debug = 0;

GetOptions(
	'upload!' => \$upload,
	'rpm!' => \$rpm,
	'deb!' => \$deb,
	'debug' => \$debug
);

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

print "making package for version = $main.$sub-$rev\n";

# Clean junk.
system("rm -rf $home/$name") if(-d "$home/$name");
system("rm -rf $home/$name.tar.gz") if(-e "$home/$name.tar.gz");
system("rm -rf $home/trsh-build") if(-d "$home/trsh-build");
system("mkdir $home/trsh-build");

# Get an archive from the repo
system("git archive --prefix=$name/ HEAD | gzip > $home/$name.tar.gz");
chdir($home);
system("tar -xf $name.tar.gz");
chdir "$name.tar.gz";
unlink "mkpackage.pl";
unlink "checkin.pl";
unlink "test-trsh.bash";
unlink "VERSION";
chdir "$home";
unlink "$name.tar.gz";

system("mv $name $name.src");
chdir("$name.src");
system("gzip trsh.1");
chdir($home);

MakeTGZ();

if($rpm) {
	MakeRPM();
}

if($deb) {
	MakeDEB();
}

chdir("$home");
system("rm -rf $name.src");
chdir "$home/trsh-build";

if($upload) {
	my @pkgs = ("$name.tar.gz");
	if($rpm) {
		push @pkgs, "$name.noarch.rpm";
	}
	if($deb) {
		push @pkgs, "$name.deb";
	}
	UploadAllFiles(@pkgs);
	print "Uploaded files to googleCode! Make sure to visit it and mark all old packages as deprecated\n";
}

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
	my $srev = `git status`;
	if($srev =~ /modified:\s+/) {
		return 0;
	}
	if($srev =~ /added:\s+/) {
		return 0;
	}
	if($srev =~ /deleted:\s+/) {
		return 0;
	}
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
	return 1;
}

sub IsCommandInstalled
{
	my $cmd		=	shift;
	my $output = `which $cmd`;
	if($output =~ /no $cmd in/) {
		return 0;
	}
	if($output =~ /^\s*$/) {
		return 0;
	}
	return 1;
}

sub MakeTGZ
{
	system("cp -r $name.src $name");
	system("tar -zcf $name.tar.gz $name");
	system("rm -rf $name");
	system("mv $name.tar.gz trsh-build");
}

sub MakeRPM
{
	# Check if rpmbuild exists.
	if(IsCommandInstalled("rpmbuild") == 0) {
		print "rpmbuild is not installed on the system. Skipping rpm generation.\n";
		return;
	}

	my $packages_dir = "$home/packages";
	system("rm -f $home/.rpmmacros") if(-e "$home/.rpmmacros");
	Create_File("$home/.rpmmacros",'%_topdir ' . "$home/packages");
	system("rm -rf $packages_dir") if(-d $packages_dir);
	system("mkdir -p $packages_dir/BUILD");
	system("mkdir -p $packages_dir/RPMS");
	system("mkdir -p $packages_dir/RPMS/i386");
	system("mkdir -p $packages_dir/RPMS/i686");
	system("mkdir -p $packages_dir/RPMS/noarch");
	system("mkdir -p $packages_dir/SOURCES");
	system("mkdir -p $packages_dir/SPECS");
	system("mkdir -p $packages_dir/SRPMS");

	system("cp -r $name.src $name");
	system("rm $name/configure.pl");
	system("tar -zcf $name.tar.gz $name");
	system("rm -rf $name");
	system("mv $name.tar.gz $packages_dir/SOURCES") == 0 or die "could not move source to SOURCE dir\n";

	Create_File("trsh.spec", RPM_control() . RPM_description() . RPM_prep() . RPM_post() . RPM_install() . RPM_preun() . RPM_postun() . RPM_verify() . RPM_files());
	system("rpmbuild -bb trsh.spec > /dev/null 2> /dev/null") == 0 or die "rpmbuild failed\n";
	system("mv $packages_dir/RPMS/noarch/$name.noarch.rpm trsh-build");
	system("rm -rf $name");
	system("rm -rf trsh.spec");
	system("rm -rf $packages_dir");
}

sub MakeDEB
{
	if(IsCommandInstalled("dpkg") == 0) {
		print "dpkg is not installed on the system. Skipping deb generation.\n";
		return;
	}

	system("mkdir $name");
	system("mkdir $name/DEBIAN");
	Create_File("$name/DEBIAN/control", DEB_control());
	Create_File("$name/DEBIAN/postinst", DEB_postinst());
	Create_File("$name/DEBIAN/prerm", DEB_prerm());
	system("chmod 0755 $name/DEBIAN/postinst");
	system("chmod 0755 $name/DEBIAN/prerm");
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
	if($debug == 0) {
		system("rm -rf $name");
	}
}

sub RPM_control
{
	return "
Summary: A Trash manager aliased to rm.
Name: trsh
Version: $main.$sub
Release: $rev
Group: Utilities
License: GPL
BuildArch: noarch
URL: http://code.google.com/p/trsh
Vendor: Amithash Prasad
Packager: Amithash Prasad <amithash\@gmail.com>
Source: \$RPM_SOURCE_DIR/trsh-$main.$sub-$rev.tar.gz
Provides: trsh
Requires: libfile-basename-perl, libfile-spec-perl, libcwd-perl, libgetopt-long-perl, libfcntl-perl , libterm-ansicolor-perl, libterm-readkey-perl
";
}

sub RPM_description
{
	return '
%description
' . GetDescString();
}

sub RPM_prep
{
	return '
%prep
rm -rf $RPM_BUILD_DIR/%name-%version-%release
zcat $RPM_SOURCE_DIR/%name-%version-%release.tar.gz | tar -xvf -
mkdir -p %buildroot/%_bindir
mkdir -p %buildroot/%_mandir/man1
';
}

sub RPM_post
{
	return '
%post
if [ $1 -gt 1 ]
then
	exit 0
fi
' . CheckRC() . AddAlias();
}

sub RPM_install
{
	return '
%install
cp $RPM_BUILD_DIR/%name-%version-%release/trsh.pl %buildroot/%_bindir
cp $RPM_BUILD_DIR/%name-%version-%release/trsh.1.gz %buildroot/%_mandir/man1
chmod +x %buildroot/%_bindir/trsh.pl
exit 0
';
}

sub RPM_preun
{
	return '
%preun
if [ $1 -gt 0 ]
then
	exit 0
fi
' . CheckRC() . RemoveAlias() . "\nexit 0\n";
}

sub RPM_postun
{
	return '
%postun
rm -f %buildroot/%_bindir/trsh.pl
rm -f %buildroot/%_mandir/man1/trsh.1.gz
exit 0
';

}

sub RPM_verify
{
	return '%verifyscript\n\n' . CheckRC() . '
RC_TEST=`grep "# TRSH" $RC_FILE | wc -l`
if [ $RC_TEST -ne 2 ]
then
	echo "Alias entries not found in $RC_FILE" >&2
	exit -127
fi

if [ ! -e %_bindir/trsh.pl ]
then
	echo "trsh.pl not found in %_bindir" >&2
	exit -127
fi

if [ ! -e %_mandir/man1/trsh.1.gz ]
then
	echo "Man page not found in %_mandir/man1/" >&2
	exit -127
fi
exit 0
';
}

sub RPM_files
{
	return '
%files
%_bindir/trsh.pl
%_mandir/man1/trsh.1.gz
';
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
then
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
for rc in $( ls /etc/*rc* | grep $SHELL_NAME | grep -vP "\.bac$" | grep -vP "\.new$" | grep -vP "\.dpkg" )
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

sub Upload
{
	my $user = shift;
	my $password = shift;
	my $file = shift;
	my $project = "trsh";
	my $labels = "Featured";
	my $googlecode_upload_url = "http://support.googlecode.com/svn/trunk/scripts/googlecode_upload.py";
	my $googlecode_upload = "googlecode_upload.py";
	if(! -e $googlecode_upload) {
		system("wget", $googlecode_upload_url);
		if(! -e $googlecode_upload) {
			return 0;
		}
	}
	my $summary = "Version $main.$sub-$rev ";
	if($file =~ /\.deb$/) {
		$summary .= "Deb package (Ubuntu/Debian)";
	} elsif($file =~ /\.rpm$/) {
		$summary .= "RPM package (Fedora/SuSE)";
	} elsif($file =~ /\.tar\.gz/) {
		$summary .= "Source Package";
	} else {
		printf "Unknown file type $file\n";
		return 0;
	}
	$summary = "\"$summary\"";
	my $rc = system("python", $googlecode_upload, "-u", "$user", "-w", $password, "-p", "$project", "-s", $summary, "-l", $labels, $file);
	if($rc != 0) {
		return 0;
	}
	return 1;
}

sub UploadAllFiles
{
	my @files = @_;
	my ($user, $password) = GetUserCred();
	if($user eq "" or $password eq "") {
		print "Invalid cred!\n";
		return;
	}
	foreach my $f (@files) {
		my $rc = Upload($user, $password, $f);
		if($rc == 0) {
			printf "Failed to upload $f\n";
			return;
		}
	}
}
sub GetUserCred
{
	my $user = "";
	my $password = "";
	my $home = $ENV{HOME};
	if(! -d $home) {
		return GetUserCredPrompt();
	}
	my $file = "$home/.googlecode";
	if(! -e $file) {
		return GetUserCredPrompt();
	}
	open IN, "$file" or return GetUserCredPrompt();
	while(my $line = <IN>) {
		chomp($line);
		if($line =~ /USER\s+=\s+(.+)\s*$/) {
			$user = $1;
		}
		if($line =~ /PASSWORD\s+=\s+(.+)\s*$/) {
			$password = $1;
		}
	}
	close(IN);
	if($user eq "" or $password eq "") {
		return GetUserCredPrompt();
	}
	return ($user, $password);
}

sub GetUserCredPrompt
{
	print "Enter User name: ";
	my $user = <STDIN>;
	chomp($user);
	if($user =~ /^\s*$/) {
		print "Invalid user!\n";
		return ("", "")
	}
	print "Enter password: ";
	my $password = <STDIN>;
	chomp($password);
	if($password =~ /^\s*$/) {
		print "Invalid password!\n";
		return ("", "");
	}
	return ($user, $password);
}
