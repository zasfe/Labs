# 프롬프트 모음


## 내 설정 상태 점검용 프롬프트

> https://www.stdy.blog/increasing-token-efficiency-by-setting-adjustment-in-claude-and-codex/

거두절미하고 내 코딩 에이전트 설정이 어떤지 점검하고 싶은 분들은 아래 프롬프트를 사용해보세요.

```
https://gist.github.com/spilist/c468cbf1ed0ffc91100f813aabdcd520?#file-token-efficiency-analysis-prompt-md 를 읽고 그대로 실행해줘
```

```
https://raw.githubusercontent.com/zasfe/Labs/refs/heads/master/prompt/token-efficiency-analysis-prompt.md 를 읽고 그대로 실행해줘
```

## 컨텍스트 관리 전략 2: 선제적 압축
대화가 길어지면, 다음 에이전트를 위해 HANDOFF.md 파일을 작성하도록 지시하고 /clear 로 새롭게 시작하세요. 

```
https://raw.githubusercontent.com/zasfe/Labs/refs/heads/master/prompt/HANDOFF.md 를 읽고 그대로 실행해줘
```

```
나머지 계획 내용을 현재 폴더에 HANDOFF.md 파일로 저장하세요.
시도했던 내용, 성공했던 부분, 실패했던 부분을 자세히 설명하여,
다음 담당자가 새로운 환경에서 해당 파일만 불러와도 바로 작업을 시작하고 완료할 수 있도록 하세요.
```

---

## 로컬 레포지토리에서 하드코딩된 자격증명·키·토큰을 LLM으로 탐지하는 하네스 프롬프트

* 원본: https://github.com/gameworkerkim/vibe-investing/blob/main/TechDoc/LLM_Security/Secret%20scanning%20llm%20harness%20prompt.md

```
https://github.com/zasfe/Labs/blob/master/prompt/example/Secret%2520scanning%2520llm%2520harness/prompt.md 를 읽고 참고해서 현재 프로젝트를 검토하라.
```

## 마크다운 -> HTML 만들기

토큰사용량 2~4배 급증, 하지만 토큰 사격은 계속 내려가는중, 빠른 인지가 필요한 시점?

```
이 PR을 검토하는 데 도움을 주시려면, PR 내용을 설명하는 HTML 아티팩트를 만들어 주세요.
스트리밍/백프레셔 로직에 익숙하지 않으니 그 부분에 집중해 주세요.
실제 diff를 렌더링할 때 인라인 여백 주석을 추가하고, 심각도별로 색상 코드를 지정하고, 개념을 잘 전달하는 데 필요한 다른 요소들도 포함해 주세요.

단일 index.html 파일에, 종속성 없이, 최소한의 스타일링으로 <아이디어>를 구현하는 앱을 만들어 주세요.
```

  * 사례: https://thariqs.github.io/html-effectiveness/


## 단계 완료 후 근거가 확인되는 다음 작업을 정확히 한 개 제안함

```
  https://github.com/zasfe/Labs/blob/master/prompt/skills/planning-with-files-agent-guide/SKILL.md를 운영 지침으로 읽어라.
  현재 플랫폼의 도구와 권한 체계에 맞게 의미를 유지하여 적용하라.
  각 단계 완료 후 근거 기반 다음 작업을 정확히 한 개 제안하라.
```



