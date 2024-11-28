{
  description = "Eio";
  inputs = {
    opam-nix.url = "github:tweag/opam-nix";
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs";
  };
  outputs = { self, flake-utils, opam-nix, nixpkgs }@inputs:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        on = opam-nix.lib.${system};
        localPackagesQuery = builtins.mapAttrs (_: pkgs.lib.last)
          (on.listRepo (on.makeOpamRepo ./.));
        devPackagesQuery = {
          ocaml-lsp-server = "*";
          ocamlformat = "*";
          alcotest = "*";
          crowbar = "*";
          dscheck = "*";
          kcas = "*";
          logs = "*";
          mdx = "*";
        };
        query = devPackagesQuery // { };
        scope = on.buildOpamProject' { } ./. query;
        overlay = final: prev: { };
        scope' = scope.overrideScope' overlay;
        devPackages = builtins.attrValues
          (pkgs.lib.getAttrs (builtins.attrNames devPackagesQuery) scope');
        packages =
          pkgs.lib.getAttrs (builtins.attrNames localPackagesQuery) scope';
      in
      {
        legacyPackages = scope';

        packages = packages // {
          default = packages.eio;
        };

        devShells.default = pkgs.mkShell {
          inputsFrom = builtins.attrValues packages;
          buildInputs = devPackages;
        };
      });
}
