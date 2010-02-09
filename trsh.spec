#####################################################################################
#				TRSH SPEC FILE                                      #
#     #*************************************************************************    #
#     # Copyright 2008 Amithash Prasad                                         *    #
#     #                                                                        *    #
#     # This file is part of trsh                                              *    #
#     #                                                                        *    #
#     # trsh is free software: you can redistribute it and/or modify           *    #
#     # it under the terms of the GNU General Public License as published by   *    #
#     # the Free Software Foundation, either version 3 of the License, or      *    #
#     # (at your option) any later version.                                    *    #
#     #                                                                        *    #
#     # This program is distributed in the hope that it will be useful,        *    #
#     # but WITHOUT ANY WARRANTY; without even the implied warranty of         *    #
#     # MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the          *    #
#     # GNU General Public License for more details.                           *    #
#     #                                                                        *    #
#     # You should have received a copy of the GNU General Public License      *    #
#     # along with this program.  If not, see <http://www.gnu.org/licenses/>.  *    #
#     #*************************************************************************    #
#                                                                                   #
#####################################################################################



#####################################################################################
#				  DESCERIPTION                                      #
#####################################################################################
Summary: A Trash manager aliased to rm.
Name: trsh
Version: 3.9
Release: 23
Group: Utilities
License: GPL
BuildArch: noarch
URL: http://code.google.com/p/trsh
Vendor: Amithash Prasad
Packager: Amithash Prasad <amithash@gmail.com>
Source: $RPM_SOURCE_DIR/trsh-2.2-212.tar.gz
Provides: trsh
Requires: perl(strict), perl(warnings), perl(File::Basename), perl(File::Spec), perl(Cwd), perl(Getopt::Long), perl(Fcntl), perl(Term::ANSIColor), perl(Term::ReadKey)

%description
Trsh is a trash manager with an attitude! Once aliased to rm
it provides a full wrapper to rm enabling the user to use it
just like he/she would with rm, with extra features like trash
listing, undo, recover, etc etc.

#####################################################################################
#				Prepare Scriot                                      #
#####################################################################################
%prep
rm -rf $RPM_BUILD_DIR/%name-%version-%release
zcat $RPM_SOURCE_DIR/%name-%version-%release.tar.gz | tar -xvf -
mkdir -p %buildroot/%_bindir
mkdir -p %buildroot/%_mandir/man1

#####################################################################################
#			      Post Install Script                                   #
#####################################################################################
%post

# Do not run the bashrc update if an upgrade.
if [ $1 ]
then
	if [ $1 -gt 1 ]
	then
		exit 0
	fi
fi

TRSH_SHELL=$SHELL
SHELL_NAME=${TRSH_SHELL##/bin/}
for rc in $(ls /etc/*rc* | grep $SHELL_NAME | grep -vP "\.bac$" | grep -vP "\.new$" )
do
	RC_FILE=$rc
done
if [ -z $RC_FILE ]
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
echo $ALIAS_RM >> $RC_FILE.new
echo $ALIAS_UNDO >> $RC_FILE.new
mv $RC_FILE.new $RC_FILE
	

#####################################################################################
#			         Install Script                                     #
#####################################################################################
%install
cp $RPM_BUILD_DIR/%name-%version-%release/trsh.pl %buildroot/%_bindir
cp $RPM_BUILD_DIR/%name-%version-%release/trsh.1.gz %buildroot/%_mandir/man1
chmod +x %buildroot/%_bindir/trsh.pl

exit 0

#####################################################################################
#			      Pre-Uninstall Script                                  #
#####################################################################################
%preun

# Do not run the update bashrc scripts if an update
if [ $1 ]
then
	if [ $1 -gt 0 ]
	then
		exit 0
	fi
fi

TRSH_SHELL=$SHELL
SHELL_NAME=${TRSH_SHELL##/bin/}
for rc in $(ls /etc/*rc* | grep $SHELL_NAME | grep -vP "\.bac$" | grep -vP "\.new$" )
do
	RC_FILE=$rc
done
if [ -z $RC_FILE ]
then
	echo "ERROR! No RC FILE Found"
	exit -127
fi

sed -e '/.* # TRSH/d' $RC_FILE > $RC_FILE.new
mv $RC_FILE.new $RC_FILE

exit 0

#####################################################################################
#			      Post Uninstall Script                                 #
#####################################################################################
%postun

rm -f %buildroot/%_bindir/trsh.pl
rm -f %buildroot/%_mandir/man1/trsh.1.gz

exit 0

#####################################################################################
#			           Verify Script                                    #
#####################################################################################
%verifyscript

TRSH_SHELL=$SHELL
SHELL_NAME=${TRSH_SHELL##/bin/}
for rc in $(ls /etc/*rc* | grep $SHELL_NAME | grep -vP "\.bac$" | grep -vP "\.new$" )
do
	RC_FILE=$rc
done
if [ -z $RC_FILE ]
then
	echo "ERROR! No RC FILE Found" >&2
	exit -127
fi
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

#####################################################################################
#			       Installation Files                                   #
#####################################################################################
%files
%_bindir/trsh.pl
%_mandir/man1/trsh.1.gz

