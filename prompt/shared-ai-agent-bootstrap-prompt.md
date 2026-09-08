Shared AI Agent Architecture 초기 구성 지시문

당신은 AI Agent Runtime Architecture를 설계하고 초기화하는 역할을 수행한다.

목표는 Claude Code, Codex, Hermes 등 서로 다른 AI Agent가 하나의 SSOT(Single Source of Truth)를 공유하면서 동일한 Skill, Agent 역할, 실행 정책을 사용할 수 있는 구조를 만드는 것이다.

특정 AI 제품에 종속된 구조를 만들지 않는다.

1. 목표 구조

다음 구조를 기준으로 초기 프로젝트를 구성한다.

shared-ai/
├── AGENTS.md
│
├── policies/
│   ├── context.md
│   ├── verification.md
│   └── approval.md
│
├── skills/
│   └── README.md
│
├── agents/
│   ├── researcher.md
│   ├── architect.md
│   ├── implementer.md
│   └── reviewer.md
│
└── adapters/
    ├── codex/
    ├── claude/
    └── hermes/

shared-ai/를 SSOT로 취급한다.

Adapter에 공통 정책이나 Skill을 복제하지 않는다. 가능하면 symlink 또는 각 도구가 지원하는 참조 방식을 사용한다.

2. AGENTS.md

AGENTS.md에는 세부 기술 지식을 넣지 않는다.

다음 내용만 정의한다.

* 기본 실행 원칙
* Skill 탐색 방법
* Agent 선택 및 위임 방법
* Context 로딩 원칙
* 위험도 판정 원칙
* 검증 원칙
* 승인 필요 여부 판단 방법

세부 절차는 policies/, skills/, agents/로 분리한다.

3. Progressive Disclosure

Agent는 처음부터 모든 Skill과 Reference를 읽지 않는다.

다음 순서를 따른다.

Task
 ↓
Task Classification
 ↓
관련 Skill 탐색
 ↓
SKILL.md 로딩
 ↓
작업 수행
 ↓
추가 정보가 필요한가?
 ├─ NO → 계속 수행
 └─ YES
      ↓
   필요한 Reference만 로딩

Skill은 가능하면 다음 구조를 사용한다.

skills/<skill-name>/
├── SKILL.md
├── references/
├── scripts/
└── templates/

SKILL.md는 가능한 한 작게 유지한다.

상세 문서, 예제, 기술 자료는 references/로 분리한다.

4. Risk-based Verification

작업 또는 변경의 위험도를 다음 세 단계로 분류한다.

LOW
MEDIUM
HIGH

LOW

예:

* 문서 수정
* 주석 수정
* formatting
* 비실행 파일 변경

최소한의 검증만 수행한다.

MEDIUM

예:

* 일반 애플리케이션 코드
* 설정 변경
* dependency 변경
* API 변경

관련 범위의 lint, unit test 및 필요한 검증을 수행한다.

HIGH

예:

* 인증/인가
* 데이터베이스 변경
* 운영 인프라
* 배포
* 보안 설정
* 데이터 삭제
* 외부 시스템에 영향을 주는 변경

integration/regression/security 등 해당 변경에 필요한 강화된 검증을 수행한다.

검증 범위는 고정하지 않는다.

핵심 원칙은 다음과 같다.

Verification Level ∝ Change Risk

5. Approval Policy

Agent는 불필요한 중간 승인을 요청하지 않는다.

다음 작업은 기본적으로 자율적으로 수행한다.

READ
- 파일 읽기
- 코드 분석
- 로그 분석
- 검색
- 상태 확인
LOCAL WRITE
- 코드 수정
- 테스트 작성
- 문서 작성
- 안전하게 복구할 수 있는 로컬 파일 변경
VERIFY
- lint
- unit test
- build
- 정적 분석
- 안전한 로컬 테스트

다음과 같은 작업은 실행 직전에 사용자 승인을 요구한다.

DESTRUCTIVE / EXTERNAL IMPACT
- 운영 배포
- 데이터 삭제
- 운영 DB 변경
- Cloud Resource 삭제
- Credential 변경
- 외부 시스템 상태 변경
- 비용이 발생하는 작업
- 복구가 어렵거나 비가역적인 작업

승인이 필요한 작업이 발견되었다고 해서 전체 작업을 즉시 중단하지 않는다.

승인 없이 수행할 수 있는 분석, 구현 및 검증을 먼저 완료한 뒤 실제 영향이 발생하는 경계에서 승인을 요청한다.

6. Agent 역할

초기에는 Agent를 최소한으로 구성한다.

researcher

정보 탐색, 자료 조사, 기존 코드 및 문서 분석을 담당한다.

architect

요구사항 분석, 시스템 구조, 인터페이스 및 기술적 의사결정을 담당한다.

implementer

코드, 설정, 자동화 및 테스트 구현을 담당한다.

reviewer

구현 결과, 요구사항 충족 여부, 위험 및 회귀 가능성을 검토한다.

Agent 정의에는 기술 지식을 중복해서 작성하지 않는다.

필요한 기술 지식은 skills/에서 가져온다.

7. Adapter 원칙

다음 Agent Runtime을 지원할 수 있도록 설계한다.

Codex
Claude Code
Hermes

각 Runtime의 고유한 설정 형식이 필요하면 adapters/에서 처리한다.

              shared-ai
                 SSOT
                   │
        ┌──────────┼──────────┐
        ▼          ▼          ▼
      Codex      Claude     Hermes
     Adapter     Adapter     Adapter
        │          │          │
        ▼          ▼          ▼
      Codex    Claude Code   Hermes

Adapter에는 가능한 한 다음 내용만 포함한다.

* Runtime별 bootstrap
* 경로 연결
* Runtime-specific configuration
* 호환성 변환

공통 정책, Skill 또는 Agent 정의를 Adapter 내부에 복제하지 않는다.

8. 설계 원칙

다음 우선순위를 유지한다.

SSOT
>
Progressive Disclosure
>
Runtime Independence
>
Minimal Context
>
Risk-based Verification
>
Minimal Approval

새로운 규칙을 추가하기 전에 기존 규칙으로 해결할 수 있는지 먼저 확인한다.

중복된 지침을 만들지 않는다.

특정 모델의 Prompt 특성에 전체 Architecture를 종속시키지 않는다.

9. 초기 작업

현재 작업 디렉터리를 먼저 조사한다.

기존 다음 항목이 있다면 삭제하거나 덮어쓰지 말고 재사용 가능성을 판단한다.

AGENTS.md
CLAUDE.md
skills/
agents/
.codex/
.claude/
Hermes 관련 설정

그 후 다음 순서로 진행한다.

1. 현재 구조 조사
2. 기존 설정과 충돌 분석
3. shared-ai 구조 설계
4. 최소 디렉터리 생성
5. AGENTS.md 작성
6. policies 작성
7. 기본 agents 작성
8. Runtime adapter 구성
9. 참조/symlink 구조 구성
10. 구조 검증

기존 파일을 파괴적으로 변경하지 않는다.

10. 완료 조건

다음 조건이 모두 충족되어야 한다.

[ ] shared-ai가 SSOT이다.
[ ] 공통 정책이 Runtime별로 복제되지 않는다.
[ ] Skill을 필요할 때만 읽을 수 있다.
[ ] Reference를 필요할 때만 읽을 수 있다.
[ ] Agent 역할과 Skill이 분리되어 있다.
[ ] LOW/MEDIUM/HIGH 위험도 정책이 존재한다.
[ ] 위험도에 따른 검증 정책이 존재한다.
[ ] Approval 경계가 명확하다.
[ ] Codex Adapter가 존재한다.
[ ] Claude Code Adapter가 존재한다.
[ ] Hermes Adapter가 존재한다.
[ ] 기존 환경을 파괴하지 않는다.

11. 실행 지시

설명만 작성하지 말고 실제 현재 환경을 조사하여 구현한다.

불확실한 사항이 있더라도 안전하게 확인할 수 있다면 직접 조사한다.

구현 과정에서 일반적인 파일 생성, 수정, 검사 및 테스트에 대해서는 중간 승인을 요청하지 않는다.

비가역적 변경이나 기존 중요 설정의 파괴가 필요한 경우에만 실행 직전에 승인을 요청한다.

마지막에는 다음 항목만 보고한다.

1. 생성/변경한 구조
2. 주요 설계 결정
3. Runtime별 연결 방법
4. 검증 결과
5. 남아 있는 문제
6. 사용자 승인이 필요한 작업
