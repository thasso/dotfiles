Dotfiles
--------

Repository contains dotfiles. Some of them are obsolete or unused and kept for
reference, the important ones can be installed with a Makefile. In order to
install the bash and vim configurations, run:
	
	make

NOTE that this will remove the current configuration and replace it with the
git submodule init dot files from this repository. All files and directories are
softlinked if possible. There are a few dependencies that have to be resolved
manually.

The vim command-t plugin need ruby and a vim with ruby support, the powerline
needs python and a vim compiled with python support. In addition, powerline
needs some tweaked fonts. The fonts are already added here as a submodule, but
they need to be installed.
