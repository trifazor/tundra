# Physical test machine

The `tundra-test` flake configuration adds Tundra to an existing x86_64 NixOS
machine. It retains Plasma as a fallback session, uses Dux Greeter instead of
SDDM, and disables automatic login. It creates no users and supplies no password.
The checked-in placeholder deliberately prevents building until you supply the
actual machine configuration.

The steps below are for the physical test machine, not the development host.
No reinstall, partitioning, or formatting is involved.

## Prepare on the test machine

1. Clone `https://github.com/trifazor/tundra.git` on the test machine. Keep the
   existing `/etc/nixos` configuration and working boot generation intact.
2. Make a backup of `/etc/nixos` outside this checkout. Record the current
   generation with `sudo nix-env --list-generations -p /nix/var/nix/profiles/system`.
3. Copy the existing configuration into the checkout:

   ```sh
   mkdir -p hosts/test-machine/existing
   cp -a /etc/nixos/. hosts/test-machine/existing/
   ```

4. Replace `hosts/test-machine/machine.nix` with:

   ```nix
   {
     imports = [ ./existing/configuration.nix ];
   }
   ```

   This assumes the standard vanilla NixOS `configuration.nix`, which imports
   `hardware-configuration.nix`. If the existing setup uses a flake or additional
   modules, adapt the imports and required inputs before continuing. Do not
   import the old `flake.nix` as a NixOS module.

5. Review the copied files. Preserve the existing `system.stateVersion`,
   bootloader, root/boot mounts, encryption setup, GPU settings, hostname, users,
   and account credentials. Preserve paths to secrets using the machine's
   existing secret management; do not put private keys, plaintext passwords, or
   other secrets in the repository or Nix store. Absolute imports of Nix files
   outside this checkout need to be brought into the configuration deliberately.
6. Git-backed flakes only include tracked files. After reviewing the copied
   configuration, stage the required Nix files and any non-secret referenced
   files explicitly. For the usual two-file vanilla setup:

   ```sh
   git add hosts/test-machine/machine.nix
   git add -f hosts/test-machine/existing/configuration.nix \
     hosts/test-machine/existing/hardware-configuration.nix
   ```

   The `existing` directory is ignored by default to keep local machine files
   out of the shared repository. `-f` includes the reviewed files in the local
   flake. Add other imported files individually as needed. You do not need to
   commit or push these machine-specific changes to test them locally.

Optional personal apps can be enabled by also importing
`../../profiles/personal.nix` in `hosts/test-machine/default.nix`.

## Build and first boot

On the physical test machine, build without activating anything:

```sh
nix --extra-experimental-features 'nix-command flakes' build \
  .#nixosConfigurations.tundra-test.config.system.build.toplevel -L
```

Resolve evaluation and build failures before proceeding. The pinned Nixpkgs is
unstable, so this may upgrade more than the desktop compared with the machine's
current NixOS release. Review the resulting change before booting it.

When ready, install a boot generation without changing the running session:

```sh
sudo nixos-rebuild boot --flake .#tundra-test
```

Reboot and select the new generation. In Dux Greeter, select your existing user
and the Niri session. Your existing password remains in use; the VM's
`tundra`/`tundra` credentials do not apply. Plasma remains available in the
session selector. Do not delete older generations or run garbage collection
until the machine has passed validation.

## Validate and recover

Check login, shell startup, Files, Calendar, audio, networking, Bluetooth if
present, locking/unlocking, logout, reboot, suspend/resume, and external displays
if used. Note whether slow startup occurs only on the first login or every time.
GPU-specific problems may require adjustments to the existing machine settings.

If Niri fails but the greeter works, choose Plasma. If the greeter or boot fails,
reboot and select the previously working NixOS generation from the boot menu.
Keep the original `/etc/nixos` backup so the original configuration can be rebuilt.

After reliable hardware testing, Plasma can be removed from this machine profile.
No physical-machine activation has been performed by the development workflow.
