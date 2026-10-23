# Tundra

A minimal NixOS desktop built around **Niri** and **Dux Shell 2.0**, with Dux
Greeter, Files, Calendar, and the Foot terminal. Additional apps are optional.

Early development · x86_64 Linux · Nixpkgs unstable · Physical hardware testing
is in progress.

## Install

Start with a working NixOS installation. For a fresh machine, install NixOS
first using the [official installation guide](https://nixos.org/manual/nixos/stable/#sec-installation),
create your user, and boot into it. Tundra reuses that configuration and adds no KDE fallback; the previous
NixOS generation is your fallback. It currently ships as a configuration, without an installer ISO.

Run these steps **on the machine where you want to install Tundra**. The pinned
Nixpkgs unstable version may upgrade your system beyond its current release.

1. Back up your configuration, then clone the repository:

   ```sh
   sudo cp -a /etc/nixos /etc/nixos.before-tundra
   nix-shell -p git
   git clone https://github.com/trifazor/tundra.git
   cd tundra
   ```

   Keep the temporary Git shell open for the remaining steps.

2. Import your machine's existing configuration:

   ```sh
   mkdir -p hosts/test-machine/existing
   cp -a /etc/nixos/. hosts/test-machine/existing/
   cat > hosts/test-machine/machine.nix <<'EOF'
   {
     imports = [ ./existing/configuration.nix ];
   }
   EOF
   ```

   Keep your bootloader, disk mounts, GPU settings, users, and `system.stateVersion`.
   This assumes the standard `configuration.nix` importing `hardware-configuration.nix`;
   custom flake setups need their imports adapted.

3. Review the copied files and stage them locally so Nix can read them:

   ```sh
   git add hosts/test-machine/machine.nix
   git add -f hosts/test-machine/existing/configuration.nix \
     hosts/test-machine/existing/hardware-configuration.nix
   ```

   Stage any additional imported files too. Keep secrets out of the repository
   and Nix store. No commit or push is needed for your local machine settings.

4. Build, then prepare the next boot only after the build succeeds:

   ```sh
   nix --extra-experimental-features 'nix-command flakes' build \
     .#nixosConfigurations.tundra-test.config.system.build.toplevel -L
   sudo nixos-rebuild boot --flake .#tundra-test
   ```

5. Reboot into the new generation. Select **Niri** in Dux Greeter and log in with
   your existing account and password.

If boot or login fails, select the previous NixOS generation from the boot menu.
Keep that generation until testing is complete. For future updates, rebuild from
this checkout with `--flake .#tundra-test`.

See [the machine setup guide](docs/test-machine.md) for more detail and hardware checks.

## Optional apps

Add settings to `hosts/test-machine/machine.nix` alongside its imports:

```nix
  tundra.apps.development.enable = true;
  tundra.apps.browser.enable = true;
```

Other groups are `creative`, `productivity`, and `communication`.
Use `tundra.apps.extraPackages` for your own package selection.

## Try it in a VM

Preview Tundra without replacing your installed system. Requires Nix with flakes,
a graphical session with working OpenGL, and around 4 GiB of guest RAM:

```sh
nix build .#vm
./result/bin/run-tundra-vm-vm
```

Log in with **tundra / tundra**. The VM keeps its data in `tundra-vm.qcow2`;
shut it down before deleting that file to reset it. Building downloads dependencies
into your Nix store but does not activate Tundra on the host.

## Shortcuts

| Shortcut | Action |
| --- | --- |
| Super + Return | Terminal |
| Super + Space | App launcher |
| Super + E | Files |
| Super + C | Calendar |
| Super + L | Lock |
| Super + Q | Close window |
| Super + arrows | Navigate windows |
| Super + O | Overview |

## Development

Desktop settings live in `modules/`, Niri defaults in `config/niri.kdl`, and
machine profiles in `hosts/`. Dependencies are pinned in `flake.lock`.

Run the VM smoke test with `nix build .#checks.x86_64-linux.vm-smoke -L`.
For the graphical greeter test, build `.#vm-greeter-test` and run
`./result/bin/nixos-test-driver --no-interactive -o /tmp/tundra-greeter-test`.
All development runtime testing takes place in VMs.
