open Js_of_ocaml

let log msg : unit = Js_of_ocaml.Firebug.console##log msg

let () =
  Js_of_ocaml.Firebug.console##log (Js.string "test");
  let host = Url.Current.host in
  let port = Url.Current.port |> Option.value ~default:80 in
  let uri =
    Js.string ("ws://" ^ host ^ ":" ^ string_of_int port ^ "/websocket")
  in
  let websocket = new%js WebSockets.webSocket uri in
  let count = ref 0 in
  websocket##.onmessage :=
    Dom.handler (fun (message : _ WebSockets.messageEvent Js.t) ->
        log @@ Js.string ("got response " ^ Js.to_string message##.data);
        count := !count + 1;
        if !count = 2 then
          websocket##close;
        Js._false);
  websocket##.onopen :=
    Dom.handler (fun _ ->
        websocket##send (Js.string "hey from web");
        Js._false)
