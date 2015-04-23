You will need the following perl libraries
to use this script:

* IO::File
* Date::Manip::Date
* Text::CSV
* Time::HiRes
* Geo::Coder::Google

In most cases the easiest way to install them
is to type:

cpanm <LIBRARY>

ie: cpanm IO::File

If that turns out to be an issue though you can
always revert back to doing it manually using

perl -MCPAN -e shell

and after the shell is opened install each package
using the command

install IO::File

for instance.

If you're having trouble, contact me and I'll 
write a quick-n-dirty Makefile for you and upload
it here.  Given the amount of documentation I've
just added... maybe I should have done that in 
the first place. :)

-- good luck!
