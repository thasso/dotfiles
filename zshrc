# Homebrew path
export PATH=$HOME/bin:$HOME/.local/bin:$HOME/usr/bin:/usr/local/bin:$PATH
# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh
#ZSH_THEME="sorin"
#ZSH_THEME="avit"
ZSH_THEME="sorin"
DISABLE_AUTO_UPDATE="true"
DISABLE_AUTO_TITLE="true"
ZSH_CUSTOM=$HOME/.zshext
plugins=(gitfast virtualenv adb themes gradle)
source $ZSH/oh-my-zsh.sh

# language and base shell
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# aliases
alias tmux="env TERM=screen-256color tmux -2"
alias lg="lazygit"
function github () {
    open `git remote get-url origin | sed -e 's/git@//; s/:/\//; s/\.git$//; s/^/https:\/\//'`
}


# vim and editor
export EDITOR=vim

#Pyenv setup
# export PATH=/usr/local/opt/python/libexec/bin:$PATH
#eval "$(pyenv init -)"
#eval "$(pyenv virtualenv-init -)"

#export JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk1.8.0_192.jdk/Contents/Home

# fzf setup
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

[ -f ~/.tokens.sh ] && source ~/.tokens.sh
