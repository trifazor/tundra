# Tundra development

Never activate or install Tundra on the development host. Do not run nixos-rebuild
switch, boot, or test, change host boot settings, or copy host hardware config.
Runtime testing must happen inside a NixOS QEMU VM. Nix evaluation and building
VM artifacts on the host are allowed. Keep VM-only credentials in hosts/vm or tests.
Keep the base desktop minimal; personal apps belong in optional profiles.
