#!/bin/sh

echo "WARNING: This test was designed for bash."
echo "         If you are not running BASH, too bad"

echo "Backing up existing trash."
mv $HOME/.Trash $HOME/.Trash_backup

PASSED_COUNT=0
TOTAL_COUNT=0

alias rm="$HOME/.trsh.pl"
alias undo="$HOME/.trsh.pl -u"

echo "Starting as a virgin"
cd $HOME
/bin/rm -rf .Trash
rm
##################################################################################

# TEST 1
TOTAL_COUNT=$(( $TOTAL_COUNT+1 ))
echo "TEST 1: Tests .Trash creation" >&2
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
echo "TEST 2: Tests .history creation" >&2
if [ -e $HOME/.Trash/.history ]
then
	echo "TEST 2 PASSED: history exists" >&2
	PASSED_COUNT=$(( $PASSED_COUNT+1 ))
else
	echo "TEST 2 FAILED: history does not exist" >&2
fi
##################################################################################

# TEST 3 remove
echo "TEST 3: Tests basic file delete" >&2
cd $HOME
touch test3
rm test3
TOTAL_COUNT=$(( $TOTAL_COUNT+1 ))
if [ -e $HOME/.Trash/test3 ]
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
echo "TEST 4: Tests basic file recovery" >&2
cd $HOME
rm -r test3
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
echo "TEST 5 tests delete multiple files" >&2
cd $HOME
touch test41 
touch test42
touch test43
rm test41 test42 test43
TOTAL_COUNT=$(( $TOTAL_COUNT+1 ))
if [ -e $HOME/.Trash/test41 ] && [ -e $HOME/.Trash/test42 ] && [ -e $HOME/.Trash/test43 ]
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
# TEST 6 undo
echo "TEST 6 tests undo" >&2
undo
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
	echo "TEST 6A FAILED: File test43 exists in trash" >&2
else
	echo "TEST 6A PASSED: File test43 does not exist in trash" >&2
	PASSED_COUNT=$(( $PASSED_COUNT+1 ))
fi
##################################################################################

# TEST 7 Multiple files with same name
echo "TEST 7: tests multi files same name" >&2
touch test5
rm test5
touch test5
rm test5
touch test5
rm test5
TOTAL_COUNT=$(( $TOTAL_COUNT+1 ))
if [ -e $HOME/.Trash/test5 ] && [ -e $HOME/.Trash/test5@1 ] && [ -e $HOME/.Trash/test5@2 ]
then
	echo "TEST 7 PASSED: All three files deleted and exist in trash" >&2
	PASSED_COUNT=$(( $PASSED_COUNT+1 ))
else
	echo "TEST 7 FAILED: All three files not deleted and do not exist in the trash" >&2
fi
##################################################################################

# TEST 8 recover using undo
echo "TEST 8: tests recover with multiple files." >&2
undo
TOTAL_COUNT=$(( $TOTAL_COUNT+1 ))
if [ -e $HOME/.Trash/test5 ] && [ -e $HOME/.Trash/test5@1 ] && [ ! -e $HOME/.Trash/test5@2 ]
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
echo "TEST 9: Testing capability to handler file name with spaces." >&2
touch test\ 9
rm test\ 9
TOTAL_COUNT=$(( $TOTAL_COUNT+1 ))
if [ -e "$HOME/.Trash/test 9" ]
then
	echo "TEST 9 PASSED: File \"test 9\" exists in trash" >&2
	PASSED_COUNT=$(( $PASSED_COUNT+1 ))
else
	echo "TEST 9 FAILED: File \"test 9\" does not exist in trash" >&2
fi
##################################################################################

# TEST 10: Removal of dirs:
echo "Test 10: Testing removal of dirs" >&2
mkdir test10a
echo "y" >> yy
echo "n" >> nn
rm test10a < yy
echo ""
TOTAL_COUNT=$(( $TOTAL_COUNT+1 ))
if [ -d "$HOME/.Trash/test10a" ]
then
	echo "TEST 10A PASSED: Dir test10a exists in trash" >&2
	PASSED_COUNT=$(( $PASSED_COUNT+1 ))
else
	echo "TEST 10B FAILED: Dir test10a does not exist in trash" >&2
fi
##################################################################################
mkdir test10b
rm test10b < nn
echo ""
TOTAL_COUNT=$(( $TOTAL_COUNT+1 ))
if [ -d "$HOME/.Trash/test10b" ]
then
	echo "TEST 10A FAILED: Dir test10b removed upon no from user" >&2
else
	echo "TEST 10B PASSED: Dir test10b not removed upon no from user" >&2
	PASSED_COUNT=$(( $PASSED_COUNT+1 ))
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
rm -i test11a1 test11a2 test11a3 < nnn
TOTAL_COUNT=$(( $TOTAL_COUNT+1 ))
if [ -e $HOME/test11a1 ] && [ -e $HOME/test11a2 ] && [ -e $HOME/test11a3 ]
then
	echo "TEST 11A PASSED: All three files not deleted on a no" >&2
	PASSED_COUNT=$(( $PASSED_COUNT+1 ))
else
	echo "TEST 11A FAILED: All or some of the files are deleted on a no" >&2
fi
##################################################################################
rm -i test11a1 test11a2 test11a3 < yyy
TOTAL_COUNT=$(( $TOTAL_COUNT+1 ))
if [ -e $HOME/test11a1 ] && [ -e $HOME/test11a2 ] && [ -e $HOME/test11a3 ]
then
	echo "TEST 11B FAILED: All three files not deleted on a yes" >&2
else
	echo "TEST 11B PASSED: All three files are deleted on a yes" >&2
	PASSED_COUNT=$(( $PASSED_COUNT+1 ))
fi
##################################################################################

# Do not leave stray test files.
/bin/rm -rf .Trash test3 test41 test42 test43 test5 yy nn test10b yyy nnn 
/bin/rm -f test\ 9
mv $HOME/.Trash_backup $HOME/.Trash

echo "END OF TESTS" >&2
echo "$PASSED_COUNT of $TOTAL_COUNT tests passed." >&2

