# Tundra

A small NixOS derivative starting with Niri and Dux Shell 2.0. The base includes
Dux Greeter, Files (including file chooser dialogs), Calendar, a Foot terminal,
audio, networking, portals, and a keyring. Personal apps are opt-in.

This is an initial development configuration, not a tested installer or a
production release. Only x86_64-linux is configured initially.

## Safety

**Do not activate this configuration on the development host.** All runtime tests
belong in a NixOS QEMU VM. No host hardware configuration is imported. The only
ready-to-run machine is `tundra-vm`. The `tundra-test` physical-machine profile
requires the test machine's existing configuration before it can build; see
[the physical-machine guide](docs/test-machine.md).

## Install on a fresh NixOS system

Tundra currently installs as a NixOS configuration, not a standalone ISO. Start
with a working **x86_64 NixOS installation** on the target machine. For a new
machine, follow the [official NixOS installation guide](https://nixos.org/manual/nixos/stable/#sec-installation)
first, choose Plasma/KDE as the initial desktop, create your own user and
password, and boot into that installation. This gives you a working fallback.

Run the following **on that target machine**, not on the development host.
You need internet access and enough disk space for the initial build. Tundra
pins Nixpkgs unstable, so applying it can upgrade the whole system beyond the
release you initially installed. Hardware validation is still in progress.

1. Back up the installed configuration and record its current boot generation:

   ```sh
   sudo cp -a /etc/nixos /etc/nixos.before-tundra
   sudo nix-env --list-generations -p /nix/var/nix/profiles/system
   ```

2. Open a temporary shell with Git, clone Tundra, and copy the target's own
   configuration. Keep this shell open for the remaining steps:

   ```sh
   nix-shell -p git
   git clone https://github.com/trifazor/tundra.git
   cd tundra
   mkdir -p hosts/test-machine/existing
   cp -a /etc/nixos/. hosts/test-machine/existing/
   ```

3. Replace the guarded placeholder with an import of the installed system:

   ```sh
   cat > hosts/test-machine/machine.nix <<'EOF'
   {
     imports = [ ./existing/configuration.nix ];
   }
   EOF
   ```

   The standard installer configuration imports `hardware-configuration.nix`.
   Preserve its bootloader, disks, encryption, GPU settings, user account, and
   `system.stateVersion`. Do not substitute the VM configuration or the
   development machine's hardware configuration. The VM password does not
   apply to physical installations.

4. Review the copied files before adding them to Git. Keep private keys and
   other secrets out of the checkout and Nix store. Stage the required Nix files
   locally so the flake can see them:

   ```sh
   git add hosts/test-machine/machine.nix
   git add -f hosts/test-machine/existing/configuration.nix \
     hosts/test-machine/existing/hardware-configuration.nix
   ```

   The `existing` directory is ignored by default; `-f` deliberately includes
   these reviewed files in the local flake. No commit or push is required.
   If your configuration imports more files, review and stage those too. Avoid
   pushing these local machine changes to the shared project repository.

5. Build first, then prepare a boot generation without changing your running
   desktop:

   ```sh
   nix --extra-experimental-features 'nix-command flakes' build \
     .#nixosConfigurations.tundra-test.config.system.build.toplevel -L
   sudo nixos-rebuild boot --flake .#tundra-test
   ```

   Run the second command only after the build succeeds. Reboot when ready,
   choose the new NixOS generation, and select your user and **Niri** in Dux
   Greeter. Use the password created during the NixOS installation.

Plasma remains available in the greeter's session selector. If the greeter or
boot fails, reboot into the previous NixOS generation from the boot menu. Keep
that generation and `/etc/nixos.before-tundra` until hardware testing is complete.
See [the physical-machine guide](docs/test-machine.md) for further validation,
optional apps, and configuration details. Continue managing Tundra from this
checkout with `--flake .#tundra-test`; plain `nixos-rebuild` still uses the old
`/etc/nixos` configuration.

## Run the VM

```sh
nix build .#vm
./result/bin/run-tundra-vm-vm
```

The graphical VM uses 4 GiB RAM, four CPUs, and a persistent local QCOW2 disk.
Log in through Dux Greeter with username `tundra` and password `tundra`.
These credentials are for the VM only. Shut down the guest normally; delete its
`tundra-vm.qcow2` disk when you want a fresh guest. QEMU needs a graphical host
session with working host OpenGL; KVM access is recommended. The VM uses a
VirGL GPU and GTK with OpenGL enabled. Plain `-vga virtio` leaves Niri with a
black screen because it does not provide the required 3D acceleration. Close
an already-running VM and relaunch after rebuilding to use the new GPU options;
the existing guest disk can be kept.

Run the automated NixOS VM smoke test:

```sh
nix build .#checks.x86_64-linux.vm-smoke -L
```

It boots a disposable guest, checks greetd and NetworkManager, validates the Niri
configuration, and checks the Dux commands and portal configuration. This does
not establish that a graphical login or every app works.

Check that the greeter actually renders in a GPU-enabled NixOS VM:

```sh
nix build .#vm-greeter-test -o result-test-driver
./result-test-driver/bin/nixos-test-driver --no-interactive -o /tmp/tundra-greeter-test
```

This runs QEMU with VirGL and EGL, captures the screen through Niri inside the
guest, and requires OCR to find the user selector. It needs access to the host's
`/dev/dri` render device, so run the driver as your normal desktop user outside
the Nix build sandbox. The output directory contains `greeter.png`.

## Configuration

- `modules/desktop.nix`: minimal shared desktop and Dux integration.
- `modules/apps.nix`: optional app groups and `tundra.apps.extraPackages`.
- `profiles/personal.nix`: optional app selection drawn from `~/purrfact`.
- `hosts/vm/default.nix`: VM hardware, test user, and VM-only password.
- `hosts/test-machine/default.nix`: physical test profile with Plasma fallback.
- `hosts/test-machine/machine.nix`: guarded placeholder for the actual machine.
- `config/niri.kdl`: system keyboard shortcuts and layout defaults.
- `tests/vm.nix`: NixOS VM smoke test.

To try personal apps, add `../../profiles/personal.nix` to the imports in
`hosts/vm/default.nix`, then rebuild the VM artifact. App groups can also be
selected individually, for example:

```nix
{
  tundra.apps.development.enable = true;
  tundra.apps.browser.enable = true;
  tundra.apps.extraPackages = with pkgs; [ kitty ];
}
```

Unfree apps from purrfact (such as Obsidian, VS Code, Brave, and Vivaldi) can be
added explicitly with the appropriate Nixpkgs unfree policy. Gaming, Ollama,
Plasma, printing, Flatpak, and personal accounts are not part of the base.
Zen's separate flake is not included in this initial foundation.

Shortcuts: Super+Return terminal, Super+Space launcher, Super+E Files,
Super+C Calendar, Super+L lock, Super+Q close, Super+arrows navigate,
Super+PageUp/PageDown workspaces, Super+O overview, Super+Shift+E exit.

## Upstream

[Dux Shell v2.0.0](https://github.com/duxlabs-dev/dux-shell/releases/tag/v2.0.0)
is pinned by release tag. [Greeter](https://github.com/duxlabs-dev/dux-greeter),
[Files](https://github.com/duxlabs-dev/dux-files), and
[Calendar](https://github.com/duxlabs-dev/dux-calendar) are pinned to exact
revisions in `flake.lock`. Nixpkgs unstable supplies the recent Go/Qt toolchain
required by Dux 2.0. Update dependencies deliberately with `nix flake update`.
Upstream still uses `dms`, `dms-greeter`, `dfiles`, and `dcal` commands and some
`dank-*` Nix module names after the rebrand.

Zotero is currently omitted from the optional productivity group because the
pinned Nixpkgs package depends on an end-of-life Firefox ESR and evaluation
rejects it. No insecure-package exception is enabled.

Dux Shell's optional khal calendar integration is disabled: Dux Calendar is
installed instead, and the pinned khal package currently fails to produce its
manual output during the build.

## Validation

Initial validation on 2026-10-23: `nix build .#vm` succeeded and the
`checks.x86_64-linux.vm-smoke` NixOS QEMU test passed. The optional personal
profile also evaluated successfully. After fixing the VM GPU to use VirGL,
the GPU-enabled NixOS VM test captured the rendered Dux Greeter and passed its
OCR check for the user selector. Authentication and an interactive Dux desktop
session were subsequently confirmed manually by the user in the VM, including
opening Files and Calendar. Physical hardware testing remains pending. The
development host was not activated.
