@echo off
echo ===================================================
echo   LOCAL WORKSPACE CLEANUP SCRIPT
echo ===================================================

echo [1/3] Running flutter clean...
call flutter clean

echo [2/3] Removing coverage and temp build folders...
if exist "coverage" rmdir /s /q "coverage"
if exist "build" rmdir /s /q "build"

echo [3/3] Fetching fresh pub dependencies...
call flutter pub get

echo ===================================================
echo   WORKSPACE IS CLEAN AND READY
echo ===================================================
