let
  default = (import ./default.nix {});
  pkgs = default.pkgs;
  inputs = (
    drv: (drv.buildInputs or []) ++ (drv.propagatedBuildInputs or [])
  );
in
pkgs.stdenv.mkDerivation {
  name = "ocaml_nix-shell";
  buildInputs = [
    default.merlin
  ] ++ (inputs default.ocaml_nix);
}
