{
  config,
  pkgs,
  lib,
  ...
}:

let
  runBox = pkgs.writeShellApplication {
    name = "run-box";
    runtimeInputs = with pkgs; [
      coreutils
      qemu
      gawk
    ];
    text = ''
      memory_size=$(awk '/MemTotal/ { printf "%d\n", $2 / 1024 - ${toString reservedMemoryMegs} }' /proc/meminfo)

      qemu-kvm \
        ${lib.escapeShellArgs qemuArgs} \
        -m "$memory_size" \
        -smp "$(nproc)" \
        "$@"

      systemctl poweroff
    '';
  };
  driveFile = "${config.users.users.boxed.home}/box.qcow2";
  ovmf = "${pkgs.OVMFFull.fd}/FV";
  reservedMemoryMegs = 256;
  qemuArgs = [
    "-name"
    "box"
    "-machine"
    "q35"
    "-cpu"
    "max"
    "-drive"
    "if=pflash,format=raw,file=${ovmf}/OVMF_CODE.fd,readonly=on"
    "-drive"
    "if=pflash,format=raw,file=${config.users.users.boxed.home}/ovmf/OVMF_VARS.fd"
    "-drive"
    "file=${driveFile}"
    "-display"
    "gtk"
  ];
in
{
  users.users.boxed = {
    isNormalUser = true;
    home = "/var/lib/boxed";
    createHome = true;
    useDefaultShell = true;
    group = "boxed";
    extraGroups = [ "kvm" ];
  };
  users.groups.boxed = { };
  services.cage = {
    enable = true;
    user = "boxed";
    environment = {
      WLR_RENDERER_ALLOW_SOFTWARE = "1";
    };
    extraArguments = [
      "-d" # no client side decorations
      "-m"
      "last" # multi-monitor behavior
    ];
    program = lib.getExe runBox;
  };
  systemd.tmpfiles.settings."50-boxed" = {
    ${config.users.users.boxed.home} = {
      Z = {
        user = "boxed";
        group = "boxed";
      };
    };
    "${config.users.users.boxed.home}/ovmf" = {
      d = {
        user = "boxed";
        group = "boxed";
        mode = "0700";
      };
    };
    "${config.users.users.boxed.home}/ovmf/OVMF_VARS.fd" = {
      C = {
        user = "boxed";
        group = "boxed";
        mode = "0600";
        argument = "${ovmf}/OVMF_VARS.fd";
      };
    };
  };
}
