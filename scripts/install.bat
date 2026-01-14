@echo off
setlocal enabledelayedexpansion

REM Lumix Build Tool Installation Script v1.0.0
REM Installs the Lumix build system for Luma projects on Windows

set VERSION=v1.0.0
set INSTALL_DIR=%USERPROFILE%\.lumix
set BIN_DIR=%INSTALL_DIR%\bin

echo ======================================
echo   Lumix Build Tool Installer %VERSION%
echo ======================================
echo.

REM Check for admin rights
net session >nul 2>&1
if %errorLevel% == 0 (
    echo Running with administrator privileges.
    echo Installing to: %ProgramFiles%\Lumix
    set INSTALL_DIR=%ProgramFiles%\Lumix
    set BIN_DIR=%INSTALL_DIR%\bin
    set SYSTEM_INSTALL=true
) else (
    echo Running without administrator privileges.
    echo Installing to user directory: %INSTALL_DIR%
    echo For system-wide installation, run as administrator.
    echo.
)

REM Create directories
echo Creating installation directories...
if not exist "%BIN_DIR%" mkdir "%BIN_DIR%"

REM Copy binary
echo Installing Lumix to %BIN_DIR%...
if exist "lumix.exe" (
    copy /Y "lumix.exe" "%BIN_DIR%\lumix.exe" >nul
) else if exist "bin\lumix.exe" (
    copy /Y "bin\lumix.exe" "%BIN_DIR%\lumix.exe" >nul
) else (
    echo Error: Could not find lumix.exe!
    echo Please ensure 'lumix.exe' is in the current directory or bin\ subdirectory.
    echo.
    echo Build Lumix first with:
    echo   luma src\lumix.lx -name lumix -l std\io.lx std\sys.lx std\vector.lx std\string.lx std\memory.lx --no-sanitize
    pause
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
echo %PATH% | find /i "%BIN_DIR%" >nul
if errorlevel 1 (
    set "PATH_CHECK=true"
)

if "%PATH_CHECK%"=="true" (
    echo IMPORTANT: The installation directory is not in your PATH.
    echo.
    if "%SYSTEM_INSTALL%"=="true" (
        echo Adding to system PATH...
        setx /M PATH "%PATH%;%BIN_DIR%" >nul 2>&1
        if errorlevel 1 (
            echo Failed to add to system PATH automatically.
            echo Please add manually: %BIN_DIR%
        ) else (
            echo Added to system PATH successfully.
            echo Restart your command prompt for changes to take effect.
        )
    ) else (
        echo Adding to user PATH...
        setx PATH "%PATH%;%BIN_DIR%" >nul 2>&1
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
echo For more information, see DOCS.md
echo.
pause
