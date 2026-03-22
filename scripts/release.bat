@echo off
setlocal enabledelayedexpansion

if "%~1"=="" (
    echo Usage: release.bat ^<version^>
    echo Example: release.bat 0.1.0
    exit /b 1
)

set "VERSION=%~1"
set "TAG=v%VERSION%"

echo Releasing TerriblePackWarnings %TAG%

pushd "%~dp0.."

git tag -a %TAG% -m "Release %VERSION%"
if errorlevel 1 (
    echo Error: Failed to create tag %TAG%
    popd
    exit /b 1
)

git push origin main %TAG%
if errorlevel 1 (
    echo Error: Failed to push
    popd
    exit /b 1
)

echo Released %TAG% -- GitHub Actions will handle packaging
popd
