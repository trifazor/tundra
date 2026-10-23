# Optional selection drawn from ~/purrfact. Import alongside the Tundra module.
{ pkgs, ... }:
{
  tundra.apps = {
    development.enable = true;
    creative.enable = true;
    productivity.enable = true;
    communication.enable = true;
    browser.enable = true;
    extraPackages = with pkgs; [
      unzip
      zip
      evtest
    ];
  };
}
