
type template_context = (string * string) list

let mustache_regex = Pcre.regexp {|\{\{([^}]+)\}\}|}
let conditional_regex = Pcre.regexp {|\{\{#if\s+([^}]+)\}\}(.*?)\{\{/if\}\}|}
let loop_regex = Pcre.regexp {|\{\{#([^}]+)\}\}(.*?)\{\{/\1\}\}|}

let safe_assoc key context =
  try List.assoc key context with Not_found -> ""

let render_template template context =
  let replace_var matched =
    try
      let substrings = Pcre.exec ~rex:mustache_regex matched in
      let var_name = String.trim (Pcre.get_substring substrings 1) in
      let value = safe_assoc var_name context in
      value
    with
    | Not_found -> matched
  in
  
  (* Handle conditionals *)
  let handle_conditionals text =
    let rec process_text input =
      try
        let substrings = Pcre.exec ~rex:conditional_regex input in
        let condition = String.trim (Pcre.get_substring substrings 1) in
        let content = Pcre.get_substring substrings 2 in
        let replacement =
          let condition_value = safe_assoc condition context in
          if condition_value <> "" then content else ""
        in
        let (before_match, after_match) = Pcre.get_substring_ofs substrings 0 in
        let prefix = String.sub input 0 before_match in
        let suffix = String.sub input after_match (String.length input - after_match) in
        process_text (prefix ^ replacement ^ suffix)
      with
      | Not_found -> input
    in
    process_text text
  in
  
  (* Handle basic variable substitution *)
  let final_text = handle_conditionals template in
  let substituted = Pcre.substitute ~rex:mustache_regex ~subst:replace_var final_text in
  
  (* Add Mermaid script if content contains mermaid diagrams *)
  let content_value = safe_assoc "content" context in
  if String.contains content_value 'm' && String.contains content_value 'e' && 
     String.contains content_value 'r' && String.contains content_value 'a' then
    Mermaid.add_mermaid_script substituted
  else
    substituted



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

let load_template template_dir layout =
  let template_path = Filename.concat template_dir (layout ^ ".html") in
  try
    Some (read_all template_path)
  with
  | Sys_error _ -> None

let create_context content site_config =
  let base_context = [
    ("title", match content.Content.frontmatter.title with Some t -> t | None -> site_config.Config.site.title);
    ("content", content.html);
    ("site_title", site_config.site.title);
    ("site_url", site_config.site.base_url);
    ("site_description", site_config.site.description);
    ("slug", content.slug);
    ("date", match content.frontmatter.date with Some d -> d | None -> "");
    ("author", match content.frontmatter.author with Some a -> a | None -> "");
  ] in
  
  (* Add tags as comma-separated string *)
  let tags_context = [("tags", String.concat ", " content.frontmatter.tags)] in
  
  (* Add custom metadata from frontmatter *)
  let metadata_context =
    List.map (fun (k, v) -> (k, Yojson.Safe.to_string v)) content.frontmatter.metadata
  in
  
  base_context @ tags_context @ metadata_context
