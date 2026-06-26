## 생성 파일

* [Claude Code agent 파일: `hephaestus.claude.md`](sandbox:/mnt/data/hephaestus.claude.md)
* [Codex agent 파일: `hephaestus.codex.toml`](sandbox:/mnt/data/hephaestus.codex.toml)
* [설치 안내: `hephaestus-agent-install.md`](sandbox:/mnt/data/hephaestus-agent-install.md)

## 적용 위치

```bash
# Claude Code
mkdir -p .claude/agents
cp hephaestus.claude.md .claude/agents/hephaestus.md

# Codex
mkdir -p .codex/agents
cp hephaestus.codex.toml .codex/agents/hephaestus.toml
```

## 변환 기준

* 원본 `gpt-5-5.ts`의 Hephaestus 핵심 정책 유지
* OpenCode 전용 `task_create`, `task_update`, `todowrite`, `task()`, `background_output()` 도구명 제거 또는 런타임 중립화
* Claude Code는 Markdown + YAML frontmatter 포맷 적용
* Codex는 standalone TOML custom agent 포맷 적용
* Codex TOML 파싱 검증 완료
* Claude Code frontmatter 구조 확인 완료

> 📄출처: [code-yeongyu, oh-my-openagent `gpt-5-5.ts`, 2026, ([GitHub][1])], [Anthropic, Claude Code Subagents, 2026, ([Claude Platform Docs][2])], [OpenAI, Codex Subagents, 2026, ([OpenAI Developers][3])], [OpenAI, Codex AGENTS.md, 2026, ([OpenAI 개발자][4])], [프로젝트 업로드 메모, Agent Notes, 2026, ]

[1]: https://raw.githubusercontent.com/code-yeongyu/oh-my-openagent/refs/heads/dev/packages/omo-opencode/src/agents/hephaestus/gpt-5-5.ts?utm_source=chatgpt.com "raw.githubusercontent.com"
[2]: https://docs.anthropic.com/en/docs/claude-code/sub-agents?utm_source=chatgpt.com "Create custom subagents - Claude Code Docs"
[3]: https://developers.openai.com/codex/subagents?utm_source=chatgpt.com "Subagents – Codex | OpenAI Developers"
[4]: https://developers.openai.com/codex/guides/agents-md "Custom instructions with AGENTS.md – Codex | OpenAI Developers"
