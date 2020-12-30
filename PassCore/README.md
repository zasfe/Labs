# PassCore

Active Directory 환경에서 스스로 비밀번호를 변경할 수 있는 단일 페이지 웹서비스를 생성할 수 있는 패키지 입니다.

https://github.com/unosquare/passcore

## 설치 - Install

### 사전 준비

1. IIS 가 설치되어 있어야 합니다. 
   * <code powershell>Install-WindowsFeature -name Web-Server -IncludeManagementTools</code>
2. ASP.NET Core Runtime가 설치 되어 있어야 합니다.
   *  https://dotnet.microsoft.com/download/dotnet-core/thank-you/runtime-aspnetcore-3.1.0-windows-hosting-bundle-installer

### 설치 및 세팅

1. PassCore Release파일을 다운받아서 압축 해제합니다.
   * URL: https://github.com/unosquare/passcore/releases (저는 4.2.2 로 진행했습니다.)
   * 압축 해제 경로: C:\PassCore422
   * 테스트 환경: PassCore Version 4.2.2, Windows server 2019(IIS 10.0), on-promise Active Directory
2. IIS 설정을 합니다.
   1. powershell 버전<code powershell>Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/unosquare/passcore/master/IISSetup.ps1'))</code>
   2. GUI 버전
      * `IIS(인터넷 정보 서비스) 관리자` 을 실행하고 `응용 프로그램 풀`를 선택하고 `응용 프로그램 풀`을 추가합니다.
         * 이름은 `PassCore Application Pool`, `.NET CLR 버전`은 `관리코드 없음`, 관리되는 파이프라인 모드는 `통합`을 선택하여 생성합니다.
         * 방금전에 생성한 응용 프로그램 풀의 `고급설정`을 선택합니다.
         * 시작 모드를 `AlwaysRunning`, 유휴 시간 제한(분)을 `0`으로 변경합니다.
      * 사이트를 추가합니다.
         * 이름은 `PassCore Websit`, 응용 프로그램 풀은 방금 생성한 것으로 변경합니다.
         * 실제 경로는 압축을 해제한 폴더를 선택합니다.
         * 주의, 실제 경로는 wwwroot 폴더의 상위 폴더를 선택해야 합니다.
3. 설정 파일을 수정합니다.
   * 설정파일: `C:\PassCore422\appsettings.json`
   * 설정 변경
      * LdapSearchBase: Active Directory 도메인을 입력합니다. <code javascript>"LdapSearchBase": "dc=myseit,dc=local",</code>
      * LdapHostnames: Ldap 서버의 이름 또는 IP를 입력합니다. <code javascript>"LdapHostnames": [ "win19.myseit.local" ], // Set your hostname(s)</code>
      * LdapUsername: 다른 사용자의 패스워드를 변경할 수 있는 권한을 가진 사용자 이름을 입력합니다. <code javascript>"LdapUsername": "administator", // Set the username or distinguish name (DN) to bind the LDAP server</code>
      * LdapPassword: 사용자의 비밀번호를 입력합니다. <code javascript>"LdapPassword": "P@ssw0rd11", // Set the password for the username</code>
      * DefaultDomain: 기본 AD도메인을 입력 합니다.<code javascript>"DefaultDomain": "myset.local" // Set your default AD domain here, or non "@" logins will not work! Use empty value to allow user to set the domain. This option is ONLY available with UPN.</code>

### 접속 테스트

1. 웹브라우저로 웹사이트에 접속합니다.
   * URL: http://pass.myseit.local:8042/
2. `UserName` 에 변경할 사용자 메일주소를 입력합니다.
3. `Current Password` 에 현재 비밀번호를 입력합니다.
4. `New Password` 에 변경할 비밀번호를 입력합니다.
5. `Re-enter New Password` 에 변경할 비밀번호를 한번 더 입력합니다.
6. `CHANGE PASSWORD` 버튼을 클릭하고 기다립니다.


##  TrubleShooting

### Logs - The framework 'Microsoft.AspNetCore.App', version '3.1.0' was not found.

* 증상: 웹페이지 접속할때 `loading..` 표시만 있고, 로그에 'Microsoft.AspNetCore.App' framework 를 찾을수 없다는 메세지 표시되며 패스워드 변경 불가
* 원인: PassCore는 ASP.NET Core Runtime 3.1.0을 사용하여 개발되어 있으며, Windows server 2019에 기본적으로 설치가 되어 있지 않아서 발생하였음.
* 해결 방법: ASP.NET Core Runtime 3.1.0를 설치함
   * https://dotnet.microsoft.com/download/dotnet-core/thank-you/runtime-aspnetcore-3.1.0-windows-hosting-bundle-installer
* 참고
   * 설치 버전 확인 `dir "C:\Program Files\dotnet\shared\Microsoft.AspNetCore.App"`

### Response Message - Unknown error (0x80005000)

* 증상: 패스워드 변경할 때 `Unknown error (0x80005000)`가 발생하며 변경이 되지 않음
* 원인: `기본 도메인 정책` 에 최소 패스워드 사용기간이 1이상이기에 발생함
* 해결 방법: `기본 도메인 정책` 중 최소 패스워드 사용기간을 0으로 변경함
   1. 시작 -> 실행 -> gpedit.msc
   2. 도메인 -> 도메인이름(ex zasfe.com) -> 기본 도메인 정책, 마우스 우클릭 후 수정
   3. 컴퓨터 설정 -> 정책 -> 윈도우 설정 -> 보안 정책 -> 계정 정책 -> 암호 정책 -> 최소 패스워드 사용기간, 0으로 변경
   4. 명령 프롬프트를 관리자 권한으로 실행하고 `gpupdate /force` 실행
