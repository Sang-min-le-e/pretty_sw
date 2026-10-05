# -*- coding: utf-8 -*-
"""전체 파일 흐름 시각화 페이지(flow.html)를 spec.py의 정류장 목록에서 만든다.

사용법: python3 docs/code-tour/flow.py  ->  docs/code-tour/flow.html
정류장(파일)이 늘거나 바뀌면 spec.py만 고치고 이 스크립트를 다시 돌리면 된다.
각 파일 카드를 누르면 tour.html의 해당 정류장으로 이동한다.
"""
import html, os, sys
sys.dont_write_bytecode = True
sys.path.insert(0, os.path.dirname(__file__))
from spec import STOPS, CHAPTERS

OUT = os.path.join(os.path.dirname(__file__), "flow.html")


def layer(path):
    """파일 경로로 계층(색)을 정한다."""
    if "/presentation/" in path:
        return "ui"
    if "/data/" in path:
        return "data"
    if "/domain/" in path:
        return "domain"
    if path.startswith("lib/core/"):
        return "core"
    if path.startswith("lib/app/widgets/"):
        return "widget"
    return "app"


LAYER_LABEL = {
    "ui": "화면 (presentation)",
    "data": "데이터 접근 (data: provider·저장소)",
    "domain": "모델 (domain)",
    "core": "기반 도구 (core: 서버·저장소)",
    "widget": "공용 위젯 (app/widgets)",
    "app": "앱 뼈대 (main·app·router·theme)",
}

# 장마다 "이 장이 어떤 길로 이어지는지" 한 줄 설명.
CHAPTER_NOTE = {
    1: "앱이 켜지고 로그인 화면에서 서버에 로그인한다. 이름이 비어 있으면 2장, 있으면 3장(홈)으로 간다.",
    2: "처음 로그인한 보호자만 거친다: 이름 저장(PATCH /users/me) → 자녀 등록(POST /children) → 기기 연결 대기 → 홈.",
    3: "로그인 후의 중심 화면. 기기 목록은 서버가 아니라 기기 안 Hive에 저장돼 있다.",
    4: "하단 탭 1번. 루틴은 지금 보는 자녀의 서버 데이터(calendar)이고, 만들 때마다 캐시를 invalidate해서 화면이 갱신된다. 템플릿만 아직 Hive.",
    5: "하단 탭 3번. 이름 변경은 서버(PATCH), 프로필 사진은 기기 안에만 저장한다.",
}

cards_by_ch = {}
for i, st in enumerate(STOPS, 1):
    cards_by_ch.setdefault(st.get("chapter", 1), []).append((i, st))

chapters_html = []
for ch in sorted(cards_by_ch):
    cards = []
    for n, (i, st) in enumerate(cards_by_ch[ch]):
        base = os.path.basename(st["file"])
        folder = os.path.basename(os.path.dirname(st["file"]))
        lay = layer(st["file"])
        cards.append(
            f'<a class="node {lay}" href="tour.html#stop-{i}" title="{html.escape(st["title"])}">'
            f'<span class="num">{i}</span>'
            f'<span class="fn">{html.escape(base)}</span>'
            f'<span class="role">{html.escape(st["role"])}</span>'
            f'<span class="dir">{html.escape(folder)}/</span></a>'
        )
        if n < len(cards_by_ch[ch]) - 1:
            cards.append('<span class="arrow" aria-hidden="true">→</span>')
    chapters_html.append(
        f'<section class="chapter"><header><span class="ch-no">{ch}장</span>'
        f'<h3>{html.escape(CHAPTERS[ch])}</h3>'
        f'<p>{html.escape(CHAPTER_NOTE.get(ch, ""))}</p></header>'
        f'<div class="track">{"".join(cards)}</div></section>'
    )

legend = "".join(
    f'<span class="lg"><i class="sw {k}"></i>{v}</span>' for k, v in LAYER_LABEL.items()
)

PAGE = """<!doctype html>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Tomo 전체 파일 흐름</title>
<style>
:root {
  --bg:#f6f7f9; --surface:#fff; --ink:#1d2330; --muted:#667085; --line:#d8dde6; --accent:#1c8fd6;
  --ui:#e3f3ff; --ui-b:#7cc4f5; --data:#fff1d6; --data-b:#f1c15a; --domain:#e8f6e6; --domain-b:#8fcb87;
  --core:#efe7fb; --core-b:#b79be6; --widget:#ffe6ee; --widget-b:#ef9bb4; --app:#eceff3; --app-b:#aab2c0;
}
@media (prefers-color-scheme: dark) {
  :root:not([data-theme="light"]) {
    --bg:#12151b; --surface:#1b2029; --ink:#e8ebf1; --muted:#98a2b3; --line:#2f3745; --accent:#59b6f0;
    --ui:#14344a; --ui-b:#2f7fae; --data:#43361a; --data-b:#a07f2c; --domain:#1d3a1b; --domain-b:#4f8a49;
    --core:#2d2447; --core-b:#7a5fb8; --widget:#4a2133; --widget-b:#a24e6d; --app:#262c36; --app-b:#566074;
  }
}
* { box-sizing: border-box; }
body { margin:0; background:var(--bg); color:var(--ink); font:15px/1.55 system-ui,-apple-system,"Noto Sans KR",sans-serif; }
.wrap { max-width:1180px; margin:0 auto; padding:28px 16px 64px; }
h1 { font-size:28px; margin:0 0 6px; }
h2 { font-size:20px; margin:40px 0 12px; }
h3 { font-size:17px; margin:0; }
p { margin:4px 0; color:var(--muted); }
a { color:inherit; text-decoration:none; }
code { font-family:ui-monospace,Menlo,monospace; font-size:.92em; background:var(--app); padding:1px 5px; border-radius:5px; }
.card { background:var(--surface); border:1px solid var(--line); border-radius:14px; padding:18px 18px; }

/* 화면 이동 흐름 */
.screens { display:flex; flex-wrap:wrap; align-items:center; gap:8px 6px; }
.scr { background:var(--ui); border:1.5px solid var(--ui-b); border-radius:10px; padding:7px 12px; font-size:13.5px; white-space:nowrap; }
.scr small { display:block; color:var(--muted); font-size:11px; }
.scr.alt { background:var(--data); border-color:var(--data-b); }
.fl-arrow { color:var(--muted); font-size:18px; }
.branch { display:flex; flex-direction:column; gap:6px; }
.row { display:flex; align-items:center; gap:6px; flex-wrap:wrap; }
.tabs { display:grid; grid-template-columns:repeat(4,minmax(0,1fr)); gap:8px; margin-top:10px; }
.tab { background:var(--ui); border:1.5px solid var(--ui-b); border-radius:10px; padding:8px 10px; font-size:13px; }
.tab b { display:block; }
.tab span { color:var(--muted); font-size:12px; }

/* 계층 */
.layers { display:grid; grid-template-columns:repeat(5,minmax(0,1fr)); gap:0; align-items:stretch; }
.lay { padding:12px 10px; text-align:center; border:1.5px solid; font-size:13px; }
.lay b { display:block; font-size:14px; }
.lay span { color:var(--muted); font-size:12px; }
.lay.ui { background:var(--ui); border-color:var(--ui-b); border-radius:12px 0 0 12px; }
.lay.data { background:var(--data); border-color:var(--data-b); }
.lay.domain { background:var(--domain); border-color:var(--domain-b); }
.lay.core { background:var(--core); border-color:var(--core-b); }
.lay.src { background:var(--app); border-color:var(--app-b); border-radius:0 12px 12px 0; }

/* 장별 파일 흐름 */
.legend { display:flex; flex-wrap:wrap; gap:6px 16px; margin:8px 0 4px; font-size:13px; color:var(--muted); }
.lg { display:inline-flex; align-items:center; gap:6px; }
.sw { width:14px; height:14px; border-radius:4px; border:1.5px solid; display:inline-block; }
.chapter { background:var(--surface); border:1px solid var(--line); border-radius:14px; padding:16px; margin-top:14px; }
.chapter header { margin-bottom:12px; }
.ch-no { display:inline-block; background:var(--accent); color:#fff; border-radius:999px; padding:1px 10px; font-size:12px; margin-bottom:4px; }
.track { display:flex; flex-wrap:wrap; align-items:stretch; gap:8px 4px; }
.arrow { align-self:center; color:var(--muted); font-size:18px; }
.node { display:grid; gap:1px; width:158px; padding:8px 10px 8px 34px; border:1.5px solid; border-radius:10px; position:relative; transition:transform .12s, box-shadow .12s; }
.node:hover { transform:translateY(-2px); box-shadow:0 4px 14px rgba(0,0,0,.14); }
.node .num { position:absolute; left:8px; top:8px; width:20px; height:20px; border-radius:50%; background:var(--surface); display:grid; place-items:center; font-size:11px; font-weight:600; }
.node .fn { font-family:ui-monospace,Menlo,monospace; font-size:11.5px; font-weight:600; overflow-wrap:anywhere; }
.node .role { font-size:12px; }
.node .dir { font-size:10.5px; color:var(--muted); }
.node.ui { background:var(--ui); border-color:var(--ui-b); }
.node.data { background:var(--data); border-color:var(--data-b); }
.node.domain { background:var(--domain); border-color:var(--domain-b); }
.node.core { background:var(--core); border-color:var(--core-b); }
.node.widget { background:var(--widget); border-color:var(--widget-b); }
.node.app { background:var(--app); border-color:var(--app-b); }
.sw.ui { background:var(--ui); border-color:var(--ui-b); } .sw.data { background:var(--data); border-color:var(--data-b); }
.sw.domain { background:var(--domain); border-color:var(--domain-b); } .sw.core { background:var(--core); border-color:var(--core-b); }
.sw.widget { background:var(--widget); border-color:var(--widget-b); } .sw.app { background:var(--app); border-color:var(--app-b); }
.note { font-size:13px; }
@media (max-width:720px) {
  .tabs { grid-template-columns:repeat(2,minmax(0,1fr)); }
  .layers { grid-template-columns:1fr; } .lay { border-radius:0 !important; }
  .node { width:calc(50% - 6px); }
}
</style>

<div class="wrap">
  <h1>Tomo 전체 파일 흐름</h1>
  <p>화면이 어떻게 이어지는지, 파일이 어떤 층으로 나뉘는지, 그리고 <a href="tour.html"><b>코드 따라 읽기</b></a>의 56개 파일이 어떤 순서로 이어지는지를 한 장에 모았습니다. 파일 카드를 누르면 그 정류장으로 갑니다.</p>

  <h2>1. 화면 이동 흐름</h2>
  <div class="card">
    <div class="screens">
      <div class="scr">/splash<small>1.5초 로고</small></div><span class="fl-arrow">→</span>
      <div class="scr">/login<small>이메일 로그인 (POST /auth/login)</small></div><span class="fl-arrow">→</span>
      <div class="branch">
        <div class="row"><span class="note">이름 있음 →</span><div class="scr">/ 홈</div></div>
        <div class="row"><span class="note">이름 없음(첫 로그인) →</span>
          <div class="scr alt">guardian-info<small>1/3 보호자 이름</small></div><span class="fl-arrow">→</span>
          <div class="scr alt">child-info<small>2/3 자녀 등록</small></div><span class="fl-arrow">→</span>
          <div class="scr alt">device-connection<small>3/3 기기 연결 대기</small></div><span class="fl-arrow">→</span>
          <div class="scr">/ 홈</div></div>
      </div>
    </div>
    <p class="note" style="margin-top:14px">홈에 도착하면 하단 탭바(<code>bottom_nav_bar.dart</code>)로 네 화면을 오갑니다. 탭은 <code>context.go</code>로 갈아치우고, 그 안의 상세·추가 화면은 <code>context.push</code>로 위에 쌓습니다.</p>
    <div class="tabs">
      <div class="tab"><b>0 · 홈 /</b><span>기기 캐러셀, 연결된 기기, 현재 루틴<br>→ 기기 추가, 연결된 기기</span></div>
      <div class="tab"><b>1 · 루틴 /routine</b><span>달력, 날짜별 카드<br>→ 오늘 할 일, 상세, 추가·수정, 템플릿</span></div>
      <div class="tab"><b>2 · 기기 /devices</b><span>기기 카드 그리드<br>→ 기기 상세, 설정, 통계, 와이파이</span></div>
      <div class="tab"><b>3 · 프로필 /profile</b><span>설정 카드<br>→ 프로필 관리, 사용자 설정, 언어, 로그인 기록</span></div>
    </div>
  </div>

  <h2>2. 데이터가 흐르는 층</h2>
  <div class="card">
    <div class="layers">
      <div class="lay ui"><b>화면</b><span>ConsumerWidget<br><code>ref.watch / read</code></span></div>
      <div class="lay data"><b>provider</b><span>데이터를 꺼내는 손잡이<br><code>*Provider</code>, <code>*Actions</code></span></div>
      <div class="lay data"><b>저장소</b><span>읽기·쓰기 약속<br><code>*Repository</code></span></div>
      <div class="lay core"><b>도구</b><span><code>ApiClient(Dio)</code><br><code>LocalStorageService</code></span></div>
      <div class="lay src"><b>데이터가 사는 곳</b><span>서버(백엔드) · 기기 안 Hive</span></div>
    </div>
    <p class="note" style="margin-top:12px"><b>서버에 있는 것</b>: 로그인, 내 정보(이름), 자녀, 루틴. <b>기기 안(Hive)에만 있는 것</b>: 템플릿, 연결된 기기, 프로필 사진 경로, 로그인 세션(<code>accessUuid</code>). 쓰기가 끝나면 <code>ref.invalidate(목록Provider)</code>로 낡은 캐시를 버려 화면이 새로 그려집니다.</p>
  </div>

  <h2>3. 코드 따라 읽기: 장별 파일 순서</h2>
  <div class="legend">__LEGEND__</div>
  __CHAPTERS__
</div>
"""

page = PAGE.replace("__LEGEND__", legend).replace("__CHAPTERS__", "".join(chapters_html))
open(OUT, "w", encoding="utf-8").write(page)
print("ok", OUT, len(page))
