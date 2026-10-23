{ lib, ... }:
{
  imports = [ ./machine.nix ];

  # Preserve the existing Plasma desktop as a fallback session in Dux Greeter.
  services.desktopManager.plasma6.enable = true;
  services.displayManager.sddm.enable = lib.mkForce false;
  services.greetd.enable = lib.mkForce true;
  services.displayManager.autoLogin.enable = lib.mkForce false;
  services.displayManager.defaultSession = lib.mkForce "niri";
}
