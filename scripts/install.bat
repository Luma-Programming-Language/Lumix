@echo off
setlocal enabledelayedexpansion

REM Lumix Build Tool Installation Script v1.0.0
REM Installs the Lumix build system for Luma projects on Windows

set VERSION=v1.0.0
set "SCRIPT_DIR=%~dp0"
set "INSTALL_DIR=%USERPROFILE%\.lumix"
set "BIN_DIR=%INSTALL_DIR%\bin"
set "SYSTEM_INSTALL=false"

echo ======================================
echo   Lumix Build Tool Installer %VERSION%
echo ======================================
echo.

REM Check for admin rights
"%SystemRoot%\System32\net.exe" session >nul 2>&1
if not errorlevel 1 (
    echo Running with administrator privileges.
    echo Installing to: %ProgramFiles%\Lumix
    set "INSTALL_DIR=%ProgramFiles%\Lumix"
    set "BIN_DIR=%ProgramFiles%\Lumix\bin"
    set SYSTEM_INSTALL=true
    goto :admin_check_complete
)

set "ADMIN_CHOICE="
set /p "ADMIN_CHOICE=Request administrator privileges for a system-wide installation? [Y/N] "
if /I "%ADMIN_CHOICE%"=="Y" goto :request_admin
goto :user_install

:request_admin
echo.
echo Requesting administrator privileges...
set "LUMIX_INSTALLER=%~f0"
set "LUMIX_WORKDIR=%CD%"
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -Command "try { Start-Process -FilePath $env:LUMIX_INSTALLER -WorkingDirectory $env:LUMIX_WORKDIR -Verb RunAs; exit 0 } catch { exit 1 }"
if errorlevel 1 (
    echo Administrator access was cancelled or unavailable.
    goto :user_install
)
exit /b 0

:user_install
echo.
echo Running without administrator privileges.
echo Installing to user directory: %INSTALL_DIR%
echo.

:admin_check_complete
REM Create directories
echo Creating installation directories...
if not exist "%BIN_DIR%\" mkdir "%BIN_DIR%"
if not exist "%BIN_DIR%\" (
    echo Error: Could not create installation directory: %BIN_DIR%
    exit /b 1
)

REM Copy binary
echo Installing Lumix to %BIN_DIR%...
set "SOURCE_BIN="
if exist "%SCRIPT_DIR%..\lumix.exe" set "SOURCE_BIN=%SCRIPT_DIR%..\lumix.exe"
if exist "%SCRIPT_DIR%..\bin\lumix.exe" set "SOURCE_BIN=%SCRIPT_DIR%..\bin\lumix.exe"
if not defined SOURCE_BIN if exist "lumix.exe" set "SOURCE_BIN=lumix.exe"
if not defined SOURCE_BIN if exist "bin\lumix.exe" set "SOURCE_BIN=bin\lumix.exe"

if not defined SOURCE_BIN (
    echo Error: Could not find lumix.exe!
    echo Please ensure lumix.exe is beside the repository or in its bin\ subdirectory.
    echo.
    echo Build Lumix first with:
    echo   luma src\lumix.lx -name lumix -l std\io.lx std\sys.lx std\vector.lx std\string.lx std\memory.lx --no-sanitize
    pause
    exit /b 1
)
copy /Y "%SOURCE_BIN%" "%BIN_DIR%\lumix.exe" >nul
if errorlevel 1 (
    echo Error: Could not install "%SOURCE_BIN%" to "%BIN_DIR%\lumix.exe".
    exit /b 1
)

echo.
echo Installation complete!
echo.
echo Installed to:
echo   Binary: %BIN_DIR%\lumix.exe
echo.

REM Check if directory is in PATH
set "PATH_CHECK=false"
echo(%PATH%| "%SystemRoot%\System32\find.exe" /I "%BIN_DIR%" >nul
if errorlevel 1 (
    set "PATH_CHECK=true"
)

if "%PATH_CHECK%"=="true" (
    echo IMPORTANT: The installation directory is not in your PATH.
    echo.
    if "%SYSTEM_INSTALL%"=="true" (
        echo Adding to system PATH...
        "%SystemRoot%\System32\setx.exe" /M PATH "%PATH%;%BIN_DIR%" >nul 2>&1
        if errorlevel 1 (
            echo Failed to add to system PATH automatically.
            echo Please add manually: %BIN_DIR%
        ) else (
            echo Added to system PATH successfully.
            echo Restart your command prompt for changes to take effect.
        )
    ) else (
        echo Adding to user PATH...
        "%SystemRoot%\System32\setx.exe" PATH "%PATH%;%BIN_DIR%" >nul 2>&1
        if errorlevel 1 (
            echo Failed to add to PATH automatically.
            echo.
            echo Please add manually:
            echo   1. Open System Properties ^> Environment Variables
            echo   2. Edit your user PATH variable
            echo   3. Add: %BIN_DIR%
        ) else (
            echo Added to user PATH successfully.
            echo Restart your command prompt for changes to take effect.
        )
    )
    echo.
)

echo Usage:
echo   cd C:\path\to\your\luma\project
echo   lumix
echo.
echo Commands:
echo   build - Build your Luma project
echo   clean - Remove build artifacts
echo   deps  - Show dependency tree
echo.
echo For more information, see docs\README.md
echo.
pause
