# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      # Neovim setup lives in its own file, see neovim.nix
      ./neovim.nix
    ];

  ############################################################################
  # BOOTLOADER / KERNEL
  ############################################################################

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
  };

  ############################################################################
  # NETWORKING
  ############################################################################

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;
  networking.networkmanager.wifi.powersave = false;

  networking.firewall.allowedTCPPorts = [ 53 8384 22000 51821 8088 ];
  networking.firewall.allowedUDPPorts = [ 53 22000 21027 51820 ];

  ############################################################################
  # LOCALIZATION / TIME
  ############################################################################

  # Set your time zone.
  time.timeZone = "Europe/Kyiv";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "uk_UA.UTF-8";
    LC_IDENTIFICATION = "uk_UA.UTF-8";
    LC_MEASUREMENT = "uk_UA.UTF-8";
    LC_MONETARY = "uk_UA.UTF-8";
    LC_NAME = "uk_UA.UTF-8";
    LC_NUMERIC = "uk_UA.UTF-8";
    LC_PAPER = "uk_UA.UTF-8";
    LC_TELEPHONE = "uk_UA.UTF-8";
    LC_TIME = "uk_UA.UTF-8";
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  ############################################################################
  # NIX / NIX STORE
  ############################################################################

  nix.settings = {
    auto-optimise-store = true;
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    substituters = [
      "https://cache.nixos.org/"
      "https://nix-community.cachix.org"
    ];
    trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  ############################################################################
  # USERS
  ############################################################################

  # Define a user account. Don't forget to set a password with 'passwd'.
  users.users."fell" = {
    isNormalUser = true;
    description = "fell";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    shell = pkgs.fish;
    packages = with pkgs; [ ];
  };

  ############################################################################
  # SYSTEM PACKAGES
  ############################################################################

  environment.systemPackages = with pkgs; [
    git
    kitty
    fastfetch
    nh
    starship
    docker-compose
    mc
    btop
    cmatrix
    keepassxc
    kpcli

    # docker type shi
    dockerfile-language-server
    docker-compose-language-service
    yaml-language-server
  ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  ############################################################################
  # FISH SHELL
  ############################################################################

  programs.fish = {
    enable = true;
    shellAliases = {
      c = "clear";
      cls = "clear";
      updd = "sudo nixos-rebuild switch";
      upd = "nh os switch";
      dcu = "docker compose up -d --build";
      dca = "docker ps";
      dcd = "docker compose down";
      dcr = "docker rm";
      cfg = "sudo nano /etc/nixos/configuration.nix";
      ncfg = "sudo nvim /etc/nixos/configuration.nix";
      up = "uptime";
    };
    interactiveShellInit = ''
      function dc --description "Show Docker & System shortcuts"
        echo -e "\n\e[1;34mDocker & System Shortcuts:\e[0m"
        echo -e "  \e[32mdcu\e[0m   -> docker compose up -d --build"
        echo -e "  \e[32mdcd\e[0m   -> docker compose down"
        echo -e "  \e[32mdca\e[0m   -> docker ps"
        echo -e "  \e[32mdcr\e[0m   -> docker rm <container>"
        echo -e "\n\e[1;34mSystem Shortcuts:\e[0m"
        echo -e "  \e[32mc/cls\e[0m -> clear."
        echo -e "  \e[32mup\e[0m    -> uptime"
        echo -e "  \e[32mupd\e[0m   -> nh os switch"
        echo -e "  \e[32mupdd\e[0m  -> sudo nixos-rebuild switch"
        echo -e "  \e[32mncfg\e[0m   -> sudo nvim /etc/nixos/configuration.nix"
        echo -e "  \e[32mcfg\e[0m  -> sudo nano /etc/nixos/configuration.nix\n"
      end
    '';
  };

  ############################################################################
  # VIRTUALISATION / DOCKER
  ############################################################################

  virtualisation.docker.enable = true;

  ############################################################################
  # SERVICES
  ############################################################################

  services.openssh = {
    enable = true;
  };

  services.zerotierone = {
    enable = true;
    joinNetworks = [ "633e31d8a21e24ba" ];
  };

  services.syncthing = {
    enable = true;
    user = "fell";
    dataDir = "/home/fell/Sync";
    configDir = "/home/fell/.config/syncthing";
    guiAddress = "0.0.0.0:8384";
  };

  services.logind.settings.Login.HandleLidSwitch = "ignore";
  # services.logind.lidSwitch = "ignore";
  # services.logind.lidSwitchExternalPower = "ignore";

  ############################################################################
  # MISC (kept from the generated defaults, for reference)
  ############################################################################

  # List packages installed in system profile.
  # You can use https://search.nixos.org/ to find more packages (and options).
  # environment.systemPackages = with pkgs; [
  #   vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
  #   wget
  # ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  ############################################################################
  # STATE VERSION
  ############################################################################

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "26.05"; # Did you read the comment?

}
