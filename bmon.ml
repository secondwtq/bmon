
open Printf

let log_gettime (): string =
  let tm = Unix.gettimeofday () |> Unix.localtime in
  sprintf "%d-%02d-%02d %02d:%02d:%02d"
    (tm.tm_year + 1900) (tm.tm_mon + 1) tm.tm_mday
    tm.tm_hour tm.tm_min tm.tm_sec

module Resp = struct
  type data = {
    live_status: int;
  } [@@deriving yojson { strict = false }]
  type t = {
    code: int;
    data: data;
  } [@@deriving yojson { strict = false }]
  (* seems ppx_deriving_merlin is outdated ... *)
end

(* TODO: replace return type w/ result *)
let get_islive (room_id: string): bool Lwt.t =
  let%lwt (resp, body) = sprintf "https://api.live.bilibili.com/room/v1/Room/get_info?id=%s" room_id |> Uri.of_string |> Cohttp_lwt_unix.Client.get in
  let resp = Cohttp.Response.status resp in
  if resp <> `OK
  then Lwt.return false
  else (
    let%lwt body = Cohttp_lwt.Body.to_string body in
    let body_json = Yojson.Safe.from_string body in
    (match Resp.of_yojson body_json with
     | Ok resp ->
       printf "%s - resp %s\n" (log_gettime ()) (resp |> Resp.to_yojson |> Yojson.Safe.to_string); flush_all ();
       Lwt.return (resp.data.live_status <> 0)
     | Error err ->
       printf "%s - resp err %s\n" (log_gettime ()) err; flush_all();
       Lwt.return false))

type arg = {
  room_id: string;
  interval: float;
  exec: string option;
  check_exec: string option;
}

let construct_arg (room_id: string) (interval: float) (exec: string option) (check_exec: string option): arg =
  { room_id; interval; exec; check_exec; }

let exec_cmd (cmd: string): unit = ignore (Lwt_process.(cmd |> shell |> exec))

let rec bmon_loop (cur_live: bool) (arg: arg): unit Lwt.t =
  printf "%s - requesting\n" (log_gettime ()); flush_all ();
  let%lwt islive = get_islive arg.room_id in
  printf "%s - got %b\n" (log_gettime ()) islive; flush_all ();
  (match cur_live, islive with
  | false, true -> CCOpt.iter exec_cmd arg.exec
  | true, false -> ()
  | _ -> CCOpt.iter exec_cmd arg.check_exec);
  let%lwt _ = Lwt_unix.sleep arg.interval in
  bmon_loop islive arg

let bmon (arg: arg) =
  Lwt_main.run (
    bmon_loop false arg);
  `Ok 0

let arg_liveid = Cmdliner.Arg.(
    let doc = "specify live id to monitor" in
    required & pos 0 (some string) None & info [] ~docv:"ID" ~doc
  )

let arg_interval = Cmdliner.Arg.(
    let doc = "interval between checking, in seconds, non-integer value allowed" in
    value & opt float 20.0 & info ["i"; "interval"] ~docv:"SEC" ~doc
  )

let arg_exec = Cmdliner.Arg.(
    let doc = "command to execute when live starts" in
    value & opt (some string) None & info ["e"; "exec"] ~docv:"CMD" ~doc
  )

let arg_check_exec = Cmdliner.Arg.(
    let doc = "command to execute after check and nothing changes" in
    value & opt (some string) None & info ["c"; "check-exec"] ~docv:"CMD" ~doc
  )

let cmd = Cmdliner.Term.(
    ret (const bmon $ (
        const construct_arg $ arg_liveid $ arg_interval $ arg_exec $ arg_check_exec)), info "bmon")

let _ = Cmdliner.Term.(exit @@ eval cmd)
