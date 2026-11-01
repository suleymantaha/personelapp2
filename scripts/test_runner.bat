@echo off
setlocal
echo Nizam host quality checks
call flutter analyze
if errorlevel 1 exit /b %ERRORLEVEL%
call flutter test --coverage --reporter expanded --timeout 2m
if errorlevel 1 exit /b %ERRORLEVEL%
echo Host checks passed. See coverage/lcov.info for measured coverage.
echo Android integration requires an explicitly verified nizam-nobet-test serial.
exit /b 0
