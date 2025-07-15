(lang dune 3.19)
(name imber)
(version 1.0.0)
(generate_opam_files true)

(source
 (github officiallyutso/imber-ocaml-site-generator))

(authors "Utso Sarkar <utsosarkar1@gmail.com>")
(maintainers "Utso Sarkar <utsosarkar1@gmail.com>")
(license MIT)
(documentation https://github.com/officiallyutso/imber-ocaml-site-generator)

(package
 (name imber)
 (synopsis "A fast and flexible static site generator written in OCaml")
 (description "Imber is a static site generator that gives you complete creative freedom with Mermaid diagram support, syntax highlighting, and modern templates.")
 (depends 
  ocaml
  dune
  cmdliner
  yojson
  yaml
  omd
  lwt
  cohttp-lwt-unix
  fileutils
  re
  fmt
  logs
  pcre)
 (tags
  ("static-site-generator" "markdown" "web" "ocaml")))
