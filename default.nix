{ pkgs ?
  import
    (fetchTarball {
      url = "https://github.com/NixOS/nixpkgs/archive/56ddb0a32acb6a93704384e5de93645eb1e66800.tar.gz";
      #sha256 = "";
    }) { }
}:

with pkgs;
let
  piaf = fetchFromGitHub {
    owner = "anmonteiro";
    repo = "piaf";
    rev = "10c2842cb3b1fcef9b4c459265136c576a278d0c";
    sha256 = "0j9n7lymsbx38jb9lwk51p2kxq95m49rzvcr1dk5hkav7qkdqn4z";
  };
  lambda-runtime = fetchFromGitHub {
    owner = "anmonteiro";
    repo = "aws-lambda-ocaml-runtime";
    rev = "148027b";
    sha256 = "1m0aph410c4c2j9516gy5r2waj85v3181dps854vv1820zr6si0b";
  };
  opam2nix = import ./opam2nix.nix { };
  args = {
    inherit (ocaml-ng.ocamlPackages_4_10) ocaml;
    selection = ./opam-selection.nix;
    src = {
      inherit lambda-runtime;
      inherit piaf;
      ocaml_nix = ./.;
    };
  };
  resolve = opam2nix.resolve args [
    "${lambda-runtime}/lambda-runtime.opam"
    "${piaf}/piaf.opam"
    "ocaml_nix.opam"
  ];
  opam-selection = opam2nix.build args;
in
{
  inherit piaf lambda-runtime opam2nix resolve;
  inherit (opam-selection) ocaml_nix;
}
