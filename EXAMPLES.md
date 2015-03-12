All the examples assume that the following aliases exist:
```
rm="trsh.pl"
undo="trsh.pl -u"
```

### Removal: ###
```
rm test1 test2 *.gz # Move a bunch of files to trash.
```
Directories are not deleted by default. trsh will give an error message. Use the -r option. Refer being recursive below.
### Recover: ###
```
undo test1 # Specify the file name to recover
undo -x ".*.gz" # Specify a regex in quotes.
undo # Recover the latest set of files which was deleted.
```
### Displays ###
```
rm -l
Trash Entry                                 | Deletion Date | Restore Path
-----------                                 | ------------- | ------------
features.dat                                | Today         | /home/user/tiny-utils/../features.dat
upload_files.sh                             | Yesterday     | /home/user/upload_files.sh

```

```
rm -s
180597744     | Home Trash
```
Display the size in bytes. If you want an output to be more human readable, use the -h option.
```
rm -sh
172.231 MB    | Home Trash
```
Size of each file can also be displayed with the listing, and that too can be human readable.
```
rm -lsh
aeprasad@linux-3lk6:~/trsh> rm -lsh
Trash Entry                                 | Deletion Date | Size      | Restore Path
-----------                                 | ------------- | ----      | ------------
features.dat                                | Today         | 8.790 kB  | /home/user/tiny-utils/../features.dat
upload_files.sh                             | Yesterday     | 265.000 B | /home/user/upload_files.sh

```
### Emptying ###
```
rm -e test # Remove test from the trash permanently.

rm -ex "test.*" # Remove test1 test2 (Which match the regex "test*" from the trash permanently
Are you sure you want to remove test1 from the trash? (y/n):y
Are you sure you want to remove test2 from the trash? (y/n):y

rm -e # Empty the trash. 
Are you sure you want to empty the trash? (y/n):y
```
You can be forceful with the empty option, where trsh will not nag you. but it is not recomended!
```
rm -ef "test*" # Do not ask for every file.
rm -ef # Do not ask for a confirmation
```

### Being Permanent ###
```
rm -p test
```
Removes the file test permanently bypassing the trash. In simpler words, test is gone and cannot be recovered! In simple words, when deleting files, the -p option mimics rm and hence all the options you use is passed on to rm:
```
rm -rpf new_test_dir some_files_*
# same as:
/bin/rm -rf new_test_dir some_files_*
```

### Being Recursive ###
```
rm -r test_dir # Move test_dir to the trash
rm -rp new_test_dir # Remove new_test_dir permanently.
```
while test\_dir is moved to trash, new\_test\_dir is permanently removed. Use the -r option to delete directories.

### Others ###
Use the -v option to make anything verbose.
--help option displays the help and the version.

### Perl Style Regex ###
All regexes are perl regexes to delete, restore and remove files from trash. The -x option turns this feature on.
```
rm -x "/some/random/path/test\.\d+\.log" # Removes all files test.<number>.log from /some/random/path
undo -x "test\.\d+\.log" # Recovers all files with the name test.<number>.log to cwd.
rm -ex "test\.\d+\.log" # Removes all test.<number>.log from the trash.
```
This option allows you to use trsh in a more advanced way if you are comfortable with perl regular expressions.

As usual, you need to enclose the regex in quotes.