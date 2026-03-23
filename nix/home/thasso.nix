{ config, pkgs, ... }:

let
 dotfiles = "${config.home.homeDirectory}/dotfiles";
in

{
  home.stateVersion = "25.11";

  programs.zsh = {
    enable = true;
    initContent = ''
      source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
      ${builtins.readFile ./zsh/init.zsh}
    '';
  };

  home.packages = with pkgs; [
    zsh-powerlevel10k
  ];

  # Symlink zsh config files from dotfiles repo
  home.file = {
   ".p10k.zsh".source = ./zsh/p10k.zsh;
   #".zshrc".source = 
   #  config.lib.file.mkOutOfStoreSymlink "${dotfiles}/zshrc";
   #".zsh".source = 
   #  config.lib.file.mkOutOfStoreSymlink "${dotfiles}/zsh";
    #".zshrc".source = ../../zshrc;
    #".zshenv".source = "${dotfiles}/zshenv";
    #".zpath".source = "${dotfiles}/zpath";
    #".zprofile".source = "${dotfiles}/zprofile";
    #".p10k.zsh".source = "${dotfiles}/p10k.zsh";
    #".zsh".source = "${dotfiles}/zsh";
  };

}
