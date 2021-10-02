open Lwt.Syntax

module type DB = Caqti_lwt.CONNECTION

module R = Caqti_request
module T = Caqti_type

let counter = Counter.counter

type user = {
  id : int;
  name : string;
}
[@@deriving yojson]

type comment = {
  id : int;
  text : string;
}

let list_comments =
  let query =
    R.collect T.unit T.(tup2 int string) "SELECT id, text FROM comment"
  in
  fun (module Db : DB) ->
    let* comments_or_error = Db.collect_list query () in
    Caqti_lwt.or_fail comments_or_error

let api =
  Dream.scope "/api" []
    [
      Dream.get "/query" (fun req ->
          let* comments = Dream.sql req list_comments in
          comments |> List.iter (fun (_, comment) -> print_endline comment);
          Dream.empty `OK);
      Dream.get "/slow" (fun _ ->
          let* () = Lwt_unix.sleep 0.1 in
          Dream.html
            (Printf.sprintf "world successes: %i failures: %i"
               !Counter.successes !Counter.failures));
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
      Dream.get "/users" (fun _ ->
          let users =
            `List [ { name = "user-1"; id = 1 } |> yojson_of_user ]
            |> Yojson.Safe.to_string
          in
          Dream.json users);
      Dream.get "/user" (fun req ->
          let user =
            Dream.session "user" req |> Option.value ~default:"not logged in"
          in
          Dream.respond user);
      Dream.post "/user/:user" (fun req ->
          let username = Dream.param "user" req in
          let* () = Dream.put_session "user" username req in
          Dream.html "logged in");
    ]

let show ?(prefix = "/") ?(method_ = `GET) ?(body = "") target router =
  try
    Dream.request ~method_ ~target body
    |> Dream.test ~prefix
         (router @@ fun _ -> Dream.respond ~status:`Not_Found "")
    |> fun response ->
    let status = Dream.status response
    and body = Lwt_main.run (Dream.body response) in
    Printf.printf "Response: %i %s\n"
      (Dream.status_to_int status)
      (Dream.status_to_string status);
    if body <> "" then
      Printf.printf "%s\n" body
    else
      ()
  with Failure message -> print_endline message

let%expect_test _ =
  show ~method_:`POST ~body:"test" "/api/echo" @@ Dream.router [ api ];
  [%expect {| 
    Response: 200 OK 
    test
  |}]
