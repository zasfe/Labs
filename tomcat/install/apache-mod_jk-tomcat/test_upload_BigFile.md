
## Big File create...

```bash
fallocate -l 10G /root/test10gb.dat
fallocate -l 20G /root/test20gb.dat
```


## Big File Upload...

* **web ip : 10.9.88.40**
* **도메인: example.local**
    * 미등록된 도메인으로 curl 파일 업로드 테스트

```bash
# 10GB 파일 업로드
curl -v -F "file=@/root/test10gb.dat" --resolve example.local:80:10.9.88.40 http://example.local/uploadResult.jsp

# 20GB 파일 업로드
curl -v -F "file=@/root/test20gb.dat" --resolve example.local:80:10.9.88.40 http://example.local/uploadResult.jsp
```
