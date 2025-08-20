@echo off
setlocal

set web_ip_public=222.222.222.222
set web_ip_private=10.10.10.5
set web_port=80
set was_ip_public=
set was_ip_private=10.20.20.6
set was_port=8009
set db_ip_public=
set db_ip_private=10.30.30.7
set db_port=5444

@echo =================================================================
changecolor lightgreen /Q
@echo # WEB - http
changecolor white /Q
tcping -n 1 -w 100  %web_ip_private% %web_port% | findstr time | findstr Probing
@echo.
sc query apache2.4
@echo.
@echo -----------------------------------------------------------------
changecolor lightgreen /Q
@echo # WAS - tomcat
changecolor white /Q
tcping -n 1 -w 100  %was_ip_private% %was_port% | findstr time | findstr Probing
changecolor lightgreen /Q
@echo # WAS - RDP
changecolor white /Q
tcping -n 1 -w 100  %was_ip_private% 3389 | findstr time | findstr Probing
@echo -----------------------------------------------------------------
changecolor lightgreen /Q
@echo # DB - postgresql
changecolor white /Q
tcping -n 1 -w 100  %db_ip_private% %db_port% | findstr time | findstr Probing
changecolor lightgreen /Q
@echo # DB - SSH
changecolor white /Q
tcping -n 1 -w 100  %db_ip_private% 22 | findstr time | findstr Probing
changecolor white /Q
@echo =================================================================
ping 127.0.0.1 2>&1 >nul
pause
endlocal
