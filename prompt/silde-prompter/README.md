# ChatGPT / Codex 용 프롬프트

> https://slide-prompter.tonylee.im/

* 👉 Codex → npx skills add bytonylee/future-slide-skill → With $tightened-slide skill, 붙여서 사용 
* 👉 ChatGPT → 프롬프트 그대로 사용 (표현 붙이지 않음)


```markdown
You are a professional slide designer.
Create a 6-slide presentation for seminars or internal meetings in one consistent visual world.

[Output Format]
- Image ratio: 16:9 widescreen presentation
- Number of slides: 6
- Image generation: use imagegen to generate the slide images sequentially

[Concept]Large headings readable during projection, generous spacing, and one clear theme per slide

[Language Rule]
Main body copy should be Korean. Use concise English for section labels, short catchphrases, metrics, product terms, and key business keywords. The result should feel naturally Korean-led with selective English emphasis.

[Visual Style]Clean corporate slide design for business audiences, based on a white background, generous spacing, and a trustworthy tone.

[Typography]Use large, high-visibility text that remains readable from projection distance.

[Common Rules]

[Design Rules]
- Visual consistency: All 6 slides must look as if the same designer created them in sequence. Match not only colors and typography, but also the level of decoration, illustration density, diagram detail, and dimensionality. Avoid any variation in decorative density across slides.
- Composition variety: Do not repeat the same composition across the deck. Change the lead element according to the content, such as a main visual, character, large number, striking short phrase, list, or chart. Vary the camera position and focal subject while staying inside the same visual world. Choose the best presentation style for each slide based on its content and purpose.
- Information density: Limit each slide to one message. Do not pack multiple points into one slide. Prioritize quick visual comprehension over volume of information. Bullet lists should have at most three items, and each item should fit on one short line.
- Spacing: Keep a safe margin on all four edges equal to about 7-8% of the short side of the canvas. Place all sublabels, titles, subcopy, diagrams, and decoration inside this safe area. Do not push elements to the edge. Keep at least 30% of the canvas as empty space. Aligning the safe-area starting point helps title positions and title sizes feel consistent across slides.
- Communication: Minimize text and communicate through diagrams, icons, and generous empty space. Avoid layouts made from text blocks arranged in rows and columns.
- Typography cue: Place a subtle 1-2 word English catchphrase directly above the main heading to preview its meaning, such as STEP 01 / INSPECT, PRIORITY 01 / INFRASTRUCTURE, or NEW FEATURE / RELEASE. Do not use generic type labels such as COVER, INTRO, BODY, or OUTRO. Choose words that match the slide content.
- Layout freedom: Leave the upper-right area intentionally quiet. Do not fill it with category icons, decorative quotation marks, geometric accents, logo-like badges, or extra information. Keep the right side open so attention stays on the main heading.
- Deck flow: Treat slide 1 as the Cover and the final slide as the closing slide for summary or next action. Follow the separate [Slide-Type Layout Rules] block for layout, placement, and prohibited patterns for each slide type.
- Page number: Do not include page numbers.
- Photo handling: If using photos, real people, buildings, or spaces, let the photo stand alone as a quiet visual. Do not overlay text, numbers, icons, cards, charts, speech bubbles, logos, or decorative badges on the photo. Place explanatory text, metrics, and supporting information in an independent area physically separated from the photo zone.

[Prohibited Patterns]
- Card-row template ban: Do not use the default AI template of three or four white rounded cards in a row, each with a pale circular icon background, heading, and one-line description. Prefer asymmetric, editorial, magazine-like layouts.
- Step-flow template ban: Avoid AI-template step diagrams made from numbered badges, icons, labels, and arrows. Express procedures through typesetting, typography, and custom diagrams.

[Slide-Type Layout Rules]
For each slide type used in this deck, follow the rules below and draw each type differently.

### Cover (COVER, slide 1)
Layout: Place the message on the left and the visual on the right in a side-by-side composition. Do not lock the ratio at 50:50; distribute space freely for the design.
- left: Typography, including main title, subtitle, and small credits such as presenter and date.
- right: A visual scene that symbolizes the deck's world, such as a 3D diagram, key visual, representative illustration, or photo.
- Make the message and visual feel like a strong entrance into the story.

Prohibited:
- Do not use an icon-organizing layout made from icon, label, and one-line description rows.
- Do not use a top-and-bottom two-tier composition. The standard is left message and right visual side by side.

### Intro (INTRO, slide 2)
Layout: Place the message on top and a table-of-contents or roadmap structure below. Do not lock the ratio at 50:50; distribute space freely for the design.
- Top: Main heading plus subcopy or lead sentence in 1-2 lines.
- Bottom: Table-of-contents or roadmap style, using 3-5 icons, short 1-2 word labels, and concise one-line descriptions. Arrange items horizontally or vertically with equal visual weight.
- Keep at least 10% of the canvas height as spacing between the upper and lower areas. Use one continuous background, not a separate colored band, gradient band, or framed band for the top area.

Prohibited:
- Do not use a left-right split with text on the left and diagram on the right.
- Do not use a pictorial 3D diagram or key visual. The lower area is fixed as icon plus text organization.

### Body (BODY, middle slides)
Layout: Place the message on top and the diagram or visual explanation below. Do not lock the ratio at 50:50; distribute space freely for the design.
- Top: Main heading plus subcopy or lead sentence in 1-2 lines.
- Bottom: Focus on pictorial expression such as a 3D diagram, key visual, photo, chart, or editorial diagram.
- Let the lower area use the full canvas width. It is acceptable to leave natural empty space to the right of the upper heading.
- Keep at least 10% of the canvas height as spacing between the upper and lower areas. Use one continuous background, not a separate colored band, gradient band, or framed band for the top area.
- Give each slide its own diagram, scene, or visual. Avoid repeating the same look.

Prohibited:
- Do not use a left-right split with text on the left and diagram on the right.
- Do not use the intro-style table-of-contents or roadmap layout made from 3-5 icons, labels, and one-line descriptions.

### Summary / Next Action (OUTRO, final slide)
Layout: Place the message on the left and next actions on the right in a side-by-side composition. Do not lock the ratio at 50:50; distribute space freely for the design.
- Left: Typography with a recap message and a strong closing key message.
- Right: Next actions, using 3-4 icons, short 1-2 word labels, and one-line descriptions in a vertical list or grid. Give equal visual weight to actions such as what to do next, signup route, contact, reference resource, or concrete first step.
- Make the eye flow naturally from recap on the left to next action on the right.

Prohibited:
- Do not make the right side visual-scene-centered like the Cover. The right side is fixed as icon organization.
- Do not use a top-and-bottom two-tier composition. The standard is left message and right next actions.

[Slide Structure] (6 slides)
1. Cover: Generate content automatically based on the deck theme.
2. Intro: Generate content automatically based on the deck theme.
3. Body: Generate content automatically based on the deck theme.
4. Body: Generate content automatically based on the deck theme.
5. Body: Generate content automatically based on the deck theme.
6. Summary / Next Action: Generate content automatically based on the deck theme.

[Final Instruction]
Use imagegen without fail, and generate the slide images one by one in the order above.
Do not stop at the outline. Create all 6 completed slide images.
```

