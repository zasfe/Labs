
## 대용량 파일 생성 및 업로드 테스트

* 실행환경
  * OS: Rocky linux 8
  * WEB: Apache/2.4.37, mod_jk/1.2.49
  * WAS: Tomcat/9.0.85, java-1.8.0-openjdk
* **web ip : 10.9.88.40**
* **도메인: example.local**
    * 미등록된 도메인으로 curl 파일 업로드 테스트

```bash
# 파일 생성
fallocate -l 10G /root/test10gb.dat
fallocate -l 20G /root/test20gb.dat

# 10GB 파일 업로드
curl -v -F "file=@/root/test10gb.dat" --resolve example.local:80:10.9.88.40 http://example.local/uploadResult.jsp

# 20GB 파일 업로드
curl -v -F "file=@/root/test20gb.dat" --resolve example.local:80:10.9.88.40 http://example.local/uploadResult.jsp
```

## 설정 요약
### mod_jk 설정

* `workers.properties` 에서 timeout 과 buffer, connection_pool_size 설정 추가
* `vhost.conf` 에서 Timeout 과 LimitRequestBody 무제한 설정 추가(기본값이지만 변경되었을 수 있으니 다시 설정함)
* tomcat `server.xml` 에서 maxPostSize, maxSwallowSize, packetSize, connectionTimeout 설정 추가
* `workers.properties` 에서 socket_buffer 는 `server.xml` 의 packetSize 와 동일하도록 설정해야함.


**./conf.d/mod_jk.conf**
```
# ./conf.d/mod_jk.conf
LoadModule jk_module modules/mod_jk.so
JkWorkersFile /etc/httpd/conf/workers.properties
JkLogFile /var/log/httpd/mod_jk.log
JkLogLevel info
JkMount /upload ajp_worker
```

**/etc/httpd/conf/workers.properties**

* `socket_timeout` : 원격 호스트가 지정된 시간 초과 내에 응답하지 않으면 JK는 오류를 생성하고 다시 시도합니다. 0(기본값)으로 설정하면 JK는 모든 소켓 작업을 무한정 대기합니다.
* `reply_timeout` : Tomcat에서 수신한 두 패킷 사이의 최대 시간
* `connection_pool_size` : 연결 풀로 유지되는 AJP 백엔드에 대한 연결 수
  * Apache 2.x의 prefork MPM 이나 Apache 1.3.x 에서는 connection_pool_size 값을 1보다 높게 사용하지 마세요 !
  * IIS의 경우 기본값은 250입니다(1.2.20 이전 버전: 10).

https://tomcat.apache.org/connectors-doc/reference/workers.html

```
# /etc/httpd/conf/workers.properties
worker.list=ajp_worker
worker.ajp_worker.type=ajp13
worker.ajp_worker.host=10.9.89.24
worker.ajp_worker.port=7019

# 추가 설정
worker.ajp_worker.socket_timeout=7200
worker.ajp_worker.reply_timeout=7200000
worker.ajp_worker.socket_buffer=65536
worker.ajp_worker.connection_pool_size=20
```

**./conf.d/vhost-tomcat.conf**

https://tomcat.apache.org/connectors-doc/reference/apache.html

```
# ./conf.d/vhost-tomcat.conf
<VirtualHost *:80>
    ServerName www.example.kr
    ServerAlias *.example.kr example.local *.example.local

    Timeout 7200
    KeepAliveTimeout 7200

    JkMount /* ajp_worker
    LimitRequestBody 0

    ErrorLog logs/vhost-tomcat_error_log
    TransferLog logs/vhost-tomcat_access_log
    LogLevel warn
</VirtualHost>
``

**tomcat server.xml**

- maxPostSize : 기본값 2097152(2 MiB), 무제한(-1), FORM 으로 보내는 최대 크기.
- maxSwallowSize : 기본값 2097152(2 MiB), 크기 초과 연결 등을 버퍼만큼 삼켜서 오류를 반환할 수 있도록 함
- packetSize : 기본값 8192, 최대 65536, 최대 AJP 패킷크기, mod_jk 의 max_packet_size 와 동일하도록 설정해야함
- connectionTimeout : 기본값 60000(60초), 무제한(-1), 연결후 URI응답을 기다리는 시간

https://tomcat.apache.org/tomcat-8.5-doc/config/http.html
https://tomcat.apache.org/tomcat-9.0-doc/config/ajp.html

```
# tomcat server.xml
        <Connector protocol="AJP/1.3"
           port="7019"
           address="0.0.0.0"
           redirectPort="8443"
           maxThreads="500"
           secretRequired="false"
           maxPostSize="21474836480"
           maxSwallowSize="-1"
           packetSize="65536"
           connectionTimeout="7200000" />
```
