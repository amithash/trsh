USAGE:
`rm [OPTIONS]... [FILES]...`

FILES: A list of files to recover or delete.
rm FILES just moves FILES to the trash. By default, directories are not deleted.

OPTIONS:

-u|--undo `[FILES]`
Undo's a delete (Restores FILES or files matching REGEX from trash).
Without arguments, the latest deleted file is restored.

-p|--permanent FILES
Instructs trsh to permanently delete FILES and completely bypass the trash

-i|--interactively
Prompt the user before any operation.

-r|--recursive
Allows directories to be deleted.

-v|--verbose
Provide verbose output.

-e|--empty `[FILES]`
Removed FILES or files matching REGEX from the trash (Permanently).
Without arguments, the trash is emptied.

-f|--force
Forces any operation:
deletion   : overrides -i and does not prompt the user for any action. with -p passes the -f flag to /bin/rm

restore    : will force overwrites of files and will not ask for user permission.

empty file : will not ask the user's permission for each file.

empty trash: will not ask for confirmation from the user.

-l|--list
Display the contents of the trash.

--color (Default) (or --nocolor)
Print listings (Refer -l) with (or without) the terminal's support for colored text.

--date (Default) (or --nodate)
Print (Or do not print) the deletion date with the trash listing (-l)

--relative-date (Default) (or --norelative-date)
Display (or do not display) date in listings as a relative figure in words.

-x|--regex
Considers all parameters (All uses) as perl regexes. So you can delete, undo or remove files
using perl's extensive regex.

-s|--size
Display the size in bytes of the trash.
If used along with -l, the trash listing will also display each file's size.

-h|--human-readable
If used along with -s, the file size displayed will be human readable
(KB, MB etc) rather than in bytes.

--help
Displays this help and exits.

Please read the README or `man trsh` for more information