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

sql:
	sqlite3 db.sqlite

dep-graph:
	 nix-store -q --graph result

websocket:
	  websocat ws://localhost:8080/websocket
