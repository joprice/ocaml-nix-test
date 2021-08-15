all:
	dune build

watch:
	./watch.sh

update: resolve
	direnv reload

resolve:
	nix-shell -A resolve ./default.nix

init-sqlite:
	sqlite3 db.sqlite < schema.sql

dep-graph:
	 nix-store -q --graph result
