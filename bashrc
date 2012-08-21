#!/bin/bash

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

## terminal environment
unset COLORS
unset LS_COLORS

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
        # We have color support; assume it's compliant with Ecma-48
        # (ISO/IEC-6429). (Lack of such support is extremely rare, and such
        # a case would tend to support setf rather than setaf.)
        color_prompt=yes
    else
        color_prompt=
    fi
fi

# Set autocompletion and PS1 integration
if [ `uname` = 'Darwin' ]; then
    if [ -f `brew --prefix`/etc/bash_completion ]; then
        . `brew --prefix`/etc/bash_completion
    fi
else
    if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
        . /etc/bash_completion
    fi
fi

## function to get the current branch if we are in a git repo
__git_ps1 () {
    local b="$(git symbolic-ref HEAD 2>/dev/null)";
    if [ -n "$b" ]; then
        printf " (%s)" "${b##refs/heads/}";
    fi
}
## The prompt
export PS1='\u@\h:\w \[\033[31m\]$(__git_ps1 "(%s)") \[\033[01;34m\]$\[\033[00m\] '


## default tweaks for mac os x
if [ `uname` == 'Darwin' ]; then
    alias ls="ls -G"
    alias ll="ls -laG"
    export PATH=$PATH:~/Library/Python/2.7/bin
fi

## default path and library path
export PATH=$HOME/usr/bin:$PATH
export LD_LIBRARY_PATH=$HOME/usr/lib:$LD_LIBRARY_PATH

## configure editor
export ALTERNATE_EDITOR=emacs
export EDITOR='emacsclient'
export VISUAL=$EDITOR
export GIT_EDITOR=$EDITOR
alias emacs='emacsclient -t'


## language
export LC_CTYPE="en_US.UTF-8"
export LANG="en_US.UTF-8"

## load customizations
if [ -d "$HOME/.bashrc.d" ]; then
    for file in $HOME/.bashrc.d/*; do
        . $file
    done
fi
