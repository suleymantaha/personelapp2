@echo off
echo ===================================================
echo   FLUTTER SUITE RUNNER: Shopping & Debt Modules
echo ===================================================

echo [1/5] Running Flutter Static Analysis...
call flutter analyze
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Static analysis failed!
    exit /b %ERRORLEVEL%
)

echo [2/5] Running Unit & Widget Tests with Coverage...
call flutter test --coverage test/unit test/widget
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Unit/Widget tests failed!
    exit /b %ERRORLEVEL%
)

echo [3/5] Running Integration User Journey Tests...
call flutter test integration_test
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Integration tests failed!
    exit /b %ERRORLEVEL%
)

echo ===================================================
echo   TEST SUITE EXECUTED SUCCESSFULLY (%Coverage Target: 95%+)
echo ===================================================
