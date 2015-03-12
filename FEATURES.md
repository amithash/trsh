## TRSH FEATURES ##

---


  * Follows the freeDesktop.org's Trash specification so your desktop and command prompt share a single trash and are in sync with each other. As per the specifications, each partition has it's own trash and hence deletions are just a re-link and is very quick.

  * Deletes all files by moving them to trash without overwriting exesting files (trsh.pl /path/to/files)

  * Delete files matching a regex (trsh.pl -x "/path/to/file.+"

  * Permanent option is available, which deletes the files permanently and cannot be restored. (trsh.pl -p /path/to/unwanted/files)

  * A recursive option is available to delete directories (trsh.pl -r /path/to/directory)

  * A delete can be interactive, where the user is prompted for every file (trsh.pl -i /path/to/files )

  * Anything can be verbose, useful in debugging. (trsh -v )

  * A deleted file can be recovered either by name (trsh.pl -u something) or by path (trsh -u /where/file/was) a matching regex `(trsh.pl -ux "some.*")` or the latest set of files (trsh.pl -u)

  * Specific files can be removed from the trash, either by name (trsh.pl -e something) or a path (trsh.pl -e /path/to/where/something/was) or a matched regex `(trsh.pl -ex "some*")` or empty the trash (trsh.pl -e).

  * Contents of the trash can be listed (trsh.pl -l) where the files in trashes (from all mounted devices) are listed with their name, date of deletion (relative date like "yesterday") and their origional path.

  * Size of each trash can be displayed. (-h option makes the size displayed human readable). (trsh.pl -s or trsh.pl -sh)

  * Size of each trash entry can be displayed during listing (trsh.pl -ls or trsh.pl -lsh). Note: As the freeDesktop.org's specification does not allow each trash entry's file size to be stored, a stat is performed on all files in the directory.

  * Size can be displayed in a human readable form with an option (trsh.pl -lsh or trsh.pl -sh)

  * When trsh creates its trash directory, its permissions are set such that only the user can access it. (Privacy).

  * Once the size of a trash is computed, the _total_ size is cached. So as long as no other files are deleted, the next time trsh.pl -s is called, a stat operation is not performed.

  * Any operation which might potentially nag the user can be forced with the -f option.

  * All regex's used are perl regex. Hence you can perform complex tasks. Any operation which takes in a parameter can also take in a regex if provided the -x option.

  * You can list only specific files in the trash matching a regex by providing the regex as a parameter (`trsh.pl -lx SOME_.+_PATTERN`

  * --nocolor option is provided to make trsh not print using the terminal color support. Useful for older terminals.

  * --nodate Option can be provided to not display the date in listings.

  * --norelative-date Option can be provided to display the real date in listings rather than the relative date of deletion.


## ODD NOTES TO USERS ##

---

Please be mindful of your Trash size. Do check it often and empty or remove large files. Sometimes you might have a disk space quota, and you do not want to reach that limit. If it is your personal system, this is not an issue. But every time you ask the question: "Where has all my disk space gone?" check your trash!

CRON can be configured to check your trash size every month and send you an email about it! If you would like that, execute this:
crontab -e
And add the following line at the end of the list
@monthly /path/to/trsh.pl -sh

This will send you a mail with the trash size every month.