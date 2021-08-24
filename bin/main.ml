open Lwt.Syntax

type error = {
  code : int;
  message : string;
  debug_info : string option;
}
[@@deriving yojson]

let html_to_string html = Format.asprintf "%a" (Tyxml.Html.pp ()) html

let development = true

(* 256-bit key for secret in prod
   "A medium-sized Web app serving 1000 fresh encrypted cookies per second should rotate keys about once a year"
   use old_secrets for key rotation
*)
(* let () = print_endline @@ Dream.to_base64url (Dream.random 32) *)

let ty_html_error_template debug_info suggested_response =
  let status = Dream.status suggested_response in
  let code = Dream.status_to_int status in
  let reason = Dream.status_to_string status in
  let debug_info = debug_info |> Option.value ~default:"" in
  suggested_response
  |> Dream.with_header "Content-Type" Dream.text_html
  |> Dream.with_body
       (let open Tyxml in
       html_to_string
         [%html
           {|
    <html>
      <head>
        <title>page</title>
      </head>
      <body><h1>|}
             [ Html.txt (Int.to_string code ^ " " ^ reason) ]
             {|</h1>
        <pre>|}
             [ Html.txt debug_info ]
             {|
         </pre>
      </body>
    </html>
|}])
  |> Lwt.return

let html_error_template debug_info suggested_response =
  let status = Dream.status suggested_response in
  let code = Dream.status_to_int status in
  let reason = Dream.status_to_string status in
  let debug_info = debug_info |> Option.value ~default:"" in
  suggested_response
  |> Dream.with_header "Content-Type" Dream.text_html
  |> Dream.with_body
       [%string
         {|<html>
  <body>
    <h1>%d$code $reason</h1>
    <pre>$debug_info </pre>
  </body>
</html>
|}]
  |> Lwt.return

let json_error_template debug_info suggested_response =
  let status = Dream.status suggested_response in
  let code = Dream.status_to_int status in
  let reason = Dream.status_to_string status in

  suggested_response
  |> Dream.with_header "Content-Type" Dream.application_json
  |> Dream.with_body
       ({ code; message = reason; debug_info }
       |> yojson_of_error
       |> Yojson.Safe.to_string)
  |> Lwt.return

(* ppx?*)
let default_query = "{\\n  users {\\n    name\\n    id\\n  }\\n}\\n"

let () =
  (* Dream_cli.run ~debug:true *)
  (*
  this does not seem to work
  ~https:true  *)
  Dream.run ~debug:development ~greeting:development
    ~error_handler:(Dream.error_template ty_html_error_template)
  @@ Dream.logger
  @@ Dream_encoding.compress
  @@ Dream_livereload.inject_script ()
  @@ Handlers.counter
  (* @@ Dream.memory_sessions *)
  @@ Dream.cookie_sessions
  @@ Dream.sql_pool "sqlite3:db.sqlite"
  (* @@ Dream.sql_sessions *)
  @@ Dream.router
       [
         Dream.scope "/"
           [ Dream.origin_referer_check ]
           [ Dream.any "/csrf" (fun _ -> Dream.html "csrf") ];
         Handlers.api;
         Dream.get "/websocket" (fun _ ->
             Dream.websocket (fun websocket ->
                 let* () = Dream.send websocket "hey from server" in
                 let* message = Dream.receive websocket in
                 let* () =
                   message
                   |> Option.fold ~none:Lwt.return_unit ~some:(fun message ->
                          let* () = Lwt_io.printf "%s\n" message in
                          Dream.send websocket message)
                 in
                 Dream.close_websocket websocket));
         Dream.get "/bad" (fun _ -> Dream.empty `Bad_Request);
         Dream.any "graphql" (Dream.graphql Lwt.return (Schema.schema ()));
         (if development then
            Dream.get "/graphiql" (Dream.graphiql ~default_query "/graphql")
         else
           Dream.no_route);
         Dream.get "/static" (Dream.from_filesystem "static" "index.html");
         (*Dream.static "static/index.html";*)
         Dream.get "/frontend/**" @@ Dream.static "_build/default/frontend";
         Dream.get "/static/**" @@ Dream.static "static";
         Dream_livereload.route ();
       ]
  @@ Dream.not_found
