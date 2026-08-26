PRD — Vendor-Neutral AI Skills & Agents Runtime

* 문서 버전: 1.3
* 기준일: 2026-08-27
* 목적: Claude Code, OpenCode 및 검증이 완료된 향후 AI Coding Agent가 하나의 Skills와 Canonical Agents 원본을 공유하도록 한다.
* 핵심 원칙: SSOT + 표준 Skill + 최소 Canonical Agent Spec + 검증된 Adapter
* 목표 환경: Linux / WSL 우선
* 구현 우선순위: 단순성 > 안전성 > 이식성 > 자동화 > 도구별 고급 기능

⸻

1. 문서 검토 결과

1.1 확인된 충돌과 모호성

기존 문서에는 다음 요구사항이 서로 충돌하거나 구현 범위가 모호했다.

1. MVP에서 "안전한 symlink/copy 배포"를 요구하면서
   install 명령은 Phase 2로 연기함.
2. generate는 배포하지 않는다고 정의하면서
   MVP 수용 기준은 실제 플랫폼에서 사용할 수 있는 상태를 요구함.
3. Skill은 직접 공유한다고 정의하면서
   Claude와 OpenCode가 동일한 경로를 항상 지원하는지 불명확함.
4. Canonical Agent의 skills 필드를 지원하면서
   플랫폼별 Skill 연결을 생성할지 여부가 명확하지 않음.
5. capability 변환 실패 시 "생성 중단 또는 WARNING"이라고 하여
   실패 처리 정책이 일관되지 않음.
6. 기존 디렉터리 내부 파일 충돌을 검사한다고 정의하면서
   generated 파일과 배포 대상의 소유권 기준이 없음.
7. `generated/`를 Git에서 제외한다고 정의하면서
   생성 결과 검증과 재현성 기준이 부족함.
8. `doctor`가 symlink 상태와 충돌을 표시한다고 정의하면서
   실제 배포를 수행하는지 여부가 불명확함.
9. MVP에서 "플랫폼별 미지원 기능을 명시적으로 표시"한다고 하면서
   검증 상태와 capability 상태의 표현 방식이 분리되어 있지 않음.
10. OpenCode Skill 경로를 `~/.claude/skills/` 또는 `~/.agents/skills/` 중
    선택적으로 사용한다고 하면서 기본 정책이 없음.
11. Canonical Agent의 `mode`를 지원하지만
    Claude Code와 OpenCode에서의 의미와 변환 규칙이 정의되지 않음.
12. `capabilities.filesystem: write`와 `capabilities.edit: true`가
    중복되거나 서로 충돌할 수 있음.
13. "기존 사용자 파일을 덮어쓰지 않는다"와
    "기존 symlink는 유지 또는 갱신"이 충돌할 수 있음.
14. MVP에서 `adapters/`를 만들지 않는다고 하면서
    Claude/OpenCode generator의 구현 위치가 정의되지 않음.
15. "모든 플랫폼의 자동 discovery 테스트는 비목표"라고 하면서
    Claude/OpenCode integration test는 discovery를 요구함.

1.2 통일된 정책

위 충돌을 해결하기 위해 다음 정책을 확정한다.

1. MVP에는 install 명령을 포함한다.
   generate와 install은 분리한다.
2. generate는 generated/ 파일만 생성한다.
   install은 검증된 대상에만 배포한다.
3. doctor는 상태 확인만 수행하며 파일을 생성·삭제·갱신하지 않는다.
4. Skill의 Canonical 원본은 ~/ai-agent/skills/ 하나다.
   플랫폼별 Skill 파일은 생성하지 않는다.
5. OpenCode Skill 배포의 기본 경로는 ~/.agents/skills/로 한다.
   OpenCode가 해당 경로를 지원하지 않는 것이 확인되면
   ~/.claude/skills/를 대체 경로로 사용한다.
   두 경로를 동시에 생성하지 않는다.
6. Agent의 skills 필드는 검증과 문서화에 사용한다.
   MVP에서는 Agent 파일 안에 Skill 내용을 삽입하지 않는다.
   Skill discovery는 플랫폼의 native discovery에 맡긴다.
7. capability 변환이 불가능하면 해당 Agent 생성과 배포를 중단한다.
   안전한 축소 변환만 WARNING과 함께 허용한다.
8. capability는 권한 모델이 아니라 최소 안전 제약으로 취급한다.
   `filesystem: write`와 `edit: true`는 별도 의미를 유지하되,
   둘 중 하나라도 쓰기 권한을 허용하면 쓰기 가능 Agent로 분류한다.
9. 기존 일반 파일과 디렉터리는 절대 덮어쓰지 않는다.
   기존 symlink도 기본적으로 갱신하지 않는다.
   명시적 `--force`는 MVP에서 제공하지 않는다.
10. generated/는 Git에서 제외하지만,
    생성 결과는 deterministic해야 하며 generate 후 검증한다.
11. MVP의 검증 상태는 VERIFIED, MANUAL, UNKNOWN 세 가지로 유지한다.
    capability 변환 결과는 EXACT, DOWNGRADED, UNSUPPORTED로 별도 표시한다.
12. `mode`는 `subagent`만 MVP에서 허용한다.
    다른 값은 검증 오류로 처리한다.
13. Claude/OpenCode generator는 MVP에서 직접 구현한다.
    별도 adapters/ 디렉터리는 만들지 않고 bin 또는 lib 내부에 둔다.
14. MVP integration test는 실제 CLI가 설치된 환경에서만 실행한다.
    CLI가 없으면 실패가 아니라 SKIPPED로 표시한다.
15. Codex와 Rules는 MVP에서 생성·배포하지 않는다.
    doctor에서 상태만 표시한다.

⸻

2. YAGI 원칙

이 프로젝트에서 YAGI는 다음 원칙으로 정의한다.

YAGI = You Aren't Gonna Integrate

아직 실제 요구가 확인되지 않은 플랫폼 통합·추상화·자동화를 미리 구현하지 않는다.

2.1 YAGI 적용 규칙

1. 실제로 두 플랫폼 이상에서 반복되는 차이만 추상화한다.
2. 공식 문서와 실제 사용 사례가 없는 기능은 Canonical Spec에 넣지 않는다.
3. 변환이 단순한 경우 별도 IR을 만들지 않는다.
4. 자동화보다 수동 확인이 더 안전하면 수동 확인을 선택한다.
5. 플랫폼별 기능을 공통 모델에 억지로 포함하지 않는다.
6. MVP에서 사용되지 않는 CLI와 디렉터리는 만들지 않는다.
7. 검증되지 않은 플랫폼은 자동 지원하지 않는다.
8. 불확실한 동작은 조용히 추정하지 않고 상태와 경고로 표시한다.

⸻

3. MVP 목표

MVP는 Claude Code와 OpenCode를 대상으로 한다.

                    Canonical Repository
                         ~/ai-agent
                              │
              ┌───────────────┴───────────────┐
              │                               │
         Standard Skills                Canonical Agents
          skills/*                       agents/*
              │                               │
              │ native discovery             │ 생성
              │                               ▼
      ┌───────┴────────┐              ┌───────┴────────┐
      ▼                ▼              ▼                ▼
   Claude           OpenCode       Claude           OpenCode

사용자는 다음 원본만 관리한다.

~/ai-agent/
├── skills/
├── agents/
├── bin/
└── tests/

MVP에서는 다음만 Canonical source로 관리한다.

skills/
agents/

Rules와 Codex Adapter는 Phase 2 이후에 추가한다.

MVP 범위

1. Agent Skills 표준 기반 Skill SSOT 구축
2. Claude Code Skill discovery 지원
3. OpenCode Skill discovery 지원
4. Markdown + YAML 기반 Canonical Agent Spec 구축
5. Claude Code Agent 생성
6. OpenCode Agent 생성
7. 생성 결과 검증
8. 검증된 대상에 대한 안전한 배포
9. validate, generate, install, doctor CLI 구현
10. 기존 사용자 파일 보호
11. 멱등성 보장
12. 플랫폼별 미지원 기능의 명시적 표시

MVP 비목표

1. Codex Agent 자동 생성·배포
2. Rules 자동 생성·배포
3. Normalized IR 구현
4. 모든 capability의 완전한 공통 추상화
5. MCP 통합
6. 모델 선택 통합
7. 프로젝트별 override
8. 플랫폼별 runtime 통합
9. 설치되지 않은 플랫폼의 실제 discovery 자동 검증
10. 플랫폼별 고급 기능의 공통화
11. 강제 덮어쓰기 옵션
12. 자동 복구 또는 자동 삭제

⸻

4. Canonical Repository

~/ai-agent/
├── README.md
├── VERSION
├── bin/
│   └── ai-agent
├── skills/
├── agents/
├── generated/
│   ├── claude/
│   └── opencode/
└── tests/
    ├── fixtures/
    └── integration/

MVP 원칙:

Canonical sources = Git으로 관리
Generated files = 재생성 가능하며 Git에서 제외

MVP에서는 다음 최상위 디렉터리를 만들지 않는다.

rules/
adapters/
schemas/
lib/

단, 구현 복잡도가 증가하면 내부 모듈로 분리할 수 있다. 이 경우에도 공개 구조와 Canonical source의 의미는 변경하지 않는다.

⸻

5. Skills

5.1 설계 결정

Skill은 Agent Skills 표준의 SKILL.md를 Canonical Format으로 사용한다.

자체 Skill 포맷을 만들지 않는다.
Skill 변환 계층을 만들지 않는다.
Skill별 플랫폼 파일을 생성하지 않는다.
Skill 내용을 Agent 파일에 복사하지 않는다.

Canonical 위치:

~/ai-agent/skills/
└── architecture-review/
    ├── SKILL.md
    ├── references/
    ├── scripts/
    └── assets/

Skill은 플랫폼의 native discovery 경로를 통해 발견하도록 한다.

5.2 Skill 배포 정책

Canonical Skill은 다음 우선순위로 연결한다.

1. 플랫폼이 ~/ai-agent/skills를 직접 지원하면 직접 사용
2. 지원하지 않으면 플랫폼의 공식 사용자 Skill 경로에 symlink 생성
3. 공식 경로가 확인되지 않으면 자동 배포하지 않고 MANUAL 표시

MVP의 기본 경로:

Claude Code
~/ai-agent/skills/
    ↓
~/.claude/skills/
OpenCode
~/ai-agent/skills/
    ↓
~/.agents/skills/

OpenCode가 ~/.agents/skills/를 현재 설치 버전에서 지원하지 않는 경우에만 다음 대체 경로를 사용한다.

~/ai-agent/skills/
    ↓
~/.claude/skills/

두 경로를 동시에 생성하지 않는다.

5.3 최소 Skill 예시

---
name: architecture-review
description: 시스템 아키텍처의 구조적 문제, 확장성, 운영성 및 개선안을 분석한다.
metadata:
  version: "1.0.0"
---
# Architecture Review
## 목적
시스템 아키텍처의 문제와 개선 가능성을 분석한다.
## Workflow
1. 현재 구조를 파악한다.
2. 주요 컴포넌트와 데이터 흐름을 식별한다.
3. 장애 지점을 분석한다.
4. 확장성과 운영성을 분석한다.
5. 개선안을 제시한다.

5.4 Skill 검증

MVP에서 검증하는 항목은 다음으로 제한한다.

SKILL.md 존재
YAML frontmatter 유효
name 존재
description 존재
directory/name 일치
참조 파일 존재

다음은 MVP에서 검증하지 않는다.

Skill 내용의 품질
모델별 실행 결과
모든 표준 필드의 의미
플랫폼별 tool 호출의 정확성

Skill description은 discovery metadata이므로 무엇을 수행하는지와 언제 사용하는지를 명확히 작성한다.

📄출처: Agent Skills Specification⁠￼, Claude Code Skills⁠￼

⸻

6. Agents

6.1 설계 결정

Agent는 Skill처럼 표준 포맷을 직접 공유하지 않는다.

MVP에서는 별도 Normalized IR을 만들지 않고 다음 단계를 사용한다.

Canonical Agent Markdown
        │
        ├── Claude generator
        └── OpenCode generator

Normalized IR은 다음 조건을 모두 만족하는 경우에만 도입을 검토한다.

1. 세 개 이상의 플랫폼을 지원할 때
2. 두 개 이상의 Adapter에서 동일한 변환 로직이 반복될 때
3. capability mapping이 실제로 복잡해질 때
4. 중간 표현이 변환 오류를 줄인다는 근거가 있을 때

6.2 Canonical Agent 형식

---
name: reviewer
description: 구현 결과를 독립적으로 검토하고 결함, 회귀 및 운영 위험을 찾는다.
mode: subagent
capabilities:
  filesystem: read
  shell: none
  network: false
  edit: false
skills:
  - code-review
  - architecture-review
---
# Reviewer
## Role
구현 결과를 독립적으로 검증한다.
## Responsibilities
- 요구사항 누락 확인
- 논리 오류 확인
- 회귀 가능성 확인
- 운영 위험 확인
- 테스트 누락 확인
## Constraints
- 직접 구현하지 않는다.
- 문제와 수정 방향을 분리한다.

6.3 MVP에서 지원하는 Agent 필드

name
description
mode
capabilities.filesystem
capabilities.shell
capabilities.network
capabilities.edit
skills
본문

6.4 MVP에서 지원하지 않는 Agent 필드

model
mcp
subagents
platform-specific permission
provider/model ID
background execution
parallel execution
tool 목록

지원하지 않는 필드는 검증 오류로 처리한다. 조용히 무시하지 않는다.

6.5 Agent 필드 정책

name

소문자 영문, 숫자, 하이픈만 허용
Canonical 파일명과 일치해야 함
전체 agents/ 내에서 unique해야 함

description

필수
한 줄 또는 여러 줄 문자열 허용
Agent의 역할과 사용 시점을 설명해야 함

mode

MVP에서는 다음 값만 허용한다.

mode: subagent

primary, default 등 다른 값은 플랫폼별 의미가 다르므로 MVP에서 허용하지 않는다.

skills

각 항목은 ~/ai-agent/skills/<name>/에 존재해야 함
Skill 내용은 생성된 Agent 파일에 삽입하지 않음
플랫폼의 native Skill discovery에 맡김

Agent가 참조하는 Skill이 플랫폼에서 발견되지 않는 경우 doctor는 WARNING을 표시한다. Agent 생성 자체는 Skill 파일이 Canonical repository에 존재하면 허용한다.

⸻

7. Capability Model

MVP에서는 capability를 완전한 권한 추상화로 취급하지 않는다. 플랫폼별 권한을 안전하게 제한하기 위한 최소 제약으로만 사용한다.

capabilities:
  filesystem: none | read | write
  shell: none | execute
  network: true | false
  edit: true | false

7.1 필드 의미

filesystem
- none: 파일 접근을 요구하지 않음
- read: 파일 읽기만 요구함
- write: 파일 생성·수정·삭제를 요구함
shell
- none: shell 실행을 요구하지 않음
- execute: shell 실행을 요구함
network
- false: 네트워크 접근을 요구하지 않음
- true: 네트워크 접근이 필요함
edit
- false: 파일 편집을 요구하지 않음
- true: 파일 편집이 필요함

filesystem: write와 edit: true는 중복 필드가 아니다.

filesystem
= 파일 시스템 접근 범위
edit
= Agent가 파일 내용을 변경하는 작업을 수행하는지 여부

따라서 다음 정책을 적용한다.

filesystem: write 또는 edit: true
→ 쓰기 가능 Agent
filesystem: read 및 edit: false
→ 읽기 전용 Agent

7.2 변환 규칙

정확히 표현 가능
→ EXACT
더 안전한 축소 표현 가능
→ DOWNGRADED + WARNING
표현 불가능
→ UNSUPPORTED + 생성 중단

MVP에서는 UNSUPPORTED capability를 가진 Agent를 생성하거나 배포하지 않는다.

권한 확대는 금지한다.

Canonical: filesystem: read
허용: 읽기 전용 native capability
금지: 전체 파일 수정 권한

⸻

8. Claude Code Adapter

Claude Code는 MVP의 첫 번째 대상이다.

입력

agents/reviewer.md

출력

generated/claude/agents/reviewer.md

예:

---
name: reviewer
description: 구현 결과를 독립적으로 검토한다.
tools: Read, Grep, Glob
---
당신은 구현 결과를 독립적으로 검증하는 Reviewer다.
직접 구현하지 않는다.
결함, 회귀, 운영 위험, 테스트 누락을 찾는다.

8.1 변환 정책

filesystem: none
→ 파일 읽기 도구를 생성하지 않음
filesystem: read
→ Read, Grep, Glob 등 읽기 전용 도구만 허용
filesystem: write 또는 edit: true
→ Claude의 쓰기 도구가 필요함

Claude에서 Canonical capability를 정확히 표현할 수 없는 경우:

정확한 축소 표현 가능
→ DOWNGRADED + WARNING
축소 표현도 불가능
→ UNSUPPORTED + 생성 중단

skills 필드는 Claude Agent 파일에 Skill 본문으로 삽입하지 않는다. Claude의 Skill discovery 경로에서 Skill을 발견할 수 있어야 하며, 발견되지 않으면 doctor가 경고한다.

8.2 배포

generated/claude/agents/
          ↓
~/.claude/agents/

Skill:

~/ai-agent/skills/
          ↓
~/.claude/skills/

Claude Code의 공식 형식과 경로가 현재 설치 버전에서 확인된 경우에만 자동 배포한다.

📄출처: Claude Code Skills⁠￼, Claude Code Subagents⁠￼

⸻

9. OpenCode Adapter

OpenCode는 MVP의 두 번째 대상이다.

입력

agents/reviewer.md

출력

generated/opencode/agents/reviewer.md

예:

---
description: 구현 결과를 검토한다.
mode: subagent
permission:
  bash: deny
  edit: deny
---
구현 결과를 독립적으로 검증한다.

9.1 변환 정책

shell: none
→ bash: deny
edit: false 및 filesystem: read 이하
→ edit: deny
network: false
→ OpenCode에서 명시적 network deny를 지원하는 경우에만 적용

OpenCode가 특정 capability를 표현할 수 없는 경우:

안전한 축소 표현 가능
→ DOWNGRADED + WARNING
축소 표현 불가능
→ UNSUPPORTED + 생성 중단

9.2 배포

generated/opencode/agents/
          ↓
~/.config/opencode/agents/

Skill 기본 경로:

~/ai-agent/skills/
          ↓
~/.agents/skills/

OpenCode의 현재 설치 버전이 ~/.agents/skills/를 지원하지 않는 경우에만 다음 대체 경로를 사용한다.

~/ai-agent/skills/
          ↓
~/.claude/skills/

두 경로를 동시에 생성하지 않는다.

📄출처: OpenCode Skills⁠￼, OpenCode Agents⁠￼

⸻

10. Codex 정책

Codex는 MVP에서 자동 생성·배포하지 않는다.

이유:

1. 설치 버전별 Agent 형식과 경로가 안정적인 공통 계약으로 확인되지 않음
2. migration 예시와 실제 CLI 계약을 동일하게 취급할 수 없음
3. 잘못된 자동 배포가 사용자 설정을 손상시킬 수 있음
4. Codex 지원이 MVP의 핵심 가치가 아님

MVP에서 Codex는 다음만 수행한다.

doctor에서 설치 여부와 버전을 표시
지원 상태를 MANUAL 또는 UNKNOWN으로 표시
자동 파일 생성·배포하지 않음

Codex Adapter는 다음 조건을 모두 충족한 뒤 Phase 2에서 추가한다.

1. 공식 문서에 형식과 경로가 명시됨
2. 현재 설치 버전에서 실제 discovery가 확인됨
3. 기존 사용자 파일 보호 정책이 구현됨
4. 최소 하나의 integration test가 통과함

⸻

11. Rules 정책

Rules는 MVP에서 Canonical source로 만들지 않는다.

이유:

1. Claude Code, OpenCode, Codex의 instruction loading semantics가 다름
2. global rule과 project rule의 범위가 다름
3. 기존 CLAUDE.md와 AGENTS.md를 안전하게 병합하기 어려움
4. Rules 자동 생성은 파일 충돌 위험이 큼
5. Skill과 Agent만으로 MVP의 핵심 가치를 검증할 수 있음

MVP에서는 Rules를 다음처럼 처리한다.

Rules 자동 생성하지 않음
Rules 자동 배포하지 않음
기존 CLAUDE.md와 AGENTS.md를 수정하지 않음

Rules는 Phase 2에서 다음 정책을 먼저 확정한 뒤 추가한다.

global rule
project rule
user rule
기존 파일 병합
충돌 해결
삭제 및 복구

⸻

12. 생성 및 배포

12.1 생성 흐름

Canonical source
      │
      ▼
parse
      │
      ▼
validate
      │
      ▼
platform generator
      │
      ▼
generated/<platform>/

MVP에서는 normalize 단계를 두지 않는다.

12.2 생성 파일 헤더

# GENERATED FILE
# DO NOT EDIT
# source: ~/ai-agent/agents/reviewer.md
# target-platform: <platform>
# target-version: <version>

12.3 생성 정책

generate는 다음 조건을 지켜야 한다.

1. Canonical source를 변경하지 않음
2. generated/ 외부에 파일을 생성하지 않음
3. UNSUPPORTED Agent는 생성하지 않음
4. DOWNGRADED Agent는 경고와 함께 생성함
5. 동일 입력에 대해 동일한 결과를 생성함
6. 생성 후 출력 형식을 다시 검증함

하나 이상의 Agent가 UNSUPPORTED이면 전체 명령을 실패시킨다. 부분 생성은 허용하지 않는다.

12.4 배포 정책

install은 generate가 성공한 뒤에만 실행할 수 있다.

ai-agent install

수행 순서:

1. 플랫폼 탐지
2. CLI 버전 확인
3. generate 실행
4. 대상 경로 검증
5. 충돌 검사
6. Skill symlink 설치
7. Agent 파일 설치
8. 설치 결과 검증

12.5 자동 배포 조건

다음 조건을 모두 만족할 때만 자동 배포한다.

1. 플랫폼이 탐지됨
2. CLI 버전이 확인됨
3. 형식과 검색 경로가 확인됨
4. 대상 경로가 공식 또는 검증된 경로임
5. 기존 사용자 파일을 덮어쓰지 않음
6. symlink 또는 copy 방식이 검증됨

조건을 하나라도 만족하지 못하면 해당 플랫폼은 설치하지 않고 MANUAL 또는 UNKNOWN으로 표시한다.

12.6 기존 대상 처리

대상 없음
→ 생성 또는 symlink
기존 일반 파일
→ 오류 및 수동 확인
기존 디렉터리
→ 내부 대상별 충돌 검사
기존 symlink가 Canonical 대상
→ 유지
기존 symlink가 다른 대상
→ 오류 및 수동 확인
깨진 symlink
→ 자동 삭제하지 않음
→ 오류 및 수동 확인
생성 파일 헤더가 있는 기존 파일
→ 내용과 source를 비교
→ 동일하면 유지
→ 다르면 오류 및 수동 확인

MVP에서는 --force를 제공하지 않는다.

⸻

13. CLI 요구사항

MVP에서는 다음 명령을 제공한다.

ai-agent validate
ai-agent generate
ai-agent install
ai-agent doctor

13.1 validate

ai-agent validate

검사:

Skills
├─ SKILL.md 존재
├─ YAML frontmatter
├─ name/description
├─ directory/name 일치
└─ 참조 파일
Agents
├─ YAML frontmatter
├─ name unique
├─ description
├─ mode
├─ capability
├─ referenced skill
└─ Claude/OpenCode 변환 가능성

검증 실패 시 종료 코드는 0이 아니어야 한다.

13.2 generate

ai-agent generate

수행:

1. Canonical Agent 파싱
2. Canonical source 검증
3. Claude 출력 생성
4. OpenCode 출력 생성
5. 생성 결과 검증
6. generated/에 저장

generate는 배포하지 않는다.

generate = 파일 생성
install = 파일 연결 또는 복사
doctor = 상태 확인

13.3 install

ai-agent install

수행:

1. validate 실행
2. generate 실행
3. 설치 가능한 플랫폼 탐지
4. 대상 경로와 기존 파일 검사
5. 충돌이 없는 대상만 설치
6. 설치 결과 검증

한 플랫폼에서 충돌이 발생해도 다른 플랫폼의 안전한 설치까지 중단할지는 다음 정책을 따른다.

플랫폼별 독립 처리
충돌한 플랫폼은 실패
충돌이 없는 플랫폼은 계속 설치
최종 종료 코드는 하나라도 실패하면 0이 아님

13.4 doctor

ai-agent doctor

doctor는 읽기 전용 명령이다. 파일을 생성·삭제·갱신하지 않는다.

출력:

Canonical repository 상태
설치된 CLI와 버전
Claude Skill 경로와 상태
Claude Agent 경로와 상태
OpenCode Skill 경로와 상태
OpenCode Agent 경로와 상태
symlink 상태
생성 파일 수
충돌 파일
capability 변환 상태
Codex 상태

⸻

14. 검증 상태

MVP에서는 플랫폼 검증 상태를 다음 세 가지로 유지한다.

VERIFIED
현재 설치 버전에서 공식 형식과 경로가 확인됨
MANUAL
자동 배포하지 않고 사용자가 확인해야 함
UNKNOWN
공식 문서 또는 실제 동작으로 확인하지 못함

Capability 변환 결과는 별도로 표시한다.

EXACT
Canonical capability를 의미 손실 없이 표현함
DOWNGRADED
더 안전한 축소 표현으로 변환함
UNSUPPORTED
안전한 표현이 불가능함

두 상태를 혼동하지 않는다.

플랫폼 상태
= VERIFIED / MANUAL / UNKNOWN
Capability 상태
= EXACT / DOWNGRADED / UNSUPPORTED

⸻

15. 테스트

15.1 Unit Test

Skill parser
Skill validator
Agent parser
Agent validator
Claude generator
OpenCode generator
Capability mapper
Path conflict handler
Deterministic generation

15.2 Fixture

tests/fixtures/
├── minimal-agent.md
├── readonly-agent.md
├── skill-agent.md
├── downgraded-capability.md
└── unsupported-capability.md

15.3 Integration Test

실제 CLI가 설치된 환경에서만 실행한다.

Claude Code
- Skill discovery
- Agent discovery
OpenCode
- Skill discovery
- Agent discovery

CLI가 설치되지 않았거나 버전 확인이 불가능한 경우:

테스트 실패가 아니라 SKIPPED
doctor에서 MANUAL 또는 UNKNOWN 표시

CI에서는 다음 두 모드를 지원한다.

offline
- parser, validator, generator, conflict test만 실행
runtime
- 실제 Claude Code/OpenCode discovery test 실행

⸻

16. MVP 수용 기준

[ ] ~/ai-agent/skills가 Skill의 유일한 원본 저장소다.
[ ] Skill은 Agent Skills 표준의 SKILL.md 형식을 사용한다.
[ ] 플랫폼별 Skill 파일을 사람이 별도로 관리하지 않는다.
[ ] Canonical Agent는 agents/에만 존재한다.
[ ] Claude Agent가 생성된다.
[ ] OpenCode Agent가 생성된다.
[ ] 생성 파일은 generated/에 저장된다.
[ ] 생성 파일을 삭제해도 재생성할 수 있다.
[ ] generate는 배포하지 않는다.
[ ] install은 검증된 대상에만 배포한다.
[ ] doctor는 파일을 변경하지 않는다.
[ ] validate가 잘못된 Skill과 Agent를 검출한다.
[ ] doctor가 CLI 버전, 경로, symlink 및 충돌 상태를 표시한다.
[ ] unsupported capability가 경고 없이 사라지지 않는다.
[ ] UNSUPPORTED Agent는 생성되지 않는다.
[ ] DOWNGRADED Agent는 경고와 함께 생성된다.
[ ] 권한 확대 변환이 발생하지 않는다.
[ ] 기존 사용자 파일을 덮어쓰지 않는다.
[ ] 기존 symlink가 다른 대상을 가리키면 오류 처리한다.
[ ] Codex가 설치되어 있어도 검증 전에는 자동 배포하지 않는다.
[ ] Rules 파일을 자동으로 덮어쓰거나 생성하지 않는다.
[ ] MVP 구현에 Normalized IR이 필요하지 않다.
[ ] 동일한 Canonical source로 반복 생성해도 결과가 동일하다.

⸻

17. 구현 순서

Phase 1 — Skills SSOT

~/ai-agent/skills
Skill validator
Claude path detection
OpenCode path detection
symlink 상태 확인
doctor

Phase 2 — Canonical Agents

agents/*.md
최소 Agent parser
Agent validator
Claude generator
OpenCode generator
generated/ 검증

Phase 3 — 안전한 배포

기존 파일 충돌 검사
Skill symlink 생성
Agent 파일 설치
배포 상태 확인
install 명령

Phase 4 — Runtime Integration Test

Claude Skill discovery
Claude Agent discovery
OpenCode Skill discovery
OpenCode Agent discovery

Phase 5 — Rules

rules/global.md
rules/coding.md
platform-native instruction generation
충돌 및 병합 정책

Phase 6 — Codex

Codex 형식 검증
Codex 경로 검증
Codex discovery test
Codex generator
Codex install

Phase 7 — 추상화 재평가

Normalized IR 필요성 검토
Capability model 확장
Project-local override
status/clean 명령

⸻

18. MVP 파일 구조

ai-agent/
├── README.md
├── VERSION
├── bin/
│   └── ai-agent
├── skills/
├── agents/
├── generated/
│   ├── claude/
│   └── opencode/
└── tests/
    ├── fixtures/
    └── integration/

구현이 커질 때 다음 구조로 확장할 수 있다.

ai-agent/
├── schemas/
├── lib/
├── adapters/
└── rules/

확장 시에도 다음 원칙을 유지한다.

Canonical source는 skills/와 agents/에 둔다.
generated/는 파생 산출물이다.
플랫폼별 파일은 직접 수정하지 않는다.

⸻

19. YAGI에 따른 삭제 및 연기 목록

MVP에서 제거하거나 연기한 항목은 다음과 같다.

삭제 또는 연기:
- Normalized IR
- Codex 자동 Adapter
- Rules 자동 생성
- Rules 자동 배포
- mcp capability
- subagents capability
- model abstraction
- parallel/background execution
- status CLI
- clean CLI
- project-local override
- 세분화된 플랫폼 상태
- 플랫폼별 고급 기능의 공통화

다음 항목은 MVP에 포함하도록 결정했다.

- install CLI
- 안전한 symlink/copy 배포
- 생성과 배포의 분리
- capability 변환 결과 표시
- 실제 설치 환경에서의 선택적 integration test

이 항목들은 영구적으로 금지하는 것이 아니라, 실제 요구와 검증 결과에 따라 Phase 2 이후 추가한다.

⸻

20. 최종 제품 정의

제품 이름:

ai-agent

MVP 정의:

Claude Code와 OpenCode가 하나의 Agent Skills 저장소를 공유하고, 최소한의 Canonical Agent 정의를 각 플랫폼의 native 형식으로 생성·검증·안전하게 배포할 수 있도록 하는 로컬 SSOT 도구.

Phase 2 이후 정의:

검증된 여러 AI Coding Agent가 하나의 Skills·Agents·Rules 저장소를 공유하도록 표준 자산은 직접 공유하고, 플랫폼별 자산은 현재 버전에 맞는 native format으로 변환·검증·배포하는 로컬 SSOT 관리 도구.

핵심 원칙:

One Skill Source
One Agent Source
Direct Sharing First
Generation Only When Necessary
Generate and Install Are Separate
Doctor Is Read-Only
No Premature IR
No Unverified Adapter
No Automatic Rule Overwrite
No Silent Capability Loss
No Permission Escalation
Explicit Uncertainty

성공 기준은 다음과 같다.

Claude Code와 OpenCode를 교체해도 Skill과 Agent의 의미·역할 정의를 다시 작성하지 않아야 한다. 생성과 배포가 분리되어야 하며, 기존 사용자 파일은 자동으로 덮어쓰지 않아야 한다. Codex와 Rules는 실제 형식과 동작이 검증된 뒤에만 추가하며, 검증되지 않은 기능은 자동화하지 않는다.
