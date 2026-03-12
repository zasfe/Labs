@echo off
setlocal

for /f "tokens=2 delims==" %%a in ('wmic OS Get localdatetime /value') do set "dt=%%a"
set "YY=%dt:~2,2%" & set "YYYY=%dt:~0,4%" & set "MM=%dt:~4,2%" & set "DD=%dt:~6,2%"
set "HH=%dt:~8,2%" & set "Min=%dt:~10,2%" & set "Sec=%dt:~12,2%"

set "datestamp=%YYYY%%MM%%DD%" & set "timestamp=%HH%%Min%%Sec%"
set "fullstamp=%YYYY%-%MM%-%DD%_%HH%-%Min%-%Sec%"
@echo THIS-TIME: "%fullstamp%"

test-local.bat >> output-test-local_%fullstamp%.log 2>&1
test-cifs.bat >> output-test-cifs_%fullstamp%.log 2>&1
test-nfs.bat >> output-test-nfs_%fullstamp%.log 2>&1

endlocal
