# Path to your oh-my-zsh configuration.
ZSH=$HOME/.zsh.d

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
ZSH_THEME="agnoster"

# Set to this to use case-sensitive completion
# CASE_SENSITIVE="true"

# Uncomment to change how often before auto-updates occur? (in days)
# export UPDATE_ZSH_DAYS=13

# Uncomment following line if you want to disable colors in ls
# DISABLE_LS_COLORS="true"

# Uncomment following line if you want to disable autosetting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment following line if you want to disable command autocorrection
# DISABLE_CORRECTION="true"

# Uncomment following line if you want red dots to be displayed while waiting for completion
# COMPLETION_WAITING_DOTS="true"

# Uncomment following line if you want to disable marking untracked files under
# VCS as dirty. This makes repository status check for large repositories much,
# much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
plugins=(git git-flow virtualenv)

source $ZSH/zsh.sh

# Customize to your needs...
export PATH=$HOME/bin:$HOME/usr/bin:$PATH
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$HOME/usr/lib

# disable ssh askpass
unset SSH_ASKPASS
# terminal configuration
export TERM="xterm-256color"
# language setup
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
# set default user name
export DEFAULT_USER=thasso
#editor settings
export EDITOR=vim
# enable zmv by default
autoload zmv
# disable autocorrect
unsetopt correct
unsetopt correct_all

# load extensions
ext_files=($ZSH/ext/*.zsh) 2>/dev/null
for config_file ($ext_files); do
  source $config_file
done
