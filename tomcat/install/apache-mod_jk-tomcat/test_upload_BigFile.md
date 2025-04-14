
## 대용량 파일 생성 및 업로드 테스트

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

* workers.properties 에서 timeout 과 buffer, connection_pool_size 추가 설정
* vhost.conf 에서 Timeout 과 LimitRequestBody 무제한 설정 추가(기본값이지만 변경되었을 수 있으니 다시 설정함)

```
# ./conf.d/mod_jk.conf
LoadModule jk_module modules/mod_jk.so
JkWorkersFile /etc/httpd/conf/workers.properties
JkLogFile /var/log/httpd/mod_jk.log
JkLogLevel info
JkMount /upload ajp_worker
```

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
