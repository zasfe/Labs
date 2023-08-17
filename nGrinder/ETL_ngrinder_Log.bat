@echo off


D:\seit\system\7za.exe e D:\0.tmp\work\aa\*.zip -oD:\0.tmp\work\aa -y

findstr /C:"http" *.log | findstr /v /C:"/lib/grinder-dcr-agent" | findstr /v /C:"plug-in net.grinder.plugin.http.HTTPPlugin" | findstr /v /C:" 200 OK" > Not200.txt





