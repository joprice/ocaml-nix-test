resolve:
	nix-shell -A resolve ./default.nix

dep-graph:
	 nix-store -q --graph result
