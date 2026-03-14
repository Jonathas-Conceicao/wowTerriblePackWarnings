@echo off
setlocal enabledelayedexpansion

if "%~1"=="" (
    echo Usage: release.bat ^<version^>
    echo Example: release.bat 1.0.0
    exit /b 1
)

set "SOURCE=%~dp0..\"
set "VERSION=%~1"
set "TAG=v%VERSION%"

echo Releasing TerriblePackWarnings %VERSION%

git -C "%SOURCE%" tag -a "%TAG%" -m "Release %VERSION%"
if errorlevel 1 (
    echo Error: Failed to create tag %TAG%
    exit /b 1
)

git -C "%SOURCE%" push origin main "%TAG%"
if errorlevel 1 (
    echo Error: Failed to push tag %TAG%
    exit /b 1
)

echo Released %TAG% -- GitHub Actions will handle packaging
