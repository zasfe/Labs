# design.md — HTML 보고서 작성 형식 가이드

이 문서는 결과보고서 HTML 파일을 만들 때 따르는 디자인 시스템 정본이다. **HTML의 형식(골격, 색, 폰트, 컴포넌트, SVG, 조작 스크립트)만** 다루며, 무엇을 쓸지에 대한 콘텐츠 규칙(필수 포함 항목, 입력 문서, 퀴즈 주제 범위 등)은 프로젝트별 콘텐츠 가이드 문서에 따로 둔다.

---

## 1. 파일 골격

`<title>`로 시작하며 `<!DOCTYPE>`, `<html>`, `<head>`, `<body>` 태그는 쓰지 않는다.

```
<title>…</title>                      ← 짧은 명사구다. 보고서 제목이 아니다
<style> … </style>
<div class="wrap"> … </div>           ← 본문
<script> … </script>                  ← 퀴즈와 다이어그램 조작. 맨 끝에 한 번만 둔다
```

외부 리소스는 전혀 쓰지 않는다. `<link>`, `<script src>`, `@import`, 웹폰트, 이미지가 모두 여기에 해당하며, 파일 하나로 완결돼야 오프라인 환경과 사내망에서 동일하게 보인다.

```bash
# 검사 — 전부 0이어야 통과한다 (SVG 내부 url(#…) 참조는 예외)
F=<결과보고서 HTML 경로>
grep -cE '<link|<script[^>]*src=|@import|https?://|\.woff|\.ttf' $F
```

---

## 2. 디자인 토큰

`:root`에 CSS 변수로 팔레트를 정의하고, 다크모드는 반드시 삼중으로 선언한다. 하나라도 빠지면 한쪽 테마가 깨진다.

| 선언 | 용도 |
|---|---|
| `:root` | 라이트 기본값이다. 모든 변수를 여기서 한 번은 정의한다 |
| `@media (prefers-color-scheme: dark) { :root:not([data-theme="light"]) { … } }` | 시스템 다크 모드를 따른다 |
| `:root[data-theme="dark"]` | 사용자가 명시적으로 선택한 값을 우선한다 |

필요한 변수 목록은 다음과 같다.

```
--paper --surface --surface-2 --ink --ink-2 --muted --line --line-soft
--accent --accent-2 --accent-soft --pass --pass-soft --warn --warn-soft --shadow
```

개념 박싱을 색으로 구별해야 한다면 `--plum`/`--plum-soft`처럼 쌍으로 추가한다.

---

## 3. 폰트: OS 내장 폰트만 쓴다

웹폰트를 내려받지 않는다. 브라우저가 글리프 단위로 폴백하므로 스택 하나로도 두 운영체제가 각자 맞는 폰트를 쓰게 된다. macOS는 라틴 문자에 SF Pro를, 한글에 Apple SD Gothic Neo를 쓰고, Windows는 라틴 문자에 Segoe UI를, 한글에 맑은 고딕을 쓴다.

```css
--font-ui:   -apple-system, BlinkMacSystemFont, "Apple SD Gothic Neo",
             "Segoe UI", "Malgun Gothic", system-ui, "Noto Sans KR", sans-serif;
--font-mono: ui-monospace, SFMono-Regular, "SF Mono", "Cascadia Mono",
             Consolas, "D2Coding", "Malgun Gothic", monospace;
```

`Noto Sans KR`과 `D2Coding`은 설치돼 있을 때만 쓰이며, 없으면 조용히 다음 폰트로 넘어갈 뿐 다운로드는 일어나지 않는다.

문서 안의 모든 `font-family`는 이 변수 둘 중 하나를 쓴다. SVG `<text>`도 같은 규칙을 따르며, 폰트명을 직접 적으면 운영체제 한쪽에서 폴백 순서가 어긋난다.

본문 폭은 `max-width: 78ch`로 둔다.

```bash
# 검사 — 이 변수 둘을 벗어난 지정이 없어야 통과한다
grep -n 'font-family:' $F | grep -v 'var(--font'
```

---

## 4. 개념 박싱

용어와 개념을 처음 꺼내는 자리, 그 개념을 설명하는 문단 바로 위에 배치한다.

```html
<div class="concepts two">                     <!-- two = 2열 그리드(680px 이상에서 적용) -->
  <div class="concept c-accent">
    <span class="name">개발 입력 명세</span>     <!-- 명사형 구분, 굵은 글씨로 표시한다 -->
    <span class="gloss">…한 문장 요약…</span>
    <span class="tags"><span class="tag">docs/</span><span class="tag">독자 = Task 4~9</span></span>
  </div>
</div>
```

| 규칙 | 값 |
|---|---|
| 모양 | 둥근 테두리를 가진 네모다. `border-radius: 4px`를 준다 |
| 색 구별 | 상단에만 3px를 준다. `border-top: 3px solid var(--c)`, 나머지 변은 `1px solid var(--line)`로 둔다 |
| 색 지정 | `.concept { --c: var(--accent); --c-soft: var(--accent-soft); }`를 기본값으로 두고, `.c-pass` `.c-warn` `.c-plum` `.c-rust`가 `--c`와 `--c-soft`를 덮어쓰게 한다 |
| 구분(name) | `font-weight: 700`, 제목용 폰트를 쓴다 |
| 태그(tag) | 박싱 처리한다. `border: 1px solid var(--c)`, `background: var(--c-soft)`, `color: var(--c)`, 모노 폰트를 쓴다 |

같은 수준의 박싱이 여럿이면 서로 다른 `--c`를 준다. 하나만 쓸 때는 색을 구별할 필요가 없으므로 기본색을 그대로 쓴다.

---

## 5. SVG 흐름도

정보가 어디서 어디로 이동하는지 보여줘야 할 때만 쓴다. 표로 충분한 내용은 표로 남긴다.

라이브러리는 쓰지 않으며 인라인 SVG와 공용 스크립트만으로 만든다. 조작 스크립트는 92줄이며, 다이어그램이 몇 개든 한 벌만 `<script>` 맨 끝에 둔다.

| 항목 | 값 |
|---|---|
| 외부 의존 | 0개다 |
| 검증 방법 | Chrome에서 pan, zoom, fit view, 테마 전환, 선 흐름 표현의 동작을 직접 확인한다 |
| 알려진 제약 | 모바일 터치다. 한 손가락 드래그만 지원하며 핀치 줌은 넣지 않는다 |

### 5.1 컨테이너 CSS

`:root`의 색 토큰은 2절의 디자인 토큰을 그대로 쓴다. 아래는 다이어그램 전용 규칙이다.

```css
/* ── 컨테이너 ────────────────────────────────────── */
figure.flow{margin:1.8rem 0;background:var(--surface);border:1px solid var(--line);
  border-radius:6px;overflow:hidden;box-shadow:0 1px 2px rgba(0,0,0,.04)}

/* 헤더 — 캔버스 위. 분류 · 결론 · 부연 */
.flow-head{padding:.85rem 1.1rem;border-bottom:1px solid var(--line-soft);
  background:var(--surface-2)}
.flow-eyebrow{margin:0;font-family:var(--font-mono);font-size:.66rem;font-weight:600;
  letter-spacing:.06em;text-transform:uppercase;color:var(--accent)}
.flow-title{margin:.2rem 0 0;font-size:.98rem;font-weight:700;line-height:1.45;color:var(--ink)}
.flow-desc{margin:.35rem 0 0;font-size:.8rem;line-height:1.6;color:var(--muted)}

.flow-stage{position:relative;height:clamp(260px,46vw,380px);touch-action:pan-y}
.flow-stage svg{display:block;width:100%;height:100%}
.flow-stage.pannable{cursor:grab}
.flow-stage.grabbing{cursor:grabbing}

.flow-ctl{position:absolute;right:.5rem;bottom:.5rem;display:flex;gap:.25rem;
  background:var(--surface);border:1px solid var(--line);border-radius:4px;padding:.15rem}
.flow-ctl button{width:26px;height:26px;display:grid;place-items:center;font:inherit;
  font-size:.8rem;color:var(--ink-2);background:transparent;border:0;border-radius:3px;cursor:pointer}
.flow-ctl button:hover{background:var(--surface-2);color:var(--accent)}

/* 힌트 — 우상단. 그림을 가리지 않게 반투명 + 클릭 통과 */
.flow-hint{position:absolute;right:.55rem;top:.55rem;z-index:2;pointer-events:none;
  padding:.1rem .4rem;border:1px solid var(--line);border-radius:3px;
  background:color-mix(in srgb, var(--surface) 70%, transparent);
  font-family:var(--font-mono);font-size:.62rem;letter-spacing:.05em;
  text-transform:uppercase;color:var(--muted)}
@supports (backdrop-filter:blur(2px)){.flow-hint{backdrop-filter:blur(3px)}}

/* ── 간단 노드 ───────────────────────────────────── */
.svg-box{fill:var(--surface-2);stroke:var(--line);stroke-width:1}
.svg-box-a{fill:var(--accent-soft);stroke:var(--accent);stroke-width:1.5}
.svg-box-p{fill:var(--pass-soft);stroke:var(--pass);stroke-width:1.5}
.svg-box-w{fill:var(--warn-soft);stroke:var(--warn);stroke-width:1.5}
.svg-t{fill:var(--ink);font-family:var(--font-mono);font-size:12px;font-weight:500}
.svg-s{fill:var(--muted);font-family:var(--font-ui);font-size:10.5px}

/* ── 확장 노드 ───────────────────────────────────── */
.svg-node{fill:var(--surface)}
.svg-node-edge{fill:none;stroke:var(--line);stroke-width:1}
.svg-cap-a{fill:var(--accent)}      /* 상단 3px 띠 — 강조색별 */
.svg-cap-p{fill:var(--pass)}
.svg-cap-w{fill:var(--warn)}
.svg-nt{fill:var(--ink);font-family:var(--font-mono);font-size:12.5px;font-weight:600}
.svg-nd{fill:var(--muted);font-family:var(--font-ui);font-size:10.5px}
.svg-tag{fill:var(--surface-2);stroke:var(--line);stroke-width:1}
.svg-tag-t{fill:var(--muted);font-family:var(--font-mono);font-size:9px}

/* ── 선 · 라벨 ───────────────────────────────────── */
.svg-line{stroke:var(--line);stroke-width:1.5;fill:none;stroke-linecap:round}
.svg-line-d{stroke:var(--rust);stroke-width:1.5;fill:none;stroke-dasharray:4 3}
.svg-arrow{fill:var(--line)}
.svg-lbl{fill:var(--muted);font-family:var(--font-ui);font-size:10px;
  paint-order:stroke;stroke:var(--surface);stroke-width:4px;stroke-linejoin:round}

/* ── 애니메이션 ──────────────────────────────────── */
.svg-line-flow{stroke-dasharray:6 6;animation:svg-flow 1.2s linear infinite}
@keyframes svg-flow{to{stroke-dashoffset:-12}}

[data-vp]{transition:none}
[data-vp].animate{transition:transform .18s ease-out}

@media (prefers-reduced-motion:reduce){
  .svg-line-flow{animation:none;stroke-dasharray:none}
  [data-vp].animate{transition:none}
}
```

### 5.2 컨테이너 구조: 제목이 위, 그림이 아래

```html
<figure class="flow">
  <figcaption class="flow-head">
    <p class="flow-eyebrow">의존 전이</p>                      <!-- 분류. 모노 폰트, 대문자 -->
    <p class="flow-title">한 함수의 의존이 두 어댑터로 전이된다</p>  <!-- 그림이 말하는 결론 -->
    <p class="flow-desc">…왜 그런지 한두 문장…</p>              <!-- 부연 설명 -->
  </figcaption>

  <div class="flow-stage" data-flow>
    <svg viewBox="0 0 720 404" role="img" aria-label="…결론 한 문장…">
      <defs>
        <!-- 화살촉: SVG마다 고유 id를 준다 -->
        <marker id="ah1" viewBox="-10 -10 20 20" refX="0" refY="0"
                markerWidth="12" markerHeight="12"
                orient="auto-start-reverse" markerUnits="strokeWidth">
          <polyline class="svg-arrow" points="-5,-4 0,0 -5,4 -5,-4"
                    stroke-linecap="round" stroke-linejoin="round"/>
        </marker>
        <!-- 확장 노드마다 clipPath 하나. 크기가 달라 재사용할 수 없다 -->
        <clipPath id="n1"><rect x="250" y="14" width="220" height="98" rx="6"/></clipPath>
      </defs>

      <g data-vp>
        <!-- 확장 노드 -->
        <g clip-path="url(#n1)">
          <rect class="svg-node"  x="250" y="14" width="220" height="98"/>
          <rect class="svg-cap-w" x="250" y="14" width="220" height="3"/>
        </g>
        <rect class="svg-node-edge" x="250" y="14" width="220" height="98" rx="6"/>
        <text class="svg-nt" x="266" y="40">dbms/cli.go</text>
        <text class="svg-nd" x="266" y="58">formatResult 를 여기서 정의한다</text>
        <rect class="svg-tag"   x="266" y="70" width="46" height="16" rx="3"/>
        <text class="svg-tag-t" x="289" y="81" text-anchor="middle">321줄</text>

        <!-- 선 · 라벨 -->
        <path class="svg-line svg-line-flow" d="M 360 112 L 360 164" marker-end="url(#ah1)"/>
        <text class="svg-lbl" x="360" y="138" text-anchor="middle"
              dominant-baseline="middle">재노출</text>

        <!-- 간단 노드 -->
        <rect class="svg-box" x="46" y="372" width="168" height="30" rx="5"/>
        <text class="svg-t" x="130" y="392" text-anchor="middle">httpapi</text>
      </g>
    </svg>

    <div class="flow-hint">드래그로 이동 · Ctrl/⌘+휠로 확대</div>
    <div class="flow-ctl">
      <button type="button" data-zoom="in"  title="확대" aria-label="확대">+</button>
      <button type="button" data-zoom="out" title="축소" aria-label="축소">−</button>
      <button type="button" data-zoom="fit" title="전체 보기" aria-label="전체 보기">⤢</button>
    </div>
  </div>
</figure>
```

| 규칙 | 내용 |
|---|---|
| 제목 위치 | 캔버스 위에 둔다. 그림을 보기 전에 무엇을 보는지 알아야 하므로, 아래에 캡션을 다시 두지 않는다 |
| 제목 태그 | `<p class="flow-title">`를 쓴다. `<h3>`는 쓰지 않는다. 보고서 소절 제목과 같은 레벨로 끼어들어 문서 개요를 흐리게 만들기 때문이다 |
| 3단 구성 | 분류(eyebrow), 결론(title), 부연(desc) 순서로 두며, 셋 다 같은 폭으로 흐르게 한다(`max-width`를 걸지 않는다) |
| 도형 묶음 | 모든 도형을 `<g data-vp>` 하나에 담는다. 조작 스크립트는 이 요소의 `transform`만 바꾼다 |

### 5.3 노드: 두 종류를 구분해 쓴다

| 종류 | 언제 쓰는가 | 담는 것 |
|---|---|---|
| 확장 노드 | 그 지점에 설명이 필요할 때 | 상단 색선, 제목, 설명, 태그 |
| 간단 노드 | 존재만 보이면 될 때 | 이름 한 줄 |

한 그림에서 둘을 섞어 어디가 읽어야 할 지점인지 시선을 유도한다. 전부 확장 노드로 만들면 강조가 사라진다.

확장 노드는 상단 3px 색선으로 구별한다. 개념 박싱과 같은 규칙이다. 다만 SVG에서는 둥근 모서리 위에 사각 띠를 그대로 얹으면 좌우 상단이 삐져나오므로, `clipPath`로 잘라낸다.

**확장 노드 좌표 규칙**(`x`, `y`, `w`, `h` 기준)

| 요소 | 좌표 |
|---|---|
| 배경, 띠, 테두리, clipPath | 네 값이 전부 같아야 한다. `rx`는 테두리와 clipPath에만 준다 |
| 제목 | `x+16`, `y+26` |
| 설명 | `x+16`, `y+44` |
| 태그 줄 | `x+16`, `y+56`이며, 높이는 16, 태그 사이 간격은 6이다 |

| 규칙 | 내용 |
|---|---|
| 정렬 | 텍스트는 좌측 정렬로 한다. 중앙 정렬은 간단 노드에만 쓴다 |
| 모서리 | 확장 노드는 `rx="6"`, 간단 노드는 `rx="5"`로 준다 |
| 태그 개수 | 노드당 3개 이하로 한정하며, 짧은 고정 문구만 쓴다 |

**태그 폭 계산**: SVG는 텍스트 폭을 자동으로 계산하지 않으므로 rect 폭을 손으로 적어야 한다. 아래 근사식을 쓴다(`.svg-tag-t`가 9px 모노일 때의 값이다).

```
폭 ≈ (라틴 글자수 × 5.4) + (한글 글자수 × 9) + 12
```

글자 수가 자주 바뀌는 값은 태그로 만들지 않는다.

### 5.4 연결선

| 규칙 | 내용 |
|---|---|
| 방향 | 수평, 수직만 쓴다. 대각선은 쓰지 않는다 |
| 코너 | 둥글게 꺾으며, 반지름 `r=8`을 `Q` 명령으로 준다 |
| 화살촉 | `<marker>`를 SVG마다 고유 id로 둔다(`ah1`, `ah2` 등). id가 겹치면 한 SVG만 렌더된다 |

화살촉 마커의 속성은 다음과 같다.

```
viewBox="-10 -10 20 20" refX="0" refY="0" orient="auto-start-reverse" markerUnits="strokeWidth"
<polyline points="-5,-4 0,0 -5,4 -5,-4" stroke-linecap="round" stroke-linejoin="round"/>
```

둥근 꺾은선 경로식이다. 소스 하단 중앙 `(cx,y1)`에서 중간선 `ym`을 지나 대상 상단 중앙 `(tx,y2)`로 이어진다.

```
sx = (tx > cx) ? +1 : -1
r  = min(8, |tx-cx|/2, |ym-y1|, |y2-ym|)      ← 구간이 짧으면 반지름을 줄인다

M {cx} {y1}
L {cx} {ym-r}    Q {cx} {ym} {cx+sx*r} {ym}    ← 첫째 코너
L {tx-sx*r} {ym} Q {tx} {ym} {tx} {ym+r}      ← 둘째 코너
L {tx} {y2}
```

`tx == cx`(직진)면 코너가 없으므로 `M {cx} {y1} L {cx} {y2}`로 둔다. `r` 가드를 빼면 짧은 구간에서 곡선이 서로 파고들어 선이 뒤집힌다.

좌표를 손으로 계산하지 말고 아래 생성기를 쓴다.

```python
def rounded_step(cx, y1, tx, y2, ym, r=8):
    if tx == cx:
        return f"M {cx} {y1} L {cx} {y2}"
    sx = 1 if tx > cx else -1
    rr = min(r, abs(tx-cx)/2, abs(ym-y1), abs(y2-ym))
    return (f"M {cx} {y1} L {cx} {ym-rr} Q {cx} {ym} {cx+sx*rr} {ym} "
            f"L {tx-sx*rr} {ym} Q {tx} {ym} {tx} {ym+rr} L {tx} {y2}")
```

좌분기, 우분기, 직진, 근접 4가지 경우를 검증한 결과 대각선 세그먼트가 0개였으며, 근접(수평 6px)한 경우 `r`이 8에서 3으로 자동 축소됐다.

### 5.5 선 위 라벨

배경 사각형을 따로 그리지 않는다. `paint-order: stroke`로 글자 뒤에 배경색 테두리를 깔면 선이 저절로 끊겨 보이며, 글자 수가 바뀌어도 좌표를 다시 계산할 필요가 없어진다.

```css
.svg-lbl{fill:var(--muted);font-family:var(--font-ui);font-size:10px;
  paint-order:stroke;stroke:var(--surface);stroke-width:4px;stroke-linejoin:round}
```

```html
<text class="svg-lbl" x="360" y="264" text-anchor="middle" dominant-baseline="middle">2곳</text>
```

| 규칙 | 내용 |
|---|---|
| 배치 | 선 위 중앙에 둔다. `text-anchor="middle"`과 `dominant-baseline="middle"`을 함께 쓴다 |
| 분기 라벨 | 갈라지기 전 수직 구간에 둔다. 코너나 분기점 위에 놓으면 두 선과 겹쳐 읽기 어려워진다 |
| 일관성 | 한 그림 안에서 어떤 라벨은 선 옆에, 어떤 라벨은 선 위에 두는 식으로 섞지 않는다 |

### 5.6 색과 반응형

| 규칙 | 내용 |
|---|---|
| 색 | CSS 클래스로만 준다: `.svg-box`, `.svg-box-a/p/w/r/m`(강조색별), `.svg-t`(제목), `.svg-s`(부연), `.svg-line`, `.svg-line-d`(점선), `.svg-arrow`, `.svg-lbl`. `fill`과 `stroke`를 인라인으로 쓰지 않는다. 다크모드에서 보이지 않게 되기 때문이다 |
| 박스 색 구별 | 테두리 색으로 준다. 상단 3px 띠는 간단 노드에 쓰지 않는다. `rx`로 둥글린 모서리 위에 사각 띠를 얹으면 좌우 상단이 삐져나오며, 이 표현은 확장 노드 전용이다 |
| 크기 | `viewBox`만 지정하고 `width`와 `height`는 쓰지 않는다. 캔버스 높이는 `clamp(260px, 46vw, 380px)`로 둔다 |
| 가로 스크롤 | 두지 않는다. fit view가 그 역할을 대신한다 |
| 접근성 | `role="img"`과 `aria-label`을 주며, 그림이 말하는 결론을 한 문장으로 적는다 |

### 5.7 애니메이션: 두 가지만 허용한다

보고서는 정지 화면에서 읽는 문서이므로 시선을 뺏는 움직임은 방해가 된다. 아래 둘 외에는 쓰지 않는다. 진입 페이드인, 노드 펄스, 자동 순회는 모두 금지한다.

**(1) 버튼 조작 시 전환**. 클릭 한 번에 화면이 순간이동하면 무엇이 어디로 갔는지 놓친다.

```css
[data-vp]{transition:none}
[data-vp].animate{transition:transform .18s ease-out}
```

드래그와 휠에는 전환을 걸지 않는다. 전환이 끼면 커서를 따라오지 못해 끈적거리게 되므로, 조작 함수가 `animate` 인자를 받아 버튼일 때만 `true`를 넘긴다.

**(2) 선 흐름 표현**. 방향을 보여줘야 하는 선에만 붙이며, 한 그림에 한두 개까지만 쓴다.

```css
.svg-line-flow{stroke-dasharray:6 6;animation:svg-flow 1.2s linear infinite}
@keyframes svg-flow{to{stroke-dashoffset:-12}}
```

나머지 선은 정적으로 두어야 대비가 살아난다. 전부 흐르게 하면 아무것도 강조되지 않는다.

**(3) `prefers-reduced-motion`을 반드시 존중한다**. 전정기관 문제로 움직임을 끈 사용자가 있기 때문이다.

```css
@media (prefers-reduced-motion:reduce){
  .svg-line-flow{animation:none;stroke-dasharray:none}   /* 실선으로 되돌린다 */
  [data-vp].animate{transition:none}
}
```

`stroke-dasharray`까지 함께 꺼야 한다. 애니메이션만 멈추면 이유 없는 점선이 남는다.

### 5.8 조작: pan, zoom, fit view

정적 시각 요소는 SVG만으로 되지만, 조작에는 스크립트가 필요하다. 외부 의존은 없다.

| 동작 | 규칙 |
|---|---|
| 이동 | 드래그로 처리한다. `pointerdown`/`pointermove`/`pointerup`으로 마우스, 터치, 펜을 함께 받는다 |
| 확대 | `Ctrl`/`⌘`와 함께 휠을 굴릴 때만 동작한다. 맨 휠은 페이지 스크롤로 흘려보낸다. 보고서는 세로로 긴 문서이므로 다이어그램이 스크롤을 가로채면 읽기가 나빠지기 때문이다 |
| 전체 보기 | `⤢` 버튼으로 처리한다. 내용의 `getBBox()`를 여백 12 안에 중앙 정렬한다 |
| 배율 한계 | `0.4`에서 `4`까지로 둔다 |
| 힌트 | 우상단에 반투명 배경과 `pointer-events:none`으로 둬 그림을 가리지 않게 한다 |
| 컨트롤 | 우하단에 `+`, `−`, `⤢` 버튼을 두며, `title`과 `aria-label`을 단다 |
| 터치 | 한 손가락 드래그만 지원한다. 핀치 줌은 넣지 않으며 `⤢` 버튼으로 대신한다 |

구현의 핵심은 두 가지다. 첫째는 포인터 아래 지점을 고정한 채 배율만 바꾸는 계산이다.

```js
tx = p.x - (p.x - tx) * (nk / k);
ty = p.y - (p.y - ty) * (nk / k);
```

둘째는 fit view이며, 측정 전에 변환을 초기화해야 bbox가 원래 크기로 나온다.

```js
k = 1; tx = 0; ty = 0; apply();
const b = vp.getBBox();
k  = Math.min((vb.width - 24) / b.width, (vb.height - 24) / b.height, MAX);
tx = (vb.width  - b.width  * k) / 2 - b.x * k;
ty = (vb.height - b.height * k) / 2 - b.y * k;
```

`getBBox()`는 레이아웃이 끝나야 값이 나오므로, `document.fonts?.ready.then(fit)`으로 폰트 로딩 뒤에 한 번 더 맞춘다.

`<script>` 맨 끝에 아래 코드를 한 번만 둔다. `[data-flow]`를 전부 순회하므로 다이어그램이 몇 개든 한 벌이면 된다.

```js
// 다이어그램 pan / zoom / fit view — 외부 의존 0
document.querySelectorAll('[data-flow]').forEach(stage => {
  const svg = stage.querySelector('svg');
  const vp  = stage.querySelector('[data-vp]');
  if (!svg || !vp) return;

  const MIN = 0.4, MAX = 4;
  let k = 1, tx = 0, ty = 0;

  // animate=true 는 버튼 조작에서만. 드래그·휠에 전환을 걸면 커서를 못 따라온다.
  const apply = (animate) => {
    vp.classList.toggle('animate', !!animate);
    vp.setAttribute('transform', `translate(${tx} ${ty}) scale(${k})`);
  };

  // viewBox 좌표계로 환산한 포인터 위치
  const toLocal = e => {
    const r = svg.getBoundingClientRect();
    const vb = svg.viewBox.baseVal;
    return {
      x: (e.clientX - r.left) / r.width  * vb.width,
      y: (e.clientY - r.top)  / r.height * vb.height
    };
  };

  const zoomAt = (p, nk, animate) => {
    nk = Math.min(MAX, Math.max(MIN, nk));
    tx = p.x - (p.x - tx) * (nk / k);      // 포인터 아래 지점을 고정한 채 배율만 바꾼다
    ty = p.y - (p.y - ty) * (nk / k);
    k = nk;
    apply(animate);
  };

  function fit(animate) {
    k = 1; tx = 0; ty = 0; apply(false);    // 측정 전에 변환을 초기화한다
    const b  = vp.getBBox();
    const vb = svg.viewBox.baseVal;
    if (!b.width || !b.height) return;
    const pad = 12;
    k = Math.min((vb.width - pad * 2) / b.width, (vb.height - pad * 2) / b.height, MAX);
    tx = (vb.width  - b.width  * k) / 2 - b.x * k;
    ty = (vb.height - b.height * k) / 2 - b.y * k;
    apply(animate);
  }

  // 휠: Ctrl/⌘ 을 누른 경우에만 확대. 문서 스크롤을 빼앗지 않는다.
  stage.addEventListener('wheel', e => {
    if (!e.ctrlKey && !e.metaKey) return;
    e.preventDefault();
    zoomAt(toLocal(e), k * (e.deltaY < 0 ? 1.12 : 1 / 1.12), false);
  }, { passive: false });

  // 드래그: 포인터 이벤트 하나로 마우스·터치·펜을 함께 받는다
  let drag = null;
  stage.classList.add('pannable');
  stage.addEventListener('pointerdown', e => {
    if (e.button !== 0 || e.target.closest('button')) return;
    drag = { x: e.clientX, y: e.clientY, tx, ty };
    stage.setPointerCapture(e.pointerId);
    stage.classList.add('grabbing');
  });
  stage.addEventListener('pointermove', e => {
    if (!drag) return;
    const r  = svg.getBoundingClientRect();
    const vb = svg.viewBox.baseVal;
    tx = drag.tx + (e.clientX - drag.x) / r.width  * vb.width;
    ty = drag.ty + (e.clientY - drag.y) / r.height * vb.height;
    apply(false);
  });
  const end = e => {
    if (!drag) return;
    drag = null;
    stage.classList.remove('grabbing');
    if (stage.hasPointerCapture?.(e.pointerId)) stage.releasePointerCapture(e.pointerId);
  };
  stage.addEventListener('pointerup', end);
  stage.addEventListener('pointercancel', end);

  // 버튼 = 부드럽게. 확대 중심은 viewBox 중앙 — 좌표를 박아 두면 다른 그림에서 어긋난다.
  const center = () => {
    const vb = svg.viewBox.baseVal;
    return { x: vb.width / 2, y: vb.height / 2 };
  };
  stage.querySelector('[data-zoom="in"]').onclick  = () => zoomAt(center(), k * 1.25, true);
  stage.querySelector('[data-zoom="out"]').onclick = () => zoomAt(center(), k / 1.25, true);
  stage.querySelector('[data-zoom="fit"]').onclick = () => fit(true);

  // getBBox 는 레이아웃이 끝나야 값이 나온다. 폰트 로딩 뒤 한 번 더 맞춘다.
  fit(false);
  document.fonts?.ready.then(() => fit(false));
});
```

---

## 6. 확인용 퀴즈 UI 사양

퀴즈가 다룰 주제의 범위는 콘텐츠 규칙이므로 프로젝트별 콘텐츠 가이드 문서를 따른다. 아래는 UI 동작 형식만 규정한다.

| 항목 | 값 |
|---|---|
| 문항 수 | 5개다 |
| 데이터 | `<script>`의 `QUESTIONS = [{ q, opts:[4], answer:index, why }]`로 둔다 |
| 채점 | 보기를 클릭한 즉시 처리한다. 정답은 `.correct`(체크 표시, pass색)로, 선택한 오답은 `.wrong`(엑스 표시, warn색)으로, 나머지는 `.dimmed`로 표시하며, 클릭 뒤에는 모든 보기를 `disabled`로 둔다 |
| 해설 | 선택 직후 `.explain`을 노출한다(`hidden` 속성을 해제한다). 왜 그것이 답인지와 오답이 왜 그럴듯한지를 함께 적는다 |
| 저장 | `localStorage`에 프로젝트와 보고서를 구분할 수 있는 고유 키(예: `<project>-<report-id>-quiz`)로 저장한다. 읽기와 쓰기 양쪽 다 try/catch로 감싼다. 사생활 보호 창에서는 접근이 예외를 던지기 때문이다 |
| 점수판 | `position: sticky; bottom: 1rem`으로 둔다. `진행 n / 5 · 정답 n` 형태로 표시하며, 만점이면 `.pass` 클래스를 준다 |
| 리셋 | "다시 풀기" 버튼을 두며, 누르면 상태를 초기화하고 퀴즈 상단으로 스크롤한다 |

---

## 7. 공통 요소 클래스

| 클래스 | 용도 |
|---|---|
| `.term` | 명령과 출력 블록이다. `<header>`와 `<pre>`로 구성하며, `.ok`(초록), `.bad`(빨강), `.dim`(회색) 스팬을 쓴다 |
| `.gates` / `.gate` | 게이트 결과 목록이며, 체크 표시와 항목명, 값을 함께 적는다 |
| `.callout` / `.callout.warn` | 인용과 경고이며, 좌측에 3px 강조선을 준다 |
| `.tbl-scroll` | 모든 `<table>`을 감싸며, 표가 넓어도 페이지 자체는 가로 스크롤되지 않게 한다 |
| `.chip` / `.chip--done` | 머리말의 메타 배지다 |
| `figure.flow` | 다이어그램 컨테이너이며, `overflow: hidden`을 준다 |
| `.flow-head` / `.flow-eyebrow` / `.flow-title` / `.flow-desc` | 캔버스 위 헤더 3단이다 |
| `.flow-stage` | 캔버스이며, `position: relative`, `height: clamp(260px,46vw,380px)`, `touch-action: pan-y`를 준다 |
| `.flow-hint` / `.flow-ctl` | 조작 안내(우상단)와 확대·축소·전체보기 버튼(우하단)이다 |
| `footer` | 파일 경로, 브랜치, Issue 번호를 적는다 |

---

## 8. 커밋 전 검증

브라우저 없이 확인할 수 있는 항목이다. 파일을 커밋하기 전에 모두 돌린다.

```bash
F=<결과보고서 HTML 경로>

# 외부 리소스 0건 (SVG 내부 url(#…) 은 제외)
grep -cE '<link|<script[^>]*src=|@import|https?://|\.woff|\.ttf' $F

# marker id 중복 — 겹치면 한 SVG 만 렌더된다
grep -oE 'id="ah[0-9]+"' $F | sort | uniq -d

# SVG 인라인 색 — 다크모드에서 안 보인다
grep -E '<(rect|path|text)' $F | grep -E '(fill|stroke)="[^u]'

# 모든 <svg> 에 role·aria-label
diff <(grep -c '<svg viewBox' $F) <(grep -c 'role="img" aria-label=' $F)

# 폰트 직접 지정 — 변수만 써야 한다
grep -n 'font-family:' $F | grep -v 'var(--font'
```

대각선 검사는 아래 스크립트로 확인한다. 모든 `L` 세그먼트가 수평이거나 수직이어야 하며, 결과 목록이 비어 있어야 통과다.

```python
def check(d):
    toks = d.replace(',', ' ').split()
    i, cur, bad = 0, None, []
    while i < len(toks):
        c = toks[i]
        if c == 'M':   cur = (float(toks[i+1]), float(toks[i+2])); i += 3
        elif c == 'L':
            nxt = (float(toks[i+1]), float(toks[i+2]))
            if cur and nxt[0] != cur[0] and nxt[1] != cur[1]: bad.append((cur, nxt))
            cur = nxt; i += 3
        elif c == 'Q': cur = (float(toks[i+3]), float(toks[i+4])); i += 5
        else: i += 1
    return bad          # 비어 있어야 통과
```

clipPath 좌표가 배경·띠·테두리 rect와 정확히 같은지도 함께 확인한다.

---

## 9. 최종 체크리스트

- [ ] `<title>`로 시작하고 `<!DOCTYPE>`, `<html>`, `<head>`, `<body>`가 없는가
- [ ] 외부 리소스가 0건인가 (`<link>`, `<script src>`, `@import`, 웹폰트, 이미지)
- [ ] 디자인 토큰이 라이트, 시스템 다크, 명시적 다크 3중으로 선언됐는가
- [ ] 폰트가 `--font-ui`와 `--font-mono` 변수만 쓰는가
- [ ] 개념 박싱이 설명 문단 바로 위에 있고, 상단 3px 색선으로 구별되는가
- [ ] SVG 흐름도의 선이 전부 수평, 수직이며 marker id가 중복되지 않는가
- [ ] SVG `fill`·`stroke`가 인라인이 아니라 CSS 클래스로만 지정됐는가
- [ ] 조작 스크립트가 다이어그램 개수와 무관하게 한 벌만 있는가
- [ ] 애니메이션이 버튼 전환과 선 흐름 2가지로 한정되고 `prefers-reduced-motion`을 존중하는가
- [ ] 퀴즈 UI가 5문항, 즉시 채점, `localStorage` 저장, 점수판, 리셋을 모두 갖췄는가
- [ ] 8절의 검증 명령을 모두 돌려 통과했는가
