#
# Spec file for trsh Trash Manager
#
Summary: A Trash manager aliased to rm.
Name: trsh
Version: 3.3
Release: 306
Group: Utilities
License: GPL
BuildArch: noarch
URL: http://code.google.com/p/trsh
Vendor: Amithash Prasad
Packager: Amithash Prasad <amithash@gmail.com>
Source: $RPM_SOURCE_DIR/trsh-2.2-212.tar.gz

%description
Trsh is a trash manager with an attitude! Once aliased to rm
it provides a full wrapper to rm enabling the user to use it
just like he/she would with rm, with extra features like trash
listing, undo, recover, etc etc.

%prep
rm -rf $RPM_BUILD_DIR/%name-%version-%release
zcat $RPM_SOURCE_DIR/%name-%version-%release.tar.gz | tar -xvf -
mkdir -p %buildroot/%_bindir
mkdir -p %buildroot/%_mandir/man1
mkdir -p %buildroot/etc/profile.d

%install
TRSH_SHELL=$SHELL
SHELL_NAME=${TRSH_SHELL##/bin/}
for rc in $(ls /etc/*rc* | grep $SHELL_NAME | grep -vP "\.bac$" | grep -vP "\.new$" )
do
	RC_FILE=$rc
done
if [[ $RC_FILE -eq "" ]]
then
	echo "ERROR! No RC FILE Found"
	exit -127
fi

if [[ $SHELL_NAME -eq "bash" ]]
then
	ALIAS_RM="alias rm=\"%_bindir/trsh.pl\" # TRSH"
	ALIAS_UNDO="alias undo=\"%_bindir/trsh.pl -u\" # TRSH"
elif [[ $SHELL_NAME -eq "csh" ]] || [[ $SHELL_NAME -eq "tcsh" ]]
then
	ALIAS_RM="alias rm \"%_bindir/trsh.pl\" # TRSH"
	ALIAS_UNDO="alias undo \"%_bindir/trsh.pl -u\" # TRSH"
else
	exit -127
fi
sed -e '/.* # TRSH/d' $RC_FILE > $RC_FILE.new
echo \"$ALIAS_RM\" >> $RC_FILE.new
echo \"$ALIAS_UNDO\" >> $RC_FILE.new
cp $RPM_BUILD_DIR/%name-%version-%release/trsh.pl %buildroot/%_bindir
cp $RPM_BUILD_DIR/%name-%version-%release/trsh.1.gz %buildroot/%_mandir/man1
chmod +x %buildroot/%_bindir/trsh.pl
echo "mv $RC_FILE.new $RC_FILE"
exit 0

%preun
TRSH_SHELL=$SHELL
SHELL_NAME=${TRSH_SHELL##/bin/}
for rc in $(ls /etc/*rc* | grep $SHELL_NAME | grep -vP "\.bac$" | grep -vP "\.new" )
do
	RC_FILE=$rc
done
if [[ $RC_FILE -eq "" ]]
then
	echo "ERROR! No RC FILE Found"
	exit -127
fi

sed -e '/.* # TRSH/d' $RC_FILE > $RC_FILE.new
rm -f %buildroot/%_bindir/trsh.pl
rm -f %buildroot/%_mandir/man1/trsh.1.gz
mv $RC_FILE.new $RC_FILE
exit 0

%files
%_bindir/trsh.pl
%_mandir/man1/trsh.1.gz

