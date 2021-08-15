{}:
let
  pkgsBase =
    import <nixpkgs> {
      #overlays = [
      #  (
      #    self: super: {
      #      sqlite = super.sqlite.override {
      #        interactive = true;
      #      };
      #    }
      #  )
      #];
    };
  pkgs = pkgsBase // {
    sqlite = pkgsBase.sqlite.override {
      interactive = true;
    };
  };
in
pkgs.callPackage ./nix {}
