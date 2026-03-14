@echo off
REM Copies addon files to WoW AddOns folder for local development

set "SOURCE=%~dp0..\"
set "DEST=%PROGRAMFILES(x86)%\World of Warcraft\_retail_\Interface\AddOns\TerriblePackWarnings"

if not exist "%DEST%" mkdir "%DEST%"

echo Copying TerriblePackWarnings to WoW retail addons folder...

copy /Y "%SOURCE%TerriblePackWarnings.toc" "%DEST%\"
copy /Y "%SOURCE%Core.lua" "%DEST%\"

if not exist "%DEST%\Data" mkdir "%DEST%\Data"
copy /Y "%SOURCE%Data\WindrunnerSpire.lua" "%DEST%\Data\"

echo Done! /reload in WoW to load the addon.
