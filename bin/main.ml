open Lwt.Syntax

let successes = ref 0

let failures = ref 0

type error = {
  code : int;
  message : string;
  debug_info : string option;
}
[@@deriving yojson]

let counter handler request =
  (* not using try%lwt catches exceptions generated by Lwt.fail and raise *)
  try%lwt
    let* result = handler request in
    successes := !successes + 1;
    Lwt.return result
  with exn ->
    failures := !failures + 1;
    raise exn

let html_to_string html = Format.asprintf "%a" (Tyxml.Html.pp ()) html

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
           {|<html>
            <head>
            <title>page</title>
            </head>
  <body>
    <h1>|}
             [ Html.txt (Int.to_string code ^ " " ^ reason) ]
             {|</h1>
    <pre>|}
             [ Html.txt debug_info ] {|</pre>
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

let () =
  (* Dream_cli.run ~debug:true *)
  Dream.run ~debug:true
    ~error_handler:(Dream.error_template ty_html_error_template)
  @@ Dream.logger
  @@ Dream_encoding.compress
  @@ Dream_livereload.inject_script ()
  @@ counter
  (* @@ Dream.memory_sessions *)
  @@ Dream.cookie_sessions
  @@ Dream.router
       [
         Dream.get "/slow" (fun _ ->
             let* () = Lwt_unix.sleep 0.1 in
             Dream.html
               (Printf.sprintf "world successes: %i failures: %i" !successes
                  !failures));
         Dream.get "/fast" (fun _ -> Dream.html "world a");
         Dream.get "/fail" (fun _ -> raise @@ Failure "fail");
         Dream.get "/exn" (fun _ -> Lwt.fail @@ Failure "fail");
         Dream.post "/echo" (fun req ->
             let+ body = Dream.body req in
             Dream.response
               ~headers:[ ("Content-Type", "application/octet-stream") ]
               body);
         (* returns all keys stored in the session for the current user *)
         Dream.get "sessions" (fun req ->
             let sessions = Dream.all_session_values req in
             let sessions =
               sessions
               |> ListLabels.map ~f:(fun (a, b) -> Printf.sprintf "%s:%s" a b)
             in
             sessions |> String.concat "," |> Dream.respond);
         Dream.get "/user" (fun req ->
             let user =
               Dream.session "user" req |> Option.value ~default:"not logged in"
             in
             Dream.respond user);
         Dream.post "/user/:user" (fun req ->
             let username = Dream.param "user" req in
             let* () = Dream.put_session "user" username req in
             Dream.html "logged in");
         Dream_livereload.route ();
         Dream.get "/bad" (fun _ -> Dream.empty `Bad_Request);
       ]
  @@ Dream.not_found
