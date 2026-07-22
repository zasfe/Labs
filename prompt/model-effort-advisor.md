# AI 모델 및 Reasoning Effort 운영 가이드

## 목적

작업 단계별로 적절한 AI 모델과 Reasoning Effort를 사용하여 다음 목표를 동시에 달성한다.

- 품질 확보
- 토큰 및 비용 절감
- 응답 속도 향상
- 긴 세션으로 인한 Context 오염 방지

이 문서는 Claude Code와 Codex를 모두 사용하는 환경을 기준으로 작성되었으며, 특정 프로젝트에 종속되지 않는다.

---

# 운영 원칙

## 1. 단계마다 새로운 세션을 시작한다.

하나의 긴 세션을 유지하지 않는다.

각 단계는

- 필요한 문서를 읽고
- 작업을 수행하고
- 문서를 저장한 뒤
- 세션을 종료한다.

다음 단계는 반드시 새로운 세션에서 시작한다.

---

## 2. 모델과 Effort는 세션 시작 전에 선택한다.

Claude Code와 Codex는 실행 중 모델이나 Reasoning Effort를 변경하지 않는다.

따라서 새로운 작업 단계가 시작되면 아래 권장 모델을 확인한 후 새로운 세션을 시작한다.

---

# 단계별 권장 모델

| 작업 단계 | Claude Code | Claude Effort | Codex | Codex Effort | 비고 |
|------------|-------------|---------------|--------|---------------|------|
| 작업 분석 | Opus | High | GPT-5 Thinking | High | 요구사항 이해, 조사 |
| 수행계획서 작성 | Opus | High | GPT-5 Thinking | High | 방향 결정 |
| 구현계획서 작성 | Opus | High | GPT-5 Thinking | High | 설계 및 변경 범위 결정 |
| 코드 구현 | Sonnet | Medium | GPT-5 Codex | Medium | 구현 중심 |
| 단위 테스트 | Sonnet | Medium | GPT-5 Codex | Medium | 테스트 및 수정 |
| 리팩토링 | Sonnet | Medium | GPT-5 Codex | Medium | 최소 변경 원칙 |
| 코드 리뷰 | Opus | High | GPT-5 Thinking | High | 논리 검증 |
| Progress 작성 | Sonnet | Low | GPT-5 Mini | Low | 단순 문서화 |
| Stage Summary 작성 | Sonnet | Low | GPT-5 Mini | Low | 핵심 요약 |
| 결과보고서 작성 | Sonnet | Low | GPT-5 Mini | Low | 문서화 |
| Postmortem | Opus | High | GPT-5 Thinking | High | 회고 및 개선 |

---

# 모델 선택 기준

## Opus / GPT-5 Thinking

사용 시점

- 설계
- 분석
- 구조 결정
- 원인 분석
- 리뷰
- Postmortem

특징

- 긴 추론
- 높은 정확도
- 비용이 큼

---

## Sonnet / GPT-5 Codex

사용 시점

- 코드 작성
- 수정
- 테스트
- 리팩토링

특징

- 구현 속도 우수
- 코드 생성 효율 우수
- 비용 대비 성능 우수

---

## GPT-5 Mini

사용 시점

- Progress
- 보고서
- Stage Summary
- 체크리스트
- 단순 변환

특징

- 매우 저렴
- 빠른 응답
- 복잡한 추론에는 사용하지 않음

---

# 세션 시작 체크리스트

새로운 단계를 시작하기 전에 아래 항목을 확인한다.

- 현재 단계에 맞는 모델을 선택했는가
- 현재 단계에 맞는 Reasoning Effort를 선택했는가
- 필요한 문서만 준비했는가
- 이전 세션은 종료했는가

---

# 세션 종료 규칙

현재 단계가 완료되면

1. 계획서 또는 보고서를 저장한다.
2. Progress를 갱신한다.
3. Stage Summary를 작성한다(필요한 경우).
4. 세션을 종료한다.

다음 단계는 반드시 새로운 세션에서 시작한다.

---

# 사용자 안내

작업을 시작하기 전에 아래 권장 모델을 확인하십시오.

현재 단계에 맞는 모델과 Reasoning Effort를 선택한 후 새로운 세션을 시작하십시오.

모델 변경은 실행 중에는 적용되지 않으며, 새로운 세션에서만 적용됩니다.

작업이 완료되면 문서를 저장한 후 현재 세션을 종료하고 다음 단계를 시작하십시오.
