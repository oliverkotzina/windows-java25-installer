@echo off
setlocal EnableExtensions

rem ---------------------------------------------------------------------------
rem  install-java25.cmd
rem  Laedt Eclipse Temurin JDK 25 (x64) herunter, entpackt nach
rem  %USERPROFILE%\java\java25, legt einen Wrapper "java25.cmd" an und
rem  registriert den Ordner im User-PATH, sodass "java25" in jedem neuen
rem  Terminal verfuegbar ist. Keine Administratorrechte noetig.
rem ---------------------------------------------------------------------------

set "INSTALL_ROOT=%USERPROFILE%\java"
set "INSTALL_DIR=%INSTALL_ROOT%\java25"
set "TMP_ZIP=%TEMP%\temurin-jdk25.zip"
set "DOWNLOAD_URL=https://api.adoptium.net/v3/binary/latest/25/ga/windows/x64/jdk/hotspot/normal/eclipse"

echo.
echo === Java 25 Installer (Eclipse Temurin, User-Scope) ===
echo Zielverzeichnis: %INSTALL_DIR%
echo.

rem --- Idempotenz: bereits installiert? ---------------------------------------
if exist "%INSTALL_DIR%\bin\java.exe" (
    echo Eine Installation existiert bereits unter "%INSTALL_DIR%".
    choice /c JN /m "Neu herunterladen und ueberschreiben"
    if errorlevel 2 goto :register_only
)

rem --- Download ---------------------------------------------------------------
if not exist "%INSTALL_ROOT%" mkdir "%INSTALL_ROOT%"

echo Lade JDK 25 herunter ...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ProgressPreference='SilentlyContinue'; try { Invoke-WebRequest -Uri '%DOWNLOAD_URL%' -OutFile '%TMP_ZIP%' -UseBasicParsing -MaximumRedirection 10 } catch { Write-Error $_; exit 1 }"
if errorlevel 1 (
    echo FEHLER: Download fehlgeschlagen.
    goto :fail
)

rem --- Extraktion -------------------------------------------------------------
echo Entpacke Archiv ...
if exist "%INSTALL_DIR%" rmdir /s /q "%INSTALL_DIR%"
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { Expand-Archive -Path '%TMP_ZIP%' -DestinationPath '%INSTALL_ROOT%' -Force } catch { Write-Error $_; exit 1 }"
if errorlevel 1 (
    echo FEHLER: Entpacken fehlgeschlagen.
    goto :fail
)

rem Temurin-ZIPs enthalten einen Unterordner wie "jdk-25+36" -> umbenennen.
set "EXTRACTED="
for /d %%D in ("%INSTALL_ROOT%\jdk-25*") do set "EXTRACTED=%%D"
if not defined EXTRACTED (
    echo FEHLER: Erwarteten Unterordner jdk-25* nicht gefunden.
    goto :fail
)
rem Umbenennen mit Retry: Virenscanner/Indexer halten die gerade entpackten
rem Dateien kurz offen, sodass ein sofortiger "ren" mit "Zugriff verweigert"
rem scheitern kann. Wir versuchen es bis zu 15 Sekunden lang.
set "RETRY=0"
:ren_retry
ren "%EXTRACTED%" "java25" 2>nul
if not errorlevel 1 goto :ren_ok
set /a RETRY+=1
if %RETRY% lss 15 (
    echo   Ordner gesperrt, erneuter Versuch %RETRY%/15 ...
    timeout /t 1 /nobreak >nul
    goto :ren_retry
)
echo FEHLER: Umbenennen nach java25 fehlgeschlagen (Ordner dauerhaft gesperrt).
echo Hinweis: Ggf. Virenscanner pruefen oder den Ordner "%EXTRACTED%"
echo manuell nach "%INSTALL_DIR%" umbenennen und das Skript erneut starten.
goto :fail
:ren_ok

rem --- Wrapper java25.cmd anlegen --------------------------------------------
echo Erzeuge Wrapper "%INSTALL_DIR%\java25.cmd" ...
> "%INSTALL_DIR%\java25.cmd" echo @echo off
>>"%INSTALL_DIR%\java25.cmd" echo "%%~dp0bin\java.exe" %%*

:register_only
rem --- PATH-Eintrag im User-Scope --------------------------------------------
rem  Absichtlich CMD-nativ (reg query + setx) statt PowerShell, damit das
rem  Skript auch im PowerShell Constrained Language Mode (WDAC/AppLocker)
rem  laeuft, wo .NET-Methodenaufrufe wie [Environment]::Set... blockiert sind.
rem  "setx" loest zusaetzlich die WM_SETTINGCHANGE-Broadcast aus, damit neu
rem  gestartete Terminals den neuen PATH sofort sehen.
echo Registriere "%INSTALL_DIR%" im User-PATH ...

set "CURRENT_USER_PATH="
for /f "tokens=2,*" %%A in ('reg query "HKCU\Environment" /v Path 2^>nul ^| find /i "Path"') do set "CURRENT_USER_PATH=%%B"

if defined CURRENT_USER_PATH (
    echo ";%CURRENT_USER_PATH%;" | find /i ";%INSTALL_DIR%;" >nul
    if not errorlevel 1 (
        echo PATH enthaelt den Eintrag bereits.
        goto :path_done
    )
    set "NEW_USER_PATH=%CURRENT_USER_PATH%;%INSTALL_DIR%"
) else (
    set "NEW_USER_PATH=%INSTALL_DIR%"
)

setx Path "%NEW_USER_PATH%" >nul
if errorlevel 1 (
    echo FEHLER: PATH konnte nicht gesetzt werden.
    goto :fail
)
echo PATH aktualisiert.

:path_done

rem --- Cleanup ----------------------------------------------------------------
if exist "%TMP_ZIP%" del /q "%TMP_ZIP%"

echo.
echo === Fertig ===
echo Java 25 installiert unter: %INSTALL_DIR%
echo Oeffne ein NEUES Terminal und teste:  java25 -version
echo.
endlocal
exit /b 0

:fail
if exist "%TMP_ZIP%" del /q "%TMP_ZIP%"
endlocal
exit /b 1
