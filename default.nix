{ pkgs ?
  import
    (fetchTarball {
      url = "https://github.com/NixOS/nixpkgs/archive/56ddb0a32acb6a93704384e5de93645eb1e66800.tar.gz";
      #sha256 = "";
    }) { }
}:

with pkgs;
let
  ssl = fetchFromGitHub {
    owner = "savonet";
    repo = "ocaml-ssl";
    rev = "fbffa9b";
    sha256 = "1zf6i4z5aq45in430pagp8cz2q65jdhsdpsgpcdysjm4jlfsswr1";
  };
  httpaf = fetchFromGitHub {
    owner = "anmonteiro";
    repo = "httpaf";
    rev = "dbeec79bf9922011162bd86b6aa1028cb6d4ffac";
    sha256 = "1qc8pg9zfp6chsal0dn66w9cmxyrma4c57vk0dlnb8brv34xxjhx";
  };
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
  #args2 = {
  #  inherit (ocaml-ng.ocamlPackages_4_10) ocaml;
  #  selection = ./opam-selection.nix;
  #  src = {
  #    inherit piaf;
  #    inherit lambda-runtime;
  #    #inherit lambda-runtime;
  #  };
  #};
  args = {
    inherit (ocaml-ng.ocamlPackages_4_10) ocaml;
    selection = ./opam-selection.nix;
    src = {
      inherit lambda-runtime;
      inherit piaf;
      inherit httpaf;
      inherit ssl;
      httpaf-lwt-unix = httpaf;
      httpaf-lwt = httpaf;
      ocaml_nix = ./.;
    };
  };
  resolve =
    opam2nix.resolve args [
      "${lambda-runtime}/lambda-runtime.opam"
      "${piaf}/piaf.opam"
      "${httpaf}/httpaf.opam"
      "${httpaf}/httpaf-lwt.opam"
      "${httpaf}/httpaf-lwt-unix.opam"
      "ocaml_nix.opam"
    ];
  selection = opam2nix.build args;
  #selection2 = opam2nix.build args2;
in
{
  inherit opam2nix resolve;
  inherit selection;
  inherit (selection) ocaml_nix;
  # selection selection2;
  #inherit (selection) ocaml_nix piaf lambda-runtime;
}
