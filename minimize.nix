{ modulesPath, ... }:
{
  imports = [
    "${modulesPath}/profiles/minimal.nix"
  ];
  config = {
    boot.initrd.systemd.enable = true;
    # system.etc.overlay = {
    #   enable = true;
    #   mutable = false;
    # };
    services.userborn.enable = true;
    users.mutableUsers = false;
    users.allowNoPasswordLogin = true;
    system.disableInstallerTools = true;
    boot.enableContainers = false;
    documentation.enable = false;
    environment.defaultPackages = [ ];
    nix.enable = false;
  };
}
