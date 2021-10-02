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

module Comment = struct
  type t = {
    id : int;
    text : string;
  }
  [@@deriving make, yojson]
end

let _list_comments =
  let query =
    R.collect T.unit T.(tup2 int string) "SELECT id, text FROM comment"
  in
  fun (module Db : DB) ->
    let* comments_or_error = Db.collect_list query () in
    Caqti_lwt.or_fail comments_or_error

let list_comments dbh =
  let open Comment in
  let* result =
    [%rapper
      get_many
        {sql|
      SELECT @int{comment.id}, @string{comment.text}
      FROM comment
      |sql}
        record_out]
      () dbh
  in
  Caqti_lwt.or_fail result

(* >|= Rapper.load_many *)
(*       (fst, fun { Comment.id; _ } -> id) *)
(*       [ (snd, fun user twoots -> { user with twoots }) ] *)

module ResponseBody = struct
  type 'a t = { data : 'a list } [@@deriving make, yojson]

  module Make (F : sig
    type t

    val t_of_yojson : Yojson.Safe.t -> t

    val yojson_of_t : t -> Yojson.Safe.t
  end) =
  struct
    type 'a u = 'a t

    let u_of_yojson = t_of_yojson

    let yojson_of_u = yojson_of_t

    type t = F.t u [@@deriving yojson]
  end
end

module Comments = ResponseBody.Make (Comment)

(* module Comments = struct *)
(*   type t = Comment.t ResponseBody.t [@@deriving yojson] *)
(* end *)

let api =
  Dream.scope "/api" []
    [
      Dream.get "/query" (fun req ->
          let* comments = Dream.sql req list_comments in
          let json =
            ResponseBody.{ data = comments }
            |> Comments.yojson_of_t
            |> Yojson.Safe.to_string
          in
          Dream.json json);
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
