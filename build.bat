@echo off
setlocal

:: ==========================================
:: heather Build Script (Windows)
:: ==========================================

set APP=heather.exe
set SRC_FILE=src\heather.pas
set BIN_DIR=bin
set OBJ_DIR=obj

:: Route the command line arguments
if /I "%1"=="clean" goto clean
if /I "%1"=="build" goto build
if "%1"=="" goto build

echo Unknown command: %1
echo Usage: build.bat [build^|clean]
goto end

:clean
echo ==^> Cleaning build artifacts...
if exist %OBJ_DIR% rmdir /s /q %OBJ_DIR%
if exist %BIN_DIR% rmdir /s /q %BIN_DIR%
echo ==^> Clean complete.
goto end

:build
echo ==^> Scaffolding directories...
if not exist %OBJ_DIR% mkdir %OBJ_DIR%
if not exist %BIN_DIR% mkdir %BIN_DIR%

echo ==^> Compiling %APP%...
fpc @heather.cfg %SRC_FILE%

:: Check if the compilation succeeded
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ==^> Build failed! Check the compiler errors above.
) else (
    echo.
    echo ==^> Build complete! Executable is at %BIN_DIR%\%APP%
)
goto end

:end
endlocal
