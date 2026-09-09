# Codex 작업 지시문: Herdr AI Quota Monitor 구성

## 목표

Windows 11 → WSL Ubuntu 환경에서 Herdr를 주 터미널 도구로 유지하면서, Claude Code와 Codex의 구독 사용량을 상시 확인할 수 있는 경량 CLI 모니터를 구성한다.

Codex는 먼저 현재 환경과 Herdr 설정을 조사한 뒤, 기존 설정을 최대한 보존하면서 실제 동작 가능한 형태로 구현한다. 확인되지 않은 Herdr 명령이나 설정 키를 추측해서 사용하지 않는다.

## 목표 화면

Herdr의 좌측 하단 또는 작업을 방해하지 않는 위치에 약 10~15% 영역의 상시 pane을 배치한다.

    ┌──────────────┬───────────────────────────────┐
    │ AGENTS       │                               │
    │ Claude ●     │                               │
    │ Codex  ●     │        Main Workspace         │
    │              │                               │
    ├──────────────┤                               │
    │ AI QUOTA     │                               │
    │ C 5H 61%     │                               │
    │   WK 43%     │                               │
    │   ▁▃▅█▆ +14  │                               │
    │ X 5H 47%     │                               │
    │   WK 68% ⚠   │                               │
    │   ▁▂▄█▅ +9   │                               │
    └──────────────┴───────────────────────────────┘

## 반드시 표시할 정보

Claude Code와 Codex를 각각 표시한다.

1. 최근 5시간 사용률
2. 5시간 한도 reset까지 남은 시간
3. 주간 사용률
4. 주간 한도 reset까지 남은 시간
5. 최근 1시간 소비속도
6. 최근 24시간 소비 추세
7. 1시간 Sparkline
8. 24시간 Sparkline
9. 현재 quota 위험도

가능하다면 다음 값도 계산한다.

- 최근 1시간 사용량 증가율
- 최근 24시간 사용량 증가율
- 주간 경과율 대비 사용률
- 현재 소비속도 기준 quota 소진 예상시간(ETA)

단, 원본 데이터로 정확하게 계산할 수 없는 값은 임의로 생성하지 않는다.

## 핵심 원칙

### 1. 구독 quota를 우선한다.

API 비용 추정보다 실제 Claude Code/Codex 구독 제한 관리가 목적이다.

우선순위:

    Weekly quota
        ↓
    5-hour quota
        ↓
    Consumption rate
        ↓
    Reset time
        ↓
    Token / estimated cost

### 2. 로컬 데이터를 우선한다.

가능하면 다음과 같은 기존 CLI/session 정보를 이용한다.

    ~/.claude/
    ~/.codex/

이미 설치되어 있고 신뢰할 수 있는 usage CLI가 있다면 재사용한다.

외부 API 키를 새로 요구하지 않는다.

### 3. 기존 Herdr 설정을 보존한다.

Herdr 설정 파일을 찾은 후 변경 전에 반드시 백업한다.

    <original>.bak-YYYYMMDD-HHMMSS

기존 key binding, agent 설정, workspace 설정을 삭제하거나 초기화하지 않는다.

## Responsive TUI 요구사항

고정 폭을 가정하지 않는다.

현재 pane의 column 수를 감지한다.

예:

    cols=$(tput cols)

출력 모드는 최소 세 단계로 구성한다.

### FULL

32 columns 이상인 경우:

    CLAUDE  5H 61% ↻02:14
    WK 43%        ↻3d12h
    1H  ▁▂▃▅▇█▆▃  +14%/h
    24H ▁▂▄▃▅▇▅▃  +31%
    RISK NORMAL

### COMPACT

24~31 columns인 경우:

    CLAUDE
    5H 61% ↻02:14
    WK 43% ↻3d12h
    1H ▁▂▃▅▇█ +14%
    24 ▁▂▄▅▇▅ +31%

### MINI

24 columns 미만인 경우:

    CLAUDE
    5H 61%
    WK 43%
    1H ▁▂▃▅ +14

터미널 자동 줄바꿈이 발생하지 않도록 출력 직전에 실제 문자열 폭을 검사한다.

ANSI escape sequence는 화면 폭 계산에서 제외한다.

## Sparkline

Unicode block 문자를 사용한다.

    ▁ ▂ ▃ ▄ ▅ ▆ ▇ █

기본적으로 다음 두 추세를 제공한다.

    1H  ▁▂▃▅▇█▆▃
    24H ▁▂▄▃▅▇▅▃

pane 폭이 좁아지면 데이터 포인트를 자동 축약한다.

## Sampling

사용량 history가 필요하면 로컬에 snapshot을 저장한다.

권장 기본값:

    refresh interval  : 15~30초
    snapshot interval : 5분
    1H history        : 12 points 이상
    24H history       : 시간 단위 집계

history는 다음 디렉터리에 저장한다.

    ~/.local/state/ai-quota-monitor/

파일이 무한 증가하지 않도록 retention을 적용한다.

## 위험도

기본 임계치는 다음처럼 시작하되 설정 가능하게 구현한다.

    0~49%    NORMAL
    50~69%   WATCH
    70~84%   HIGH
    85~100%  CRITICAL

단기 한도와 주간 한도 중 더 위험한 상태를 전체 RISK로 표시한다.

특히 주간 quota가 HIGH 또는 CRITICAL이면 5시간 quota가 낮더라도 명확하게 표시한다.

## 주간 Budget 관리

단순한 Weekly 사용률뿐 아니라 주간 경과율과 비교한다.

예:

    Weekly 사용률 : 68%
    주간 경과율   : 40%
    Budget        : +28% ⚠

주간 경과율보다 사용률이 빠르면 과소비 상태로 판단한다.

가능하면 다음을 표시한다.

    WK 68% +28 ⚠

또는 충분한 폭에서는:

    WK 68%  BUD +28% ⚠

## 구현 언어

우선순위:

1. Python 표준 라이브러리만으로 구현
2. Bash
3. 기존 설치 CLI 재사용

새 Python 패키지는 꼭 필요한 경우에만 설치한다.

Rich/Textual 같은 대형 TUI dependency는 기본적으로 사용하지 않는다.

## Herdr 통합

현재 설치된 Herdr 버전을 먼저 확인한다.

    herdr --version

그 버전에서 실제 지원되는 다음 기능을 조사한다.

- pane 생성
- pane split
- pane resize
- startup command
- workspace/layout 저장
- 자동 실행
- pane 위치 지정

현재 버전에서 존재하지 않는 CLI 옵션이나 config key를 만들어내지 않는다.

가능하면 Herdr 시작 또는 workspace 진입 시 AI quota monitor가 자동 실행되도록 한다.

선호 배치는 다음 순서로 검토한다.

    1. 좌측 sidebar 하단
    2. 좌측 하단 별도 pane
    3. 화면 하단 전체 폭의 얕은 pane

실제 Herdr 제약 때문에 1번이 불가능하면 2번을 사용한다.

10% 비율을 절대값으로 강제하기보다 최소 22~26 columns를 확보하여 가독성을 우선한다.

## 기존 도구 조사

새 구현을 시작하기 전에 현재 시스템에서 다음을 확인한다.

    command -v claude
    command -v codex
    command -v herdr
    command -v ccusage
    command -v cc-usage
    command -v codexbar

각 도구가 제공하는 데이터를 직접 확인한다.

특히 다음 값이 실제로 제공되는지 검증한다.

    Claude 5H quota
    Claude weekly quota
    Claude reset time

    Codex 5H quota
    Codex weekly quota
    Codex reset time

직접 제공되는 값과 로컬 history를 이용해 계산하는 값을 문서에서 명확하게 구분한다.

## 구현 절차

다음 순서로 작업한다.

    1. 환경 조사
    2. Herdr 버전/설정 확인
    3. Claude/Codex usage 데이터 소스 확인
    4. 기존 설정 백업
    5. 데이터 collector 구현
    6. history/sampling 구현
    7. rate 계산 구현
    8. responsive renderer 구현
    9. Sparkline 구현
    10. Herdr pane 통합
    11. resize 테스트
    12. Claude/Codex 실제 실행 상태에서 검증
    13. 재로그인/WSL 재시작 후 검증

## 검증 조건

최소 다음 terminal width에서 테스트한다.

    20
    24
    28
    32
    40 columns

각 폭에서 다음 조건을 만족해야 한다.

- 의도하지 않은 자동 개행이 없어야 한다.
- Claude와 Codex를 명확하게 구분해야 한다.
- 5H와 Weekly를 혼동하지 않아야 한다.
- Weekly 위험 상태가 눈에 띄어야 한다.
- Sparkline이 깨지지 않아야 한다.
- pane resize 후 자동으로 다시 렌더링되어야 한다.

## 실패 처리

usage source를 읽을 수 없으면 프로그램 전체를 종료하지 않는다.

    CLAUDE
    5H --
    WK --
    DATA unavailable

    CODEX
    5H 47%
    WK 68% ⚠

Claude와 Codex 중 하나의 데이터 수집 실패가 다른 provider 표시를 막으면 안 된다.

## 산출물

작업 완료 후 다음 구조를 제공한다.

    ai-quota-monitor/
    ├── monitor.py
    ├── config.json
    ├── install.sh
    ├── uninstall.sh
    ├── README.md
    └── docs/
        └── herdr-integration.md

필요한 경우 systemd user service 또는 이에 준하는 자동 실행 구성을 추가할 수 있지만, Herdr 자체에서 lifecycle을 관리할 수 있다면 Herdr 방식을 우선한다.

## 최종 보고

구현 후 다음 내용을 명확하게 보고한다.

1. 변경한 파일
2. Herdr 설정 변경 사항
3. 데이터 취득 방식
4. 직접 취득하는 quota와 계산된 지표의 구분
5. 실행 명령
6. 자동 실행 여부
7. 검증 결과
8. 알려진 제약

## 완료 기준

설정 파일을 수정하기 전에 현재 내용을 읽고 기존 사용자 설정을 유지한다.

Herdr, Claude Code, Codex의 동작을 추측하지 말고 현재 설치된 버전과 실제 CLI 출력 및 로컬 데이터를 기준으로 구현한다.

최종 목표는 화려한 TUI가 아니라 작업 중 다음 질문에 1~2초 안에 답할 수 있는 화면을 만드는 것이다.

    지금 Claude와 Codex 중 어느 쪽의 quota가 더 위험한가?
    5시간 한도는 얼마나 남았는가?
    주간 한도는 얼마나 남았는가?
    최근 사용속도가 증가하고 있는가?
    주간 소비속도가 현재 예산을 초과하고 있는가?
    이 속도로 계속 사용해도 되는가?
