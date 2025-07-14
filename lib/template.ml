open Re

type template_context = (string * string) list

let mustache_regex = Pcre.regexp {|\{\{([^}]+)\}\}|}
let conditional_regex = Pcre.regexp {|\{\{#if\s+([^}]+)\}\}(.*?)\{\{/if\}\}|}
let loop_regex = Pcre.regexp {|\{\{#([^}]+)\}\}(.*?)\{\{/\1\}\}|}

let render_template template context =
  let replace_var matched =
    let var_name = String.trim (Pcre.get_substring matched 1) in
    match List.assoc_opt var_name context with
    | Some value -> value
    | None -> ""
  in
  
  (* Handle conditionals *)
  let handle_conditionals text =
    Pcre.substitute ~rex:conditional_regex text ~subst:(fun matched ->
      let condition = String.trim (Pcre.get_substring matched 1) in
      let content = Pcre.get_substring matched 2 in
      match List.assoc_opt condition context with
      | Some "true" | Some _ -> content
      | None -> ""
    )
  in
  
  (* Handle basic variable substitution *)
  let final_text = handle_conditionals template in
  Pcre.substitute ~rex:mustache_regex ~subst:replace_var final_text

let load_template template_dir layout =
  let template_path = Filename.concat template_dir (layout ^ ".html") in
  try
    Some (In_channel.read_all template_path)
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
