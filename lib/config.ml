open Yojson.Safe

type site_config = {
  title: string;
  base_url: string;
  language: string;
  description: string;
}

type build_config = {
  output_dir: string;
  content_dir: string;
  template_dir: string;
  static_dir: string;
  minify: bool;
}

type server_config = {
  port: int;
  host: string;
}

type config = {
  site: site_config;
  build: build_config;
  server: server_config;
}

let default_config = {
  site = {
    title = "My Imber Site";
    base_url = "http://localhost:3000";
    language = "en";
    description = "A beautiful static site built with Imber";
  };
  build = {
    output_dir = "dist";
    content_dir = "content";
    template_dir = "templates";
    static_dir = "static";
    minify = false;
  };
  server = {
    port = 3000;
    host = "localhost";
  };
}

let parse_toml_config json =
  try
    let site_title = json |> member "site" |> member "title" |> to_string_option |> Option.value ~default:default_config.site.title in
    let site_url = json |> member "site" |> member "base_url" |> to_string_option |> Option.value ~default:default_config.site.base_url in
    let site_lang = json |> member "site" |> member "language" |> to_string_option |> Option.value ~default:default_config.site.language in
    let site_desc = json |> member "site" |> member "description" |> to_string_option |> Option.value ~default:default_config.site.description in
    
    let build_output = json |> member "build" |> member "output" |> to_string_option |> Option.value ~default:default_config.build.output_dir in
    let build_content = json |> member "build" |> member "content" |> to_string_option |> Option.value ~default:default_config.build.content_dir in
    let build_templates = json |> member "build" |> member "templates" |> to_string_option |> Option.value ~default:default_config.build.template_dir in
    let build_static = json |> member "build" |> member "static" |> to_string_option |> Option.value ~default:default_config.build.static_dir in
    let build_minify = json |> member "build" |> member "minify" |> to_bool_option |> Option.value ~default:default_config.build.minify in
    
    let server_port = json |> member "server" |> member "port" |> to_int_option |> Option.value ~default:default_config.server.port in
    let server_host = json |> member "server" |> member "host" |> to_string_option |> Option.value ~default:default_config.server.host in
    
    {
      site = { title = site_title; base_url = site_url; language = site_lang; description = site_desc };
      build = { output_dir = build_output; content_dir = build_content; template_dir = build_templates; static_dir = build_static; minify = build_minify };
      server = { port = server_port; host = server_host };
    }
  with
  | _ -> default_config

let load_config file =
  try
    let json = from_file file in
    parse_toml_config json
  with
  | Sys_error _ -> default_config
