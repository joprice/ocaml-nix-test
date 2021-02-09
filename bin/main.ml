let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.router [ Dream.get "/hello" (fun _ -> Dream.html "world") ]
  @@ Dream.not_found
