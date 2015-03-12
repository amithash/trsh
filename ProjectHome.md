
---

> # TRSH #
> Copyright 2008 Amithash Prasad

> Trsh is free software: you can redistribute it and/or modify
> it under the terms of the GNU General Public License as published by
> the Free Software Foundation, either version 3 of the License, or
> (at your option) any later version.

> This program is distributed in the hope that it will be useful,
> but WITHOUT ANY WARRANTY; without even the implied warranty of
> MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
> GNU General Public License for more details.

> You should have received a copy of the GNU General Public License
> along with this program.  If not, see <http://www.gnu.org/licenses/>.


---


### A safer RM tool which uses a trash ###

Downloads have been moved to:
https://drive.google.com/folderview?id=0B-AJPvOjZVdwNG55enhRUldSRlk&usp=sharing


![http://trsh.googlecode.com/svn/wiki/trsh-listing.png](http://trsh.googlecode.com/svn/wiki/trsh-listing.png)

### Motivation ###

Once upon a time, I deleted my homework and there was no way of redemption. I spent some time breathing fire on the "rm" tool, and tried my level best to recover these files. Finally, I gave up and rewrote everything from scratch.

I tried a simple alias to make rm prompt by default. It soon drove me up the wall.
I then tried a simple alias for rm to mv. That did not work most of the time and it drove my friends up the wall (Who did not know of the alias). This was when I started development of this wrapper script and grew up to version 2.x.

After which I started using the KDE desktop predominantly and discovered that the files I deleted with trsh and the ones I delete with the desktop file manager were never in sync (I used another trash folder and different specifications). This was the birth of trsh 3.x - a rewrite and is currently considered stable.

This is one if the first scripts I install on a clean system and hence I am also the biggest user. As I use this almost every day, I discover most the the bugs and annoyances and try to fix them.

As usual do use the tool with caution and please do report bugs:
1. Any departure from the workings of day-to-day /bin/rm usage is a bug.
2. Any departure from the freeDesktop.org's trash specification is a bug.

### Links to Wiki ###
[FEATURES](http://code.google.com/p/trsh/wiki/FEATURES)
[USAGE](http://code.google.com/p/trsh/wiki/USAGE)
[EXAMPLES](http://code.google.com/p/trsh/wiki/EXAMPLES)
