# Claude Code / Codex 격리 샌드박스 완전 매뉴얼

> Windows + WSL2에서 Claude Code와 Codex를 **무제한 권한으로 안전하게** 돌리는 일회용 격리 환경.
> 개념 이해부터 실제 구축·사용까지 한 문서에 담았다.
> IT 지식이 많지 않아도 0장만 읽으면 전체 그림이 보인다.

---

## 📍 실행 위치 표기 약속

이 매뉴얼은 **명령을 어디서 치느냐**가 가장 중요하다.

| 배지 | 실행 위치 | 무엇을 하는 곳 |
|------|-----------|----------------|
| 🪟 **PS** | Windows PowerShell | 배포판 설치·삭제 |
| 🛠️ **Host** | 호스트 Work Ubuntu | 토큰·키 보관, wtest 명령 |
| 📦 **Template** | Template Ubuntu | 도구 굽기 (복사 전용) |
| 🧪 **Test** | 일회용 Test Ubuntu | Claude/Codex 실행 (자동 처리) |

---

# 0. 시작 전 읽기 — 핵심 개념

> 이 장만 읽으면 전체의 70%가 이해된다.

## 한 줄 요약

> **위험한 AI 도구를 일회용 방에 가두고, 일 끝나면 방을 통째로 버린다.**

## 무엇을 하려는 건가

Claude Code나 Codex를 `--dangerously-skip-permissions`(무제한 권한)로 돌리면 편하지만 위험하다.
AI가 실수로 또는 악의적 입력에 의해 **다른 프로젝트 파일을 건드리거나, 비밀번호·API키를 읽어 유출**할 수 있다.

이 매뉴얼은 그 위험을 "방 격리"로 푼다.

```
┌─────────────────────────────────────────────────────┐
│                 내 Windows PC (WSL2)                │
│                                                     │
│  ┌──────────────┐      ┌──────────────┐            │
│  │  Template    │      │    Host      │            │
│  │  (도장 원판)  │      │  (금고)      │            │
│  │              │      │              │            │
│  │ 도구 다 설치  │      │ SSH키·토큰   │            │
│  │ 복사 전용    │      │ 안전 보관    │            │
│  └──────┬───────┘      └──────┬───────┘            │
│         │ 복제                 │ 인증만 빌려줌       │
│         ▼                      ▼                    │
│  ┌──────────────────────────────────┐              │
│  │  proj-A Test (일회용 방)          │              │
│  │  Claude/Codex 무제한 권한         │              │
│  │  · /mnt/c 안 보임                 │              │
│  │  · 다른 프로젝트 안 보임          │              │
│  │  일 끝나면 방 통째로 버림 🗑️       │              │
│  └──────────────────────────────────┘              │
└─────────────────────────────────────────────────────┘
              │ git push
              ▼
        GitHub 사설 repo (코드 영속 보관)
```

## 도장 비유로 이해하기

| 역할 | 비유 | 실제 이름 | 하는 일 |
|------|------|-----------|---------|
| 원판 | 도장 원판 | `Ubuntu-26.04-Sandbox-Template` | 도구만 구워둔 깨끗한 원본, 복사만 함 |
| 금고 | 금고 | 호스트 Work Ubuntu | SSH키·인증토큰 보관, Test엔 안 줌 |
| 일회용 방 | 일회용 작업실 | `Ubuntu-26.04-Sandbox-proj-A` | AI가 일하는 곳, 끝나면 폐기 |

## 왜 일회용인가

```
[고정 환경에서 AI 실행]              [일회용 방에서 AI 실행]
   │                                    │
   AI가 흔적 남김                       방을 통째로 버림
   다른 프로젝트 오염 가능               다음 작업은 깨끗한 방에서
   비밀 읽으면 계속 노출                 방 버리면 흔적도 소멸
        │                                    │
        ▼                                    ▼
   위험 누적 😱                         피해 단발성 ✨
```

핵심 원리: **코드는 GitHub가 영구 보관하니, 실행 환경(방)은 버려도 안 잃는다.**
데이터 영속성(GitHub)과 실행 격리(일회용 방)를 분리한 것이 이 설계의 뼈대다.

## 3대 안심 포인트

이 매뉴얼이 보장하는 것:

```
비용 0      → 구독·오픈소스·무료만 사용, 추가 결제 없음
토큰 입력 0  → 한 번 등록하면 매번 자동, 토큰 붙여넣기 안 함
완전 격리    → AI가 무제한 권한이어도 방 밖은 못 건드림
```

## 자주 쓰는 명령 미리보기

```
wtest create  proj-A    ← 일회용 방 만들기 (자동으로 도구·인증 준비)
wtest claude  proj-A    ← 그 방에서 Claude Code 실행
wtest codex   proj-A    ← 그 방에서 Codex 실행
wtest destroy proj-A    ← 방 버리기
wtest doctor            ← 준비 상태 점검
```

---

# 1. 이렇게 설계한 이유 (선택 사항 — 원리가 궁금하면)

> 바로 구축하려면 2장으로 건너뛰어도 된다.

## 1.1 굽기 vs 주입 vs 클론 — 3계층

일회용 방의 핵심 질문은 "매번 새로 만드는데 뭘 어떻게 유지하나"다. 답은 셋으로 나누는 것:

| 계층 | 무엇 | 어디에 | 왜 |
|------|------|--------|-----|
| **굽기** | Claude Code·Codex·Node·git·gitleaks | Template | 안 바뀜, 매번 설치하면 느림 |
| **주입** | 인증 토큰·SSH 접근 | 호스트 → Test (생성 시) | 매번 로그인 회피 |
| **클론** | 코드·스킬·프로젝트 설정 | GitHub repo | 프로젝트마다 다름 |

## 1.2 인증 — "장기 자격증명은 방 밖, 단기 토큰만 안에"

3종 인증이 같은 철학으로 통일된다.

| 대상 | 주입 방식 | 방에 안 들어가는 것 | 비용 |
|------|-----------|---------------------|------|
| **SSH (git push)** | agent forwarding | 개인키 파일 | 0 |
| **Claude Code** | `CLAUDE_CODE_OAUTH_TOKEN` 환경변수 | (1년 토큰) | 구독 차감 |
| **Codex** | `CODEX_ACCESS_TOKEN` 환경변수 | refresh 토큰 | 구독 차감 |

핵심: AI가 무제한 권한으로 토큰을 훔쳐도, **장기 자격증명(SSH 개인키·refresh 토큰)은 방에 없으니** 피해가 단기로 제한된다.

> **주의 (Claude):** OAuth 토큰을 **공식 `claude` CLI에서 직접** 쓰는 건 정상.
> OpenClaw 등 서드파티 래퍼에 먹이면 Anthropic ToS 위반.

> **주의 (Codex):** access_token은 ~10일 만료. 만료되면 호스트에서 `codex login` 갱신 후 새 방 생성.

## 1.3 Secret 방어 — gitleaks 단독 (무료)

GitHub의 사설 repo secret scanning은 유료(시트당 과금)라 안 쓴다.
대신 오픈소스 **gitleaks**를 커밋 훅으로 — GitHub 도달 전 로컬에서 막으니 오히려 빠르다.

AI가 secret을 유출하는 3경로와 방어:

```
① 코드에 하드코딩 → 커밋    → gitleaks 훅이 차단
② 다른 프로젝트 secret 읽기  → 방 격리가 차단 (핵심)
③ 외부로 전송               → 네트워크 열려있어 완전차단 불가
                              → ②로 원천봉쇄 (읽을 게 없으면 보낼 것도 없음)
```

네트워크를 막지 않으면서 secret을 지키는 길은 **②(접근 차단)를 확실히** 하는 것이다.

## 1.4 구현 결정 (단서조항 포함)

| 항목 | 결정 | 단서 |
|------|------|------|
| ssh-agent forwarding | 채택 | wsl.exe 원격에서 안 되면 deploy key 폴백 (7장) |
| Codex 인증 | access_token 환경변수 | ~10일 만료, 호스트에서 재발급 |
| 스킬 연결 | 심볼릭 링크 | Test 내부 clone일 때만 (격리 유지) |
| gitleaks 룰 | 기본 + 사내 custom | custom은 스킬 repo에 커밋 |
| Template 갱신 | 수동 재굽기 (분기 1회) | Test 내 자동업데이트는 허용 |

---

# 2. 1회 구축 — 전체 흐름

```
[1회만 — 2~5장]                        [매번 — 6장]
─────────────────                      ──────────────
2. base + Template 생성                 wtest create <proj>
3. Template에 도구 굽기                  wtest claude/codex <proj>
4. 호스트 인증 준비                       git push (방 안)
5. wtest 설치                           wtest destroy <proj>
```

---

# 3. base 이미지 + Template 생성

🪟 **PS**

```powershell
# WSL 확인 및 base 설치
wsl --version
wsl --set-default-version 2
wsl --install -d Ubuntu-26.04
wsl --terminate Ubuntu-26.04

# base 백업본 생성
mkdir D:\wsl\base
wsl --export Ubuntu-26.04 D:\wsl\base\ubuntu-2604-base.tar

# Template 배포판 생성
mkdir D:\wsl\Ubuntu-26.04-Sandbox-Template
wsl --import Ubuntu-26.04-Sandbox-Template `
  D:\wsl\Ubuntu-26.04-Sandbox-Template `
  D:\wsl\base\ubuntu-2604-base.tar --version 2
```

✅ `D:\wsl\Ubuntu-26.04-Sandbox-Template\ext4.vhdx` 생성 확인.

---

# 4. Template에 도구 굽기

📦 **Template**

```powershell
wsl -d Ubuntu-26.04-Sandbox-Template
```

```bash
# 사용자 생성
id john || sudo adduser john
sudo usermod -aG sudo john

# provision 스크립트 실행 (template-provision.sh)
bash template-provision.sh john
```

이 스크립트가 굽는 것: Claude Code(native installer), Codex CLI, Node.js(nvm LTS),
gitleaks, git·jq·ripgrep, 그리고 `/etc/wsl.conf` Windows 차단 설정.

```bash
exit
```

```powershell
wsl --terminate Ubuntu-26.04-Sandbox-Template
```

> ⚠️ Template은 여기서 끝. 인증 정보는 **굽지 않는다** (방마다 주입).
> 이후 직접 접속하지 않고 복사(wtest create)만 한다.

---

# 5. 호스트 인증 준비 (1회)

🛠️ **Host** — Work Ubuntu

## 5.1 SSH 키

```bash
ssh-keygen -t ed25519 -C "sandbox@host"
cat ~/.ssh/id_ed25519.pub      # → GitHub Settings → SSH and GPG keys 등록

eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
```

## 5.2 Claude Code 토큰 (1년)

```bash
claude setup-token             # 브라우저 인증 후 토큰 출력
wtest setup-claude             # 출력된 토큰 붙여넣기 → ~/.wtest-tokens/claude_oauth (0600)
```

## 5.3 Codex 로그인 (구독)

```bash
codex login                    # ChatGPT 브라우저 인증 → ~/.codex/auth.json 생성
# wtest는 access_token만 추출해 주입 (refresh 토큰 제외)
```

---

# 6. wtest 설치

🛠️ **Host**

```bash
mkdir -p ~/scripts
cp wtest.sh ~/scripts/wtest.sh
chmod +x ~/scripts/wtest.sh

cat >> ~/.bashrc <<'EOF'
export PATH="$HOME/scripts:$PATH"
alias wtest='~/scripts/wtest.sh'
export GITHUB_USER=zasfe        # repo URL 조립용
EOF
source ~/.bashrc

wtest doctor                    # SSH·Claude·Codex·jq 전부 OK 확인
```

---

# 7. 일상 사용

🛠️ **Host** 중심

## 7.1 프로젝트 시작

```bash
wtest create proj-A
```

내부 동작: Template 복제 → 방 등록 → SSH forwarding 확인 → 코드+스킬 clone →
토큰 주입 → gitleaks 훅 설치.

## 7.2 Claude Code / Codex 실행

```bash
wtest claude proj-A     # 회사: Claude Code
wtest codex  proj-A     # 집: Codex
wtest enter  proj-A     # 방 셸 진입해서 직접
```

방 안에서 `claude`/`codex`가 로그인 없이 바로 작동. 무제한 권한이지만 이 방 안에서만 —
`/mnt/c` 없음, 다른 프로젝트 안 보임.

## 7.3 커밋·푸시

방 안에서 평소처럼:

```bash
git add . && git commit -m "..."   # gitleaks 훅이 secret 자동 차단
git push                            # agent forwarding 인증, 토큰 입력 0
```

## 7.4 작업 종료

```bash
wtest destroy proj-A    # 방 삭제 → 주입된 토큰도 소멸 (코드는 GitHub에 안전)
```

## 7.5 멀티 프로젝트

```bash
wtest create proj-A
wtest create proj-B     # 독립 방, 서로 격리
wtest list              # 활성 목록
```

---

# 8. 문제 해결

| 증상 | 원인 | 조치 |
|------|------|------|
| `wtest create` 인증 WARN | 호스트 인증 미비 | `wtest doctor` 확인 후 5장 재실행 |
| agent forwarding 실패 | wsl.exe 원격에서 SSH_AUTH_SOCK 미전달 | 아래 deploy key 폴백 |
| Codex 로그인 루프 | 캐시된 ChatGPT 세션 충돌 | 방은 일회용이라 미발생 / 호스트는 `codex logout` |
| `claude` ToS 경고 | 서드파티 래퍼에 토큰 사용 | 공식 `claude` CLI만 사용 |
| Codex 인증 만료 | access_token ~10일 경과 | 호스트 `codex login` 갱신 후 새 방 생성 |
| Template에서 `/mnt/c` 보임 | wsl.conf 미적용 | `automount.enabled=false` 확인 후 재시작 |

## agent forwarding 폴백 (deploy key)

forwarding이 환경에서 안 되면 프로젝트별 임시 deploy key:

```bash
wtest run proj-A 'ssh-keygen -t ed25519 -f ~/.ssh/deploy -N ""'
wtest run proj-A 'cat ~/.ssh/deploy.pub'
# → GitHub repo → Settings → Deploy keys 에 등록 (write 체크)
# 작업 종료 시 wtest destroy로 키 소멸, GitHub에서도 deploy key 삭제
```

---

# 부록 A. 용어 사전

| 용어 | 한 줄 설명 | 비유 |
|------|-----------|------|
| **WSL2** | Windows 안에서 진짜 리눅스를 돌리는 기능 | Windows 속 리눅스 PC |
| **배포판** | 리눅스 한 대. Ubuntu가 그 하나 | 리눅스 PC 한 대 |
| **Template / Test / Host** | 원판 / 일회용 방 / 금고 | 도장세트 |
| **VHDX** | 배포판 디스크 전체가 담긴 파일 | 방 전체를 담은 상자 |
| **agent forwarding** | 개인키 없이 인증만 빌려주는 방식 | 금고 안 열고 도장만 찍어줌 |
| **OAuth 토큰** | 구독 로그인 증표 | 출입증 |
| **access / refresh 토큰** | 단기 출입증 / 출입증 재발급권 | 일일권 / 정기권 |
| **gitleaks** | 코드 속 비밀을 찾아 커밋 막는 도구 | 검색대 |
| **무제한 권한** | AI가 승인 없이 명령 실행 | 프리패스 |

# 부록 B. 한 페이지 요약

```
[구축 1회]
  3장: base + Template 배포판 생성 (PowerShell)
  4장: Template에 도구 굽기 (template-provision.sh)
  5장: 호스트 인증 — SSH키 / claude setup-token / codex login
  6장: wtest 설치

[매 프로젝트]
  wtest create  <proj>    방 생성 + 인증 주입
  wtest claude  <proj>    Claude Code 실행
  wtest codex   <proj>    Codex 실행
  (방 안) git push        gitleaks 통과 → GitHub
  wtest destroy <proj>    방 폐기

[원칙]
  비용 0 · 토큰 입력 0 · 완전 격리
  장기 자격증명은 방 밖, 단기 토큰만 안에
```

# 부록 C. 출처

> 📄출처: [Anthropic, Claude Code Authentication, 2026, https://code.claude.com/docs/en/authentication], [Anthropic, Claude Code Advanced setup, 2026, https://code.claude.com/docs/en/setup], [OpenAI, Codex Authentication, 2026, https://developers.openai.com/codex/auth], [OpenAI, Maintain Codex account auth in CI/CD, 2026, https://developers.openai.com/codex/auth/ci-cd-auth], [GitHub, About GitHub Advanced Security, 2026, https://docs.github.com/en/get-started/learning-about-github/about-github-advanced-security], [gitleaks, gitleaks releases, 2026, https://github.com/gitleaks/gitleaks]
