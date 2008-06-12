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

echo "WARNING: This test was designed for bash."
echo "         If you are not running BASH, too bad"

echo "Backing up existing trash."
if [ -d $HOME/.Trash ]
then
	mv $HOME/.Trash $HOME/.Trash_backup
fi
export PATH=`pwd`:$PATH

which trsh.pl

PASSED_COUNT=0
TOTAL_COUNT=0

echo "Starting as a virgin"
cd $HOME
/bin/rm -rf .Trash
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
touch test3
trsh.pl test3
TOTAL_COUNT=$(( $TOTAL_COUNT+1 ))
if [ -e $HOME/.Trash/test3______0 ]
then
	echo "TEST 3A PASSED: file test3 exists in trash" >&2
	PASSED_COUNT=$(( $PASSED_COUNT+1 ))
else
	echo "TEST 3A FAILED: file test3 does not exist in trash" >&2
fi
##################################################################################
TOTAL_COUNT=$(( $TOTAL_COUNT+1 ))
if [ -e $HOME/test3 ]
then
	echo "TEST 3B FAILED: file test3 not deleted" >&2
else
	echo "TEST 3B PASSED: file test3 deleted" >&2
	PASSED_COUNT=$(( $PASSED_COUNT+1 ))
fi
##################################################################################
# TEST 4 recover
echo "TEST 4: Tests basic file recovery"
cd $HOME
trsh.pl -u test3
TOTAL_COUNT=$(( $TOTAL_COUNT+1 ))
if [ -e $HOME/.Trash/test3 ]
then
	echo "TEST 4A FAILED: file test3 exists in trash" >&2
else
	echo "TEST 4A PASSED: file test3 does not exist in trash" >&2
	PASSED_COUNT=$(( $PASSED_COUNT+1 ))
fi
##################################################################################
TOTAL_COUNT=$(( $TOTAL_COUNT+1 ))
if [ -e $HOME/test3 ]
then
	echo "TEST 4B PASSED: file test3 recovered" >&2
	PASSED_COUNT=$(( $PASSED_COUNT+1 ))
else
	echo "TEST 4B FAILED: file test3 not recovered" >&2
fi
##################################################################################
/bin/rm test3

# TEST 5 delete multiple files
echo "TEST 5 tests delete multiple files"
cd $HOME
touch test41 
touch test42
touch test43
trsh.pl test41 test42 test43
TOTAL_COUNT=$(( $TOTAL_COUNT+1 ))
if [ -e $HOME/.Trash/test41______0 ] && [ -e $HOME/.Trash/test42______0 ] && [ -e $HOME/.Trash/test43______0 ]
then
	echo "TEST 5A PASSED: Files test41 test42 and test43 exist in Trash" >&2
	PASSED_COUNT=$(( $PASSED_COUNT+1 ))
else
	echo "TEST 5A FAILED: Files test41 test42 and test43 do not exist in Trash" >&2
fi
##################################################################################
TOTAL_COUNT=$(( $TOTAL_COUNT+1 ))
if [ -e $HOME/test41 ] && [ -e $HOME/test42 ] && [ -e $HOME/test43 ]
then
	echo "TEST 5B FAILED: Files test41 test42 and test43 not deleted" >&2
else
	echo "TEST 5B PASSED: Files test41 test42 and test43 are deleted" >&2
	PASSED_COUNT=$(( $PASSED_COUNT+1 ))
fi

##################################################################################
# TEST 6 trsh.pl -u
echo "TEST 6 tests trsh.pl -u"
trsh.pl -u
TOTAL_COUNT=$(( $TOTAL_COUNT+1 ))
if [ -e $HOME/test43 ]
then
	echo "TEST 6A PASSED: File test43 recovered" >&2
	PASSED_COUNT=$(( $PASSED_COUNT+1 ))
else
	echo "TEST 6A FAILED: File test43 not recovered" >&2
fi
##################################################################################
TOTAL_COUNT=$(( $TOTAL_COUNT+1 ))
if [ -e $HOME/.Trash/test43 ]
then
	echo "TEST 6B FAILED: File test43 exists in trash" >&2
else
	echo "TEST 6B PASSED: File test43 does not exist in trash" >&2
	PASSED_COUNT=$(( $PASSED_COUNT+1 ))
fi
##################################################################################

# TEST 7 Multiple files with same name
echo "TEST 7: tests multi files same name"
touch test5
trsh.pl test5
touch test5
trsh.pl test5
touch test5
trsh.pl test5
TOTAL_COUNT=$(( $TOTAL_COUNT+1 ))
if [ -e $HOME/.Trash/test5______0 ] && [ -e $HOME/.Trash/test5______1 ] && [ -e $HOME/.Trash/test5______2 ]
then
	echo "TEST 7 PASSED: All three files deleted and exist in trash" >&2
	PASSED_COUNT=$(( $PASSED_COUNT+1 ))
else
	echo "TEST 7 FAILED: All three files not deleted and do not exist in the trash" >&2
fi
##################################################################################

# TEST 8 recover using trsh.pl -u
echo "TEST 8: tests recover with multiple files."
trsh.pl -u
TOTAL_COUNT=$(( $TOTAL_COUNT+1 ))
if [ -e $HOME/.Trash/test5______0 ] && [ -e $HOME/.Trash/test5______1 ] && [ ! -e $HOME/.Trash/test5______2 ]
then
	echo "TEST 8A PASSED: 2 other files still exist and the 3'd file does not in the trash" >&2
	PASSED_COUNT=$(( $PASSED_COUNT+1 ))
else
	echo "TEST 8A FAILED: either 2 other files do not exist or the 3'd also exists or both" >&2
fi
##################################################################################
TOTAL_COUNT=$(( $TOTAL_COUNT+1 ))
if [ -e $HOME/test5 ] 
then
	echo "TEST 8B PASSED: File recovered as itself" >&2
	PASSED_COUNT=$(( $PASSED_COUNT+1 ))
else
	echo "TEST 8B FAILED: File not recovered as itself" >&2
fi
##################################################################################

# TEST 9: File name with space
echo "TEST 9: Testing capability to handler file name with spaces."
touch "test 9"
trsh.pl "test 9"
TOTAL_COUNT=$(( $TOTAL_COUNT+1 ))
if [ -e "$HOME/.Trash/test 9______0" ]
then
	echo "TEST 9 PASSED: File \"test 9\" exists in trash" >&2
	PASSED_COUNT=$(( $PASSED_COUNT+1 ))
else
	echo "TEST 9 FAILED: File \"test 9\" does not exist in trash" >&2
fi
##################################################################################

# TEST 10: Removal of dirs:
echo "Test 10: Testing removal of dirs"
mkdir test10a
trsh.pl test10a
echo ""
TOTAL_COUNT=$(( $TOTAL_COUNT+1 ))
if [ -d "$HOME/test10a" ]
then
	echo "TEST 10A PASSED: Dir test10a not removed" >&2
	PASSED_COUNT=$(( $PASSED_COUNT+1 ))
else
	echo "TEST 10A FAILED: Dir test10a removed" >&2
fi
##################################################################################
mkdir test10b
trsh.pl -r test10b
echo ""
TOTAL_COUNT=$(( $TOTAL_COUNT+1 ))
if [ -d "$HOME/.Trash/test10b______0" ]
then
	echo "TEST 10A PASSED: Dir test10b removed" >&2
	PASSED_COUNT=$(( $PASSED_COUNT+1 ))
else
	echo "TEST 10B FAILED: Dir test10b not removed" >&2
fi
##################################################################################

# TEST 11: Interactive mode. 
touch test11a1
touch test11a2
touch test11a3
echo "y" >> yyy
echo "y" >> yyy
echo "y" >> yyy
echo "n" >> nnn
echo "n" >> nnn
echo "n" >> nnn
trsh.pl -i test11a1 test11a2 test11a3 < nnn
TOTAL_COUNT=$(( $TOTAL_COUNT+1 ))
if [ -e $HOME/test11a1 ] && [ -e $HOME/test11a2 ] && [ -e $HOME/test11a3 ]
then
	echo "TEST 11A PASSED: All three files not deleted on a no" >&2
	PASSED_COUNT=$(( $PASSED_COUNT+1 ))
else
	echo "TEST 11A FAILED: All or some of the files are deleted on a no" >&2
fi
##################################################################################
trsh.pl -i test11a1 test11a2 test11a3 < yyy
TOTAL_COUNT=$(( $TOTAL_COUNT+1 ))
if [ -e $HOME/test11a1 ] && [ -e $HOME/test11a2 ] && [ -e $HOME/test11a3 ]
then
	echo "TEST 11B FAILED: All three files not deleted on a yes" >&2
else
	echo "TEST 11B PASSED: All three files are deleted on a yes" >&2
	PASSED_COUNT=$(( $PASSED_COUNT+1 ))
fi
##################################################################################

# Cleanup
/bin/rm -rf .Trash test3 test41 test42 test43 test5 nn test10a test10b yyy nnn 
/bin/rm -f test\ 9
echo "END OF REQUIRED TESTS" >&2
echo "" >&2

echo "$PASSED_COUNT OF $TOTAL_COUNT TESTS PASSED." >&2
if [ $PASSED_COUNT -eq $TOTAL_COUNT ] 
then
	echo "ALL TESTS PASSED. BASIC FEATURES WORKING" >&2
fi
echo "" >&2
PASSED_COUNT=0
TOTAL_COUNT=0

##################################################################################
echo "Running Extended Tests" >&2
echo "y" >> yy
echo "y" >> yy

touch test1 test2
trsh.pl test1 test2
trsh.pl -u "test*"

TOTAL_COUNT=$(( $TOTAL_COUNT+1 ))
if [ -e $HOME/test1 ] && [ -e $HOME/test2 ]
then
	echo "TEST 12 PASSED: Recover regex" >&2
	PASSED_COUNT=$(( $PASSED_COUNT+1 ))
else
	echo "TEST 12 FAILED: Recover regex" >&2
fi
##################################################################################
trsh.pl test1 test2
trsh.pl -e "test*" < ./yy

TOTAL_COUNT=$(( $TOTAL_COUNT+1 ))
if [ -e $HOME/.Trash/test1______0 ] || [ -e $HOME/.Trash/test2______0 ]
then
	echo "TEST 13 FAILED: Erase regex" >&2
else
	echo "TEST 13 PASSED: Erase regex" >&2
	PASSED_COUNT=$(( $PASSED_COUNT+1 ))
fi
##################################################################################
touch test1 test2
trsh.pl test1 test2
trsh.pl -e "test1" < ./yy

TOTAL_COUNT=$(( $TOTAL_COUNT+1 ))
if [ -e $HOME/.Trash/test1______0 ] || [ ! -e $HOME/.Trash/test2______0 ]
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
fi
echo "" >&2

if [ -d $HOME/.Trash_backup ]
then
	mv $HOME/.Trash_backup $HOME/.Trash
fi

