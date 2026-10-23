{ lib, pkgs, ... }:
{
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  networking.networkmanager.enable = true;
  programs.niri.enable = true;
  programs.dank-material-shell = {
    enable = true;
    systemd.enable = true;
    systemd.target = "niri.service";
    # Use Dux Calendar; the optional khal integration is unnecessary here.
    enableCalendarEvents = false;
  };
  programs.dms-greeter = {
    enable = true;
    compositor.name = "niri";
  };
  programs.dank-calendar = {
    enable = true;
    systemd.enable = true;
  };
  programs.dux-files = {
    enable = true;
    systemd.enable = true;
    portal = {
      enable = true;
      preferred = true;
      desktop = "niri";
    };
  };

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };
  security.rtkit.enable = true;
  security.polkit.enable = true;
  security.pam.services.dankshell = { };
  services.gnome.gnome-keyring.enable = true;
  services.udisks2.enable = true;
  services.gvfs.enable = true;
  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };
  xdg.mime.defaultApplications."inode/directory" = "dev.duxlabs.files.desktop";
  environment.etc."xdg/niri/config.kdl".source = ../config/niri.kdl;
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
  environment.systemPackages = with pkgs; [
    foot
    wl-clipboard
    xwayland-satellite
  ];
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-color-emoji
    nerd-fonts.jetbrains-mono
  ];
  services.displayManager.defaultSession = "niri";
  system.stateVersion = lib.mkDefault "26.05";
}
