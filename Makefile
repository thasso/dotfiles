COMMAND_T_PATH = vim/bundle/command-t
POWERLINE_PATH = vim/bundle/powerline

all: vim bash tmux gitconfig
	@echo "Configuration installed"

init:
	git submodule init

gitconfig-clean:
	rm -f ~/.gitconfig

gitconfig: gitconfig-clean
	ln -sf $(CURDIR)/gitconfig ~/.gitconfig
	
vim-clean:
	rm -f ~/.vimrc
	rm -Rf ~/.vim

vim-init:
	ln -sf $(CURDIR)/vim ~/.vim
	ln -sf ~/.vim/vimrc ~/.vimrc

vim: init vim-clean vim-init
	echo "Vim plugins initialized"

command-t: vim-init
	cd $(COMMAND_T_PATH)/ruby/command-t; ruby extconf.rb; make

powerline: vim-init
	cd $(POWERLINE_PATH); python setup.py install --user	
	@mkdir -p ~/.config/powerline
	cp -R $(POWERLINE_PATH)/powerline/config_files/* ~/.config/powerline/
	@rm -f ~/.config/powerline/config.json
	ln -s $(CURDIR)/powerline_config.json ~/.config/powerline/config.json	

bash-clean:
	rm -f ~/.bashrc
	rm -f ~/.profile

bash-init:
	@mkdir -p ~/.bashrc.d

bash: init bash-clean bash-init
	ln -s $(CURDIR)/bashrc ~/.bashrc
	ln -s $(CURDIR)/profile ~/.profile

zsh-clean:
	rm -f ~/.zshrc
	rm -f ~/.zsh.d

zsh: init zsh-clean
	ln -s $(CURDIR)/zshrc ~/.zshrc
	ln -s $(CURDIR)/zsh.d ~/.zsh.d


tmux-clean:
	rm -f ~/.tmux.conf

tmux: tmux-clean
	ln -s $(CURDIR)/tmux.conf ~/.tmux.conf
