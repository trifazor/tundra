{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.tundra.apps;
in
{
  options.tundra.apps = {
    development.enable = lib.mkEnableOption "development apps";
    creative.enable = lib.mkEnableOption "creative apps";
    productivity.enable = lib.mkEnableOption "productivity apps";
    communication.enable = lib.mkEnableOption "communication apps";
    browser.enable = lib.mkEnableOption "Firefox";
    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "Additional system apps; unfree apps require nixpkgs.config.allowUnfree.";
    };
  };
  config = {
    programs.firefox.enable = lib.mkIf cfg.browser.enable true;
    environment.systemPackages =
      cfg.extraPackages
      ++ lib.optionals cfg.development.enable (
        with pkgs;
        [
          git
          helix
          zellij
          nil
          nixd
          jq
          ripgrep
          bat
          fd
          jujutsu
          direnv
        ]
      )
      ++ lib.optionals cfg.creative.enable (
        with pkgs;
        [
          inkscape
          krita
          kdePackages.kdenlive
        ]
      )
      ++ lib.optionals cfg.productivity.enable (
        with pkgs;
        [
          yazi
          sioyek
          onlyoffice-desktopeditors
        ]
      )
      ++ lib.optionals cfg.communication.enable (
        with pkgs;
        [
          signal-desktop
          vesktop
        ]
      );
  };
}
