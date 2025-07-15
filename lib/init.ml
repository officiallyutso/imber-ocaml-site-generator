let write_all path content =
  let oc = open_out path in
  Fun.protect ~finally:(fun () -> close_out oc) (fun () ->
    output_string oc content
  )

let create_directory dir =
  if not (Sys.file_exists dir) then
    FileUtil.mkdir ~parent:true dir

let create_file path content =
  let dir = Filename.dirname path in
  create_directory dir;
  write_all path content

let default_config_toml = {|{
  "site": {
    "title": "My Imber Site",
    "base_url": "http://localhost:3000",
    "language": "en",
    "description": "A beautiful static site built with Imber"
  },
  "build": {
    "output": "dist",
    "content": "content",
    "templates": "templates",
    "static": "static",
    "minify": false
  },
  "server": {
    "port": 3000,
    "host": "localhost"
  }
}|}

let default_template = {|<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{title}} - {{site_title}}</title>
    <meta name="description" content="{{site_description}}">
    <link rel="stylesheet" href="/style.css">
    <style>
        /* Mermaid diagram styling */
        .mermaid {
            text-align: center;
            margin: 2rem 0;
            background: #fafafa;
            padding: 1rem;
            border-radius: 8px;
            border: 1px solid #e1e1e1;
        }
    </style>
</head>
<body>
    <header class="header">
        <div class="container">
            <h1><a href="/">{{site_title}}</a></h1>
            <nav>
                <a href="/">Home</a>
                <a href="/about">About</a>
                <a href="/first-post">Post</a>
            </nav>
        </div>
    </header>
    
    <main class="main">
        <div class="container">
            <article class="article">
                <h1>{{title}}</h1>
                {{#if date}}<p class="date">Published on {{date}}</p>{{/if}}
                {{#if author}}<p class="author">By {{author}}</p>{{/if}}
                <div class="content">
                    {{content}}
                </div>
                {{#if tags}}<div class="tags">Tags: {{tags}}</div>{{/if}}
            </article>
        </div>
    </main>
    
    <footer class="footer">
        <div class="container">
            <p>&copy; 2025 {{site_title}}. Built with <a href="https://github.com/yourusername/imber">Imber</a>.</p>
        </div>
    </footer>
    <script src="https://cdn.jsdelivr.net/npm/mermaid@10.6.1/dist/mermaid.min.js"></script>
    <script>
        mermaid.initialize({
            startOnLoad: true,
            theme: 'default',
            securityLevel: 'loose',
        });
    </script>
</body>
</html>|}

let modern_css = {|/* Modern Imber Styles */
:root {
    --primary-color: #2c3e50;
    --secondary-color: #3498db;
    --accent-color: #e74c3c;
    --text-color: #333;
    --text-light: #666;
    --background: #fff;
    --background-light: #f8f9fa;
    --border-color: #e9ecef;
    --shadow: 0 2px 4px rgba(0,0,0,0.1);
}

* {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
}

body {
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
    line-height: 1.6;
    color: var(--text-color);
    background-color: var(--background);
}

.container {
    max-width: 1200px;
    margin: 0 auto;
    padding: 0 2rem;
}

.header {
    background: var(--background-light);
    border-bottom: 1px solid var(--border-color);
    padding: 1rem 0;
    position: sticky;
    top: 0;
    z-index: 100;
}

.header h1 {
    margin: 0;
    font-size: 1.8rem;
    display: inline-block;
}

.header h1 a {
    color: var(--primary-color);
    text-decoration: none;
    transition: color 0.3s ease;
}

.header h1 a:hover {
    color: var(--secondary-color);
}

.header nav {
    float: right;
    margin-top: 0.5rem;
}

.header nav a {
    margin-left: 2rem;
    text-decoration: none;
    color: var(--secondary-color);
    font-weight: 500;
    transition: color 0.3s ease;
}

.header nav a:hover {
    color: var(--primary-color);
}

.main {
    min-height: 70vh;
    padding: 3rem 0;
}

.article {
    max-width: 800px;
    margin: 0 auto;
}

.article h1 {
    color: var(--primary-color);
    margin-bottom: 1rem;
    font-size: 2.5rem;
    line-height: 1.2;
}

.date, .author {
    color: var(--text-light);
    font-size: 0.9rem;
    margin-bottom: 1rem;
}

.date {
    font-style: italic;
}

.content {
    line-height: 1.8;
    margin: 2rem 0;
}

.content h2 {
    margin-top: 2.5rem;
    margin-bottom: 1rem;
    color: var(--primary-color);
    font-size: 1.8rem;
}

.content h3 {
    margin-top: 2rem;
    margin-bottom: 0.75rem;
    color: var(--primary-color);
    font-size: 1.4rem;
}

.content p {
    margin-bottom: 1.5rem;
}

.content ul, .content ol {
    margin-bottom: 1.5rem;
    padding-left: 2rem;
}

.content li {
    margin-bottom: 0.5rem;
}

.content blockquote {
    border-left: 4px solid var(--secondary-color);
    padding-left: 1.5rem;
    margin: 2rem 0;
    font-style: italic;
    color: var(--text-light);
    background: var(--background-light);
    padding: 1rem 1.5rem;
    border-radius: 0 4px 4px 0;
}

.content code {
    background: var(--background-light);
    padding: 0.2rem 0.4rem;
    border-radius: 3px;
    font-family: 'Monaco', 'Menlo', 'Ubuntu Mono', monospace;
    font-size: 0.9rem;
    color: var(--accent-color);
}

.content pre {
    background: var(--background-light);
    padding: 1.5rem;
    border-radius: 8px;
    overflow-x: auto;
    margin: 2rem 0;
    border: 1px solid var(--border-color);
}

.content pre code {
    background: none;
    padding: 0;
    color: var(--text-color);
}

.content img {
    max-width: 100%;
    height: auto;
    border-radius: 8px;
    box-shadow: var(--shadow);
    margin: 2rem 0;
}

.tags {
    margin-top: 2rem;
    padding-top: 1rem;
    border-top: 1px solid var(--border-color);
    color: var(--text-light);
    font-size: 0.9rem;
}

.footer {
    background: var(--background-light);
    border-top: 1px solid var(--border-color);
    padding: 2rem 0;
    margin-top: 3rem;
    text-align: center;
}

.footer p {
    color: var(--text-light);
    margin: 0;
}

.footer a {
    color: var(--secondary-color);
    text-decoration: none;
}

.footer a:hover {
    text-decoration: underline;
}

/* Mermaid diagram styling */
.mermaid {
    text-align: center;
    margin: 2rem 0;
    background: #fafafa;
    padding: 1rem;
    border-radius: 8px;
    border: 1px solid #e1e1e1;
}

/* Responsive Design */
@media (max-width: 768px) {
    .container {
        padding: 0 1rem;
    }
    
    .header h1 {
        font-size: 1.5rem;
    }
    
    .header nav {
        float: none;
        margin-top: 1rem;
    }
    
    .header nav a {
        margin-left: 0;
        margin-right: 1rem;
    }
    
    .article h1 {
        font-size: 2rem;
    }
    
    .content h2 {
        font-size: 1.5rem;
    }
    
    .main {
        padding: 2rem 0;
    }
}|}

let sample_index = {|---
title: "Welcome to Imber"
layout: "default"
date: "2025-01-15"
author: "Imber Team"
tags: ["welcome", "getting-started", "static-site"]
---

# Welcome to Imber!

Congratulations! You've successfully created your first Imber static site. This is your homepage, and you can start customizing it right away.

## What is Imber?

Imber is a **fast** and **flexible** static site generator written in OCaml. It gives you complete creative freedom to build anything from personal blogs to professional portfolios.

### Key Features

- **Fast**: Built with OCaml for maximum performance
- **Flexible**: Complete creative freedom with custom templates
- **Simple**: Easy-to-use Markdown content with frontmatter
- **Extensible**: Plugin system for custom functionality
- **Modern**: Clean URLs and responsive design

## Getting Started

1. **Edit this file**: Modify `content/index.md` to customize your homepage
2. **Create new content**: Add new `.md` files in the `content/` directory
3. **Customize templates**: Edit files in `templates/` to change your site's layout
4. **Style your site**: Modify `static/style.css` to customize the appearance
5. **Build and serve**: Run `imber build` and `imber serve` to see your changes

## Project Structure
```
your-site/
├── content/ # Your Markdown content
├── templates/ # HTML templates
├── static/ # CSS, images, and other assets
├── config.json # Site configuration
```


## Sample Content

This site includes:

- **Homepage** (this page) - Introduction to your site
- **About page** - Tell visitors about yourself
- **Modern CSS** - Beautiful, responsive design
- **Sample posts** - Examples to get you started

## Next Steps

- Read the [documentation](https://github.com/yourusername/imber) to learn more
- Explore the template system to create custom layouts
- Add more content and pages to your site
- Deploy your site to your favorite hosting platform

**Start building something amazing!** |}

let sample_about = {|---
title: "About This Site"
layout: "default"
date: "2025-01-15"
author: "Site Owner"
tags: ["about", "personal"]
---

# About This Site

Welcome to my personal website built with **Imber**, a fast and flexible static site generator written in OCaml.

## About Imber

Imber is a static site generator that prioritizes:

- **Performance**: Fast builds and optimized output
- **Flexibility**: No imposed design constraints
- **Simplicity**: Clean, intuitive workflow
- **Power**: Advanced features when you need them

## About Me

This is where you can tell your story. Feel free to customize this page with:

- Your background and experience
- Your interests and hobbies
- Your professional work
- Contact information
- Links to your social media

## Customization

This site is fully customizable:

- **Content**: Edit Markdown files in the `content/` directory
- **Design**: Modify templates in `templates/`
- **Styling**: Update CSS in `static/style.css`
- **Configuration**: Adjust settings in `config.json`

## Get Started

1. Replace this content with your own story
2. Add your own pages and posts
3. Customize the design to match your style
4. Deploy to your favorite hosting platform

**Start building something amazing!** |}

let sample_blog_post = {|---
title: "My First Blog Post with Mermaid Diagrams"
layout: "default"
date: "2025-01-15"
author: "Your Name"
tags: ["blog", "first-post", "example", "mermaid"]
---

# My First Blog Post with Mermaid Diagrams

This is an example blog post showing how to create content with Imber, including support for Mermaid diagrams!

## Writing in Markdown

Markdown is easy to write and read. Here are some examples:

### Text Formatting

- **Bold text** for emphasis
- *Italic text* for style
- `Code snippets` for technical content
- ~~Strikethrough~~ for corrections

### Sample Flowchart

```mermaid
graph TD
A[Start] --> B{Is it working?}
B -->|Yes| C[Great!]
B -->|No| D[Debug]
D --> B
C --> E[Deploy]
```


### Sample Sequence Diagram

```mermaid
sequenceDiagram
participant User
participant Browser
participant Server
User->>Browser: Open website
Browser->>Server: Request page
Server->>Browser: Return HTML
Browser->>User: Display page
```


### Sample Pie Chart

```mermaid
pie title Programming Languages Usage
"OCaml" : 45
"Python" : 25
"JavaScript" : 20
"Other" : 10
```


## Code Blocks

```OCaml
function greet(name) {
return Hello, ${name}!;
}

console.log(greet("World"));
```


## Next Steps

- Create more blog posts
- Customize the design
- Add your own content
- Experiment with Mermaid diagrams!

Happy blogging! |}

let init_project name =
  Printf.printf "Initializing new Imber project: %s\n" name;
  
  (* Create directory structure *)
  create_directory name;
  create_directory (Filename.concat name "content");
  create_directory (Filename.concat name "templates");
  create_directory (Filename.concat name "static");
  
  (* Create configuration file *)
  create_file (Filename.concat name "config.json") default_config_toml;
  
  (* Create default template *)
  create_file (Filename.concat name "templates/default.html") default_template;
  
  (* Create modern stylesheet *)
  create_file (Filename.concat name "static/style.css") modern_css;
  
  (* Create sample content with proper frontmatter *)
  create_file (Filename.concat name "content/index.md") sample_index;
  create_file (Filename.concat name "content/about.md") sample_about;
  create_file (Filename.concat name "content/first-post.md") sample_blog_post;
  
  (* Create README *)
  let readme_content = Printf.sprintf {|# %s

A beautiful static site built with Imber.

## Quick Start

### Build the site
- imber build

### Serve locally
- imber serve --port 3000

### Clean build artifacts
- imber clean


## Project Structure

- `content/` - Your Markdown content files
- `templates/` - HTML templates with placeholders
- `static/` - CSS, images, and other static assets
- `config.json` - Site configuration
- `dist/` - Generated static site (created after build)

## Features

**Modern Design** - Clean, responsive layout
**Fast Performance** - Optimized static generation
**Easy Customization** - Modify templates and styling
**Markdown Support** - Write content in Markdown
**Mermaid Diagrams** - Create beautiful diagrams
**Development Server** - Local preview with live reload

## Customization

1. **Content**: Edit files in `content/` directory
2. **Templates**: Modify HTML templates in `templates/`
3. **Styling**: Update CSS in `static/style.css`
4. **Configuration**: Adjust settings in `config.json`

## Deployment

Your generated site in `dist/` is ready to deploy to:
- Netlify
- Vercel
- GitHub Pages
- Any static hosting service

Built using [Imber](https://github.com/yourusername/imber).
|} name in
  create_file (Filename.concat name "README.md") readme_content;
  
  Printf.printf "Project initialized successfully!\n";
  Printf.printf "\nYour new site includes:\n";
  Printf.printf "   • Modern responsive design\n";
  Printf.printf "   • Sample content with proper frontmatter\n";
  Printf.printf "   • Professional CSS styling\n";
  Printf.printf "   • Mermaid diagram support\n";
  Printf.printf "   • Ready-to-use templates\n";
  Printf.printf "\nNext steps:\n";
  Printf.printf "   cd %s\n" name;
  Printf.printf "   imber build\n";
  Printf.printf "   imber serve\n";
  Printf.printf "\nHappy building!\n"

