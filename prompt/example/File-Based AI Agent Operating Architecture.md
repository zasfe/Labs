
# File-Based AI Agent Operating Architecture

> 버전: 1.0  
> 작성일: 2026-11-17  
> 분류: 재사용 가능한 AI 에이전트 운영 아키텍처  
> 적용 대상: Codex, Claude Code, Hermes, OpenClaw 및 기타 AI 에이전트

## 1. 문서 목적

이 문서는 AI 에이전트가 공유된 업무 맥락을 기반으로 작업을 수행하고, 실행 결과를 기록하며, 사람의 피드백을 반영하는 파일 기반 운영 구조를 정의합니다.

특정 마케팅 도구에 종속되지 않으며, 다음과 같은 업무에 재사용할 수 있습니다.

- 마케팅 캠페인 자동화
- 클라우드 MSP 운영 및 장애 분석
- 제품 경쟁력 분석
- 기술 조사 및 보고서 작성
- 소프트웨어 개발 및 검증
- 다중 AI 에이전트 협업

핵심 원칙은 다음과 같습니다.

1. Markdown 파일을 사람이 이해하고 수정할 수 있는 기준 정보로 사용합니다.
2. 사실, 정책, 실행 절차, 결과를 서로 분리합니다.
3. 모든 에이전트가 동일한 기준 문서를 참조합니다.
4. 에이전트가 생성한 추론은 검증 전까지 공식 정책으로 취급하지 않습니다.
5. 외부 변경이나 비용이 발생하는 작업은 승인 후 실행합니다.
6. 실패와 수정 이력을 다음 작업에 반영합니다.
7. 처음에는 하나의 에이전트로 시작하고 검증 후 확장합니다.

---

## 2. 설계 배경

### 2.1 기존 AI 에이전트의 문제

AI 에이전트를 여러 개 운영하더라도 다음과 같은 문제가 발생할 수 있습니다.

- 에이전트마다 사업과 업무에 대한 이해가 다릅니다.
- 이전에 실패한 작업을 반복합니다.
- 실제 고객이나 운영 환경의 맥락이 누락됩니다.
- 잘못된 추론이 공식 정보처럼 축적됩니다.
- 에이전트가 변경되면 작업 맥락이 사라집니다.
- 실행 결과와 의사결정 근거를 추적하기 어렵습니다.
- 사람이 작업을 검토하거나 중단하기 어렵습니다.

### 2.2 해결 방향

에이전트 내부 기억에 의존하지 않고, 공유 파일 시스템에 업무 지식을 명시적으로 저장합니다.

운영 구조는 다음과 같습니다.

```text
사람
 │
 ▼
기준 정보 및 정책
 │
 ▼
공유 업무 맥락
 │
 ▼
AI 에이전트
 │
 ├── 정보 수집
 ├── 분석 및 판단
 ├── 실행 계획
 └── 결과물 작성
 │
 ▼
검증 및 승인
 │
 ▼
실행 및 결과 기록
 │
 ▼
피드백과 교훈
 │
 └──────> 기준 정보 개선
```

### 2.3 핵심 설계 철학

이 구조는 단순한 프롬프트 저장소가 아닙니다.

**사람이 통제할 수 있는 파일 기반 AI 운영 시스템**입니다.

Markdown은 사람이 관리하는 기준 정보와 작업 기록을 담당합니다.

에이전트는 해당 정보를 읽고 작업을 수행하며, 검증된 결과만 기준 정보에 반영합니다.

---

## 3. 전체 디렉터리 구조

```text
agent-workspace/
│
├── README.md
├── START-HERE.md
├── AGENTS.md
│
├── company/
│   ├── customer-fit.md
│   └── offers.md
│
├── brand/
│   ├── voice.md
│   └── founder-opinions.md
│
├── decisions/
│   ├── failed-campaigns.md
│   ├── agent-corrections.md
│   └── decision-log.md
│
├── evidence/
│   ├── calls/
│   ├── customer-language/
│   ├── research/
│   └── observations/
│
├── workflows/
│   ├── customer-language/
│   │   ├── AGENTS.md
│   │   ├── contract.md
│   │   └── workflow.md
│   │
│   ├── buying-signals/
│   ├── search/
│   ├── ad-creative/
│   ├── winback/
│   └── performance/
│
├── campaigns/
│   └── BK014/
│       ├── brief.md
│       ├── evidence.md
│       ├── approval.md
│       └── results.md
│
├── tests/
│   └── golden-cases/
│
└── templates/
    ├── workflow-template.md
    ├── agent-contract-template.md
    └── decision-template.md
```

### 3.1 원문과 확장 설계 구분

원문에서 직접 제안한 핵심 요소는 다음과 같습니다.

- `START-HERE.md`
- `company/customer-fit.md`
- `company/offers.md`
- `brand/voice.md`
- `brand/founder-opinions.md`
- `decisions/failed-campaigns.md`
- `evidence/calls/`
- `evidence/customer-language/`
- `workflows/`

`campaigns/`는 원문에서 설명한 캠페인 ID와 실행 기록을 파일 구조로 구체화한 것입니다.

`AGENTS.md`, `contract.md`, `tests/`, `templates/` 및 기타 보조 파일은 실제 운영을 위해 추가한 권장 설계입니다.

---

## 4. 최상위 파일

### 4.1 README.md

**목적:** 프로젝트 전체를 설명합니다.

포함 내용:

- 프로젝트 목적
- 전체 아키텍처
- 폴더 구조
- 설치 및 실행 방법
- 운영 방법
- 관련 문서 링크

이 파일은 사람을 위한 프로젝트 안내서입니다.

### 4.2 START-HERE.md

**목적:** 에이전트가 작업을 시작할 때 가장 먼저 읽는 문서입니다.

포함 내용:

- 조직 및 사업 개요
- 현재 목표
- 주요 고객 또는 서비스 대상
- 우선순위
- 운영 제약
- 핵심 문서 위치
- 작업 시작 절차

예시:

```yaml
project: marketing-agent
goal: qualified-customer-acquisition
priority:
  - customer-research
  - campaign-experiment
  - performance-analysis

required_context:
  - company/customer-fit.md
  - company/offers.md
  - brand/voice.md
  - decisions/failed-campaigns.md
```

실제 작업을 시작하기 전에 필요한 문서만 선택적으로 읽도록 구성합니다.

### 4.3 AGENTS.md

**목적:** 모든 에이전트가 준수해야 하는 공통 실행 규칙을 정의합니다.

포함 내용:

- 작업 범위
- 파일 읽기 및 쓰기 권한
- 승인 조건
- 실패 처리
- 출력 형식
- 검증 절차
- 중단 조건

예시:

```markdown
# Agent Operating Rules

## Required

1. Read START-HERE.md first.
2. Read relevant context files.
3. Separate facts from assumptions.
4. Preserve source references.
5. Do not modify company policies without approval.
6. Record execution results.
7. Report failed or skipped operations.
8. Request approval before external actions.

## Prohibited

- Unauthorized external publication
- Unauthorized spending
- Silent modification of policy files
- Destructive operations without approval
- Treating unverified assumptions as facts
```

---

## 5. company/ : 업무 기준 정보

### customer-fit.md

**역할:** 어떤 고객 또는 작업 대상이 적합한지 정의합니다.

마케팅에서는 이상적인 고객 프로필을 기록합니다.

MSP 운영에서는 지원 대상 고객, 서비스 등급, 지원 범위를 정의하는 용도로 확장할 수 있습니다.

포함 내용:

- 대상 고객
- 적합성 조건
- 제외 조건
- 우선순위
- 수익성 또는 업무 중요도

### offers.md

**역할:** 제공할 수 있는 서비스와 허용 범위를 정의합니다.

포함 내용:

- 상품 및 서비스
- 가격과 조건
- 제공 범위
- 보장 가능한 사항
- 승인 없이 약속할 수 없는 사항

에이전트가 임의로 서비스 범위나 가격을 변경하지 않도록 하는 기준입니다.

---

## 6. brand/ : 표현과 관점

### voice.md

**역할:** 조직이 사용하는 문체와 표현 기준을 정의합니다.

포함 내용:

- 선호하는 표현
- 피해야 하는 표현
- 승인된 문서 예시
- 거절된 문서 예시
- 승인 및 거절 사유

추상적인 형용사보다 실제 승인·거절 사례를 활용합니다.

### founder-opinions.md

**역할:** 조직이나 의사결정권자의 고유한 관점을 기록합니다.

포함 내용:

- 시장에 대한 관점
- 고객에 대한 이해
- 경쟁사와의 차별점
- 전략적 판단 기준
- 장기적인 방향성

일반적인 AI 모델 지식만으로 재현하기 어려운 조직 고유의 판단 근거를 제공합니다.

---

## 7. decisions/ : 의사결정과 학습

### failed-campaigns.md

**역할:** 과거에 실패한 실험과 원인을 기록합니다.

포함 내용:

- 시도한 작업
- 초기 가설
- 실제 결과
- 실패 원인
- 재발 방지 방안

### agent-corrections.md

**역할:** 에이전트가 잘못 판단하거나 실행한 사례를 기록합니다.

예시:

```markdown
## CORR-001

Date: 2026-11-17
Agent: customer-language

### Problem
특정 고객의 발언을 전체 고객의 요구로 일반화했습니다.

### Cause
발언 빈도만 고려하고 고객 수를 구분하지 않았습니다.

### Correction
발언 빈도와 고유 고객 수를 별도로 집계합니다.

### Verification
기존 테스트 사례를 재실행합니다.
```

### decision-log.md

**역할:** 승인된 주요 의사결정을 기록합니다.

권장 항목:

- 결정 ID
- 결정 일자
- 배경
- 검토한 대안
- 선택한 방안
- 결정 근거
- 승인자
- 변경 또는 폐기 조건

---

## 8. evidence/ : 사실과 근거

**목적:** 에이전트가 수집한 원본 정보와 검증되지 않은 분석을 보관합니다.

하위 폴더:

| 경로 | 역할 |
|---|---|
| calls/ | 고객 통화 및 인터뷰 기록 |
| customer-language/ | 고객 표현 분석 |
| research/ | 조사 결과와 출처 |
| observations/ | 관찰 내용과 가설 |

### 운영 원칙

1. 원본 데이터를 가능한 한 보존합니다.
2. 수집 시점과 출처를 기록합니다.
3. 관찰 사실과 추론을 구분합니다.
4. 검증되지 않은 가설은 명시적으로 표시합니다.
5. 에이전트가 evidence에 기록했다고 해서 공식 정책이 되지는 않습니다.

권장 메타데이터:

```yaml
id: EVD-001
created_at: 2026-11-17
source: customer-interview
status: unverified
confidence: medium
owner: customer-language-agent
```

`confidence`는 모델의 추정 수준이며 검증 완료를 의미하지 않습니다.

---

## 9. workflows/ : 에이전트 실행 절차

**목적:** 에이전트별 업무 범위와 실행 방법을 분리합니다.

각 에이전트는 독립적인 작업 계약을 가집니다.

### 9.1 공통 구조

```text
workflows/<agent-name>/
├── AGENTS.md
├── contract.md
└── workflow.md
```

### AGENTS.md

해당 에이전트의 역할과 규칙을 정의합니다.

### contract.md

입력, 출력, 권한, 완료 조건을 명시합니다.

### workflow.md

업무 수행 순서와 검증 절차를 정의합니다.

### 9.2 에이전트 목록

| 에이전트 | 주요 업무 |
|---|---|
| customer-language | 고객 언어 및 요구 분석 |
| buying-signals | 구매 가능성을 높이는 사건 탐색 |
| search | 검색 수요와 질문 분석 |
| ad-creative | 광고 소재와 메시지 제작 |
| winback | 실패 계약 재접촉 기회 탐색 |
| performance | 성과 분석 및 후속 실험 제안 |

### 9.3 작업 계약 예시

```yaml
agent: customer-language

purpose:
  - Extract customer problems
  - Identify recurring expressions

inputs:
  - evidence/calls/

outputs:
  - evidence/customer-language/

permissions:
  read:
    - company/
    - brand/
    - evidence/
  write:
    - evidence/customer-language/

approval_required:
  - company-policy-change
  - external-publication

completion:
  - all-available-sources-checked
  - evidence-linked
  - assumptions-labeled
  - failures-reported
```

권한 정의는 문서에만 기록하지 않고 실제 실행 도구와 파일 접근 제어에도 적용해야 합니다.

---

## 10. campaigns/ : 실행 및 결과 추적

**목적:** 하나의 작업 또는 실험을 고유 ID로 관리합니다.

```text
campaigns/BK014/
├── brief.md
├── evidence.md
├── approval.md
└── results.md
```

### brief.md

실험 목적, 가설, 성공 기준, 기간을 기록합니다.

### evidence.md

실험을 제안한 근거와 원본 자료를 연결합니다.

### approval.md

실행 승인 상태와 승인 조건을 기록합니다.

### results.md

실행 결과와 다음 행동을 기록합니다.

권장 상태:

```text
DRAFT
  ↓
REVIEW
  ↓
APPROVED
  ↓
RUNNING
  ↓
COMPLETED
  ↓
EVALUATED
```

승인 거절은 `REJECTED`, 실행 실패는 `FAILED`, 중단은 `CANCELLED`로 별도 기록합니다.

### 성과 분석

각 실험은 다음 네 가지 결정 중 하나로 마무리합니다.

- KEEP: 현재 방식을 유지합니다.
- STOP: 실행을 중단합니다.
- MODIFY: 조건을 변경합니다.
- EXPERIMENT: 새로운 실험을 수행합니다.

---

## 11. tests/ : 에이전트 품질 검증

**목적:** 지시문이나 모델을 변경했을 때 기존 기능이 저하되는지 확인합니다.

### Golden Case

검증된 입력과 기대 출력을 보관하는 테스트 사례입니다.

```text
tests/golden-cases/
├── case-001/
│   ├── input.md
│   └── expected.md
└── case-002/
    ├── input.md
    └── expected.md
```

검증 항목:

1. 사실을 정확하게 추출했는지 확인합니다.
2. 출처를 유지했는지 확인합니다.
3. 추측을 사실로 표현하지 않았는지 확인합니다.
4. 금지된 행동을 수행하지 않았는지 확인합니다.
5. 출력 형식을 준수했는지 확인합니다.
6. 이전에 수정한 오류가 재발하지 않았는지 확인합니다.

처음에는 에이전트별 대표 사례 10개 정도로 시작합니다.

---

## 12. templates/ : 재사용 가능한 양식

**목적:** 에이전트와 작업을 추가할 때 동일한 구조를 사용합니다.

### workflow-template.md

```markdown
# Workflow

## Objective
이 작업의 목적을 작성합니다.

## Inputs
필요한 입력 자료를 작성합니다.

## Steps
1. 자료를 수집합니다.
2. 내용을 분석합니다.
3. 결과를 작성합니다.
4. 결과를 검증합니다.

## Outputs
생성할 결과물을 작성합니다.

## Failure Handling
실패 시 보고 및 재시도 조건을 작성합니다.
```

### agent-contract-template.md

```markdown
# Agent Contract

## Identity
에이전트 이름과 역할을 작성합니다.

## Scope
허용된 작업 범위를 작성합니다.

## Permissions
읽기 및 쓰기 권한을 작성합니다.

## Approval
승인이 필요한 행동을 작성합니다.

## Completion
완료 판정 조건을 작성합니다.

## Reporting
실행 결과와 실패 보고 형식을 작성합니다.
```

---

## 13. 실행 흐름

### Phase 1. Context Loading

에이전트가 다음 문서를 확인합니다.

1. START-HERE.md
2. AGENTS.md
3. 해당 workflow의 contract.md
4. 작업과 관련된 company 및 brand 문서
5. 관련된 decisions 및 evidence 문서

모든 파일을 무조건 읽지 않고 작업에 필요한 정보만 선택합니다.

### Phase 2. Planning

에이전트가 실행 계획을 작성합니다.

계획에는 다음 항목을 포함합니다.

- 작업 목적
- 입력 자료
- 예상 결과
- 실행 단계
- 위험 요소
- 승인 필요 여부

### Phase 3. Execution

승인된 범위에서 작업을 수행합니다.

읽기 전용 작업과 외부 상태를 변경하는 작업을 구분합니다.

### Phase 4. Verification

결과의 정확성과 완료 조건을 검증합니다.

### Phase 5. Approval

필요한 경우 사람이 결과를 검토합니다.

### Phase 6. Recording

실행 결과와 의사결정을 파일로 기록합니다.

### Phase 7. Learning

오류와 개선 사항을 decisions에 반영합니다.

기준 정보 변경은 사람의 승인을 받은 후 수행합니다.

---

## 14. 사람과 에이전트의 권한 분리

| 작업 | 에이전트 | 사람 |
|---|---|---|
| 정보 수집 | 실행 | 감독 |
| 자료 분석 | 실행 | 검토 |
| 가설 작성 | 실행 | 평가 |
| 콘텐츠 초안 | 실행 | 승인 |
| 공식 정책 변경 | 제안 | 승인 |
| 외부 게시 | 초안 작성 | 승인 |
| 비용 지출 | 제안 | 승인 |
| 데이터 삭제 | 원칙적으로 금지 | 별도 승인 |
| 실행 결과 기록 | 실행 | 감사 |

### 권한 관리 원칙

- 기본 권한은 읽기 전용입니다.
- 쓰기 권한은 필요한 폴더로 제한합니다.
- 외부 실행 권한은 별도 승인 절차를 적용합니다.
- 승인 여부는 코드 수준에서 검사합니다.
- 실행 중단 수단을 마련합니다.
- 중요한 변경은 Git으로 추적합니다.

---

## 15. 다중 에이전트 확장

### 15.1 기본 구조

```text
             Human Operator
                    │
                    ▼
              Main Agent
                    │
          ┌─────────┼─────────┐
          ▼         ▼         ▼
       Agent A   Agent B   Agent C
          │         │         │
          └─────────┼─────────┘
                    ▼
             Shared Files
                    │
                    ▼
               Verification
                    │
                    ▼
                 Approval
```

### 15.2 운영 원칙

1. 메인 에이전트는 작업 분배와 결과 통합을 담당합니다.
2. 서브 에이전트는 정의된 업무만 수행합니다.
3. 에이전트마다 쓰기 권한을 분리합니다.
4. 공유 기준 파일은 임의로 수정하지 않습니다.
5. 동일 파일의 동시 수정을 방지합니다.
6. 결과를 통합하기 전에 검증합니다.

### 15.3 상태 저장 방식

초기에는 Markdown과 Git만 사용합니다.

다음 조건이 발생하면 SQLite 도입을 검토합니다.

- 여러 에이전트가 동시에 작업 상태를 변경합니다.
- 작업 큐의 원자적 처리가 필요합니다.
- 중복 실행 방지가 필요합니다.
- 대량 실행 이력을 검색해야 합니다.
- 재시도 및 장애 복구 상태를 관리해야 합니다.

SQLite를 도입하더라도 업무 기준 정보는 Markdown에 유지합니다.

Markdown은 사람이 관리하는 지식과 정책을 담당하고, SQLite는 기계가 관리하는 실행 상태를 담당하도록 역할을 구분합니다.

---

## 16. 운영 품질 평가 기준

| 평가 항목 | 측정 방법 |
|---|---|
| 맥락 정확도 | 기준 문서와 결과의 일치 여부 |
| 사실 정확도 | 근거 자료와 결과의 일치 여부 |
| 작업 완료율 | 완료 작업 / 전체 작업 |
| 승인 준수율 | 승인 대상 작업의 승인 이행률 |
| 오류 재발률 | 기존 수정 오류의 재발 비율 |
| 재현 가능성 | 동일 입력에 대한 핵심 결과 일치 여부 |
| 추적 가능성 | 결과에서 원본 근거까지 추적 가능 여부 |
| 운영 개입량 | 작업당 사람의 수정 및 승인 시간 |

### 자율성 확대 조건

다음 조건을 충족한 작업부터 자율 실행 범위를 확대합니다.

1. 대표 테스트 사례를 통과합니다.
2. 주요 오류가 반복되지 않습니다.
3. 출처와 실행 결과를 추적할 수 있습니다.
4. 권한 경계를 위반하지 않습니다.
5. 실패 상황을 명확하게 보고합니다.
6. 사람이 실행을 중단할 수 있습니다.

자율성은 에이전트의 수가 아니라, 검증된 작업 범위와 신뢰성에 따라 확대합니다.

---

## 17. 단계별 도입 계획

### 1단계: 최소 구조

```text
agent-workspace/
├── START-HERE.md
├── AGENTS.md
├── company/
├── decisions/
├── evidence/
└── workflows/
```

하나의 에이전트만 운영합니다.

### 2단계: 품질 검증

- 작업 계약을 추가합니다.
- Golden Case를 작성합니다.
- 오류 수정 이력을 축적합니다.
- 결과 검증 절차를 도입합니다.

### 3단계: 실행 추적

- 캠페인 또는 작업 ID를 부여합니다.
- 승인 절차를 도입합니다.
- 실행 결과를 기록합니다.
- Git으로 변경을 관리합니다.

### 4단계: 다중 에이전트

- 업무별 에이전트를 분리합니다.
- 메인 에이전트가 작업을 분배합니다.
- 공유 파일 충돌을 방지합니다.
- 검증된 결과만 통합합니다.

### 5단계: 자율 운영

- 정기 실행을 추가합니다.
- 반복 작업을 자동화합니다.
- 장애 복구와 재시도를 구현합니다.
- 위험 수준에 따라 승인 정책을 차등 적용합니다.

---

## 18. 다른 프로젝트에 적용하는 방법

이 구조를 다른 프로젝트에 적용할 때는 다음과 같이 매핑합니다.

| 원래 구조 | 범용 적용 |
|---|---|
| company/ | 조직 정책 및 업무 기준 |
| brand/ | 표현 규칙 및 조직 고유 관점 |
| decisions/ | 의사결정 및 실패 교훈 |
| evidence/ | 원본 자료 및 검증 근거 |
| workflows/ | 작업별 에이전트 실행 절차 |
| campaigns/ | 작업 및 실험 실행 이력 |
| tests/ | 품질 검증 사례 |
| templates/ | 재사용 가능한 작업 양식 |

### MSP 운영 적용 예시

```text
msp-agent/
├── START-HERE.md
├── AGENTS.md
│
├── company/
│   ├── service-scope.md
│   └── sla-policy.md
│
├── decisions/
│   ├── incident-lessons.md
│   └── agent-corrections.md
│
├── evidence/
│   ├── logs/
│   ├── metrics/
│   └── incidents/
│
├── workflows/
│   ├── incident-analysis/
│   ├── performance-analysis/
│   ├── vulnerability-review/
│   └── report-generation/
│
├── operations/
│   └── INC-20261117-001/
│       ├── brief.md
│       ├── evidence.md
│       ├── approval.md
│       └── results.md
│
└── tests/
    └── golden-cases/
```

이 예시에서는 `campaigns/`를 `operations/`로 변경하여 운영 작업을 관리합니다.

실제 로그나 고객 정보는 Git에 직접 저장하지 않고, 접근이 통제된 별도 저장소에 보관한 후 참조 경로와 요약만 기록할 수 있습니다.

---

## 19. 설계 원칙 요약

### Principle 1. Context First

에이전트를 추가하기 전에 공유 맥락을 정리합니다.

### Principle 2. Evidence Before Decision

판단보다 근거를 먼저 확보합니다.

### Principle 3. Human-Controlled Policy

공식 정책의 최종 변경 권한은 사람에게 있습니다.

### Principle 4. Explicit Contracts

에이전트마다 업무 범위와 완료 조건을 명시합니다.

### Principle 5. Progressive Autonomy

검증된 작업부터 자율성을 확대합니다.

### Principle 6. Reproducible Execution

실행 과정과 결과를 재현할 수 있도록 기록합니다.

### Principle 7. Minimal Infrastructure

처음부터 데이터베이스나 복잡한 오케스트레이터를 도입하지 않습니다.

### Principle 8. Continuous Improvement

실패와 수정 사항을 다음 실행에 반영합니다.

---

## 20. 향후 AI 에이전트에게 전달할 지시문

이 문서를 새로운 AI 에이전트에게 제공할 때 다음 지시를 사용합니다.

> 첨부한 문서는 파일 기반 AI 에이전트 운영 아키텍처입니다.
>
> 이 구조의 설계 목적, 파일별 역할, 데이터 흐름, 승인 체계, 검증 및 학습 원칙을 유지하세요.
>
> 새로운 프로젝트에 적용할 때는 다음 순서로 진행하세요.
>
> 1. 프로젝트 목적과 기존 운영 환경을 파악합니다.
> 2. 원래 구조에서 재사용할 요소를 식별합니다.
> 3. 프로젝트에 맞게 폴더명과 파일명을 조정합니다.
> 4. 각 파일의 책임과 관리 권한을 정의합니다.
> 5. 에이전트별 작업 계약을 작성합니다.
> 6. 실행, 검증, 승인, 기록 절차를 정의합니다.
> 7. 최소 실행 구조부터 구현합니다.
> 8. 검증 결과에 따라 확장합니다.
>
> 사람의 통제 가능성, 근거 추적, 재현성, 최소한의 인프라 구성을 우선합니다.
>
> 기존 파일을 삭제하거나 덮어쓰기 전에 변경 내용을 제시하고 승인을 받으세요.
>
> 문서에 없는 정보를 사실로 가정하지 마세요.

---

## 21. 참고 자료

### 원문

- 제목: 마케팅 엔지니어: AI 에이전트로 100배 더 많은 실험하기
- 게시: GeekNews
- 게시일: 2026-10-16
- URL: https://news.hada.io/topic?id=35448

### 설계 확장

이 문서는 원문의 마케팅 에이전트 운영 방식을 일반적인 AI 에이전트 아키텍처로 확장한 것입니다.

다음 요소는 재사용성과 실제 운영을 위해 추가했습니다.

- 전역 AGENTS.md
- 에이전트별 작업 계약
- Golden Case 테스트
- 의사결정 로그
- 명시적인 실행 상태
- 파일별 접근 권한
- 다중 에이전트 협업 규칙
- Markdown과 SQLite의 역할 분리
- MSP 운영 적용 예시

### 최종 정의

**File-Based AI Agent Operating Architecture**

사람이 관리하는 Markdown 기반 지식과 정책을 중심으로, AI 에이전트가 정의된 작업 계약에 따라 실행하고, 근거와 결과를 기록하며, 검증과 승인을 통해 지속적으로 개선하는 운영 아키텍처입니다.
