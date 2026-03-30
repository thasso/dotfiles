{ pkgs, ... }: {
  # Flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Timezone & locale
  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "de_DE.UTF-8";
    LC_IDENTIFICATION = "de_DE.UTF-8";
    LC_MEASUREMENT = "de_DE.UTF-8";
    LC_MONETARY = "de_DE.UTF-8";
    LC_NAME = "de_DE.UTF-8";
    LC_NUMERIC = "de_DE.UTF-8";
    LC_PAPER = "de_DE.UTF-8";
    LC_TELEPHONE = "de_DE.UTF-8";
    LC_TIME = "de_DE.UTF-8";
  };

  # User
  users.users.thasso = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    shell = pkgs.zsh;
  };
  programs.zsh.enable = true;
  security.sudo.wheelNeedsPassword = false;

  # System packages — most user tools managed by Home Manager
  environment.systemPackages = with pkgs; [ zsh ];

  # SSH + firewall
  services.openssh.enable = true;
  networking.firewall.allowedTCPPorts = [ 22 ];
}
