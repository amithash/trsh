#!/bin/sh

alias rm="/home/prasadae/.trsh.pl"
alias undo="/home/prasadae/.trsh.pl -u"

echo "Starting as a virgin"
cd /home/prasadae
/bin/rm -rf .Trash

echo ""
echo "Basic Tests"
echo ""
echo "Now it should complain about .Trash and .history and create them"
rm

# TEST 1
echo "TEST 1: Tests .Trash creation"
if [ -d /home/prasadae/.Trash ]
then
	echo "TEST 1 PASSED: Trash exists"
else
	echo "TEST 1 FAILED: Trash does not exist"
fi

# TEST 2
echo "TEST 2: Tests .history creation"
if [ -e /home/prasadae/.Trash/.history ]
then
	echo "TEST 2 PASSED: history exists"
else
	echo "TEST 2 FAILED: history does not exist"
fi

echo ""
echo "Testing basic features of removing and recovering"
echo ""

# TEST 3 remove
echo "TEST 3: Tests basic file delete"
cd /home/prasadae
touch test3
rm test3
if [ -e /home/prasadae/.Trash/test3 ]
then
	echo "TEST 3A PASSED: file test3 exists in trash"
else
	echo "TEST 3A FAILED: file test3 does not exist in trash"
fi
if [ -e /home/prasadae/test3 ]
then
	echo "TEST 3B FAILED: file test3 not deleted"
else
	echo "TEST 3B PASSED: file test3 deleted"
fi
# TEST 4 recover
echo "TEST 4: Tests basic file recovery"
cd /home/prasadae
rm -r test3
if [ -e /home/prasadae/.Trash/test3 ]
then
	echo "TEST 4A FAILED: file test3 exists in trash"
else
	echo "TEST 4A PASSED: file test3 does not exist in trash"
fi
if [ -e /home/prasadae/test3 ]
then
	echo "TEST 4B PASSED: file test3 recovered"
else
	echo "TEST 4B FAILED: file test3 not recovered"
fi
/bin/rm test3

# TEST 5 delete multiple files
echo "TEST 5 tests delete multiple files"
cd /home/prasadae
touch test41 
touch test42
touch test43
rm test41 test42 test43
if [ -e /home/prasadae/.Trash/test41 ] && [ -e /home/prasadae/.Trash/test42 ] && [ -e /home/prasadae/.Trash/test43 ]
then
	echo "TEST 5A PASSED: Files test41 test42 and test43 exist in Trash"
else
	echo "TEST 5A FAILED: Files test41 test42 and test43 do not exist in Trash"
fi
if [ -e /home/prasadae/test41 ] && [ -e /home/prasadae/test42 ] && [ -e /home/prasadae/test43 ]
then
	echo "TEST 5B FAILED: Files test41 test42 and test43 not deleted"
else
	echo "TEST 5B PASSED: Files test41 test42 and test43 are deleted"
fi

# TEST 6 undo
echo "TEST 6 tests undo"
undo
if [ -e /home/prasadae/test43 ]
then
	echo "TEST 6A PASSED: File test43 recovered"
else
	echo "TEST 6A FAILED: File test43 not recovered"
fi
if [ -e /home/prasadae/.Trash/test43 ]
then
	echo "TEST 6A FAILED: File test43 exists in trash"
else
	echo "TEST 6A PASSED: File test43 does not exist in trash"
fi

# TEST 7 Multiple files with same name
echo "TEST 7: tests multi files same name"
touch test5
rm test5
touch test5
rm test5
touch test5
rm test5
if [ -e /home/prasadae/.Trash/test5 ] && [ -e /home/prasadae/.Trash/test5@1 ] && [ -e /home/prasadae/.Trash/test5@2 ]
then
	echo "TEST 7 PASSED: All three files deleted and exist in trash"
else
	echo "TEST 7 FAILED: All three files not deleted and do not exist in the trash"
fi

# TEST 8 recover using undo
echo "TEST 8: tests recover with multiple files."
undo
if [ -e /home/prasadae/.Trash/test5 ] && [ -e /home/prasadae/.Trash/test5@1 ] && [ ! -e /home/prasadae/.Trash/test5@2 ]
then
	echo "TEST 8A PASSED: 2 other files still exist and the 3'd file does not in the trash"
else
	echo "TEST 8A FAILED: either 2 other files do not exist or the 3'd also exists or both"
fi
if [ -e /home/prasadae/test5 ] 
then
	echo "TEST 8B PASSED: File recovered as itself"
else
	echo "TEST 8B FAILED: File not recovered as itself"
fi

# TEST 9: File name with space
echo "TEST 9: Testing capability to handler file name with spaces."
touch test\ 9
rm test\ 9
if [ -e "/home/prasadae/.Trash/test 9" ]
then
	echo "TEST 9 PASSED: File \"test 9\" exists in trash"
else
	echo "TEST 9 FAILED: File \"test 9\" does not exist in trash"
fi
	
# Do not leave stray test files.
/bin/rm -rf .Trash test3 test41 test42 test43 test5
/bin/rm -f test\ 9

echo "END OF TESTS"

