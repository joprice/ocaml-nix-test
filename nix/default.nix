{ pkgs }:

with pkgs;
let
  ocamlPackages = ocaml-ng.ocamlPackages_4_12;
  ocaml = ocamlPackages.ocaml;
  opam2nix = import ./opam2nix.nix {
    ocamlPackagesOverride = ocamlPackages;
  };
  args = {
    inherit ocaml;
    selection = ./opam-selection.nix;
    src = {
      ocaml_nix = ../.;
      inherit gen_js_api;
      ojs = gen_js_api;
    };
    override = {}: {
      conf-sqlite3 = super: super.overrideAttrs (
        super: {
          buildInputs = [ pkgs.sqliteInteractive ];
        }
      );
      ocaml_nix = super: super.overrideAttrs (
        super: {
          buildInputs = (super.buildInputs or []) ++ [
            selection.gen_js_api
          ];
        }
      );
    };
  };
  gen_js_api = fetchFromGitHub {
    owner = "LexiFi";
    repo = "gen_js_api";
    rev = "e887631577170df74237618d27336dc9c73f8c21";
    sha256 = "1srpl39cs3vram7p0l0vdyhjxcvg7v61j027i05yzcri91c8yrrl";
  };
  #ocamlfind = super: import ./ocamlfind { inherit pkgs super selection; };
  resolve = opam2nix.resolve args [
    "ocaml_nix.opam"
    "${gen_js_api}/gen_js_api.opam"
    "${gen_js_api}/ojs.opam"
  ];
  selection = opam2nix.build args;
in
{
  inherit opam2nix pkgs resolve
    ;
  inherit (ocamlPackages) merlin;
  inherit (selection) ocaml_nix;
}
