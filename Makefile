all:
	dune build

watch:
	./watch.sh

update: resolve
	direnv reload

resolve:
	nix-shell -A resolve ./default.nix

dep-graph:
	 nix-store -q --graph result
