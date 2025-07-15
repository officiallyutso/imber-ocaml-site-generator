let write_all path content =
  let oc = open_out path in
  Fun.protect ~finally:(fun () -> close_out oc) (fun () ->
    output_string oc content
  )

let ensure_dir_exists dir =
  if not (Sys.file_exists dir) then
    FileUtil.mkdir ~parent:true dir

let copy_static_files config =
  let static_dir = config.Config.build.static_dir in
  let output_dir = config.build.output_dir in
  if Sys.file_exists static_dir then (
    Printf.printf "Copying static files from %s to %s\n" static_dir output_dir;
    FileUtil.cp ~recurse:true [static_dir ^ "/."] output_dir
  )

let generate_page content config =
  let layout = match content.Content.frontmatter.layout with
    | Some l -> l
    | None -> "default"
  in
  match Template.load_template config.Config.build.template_dir layout with
  | Some template ->
      let context = Template.create_context content config in
      let html = Template.render_template template context in
      
      (* Create output path maintaining directory structure *)
      let relative_dir = Filename.dirname content.relative_path in
      let output_subdir = if relative_dir = "." then "" else relative_dir in
      let output_dir = Filename.concat config.build.output_dir output_subdir in
      ensure_dir_exists output_dir;
      
      let output_path = Filename.concat output_dir (content.slug ^ ".html") in
      write_all output_path html;
      Printf.printf "Generated: %s\n" output_path
  | None ->
      Printf.eprintf "Template not found: %s\n" layout

let scan_content_files config =
  let content_dir = config.Config.build.content_dir in
  let rec scan_dir dir =
    if Sys.file_exists dir then
      Sys.readdir dir
      |> Array.to_list
      |> List.fold_left (fun acc file ->
          let path = Filename.concat dir file in
          if Sys.is_directory path then
            acc @ (scan_dir path)
          else if Filename.extension file = ".md" then
            path :: acc
          else
            acc) []
    else
      []
  in
  scan_dir content_dir

let build_site config =
  Printf.printf "Building site with Imber...\n";
  
  (* Clean and create output directory *)
  if Sys.file_exists config.Config.build.output_dir then
    FileUtil.rm ~recurse:true [config.build.output_dir];
  ensure_dir_exists config.build.output_dir;
  
  (* Copy static files *)
  copy_static_files config;
  
  (* Process content files *)
  let content_files = scan_content_files config in
  Printf.printf "Found %d content files\n" (List.length content_files);
  
  List.iter (fun file ->
    let content = Content.parse_content file config.build.content_dir in
    if not content.frontmatter.draft then
      generate_page content config
    else
      Printf.printf "Skipping draft: %s\n" file
  ) content_files;
  
  Printf.printf "Site built successfully in %s!\n" config.build.output_dir

open Lwt.Syntax
open Cohttp_lwt_unix

let serve_file_from_dist dist_dir uri =
  let file_path =
    if uri = "/" then
      Filename.concat dist_dir "index.html"
    else
      let path = String.sub uri 1 (String.length uri - 1) in
      if Filename.extension path = "" then
        Filename.concat dist_dir (path ^ ".html")
      else
        Filename.concat dist_dir path
  in
  
  if Sys.file_exists file_path then
    let* content = Lwt_io.with_file ~mode:Input file_path Lwt_io.read in
    let content_type =
      match Filename.extension file_path with
      | ".css" -> "text/css"
      | ".js" -> "text/javascript"
      | ".png" -> "image/png"
      | ".jpg" | ".jpeg" -> "image/jpeg"
      | ".gif" -> "image/gif"
      | ".svg" -> "image/svg+xml"
      | _ -> "text/html"
    in
    let headers = Cohttp.Header.init_with "content-type" content_type in
    let response = Cohttp.Response.make ~status:`OK ~headers () in
    Lwt.return (response, `String content)
  else
    let headers = Cohttp.Header.init_with "content-type" "text/html" in
    let response = Cohttp.Response.make ~status:`Not_found ~headers () in
    Lwt.return (response, `String "404 Not Found")


let serve_site config =
  Printf.printf "🚀 Starting development server...\n";
  flush_all ();
  Printf.printf "Server running at http://%s:%d\n" config.Config.server.host config.server.port;
  flush_all ();
  Printf.printf "Press Ctrl+C to stop\n";
  flush_all ();
  
  let callback _conn req _body =
    let uri = Uri.path (Cohttp.Request.uri req) in
    Printf.printf "Serving: %s\n" uri;
    flush_all ();
    serve_file_from_dist config.Config.build.output_dir uri
  in
  
  let server = Server.create ~mode:(`TCP (`Port config.server.port))
    (Server.make ~callback ()) in
  
  Lwt_main.run server

