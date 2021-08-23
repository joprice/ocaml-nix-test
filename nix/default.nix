{ pkgs }:

with pkgs;
let
  ocamlPackages = ocaml-ng.ocamlPackages_4_12.overrideScope' (
    self: super: {
      ocaml = super.ocaml.override {
        flambdaSupport = true;
      };
    }
  );
  ocaml = ocamlPackages.ocaml;
  opam2nix = import ./opam2nix.nix {
    ocamlPackagesOverride = ocamlPackages;
  };
  args = {
    inherit ocaml;
    selection = ./opam-selection.nix;
    src = {
      ocaml_nix = ../.;
    };
    override = {}: {
      conf-sqlite3 = super: super.overrideAttrs (
        super: {
          buildInputs = [ pkgs.sqliteInteractive ];
        }
      );
    };
  };
  resolve = opam2nix.resolve args [
    "ocaml_nix.opam"
  ];
  selection = opam2nix.build args;
in
{
  inherit opam2nix pkgs resolve;
  inherit (ocamlPackages) merlin;
  inherit (selection) ocaml_nix;
}
