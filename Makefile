all:
	dune build

watch:
	./watch.sh

update: resolve
	direnv reload

resolve:
	nix-shell -A resolve ./default.nix

init-sqlite:
	sqlite3 db.sqlite < schema-sqlite.sql

sql:
	sqlite3 db.sqlite

dep-graph:
	 nix-store -q --graph result

websocket:
	  websocat ws://localhost:8080/websocket

init-postgres:
	docker-compose exec -T timescale psql -U test test < schema-postgres.sql

psql:
	 docker-compose exec timescale psql -U test test
