{
  description = "Standalone source and Nix package for finder-favorites";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      system = "aarch64-darwin";
      pkgs = import nixpkgs { inherit system; };
      package = pkgs.callPackage ./package.nix { };
    in
    {
      packages.${system}.default = package;
      checks.${system}.package = package;
      devShells.${system}.default = pkgs.mkShellNoCC {
        packages = with pkgs; [
          clang-tools
          deadnix
          jq
          nixf-diagnose
          nixfmt
          periphery
          prettier
          rumdl
          shellcheck
          shfmt
          statix
          swift-format
          swiftlint
          typos
          yamlfmt
          yamllint
        ];
      };
    };
}
