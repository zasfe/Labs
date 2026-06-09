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
