# 01. 전하고 싶은 메시지 any

## 슬라이드 제목 slide title

슬라이드 전체 주제를 한 문장으로 적습니다. 첫 페이지 커버에도 반영됩니다.

> 예시: 2026년 2분기 영업 전략 공유 / 신규 고객 전환율 개선 방안

```markdown
[Concept]Large headings readable during projection, generous spacing, and one clear theme per slide
```

```markdown
[Concept]Large headings readable during projection, generous spacing, and one clear theme per slide. Slide deck theme: "[슬라이드 제목 slide title/시작] 2026년 2분기 영업 전략 공유 [슬라이드 제목 slide title/끝]"
```


## 대상 target

누구를 위한 발표인지 한 줄로 적습니다.
 
> 예시: 팀장급 실무 리더 / 영업·마케팅 담당자 / 경영진 보고 대상

```markdown
[Concept]Large headings readable during projection, generous spacing, and one clear theme per slide. Slide deck theme: "[슬라이드 제목 slide title/시작] 2026년 2분기 영업 전략 공유 [슬라이드 제목 slide title/끝]"

[Language Rule]
Main body copy should be Korean. Use concise English for section labels, short catchphrases, metrics, product terms, and key business keywords. The result should feel naturally Korean-led with selective English emphasis.
```


```markdown
[Concept]Large headings readable during projection, generous spacing, and one clear theme per slide. Slide deck theme: "[슬라이드 제목 slide title/시작] 2026년 2분기 영업 전략 공유 [슬라이드 제목 slide title/끝]"

[Target][대상 target/시작] 팀장급 실무 리더 [대상 target/끝]

[Language Rule]
Main body copy should be Korean. Use concise English for section labels, short catchphrases, metrics, product terms, and key business keywords. The result should feel naturally Korean-led with selective English emphasis.
```

## 핵심 메시지 my point

이 덱으로 전달하고 싶은 결론이나 주요 포인트를 짧게 적습니다.

> 예시: 이번 분기에는 기존 고객 유지율을 높이고, 반복 구매를 만드는 실행 과제에 집중해야 합니다.


```markdown
[Concept]Large headings readable during projection, generous spacing, and one clear theme per slide

[Language Rule]
Main body copy should be Korean. Use concise English for section labels, short catchphrases, metrics, product terms, and key business keywords. The result should feel naturally Korean-led with selective English emphasis.
```


```markdown
[Concept]Large headings readable during projection, generous spacing, and one clear theme per slide

[Main Message][핵심 메시지 my point/시작] 블라블라블라 [핵심 메시지 my point/끝]

[Language Rule]
Main body copy should be Korean. Use concise English for section labels, short catchphrases, metrics, product terms, and key business keywords. The result should feel naturally Korean-led with selective English emphasis.
```


### 남기고 싶은 인상 impression

프리셋만으로 담기 어려운 분위기와 감정을 보완합니다.

> 예시: 신뢰감 / 실행력 / 명확함 / 전문적인 인상


```markdown
[Concept]Large headings readable during projection, generous spacing, and one clear theme per slide

[Language Rule]
Main body copy should be Korean. Use concise English for section labels, short catchphrases, metrics, product terms, and key business keywords. The result should feel naturally Korean-led with selective English emphasis.
```

```markdown
[Concept]Large headings readable during projection, generous spacing, and one clear theme per slide

[Desired Impression][남기고 싶은 인상 impression/시작] 신뢰감 / 실행력 / 명확함 / 전문적인 인상 [남기고 싶은 인상 impression/끝]

[Language Rule]
Main body copy should be Korean. Use concise English for section labels, short catchphrases, metrics, product terms, and key business keywords. The result should feel naturally Korean-led with selective English emphasis.
```



### 메인 언어 Main language

한 언어만 고정하지 않고, 슬라이드 맥락에 맞게 한국어와 영어 키워드를 섞도록 프롬프트에 반영합니다.

1. 한국어 중심 + English keywords : 본문은 한국어, 라벨/키워드는 영어를 섞습니다.
2. English main + 한국어 보조 : 본문은 영어, 보조 문구는 한국어를 허용합니다.
3. 입력 언어 맞춤 : 사용자가 입력한 언어를 우선하고 필요한 키워드만 섞습니다.

```markdown
[Concept]Large headings readable during projection, generous spacing, and one clear theme per slide

[Language Rule]
Main body copy should be Korean. Use concise English for section labels, short catchphrases, metrics, product terms, and key business keywords. The result should feel naturally Korean-led with selective English emphasis.

[Visual Style]Clean corporate slide design for business audiences, based on a white background, generous spacing, and a trustworthy tone.
```


```markdown
[Concept]Large headings readable during projection, generous spacing, and one clear theme per slide

[Language Rule]
Main body copy should be English. Korean may appear as short supporting labels, audience-specific nuance, or brief secondary text. Keep important business keywords in clear English when they improve comprehension.

[Visual Style]Clean corporate slide design for business audiences, based on a white background, generous spacing, and a trustworthy tone.
```


```markdown
[Concept]Large headings readable during projection, generous spacing, and one clear theme per slide

[Language Rule]
Follow the language of the user's input as the main language. Mix English or Korean only where it clarifies keywords, product terms, labels, or presentation rhythm. Do not translate proper nouns unnecessarily.

[Visual Style]Clean corporate slide design for business audiences, based on a white background, generous spacing, and a trustworthy tone.
```


### 진행 방식 How to proceed

디자인을 꼼꼼히 정하고 싶다면 먼저 구성안을 확인하는 방식이 좋습니다.

1. 바로 슬라이드 생성 : 붙여넣은 뒤 즉시 이미지를 생성합니다. Default
2. 먼저 구성안 확인 : ChatGPT가 제안 구조를 먼저 보여주고, 확인 후 이미지를 생성합니다.



```markdown
[Output Format]
- Image ratio: 16:9 widescreen presentation
- Number of slides: 6
- Image generation: use imagegen to generate the slide images sequentially

[Concept]Large headings readable during projection, generous spacing, and one clear theme per slide
```


```markdown
[Output Format]
- Image ratio: 16:9 widescreen presentation
- Number of slides: 6
- Image generation: use imagegen to generate the slide images sequentially

[Generation Workflow]
Before generating images, first present a text plan for all 6 slides.
For each slide, summarize the role, main point, and expected visual elements in 2-3 lines.
Proceed to image generation only after the user replies with approval or revision instructions.

[Concept]Large headings readable during projection, generous spacing, and one clear theme per slide
```

# 02. 디자인 design 필수 Required


## 슬라이드 수 Number of slides 필수 Required

9장 이상이 필요하면 챕터별로 나누어 여러 번 생성하세요.


# 03. 각 슬라이드 내용 optional / any

* 각 페이지의 역할은 버튼으로 설정하고, 내용은 줄 단위로 입력할 수 있습니다.
* 역할 이름은 슬라이드 타입이 단일 모드인지 챕터 모드인지에 따라 자동으로 달라집니다.
* 내용을 비워두면 GPT 가 내용을 자동으로 구성합니다.
* 각 슬라이드를 다이어그램, 숫자, 인용, 목록 등으로 표현하는 여부는 GPT 가 판단하며,
* 공통 규칙에는 같은 세계관을 유지하면서 주요 내용을 전환하도록 지시합니다.





# 04. 고급 설정 Advanced settings any


## 브랜드 컬러 Brand color

색상 이름이나 HEX 코드를 입력할 수 있습니다. ChatGPT Images 2.0은 두 가지를 모두 이해합니다.

> 예시: 검정과 흰색 중심 / #060606 and #FFFFFF


```markdown
[Language Rule]
Follow the language of the user's input as the main language. Mix English or Korean only where it clarifies keywords, product terms, labels, or presentation rhythm. Do not translate proper nouns unnecessarily.

[Visual Style]Clean corporate slide design for business audiences, based on a white background, generous spacing, and a trustworthy tone.

[Typography]Use large, high-visibility text that remains readable from projection distance.
```


```markdown
[Language Rule]
Follow the language of the user's input as the main language. Mix English or Korean only where it clarifies keywords, product terms, labels, or presentation rhythm. Do not translate proper nouns unnecessarily.

[Visual Style]Clean corporate slide design for business audiences, based on a white background, generous spacing, and a trustworthy tone. Use [브랜드 컬러 Brand color/시작] 검정과 흰색 중심 / #060606 and #FFFFFF [브랜드 컬러 Brand color/끝] as a key brand-color basis.

[Typography]Use large, high-visibility text that remains readable from projection distance.
```

## 슬라이드 장식 Slide decoration

### 페이지 번호 넣기

> 예: "1/4" 형식으로 눈에 띄지 않게 배치합니다.

```markdown
[Design Rules]
- Visual consistency: All 8 slides must look as if the same designer created them in sequence. Match not only colors and typography, but also the level of decoration, illustration density, diagram detail, and dimensionality. Avoid any variation in decorative density across slides.
- Composition variety: Do not repeat the same composition across the deck. Change the lead element according to the content, such as a main visual, character, large number, striking short phrase, list, or chart. Vary the camera position and focal subject while staying inside the same visual world. Choose the best presentation style for each slide based on its content and purpose.
- Information density: Limit each slide to one message. Do not pack multiple points into one slide. Prioritize quick visual comprehension over volume of information. Bullet lists should have at most three items, and each item should fit on one short line.
- Spacing: Keep a safe margin on all four edges equal to about 7-8% of the short side of the canvas. Place all sublabels, titles, subcopy, diagrams, and decoration inside this safe area. Do not push elements to the edge. Keep at least 30% of the canvas as empty space. Aligning the safe-area starting point helps title positions and title sizes feel consistent across slides.
- Communication: Minimize text and communicate through diagrams, icons, and generous empty space. Avoid layouts made from text blocks arranged in rows and columns.
- Typography cue: Place a subtle 1-2 word English catchphrase directly above the main heading to preview its meaning, such as STEP 01 / INSPECT, PRIORITY 01 / INFRASTRUCTURE, or NEW FEATURE / RELEASE. Do not use generic type labels such as COVER, INTRO, BODY, or OUTRO. Choose words that match the slide content.
- Layout freedom: Leave the upper-right area intentionally quiet. Do not fill it with category icons, decorative quotation marks, geometric accents, logo-like badges, or extra information. Keep the right side open so attention stays on the main heading.
- Deck flow: Treat slide 1 as the Cover and the final slide as the closing slide for summary or next action. Follow the separate [Slide-Type Layout Rules] block for layout, placement, and prohibited patterns for each slide type.
- Page number: Do not include page numbers.
- Photo handling: If using photos, real people, buildings, or spaces, let the photo stand alone as a quiet visual. Do not overlay text, numbers, icons, cards, charts, speech bubbles, logos, or decorative badges on the photo. Place explanatory text, metrics, and supporting information in an independent area physically separated from the photo zone.
```

```markdown
[Design Rules]
created them in sequence. Match not only colors and typography, but also the level of decoration, illustration density, diagram detail, and dimensionality. Avoid any variation in decorative density across slides.
- Composition variety: Do not repeat the same composition across the deck. Change the lead element according to the content, such as a main visual, character, large number, striking short phrase, list, or chart. Vary the camera position and focal subject while staying inside the same visual world. Choose the best presentation style for each slide based on its content and purpose.
- Information density: Limit each slide to one message. Do not pack multiple points into one slide. Prioritize quick visual comprehension over volume of information. Bullet lists should have at most three items, and each item should fit on one short line.
- Spacing: Keep a safe margin on all four edges equal to about 7-8% of the short side of the canvas. Place all sublabels, titles, subcopy, diagrams, and decoration inside this safe area. Do not push elements to the edge. Keep at least 30% of the canvas as empty space. Aligning the safe-area starting point helps title positions and title sizes feel consistent across slides.
- Communication: Minimize text and communicate through diagrams, icons, and generous empty space. Avoid layouts made from text blocks arranged in rows and columns.
- Typography cue: Place a subtle 1-2 word English catchphrase directly above the main heading to preview its meaning, such as STEP 01 / INSPECT, PRIORITY 01 / INFRASTRUCTURE, or NEW FEATURE / RELEASE. Do not use generic type labels such as COVER, INTRO, BODY, or OUTRO. Choose words that match the slide content.
- Layout freedom: Leave the upper-right area intentionally quiet. Do not fill it with category icons, decorative quotation marks, geometric accents, logo-like badges, or extra information. Keep the right side open so attention stays on the main heading.
- Deck flow: Treat slide 1 as the Cover and the final slide as the closing slide for summary or next action. Follow the separate [Slide-Type Layout Rules] block for layout, placement, and prohibited patterns for each slide type.
- Page number: Place a subtle page number in the bottom-right corner in 1/8 format.
- Photo handling: If using photos, real people, buildings, or spaces, let the photo stand alone as a quiet visual. Do not overlay text, numbers, icons, cards, charts, speech bubbles, logos, or decorative badges on the photo. Place explanatory text, metrics, and supporting information in an independent area physically separated from the photo zone.
```

### Footer 에 슬라이드 제목 반복하기

