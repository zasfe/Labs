# Hephaestus Agent Files

## 파일

- Claude Code: `.claude/agents/hephaestus.md`
- Codex: `.codex/agents/hephaestus.toml`

## 설치

### Claude Code

```bash
mkdir -p .claude/agents
cp hephaestus.claude.md .claude/agents/hephaestus.md
```

Claude Code 세션을 재시작하거나 `/agents`에서 확인한다.

### Codex

```bash
mkdir -p .codex/agents
cp hephaestus.codex.toml .codex/agents/hephaestus.toml
```

Codex에서 이 agent를 명시적으로 spawn하거나 agent 선택 기능에서 `hephaestus`를 사용한다.

## 변환 기준

- 원본 OpenCode 전용 `task_create`, `task_update`, `todowrite`, `task()`, `background_output()` 같은 도구명은 Claude Code/Codex 런타임에 맞게 제거 또는 일반화했다.
- 원본의 핵심 정책인 자율 실행, 탐색 후 구현, 수동 QA 게이트, 실패 복구, 비파괴 Git 원칙, 타입 안정성 금지는 유지했다.
- Claude Code는 Markdown + YAML frontmatter 포맷을 사용한다.
- Codex는 standalone TOML custom agent 포맷을 사용한다.
