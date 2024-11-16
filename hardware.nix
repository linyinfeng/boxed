{
  config,
  pkgs,
  lib,
  modulesPath,
  ...
}:
{
  imports = [
    "${modulesPath}/profiles/all-hardware.nix"
  ];
  boot.loader.grub.enable = false;
  boot.loader.efi.canTouchEfiVariables = false;
  boot.loader.systemd-boot = {
    enable = true;
    edk2-uefi-shell.enable = true;
    memtest86.enable = true;
    netbootxyz.enable = true;
  };
  disko.imageBuilder = {
    imageFormat = "qcow2";
  };
  disko.devices = {
    nodev = {
      "/" = {
        fsType = "tmpfs";
        mountOptions = [
          "defaults"
          "size=25%"
          "mode=755"
        ];
      };
    };
    disk.boxed = {
      imageName = "boxed-${pkgs.stdenv.hostPlatform.system}";
      imageSize = "5G";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          esp = {
            priority = 0;
            size = "256M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [
                "dmask=077"
                "fmask=177"
              ];
            };
          };
          main = {
            priority = 100;
            size = "100%";
            content = {
              type = "btrfs";
              subvolumes =
                let
                  mountOptions = [
                    "x-systemd.growfs"
                    "compress=zstd"
                  ];
                in
                {
                  "@nix" = {
                    mountpoint = "/nix";
                    inherit mountOptions;
                  };
                  "@boxed" = {
                    mountpoint = "/var/lib/boxed";
                    inherit mountOptions;
                  };
                  "@log" = {
                    mountpoint = "/var/log";
                    inherit mountOptions;
                  };
                };
            };
          };
        };
      };
    };
  };
  system.build.writeImage = pkgs.writeShellApplication {
    name = "write-image";
    runtimeInputs = with pkgs; [ qemu ];
    text = ''
      exec qemu-img dd -f qcow2 -O raw \
        if="${config.system.build.diskoImages}/${config.disko.devices.disk.boxed.imageName}.${config.disko.imageBuilder.imageFormat}" \
        "$@"
    '';
  };
}
