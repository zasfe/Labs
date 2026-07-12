# 운영 워크플로우 상세

> **이것은 바이브 코딩이 아니다.** AI 출력을 읽지도 않고 수락하는 게 아니다.
> 모든 계획은 검토되고, 모든 결과물은 검증되며, 모든 결정 뒤에는 사람이 있다.

거시적 워터폴(계획→승인→구현→검증) + 미시적 애자일(단계별 반복)을 AI가 동시에 수행하게 한다.

## 핵심 원칙

| 구분 | 바이브 코딩 | 이 프로젝트 |
|------|------------|-------------|
| **사람의 역할** | AI 출력 수락 | 지시, 검토, 결정 |
| **계획** | 없음 | 계획서 작성 → 승인 → 실행 |
| **품질 관문** | 동작하길 바람 | 단계별 승인 + 테스트 통과 |
| **디버깅** | AI에게 AI 버그 수정 요청 | 사람이 진단, AI가 구현 |
| **문서** | 없음 | mydocs/ 에 전 과정 기록 |

## 타스크 진행 절차

모든 정식 타스크는 아래 절차를 따른다. 단계를 건너뛰지 않는다.

1. GitHub Issue 등록 (또는 `## TODO / 백로그` 항목 참조)
2. 오늘할일(`mydocs/orders/yyyymmdd.md`) 기록
3. 타스크 브랜치 생성 (`local/task{번호}`)
4. **수행계획서** 작성 → **[작업지시자 승인]**
5. **구현계획서** 작성→ 다음 단계
6. 단계별 구현
7. **단계별 완료보고서** → 다음 단계
8. **최종 결과보고서** → **[작업지시자 승인]**
9. 오늘할일 상태 갱신

각 **[승인]** 지점이 품질 게이트다. 방향성 오류를 코드가 쌓이기 전에 잡는다.

## AI Context Loading / Memory / Context Budget

> AI는 모든 문서를 읽지 않는다.
> 필요한 문서만 읽고, 필요한 지식만 기억하며, 제한된 Context를 효율적으로 사용한다.

---

### 1. Context Loading 규칙

#### 목적

프로젝트가 커질수록 모든 문서를 읽는 것은 비효율적이다.

모든 AI Agent는 동일한 순서로 Context를 로드하여
항상 동일한 판단을 수행하도록 한다.

#### Context Loading 순서

```
1. AGENTS.md
2. 현재 Task 관련 HANDOFF.md
3. orders/yyyyMMdd.md
4. 현재 Task 수행계획서
5. 현재 Task 구현계획서
6. 가장 최신 working 보고서
7. 현재 Task와 직접 연결된 spec
8. 현재 Task와 직접 연결된 tech
9. 현재 Task와 직접 연결된 troubleshooting
10. 현재 Task와 관련된 ADR
```

읽는 순서는 반드시 위 순서를 따른다.

상위 문서는 하위 문서보다 우선한다.

예)

```
AGENTS.md

↓

Task Plan

↓

Working

↓

Spec

↓

Tech
```

---

#### 문서 선택 규칙

##### 반드시 읽는다

- 현재 Task 계획서
- 최신 Working
- AGENTS.md

##### 필요 시 읽는다

- spec
- tech
- troubleshooting
- ADR

관련성이 없는 문서는 읽지 않는다.

예)

Task

```
로그인 버그 수정
```

읽음

```
spec/auth.md

tech/jwt.md

troubleshooting/login_timeout.md
```

읽지 않음

```
spec/payment.md

tech/openstack.md
```

---

#### Context 우선순위

동일한 내용이 여러 문서에 존재할 경우

우선순위는

```
AGENTS.md

>

현재 Task Plan

>

Working

>

ADR

>

Spec

>

Tech

>

Troubleshooting
```

이다.

---

### 2. Memory 승격 기준

#### 목적

모든 정보를 Memory로 저장하지 않는다.

반복적으로 사용될 가치가 있는 정보만
Project Memory로 승격한다.

---

#### 승격 대상

다음 조건 중 하나 이상 만족하면
Memory 승격 후보이다.

□ 프로젝트 전체 Coding Rule
□ Architecture Rule
□ Agent 운영 규칙
□ 반복적으로 발생한 장애 해결법
□ 동일한 패턴이 3회 이상 발생
□ 향후 모든 Task에서 사용될 규칙

---

#### 승격 제외

다음은 Memory에 저장하지 않는다.

- 현재 Task 전용 정보
- 임시 실험 결과
- 개인 메모
- 미검증 정보
- 승인되지 않은 설계

---

#### 승격 절차

```
Task 완료

↓

Tech 또는 Spec 작성

↓

Review

↓

Human 승인

↓

Memory 등록

↓

다음 Task부터 자동 사용
```

---

#### Memory 수정

기존 Memory와 충돌하는 경우

```
기존 Memory 삭제 금지

↓

Deprecated 표시

↓

새로운 Memory 추가

↓

ADR 기록
```

---

### 3. Context Budget

#### 목적

LLM Context는 유한하다.

모든 문서를 읽는 것이 아니라
가장 가치 있는 정보를 우선 사용한다.

---

#### 권장 Budget

| 구분 | 최대 비율 |
|-------|----------|
| Global Rule | 20% |
| Project Memory | 20% |
| 현재 Task | 35% |
| Working | 15% |
| Spec | 5% |
| Tech | 5% |
| Troubleshooting | 5% |
| ADR | 5% |

현재 Task Context는
항상 가장 높은 우선순위를 가진다.

---

#### Budget 부족 시 제거 순서

Context가 부족하면
아래 순서대로 제거한다.

```
History

↓

Working(오래된 것)

↓

Tech

↓

Troubleshooting

↓

Spec

↓

ADR

↓

Project Memory
```

다음 항목은 절대 제거하지 않는다.

- AGENTS.md
- 현재 Task
- 현재 Plan
- 최신 Working
- Human 지시사항

---

### Sub Agent Context

Sub Agent는 Main Agent의 전체 Context를 복사하지 않는다.

Main Agent는 필요한 정보만 요약하여 전달한다.

```
Main Agent

↓

Task 요약

관련 파일

제약사항

참고 문서

↓

Sub Agent
```

Sub Agent는

- 독립적인 Context
- 독립적인 Token
- 독립적인 추론

을 수행한다.

---

### Context 최소화 원칙

Sub Agent에는

"작업 수행에 필요한 정보만"

전달한다.

절대로

- 전체 History
- 전체 Working
- 전체 Spec
- 전체 Repository 설명

을 전달하지 않는다.

---

### Context 전달 템플릿

```
Task

목표

완료 조건

관련 파일

수정 가능 파일

수정 금지 파일

제약사항

참고 Spec

참고 Tech

참고 ADR

예상 결과
```

---

### 최종 원칙

AI는

많이 읽는 것이 아니라

**정확하게 읽는 것**을 목표로 한다.

Memory는

많이 저장하는 것이 아니라

**반복 가치가 있는 정보만 저장**한다.

Context는

최대한 크게 사용하는 것이 아니라

**최대한 작게 사용하여 정확도를 높인다.**


## 문서 체계 (mydocs/)

```
mydocs/
├── orders/           # 오늘 할일 (yyyymmdd.md) — 새 세션에서 "지금 뭘 해야 하지?" 답
├── plans/            # 수행계획서 + 구현계획서 — "어떻게 할 것인가"
│   └── archives/     # 완료된 계획서 보관
├── working/          # 단계별 완료보고서 — "어디까지 했는가"
├── report/           # 최종 결과보고서 — "결과가 무엇인가"
├── feedback/         # 코드 리뷰 피드백 — "무엇이 틀렸는가" (AI가 스스로 만들 수 없는 문서)
├── tech/             # 기술 사항 정리 — "무엇을 발견했는가" (세션 간 지식 영구화)
├── spec/             # 설계 사항 정리 — "무엇을 기반으로 하는가" (세션 간 지식 영구화)
└── troubleshootings/ # 트러블슈팅 — "이 함정에 다시 빠지지 마라"
```

**왜 문서가 필요한가**: AI는 세션이 끊기면 기억이 사라진다. 문서가 있으면 새 세션에서도 컨텍스트 전달 없이 `orders/` → `working/` → `plans/` 순으로 읽어 즉시 작업 재개 가능.

## 문서 파일명 규칙

| 문서 | 위치 | 파일명 | 예시 |
|------|------|--------|------|
| 오늘 할일 | `orders/` | `yyyymmdd.md` | `20260525.md` |
| 수행 계획서 | `plans/` | `task_{번호}.md` | `task_1.md` |
| 구현 계획서 | `plans/` | `task_{번호}_impl.md` | `task_1_impl.md` |
| 단계별 보고서 | `working/` | `task_{번호}_stage{N}.md` | `task_1_stage1.md` |
| 최종 보고서 | `report/` | `task_{번호}_report.md` | `task_1_report.md` |
| 피드백 | `feedback/` | `task_{번호}_feedback.md` | `task_1_feedback.md` |
| 기술 정리 | `tech/` | 주제별 자유 명명 | `spring_security_block.md` |
| 설계 정리 | `spec/` | 주제별 자유 명명 | `spring_spec.md` |
| 트러블슈팅 | `troubleshootings/` | 주제별 자유 명명 | `ims_keepalive_bug.md` |


