> See the
> [project page](https://vigou3.github.io/emacs-modified-macos) for
> detailed information on the distribution and to obtain binary
> releases.

# Emacs Modified for macOS

*Emacs Modified for macOS* is a distribution of
[GNU Emacs](https://www.gnu.org/software/emacs/) bundled with a few
select packages for LaTeX users and R developers, most notably
[AUCTeX](https://www.gnu.org/software/auctex/) and
[ESS](https://ess.r-project.org). The distribution is based on the
latest stable release of GNU Emacs
[compiled by David Caldwell](https://emacsformacosx.com).

Other than the additions mentioned above and some minor configuration,
this is a stock distribution of Emacs. Users of Emacs on other
platforms will appreciate the similar look and feel of the
application.

## Repository content

The repository contains a few distribution-specific files and a
`Makefile` to fetch the other components and combine everything into a
disk image. The complete source code of Emacs and the extensions is
not hosted here.

## Prerequisites

Building the distribution on macOS requires `make`, `hdiutil`, `curl`,
`git` and a number of standard Unix command line tools. Many of these
utilities do not come bundled with the operating system. One first
needs to install Xcode from the App Store and, second, to install the
Command Line Developer Tools by launching from the Terminal the
following command:

```bash
$ xcode-select --install
```

## Building the distribution

Edit the `Makeconf` file to set the version numbers of GNU Emacs, the
distribution and the various extensions (more on this below). Then
`make` or `make all` will launch the following three main steps:

1. `get-packages` will fetch the binary release of GNU Emacs from
   [Emacs for Mac OS X](https://emacsformacosx.com); the official
   releases of [ESS](https://ess.r-project.org),
   [AUCTeX](https://www.gnu.org/software/auctex/) and
   [org](https://org-mode.org);
   [`markdown-mode.el`](https://github.com/jrblevin/markdown-mode),
   [`exec-path-from-shell.el`](https://github.com/purcell/exec-path-from-shell)
   and
   [`psvn.el`](http://svn.apache.org/repos/asf/subversion/trunk/contrib/client-side/emacs/)
   from their respective GitHub or Subversion repositories; the
   snapshot of the master branch of
   [Polymode](https://github.com/vspinu/polymode/).

2. `emacs` will, in summary, decompress the
   [Emacs for Mac OS X](https://emacsformacosx.com) disk image in a
   temporary directory, add all the extensions into the application
   tree and build a new signed application bundle.

3. `release` will create a tag and a release on GitHub, upload the
   disk image and attach it to said release, and update the project's
   web page with the correct version numbers and hyperlinks.

Each of the above three steps is split into smaller recipes, around 20
in total. See the `Makefile` for details.

## Publishing on GitHub

Publishing a release and uploading files in GitHub from the command
line involves using the
[GitHub API](https://developer.github.com/v3/). The interested reader
may have a look at the `create-release` and `upload` recipes in the
`Makefile` to see how we achieved complete automation of the process,
including the extraction of the release notes from the `NEWS` file.

## Version numbers of the extensions

The most manual part of the build process has always been to get the
version numbers of the latest releases for all the bundled extensions.
Here's how I managed to make my life easier using
[Git Submodules](https://git-scm.com/book/en/v2/Git-Tools-Submodules).

In a separate directory, I created a purely local Git repository named
`emacs-modified-extensions`:

```bash
$ git init emacs-modified-extensions
```

In this repository I added the following submodules:

```bash
$ git submodule add https://github.com/emacs-ess/ESS/
$ git submodule add http://git.savannah.gnu.org/r/auctex.git
$ git submodule add http://orgmode.org/org-mode.git/
$ git submodule add https://github.com/vspinu/polymode
$ git submodule add https://github.com/jrblevin/markdown-mode
$ git submodule add https://github.com/purcell/exec-path-from-shell
```

Finally, I created a `Makefile` with the following content to fetch
the version numbers of the latest releases of each of the above
submodules (except Polymode, where the date of the latest snapshop of
the master branch is used). The script also extracts the latest
revision number of `psvn.el` in the Subversion source code repository.

```Makefile
all :
	git submodule foreach 'git submodule update'
	if [ -f versions.txt ]; then rm versions.txt; fi
	touch versions.txt
	echo ESSVERSION=$(shell git -C ESS describe --tags | cut -d - -f 1 | tr -d v) \
	  >> versions.txt
	echo AUCTEXVERSION=$(shell git -C auctex describe --tags | cut -d - -f 1 | cut -d _ -f 2-3 | tr _ .) \
	  >> versions.txt
	echo ORGVERSION=$(shell git -C org-mode describe --tags | cut -d - -f 1 | cut -d _ -f 2) \
	  >> versions.txt
	echo POLYMODEVERSION=$(shell git -C polymode show -s --format="%ci" HEAD | cut -d " " -f 1) \
	  >> versions.txt
	echo MARKDOWNLOADVERSION=$(shell git -C markdown-mode describe --tags | cut -d - -f 1 | tr -d v) \
	  >> versions.txt
	echo EXECPATHVERSION=$(shell git -C exec-path-from-shell describe --tags | cut -d - -f 1) \
	  >> versions.txt
	echo PSVNVERSION=$(shell svn log -q -l 1 http://svn.apache.org/repos/asf/subversion/trunk/contrib/client-side/emacs/psvn.el \
	  | grep ^r | cut -d " " -f 1 | tr -d r) \
	  >> versions.txt
```

Running `make` in this directory yields a file `versions.txt`
containing the variable initialization strings to use in this
project's `Makeconf` file.

This is actually simpler than using `git ls-remote`.

