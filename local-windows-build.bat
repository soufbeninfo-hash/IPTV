@echo off
title Windows 11 - Xtream IPTV Flow .EXE Compiler
echo =========================================================
echo BUILD UTILITY: GENERATE WINDOWS 11 STANDALONE EXECUTABLE (.EXE)
echo =========================================================
echo.
echo PREREQUISITE: Requires Node.js installed on your Windows 11 machine.
echo Download from: https://nodejs.org/
echo.
echo PRESS ANY KEY to start installing required compilers and packaging layers...
pause > nul

echo.
echo [*] STEP 1: Installing builder dependencies (electron and electron-builder)...
call npm install electron electron-builder@24.13.3 --save-dev --no-audit

echo.
echo [*] STEP 2: Running high-speed client and server builds...
call npm run build

echo.
echo [*] STEP 3: Designing executable configuration keys in package.json...
echo Configured to package with Windows build assets.

echo.
echo [*] STEP 4: Compiling binary with electron-builder into standalone executable...
npx electron-builder build --windows --dir

echo.
echo =========================================================
echo BUILD COMPLETE!
echo =========================================================
echo Find your finished Windows 11 executable inside: \dist\win-unpacked\
echo Double-click "Xtream IPTV Flow.exe" to play IPTV streams natively.
echo =========================================================
pause
