---
title: using c-ssg
tags: C, Markdown, Static Sites
github: https://github.com/NorSomething/c-ssg
---

# Using c-ssg to build this site

I wrote `c-ssg` because I was simply bored. It all started from a conversation about having a personal site and what static site generator to use. Anna and Hugo were my first picks but then the thought of me just making one myself came about; and what better langauge to build it on but **C**!

I picked C for this ssg because its funny XD 
> The idea was to build an ssg without using any external libraries for markdown parsing and such. Just the *holy* C standard library and other POSIX headers. 

### What started as a simple pipeline that eats markdowns and spits out html files.. soon became this very opionated static site generator which I personally deem good enough to use it for my on site!

---

## The folders you work in

- `markdowns/` contains the pages you write.
- `markdowns/Blogs/` is a nested section. Each Markdown file becomes a page, and c-ssg also creates a `Blogs.html` page that lists them.
- `site-imgs/` contains images and videos referenced by your Markdown.
- `cssfiles/styles.css` is shared by every generated page.
- `htmlfiles/` is generated output. Edit the Markdown and source assets, then regenerate the HTML.

The generator reads these paths relative to the current working directory. Run it from the root of the website repo.

## Write a page

Create a Markdown file, for example `markdowns/about.md`:

```
---
title: About me
tags: personal, notes
GitHub: https://github.com/NorSomething
---

# About me

This is **my page**. Here is a [link](https://example.com).
```

Front matter is optional, but it must begin at the very top of the file and use `---` on its own line to open and close. `title` sets the browser tab title. `tags` accepts comma-separated values; on section listing pages those tags appear beside the page and can be searched. Any other metadata entry becomes a link in that page's footer, so use a full URL for its value.

The Markdown support is intentionally small: headings, paragraphs, unordered lists, bold and italic text, fenced code blocks, links, checkboxes, blockquotes, and horizontal rules. It is not a full CommonMark implementation. Ordered lists and tables are not supported yet.

## Add images and videos

Put an asset in `site-imgs/`, then reference its filename in Markdown:

```
~img=portrait.png~
~vid=demo.mp4~
```

The filename must match exactly. The generator emits paths that work on pages inside a nested folder as well as root pages, so keep the media files in the top-level `site-imgs/` directory.

## Build and preview

From the website root, build the generator and generate the pages:

```
make -C ../C/c-ssg
../C/c-ssg/c-ssg
cp -r cssfiles htmlfiles/
cp -r site-imgs htmlfiles/
```

Open up any of the html files and you'll see the page!!

You will also notice the top and bottom bars that have been spawned automatically. 

### Top Bar
The top bar basically contains all the sites generated from the markdown files along with the names of the folders inside the `markdown` files directory.

The directory option in the top bar upon clicking: cleanly lists all the generated html files inside that directory along with their tags taken from their frontmatter.

### Bottom Bar
The bottom bar has three main fields: the left, the right and the center.

The **center** is always occupied by the *last updated time* in UTC. This is taken directly from github action's build time while generating the actual site.

The **left** and **right** are customisable *(kinda)*.

Each entry of the **right** region is customizable via the frontmatter. You can add links and names for whatever you want down there!

The **left** region always says `make with love using c-ssg` cuz I need dat publicity :p

---

## Publishing and Conclusion

This site's GitHub Actions workflow checks out the `c-ssg` repository, builds it, generates the pages, copies the CSS and media, and publishes `htmlfiles/` to GitHub Pages whenever `main` is updated. For your own site, update the checkout path in the script or set `CSSG_DIR` to wherever you cloned the generator.

> Check out the entire `deploy.yml` [here!](https://github.com/NorSomething/NorSomething.github.io/blob/main/.github/workflows/deploy.yml)

That is the whole loop: write markdown, add any assets, preview, and push.

And as always feel free to always checkout and contribute to the [repo](https://github.com/NorSomething/cssg)!
