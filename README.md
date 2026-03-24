# qtopie.github.io

Personal Blog of site https://qtopie.github.io/

## Configuration

* set git submodule to ssh url

```bash
git submodule set-url themes/amp-blog-theme git@github.com:qtopie/amp-blog-theme.git
```

## Math

https://gohugo.io/content-management/mathematics/

## D2 support in Hugo

- Install D2 CLI locally:

```bash
brew install d2
```

- Write diagrams using fenced code blocks in Markdown:

	```d2
	x -> y: hello
	```

- Optional theme attribute:

	```d2 {theme="200"}
	x -> y: hello
	```

- Build-time behavior:
	- Hugo render hook `themes/drift-blog-theme/layouts/_markup/render-codeblock-d2.html` maps each `d2` code block to `static/diagrams/d2-<hash>.svg`.
	- If the SVG exists, page renders it as `<img>`; if missing, it gracefully falls back to a normal `d2` code block (no build crash).
	- Hash includes diagram source and `theme`, so you can pre-generate stable file names.
	- Local auto-build entrypoint: `./scripts/hugo-with-d2.sh` regenerates D2 diagrams first, then runs `hugo` with the same arguments.

- Recommended local commands:

```bash
./scripts/hugo-with-d2.sh
./scripts/hugo-with-d2.sh --minify
./scripts/hugo-with-d2.sh server
```

- Pre-generate diagram example:

```bash
echo 'x -> y: hello' | d2 --theme 200 - ./static/diagrams/d2-<hash>.svg
```

- CI note:
	- GitHub Actions workflow `/.github/workflows/firebase-hosting-merge.yml` installs D2 before running `./scripts/hugo-with-d2.sh --minify`.
