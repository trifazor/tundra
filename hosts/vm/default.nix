{ modulesPath, ... }:
{
  imports = [ (modulesPath + "/virtualisation/qemu-vm.nix") ];
  networking.hostName = "tundra-vm";
  virtualisation = {
    memorySize = 4096;
    cores = 4;
    diskSize = 16384;
    graphics = true;
    # Niri needs a 3D-capable GPU; plain VirtIO produces a black screen.
    qemu.options = [
      "-vga none"
      "-device virtio-vga-gl"
      "-display gtk,gl=on"
    ];
  };
  # These credentials exist only in this disposable VM configuration.
  users.users.tundra = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
    ];
    initialPassword = "tundra";
  };
  time.timeZone = "UTC";
}
