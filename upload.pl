#!/usr/bin/perl
use strict;
use warnings;
use Cwd;

my $home = $ENV{HOME};

unless(-e "$home/googlecode_upload.py") {
	print "Could not find googlecode_upload.py. Downloading it...\n";
	my $this = cwd();
	chdir($home);
	system("wget http://support.googlecode.com/svn/trunk/scripts/googlecode_upload.py\n");
	chdir($this);
}

my $gc_upload = "$home/googlecode_upload.py";

my @files = <$home/trsh-build/*>;
my $rpm = "";
my $deb = "";
my $tgz = "";
my $vers = "";
foreach my $f (@files) {
	if ($f =~ /trsh-(\d+)\.(\d+)-(\d+).tar.gz/) {
		$tgz = "$f";
		$vers = "$1.$2-$3";
	}
	if ($f =~ /trsh-(\d+)\.(\d+)-(\d+).noarch.rpm/) {
		$rpm = "$f";
	}
	if ($f =~ /trsh-(\d+)\.(\d+)-(\d+).deb/) {
		$deb = "$f";
	}
}
if($vers eq "") {
	print "No uploadable files present in $home/trsh-build\n";
	exit;
}

UploadFile($tgz, "Version $vers Source package");
UploadFile($rpm, "Version $vers RPM package (Fedora/SuSE)");
UploadFile($deb, "Version $vers Deb package (Ubuntu/Debian)");

print "\n\n==========================================================================================\n";
print     "All files provided uploaded. Please go to the project page and deprecate older versions...\n";
print     "==========================================================================================\n\n";

sub UploadFile
{
	my $file	=	shift;
	my $summ	=	shift;

	if($file eq "") {
		return;
	}
	my $pwdf = "$home/.google-code-password";
	print "Getting password from file: $home/.google-code-password\n";
	unless(-e "$pwdf") {
		print "Could not find file $pwdf\n";
		print "Create the following file and place your googlecode password there...\n";
		return;
	}
	my $pwd = `cat $pwdf`;
	chomp($pwd);
	print "Uploading $file\n";

	system("python $gc_upload -p trsh -u amithash -w $pwd -s \"$summ\" -l Featured $file") == 0 or print "Upload failed...\n";
}


