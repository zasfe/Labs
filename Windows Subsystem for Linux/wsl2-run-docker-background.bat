@echo off

@echo  # Reference
@echo  - url: https://netmarble.engineering/docker-on-wsl2-without-docker-desktop/
@echo.

@echo Starting dockerd in WSL ...
@echo.

for /f "tokens=1" %%a in ('wsl sh -c "hostname -I"') do set wsl_ip=%%a
echo wsl_ip=%wsl_ip%
@echo.

@echo # Get WSL List 
wsl --list
@echo.

wsl -d Ubuntu -u root -e nohup sh -c "dockerd -H tcp://%wsl_ip% &" < nul > nul 2>&1
wsl -d CentOS7 -u root -e nohup sh -c "dockerd -H tcp://%wsl_ip% &" < nul > nul 2>&1
wsl -d Ubuntu-18.04 -u root -e nohup sh -c "dockerd -H tcp://%wsl_ip% &" < nul > nul 2>&1

REM netsh interface portproxy add v4tov4 listenport=2375 connectport=2375 connectaddress=%wsl_ip%


@echo AWS EC2 Run
wsl -d Ubuntu -u root -e sh -c "/bin/bash /root/run_ec2_tommywin.sh" 
@echo.
ping 127.0.0.1  < nul > nul 2>&1
@echo Update w.aws.zasfe.com
wsl -d Ubuntu -u root -e sh -c "/bin/bash /root/update_ec2_ip_tommywin_cloudflare.sh" 
@echo.
ping 127.0.0.1  < nul > nul 2>&1
REM pause
