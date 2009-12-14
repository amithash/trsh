#
# Spec file for trsh Trash Manager
#
Summary: A Trash manager aliased to rm.
Name: trsh
Version: 3.3
Release: 301
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
cp $RPM_BUILD_DIR/%name-%version-%release/trsh.pl %buildroot/%_bindir
cp $RPM_BUILD_DIR/%name-%version-%release/trsh.1.gz %buildroot/%_mandir/man1
cp $RPM_BUILD_DIR/%name-%version-%release/trsh.bash %buildroot/etc/profile.d/
cp $RPM_BUILD_DIR/%name-%version-%release/trsh.csh %buildroot/etc/profile.d/
chmod +x %buildroot/%_bindir/trsh.pl
#echo "alias rm=\"/usr/bin/trsh.pl\" # TRSH" >> /etc/bash.bashrc
#echo "alias undo=\"/usr/bin/trsh.pl -u\" # TRSH" >> /etc/bash.bashrc
exit 0

%preun
rm -f %buildroot/%_bindir/trsh.pl
rm -f %buildroot/%_mandir/man1/trsh.1.gz
#sed -e '/.* # TRSH/d' /etc/bash.bashrc > /etc/bash.bashrc.new
#mv /etc/bash.bashrc.new /etc/bash.bashrc
rm -f %buildroot/etc/profile.d/trsh.bash
rm -f %buildroot/etc/profile.d/trsh.csh
exit 0

%files
%_bindir/trsh.pl
%_mandir/man1/trsh.1.gz
/etc/profile.d/trsh.bash
/etc/profile.d/trsh.csh

