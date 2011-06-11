---
title: Tutorial
---

Why static websites?
--------------------

Modern web frameworks make it easy to create huge dynamic websites. Why would
anyone still care about a static website?

- Static websites are fast, because it's simply files served directly from the
  hard disk.
- Static websites are secure. Nobody has ever found an SQL injection in static
  pages.
- Static websites are easy to deploy. Just copy them to your webhost using
  (S)FTP/rsync/scp and you are done. They work on all webhosts: no CGI or extra
  modules needed for the web server.

Why Hakyll?
-----------

Hakyll is a [Haskell] library meant for creating small-to-medium sized static
websites. It is a powerful publishing tool, precisely because of the power of
Haskell. By using the awesome [pandoc] library, it is able to create your
website from a large variety of input formats.

[Haskell]: http://haskell.org/
[pandoc]: http://johnmacfarlane.net/pandoc/

Features include:

- easy templating system;
- a simple HTTP server for previewing and compiling your website on the go;
- powerful syntax highlighting;
- modules for common items such as tags and feeds;
- easily extensible.

Let's get started!
------------------

We're going to discuss a small brochure site to start with. You can find all
code and files necessary to build this site [right here](/examples/brochure.zip)
-- feel free to look at them as we go trough the tutorial, in fact, it might be
very learnful to have a closer look at the files as we discuss them. There's a
number of files we will use:

    about.rst            A simple page written in RST format
    code.lhs             Another page with some code (which can be highlighted)
    css                  Directory for CSS files
    |- default.css       The main CSS file
    \- syntax.css        CSS file for code syntax highlighting
    hakyll.hs            Our code to generate the site
    images               Directory for images
    \- haskell-logo.png  The logo of my favorite programming language
    index.markdown       A simple page in markdown format
    templates            Directory for templates
    \- default.html      The main template for the site

By default, hakyll will compile everything to the `_site` directory. We can try
this like this:

    [jasper@phoenix] ghc --make hakyll.hs
    [jasper@phoenix] ./hakyll build

Instead of using `build`, we can also use `preview`, which will fire up a
webserver serving the `_site` directory, so have a look!

All files have been compiled, and their output has been placed in the `_site`
directory as illustrated in this diagram:

![Brochure files](/images/brochure-files.png)

No magic is involved at all -- we will precisely study how and why our items are
compiled like that. All of this is specified in the `hakyll.hs` file.

### Images

Let's start of with the `images/haskell-logo.png` file, because the processing
of this file is very simple: it is simply copied to the output directory. Let's
look at the relevant lines in the `hakyll.hs` file:

~~~~~{.haskell}
match "images/*" $ do
    route   idRoute
    compile copyFileCompiler
~~~~~

The first line specifies we will describe the process for compiling everything
in the `images/` folder: hakyll uses globs for this [^pattern].

[^pattern]: A little caveat is that these globs are not `String`s but
    `Pattern`s, so you need the `OverloadedStrings` extension.

We can see two simple rules next: [route] and [compile].

- [route] determines how the input file(s) get mapped to the output files.
  [route] only deals with file names -- not with the actual content!
- [compile], on the other hand, determines how the file content is processed.

[route]: /reference/Hakyll-Core-Rules.html#v:route
[compile]: /reference/Hakyll-Core-Rules.html#v:compile

In this case, we select the [idRoute]: which means the file name will be kept
the same (`_site` will always be prepended automatically). This explains the
name of [idRoute]: much like the `id` function in Haskell, it also maps values
to themselves.

[idRoute]: /reference/Hakyll-Core-Routes.html#v:idRoute

For our compiler, we use [copyFileCompiler], meaning that we don't process the
content at all, we just copy the file.

[copyFileCompiler]: /reference/Hakyll-Core-Writable-CopyFile.html#v:copyFileCompiler

### CSS

If we look at how the two CSS files are processed, we see something which looks
very familiar:

~~~~~{.haskell}
match "css/*" $ do
    route   idRoute
    compile compressCssCompiler
~~~~~

Indeed, the only difference with the images is that have now chosen for
[compressCssCompiler] -- a compiler which *does* process the content. Let's have
a quick look at the type of [compressCssCompiler]:

[compressCssCompiler]: /reference/Hakyll-Web-CompressCss.html#v:compressCssCompiler

~~~~~{.haskell}
compressCssCompiler :: Compiler Resource String
~~~~~

Intuitively, we can see this as a process which takes a `Resource` and produces
a `String`.

- A `Resource` is simply the Hakyll representation of an item -- usually just a
  file on the disk.
- The produced string is the processed CSS.

We can wonder what Hakyll does with the resulting `String`. Well, it simply
writes this to the file specified in the `route`! As you can see, routes and
compilers work together to produce your site.

### Templates

Next, we can see that the templates are compiled:

~~~~~{.haskell}
match "templates/*" $ compile templateCompiler
~~~~~

Let's start with the basics: what is a template? An example template gives us a
good impression:

~~~~~
<html>
    <head>
        <title>Hakyll Example - $title$</title>
    </head>
    <body>
        <h1>$title$</h1>

        $body$
    </body>
</html>
~~~~~

A template is a text file to lay our some content. The content it lays out is
called a page -- we'll see that in the next section. The syntax for templates is
intentionally very simplistic. You can bind some content by referencing the name
of the content *field* by using `$field$`, and that's it.

You might have noticed how we specify a compiler (`compile`), but we don't set
any `route`. Why is this?

Precisely because we don't want to our template to end up anywhere in our site
directory! We want to use it to lay out other items -- so we need to load
(compile) it, but we don't want to give it a real destination.

By using the `templates/*` pattern, we compile all templates in one go.

### Pages

The code for pages looks suspiciously more complicated:

~~~~~~{.haskell}
match (list ["about.rst", "index.markdown", "code.lhs"]) $ do
    route   $ setExtension "html"
    compile $ pageCompiler
        >>> applyTemplateCompiler "templates/default.html"
        >>> relativizeUrlsCompiler
~~~~~~

But we'll see shortly that this actually fairly straightforward. Let's begin by
exploring what a *page* is.

~~~~~~
---
title: Home
author: Jasper
---

So, I decided to create a site using Hakyll and...
~~~~~~

A page consists of two parts: a body, and metadata. As you can see above, the
syntax is not hard. The metadata part is completely optional, this is the same
page without metadata:

~~~~~~
So, I decided to create a site using Hakyll and...
~~~~~~

Hakyll supports a number of formats for the page body. Markdown, HTML and RST
are probably the most common. Hakyll will automatically guess the right format
if you use the right extension for your page.

~~~~~~{.haskell}
match (list ["about.rst", "index.markdown", "code.lhs"]) $ do
~~~~~~

We see a more complicated pattern here. Some sets of files cannot be described
easily by just one pattern, and here the [list] function can help us out. In
this case, we have three specific pages we want to compile.

[list]: /reference/Hakyll-Core-Identifier-Pattern.html#v:list

~~~~~~{.haskell}
route $ setExtension "html"
~~~~~~

For our pages, we do not want to use `idRoute` -- after all, we want to generate
`.html` files, not `.markdown` files or something similar! The [setExtension]
route allows you to simply replace the extension of an item, which is what we
want here.

[setExtension]: /reference/Hakyll-Core-Routes.html#v:setExtension

~~~~~~{.haskell}
compile $ pageCompiler
    >>> applyTemplateCompiler "templates/default.html"
    >>> relativizeUrlsCompiler
~~~~~~

How should we process these pages? A simple compiler such as [pageCompiler],
which renders the page, is not enough, we also want to apply our template.

[pageCompiler]: /reference/Hakyll-Web-Page.html#v:pageCompiler

Different compilers can be chained in a pipeline-like way using Arrows. Arrows
form a complicated subject, but fortunately, most Hakyll users need not be
concerned with the details. If you are interested, you can find some information
on the [Understanding arrows] page -- but the only thing you really *need* to
know is that you can chain compilers using the `>>>` operator.

[Understanding arrows]: http://en.wikibooks.org/wiki/Haskell/Understanding_arrows

The `>>>` operator is a lot like a flipped function composition (`flip (.)`) in
Haskell, with the important difference that `>>>` is more general and works on
all Arrows -- including Hakyll compilers.

Here, we apply three compilers sequentially:

1. We load and render the page using `pageCompiler`
2. We apply the template we previously loaded using [applyTemplateCompiler]
3. We relativize the URL's on the page using [relativizeUrlsCompiler]

[applyTemplateCompiler]: /reference/Hakyll-Web-Template.html#v:applyTemplateCompiler
[relativizeUrlsCompiler]: /reference/Hakyll-Web-RelativizeUrls.html#v:relativizeUrlsCompiler

Relativizing URL's is a very handy feature. It means that we can just use
absolute URL's everywhere in our templates and code, e.g.:

~~~~~{.haskell}
<link rel="stylesheet" type="text/css" href="/css/default.css" />
~~~~~

And Hakyll will translate this to a relative URL for each page. This means we
can host our site at `example.com` and `example.com/subdir` without changing a
single line of code.

More tutorials are in the works...

Various tips and tricks
-----------------------

### Syntax highlighting

Syntax highlighting is enabled by default in Hakyll. However, you also need to
enable it in pandoc. If no syntax highlighting shows up, try

    [jasper@phoenix] cabal install --reinstall -fhighlighting pandoc

### When to rebuild

If you execute a `./hakyll build`, Hakyll will build your site incrementally.
This means it will be very fast, but it will not pick up _all_ changes.

- In case you edited `hakyll.hs`, you first want to compile it again.
- It is generally recommended to do a `./hakyll rebuild` before you deploy your
  site.

After rebuilding your site, all files will look as "modified" to the filesystem.
This means that when you upload your site, it will usually transfer all files --
this can generate more traffic than necessary, since it is possible that some
files were not actually modified. If you use `rsync`, you can counter this using
the `--checksum` option.

Problems
--------

### regex-pcre dependency on Mac OS

Hakyll requires [regex-pcre], which might fail to build on Mac OS. To solve
this problem, make sure the [pcre] C library is installed (via homebrew or
macports). Then install [regex-pcre] using:

    cabal install --extra-include-dirs=/usr/local/include regex-pcre

or

    cabal install --extra-include-dirs=/opt/local/include regex-pcre

...and proceed to install Hakyll the regular way.

[regex-pcre]: http://hackage.haskell.org/package/regex-pcre
[pcre]: http://www.pcre.org/

### "File name does not match module name" on Mac OS

    Hakyll.hs:1:1:
        File name does not match module name:
        Saw: `Main'
        Expected: `Hakyll'

Is an error encountered on Mac OS when `hakyll.hs` is located on a
case-insensitive filesystem. A workaround is to rename it to something that
isn't the name of the module, for example, `site.hs`.
