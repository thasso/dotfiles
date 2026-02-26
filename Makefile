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

ghostty-clean:
	rm -rf ~/.config/ghostty

.PHONY: ghostty
ghostty:
	ln -sf $(CURDIR)/ghostty ~/.config/ghostty


nvim-clean:
	rm -rf ~/.config/nvim

.PHONY: nvim
nvim:
	ln -sf $(CURDIR)/nvim ~/.config/nvim

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
	rm -f ~/.zprofile
	rm -f ~/.zshenv
	rm -f ~/.zpath
	rm -f ~/.p10k.zsh
	rm -f ~/.zsh

zsh: init zsh-clean
	ln -s $(CURDIR)/zshrc ~/.zshrc
	ln -s $(CURDIR)/zprofile ~/.zprofile
	ln -s $(CURDIR)/zpath ~/.zpath
	ln -s $(CURDIR)/zshenv ~/.zshenv
	ln -s $(CURDIR)/p10k.zsh ~/.p10k.zsh
	ln -s $(CURDIR)/zsh ~/.zsh

opencode-clean:
	rm -f ~/.config/opencode/agent
	rm -f ~/.config/opencode/command
	rm -f ~/.config/opencode/tool
	rm -f ~/.config/opencode/opencode.json

opencode: init opencode-clean
	@mkdir -p ~/.config/opencode
	ln -s $(CURDIR)/opencode/agent ~/.config/opencode/agent
	ln -s $(CURDIR)/opencode/command ~/.config/opencode/command
	ln -s $(CURDIR)/opencode/tool ~/.config/opencode/tool
	ln -s $(CURDIR)/opencode/opencode.json ~/.config/opencode/opencode.json

atuin-clean:
	rm -f ~/.config/atuin

atuin: init atuin-clean
	ln -s $(CURDIR)/atuin ~/.config/atuin

tmux-clean:
	rm -f ~/.tmux.conf
	rm -f ~/.config/tmux

tmux: tmux-clean
	ln -s $(CURDIR)/tmux.conf ~/.tmux.conf
	ln -s $(CURDIR)/tmux ~/.config/tmux

vscode:
	mkdir -p $(HOME)/Library/Application\ Support/Code/User
	ln -s VSCode/settings.json $(HOME)/Library/Application\ Support/Code/User/settings.json
	ln -s VSCode/keybindings.json $(HOME)/Library/Application\ Support/Code/User/keybindings.json
	ln -s VSCode/snippets $(HOME)/Library/Application\ Support/Code/User/snippets

bin-scripts:
	@mkdir -p $(HOME)/bin
	@for script in $(CURDIR)/bin/*; do \
		if [ -f "$$script" ]; then \
			ln -sf "$$script" $(HOME)/bin/$$(basename "$$script"); \
		fi; \
	done
	@echo "Linked bin scripts to ~/bin"
