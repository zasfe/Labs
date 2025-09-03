@echo off
rem ===== 메인 시작 =====
echo 프로그램 시작

call :Func1 "첫 번째 실행"
call :Func2 10 20
call :Func1 "두 번째 실행"
call :Func2 7 3

echo 프로그램 종료
exit /b
rem ===== 메인 끝 =====


:Func1
rem 인자: %1
echo [Func1 실행] 메시지 = %~1
exit /b


:Func2
rem 인자: %1, %2
setlocal
set /a result=%1 + %2
echo [Func2 실행] %1 + %2 = %result%
endlocal
exit /b
