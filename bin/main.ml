open Cmdliner
open Imber

let build_cmd =
  let doc = "Build the static site" in
  let info = Cmd.info "build" ~doc in
  Cmd.v info Term.(const (fun () ->
    let config = Config.load_config "config.json" in
    Generator.build_site config
  ) $ const ())

let serve_cmd =
  let port =
    let doc = "Port to serve on" in
    Arg.(value & opt int 3000 & info ["p"; "port"] ~doc)
  in
  let doc = "Serve the site locally for development" in
  let info = Cmd.info "serve" ~doc in
  Cmd.v info Term.(const (fun port ->
    let config = Config.load_config "config.json" in
    let config = { config with server = { config.server with port } } in
    (* First build the site *)
    Generator.build_site config;
    (* Then serve it *)
    Generator.serve_site config
  ) $ port)

let init_cmd =
  let project_name =  (* Renamed from 'name' to 'project_name' *)
    let doc = "Project name" in
    Arg.(value & pos 0 string "my-imber-site" & info [] ~doc)
  in
  let doc = "Initialize a new Imber project" in
  let info = Cmd.info "init" ~doc in
  Cmd.v info Term.(const (fun name ->
    Init.init_project name
  ) $ project_name)  (* Use 'project_name' instead of 'name' *)

let clean_cmd =
  let doc = "Clean the output directory" in
  let info = Cmd.info "clean" ~doc in
  Cmd.v info Term.(const (fun () ->
    let config = Config.load_config "config.json" in
    if Sys.file_exists config.build.output_dir then (
      FileUtil.rm ~recurse:true [config.build.output_dir];
      Printf.printf "✅ Cleaned %s\n" config.build.output_dir
    ) else (
      Printf.printf "Nothing to clean - %s doesn't exist\n" config.build.output_dir
    )
  ) $ const ())

let version_cmd =
  let doc = "Show version information" in
  let info = Cmd.info "version" ~doc in
  Cmd.v info Term.(const (fun () ->
    Printf.printf "Imber v1.0.0\n";
    Printf.printf "A fast and flexible static site generator written in OCaml\n"
  ) $ const ())

let default_cmd =
  let doc = "Imber - A fast and flexible static site generator" in
  let man = [
    `S Manpage.s_description;
    `P "Imber is a static site generator that gives you complete creative freedom. Build anything from personal blogs to professional portfolios with custom templates and styling.";
    `S Manpage.s_commands;
    `P "Use $(b,imber COMMAND --help) for help on a specific command.";
    `S Manpage.s_examples;
    `P "Create a new project:";
    `P "  $(b,imber init my-blog)";
    `P "Build your site:";
    `P "  $(b,imber build)";
    `P "Serve locally:";
    `P "  $(b,imber serve)";
  ] in
  let info = Cmd.info "imber" ~version:"1.0.0" ~doc ~man in
  Cmd.group info [build_cmd; serve_cmd; init_cmd; clean_cmd; version_cmd]

let () = exit (Cmd.eval default_cmd)
