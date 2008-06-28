#!/bin/bash
#*************************************************************************
# Copyright 2008 Amithash Prasad                                         *
#									 *
# this file is part of trsh.						 *
#                                                                        *
# trsh is free software: you can redistribute it and/or modify           *
# it under the terms of the GNU General Public License as published by   *
# the Free Software Foundation, either version 3 of the License, or      *
# (at your option) any later version.                                    *
#                                                                        *
# This program is distributed in the hope that it will be useful,        *
# but WITHOUT ANY WARRANTY; without even the implied warranty of         *
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the          *
# GNU General Public License for more details.                           *
#                                                                        *
# You should have received a copy of the GNU General Public License      *
# along with this program.  If not, see <http://www.gnu.org/licenses/>.  *
#*************************************************************************

echo "Backing up existing trash."
if [ -d $HOME/.Trash ]
then
	mv $HOME/.Trash $HOME/.Trash_backup
fi
export PATH=`pwd`:$PATH

echo "Using trsh from location: `which trsh.pl`"

PASSED_COUNT=0
TOTAL_COUNT=0

cd $HOME
trsh.pl
##################################################################################

# TEST 1
TOTAL_COUNT=$(( $TOTAL_COUNT+1 ))
echo "TEST 1: Tests .Trash creation"
if [ -d $HOME/.Trash ]
then
	echo "TEST 1 PASSED: Trash exists" >&2
	PASSED_COUNT=$(( $PASSED_COUNT+1 ))
else
	echo "TEST 1 FAILED: Trash does not exist" >&2
fi
##################################################################################

# TEST 2
TOTAL_COUNT=$(( $TOTAL_COUNT+1 ))
echo "TEST 2: Tests .history creation"
if [ -e $HOME/.Trash/.history ]
then
	echo "TEST 2 PASSED: history exists" >&2
	PASSED_COUNT=$(( $PASSED_COUNT+1 ))
else
	echo "TEST 2 FAILED: history does not exist" >&2
fi
##################################################################################

# TEST 3 remove
echo "TEST 3: Tests basic file delete"
cd $HOME
touch test_trsh3
trsh.pl test_trsh3
TOTAL_COUNT=$(( $TOTAL_COUNT+1 ))
if [ -e $HOME/.Trash/test_trsh3______0 ]
then
	echo "TEST 3A PASSED: file test_trsh3 exists in trash" >&2
	PASSED_COUNT=$(( $PASSED_COUNT+1 ))
else
	echo "TEST 3A FAILED: file test_trsh3 does not exist in trash" >&2
fi
##################################################################################
TOTAL_COUNT=$(( $TOTAL_COUNT+1 ))
if [ -e $HOME/test_trsh3 ]
then
	echo "TEST 3B FAILED: file test_trsh3 not deleted" >&2
else
	echo "TEST 3B PASSED: file test_trsh3 deleted" >&2
	PASSED_COUNT=$(( $PASSED_COUNT+1 ))
fi
##################################################################################
# TEST 4 recover
echo "TEST 4: Tests basic file recovery"
cd $HOME
trsh.pl -u test_trsh3
TOTAL_COUNT=$(( $TOTAL_COUNT+1 ))
if [ -e $HOME/.Trash/test_trsh3 ]
then
	echo "TEST 4A FAILED: file test_trsh3 exists in trash" >&2
else
	echo "TEST 4A PASSED: file test_trsh3 does not exist in trash" >&2
	PASSED_COUNT=$(( $PASSED_COUNT+1 ))
fi
##################################################################################
TOTAL_COUNT=$(( $TOTAL_COUNT+1 ))
if [ -e $HOME/test_trsh3 ]
then
	echo "TEST 4B PASSED: file test_trsh3 recovered" >&2
	PASSED_COUNT=$(( $PASSED_COUNT+1 ))
else
	echo "TEST 4B FAILED: file test_trsh3 not recovered" >&2
fi
##################################################################################
/bin/rm test_trsh3

# TEST 5 delete multiple files
echo "TEST 5 test_trshs delete multiple files"
cd $HOME
touch test_trsh41 
touch test_trsh42
touch test_trsh43
trsh.pl test_trsh41 test_trsh42 test_trsh43
TOTAL_COUNT=$(( $TOTAL_COUNT+1 ))
if [ -e $HOME/.Trash/test_trsh41______0 ] && [ -e $HOME/.Trash/test_trsh42______0 ] && [ -e $HOME/.Trash/test_trsh43______0 ]
then
	echo "TEST 5A PASSED: Files test_trsh41 test_trsh42 and test_trsh43 exist in Trash" >&2
	PASSED_COUNT=$(( $PASSED_COUNT+1 ))
else
	echo "TEST 5A FAILED: Files test_trsh41 test_trsh42 and test_trsh43 do not exist in Trash" >&2
fi
##################################################################################
TOTAL_COUNT=$(( $TOTAL_COUNT+1 ))
if [ -e $HOME/test_trsh41 ] && [ -e $HOME/test_trsh42 ] && [ -e $HOME/test_trsh43 ]
then
	echo "TEST 5B FAILED: Files test_trsh41 test_trsh42 and test_trsh43 not deleted" >&2
else
	echo "TEST 5B PASSED: Files test_trsh41 test_trsh42 and test_trsh43 are deleted" >&2
	PASSED_COUNT=$(( $PASSED_COUNT+1 ))
fi

##################################################################################
# TEST 6 trsh.pl -u
echo "TEST 6 test_trshs trsh.pl -u"
trsh.pl -u
TOTAL_COUNT=$(( $TOTAL_COUNT+1 ))
if [ -e $HOME/test_trsh43 ]
then
	echo "TEST 6A PASSED: File test_trsh43 recovered" >&2
	PASSED_COUNT=$(( $PASSED_COUNT+1 ))
else
	echo "TEST 6A FAILED: File test_trsh43 not recovered" >&2
fi
##################################################################################
TOTAL_COUNT=$(( $TOTAL_COUNT+1 ))
if [ -e $HOME/.Trash/test_trsh43 ]
then
	echo "TEST 6B FAILED: File test_trsh43 exists in trash" >&2
else
	echo "TEST 6B PASSED: File test_trsh43 does not exist in trash" >&2
	PASSED_COUNT=$(( $PASSED_COUNT+1 ))
fi
##################################################################################

# TEST 7 Multiple files with same name
echo "TEST 7: test_trshs multi files same name"
touch test_trsh5
trsh.pl test_trsh5
touch test_trsh5
trsh.pl test_trsh5
touch test_trsh5
trsh.pl test_trsh5
TOTAL_COUNT=$(( $TOTAL_COUNT+1 ))
if [ -e $HOME/.Trash/test_trsh5______0 ] && [ -e $HOME/.Trash/test_trsh5______1 ] && [ -e $HOME/.Trash/test_trsh5______2 ]
then
	echo "TEST 7 PASSED: All three files deleted and exist in trash" >&2
	PASSED_COUNT=$(( $PASSED_COUNT+1 ))
else
	echo "TEST 7 FAILED: All three files not deleted and do not exist in the trash" >&2
fi
##################################################################################

# TEST 8 recover using trsh.pl -u
echo "TEST 8: test_trshs recover with multiple files."
trsh.pl -u
TOTAL_COUNT=$(( $TOTAL_COUNT+1 ))
if [ -e $HOME/.Trash/test_trsh5______0 ] && [ -e $HOME/.Trash/test_trsh5______1 ] && [ ! -e $HOME/.Trash/test_trsh5______2 ]
then
	echo "TEST 8A PASSED: 2 other files still exist and the 3'd file does not in the trash" >&2
	PASSED_COUNT=$(( $PASSED_COUNT+1 ))
else
	echo "TEST 8A FAILED: either 2 other files do not exist or the 3'd also exists or both" >&2
fi
##################################################################################
TOTAL_COUNT=$(( $TOTAL_COUNT+1 ))
if [ -e $HOME/test_trsh5 ] 
then
	echo "TEST 8B PASSED: File recovered as itself" >&2
	PASSED_COUNT=$(( $PASSED_COUNT+1 ))
else
	echo "TEST 8B FAILED: File not recovered as itself" >&2
fi
##################################################################################

# TEST 9: File name with space
echo "TEST 9: Testing capability to handle file name with spaces."
touch "test_trsh 9"
trsh.pl "test_trsh 9"
TOTAL_COUNT=$(( $TOTAL_COUNT+1 ))
if [ -e "$HOME/.Trash/test_trsh 9______0" ]
then
	echo "TEST 9 PASSED: File \"test_trsh 9\" exists in trash" >&2
	PASSED_COUNT=$(( $PASSED_COUNT+1 ))
else
	echo "TEST 9 FAILED: File \"test_trsh 9\" does not exist in trash" >&2
fi
##################################################################################

# TEST 10: Removal of dirs:
echo "Test 10: Testing removal of dirs"
mkdir test_trsh10a
trsh.pl test_trsh10a
TOTAL_COUNT=$(( $TOTAL_COUNT+1 ))
if [ -d "$HOME/test_trsh10a" ]
then
	echo "TEST 10A PASSED: Dir test_trsh10a not removed" >&2
	PASSED_COUNT=$(( $PASSED_COUNT+1 ))
else
	echo "TEST 10A FAILED: Dir test_trsh10a removed" >&2
fi
##################################################################################
mkdir test_trsh10b
trsh.pl -r test_trsh10b
TOTAL_COUNT=$(( $TOTAL_COUNT+1 ))
if [ -d "$HOME/.Trash/test_trsh10b______0" ]
then
	echo "TEST 10B PASSED: Dir test_trsh10b removed" >&2
	PASSED_COUNT=$(( $PASSED_COUNT+1 ))
else
	echo "TEST 10B FAILED: Dir test_trsh10b not removed" >&2
fi
##################################################################################

# TEST 11: Interactive mode. 
touch test_trsh11a1
touch test_trsh11a2
touch test_trsh11a3
echo "y" >> yyy
echo "y" >> yyy
echo "y" >> yyy
echo "n" >> nnn
echo "n" >> nnn
echo "n" >> nnn
trsh.pl -i test_trsh11a1 test_trsh11a2 test_trsh11a3 < nnn
echo ""
TOTAL_COUNT=$(( $TOTAL_COUNT+1 ))
if [ -e $HOME/test_trsh11a1 ] && [ -e $HOME/test_trsh11a2 ] && [ -e $HOME/test_trsh11a3 ]
then
	echo "TEST 11A PASSED: All three files not deleted on a no" >&2
	PASSED_COUNT=$(( $PASSED_COUNT+1 ))
else
	echo "TEST 11A FAILED: All or some of the files are deleted on a no" >&2
fi
##################################################################################
trsh.pl -i test_trsh11a1 test_trsh11a2 test_trsh11a3 < yyy
echo ""
TOTAL_COUNT=$(( $TOTAL_COUNT+1 ))
if [ -e $HOME/test_trsh11a1 ] && [ -e $HOME/test_trsh11a2 ] && [ -e $HOME/test_trsh11a3 ]
then
	echo "TEST 11B FAILED: All three files not deleted on a yes" >&2
else
	echo "TEST 11B PASSED: All three files are deleted on a yes" >&2
	PASSED_COUNT=$(( $PASSED_COUNT+1 ))
fi
##################################################################################

# Cleanup
/bin/rm -rf .Trash test_trsh3 test_trsh41 test_trsh42 test_trsh43 test_trsh5 nn test_trsh10a test_trsh10b yyy nnn 
/bin/rm -f test_trsh\ 9
echo "END OF REQUIRED TESTS" >&2
echo "" >&2
ALL_PASSED=0
echo "$PASSED_COUNT OF $TOTAL_COUNT TESTS PASSED." >&2
if [ $PASSED_COUNT -eq $TOTAL_COUNT ] 
then
	echo "ALL TESTS PASSED. BASIC FEATURES WORKING" >&2
	ALL_PASSED=1
fi
echo "" >&2
PASSED_COUNT=0
TOTAL_COUNT=0

##################################################################################
echo "Running Extended Tests" >&2
echo "y" >> yy
echo "y" >> yy

touch test_trsh1 test_trsh2
trsh.pl test_trsh1 test_trsh2
trsh.pl -u "test_trsh*"

TOTAL_COUNT=$(( $TOTAL_COUNT+1 ))
if [ -e $HOME/test_trsh1 ] && [ -e $HOME/test_trsh2 ]
then
	echo "TEST 12 PASSED: Recover regex" >&2
	PASSED_COUNT=$(( $PASSED_COUNT+1 ))
else
	echo "TEST 12 FAILED: Recover regex" >&2
fi
##################################################################################
trsh.pl test_trsh1 test_trsh2
trsh.pl -e "test_trsh*" < ./yy
echo ""

TOTAL_COUNT=$(( $TOTAL_COUNT+1 ))
if [ -e $HOME/.Trash/test_trsh1______0 ] || [ -e $HOME/.Trash/test_trsh2______0 ]
then
	echo "TEST 13 FAILED: Erase regex" >&2
else
	echo "TEST 13 PASSED: Erase regex" >&2
	PASSED_COUNT=$(( $PASSED_COUNT+1 ))
fi
##################################################################################
touch test_trsh1 test_trsh2
trsh.pl test_trsh1 test_trsh2
trsh.pl -e "test_trsh1" < ./yy
echo ""

TOTAL_COUNT=$(( $TOTAL_COUNT+1 ))
if [ -e $HOME/.Trash/test_trsh1______0 ] || [ ! -e $HOME/.Trash/test_trsh2______0 ]
then
	echo "TEST 14 FAILED: Erase specific file" >&2
else
	echo "TEST 14 PASSED: Erase specific file" >&2
	PASSED_COUNT=$(( $PASSED_COUNT+1 ))
fi


echo "END OF RECOMMENDED TESTS" >&2
echo "" >&2
echo "$PASSED_COUNT OF $TOTAL_COUNT TESTS PASSED." >&2
if [ $PASSED_COUNT -eq $TOTAL_COUNT ] 
then
	echo "ALL RECOMMENDED TESTS PASSED. EXTENDED FEATURES WORKING" >&2
else
	ALL_PASSED=0
fi

echo "" >&2

/bin/rm yy

if [ -d $HOME/.Trash_backup ]
then
	rm -rf $HOME/.Trash
	mv $HOME/.Trash_backup $HOME/.Trash
fi
if [ $ALL_PASSED -eq 1 ]
then
	exit 0
else
	exit 127
fi
