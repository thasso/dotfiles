#!/bin/bash

## initialize git submodules
git submodule init || (echo "Unable to initialize git submodules"; exit 1)

## link files
files=".vimrc
.vim"

for f in $files; do
    t=$HOME/$f
    s=$(readlink -f $f)
    echo "Removing ${t}"
    rm -Rf $t
    echo "Linking ${s} to ${t}"
    ln -sf $s $t
done
