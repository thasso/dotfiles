all: vim bash zsh tmux gitconfig
	@echo "Configuration installed"

init:
	git submodule init
	# install colors, they are used by the shells
	@rm -rf ~/.config/base16-shell
	ln -sf $(CURDIR)/base16-colors ~/.config/base16-shell

gitconfig-clean:
	rm -f ~/.gitconfig

gitconfig: gitconfig-clean
	ln -sf $(CURDIR)/gitconfig ~/.gitconfig
	
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

zsh: init zsh-clean
	ln -s $(CURDIR)/zshrc ~/.zshrc
	ln -s $(CURDIR)/zsh.d ~/.zsh.d

tmux-clean:
	rm -f ~/.tmux.conf

tmux: tmux-clean
	ln -s $(CURDIR)/tmux.conf ~/.tmux.conf
