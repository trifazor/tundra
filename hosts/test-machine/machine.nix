# Replace this placeholder ON THE PHYSICAL TEST MACHINE after reviewing its
# existing configuration. See docs/test-machine.md. Never copy development-host
# hardware or VM credentials here.
{
  assertions = [
    {
      assertion = false;
      message = ''
        Tundra test-machine is not configured yet. Replace
        hosts/test-machine/machine.nix with an import of this test machine's
        existing NixOS configuration, as described in docs/test-machine.md.
      '';
    }
  ];
}
