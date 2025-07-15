open Re


type frontmatter = {
  title: string option;
  date: string option;
  author: string option;
  tags: string list;
  layout: string option;
  draft: bool;
  metadata: (string * Yojson.Safe.t) list;
}

type content = {
  frontmatter: frontmatter;
  body: string;
  html: string;
  slug: string;
  path: string;
  relative_path: string;
}

(* Updated regex to handle both Unix and Windows line endings *)
let frontmatter_regex = Pcre.regexp ~flags:[`MULTILINE; `DOTALL] {|^---\s*[\r\n]+(.*?)[\r\n]+---\s*[\r\n]+(.*)$|}

let rec yaml_to_json (yaml_val : Yaml.value) : Yojson.Safe.t =
  match yaml_val with
  | `String s -> `String s
  | `Bool b -> `Bool b
  | `Float f -> `Float f
  | `Null -> `Null
  | `A arr -> `List (List.map yaml_to_json arr)
  | `O obj -> `Assoc (List.map (fun (k, v) -> (k, yaml_to_json v)) obj)

let parse_frontmatter yaml_str =
  try
    let yaml = Yaml.of_string yaml_str in
    match yaml with
    | Ok (`O assoc) ->
        let get_string key = 
          match List.assoc_opt key assoc with
          | Some (`String s) -> Some s
          | _ -> None
        in
        let get_bool key default =
          match List.assoc_opt key assoc with
          | Some (`Bool b) -> b
          | _ -> default
        in
        let get_list key =
          match List.assoc_opt key assoc with
          | Some (`A items) -> 
              List.filter_map (function `String s -> Some s | _ -> None) items
          | _ -> []
        in
        let metadata = List.map (fun (k, v) -> 
          (k, yaml_to_json v)
        ) assoc in
        {
          title = get_string "title";
          date = get_string "date";
          author = get_string "author";
          tags = get_list "tags";
          layout = get_string "layout";
          draft = get_bool "draft" false;
          metadata;
        }
    | _ -> failwith "Invalid frontmatter format"
  with
  | _ -> {
      title = None; date = None; author = None; tags = [];
      layout = None; draft = false; metadata = [];
    }

let read_all filename =
  let ic = open_in filename in
  Fun.protect ~finally:(fun () -> close_in ic) (fun () ->
    let buffer = Buffer.create 1024 in
    try
      while true do
        let line = input_line ic in
        Buffer.add_string buffer line;
        Buffer.add_char buffer '\n'
      done;
      Buffer.contents buffer
    with
    | End_of_file -> Buffer.contents buffer
  )

let drop_prefix s n =
  if String.length s <= n then "" 
  else String.sub s n (String.length s - n)

let parse_content file_path content_dir =
  try
    let content_text = read_all file_path in
    let relative_path =
      if String.length file_path > String.length content_dir && 
         String.sub file_path 0 (String.length content_dir) = content_dir then
        drop_prefix file_path (String.length content_dir + 1)
      else
        file_path
    in
    
    try
      match Pcre.extract ~rex:frontmatter_regex content_text with
      | [| _; frontmatter_str; body |] ->
          Printf.printf "Found frontmatter in %s\n" (Filename.basename file_path);
          let frontmatter = parse_frontmatter frontmatter_str in
          (* Process Mermaid blocks first, then convert to HTML *)
          let processed_body = Mermaid.process_mermaid_blocks body in
          let html = Omd.of_string processed_body |> Omd.to_html in
          let slug = Filename.basename file_path |> Filename.remove_extension in
          {
            frontmatter;
            body;
            html;
            slug;
            path = file_path;
            relative_path;
          }
      | _ ->
          Printf.printf "Unexpected frontmatter pattern in %s\n" (Filename.basename file_path);
          let processed_body = Mermaid.process_mermaid_blocks content_text in
          let html = Omd.of_string processed_body |> Omd.to_html in
          let slug = Filename.basename file_path |> Filename.remove_extension in
          {
            frontmatter = {
              title = Some (String.capitalize_ascii slug);
              date = None; author = None; tags = [];
              layout = Some "default"; draft = false; metadata = [];
            };
            body = content_text;
            html;
            slug;
            path = file_path;
            relative_path;
          }
    with
    | Not_found ->
        Printf.printf "No frontmatter in %s, treating as plain markdown\n" (Filename.basename file_path);
        let processed_body = Mermaid.process_mermaid_blocks content_text in
        let html = Omd.of_string processed_body |> Omd.to_html in
        let slug = Filename.basename file_path |> Filename.remove_extension in
        {
          frontmatter = {
            title = Some (String.capitalize_ascii slug);
            date = None; author = None; tags = [];
            layout = Some "default"; draft = false; metadata = [];
          };
          body = content_text;
          html;
          slug;
          path = file_path;
          relative_path;
        }
  with
  | Sys_error msg ->
      Printf.eprintf "Error reading file %s: %s\n" file_path msg;
      failwith ("Failed to read file: " ^ file_path)
