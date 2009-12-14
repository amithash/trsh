#!/bin/bash

declare -i PASSED_COUNT=0
declare -i TOTAL_COUNT=0
declare  TRASH_HOME=""
declare TRASH_BACKUP=""
TEST_DIR=$HOME/____trsh____test____dir
TRSH="`pwd`/trsh.pl"

passed()
{
	echo "TEST ${1} PASSED: ${2} ${3} ${4} ${5} ${6} ${7} ${8} ${9} ${10} ${11} ${11} ${12} ${13} ${14} ${15} ${16}" >&2
	PASSED_COUNT=$(( $PASSED_COUNT+1 ))	
	TOTAL_COUNT=$(( $TOTAL_COUNT+1 ))
}

failed()
{
	echo "TEST ${1} FAILED: ${2} ${3} ${4} ${5} ${6} ${7} ${8} ${9} ${10} ${11} ${11} ${12} ${13} ${14} ${15} ${16}" >&2
	TOTAL_COUNT=$(( $TOTAL_COUNT+1 ))
}

print_results()
{
	echo "$PASSED_COUNT of $TOTAL_COUNT passed!"
}


init_tests()
{
	PASSED_COUNT=0
	TOTAL_COUNT=0
	TRASH_HOME=$1
	TRASH_BACKUP="${1}_BACKUP"

	if [ -d $TRASH_HOME ]
	then
		mv $TRASH_HOME $TRASH_BACKUP
	fi
	export PATH=`pwd`:$PATH
	echo "Using trsh from location: $TRSH"
	if [ -d $TEST_DIR ]
	then
		rm -rf $TEST_DIR
	fi

	mkdir $TEST_DIR
	cd $TEST_DIR
	chmod +x $TRSH
}

exit_tests()
{
	rm -rf $TRASH_HOME
	mv $TRASH_BACKUP $TRASH_HOME
	print_results
	rm -rf $TEST_DIR
	if [ $PASSED_COUNT -eq $TOTAL_COUNT ]
	then
		exit 0
	else
		exit 127
	fi
}

#########################################################################
############################# BEGIN TESTS ###############################
#########################################################################


init_tests "$HOME/.local/share/Trash"

############################### TEST 001 ################################
TEST="creation of folders"
NUM="1A"
$TRSH

if [ -d $TRASH_HOME/files ]
then
	passed $NUM $TEST
else
	failed $NUM $TEST
fi
NUM="1B"
if [ -d $TRASH_HOME/info ]
then
	passed $NUM $TEST
else
	failed $NUM $TEST
fi
############################### TEST 002 ################################
TEST="Delete regular files"
NUM="2A"
FILE="____test_2"
touch $FILE
$TRSH $FILE

if [ -e $FILE ] 
then
	failed $NUM "File still exists after deleting"
else
	passed $NUM $TEST
fi

NUM="2B"
if [ -e $TRASH_HOME/files/$FILE ]
then
	passed $NUM $TEST
else
	failed $NUM "File not found in trash"
fi
NUM="2C"
if [ -e $TRASH_HOME/info/$FILE.trashinfo ]
then
	passed $NUM $TEST
else
	failed $NUM "Info file not found in trash"
fi

############################### TEST 003 ################################
TEST="Delete multiple files with same name does not overwrite trash contents"
NUM="3A"
touch $FILE
$TRSH $FILE
if [ -e $TRASH_HOME/files/$FILE ] && [ -e "$TRASH_HOME/files/${FILE}-1" ] 
then
	passed $NUM $TEST
else
	failed $NUM "File overwrites files in Trash"
fi

############################### TEST 004 ################################
TEST="Delete directories"
NUM="4A"
FILE="____test_3"
mkdir $FILE
$TRSH $FILE > /dev/null 2> /dev/null
# -r is not provided. $FILE must not be trashed.
if [ -d $FILE ]
then
	passed $NUM $TEST
else
	failed $NUM "directories are allowed to be deleted without -r option"
fi
NUM="4B"
$TRSH -r $FILE
if [ -d $FILE ]
then
	failed $NUM "Directory not deleted even with -r option"
else
	passed $NUM $TEST
fi
NUM="4C"
if [ -d $TRASH_HOME/files/$FILE ]
then
	passed $NUM $TEST
else
	failed $NUM "File not found in trash."
fi
############################### TEST 005 ################################
TEST="Delete Files names with space."
NUM="5A"
FILE="____test space"
touch "$FILE"
$TRSH "$TEST_DIR/$FILE"
if [ -e "$FILE" ] 
then
	failed $NUM "File still exists after deleting"
else
	passed $NUM $TEST
fi

NUM="5B"
if [ -e "$TRASH_HOME/files/$FILE" ]
then
	passed $NUM $TEST
else
	failed $NUM "File not found in trash"
fi
############################### TEST 006 ################################
TEST="Delete File names with special characters"
PATTERNA='~!@#$%^&*()_+' 
PATTERNB='[]\{}|' 
PATTERNC="trsh's"
PATTERND="\\'1234567890-="
PATTERNE=";:\"<>?"

touch "$PATTERNA" 
touch "$PATTERNB" 
touch "$PATTERNC" 
touch "$PATTERND" 
touch "$PATTERNE"

NUM="6A"
$TRSH "$PATTERNA"
if [ -e "$TRASH_HOME/files/$PATTERNA" ]
then
	passed $NUM $TEST
else
	failed $NUM "Failed for pattern $PATTERNA"
fi


NUM="6B"
$TRSH "$PATTERNB"
if [ -e "$TRASH_HOME/files/$PATTERNB" ]
then
	passed $NUM $TEST
else
	failed $NUM "Failed for pattern $PATTERNB"
fi


NUM="6C"
$TRSH "$PATTERNC"
if [ -e "$TRASH_HOME/files/$PATTERNC" ]
then
	passed $NUM $TEST
else
	failed $NUM "Failed for pattern $PATTERNC"
fi

NUM="6D"
$TRSH "$PATTERND"
if [ -e "$TRASH_HOME/files/$PATTERND" ]
then
	passed $NUM $TEST
else
	failed $NUM "Failed for pattern $PATTERND"
fi

NUM="6E"
$TRSH "$PATTERNE"
if [ -e "$TRASH_HOME/files/$PATTERNE" ]
then
	passed $NUM $TEST
else
	failed $NUM "Failed for pattern $PATTERNE"
fi
############################### TEST 007 ################################
TEST="Delete multiple files"
NUM="7A"
FILE1="____multiple_1"
FILE2="____multiple_2"
FILE3="____multiple_3"

touch $FILE1
touch $FILE2
touch $FILE3

$TRSH $FILE1 $FILE2 $FILE3

if [ -e $TRASH_HOME/files/$FILE1 ] && [ -e $TRASH_HOME/files/$FILE2 ] && [ -e $TRASH_HOME/files/$FILE3 ]
then
	passed $NUM $TEST
else
	failed $NUM "Not all files passed are deleted"
fi

############# END OF DELETE TESTS ########################

################ RECOVER TESTS ###########################

############################### TEST 008 ################################
# Note $FILE1 $FILE2 $FILE3 were deleted together.
# They must be recovered together with the -u option
# without parameters.
TEST="Recover latests deleted files"
NUM="8A"

$TRSH -u
if [ -e $FILE1 ] && [ -e $FILE2 ] && [ -e $FILE3 ]
then
	passed $NUM $TEST
else
	failed $NUM "All files were not recovered together."
	ls $TEST_DIR/____multiple_*
fi
rm $FILE1 $FILE2 $FILE3

############################### TEST 009 ################################
TEST="Recover specifying a file"
NUM="9A"

FILE="____recover_specific"
touch $FILE
$TRSH $FILE
$TRSH -u $FILE
if [ -e $FILE ] 
then
	passed $NUM $TEST
else
	failed $NUM "Failed to recover file $FILE"
	ls $TEST_DIR/____recover*
	ls $TRASH_HOME/files/____recover*
fi
rm $FILE
############################### TEST 010 ################################
TEST="Test Interactive"
NUM="10A"
echo "y" >> yyy
echo "y" >> yyy
echo "y" >> yyy
echo "" >> yyy
echo "n" >> nnn
echo "n" >> nnn
echo "n" >> nnn
echo "" >> nnn

FILE1="___test_11A"
FILE2="___test_11B"
FILE3="___test_11C"
touch $FILE1
touch $FILE2
touch $FILE3

$TRSH -i $FILE1 $FILE2 $FILE3 < nnn
echo ""
# Answer was n. so files should not be deleted.
if [ -e $FILE1 ] && [ -e $FILE2 ] && [ -e $FILE3 ]
then
	passed $NUM $TEST
else
	failed $NUM "Filed deleted when answer was no."
fi

NUM="10B"
$TRSH -i $FILE1 $FILE2 $FILE3 < yyy
echo ""
if [ -e $FILE1 ] && [ -e $FILE2 ] && [ -e $FILE3 ]
then
	failed $NUM "Files not deleted when answer was yes"
else
	passed $NUM $TEST
fi

############################### TEST 011 ################################
TEST="Test force delete"
NUM="11A"
FILE="test_force"
touch $FILE
$TRSH -f $FILE
if [ -e $FILE ]
then
	failed $NUM "File not deleted with force"
else
	passed $NUM $TEST
fi
NUM="11B"
if [ -e $TRASH_HOME/files/$FILE ]
then
	failed $NUM "File moved to trash even with the -f option"
else
	passed $NUM $TEST
fi

############################### TEST 012 ################################
TEST="Regex Delete"
NUM="12A"
FILE1="test_1"
FILE2="test_2"
FILE3="test_a"
FILE4="test_\\d+"

touch $FILE1 $FILE2 $FILE3 $FILE4

$TRSH -ef
$TRSH -x "test_\d+"

if [ -e $FILE1 ] && [ -e $FILE2 ] && [ ! -e $FILE3 ] && [ ! -e $FILE4 ]
then
	failed $NUM "Files either not deleted or deletes other files"
else
	passed $NUM $TEST
fi

NUM="12B"

if [ -e $TRASH_HOME/files/$FILE1 ] && [ -e $TRASH_HOME/files/$FILE2 ] && [ ! -e $TRASH_HOME/files/$FILE3 ] && [ ! -e $TRASH_HOME/files/$FILE4 ]
then
	passed $NUM $TEST
else
	failed $NUM "Files were either not present in trash or other files present in trash"
fi

############################### TEST 013 ################################
TEST="Undo Regex"
NUM="13A"

$TRSH -ux "test_\d+"

if [ -e $FILE1 ] && [ -e $FILE2 ]
then
	passed $NUM $TEST
else
	failed $NUM "Not all files in the regex were undoed."
fi

NUM="13B"
if [ -e $TRASH_HOME/files/$FILE1 ] && [ -e $TRASH_HOME/files/$FILE2 ]
then
	failed $NUM "Regex undo does not remove files from trash"
else
	passed $NUM $TEST
fi
############################### TEST 014 ################################
TEST="Empty regex"
NUM="14A"

FILE1="test_a"
FILE2="test_b"
FILE3="test_1"
FILE4="test_2"

$TRSH $FILE1 $FILE2 $FILE3 $FILE4
$TRSH -exf "test_[a-z]+"
if [ -e $TRASH_HOME/files/$FILE1 ] || [ -e $TRASH_HOME/files/$FILE2 ]
then
	failed $NUM "Not all files removed from trash"
else
	passed $NUM $TEST
fi
NUM="14B"
if [ ! -e $TRASH_HOME/files/$FILE3 ] || [ ! -e $TRASH_HOME/files/$FILE4 ]
then
	failed $NUM "Files not part of regex removed"
else
	passed $NUM $TEST
fi

############################  END OF TESTS  #############################
# How do I test listing and size? They do not matter anyway

exit_tests
