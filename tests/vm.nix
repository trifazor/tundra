{
  pkgs,
  tundraModule,
  graphical ? false,
}:
pkgs.testers.runNixOSTest {
  name = if graphical then "tundra-greeter" else "tundra-smoke";
  enableOCR = graphical;
  extraPythonPackages = ps: pkgs.lib.optionals graphical [ ps.pillow ];
  nodes.machine = {
    imports = [ tundraModule ];
    virtualisation.memorySize = 4096;
    virtualisation.qemu = pkgs.lib.mkIf graphical {
      package = pkgs.lib.mkForce pkgs.qemu_kvm;
      options = [
        "-vga none"
        "-device virtio-vga-gl"
        "-display egl-headless"
      ];
    };
    users.users.tundra = {
      isNormalUser = true;
      password = "tundra";
    };
  };
  testScript = ''
    machine.start()
    machine.wait_for_unit("multi-user.target")
    machine.wait_for_unit("greetd.service")
    machine.succeed("niri validate --config /etc/xdg/niri/config.kdl")
    machine.succeed("for app in dms dfiles dcal foot; do command -v $app || exit 1; done")
    machine.succeed("grep -q dfiles /etc/xdg/xdg-desktop-portal/niri-portals.conf")
    machine.succeed("systemctl is-active NetworkManager.service")
  ''
  + pkgs.lib.optionalString graphical ''
    import subprocess
    from PIL import Image, ImageOps
    from pathlib import Path

    # QEMU's GL display cannot be captured with the driver's PPM screendump.
    # Capture through Niri inside the guest, then OCR the actual rendered image.
    capture = "runuser -u greeter -- env XDG_RUNTIME_DIR=/run/user/$(id -u greeter) sh -c 'export NIRI_SOCKET=$(echo $XDG_RUNTIME_DIR/niri.*.sock); niri msg action screenshot-screen --path /tmp/greeter.png'"
    import datetime

    def greeter_visible(_last_attempt):
        status, _output = machine.execute(capture)
        if status != 0:
            return False
        machine.copy_from_machine("/tmp/greeter.png")
        screenshot = Path(machine.out_dir) / "greeter.png"
        with Image.open(screenshot) as image:
            width, height = image.size
            label = image.crop((int(width * 0.30), int(height * 0.43), int(width * 0.70), int(height * 0.56)))
            label = ImageOps.invert(label.convert("RGB")).resize((label.width * 3, label.height * 3))
            label_path = Path(machine.out_dir) / "greeter-label.png"
            label.save(label_path)
        text = subprocess.check_output(["tesseract", str(label_path), "stdout", "--psm", "6"], text=True)
        print(f"Greeter selector OCR: {text}")
        return "select user" in text.lower()

    retry(greeter_visible, timeout=datetime.timedelta(seconds=90))
  '';
}
