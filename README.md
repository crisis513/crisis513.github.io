# Son's blog. 

[![MIT Licence](https://badges.frapsoft.com/os/mit/mit.svg?v=103)](https://opensource.org/licenses/mit-license.php)
[![stable](http://badges.github.io/stability-badges/dist/stable.svg)](http://github.com/badges/stability-badges)
[![Open Source Love](https://badges.frapsoft.com/os/v1/open-source.png?v=103)](https://github.com/ellerbrock/open-source-badge/)

![Blog](https://crisis513.github.io)


## Web analytics

I use [Google analytics](https://www.google.com/analytics/) and [GrowingIO](https://www.growingio.com/) to do web analytics, you can choose either to realize it,just register a account and replace id in `_config.yml`.

## Comment

I use [Disqus](https://disqus.com/) to realize comment. You should set disqus_shortname and get public key and then, in `_config.yml`, edit the disqus value to enable Disqus.

## Compress CSS and JS files

All CSS and JS files are compressed at `/static/assets`.

I use [UglifyJS2](https://github.com/mishoo/UglifyJS2), [clean-css](https://github.com/jakubpawlowicz/clean-css) to compress CSS and JS files, customised CSS files are at `_sass` folder which is feature of [Jekyll](https://jekyllrb.com/docs/assets/). If you want to custom CSS and JS files, you need to do the following:

1. Install [NPM](https://github.com/npm/npm) then install **UglifyJS2** and **clean-css**: `npm install -g uglifyjs; npm install -g clean-css`, then run `npm install` at root dir of project.
2. Compress script is **build.js**
3. If you want to add or remove CSS/JS files, just edit **build/build.js** and **build/files.conf.js**, then run `npm run build` at root dir of project, link/src files will use new files.

OR

Edit CSS files at `_sass` folder.

# Testing Locally
To test your site locally, you’ll need

- [ruby](https://www.ruby-lang.org/en/)
- the [github-pages](https://github.com/github/pages-gem) gem

## Installing ruby
There are [lots of different ways to install ruby](https://www.ruby-lang.org/en/documentation/installation/).

In Mac OS X, older versions of ruby will already be installed. But I use the [Ruby Version Manager (RVM)](https://rvm.io/) to have a more recent version. You could also use [Homebrew](https://brew.sh/).

In Windows, use [RubyInstaller](https://rubyinstaller.org/). (In most of this tutorial, I’ve assumed you’re using a Mac or some flavor of Unix. It’s possible that none of this was usable for Windows folks. Sorry!)

## Installing the github-pages gem
Run the following command:

```
gem install github-pages
```

This will install the github-pages gem and all dependencies.

## Later, to update the gem, type:

```
gem update github-pages
```

Testing your site locally
To construct and test your site locally, go into the directory and type

```
jekyll build
```

This will create (or modify) a `_site/ directory`, containing everything from `assets/`, and then the `index.md` and all `pages/*.md` files, converted to html. (So there’ll be `_site/index.html` and the various `_site/pages/*.html.`)

Type the following in order to “serve” the site. This will first run build, and so it does not need to be preceded by `jekyll build`.

```
jekyll serve
```

Now open your browser and go to `http://localhost:4000/site-name/`

# Todo
- [ ] `jekyll server --watch` mode need to use original CSS/JS files
- [ ] User can customise index page's section title.
- [x] Non-github projects also have links.
- [ ] Add some custom color themes for selection(Nav bar, background, words, dominant hue).
