# -*- coding: utf-8 -*-
"""Build the code-reading tour HTML from spec.py + the real source files.

Usage: python3 docs/code-tour/build.py  ->  writes docs/code-tour/tour.html
If code changes and a chunk in spec.py no longer matches the file (line count changed),
the script stops and prints which file/lines to fix in spec.py.
"""
import html, re, sys, os
sys.dont_write_bytecode = True  # keep docs/code-tour free of __pycache__
sys.path.insert(0, os.path.dirname(__file__))
from spec import STOPS, CONCEPTS

# Repo root = two folders up from this script (docs/code-tour/ -> repo).
REPO = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(os.path.dirname(__file__), "tour.html")

KEYWORDS = set("""import class extends implements abstract return final const var void async await
if else try on catch finally throw static get set new this super required factory late
true false null is as in for while switch case default break continue with mixin enum""".split())

TOKEN = re.compile(r"""(?P<c>//.*$)|(?P<s>'(?:\\.|[^'\\])*'|"(?:\\.|[^"\\])*")|(?P<a>@\w+)|(?P<n>\b0x[0-9A-Fa-f]+\b|\b\d+(?:\.\d+)?\b)|(?P<w>[A-Za-z_]\w*)""")

def hl(line):
    out, pos = [], 0
    for m in TOKEN.finditer(line):
        out.append(html.escape(line[pos:m.start()]))
        t = m.group(0); e = html.escape(t)
        if m.group("c"): out.append(f'<span class="tc">{e}</span>')
        elif m.group("s"): out.append(f'<span class="ts">{e}</span>')
        elif m.group("a"): out.append(f'<span class="tk">{e}</span>')
        elif m.group("n"): out.append(f'<span class="tn">{e}</span>')
        else:
            if t in KEYWORDS: out.append(f'<span class="tk">{e}</span>')
            elif t[0].isupper() or (t[0] == "_" and len(t) > 1 and t[1].isupper()): out.append(f'<span class="tt">{e}</span>')
            else: out.append(e)
        pos = m.end()
    out.append(html.escape(line[pos:]))
    return "".join(out) or " "

seen = set()
stops_html, nav_html = [], []
problems = []
for i, st in enumerate(STOPS, 1):
    lines = open(os.path.join(REPO, st["file"]), encoding="utf-8").read().split("\n")
    if lines and lines[-1] == "": lines.pop()
    n = len(lines)
    covered = set()
    rows = []
    for (a, b, note, cks) in st["chunks"]:
        if b > n: problems.append(f"{st['file']}: chunk {a}-{b} beyond {n}"); b = n
        covered.update(range(a, b + 1))
        code = "\n".join(f'<span class="ln">{k}</span>{hl(lines[k-1])}' for k in range(a, b + 1))
        cards = []
        for ck in cks:
            if ck in seen: continue
            seen.add(ck)
            t, body = CONCEPTS[ck]
            cards.append(f'<aside class="concept"><span class="concept-k">새 개념</span><b>{t}</b><p>{body}</p></aside>')
        rng = f"{a}줄" if a == b else f"{a}–{b}줄"
        rows.append(f'<div class="row"><pre class="code"><code>{code}</code></pre>'
                    f'<div class="note"><span class="rng">{rng}</span><p>{note}</p>{"".join(cards)}</div></div>')
    missing = [k for k in range(1, n + 1) if k not in covered and lines[k-1].strip()]
    if missing: problems.append(f"{st['file']}: uncovered non-blank lines {missing}")
    total = len(STOPS)
    prev_btn = f'<button type="button" class="btn ghost" data-go="{i-1}">← 이전 정류장</button>' if i > 1 else '<span></span>'
    next_btn = (f'<button type="button" class="btn" data-go="{i+1}">다음 정류장: {os.path.basename(STOPS[i]["file"])} →</button>'
                if i < total else '<span class="end">1장 끝. 다음 장은 홈 화면부터 이어집니다.</span>')
    stops_html.append(f'''
<article class="stop" id="stop-{i}" data-i="{i}"{'' if i == 1 else ' hidden'}>
  <header class="stop-head">
    <span class="eyebrow">정류장 {i} / {total}</span>
    <h2>{st["title"]}</h2>
    <p class="path"><code>{st["file"]}</code> · {n}줄</p>
    <p class="arrive"><b>어떻게 왔나</b> {st["arrive"]}</p>
  </header>
  <div class="rows">{"".join(rows)}</div>
  <footer class="stop-foot">
    <p class="next-hint"><b>다음으로</b> {st["next_hint"]}</p>
    <div class="pager">{prev_btn}{next_btn}</div>
  </footer>
</article>''')
    nav_html.append(f'<li><a href="#stop-{i}" data-go="{i}"><span class="nav-i">{i}</span><span class="nav-t"><span class="nav-f">{os.path.basename(st["file"])}</span><span class="nav-r">{st["role"]}</span></span></a></li>')

if problems:
    print("\n".join(problems)); sys.exit(1)

glossary = "".join(f'<div class="g"><b>{t}</b><p>{b}</p></div>' for t, b in CONCEPTS.values())

tpl = open(os.path.join(os.path.dirname(__file__), "template.html"), encoding="utf-8").read()
out = tpl.replace("{{NAV}}", "".join(nav_html)).replace("{{STOPS}}", "".join(stops_html)).replace("{{GLOSSARY}}", glossary).replace("{{COUNT}}", str(len(STOPS)))
# The published artifact gets its <head> from the host; a local file needs its own
# charset meta or Korean text renders garbled when opened straight from disk.
HEAD = '<!doctype html>\n<meta charset="utf-8">\n<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">\n'
open(OUT, "w", encoding="utf-8").write(HEAD + out)
print("ok", OUT, len(out))
