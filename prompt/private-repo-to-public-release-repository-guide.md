# Private Repository 기반 Public Release Repository 구축 지시서

## 1. 문서 목적

현재 운영 중인 **Private GitHub Repository**를 유지하면서, 사용자에게는 **Public Release Repository의 Release 파일만 제공**하는 구조를 구축한다.

이 문서는 다른 AI 에이전트 또는 작업자가 그대로 수행할 수 있도록 작성된 **작업 지시서**이다.

---

## 2. 최종 목표

Private Repository는 개발과 빌드 전용으로 유지한다.

Public Repository는 배포 전용으로 사용한다.

사용자는 Public Repository의 `/releases/latest` 페이지에서 최신 배포 파일만 다운로드한다.

---

## 3. 핵심 원칙

### 3.1 Private Repository는 절대 Public으로 변경하지 않는다

소스코드는 Private Repository에만 존재해야 한다.

---

### 3.2 Public Repository에는 소스코드를 Commit하지 않는다

Public Repository에 허용되는 파일은 아래만 사용한다.

```text
README.md
LICENSE
```

그 외 파일은 GitHub Release Asset으로만 제공한다.

---

### 3.3 Public Release Repository는 Build Repository가 아니다

Build, Test, Package, Signing, SBOM 생성은 모두 Private Repository의 GitHub Actions에서 수행한다.

---

### 3.4 Release Upload만으로 완료 처리하지 않는다

Release Asset 업로드 후 반드시 다시 다운로드하여 검증한다.

필수 검증 항목은 아래와 같다.

```text
SHA256 검증
압축 해제 검증
실행 가능 여부 검증
버전 출력 검증
Manifest 일치 여부 검증
```

---

## 4. 목표 아키텍처

```text
Developer
    |
    | git tag v1.2.3
    | git push origin v1.2.3
    v

Private Repository
    |
    | GitHub Actions
    v

Test
    |
    v
Build
    |
    v
Package
    |
    v
Security Scan
    |
    v
SBOM 생성
    |
    v
Artifact Attestation 생성
    |
    v
Code Signing
    |
    v
Release Asset 생성
    |
    v
Public Release Repository에 Release 생성
    |
    v
Release Asset 업로드
    |
    v
Release Asset 재다운로드
    |
    v
SHA256 / 실행 / 버전 검증
    |
    v
Publish 완료
```

---

## 5. Repository 구성

### 5.1 Private Repository

역할:

```text
개발
소스코드 관리
빌드
테스트
릴리즈 자동화
보안 검증
패키징
```

포함 항목:

```text
source/
tests/
.github/workflows/
docs/
build scripts
```

---

### 5.2 Public Release Repository

역할:

```text
사용자 다운로드
Release Asset 배포
Release Notes 제공
무결성 검증 파일 제공
```

포함 항목:

```text
README.md
LICENSE
GitHub Releases
```

포함 금지 항목:

```text
source code
build script
internal docs
secret
.env
test data
private config
```

---

## 6. Public Repository 권장 이름

권장 형식:

```text
<project-name>-releases
```

예시:

```text
backend-ai-go-releases
myapp-releases
agent-tool-releases
```

---

## 7. Release Asset 구성

Release마다 아래 파일을 포함한다.

```text
project-windows-x64.zip
project-linux-x64.tar.gz
project-linux-arm64.tar.gz
project-macos-arm64.zip
SHA256SUMS
manifest.json
sbom.spdx.json
release-notes.md
```

선택 항목:

```text
*.sig
*.asc
provenance.json
attestation.jsonl
```

---

## 8. manifest.json 표준

Release마다 `manifest.json`을 생성한다.

예시:

```json
{
  "name": "project-name",
  "version": "v1.2.3",
  "channel": "stable",
  "commit": "abcdef1234567890",
  "tag": "v1.2.3",
  "build_time": "2026-06-26T00:00:00Z",
  "assets": [
    {
      "name": "project-linux-x64.tar.gz",
      "os": "linux",
      "arch": "x64",
      "sha256": "CHANGE_ME",
      "size": 12345678,
      "download_url": "https://github.com/ORG/REPO/releases/download/v1.2.3/project-linux-x64.tar.gz"
    }
  ]
}
```

목적:

```text
무결성 검증
자동 업데이트 준비
운영 자동화
다운로드 링크 표준화
```

---

## 9. GitHub Actions Trigger 정책

기본 Trigger:

```yaml
on:
  push:
    tags:
      - "v*"
```

운영 기준:

```text
v1.2.3        Stable Release
v1.2.3-beta.1 Beta Release
v1.2.3-rc.1   Release Candidate
```

---

## 10. Workflow 분리 기준

처음에는 단일 Workflow로 시작해도 된다.

단, 장기 운영 시 아래처럼 분리한다.

```text
test.yml
build.yml
release.yml
publish.yml
cleanup.yml
```

우선순위:

```text
1. release.yml
2. test.yml
3. build.yml
4. publish.yml
5. cleanup.yml
```

---

## 11. 인증 방식

Public Release Repository에 Release를 생성하려면 Private Repository의 GitHub Actions가 Public Repository에 쓰기 권한을 가져야 한다.

권장 우선순위:

```text
1. GitHub App
2. Fine-grained Personal Access Token
3. Classic Personal Access Token
```

운영 원칙:

```text
최소 권한
만료일 설정
Repository 단위 제한
Secret으로만 저장
Workflow 로그에 출력 금지
```

필수 Secret 예시:

```text
PUBLIC_RELEASE_REPO_TOKEN
PUBLIC_RELEASE_REPO_OWNER
PUBLIC_RELEASE_REPO_NAME
```

---

## 12. 공급망 보안

초기부터 아래 항목을 검토한다.

```text
SBOM
Provenance
Artifact Attestation
Immutable Release
Code Signing
SHA256SUMS
```

우선 적용 순서:

```text
1. SHA256SUMS
2. manifest.json
3. SBOM
4. Artifact Attestation
5. Code Signing
6. Immutable Release
```

---

## 13. Artifact Attestation

목적:

```text
배포 파일이 어떤 Workflow에서
어떤 Commit으로
어떤 빌드 과정을 통해
생성되었는지 증명
```

적용 여부를 반드시 검토한다.

---

## 14. SBOM

Release마다 SBOM을 생성한다.

권장 형식:

```text
SPDX JSON
CycloneDX JSON
```

파일명 예시:

```text
sbom.spdx.json
sbom.cyclonedx.json
```

---

## 15. Immutable Release

가능하면 Immutable Release 적용을 검토한다.

목적:

```text
Release 발행 후 Asset 변경 차단
Tag 이동 차단
공급망 공격 방어
Release 무결성 강화
```

주의:

```text
Immutable Release 적용 후에는 Asset 수정이 불가능할 수 있으므로
검증 완료 후 Publish하는 구조가 필요하다.
```

---

## 16. Code Signing

OS별 적용 여부를 검토한다.

```text
Windows: Authenticode
macOS: Apple Notarization
Linux: GPG Signature
```

초기에는 SHA256 + manifest.json으로 시작하고, 이후 Code Signing을 추가한다.

---

## 17. Release Validation

Release 업로드 후 아래 절차를 자동화한다.

```text
1. Public Release Repository에서 Asset 다운로드
2. SHA256SUMS와 실제 Hash 비교
3. 압축 해제
4. 실행 파일 권한 확인
5. --version 실행
6. manifest.json 내용과 비교
7. 실패 시 Release를 Draft 상태로 유지하거나 삭제
```

---

## 18. README.md 구성

Public Release Repository의 README는 짧게 유지한다.

예시:

```markdown
# Project Releases

이 저장소는 Project의 바이너리 배포 전용 저장소입니다.

소스코드는 포함하지 않습니다.

## Download

Latest Release:

https://github.com/ORG/project-releases/releases/latest

## Verification

다운로드 후 SHA256SUMS 파일로 무결성을 확인하십시오.
```

---

## 19. Repository Settings

Public Release Repository에서 아래 기능은 비활성화 검토한다.

```text
Issues
Discussions
Wiki
Projects
Packages
```

유지할 항목:

```text
Releases
README
Security advisories 여부 검토
```

---

## 20. Version 정책

Semantic Versioning을 기본으로 한다.

```text
vMAJOR.MINOR.PATCH
```

예시:

```text
v1.0.0
v1.1.0
v1.1.1
v2.0.0
```

정책:

```text
MAJOR: 호환성 깨지는 변경
MINOR: 기능 추가
PATCH: 버그 수정
```

---

## 21. Release Channel

필요 시 Channel을 분리한다.

```text
stable
beta
rc
nightly
dev
```

초기 권장:

```text
stable
beta
```

---

## 22. Artifact 보존 정책

정책을 명시한다.

권장:

```text
Stable: 전체 보존
Beta: 최근 10개 보존
Nightly: 30일 보존
Hotfix: 전체 보존
```

---

## 23. Rollback 정책

다음 상황별 복구 절차를 문서화한다.

```text
잘못된 Tag 생성
잘못된 Release 발행
Asset 누락
Hash 불일치
실행 파일 오류
Public Repository 권한 오류
GitHub Actions 실패
```

Rollback 원칙:

```text
기존 Release를 조용히 수정하지 않는다.
새 Patch Release를 발행한다.
문제가 있는 Release에는 경고 문구를 추가한다.
```

---

## 24. 산출물

Private Repository에 아래 문서를 작성한다.

```text
docs/release-architecture.md
docs/release-workflow.md
docs/release-security.md
docs/release-operation-manual.md
docs/release-disaster-recovery.md
```

Public Release Repository에는 아래만 둔다.

```text
README.md
LICENSE
```

---

## 25. 완료 기준

아래 조건을 모두 만족해야 완료로 본다.

```text
[ ] Private Repository가 Public으로 변경되지 않음
[ ] Public Repository에 Source Code가 없음
[ ] Public Repository에는 README.md와 LICENSE만 존재함
[ ] Release Asset은 GitHub Releases에만 업로드됨
[ ] Tag 생성 시 Release Workflow가 자동 실행됨
[ ] Release Asset이 자동 생성됨
[ ] SHA256SUMS가 생성됨
[ ] manifest.json이 생성됨
[ ] Release 업로드 후 재다운로드 검증이 수행됨
[ ] SBOM 적용 여부가 문서화됨
[ ] Artifact Attestation 적용 여부가 문서화됨
[ ] Immutable Release 적용 여부가 문서화됨
[ ] Rollback 절차가 문서화됨
[ ] 운영자가 같은 절차를 재현할 수 있음
```

---

## 26. 작업자에게 주는 최종 지시

이 작업의 핵심은 단순한 Release 업로드 자동화가 아니다.

목표는 아래 세 가지이다.

```text
1. Source Code 비공개 유지
2. Release 파일 공개 배포 자동화
3. Release 무결성 및 출처 검증 가능 구조 확보
```

구현 시 편의성을 이유로 Public Repository에 소스코드, 빌드 스크립트, 내부 문서를 추가하지 않는다.

Release Repository는 끝까지 배포 전용 Repository로 유지한다.

```

>📄출처: [GitHub Docs, About releases, 2026, GitHub Release는 Git Tag 기반으로 배포 가능한 소프트웨어와 Release Asset을 제공하는 기능](https://docs.github.com/en/repositories/releasing-projects-on-github/about-releases) :contentReference[oaicite:0]{index=0}  
>📄출처: [GitHub Docs, Artifact attestations, 2026, GitHub Actions 기반 빌드 출처 및 무결성 증명 기능](https://docs.github.com/en/actions/concepts/security/artifact-attestations) :contentReference[oaicite:1]{index=1}  
>📄출처: [GitHub Docs, Immutable releases, 2026, Release Asset과 Git Tag 변경 차단을 통한 공급망 보안 강화 기능](https://docs.github.com/en/code-security/concepts/supply-chain-security/immutable-releases) :contentReference[oaicite:2]{index=2}
```
