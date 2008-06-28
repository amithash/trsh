#!/bin/tcsh
#*************************************************************************
# Copyright 2008 Amithash Prasad                                         *
#									 *
# this endifle is part of trsh.						 *
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
if ( -d $HOME/.Trash ) then
	mv $HOME/.Trash $HOME/.Trash_backup
endif
setenv PATH `pwd`:$PATH

which trsh.pl

set PASSED_COUNT=0
@ TOTAL_COUNT=0

cd $HOME
trsh.pl
##################################################################################

# TEST 1
@ TOTAL_COUNT = $TOTAL_COUNT + 1
echo "TEST 1: Tests .Trash creation"
if ( -d $HOME/.Trash ) then
	echo "TEST 1 PASSED: Trash exists" 
	@ PASSED_COUNT = $PASSED_COUNT + 1
else
	echo "TEST 1 FAILED: Trash does not exist" 
endif
##################################################################################

# TEST 2
@ TOTAL_COUNT = $TOTAL_COUNT + 1
echo "TEST 2: Tests .history creation"
if ( -e $HOME/.Trash/.history ) then
	echo "TEST 2 PASSED: history exists" 
	@ PASSED_COUNT = $PASSED_COUNT + 1
else
	echo "TEST 2 FAILED: history does not exist" 
endif
##################################################################################

# TEST 3 remove
echo "TEST 3: Tests basic endifle delete"
cd $HOME
touch test_trsh3
trsh.pl test_trsh3
@ TOTAL_COUNT = $TOTAL_COUNT + 1
if ( -e $HOME/.Trash/test_trsh3______0 ) then
	echo "TEST 3A PASSED: endifle test_trsh3 exists in trash" 
	@ PASSED_COUNT = $PASSED_COUNT + 1
else
	echo "TEST 3A FAILED: endifle test_trsh3 does not exist in trash" 
endif
##################################################################################
@ TOTAL_COUNT = $TOTAL_COUNT + 1
if ( -e $HOME/test_trsh3 ) then
	echo "TEST 3B FAILED: endifle test_trsh3 not deleted" 
else
	echo "TEST 3B PASSED: endifle test_trsh3 deleted" 
	@ PASSED_COUNT = $PASSED_COUNT + 1
endif
##################################################################################
# TEST 4 recover
echo "TEST 4: Tests basic endifle recovery"
cd $HOME
trsh.pl -u test_trsh3
@ TOTAL_COUNT = $TOTAL_COUNT + 1
if ( -e $HOME/.Trash/test_trsh3 ) then
	echo "TEST 4A FAILED: endifle test_trsh3 exists in trash" 
else
	echo "TEST 4A PASSED: endifle test_trsh3 does not exist in trash" 
	@ PASSED_COUNT = $PASSED_COUNT + 1
endif
##################################################################################
@ TOTAL_COUNT = $TOTAL_COUNT + 1
if ( -e $HOME/test_trsh3 ) then
	echo "TEST 4B PASSED: endifle test_trsh3 recovered" 
	@ PASSED_COUNT = $PASSED_COUNT + 1
else
	echo "TEST 4B FAILED: endifle test_trsh3 not recovered" 
endif
##################################################################################
/bin/rm test_trsh3

# TEST 5 delete multiple endifles
echo "TEST 5 test_trshs delete multiple endifles"
cd $HOME
touch test_trsh41 
touch test_trsh42
touch test_trsh43
trsh.pl test_trsh41 test_trsh42 test_trsh43
@ TOTAL_COUNT = $TOTAL_COUNT + 1
if ( -e $HOME/.Trash/test_trsh41______0 && -e $HOME/.Trash/test_trsh42______0 && -e $HOME/.Trash/test_trsh43______0 ) then
	echo "TEST 5A PASSED: Files test_trsh41 test_trsh42 and test_trsh43 exist in Trash" 
	@ PASSED_COUNT = $PASSED_COUNT + 1
else
	echo "TEST 5A FAILED: Files test_trsh41 test_trsh42 and test_trsh43 do not exist in Trash" 
endif
##################################################################################
@ TOTAL_COUNT = $TOTAL_COUNT + 1
if ( -e $HOME/test_trsh41 && -e $HOME/test_trsh42 && -e $HOME/test_trsh43 ) then
	echo "TEST 5B FAILED: Files test_trsh41 test_trsh42 and test_trsh43 not deleted" 
else
	echo "TEST 5B PASSED: Files test_trsh41 test_trsh42 and test_trsh43 are deleted" 
	@ PASSED_COUNT = $PASSED_COUNT + 1
endif

##################################################################################
# TEST 6 trsh.pl -u
echo "TEST 6 test_trshs trsh.pl -u"
trsh.pl -u
@ TOTAL_COUNT = $TOTAL_COUNT + 1
if ( -e $HOME/test_trsh43 ) then
	echo "TEST 6A PASSED: File test_trsh43 recovered" 
	@ PASSED_COUNT = $PASSED_COUNT + 1
else
	echo "TEST 6A FAILED: File test_trsh43 not recovered" 
endif
##################################################################################
@ TOTAL_COUNT = $TOTAL_COUNT + 1
if ( -e $HOME/.Trash/test_trsh43 ) then
	echo "TEST 6B FAILED: File test_trsh43 exists in trash" 
else
	echo "TEST 6B PASSED: File test_trsh43 does not exist in trash" 
	@ PASSED_COUNT = $PASSED_COUNT + 1
endif
##################################################################################

# TEST 7 Multiple endifles with same name
echo "TEST 7: test_trshs multi endifles same name"
touch test_trsh5
trsh.pl test_trsh5
touch test_trsh5
trsh.pl test_trsh5
touch test_trsh5
trsh.pl test_trsh5
@ TOTAL_COUNT = $TOTAL_COUNT + 1
if ( -e $HOME/.Trash/test_trsh5______0 && -e $HOME/.Trash/test_trsh5______1 && -e $HOME/.Trash/test_trsh5______2 ) then
	echo "TEST 7 PASSED: All three endifles deleted and exist in trash" 
	@ PASSED_COUNT = $PASSED_COUNT + 1
else
	echo "TEST 7 FAILED: All three endifles not deleted and do not exist in the trash" 
endif
##################################################################################

# TEST 8 recover using trsh.pl -u
echo "TEST 8: test_trshs recover with multiple endifles."
trsh.pl -u
@ TOTAL_COUNT = $TOTAL_COUNT + 1
if ( -e $HOME/.Trash/test_trsh5______0 && -e $HOME/.Trash/test_trsh5______1 && ! -e $HOME/.Trash/test_trsh5______2 ) then
	echo "TEST 8A PASSED: 2 other endifles still exist and the 3'd endifle does not in the trash" 
	@ PASSED_COUNT = $PASSED_COUNT + 1
else
	echo "TEST 8A FAILED: either 2 other endifles do not exist or the 3'd also exists or both" 
endif
##################################################################################
@ TOTAL_COUNT = $TOTAL_COUNT + 1
if ( -e $HOME/test_trsh5 )  then
	echo "TEST 8B PASSED: File recovered as itself" 
	@ PASSED_COUNT = $PASSED_COUNT + 1
else
	echo "TEST 8B FAILED: File not recovered as itself" 
endif
##################################################################################

# TEST 9: File name with space
echo "TEST 9: Testing capability to handle file name with spaces."
touch "test_trsh 9"
trsh.pl "test_trsh 9"
@ TOTAL_COUNT = $TOTAL_COUNT + 1
if ( -e "$HOME/.Trash/test_trsh 9______0" ) then
	echo 'TEST 9 PASSED: File "test_trsh 9" exists in trash'
	@ PASSED_COUNT = $PASSED_COUNT + 1
else
	echo 'TEST 9 FAILED: File "test_trsh 9" does not exist in trash' 
endif
##################################################################################

# TEST 10: Removal of dirs:
echo "Test 10: Testing removal of dirs"
mkdir test_trsh10a
trsh.pl test_trsh10a
echo ""
@ TOTAL_COUNT = $TOTAL_COUNT + 1
if ( -d "$HOME/test_trsh10a" ) then
	echo "TEST 10A PASSED: Dir test_trsh10a not removed" 
	@ PASSED_COUNT = $PASSED_COUNT + 1
else
	echo "TEST 10A FAILED: Dir test_trsh10a removed" 
endif
##################################################################################
mkdir test_trsh10b
trsh.pl -r test_trsh10b
echo ""
@ TOTAL_COUNT = $TOTAL_COUNT + 1
if ( -d "$HOME/.Trash/test_trsh10b______0" ) then
	echo "TEST 10B PASSED: Dir test_trsh10b removed" 
	@ PASSED_COUNT = $PASSED_COUNT + 1
else
	echo "TEST 10B FAILED: Dir test_trsh10b not removed" 
endif
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
@ TOTAL_COUNT = $TOTAL_COUNT + 1
if ( -e $HOME/test_trsh11a1 && -e $HOME/test_trsh11a2 && -e $HOME/test_trsh11a3 ) then
	echo "TEST 11A PASSED: All three endifles not deleted on a no" 
	@ PASSED_COUNT = $PASSED_COUNT + 1
else
	echo "TEST 11A FAILED: All or some of the endifles are deleted on a no" 
endif
##################################################################################
trsh.pl -i test_trsh11a1 test_trsh11a2 test_trsh11a3 < yyy
echo ""
@ TOTAL_COUNT = $TOTAL_COUNT + 1
if ( -e $HOME/test_trsh11a1 && -e $HOME/test_trsh11a2 && -e $HOME/test_trsh11a3 ) then
	echo "TEST 11B FAILED: All three endifles not deleted on a yes" 
else
	echo "TEST 11B PASSED: All three endifles are deleted on a yes" 
	@ PASSED_COUNT = $PASSED_COUNT + 1
endif
##################################################################################

# Cleanup
/bin/rm -rf .Trash test_trsh3 test_trsh41 test_trsh42 test_trsh43 test_trsh5 nn test_trsh10a test_trsh10b yyy nnn 
/bin/rm -f test_trsh\ 9
echo "END OF REQUIRED TESTS" 
echo "" 
set ALL_PASSED = 0
echo "$PASSED_COUNT OF $TOTAL_COUNT TESTS PASSED." 
if ( $PASSED_COUNT == $TOTAL_COUNT )  then
	echo "ALL TESTS PASSED. BASIC FEATURES WORKING" 
	@ ALL_PASSED = 1
endif
echo "" 
@ PASSED_COUNT = 0
@ TOTAL_COUNT = 0

##################################################################################
echo "Running Extended Tests" 
echo "y" >> yy
echo "y" >> yy

touch test_trsh1 test_trsh2
trsh.pl test_trsh1 test_trsh2
trsh.pl -u "test_trsh*"

@ TOTAL_COUNT = $TOTAL_COUNT + 1
if ( -e $HOME/test_trsh1 && -e $HOME/test_trsh2 ) then
	echo "TEST 12 PASSED: Recover regex" 
	@ PASSED_COUNT = $PASSED_COUNT + 1
else
	echo "TEST 12 FAILED: Recover regex" 
endif
##################################################################################
trsh.pl test_trsh1 test_trsh2
trsh.pl -e "test_trsh*" < ./yy
echo "" 

@ TOTAL_COUNT = $TOTAL_COUNT + 1
if ( -e $HOME/.Trash/test_trsh1______0 || -e $HOME/.Trash/test_trsh2______0 ) then
	echo "TEST 13 FAILED: Erase regex" 
else
	echo "TEST 13 PASSED: Erase regex" 
	@ PASSED_COUNT = $PASSED_COUNT + 1
endif
##################################################################################
touch test_trsh1 test_trsh2
trsh.pl test_trsh1 test_trsh2
trsh.pl -e "test_trsh1" < ./yy
echo "" 

@ TOTAL_COUNT = $TOTAL_COUNT + 1
if ( -e $HOME/.Trash/test_trsh1______0 || ! -e $HOME/.Trash/test_trsh2______0 ) then
	echo "TEST 14 FAILED: Erase speciendifc endifle" 
else
	echo "TEST 14 PASSED: Erase speciendifc endifle" 
	@ PASSED_COUNT = $PASSED_COUNT + 1
endif


echo "END OF RECOMMENDED TESTS" 
echo "" 
echo "$PASSED_COUNT OF $TOTAL_COUNT TESTS PASSED." 
if ( $PASSED_COUNT == $TOTAL_COUNT ) then
	echo "ALL RECOMMENDED TESTS PASSED. EXTENDED FEATURES WORKING" 
else
	@ ALL_PASSED = 0
endif
echo "" 

/bin/rm yy

if ( -d $HOME/.Trash_backup ) then
	rm -rf $HOME/.Trash
	mv $HOME/.Trash_backup $HOME/.Trash
endif
if ( $ALL_PASSED == 1) then
	exit 0
else
	exit 127
endif

