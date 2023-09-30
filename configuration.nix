# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running `nixos-help`).

{ config, lib, pkgs, ... }:

let
  i3statusbarconfig = pkgs.writeText "i3statusbar-config" ''
    [theme]
    theme = "gruvbox-dark"
    [icons.overrides]
    bat = [
        "| |",
        "|¼|",
        "|½|",
        "|¾|",
        "|X|",
    ]
    bat_charging = "|^|"
    [[block]]
    block = "battery"
    driver = "upower"
    empty_format = " $icon $percentage $time "
    format = " $icon $percentage $time "
    [[block]]
    block = "cpu"
    interval = 1
    [[block]]
    block = "uptime"
    [[block]]
    block = "sound"
    [[block]]
    block = "time"
    interval = 10
    format = "$timestamp.datetime()"
  '';

in {
  imports = [ # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./apple-silicon-support
  ];
  hardware.asahi.extractPeripheralFirmware = true;
  hardware.asahi.peripheralFirmwareDirectory = ./firmware;
  hardware.opengl.enable = true;
  programs.dconf.enable = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = false;
  hardware.asahi.pkgsSystem = "aarch64-linux";
  networking.hostName = "sentrynixos"; # Define your hostname.
  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.networkmanager.enable =
    true; # Easiest to use and most distros use this by default.
  nixpkgs.config.allowUnfree = true;

  # Set your time zone.
  # time.timeZone = "Europe/Amsterdam";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkbOptions in tty.
  # };

  # Enable the X11 windowing system.
  # services.xserver.enable = true;

  security.polkit.enable = true;
  security.sudo.extraConfig = ''
    Defaults        timestamp_timeout=300
  '';

  # Configure keymap in X11
  # services.xserver.layout = "us";
  # services.xserver.xkbOptions = "eurosign:e,caps:escape";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.kevin = {
    isNormalUser = true;
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
    packages = with pkgs; [ firefox tree ];
    shell = pkgs.zsh;
  };
  home-manager.users.kevin = { pkgs, ... }: {
    home.packages = with pkgs; [ chromium fuzzel wezterm nixfmt ];
    home.stateVersion = "23.11";
    wayland.windowManager.sway = {
      enable = true;
      systemd.enable = true;
      config = rec {
        # terminal = "wezterm";
        modifier = "Mod4";
        input = {
          "*" = {
            xkb_options = "caps:escape";
            repeat_delay = "180";
          };
        };
        output = { "*" = { scale = "2"; }; };
        bars = [{
          statusCommand =
            "${pkgs.i3status-rust}/bin/i3status-rs ${i3statusbarconfig}";
        }];
      };
    };
    home.shellAliases = {
      g = "git";
      "..." = "cd ../..";
      nxx = "sudo vi /etc/nixos/configuration.nix";
      nrb = "sudo nixos-rebuild switch --flake /etc/nixos/#";
    };
    # https://www.reddit.com/r/NixOS/comments/nxnswt/cant_change_themes_on_wayland/h1skv8w/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button
    # try to fix wezterm cursor issues
    gtk.enable = true;
    gtk.font.name = "Noto Sans";
    gtk.font.package = pkgs.noto-fonts;
    gtk.theme.name = "Dracula";
    gtk.theme.package = pkgs.dracula-theme;
    gtk.iconTheme.name = "Papirus-Dark-Maia"; # Candy and Tela also look good
    gtk.iconTheme.package = pkgs.papirus-maia-icon-theme;
    gtk.cursorTheme.name = "Capitaine Cursors";
    gtk.cursorTheme.package = pkgs.capitaine-cursors;
    gtk.gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = true;
      gtk-key-theme-name = "Emacs";
      gtk-icon-theme-name = "Papirus-Dark-Maia";
      gtk-cursor-theme-name = "capitaine-cursors";
    };
    dconf.settings = {
      "org/gnome/desktop/interface" = {
        gtk-key-theme = "Emacs";
        cursor-theme = "Capitaine Cursors";
      };
    };
    xdg.systemDirs.data = [
      "${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}"
      "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}"
    ];

    programs.zsh = {
      enable = true;
      oh-my-zsh = {
        enable = true;
        plugins = [ "git" "sudo" ];
        theme = "robbyrussell";
      };
    };

    home.sessionVariables = { XCURSOR_THEME = "Adwaita"; };

    programs.i3status-rust = { enable = true; };

    programs.vscode = { enable = true; };

    programs.neovim = {
      defaultEditor = true;
      enable = true;
      viAlias = true;
      vimAlias = true;

      plugins = with pkgs.vimPlugins; [
        nvim-lspconfig
        nvim-treesitter.withAllGrammars
        plenary-nvim
        gruvbox-material
        mini-nvim
        neoformat
      ];
    };

  };

  programs.zsh.enable = true;

  environment.loginShellInit = ''
    [[ "$(tty)" == /dev/tty1 ]] && sway
  '';

  # chromium wayland support, fixes high-dpi scaling
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    git
    bottom
  ];

  # services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    # Certain features, including CLI integration and system authentication support,
    # require enabling PolKit integration on some desktop environments (e.g. Plasma).
    polkitPolicyOwners = [ "kevin" ];
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?

}

