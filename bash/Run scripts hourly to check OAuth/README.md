# auth-check

Claude와 Codex의 OAuth 인증이 살아있는지 최소 토큰으로 주기적으로 점검하는 스크립트 모음.

## 파일 구성

```
auth-check.sh          # 통합 실행기 — 아래 두 스크립트를 병렬 호출, cron 관리 포함
claude-ok-minimal.sh   # Claude 단독 인증 확인 (Haiku, 522 토큰)
codex-ok-minimal.sh    # Codex 단독 인증 확인 (gpt-5.4-mini)
```

## 사전 준비

```bash
# Claude 인증 (한 번만)
claude auth login

# Codex 인증 (한 번만)
codex login
```

API 키는 필요 없습니다. OAuth/구독 인증만 사용합니다.

## 빠른 시작

```bash
# 1. 즉시 실행 — 두 도구를 동시에 체크
bash auth-check.sh

# 2. 매 정시 자동 실행 등록
bash auth-check.sh --install-cron

# 3. 상태 확인
bash auth-check.sh --status
```

## 각 스크립트 상세

### auth-check.sh — 통합 실행기

두 체크를 병렬로 실행하고 결과를 `~/.auth-check.log`에 기록합니다.

```bash
bash auth-check.sh                 # 즉시 실행
bash auth-check.sh run             # 위와 동일 (중복 실행 시 자동 skip)
bash auth-check.sh --install-cron  # cron 등록 (멱등 — 여러 번 실행해도 1개)
bash auth-check.sh --remove-cron   # cron 해제
bash auth-check.sh --status        # 등록 상태 + 최근 로그 10줄
bash auth-check.sh --log 100       # 로그 마지막 100줄
```

**실행 결과 예시:**

```
[2026-06-28 15:22:52] --- auth-check start ---
[2026-06-28 15:22:56] claude  OK  (input_tokens=522)
[2026-06-28 15:22:57] codex   OK  (input_tokens=6332)
[2026-06-28 15:22:57] --- all OK ---
```

**인증 만료 시 (FAIL 예시):**

```
[2026-06-28 16:00:01] --- auth-check start ---
[2026-06-28 16:00:03] claude  FAIL  exit=1
[2026-06-28 16:00:04] codex   OK  (input_tokens=6332)
[2026-06-28 16:00:04] --- FAILED (claude=1 codex=0) ---
```

**`--status` 출력 예시:**

```
=== Crontab entries ===
0 * * * * /home/john/auth-check.sh run >> /home/john/.auth-check.log 2>&1

=== Last 10 log lines ===
[2026-06-28 15:22:52] --- auth-check start ---
[2026-06-28 15:22:56] claude  OK  (input_tokens=522)
[2026-06-28 15:22:57] codex   OK  (input_tokens=6332)
[2026-06-28 15:22:57] --- all OK ---
```

---

### claude-ok-minimal.sh — Claude 단독 체크

```bash
bash claude-ok-minimal.sh                        # JSON 출력
SHOW_PROGRESS=1 bash claude-ok-minimal.sh        # stderr 포함 디버그
```

**출력 예시 (JSON):**

```json
{
  "type": "result",
  "subtype": "success",
  "is_error": false,
  "result": "ok",
  "usage": {
    "input_tokens": 522,
    "output_tokens": 77
  },
  "total_cost_usd": 0.00146
}
```

---

### codex-ok-minimal.sh — Codex 단독 체크

```bash
bash codex-ok-minimal.sh                                # turn.completed JSON 출력
SHOW_CODEX_PROGRESS=1 bash codex-ok-minimal.sh          # stderr 포함 디버그
```

**출력 예시 (JSON):**

```json
{
  "type": "turn.completed",
  "usage": {
    "input_tokens": 6332,
    "output_tokens": 12
  }
}
```

---

## 토큰 절감 효과 (Claude 기준)

최적화 적용 여부에 따른 실측 input_tokens 비교:

| 구성                          | input_tokens | 비율    |
|-------------------------------|-------------:|--------:|
| 모든 최적화 적용 (현재)        |          522 |    1x   |
| `--system-prompt` 제거        |        6,297 |   12x   |
| `--tools ""` 제거             |       15,916 |   30x   |
| 최적화 없음 (순수 기본값)      |       21,894 |   42x   |

> 기본 시스템 프롬프트(~6,000 토큰) + 툴 정의(~9,600 토큰) 제거가 핵심.
> 캐시 히트 시 단가는 낮아지지만 캐시 미스(첫 실행, 5분 이상 경과) 시에는 42배 차이.

---

## 자동화: cron 설정

```bash
# 등록 (멱등 — 여러 번 실행해도 항목 1개만 유지)
bash auth-check.sh --install-cron

# 등록된 항목 확인
crontab -l

# 해제
bash auth-check.sh --remove-cron
```

**등록 후 crontab 예시:**

```
0 * * * * /home/john/auth-check.sh run >> /home/john/.auth-check.log 2>&1
```

매 정시(`:00`)에 실행됩니다. 로그는 `~/.auth-check.log`에 누적되며 2,000줄 초과 시 자동으 로 오래된 항목부터 삭제됩니다.

---

## 멱등성 보장

| 상황 | 동작 |
|------|------|
| 이전 실행이 아직 돌고 있을 때 새 실행 | `flock`으로 감지, 즉시 skip |
| `--install-cron`을 여러 번 실행 | 기존 항목 제거 후 재추가 — 항목 1개만 유지 |

---

## 문제 해결

**인증 만료로 FAIL이 뜰 때:**

```bash
claude auth login   # Claude 재인증
codex login         # Codex 재인증
```

**스크립트가 실행되지 않을 때 (cron 환경):**

cron은 `PATH`가 제한되어 있습니다. `which claude`, `which codex`로 전체 경로를 확인한 후
스크립트 상단의 경로를 절대 경로로 수정하세요.

**디버그 모드로 자세한 출력 보기:**

```bash
SHOW_PROGRESS=1 bash claude-ok-minimal.sh
SHOW_CODEX_PROGRESS=1 bash codex-ok-minimal.sh
```
