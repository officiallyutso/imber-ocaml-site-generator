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

let frontmatter_regex = Pcre.regexp ~opts:[`MULTILINE] {|^---\s*\n(.*?)\n---\s*\n(.*)$|}

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
          let json_v = match v with
            | `String s -> `String s
            | `Bool b -> `Bool b
            | `Float f -> `Float f
            | `Int i -> `Int i
            | _ -> `String (Yaml.to_string_exn v)
          in
          (k, json_v)
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

let parse_content file_path content_dir =
  let content_text = In_channel.read_all file_path in
  let relative_path = 
    if String.starts_with ~prefix:content_dir file_path then
      String.drop_prefix file_path (String.length content_dir + 1)
    else
      file_path
  in
  
  match Pcre.extract ~rex:frontmatter_regex content_text with
  | [| _; frontmatter_str; body |] ->
      let frontmatter = parse_frontmatter frontmatter_str in
      let html = Omd.of_string body |> Omd.to_html in
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
      (* No frontmatter, treat entire content as body *)
      let html = Omd.of_string content_text |> Omd.to_html in
      let slug = Filename.basename file_path |> Filename.remove_extension in
      {
        frontmatter = {
          title = None; date = None; author = None; tags = [];
          layout = None; draft = false; metadata = [];
        };
        body = content_text;
        html;
        slug;
        path = file_path;
        relative_path;
      }
