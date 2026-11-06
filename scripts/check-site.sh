#!/bin/sh
set -eu
ROOT=$(cd "$(dirname "$0")/.." && pwd)
OUT=$(mktemp -d)
B=$(mktemp -d)
D=$(mktemp -d)
trap 'rm -rf "$OUT" "$B" "$D"' EXIT
fail() { echo "FAIL: $*" >&2; exit 1; }

hugo --source "$ROOT" --destination "$OUT" --quiet
have() { grep -qF -- "$2" "$OUT/$1" || fail "$1 is missing: $2"; }
absent() { ! grep -qF -- "$2" "$OUT/$1" || fail "$1 unexpectedly contains: $2"; }

have index.html 'We build <span class="thesis-accent">tools</span>'
have index.html 'class="product-grid"'
have index.html 'Ticklog'
have index.html 'Simulor'
have index.html 'Machine Learning'
have index.html 'Quantitative Finance'
have index.html 'LLM Engineering'
have index.html 'href="/blog/"'
have index.html 'href="https://github.com/tensorbinge"'
have index.html 'rel="canonical" href="https://tensorbinge.com/"'
absent index.html 'class="post-row"'
have blog/index.html 'No posts yet.'
have styles.css '--color-bg:       #faf8f5'
have styles.css '.post-row'
have styles.css '.post-title'
have styles.css '.prose code'
have styles.css '@view-transition'
have styles.css 'view-transition-name: wordmark'
have styles.css 'prefers-reduced-motion'
have robots.txt 'Sitemap: https://tensorbinge.com/sitemap.xml'
have sitemap.xml 'https://tensorbinge.com/blog/'
have blog/index.xml '<rss'
have llms.txt '## Writing'
for f in $(find "$OUT" -name '*.html'); do
  grep -q '<script src=' "$f" && fail "$f contains an external script"
  grep -q 'type="text/javascript"' "$f" && fail "$f contains executable JavaScript"
done
sh -n "$ROOT/publish.sh" || fail "publish.sh has a syntax error"
grep -q 'v0\\.166\\.0' "$ROOT/publish.sh" || fail "publish.sh does not pin Hugo 0.166.0"
grep -q 'hugo --minify --gc' "$ROOT/publish.sh" || fail "publish.sh does not minify"

# Fixture site: pagination, tags, math rendering, and draft exclusion.
cp -R "$ROOT/hugo.toml" "$ROOT/layouts" "$ROOT/static" "$B/"
mkdir -p "$B/content/blog"
i=1
while [ $i -le 21 ]; do
  mkdir -p "$B/content/blog/p$i"
  printf -- '---\ntitle: "Post %s"\ndate: 2026-0%s-01\ntags: ["rust"]\n---\nBody\n' \
    "$i" "$((i % 9 + 1))" > "$B/content/blog/p$i/index.md"
  i=$((i + 1))
done
mkdir -p "$B/content/blog/special"
printf -- '---\ntitle: "Special"\ndate: 2026-01-01\ntags: ["C#", "ML & AI"]\n---\nBody\n' \
  > "$B/content/blog/special/index.md"
mkdir -p "$B/content/blog/math-fixture"
printf -- '---\ntitle: "Math fixture"\ndate: 2026-01-03\n---\nInline $E = mc^2$ math.\n' \
  > "$B/content/blog/math-fixture/index.md"
mkdir -p "$B/content/blog/draft-post"
printf -- '---\ntitle: "Draft fixture"\ndate: 2026-01-02\ntags: ["drafttag"]\ndraft: true\n---\nDraft body.\n' \
  > "$B/content/blog/draft-post/index.md"

hugo --source "$B" --quiet
haveB() { grep -qF -- "$2" "$B/public/$1" || fail "$1 is missing: $2"; }
absentB() { ! grep -qF -- "$2" "$B/public/$1" || fail "$1 unexpectedly contains: $2"; }
haveB blog/index.html 'Page 1 of 2'
haveB blog/index.html 'rel="canonical" href="https://tensorbinge.com/blog/"'
haveB blog/page/2/index.html 'rel="canonical" href="https://tensorbinge.com/blog/page/2/"'
haveB blog/page/2/index.html 'property="og:url" content="https://tensorbinge.com/blog/page/2/"'
haveB blog/page/2/index.html '"url": "https://tensorbinge.com/blog/page/2/"'
haveB blog/page/1/index.html 'url=https://tensorbinge.com/blog/'
haveB tags/rust/index.html 'Tagged: rust'
haveB blog/math-fixture/index.html '<math'
haveB blog/index.html '<p class="post-summary">'
[ ! -e "$B/public/categories" ] || fail "categories taxonomy was generated"
for u in $(grep -ho 'class="tag" href="[^"]*"' "$B/public/blog/index.html" "$B/public/blog/page/2/index.html" \
  | sed 's/.*href="//; s/"$//; s/%23/#/g'); do
  [ -f "$B/public$u/index.html" ] || fail "tag link does not resolve: $u"
done
absentB blog/index.html 'Draft fixture'
absentB sitemap.xml 'draft-post'
[ ! -e "$B/public/tags/drafttag" ] || fail "draft produced a tag page"

hugo --source "$B" --destination "$D" --buildDrafts --quiet
haveD() { grep -qF -- "$2" "$D/$1" || fail "$1 (drafts) is missing: $2"; }
grep -rqF -- 'Draft fixture' "$D/blog" || fail "draft post is missing from the draft build"
haveD blog/draft-post/index.html '<h1 class="post-title">Draft fixture</h1>'
haveD blog/draft-post/index.html 'class="post-meta"'
haveD blog/draft-post/index.html 'aria-current="page"'
absentD() { ! grep -qF -- "$2" "$D/$1" || fail "$1 (drafts) unexpectedly contains: $2"; }
absentD index.html 'class="post-row"'

echo "OK"
