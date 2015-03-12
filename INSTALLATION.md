There are rpm and deb packages avaliable for trsh. Note that I am new at making packages so they are not perfect. So do not try anything fancy.

# OpenSuSE/Fedora/Redhat and other RPM based distributions #
Install (as root):
rpm -ivh trsh-xx.xx-xx.noarch.rpm
Update/Upgrade (as root):
rpm -Uvh trsh-xx.xx-xx.noarch.rpm

Of course, this is a system wide installation and all users will use trsh.

# Ubuntu/Kubuntu/Debian and other DEB based distributions #
Install and Upgrade:
sudo dpkg -i trsh-xx.xx-xx.deb

# Installation from source #
```
./configure.pl [OPTIONS]
OPTIONS:
--user -- Perform a user installation, do not affect other users on the system.
--nouser (Default) -- Perform a system wide installation
--install-path=PATH -- Provide the PATH where trsh.pl will be installed.
--man-path=PATH -- Provide the PATH where the man page should be installed. Will be auto detected if not provided, and not installed for a user installation.
--perl-path=PATH -- Provide the path where perl is installed. Will be auto detected and useful only if you have multiple versions of perl installed.
--shell-path=PATH -- Provide the path to the shell. Else trsh will be installed to the current shell.
--rcfile-path=PATH -- Provide the path for the ${SHELL}rc file to modify to add the aliases.
```

```
make 
```

```
make install
```

# Manual Installation #

If none of the above three is good for you. Probably you have a weird shell.

1. First of all decide whether you want a system install (Install trsh for all users) or a user install (Install trsh just for yourself).

2. Based on your decision the location of your RC file will change. The user RC is in your home directory and the system wide RC file is mostly in the /etc dir, On my system, these are /etc/bashrc (System) or $HOME/.bashrc (User).

3. Edit your RC file to add aliases to trsh. This is done in bash by the following commands:
alias rm="/path/to/trsh.pl"
alias undo="/path/to/trsh.pl -u"

4. Copy trsh.pl to /path/to/trsh.pl

5. If you want a man page, copy trsh.1.gz to /usr/share/man/man1/

You are done now, restart your shell for the changes to take effect.

Note the RPM is tested on OpenSuSE, the deb is tested on ubuntu. And the source install is tested on both.