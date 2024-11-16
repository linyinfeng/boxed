{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs =
    {
      self,
      nixpkgs,
      disko,
    }:
    let
      inherit (nixpkgs) lib;
    in
    {
      nixosConfigurations.boxed = lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          disko.nixosModules.disko
          ./minimize.nix
          ./cage.nix
          ./hardware.nix
          # we do not have any state
          { system.stateVersion = lib.trivial.release; }
        ];
      };
    };
}
