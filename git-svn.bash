#!/bin/bash
#
# # pass-git-svn
#
# This is an extension to the [standard linux password
# manager](https://www.passwordstore.org/) that allows passwords to
# back up to an svn repository instead of a git repository.  This
# extension does that by using git-svn.
#
############################################################
# ## Install
#
# You will need a recentish version of pass that has extensions
# enabled.  Install pass 1.7+ from [its git
# repository](https://git.zx2c4.com/password-store) or from your Linux
# distribution's repository:
#
#     apt-get install -y pass
#
# You will also need a copy of this extension:
#
#     git clone https://github.com/OpenTechStrategies/pass-git-svn
#
# Set up your environment (you might want to add this to .bashrc):
#
#     export PASSWORD_STORE_ENABLE_EXTENSIONS=true
#
# Install the software and clone the svn repo:
#     mkdir -p ~/.password-store/.extensions
#     cp <path-to-pass-git-svn-repo>/git-svn.bash ~/.password-store/.extensions
#     chmod +x ~/.password-store/.extensions/git-svn.bash
#     pass git-svn clone https://example.com/repos/work/trunk/.password-store ~/.password-store
#
############################################################
# ## Using pass-git-svn
#
# You can use pass as you normally would.  It's in-built git routines
# will keep checking in your local changes.  When it's time to sync
# with your svn server, use `pass git-svn fetch` and `pass git-svn
# rebase` to pull down changes.  Then, use `pass git-svn dcommit` to
# send your changes up to the svn server.
#
############################################################
# ## Authorizing new people to read/write to the password store
#
# Just add them to .gpg-id.  This works on a per-directory basis, so you
# can restrict people by leaving them out of that file.  TODO: verify
# that lots of people in a parent dir is effectively restricted by fewer
# people in the subdir .gpg-id.
#
# Note that adding somebody to the .gpg-id does not actually
# re-encrypt all the files in that directory with that person's key.
# Same with removing a person.  TODO: investigate whether the init
# command can be used to handle this.  Or else script opening and
# saving all the files to update the list of keys that will decrypt
# them.
#
###########################################################
# ## Security
#
# If you have a group of people sharing a repository, be aware that if
# any of them can change `.gpg-id` files in the tree, they can
# potentially add themselves to a `.gpg-id` file in a directory whose
# passwords they should not have access to.
#
# While this would not automatically grant them the ability to read
# password files that they couldn't read before (since they wouldn't be
# able to decrypt an existing file in order to re-encrypt it with a new
# list of keys that now includes their key), there is still the
# possibility that the next fully-authorized person who comes along and
# re-encrypts a file would then accidentally include the new key.
#
# You might want to manage your repository to prevent this from
# happening.  You could do that through authz, or through server-side
# pre-commit hooks.
#
###########################################################
# ## Dependencies
#
# This extension depends on git-svn and pass being present on the
# system.
#
###########################################################
# ## Two pass configurations
#
# If you already have pass running with another configuration, you can add
# something like this to .bashrc
#
#     alias workpass='PASSWORD_STORE_ENABLE_EXTENSIONS=true PASSWORD_STORE_DIR=~/.work-password-store pass'
#
# This will let you do `workpass git-svn fetch` to sync your work
# passwords and keep them separate from your usual ~/.password-store.
# You can continue to access your non-work passwords with `pass`.  You
# can also use symlinks to access your work passwords from your
# non-work password store.  You'll still need to workpass for git-svn
# commands, though.
###########################################################
# ## Contributing
#
# Please file bug reports and issue patch requests in the GitHub
# repository.  All participation is welcome!
#
# This extension is based on some code found in password-store.sh from
# the [standard linux password
# manager](https://www.passwordstore.org/).  That code is licensed
# under GPLv2+.  This extension is copyright 2017 James Vasile
# <james@opentechstrategies.com> and is released under the terms of
# the [GNU General Public License, Version
# 3](https://www.gnu.org/licenses/gpl-3.0-standalone.html) or later.
#
###########################################################
# ## Documentation
#
# This extension will display documentation if run directly as a bash
# script or as an extension if you do `pass git-svn` or `pass git-svn help`
if [[ "$0" == ${BASH_SOURCE[0]} || $1 == "help" || -z "$1" ]]; then
		tail -n +3 ${BASH_SOURCE[0]} | sed "s/^\#\# //" | grep ^\# | sed "s/\#\#\#\#\#\#\#\#\#\#*//" | sed "s/. \?//"
		exit
fi

## Begin extension code here
set_git "$PREFIX/"
if [[ $1 == "clone" ]]; then
		INNER_GIT_DIR="$PREFIX"
		pushd "$INNER_GIT_DIR" > /dev/null
		rm -f /tmp/.gpg-id.orig
		[[ -e .gpg-id ]] && mv .gpg-id /tmp/.gpg-id.orig
		touch .gitignore
		grep -q .gitattributes .gitignore || echo .gitattributes >> .gitignore
		grep -q .gitignore .gitignore || echo .gitignore >> .gitignore
		grep -q .extensions .gitignore || echo .extensions >> .gitignore
		shift
		git svn clone "$1" . || exit 1
		[[ -e /tmp/.gpg-id.orig ]] && cat /tmp/.gpg-id.orig >> .gpg-id
		sort -u .gpg-id -o .gpg-id
		popd > /dev/null
		git_add_file "$PREFIX" "Add current contents of password store."

		echo '*.gpg diff=gpg' > "$PREFIX/.gitattributes"
		git_add_file .gitattributes "Configure git repository for gpg file diff."
		git -C "$INNER_GIT_DIR" config --local diff.gpg.binary true
		git -C "$INNER_GIT_DIR" config --local diff.gpg.textconv "$GPG -d ${GPG_OPTS[*]}"
elif [[ -n $INNER_GIT_DIR ]]; then
		pushd $INNER_GIT_DIR > /dev/null
		tmpdir nowarn #Defines $SECURE_TMPDIR. We don't warn, because at most, this only copies encrypted files.
		export TMPDIR="$SECURE_TMPDIR"
		git svn "$@"
		popd > /dev/null
else
		die "Error: the password store is not a git-svn repository. Try \"$PROGRAM git-svn init\"."
fi
