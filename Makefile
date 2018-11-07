all: vim bash zsh tmux gitconfig
	@echo "Configuration installed"

init:
	git submodule init
	# install colors, they are used by the shells
	@mkdir -p ~/.config
	@rm -rf ~/.config/base16-shell
	ln -sf $(CURDIR)/base16-colors ~/.config/base16-shell

gitconfig-clean:
	rm -f ~/.gitconfig

gitconfig: gitconfig-clean
	ln -sf $(CURDIR)/gitconfig ~/.gitconfig

nvim-clean:
	rm -rf ~/.config/nvim

.PHONY: nvim
nvim:
	@mkdir -p ~/.config/nvim
	ln -s $(CURDIR)/nvim/init.vim ~/.config/nvim/init.vim
	ln -s $(CURDIR)/nvim/autoload ~/.config/nvim/autoload

vim-clean:
	rm -f ~/.vimrc
	rm -Rf ~/.vim

vim: init vim-clean
	ln -sf $(CURDIR)/vimrc ~/.vimrc
	echo "Vim config liked, installing plugins..."

matplotlib:
	@mkdir -p ~/.config/matplotlib
	@rm -f ~/.config/matplotlib/matplotlibrc
	ln -s $(CURDIR)/matplotlibrc ~/.config/matplotlib/matplotlibrc

bash-clean:
	rm -f ~/.bashrc
	rm -f ~/.profile

bash: init bash-clean
	@mkdir -p ~/.bashrc.d
	ln -s $(CURDIR)/bashrc ~/.bashrc
	ln -s $(CURDIR)/profile ~/.profile

zsh-clean:
	rm -f ~/.zshrc
	rm -f ~/.zsh.d
	rm -f ~/.oh-my-zsh

zsh: init zsh-clean
	ln -s $(CURDIR)/zshrc ~/.zshrc
	ln -s $(CURDIR)/zsh.d ~/.zsh.d
	ln -s $(CURDIR)/oh-my-zsh ~/.oh-my-zsh

tmux-clean:
	rm -f ~/.tmux.conf

tmux: tmux-clean
	ln -s $(CURDIR)/tmux.conf ~/.tmux.conf

vscode:
	mkdir -p $(HOME)/Library/Application\ Support/Code/User
	ln -s VSCode/settings.json $(HOME)/Library/Application\ Support/Code/User/settings.json
	ln -s VSCode/keybindings.json $(HOME)/Library/Application\ Support/Code/User/keybindings.json
	ln -s VSCode/snippets $(HOME)/Library/Application\ Support/Code/User/snippets
