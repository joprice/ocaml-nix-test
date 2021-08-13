open Lwt.Syntax

type t = {
  x : int32;
  y : int32;
}

let () =
  Dream.run
  @@ Dream.logger
  @@ Dream_encoding.compress
  @@ Dream_livereload.inject_script ()
  @@ Dream.router
       [
         Dream.get "/slow" (fun _ ->
             let* () = Lwt_unix.sleep 0.1 in
             Dream.html "world");
         Dream.get "/fast" (fun _ -> Dream.html "world a");
         Dream.get "/fail" (fun _ -> Lwt.fail Not_found);
         Dream.get "/user/:user" (fun req ->
             Dream.respond @@ Dream.param "user" req);
         Dream_livereload.route ();
       ]
  @@ Dream.not_found
