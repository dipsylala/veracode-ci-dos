@echo off
REM SourceClear CI Script for Windows (DOS Batch)
REM
REM Note: This is a simplified version of the PowerShell script.
REM Some features like concurrent execution support are simplified.

setlocal enabledelayedexpansion

REM Exit if no arguments provided (matching PowerShell behavior)
if "%~1"=="" exit /b 0

REM Check for debug flag
set DEBUG_MODE=0
if not "%DEBUG%"=="" set DEBUG_MODE=1
for %%a in (%*) do (
    if /I "%%a"=="--debug" set DEBUG_MODE=1
)

set DOWNLOAD_URL=https://sca-downloads.veracode.com
set CACHE_DIR_PARENT=%TEMP%\srcclr

REM Get version
call :GetVersion
if errorlevel 1 goto :error

REM Get cache directory
call :GetCacheDir
if errorlevel 1 goto :error

REM Download and extract srcclr
call :DownloadSrcclr
if errorlevel 1 goto :error

call :UnzipSrcclr
if errorlevel 1 goto :error

REM Run srcclr with all arguments
set SRCCLR_PATH=%CACHE_DIR%\srcclr-%SRCCLR_VERSION%\bin\srcclr.cmd
if %DEBUG_MODE%==1 echo [DEBUG] Invoking %SRCCLR_PATH% with arguments: %*
if exist "%SRCCLR_PATH%" (
    call "%SRCCLR_PATH%" %*
) else (
    echo Error: srcclr not found at %SRCCLR_PATH%
    exit /b 1
)

exit /b %errorlevel%

:GetVersion
REM Get version from environment or download LATEST_VERSION
if defined SRCCLR_VERSION (
    if %DEBUG_MODE%==1 echo [DEBUG] Using SRCCLR_VERSION from environment: %SRCCLR_VERSION%
    goto :eof
)

if %DEBUG_MODE%==1 echo [DEBUG] Downloading version from %DOWNLOAD_URL%/LATEST_VERSION
set VERSION_FILE=%TEMP%\srcclr_version_%RANDOM%.txt

REM Try using curl first (available in Windows 10+)
curl -s -o "%VERSION_FILE%" "%DOWNLOAD_URL%/LATEST_VERSION" 2>nul
if errorlevel 1 (
    REM Fallback to PowerShell if curl fails
    powershell -Command "(New-Object System.Net.WebClient).DownloadString('%DOWNLOAD_URL%/LATEST_VERSION')" > "%VERSION_FILE%"
)

if not exist "%VERSION_FILE%" (
    echo Error: Could not download version file
    exit /b 1
)

REM Read version and trim whitespace
set /p SRCCLR_VERSION=<"%VERSION_FILE%"
set SRCCLR_VERSION=%SRCCLR_VERSION: =%
del "%VERSION_FILE%" 2>nul

if %DEBUG_MODE%==1 echo [DEBUG] Version: %SRCCLR_VERSION%
goto :eof

:GetCacheDir
REM Create cache directory parent if it doesn't exist
if not exist "%CACHE_DIR_PARENT%" mkdir "%CACHE_DIR_PARENT%"

REM Look for existing completed installation
set FOUND_EXISTING=0
for /d %%d in ("%CACHE_DIR_PARENT%\*") do (
    if exist "%%d\srcclr-%SRCCLR_VERSION%\completed" (
        set CACHE_DIR=%%d
        set FOUND_EXISTING=1
        if %DEBUG_MODE%==1 echo [DEBUG] Found existing installation at %%d
        goto :CacheDirSet
    )
)

:CacheDirSet
if %FOUND_EXISTING%==0 (
    REM Use process ID or random number for new installation
    set CACHE_DIR=%CACHE_DIR_PARENT%\%RANDOM%%RANDOM%
    
    REM Remove existing directory if it exists
    if exist "!CACHE_DIR!" rmdir /s /q "!CACHE_DIR!"
    
    mkdir "!CACHE_DIR!"
    if %DEBUG_MODE%==1 echo [DEBUG] Created new cache directory: !CACHE_DIR!
)

goto :eof

:DownloadSrcclr
set SRCCLR_ZIP=%CACHE_DIR%\srcclr-%SRCCLR_VERSION%-windows.zip

if exist "%SRCCLR_ZIP%" (
    if %DEBUG_MODE%==1 echo [DEBUG] Lightman zip already exists at %SRCCLR_ZIP%, skipping download...
    goto :eof
)

if %DEBUG_MODE%==1 echo [DEBUG] Fetching version %SRCCLR_VERSION% of Lightman and writing to %SRCCLR_ZIP%
set DOWNLOAD_FILE_URL=%DOWNLOAD_URL%/srcclr-%SRCCLR_VERSION%-windows.zip

REM Try using curl first
curl -L -o "%SRCCLR_ZIP%" "%DOWNLOAD_FILE_URL%" 2>nul
if errorlevel 1 (
    REM Fallback to PowerShell
    echo Downloading srcclr-%SRCCLR_VERSION%-windows.zip...
    powershell -Command "$ProgressPreference = 'SilentlyContinue'; Invoke-WebRequest -Uri '%DOWNLOAD_FILE_URL%' -OutFile '%SRCCLR_ZIP%'"
    if errorlevel 1 (
        echo Error: Failed to download %DOWNLOAD_FILE_URL%
        exit /b 1
    )
)

goto :eof

:UnzipSrcclr
set SRCCLR_INSTALL_PATH=%CACHE_DIR%\srcclr-%SRCCLR_VERSION%
set SRCCLR_COMPLETED_PATH=%SRCCLR_INSTALL_PATH%\completed

if exist "%SRCCLR_COMPLETED_PATH%" (
    if %DEBUG_MODE%==1 echo [DEBUG] Lightman is already extracted
    goto :eof
)

if %DEBUG_MODE%==1 echo [DEBUG] Unzipping %SRCCLR_ZIP% into %CACHE_DIR%

REM Try using tar (available in Windows 10+)
tar -xf "%SRCCLR_ZIP%" -C "%CACHE_DIR%" 2>nul
if not errorlevel 1 (
    echo. > "%SRCCLR_COMPLETED_PATH%"
    if %DEBUG_MODE%==1 echo [DEBUG] Successfully extracted using tar
    goto :eof
)

REM Try PowerShell Expand-Archive
powershell -Command "Expand-Archive -Path '%SRCCLR_ZIP%' -DestinationPath '%CACHE_DIR%' -Force" 2>nul
if not errorlevel 1 (
    echo. > "%SRCCLR_COMPLETED_PATH%"
    if %DEBUG_MODE%==1 echo [DEBUG] Successfully extracted using PowerShell Expand-Archive
    goto :eof
)

REM Fallback to downloading and using 7zip
set SEVEN_ZIP_EXE=%CACHE_DIR%\7za.exe
if not exist "%SEVEN_ZIP_EXE%" (
    if %DEBUG_MODE%==1 echo [DEBUG] Downloading 7zip
    curl -L -o "%SEVEN_ZIP_EXE%" "%DOWNLOAD_URL%/7za.exe" 2>nul
    if errorlevel 1 (
        powershell -Command "$ProgressPreference = 'SilentlyContinue'; Invoke-WebRequest -Uri '%DOWNLOAD_URL%/7za.exe' -OutFile '%SEVEN_ZIP_EXE%'"
    )
)

if exist "%SEVEN_ZIP_EXE%" (
    "%SEVEN_ZIP_EXE%" x -o"%CACHE_DIR%" -bd -y "%SRCCLR_ZIP%"
    if not errorlevel 1 (
        echo. > "%SRCCLR_COMPLETED_PATH%"
        if %DEBUG_MODE%==1 echo [DEBUG] Successfully extracted using 7zip
        goto :eof
    )
)

echo Error: Could not extract %SRCCLR_ZIP%
exit /b 1

:error
echo An error occurred during execution
exit /b 1
