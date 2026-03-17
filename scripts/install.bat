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
copy /Y "%SOURCE%Data\DungeonEnemies.lua" "%DEST%\Data\"
copy /Y "%SOURCE%Data\Sounds.lua" "%DEST%\Data\"

if not exist "%DEST%\Engine" mkdir "%DEST%\Engine"
copy /Y "%SOURCE%Engine\Scheduler.lua" "%DEST%\Engine\"
copy /Y "%SOURCE%Engine\CombatWatcher.lua" "%DEST%\Engine\"
copy /Y "%SOURCE%Engine\NameplateScanner.lua" "%DEST%\Engine\"

if not exist "%DEST%\Display" mkdir "%DEST%\Display"
copy /Y "%SOURCE%Display\IconDisplay.lua" "%DEST%\Display\"

if not exist "%DEST%\UI" mkdir "%DEST%\UI"
copy /Y "%SOURCE%UI\PackFrame.lua" "%DEST%\UI\"
copy /Y "%SOURCE%UI\ConfigFrame.lua" "%DEST%\UI\"

if not exist "%DEST%\Libs" mkdir "%DEST%\Libs"
xcopy /Y /E /I "%SOURCE%Libs" "%DEST%\Libs"

if not exist "%DEST%\Import" mkdir "%DEST%\Import"
copy /Y "%SOURCE%Import\Decode.lua" "%DEST%\Import\"
copy /Y "%SOURCE%Import\Pipeline.lua" "%DEST%\Import\"

echo Done! /reload in WoW to load the addon.
