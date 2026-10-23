{ lib, ... }:
{
  imports = [ ./machine.nix ];

  services.displayManager.sddm.enable = lib.mkForce false;
  services.greetd.enable = lib.mkForce true;
  services.displayManager.autoLogin.enable = lib.mkForce false;
  services.displayManager.defaultSession = lib.mkForce "niri";
}
