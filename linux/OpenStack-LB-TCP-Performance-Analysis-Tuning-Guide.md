# OpenStack VM + Load Balancer 환경 TCP 성능 분석 및 튜닝 가이드

## 문서 목적

본 문서는 OpenStack 기반 VM 환경에서 Load Balancer(LB) 뒤에 위치한 WEB/WAS/DB 서버의 TCP 성능을 분석하고 적절한 커널 파라미터를 산정하기 위한 절차를 정리한 문서이다.

LB 설정값이 공개되지 않은 환경을 전제로 하며, 클라이언트 및 서버에서 수집 가능한 정보만을 이용하여 LB 특성을 추정하고 이를 기반으로 TCP 튜닝 방향을 결정하는 것을 목표로 한다.

---

# 환경 가정

```text
Client
  ↓
Load Balancer
  ↓
OpenStack VM
  ├─ WEB
  ├─ WAS
  └─ DB
```

제약사항
- LB 설정 접근 불가
- LB 종류 미확인
- OpenStack VM SSH 접근 가능
- Client 시스템 제어 가능
- 서비스 중단 없는 분석 필요

---

# LB 환경에서 TCP 튜닝이 어려운 이유

일반적인 서버 튜닝은 다음 구조를 전제로 한다.
```text
Client
   ↓
Server
```
그러나 실제 환경은
```text
Client
   ↓
LB
   ↓
Server
```
구조이므로
다음 항목이 모두 LB 영향권에 존재한다.
- TCP KeepAlive
- Idle Timeout
- Connection Reuse
- Source NAT
- SYN Queue
- Session Persistence
- TCP Offloading
- MTU
따라서 서버 TCP 튜닝보다 LB 특성 파악이 우선이다.
---
# 분석 절차
## 1단계 : LB 종류 추정
### HTTP Header 분석
```bash
curl -I https://service.example.com
```
확인 항목
```text
X-Forwarded-For
X-Real-IP
Via
Server
```
예시
```http
X-Forwarded-For: 1.2.3.4
Via: haproxy
```
판단
```text
L7 Proxy 가능성 높음
```
---
## 2단계 : Source IP 확인
서버
```bash
ss -nt state established
```
또는
```bash
netstat -ant
```
### 실제 Client IP 확인
```text
1.2.3.4
```
→ DSR 또는 Transparent Mode 가능성
### LB IP만 확인
```text
10.0.0.10
```
→ SNAT Mode 가능성
---
## 3단계 : Idle Timeout 추정
Client
```bash
nc service.example.com 80
```
연결 유지
```bash
date
```
응답이 종료될 때까지 대기
확인 결과
```text
60초
300초
600초
```
등
---
### 일반적인 추정
| Timeout | 추정 |
|----------|--------|
| 60초 | Octavia |
| 300초 | F5 |
| 600초 | HAProxy |
| 900초 | Cloud LB |
---
## 4단계 : Listen Queue 확인
서버
```bash
ss -lnt
```
또는
```bash
cat /proc/net/netstat
```
확인 항목
```text
ListenDrops
ListenOverflows
```
---
### 정상
```text
0
```
### 비정상
```text
증가 중
```
원인
- somaxconn 부족
- acceptCount 부족
- LB Burst Traffic
---
## 5단계 : TIME_WAIT 확인
```bash
ss -ant state time-wait | wc -l
```
---
### WEB
```text
수천 ~ 수만 가능
```
정상
---
### DB
```text
수백 이하
```
권장
---
## 6단계 : Retransmission 확인
```bash
netstat -s
```
확인
```text
segments retransmitted
```
---
증가 원인
- MTU 문제
- LB 문제
- 네트워크 혼잡
- OpenStack Overlay
---
## 7단계 : MTU 확인
```bash
ip link
```
예
```text
1500
1450
1442
```
---
OpenStack Overlay 사용 시
```text
VXLAN
Geneve
GRE
```
환경은
```text
1450
1442
```
가 일반적
---
# 서버별 TCP 튜닝 기준
## WEB 서버
대상
- Apache
- Nginx
특징
```text
짧은 연결
대량 동시접속
TIME_WAIT 많음
```
---
### 권장값
```bash
net.core.somaxconn=32768
net.ipv4.tcp_max_syn_backlog=32768
net.core.netdev_max_backlog=32768
net.ipv4.tcp_fin_timeout=10
net.ipv4.tcp_tw_reuse=1
net.ipv4.tcp_keepalive_time=30
net.core.rmem_max=33554432
net.core.wmem_max=33554432
```
---
### 추가 확인
Apache
```apache
MaxRequestWorkers
KeepAliveTimeout
```
Nginx
```nginx
worker_processes
worker_connections
```
---
# WAS 서버
대상
- Tomcat
- JBoss
- Spring Boot
특징
```text
KeepAlive 사용
세션 유지
Backend Pool 사용
```
---
### 권장값
```bash
net.core.somaxconn=32768
net.ipv4.tcp_max_syn_backlog=16384
net.ipv4.tcp_keepalive_time=30~300
net.ipv4.tcp_rmem=4096 524288 33554432
net.ipv4.tcp_wmem=4096 524288 33554432
net.core.rmem_max=67108864
net.core.wmem_max=67108864
```
---
### Tomcat 권장
```xml
<Connector
  maxThreads="500"
  acceptCount="1000"
/>
```
---
### 중요
```text
acceptCount <= somaxconn
```
관계 유지 필요
---
# DB 서버
대상
- MySQL
- MariaDB
- PostgreSQL
특징
```text
장시간 연결
대용량 전송
안정성 우선
```
---
### 권장값
```bash
net.core.somaxconn=8192
net.ipv4.tcp_max_syn_backlog=8192
net.ipv4.tcp_keepalive_time=300
net.ipv4.tcp_rmem=4096 1048576 67108864
net.ipv4.tcp_wmem=4096 1048576 67108864
net.core.rmem_max=67108864
net.core.wmem_max=67108864
net.ipv4.tcp_retries2=8
```
---
# OpenStack 환경 추가 고려사항
## Conntrack
확인
```bash
cat /proc/sys/net/netfilter/nf_conntrack_count
cat /proc/sys/net/netfilter/nf_conntrack_max
```
---
경고 기준
```text
count >= max의 80%
```
---
권장
```bash
net.netfilter.nf_conntrack_max=2097152
```
메모리 충분 시
---
## Overlay Network
확인
```text
VXLAN
GENEVE
GRE
```
---
문제 증상
```text
TCP Retransmission 증가
특정 파일 다운로드 느림
대용량 응답 지연
```
---
확인
```bash
ping -M do -s 1472 target
```
---
# 우선순위
실제 장애 영향도 순서
```text
1. LB Idle Timeout
2. MTU
3. Conntrack
4. Apache MaxRequestWorkers
5. Tomcat acceptCount
6. Tomcat maxThreads
7. MySQL max_connections
8. somaxconn
9. tcp_max_syn_backlog
10. tcp buffer
```
---
# 적용 전 체크리스트
## WEB
- [ ] ListenDrops 증가 여부
- [ ] TIME_WAIT 수량 확인
- [ ] Apache KeepAliveTimeout 확인
- [ ] LB Idle Timeout 추정 완료
---
## WAS
- [ ] maxThreads 확인
- [ ] acceptCount 확인
- [ ] mod_jk timeout 확인
- [ ] LB Idle Timeout 확인
---
## DB
- [ ] max_connections 확인
- [ ] wait_timeout 확인
- [ ] retransmission 확인
- [ ] MTU 확인
---
# 결론
OpenStack VM 환경에서 TCP 튜닝은 단순히 sysctl 값을 증가시키는 작업이 아니다.
우선적으로 확인해야 하는 항목은 다음과 같다.
```text
LB Idle Timeout
MTU
Conntrack
WEB Thread Pool
WAS Thread Pool
DB Connection Pool
```
이후 LB 특성에 맞추어 KeepAlive 및 Queue 관련 파라미터를 조정하는 것이 가장 효과적이다.
특히 Apache + Tomcat + MySQL 구조에서는 과거 발생했던
- ajp_get_reply timeout
- sending request failed
- recoverable error
- Aborted connection
등의 장애가 LB Idle Timeout과 Backend Connection Timeout 불일치에서 발생하는 경우가 매우 많으므로 최우선적으로 확인해야 한다.

📄출처: [NHN Cloud Meetup, 리눅스 서버의 TCP 네트워크 성능을 결정짓는 커널 파라미터 1~3편, 2017, https://meetup.nhncloud.com/posts/53], [NHN Cloud Meetup, 리눅스 서버의 TCP 네트워크 성능을 결정짓는 커널 파라미터 2편, 2017, https://meetup.nhncloud.com/posts/54], [NHN Cloud Meetup, 리눅스 서버의 TCP 네트워크 성능을 결정짓는 커널 파라미터 3편, 2017, https://meetup.nhncloud.com/posts/55]

📄출처: [Linux Kernel Documentation, Networking Sysctl, 2026, https://www.kernel.org/doc/html/latest/networking/ip-sysctl.html], [OpenStack Octavia Documentation, 2026, https://docs.openstack.org/octavia/latest/]
