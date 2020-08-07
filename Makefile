update-deps:
	"$(shell nix-build --no-out-link ./opam2nix.nix)/bin/opam2nix" resolve --ocaml-version 4.10.0 ./ocaml_nix.opam

resolve:
	nix-shell -A resolve

dep-graph:
	 nix-store -q --graph result
