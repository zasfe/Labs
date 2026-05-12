다음 레퍼런스를 바탕으로, 내 코딩 에이전트 설정을 토큰 효율 관점에서 점검해줘.
- https://code.claude.com/docs/en/settings.md
- https://code.claude.com/docs/en/env-vars.md
- https://developers.openai.com/codex/config-reference.md
- https://github.com/cnighswonger/claude-code-cache-fix

목표는 성능 저하를 크게 만들지 않으면서 토큰 낭비를 줄이는 거야.
- 직접 절약(자동 주입 문맥, 긴 툴 출력 제한 등)과 간접 절약(검색/IDE/앱 경로 차단 등)을 구분해서 봐줘
- 현재 버전 공식 문서나 현재 설치본에서 확인되지 않은 키는 절대 추천하지 마

확인 대상:
- Claude Code: ~/.claude/settings.json, ~/.claude.json, 프로젝트별 .claude/settings.json, .claude/settings.local.json, 관련 환경변수( /^ANTHROPIC_|^CLAUDE_/)
- Codex: ~/.codex/config.toml, 프로젝트별 .codex/config.toml, 관련 환경변수(/^OPENAI_|^CODEX_/)
- 설정 파일이나 특정 설정 항목이 없으면 "명시 설정 없음"이라고 적고 documented default와 분리해서 설명해줘

작업 방식:
- 먼저 로컬 파일과 환경변수에서 실제 명시값만 확인해
- 그다음 공식 문서는 “현재 발견한 설정 키”와 “추천 후보 키”만 검증하는 데 써
- 문서 전체를 열거하지 말고, 확인에 필요한 키만 찾아
- 설정 파일이나 특정 항목이 없으면 “명시 설정 없음”이라고 적고 documented default와 분리해
- 로컬에 있으나 현재 공식 문서에서 확인되지 않는 키는 “로컬 존재 / 공식 확인 불가”로만 표시하고 추천 근거로 쓰지 마

출력 형식:
1. 현재 활성 설정 요약
2. 토큰을 직접 많이 먹는 항목
3. 토큰을 간접적으로 효율화할 수 있는 항목
4. 사용 패턴별 추천안
  - 로컬 코드 수정 위주
  - 최신 문서 검색 위주
  - IDE 문맥 공유 자주 사용
  - non-interactive 모드
5. 바로 적용 가능한 설정 diff 또는 코드블록
6. 추천하지 않는 변경
7. 절약은 되지만 품질을 크게 깎는 변경

주의:
- 각 추천마다 이유와 트레이드오프를 한 줄씩 붙여
- 공식 문서 링크는 추천한 키에 대해서만 붙여
- 없거나 deprecated인 키는 절대 제안하지 마

Claude Code에서 우선 확인할 레버:
- includeGitInstructions
- attribution
- autoInstallIdeExtension
- autoConnectIde
- CLAUDE_CODE_GLOB_NO_IGNORE
- BASH_MAX_OUTPUT_LENGTH
- CLAUDE_CODE_FILE_READ_MAX_OUTPUT_TOKENS
- MAX_MCP_OUTPUT_TOKENS
- ENABLE_CLAUDEAI_MCP_SERVERS
- CLAUDE_CODE_DISABLE_AUTO_MEMORY
- CLAUDE_CODE_DISABLE_CLAUDE_MDS
- CLAUDE_AGENT_SDK_DISABLE_BUILTIN_AGENTS
- --tools, --strict-mcp-config, --disable-slash-commands, --no-session-persistence, --exclude-dynamic-system-prompt-sections, --system-prompt 등 실행시 플래그들
- 참고: CLAUDE_CODE_SIMPLE, --bare 플래그는 oauth 로 로그인이 안 됨 (2.1.114 에서 최종 확인)

Codex에서 우선 확인할 레버:
- web_search
- tool_output_token_limit
- commit_attribution
- features.apps
- apps._default.enabled
- --profile, --json, --output-last-message, --sandbox read-only, --skip-git-repo-check, --ephemeral, --color never 등 실행 플래그들
- 기본 활성화된 openai-curated 플러그인들
