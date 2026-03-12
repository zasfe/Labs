@echo off
setlocal

for /f "tokens=2 delims==" %%a in ('wmic OS Get localdatetime /value') do set "dt=%%a"
set "YY=%dt:~2,2%" & set "YYYY=%dt:~0,4%" & set "MM=%dt:~4,2%" & set "DD=%dt:~6,2%"
set "HH=%dt:~8,2%" & set "Min=%dt:~10,2%" & set "Sec=%dt:~12,2%"

set "datestamp=%YYYY%%MM%%DD%" & set "timestamp=%HH%%Min%%Sec%"
set "fullstamp=%YYYY%-%MM%-%DD%_%HH%-%Min%-%Sec%"
@echo THIS-TIME: "%fullstamp%"

@echo ===========================================
net use
@echo ===========================================

cd C:\DISKSPD\amd64
set PATH=%PATH%;C:\DISKSPD\amd64

@echo # 디스크에 DISKTEST.DAT라는 새 10GB 파일을 만듭니다.
set TESTFILE_C=C:\DISKTEST_C.DAT
diskspd.exe -d0 -c10G %TESTFILE_C%

@echo # I/O 블록 크기를 1MB로 설정하고 I/O 깊이를 64 이상으로 설정한 상태로 여러 동시 스트림(16개 이상)에 순차적 쓰기를 수행하여 쓰기 처리량을 테스트합니다.
diskspd.exe -d60 -b1M -o64 -Sh -w100 -t16 -si %TESTFILE_C%

@echo # I/O 블록 크기를 4KB로 설정하고 I/O 깊이를 256 이상으로 설정한 상태로 무작위 쓰기를 수행하여 쓰기 IOPS를 테스트합니다.
diskspd.exe -d60 -b4K -o256 -Sh -w100 -r %TESTFILE_C%

@echo # I/O 블록 크기를 1MB로 설정하고 I/O 깊이를 최소 64 이상으로 설정한 상태로 여러 동시 스트림(16개 이상)에 순차적 읽기를 수행하여 읽기 처리량을 테스트합니다.
diskspd.exe -d60 -b1M -o64 -Sh -t16 -si %TESTFILE_C%

@echo # I/O 블록 크기를 4KB로 설정하고 I/O 깊이를 256 이상으로 설정해서 무작위 읽기를 수행하여 읽기 IOPS를 테스트합니다.
diskspd.exe -d60 -b4K -o256 -Sh -r %TESTFILE_C%

del %TESTFILE_C%

for /f "tokens=2 delims==" %%a in ('wmic OS Get localdatetime /value') do set "dt=%%a"
set "YY=%dt:~2,2%" & set "YYYY=%dt:~0,4%" & set "MM=%dt:~4,2%" & set "DD=%dt:~6,2%"
set "HH=%dt:~8,2%" & set "Min=%dt:~10,2%" & set "Sec=%dt:~12,2%"

set "datestamp=%YYYY%%MM%%DD%" & set "timestamp=%HH%%Min%%Sec%"
set "fullstamp=%YYYY%-%MM%-%DD%_%HH%-%Min%-%Sec%"
@echo THIS-TIME: "%fullstamp%"

endlocal
exit /b 0
