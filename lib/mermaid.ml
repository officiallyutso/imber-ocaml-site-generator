open Re

let mermaid_regex = Pcre.regexp ~flags:[`MULTILINE; `DOTALL] {|```mermaid\n(.*?)\n```|}

let process_mermaid_blocks content =
  let replace_mermaid matched =
    try
      let substrings = Pcre.exec ~rex:mermaid_regex matched in
      let diagram_content = String.trim (Pcre.get_substring substrings 1) in
      let diagram_id = "mermaid_" ^ (string_of_int (Random.int 10000)) in
      Printf.sprintf {|<div class="mermaid" id="%s">
%s
</div>|} diagram_id diagram_content
    with
    | Not_found -> matched
  in
  
  Pcre.substitute ~rex:mermaid_regex ~subst:replace_mermaid content

let add_mermaid_script html =
  let mermaid_script = {|
<script src="https://cdn.jsdelivr.net/npm/mermaid@10.6.1/dist/mermaid.min.js"></script>
<script>
    mermaid.initialize({
        startOnLoad: true,
        theme: 'default',
        securityLevel: 'loose',
    });
</script>|} in
  
  if String.contains html '<' && String.contains html '>' then
    let lines = String.split_on_char '\n' html in
    List.map (fun line ->
      if String.contains line '<' && 
         let trimmed = String.trim line in
         String.length trimmed >= 7 && 
         String.sub trimmed 0 7 = "</body>" then
        String.concat "\n" [mermaid_script; line]
      else
        line) lines
    |> String.concat "\n"
  else
    html
