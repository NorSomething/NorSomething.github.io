---
title: using c-ssg
tags: C, Markdown, Static Sites
github: https://github.com/NorSomething/c-ssg
---

# c-ssg
> A tiny, very opinionated static-site generator written in C, mostly because I was bored and thought it would be funny.

## Prelude
One day I was talking about making a personal website and, naturally, the question of what static-site generator to use came up. Anna and Hugo were my first picks, but then I had the very sensible thought: *what if I just made one myself?*

And what better language to build any personal project than **C** - lord's own programming language.

> The original idea was simple: make an SSG without pulling in a Markdown library or a big framework. Just the *holy* C standard library and a few POSIX headers.

---

## Tech Stack

- C
- The C standard library
- POSIX APIs
- Markdown
- HTML and CSS
- GitHub Actions and GitHub Pages

---

## Why C?

Literally no reason other than it being funny. It was indeed fun to torture myself with markdown parsing using the C standard library :)

---

## Technical Background - the site layout

The generator works with a small, predictable folder layout:

1. `markdowns/` contains the pages I write.
2. `markdowns/Blogs/` is a nested section. Every Markdown file inside becomes a page, and c-ssg also makes a `Blogs.html` page that lists them.
3. `site-imgs/` contains images and videos used by the Markdown files.
4. `cssfiles/styles.css` is the shared stylesheet.
5. `htmlfiles/` is generated output. I do not edit files in there by hand.

The paths are read relative to the website repository root, so the generator should be run from there. The basic rule is simple: write Markdown and add source assets; let c-ssg create the HTML.

### Front matter

Pages can start with a tiny front-matter block:

```
---
title: About me
tags: personal, notes
GitHub: https://github.com/NorSomething
---
```

The block is optional, but if it is used, it must start at the very top of the file and be opened and closed by `---` on its own line. `title` becomes the browser-tab title and `tags` are comma-separated values used and searchable on section listing pages. Other metadata values become links in the page footer, so they should be full URLs.

### Images and videos

Media stays in the top-level `site-imgs/` directory and is referenced by filename:

```
~img=portrait.png~
~vid=demo.mp4~
```

Keeping the assets in one place lets the generated paths work for both root-level pages and pages inside folders such as `Blogs/`.

---

# Basic Working

*cue insane hype aura edit of static sites getting generated*

## Reading the Markdown

For every Markdown file, c-ssg reads the optional front matter first and then handles the rest of the file as page content. It turns the small supported Markdown syntax into HTML and wraps it in the common page layout.

For example, a page like this:

```
# About me

This is **my page**. Here is a [link](https://example.com).
```

becomes a proper HTML page without me having to rewrite the header, navigation, footer, or basic markup every time.

---

## Generating navigation and listings

The generator also looks at the Markdown directory structure. Root-level files become normal pages, while a directory such as `Blogs/` becomes its own listing page. That listing page shows the generated posts and the tags read from their front matter.

This is what powers the top bar too: it contains links to the generated pages and names of the folders inside `markdowns/`. Clicking a directory gives a clean list of the HTML files generated from that directory.

---

## The bottom bar

Every generated page gets a footer with three regions:

1. The **left** always says `make with love using c-ssg` because I need the publicity :p
2. The **center** shows the last-updated time in UTC. During deployment, that comes from the GitHub Actions build time.
3. The **right** is populated from the additional front-matter links, so a page can point to its GitHub repository or anything else relevant.

---

## Building and publishing

From the website root, I build c-ssg, run it, and copy the shared assets into the generated site:

```
make -C ../C/c-ssg
../C/c-ssg/c-ssg
cp -r cssfiles htmlfiles/
cp -r site-imgs htmlfiles/
```

After that, opening any file in `htmlfiles/` is enough to preview the site locally.

For the actual site, a GitHub Actions workflow does the same loop whenever `main` is updated: it checks out c-ssg, builds it, generates the pages, copies the CSS and media, and publishes `htmlfiles/` to GitHub Pages. For another site, update the checkout path in the workflow or set `CSSG_DIR` to the location where c-ssg was cloned.

> Check out the entire `deploy.yml` [here!](https://github.com/NorSomething/NorSomething.github.io/blob/main/.github/workflows/deploy.yml)

---

# Limitations and Conclusion

`c-ssg` works nicely for this site, but it is deliberately tiny and has some very obvious limitations lol.

1. There is no support for *all* of markdown features just yet. I only made c-ssg support a handful of features that I thought I would need in a personal site. Hopefully one day I'll have more support and maybe even full GH Markdown support.

2. The entire flow of this ssg is **very** rigid. The next steps should probably be my lazy ass working on proper templating support.

I hope I get time to keep polishing it and maybe make it useful for more than just my own little corner of the internet.

#### Always feel free to contribute to the project on [Github!](https://github.com/NorSomething/c-ssg)

*until next time, baii!*
