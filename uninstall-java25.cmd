@echo off
setlocal EnableExtensions EnableDelayedExpansion

rem ---------------------------------------------------------------------------
rem  uninstall-java25.cmd
rem  Entfernt die durch install-java25.cmd angelegte Java-25-Installation
rem  sowie den zugehoerigen User-PATH-Eintrag. CMD-nativ (reg query + setx),
rem  funktioniert auch im PowerShell Constrained Language Mode.
rem ---------------------------------------------------------------------------

set "INSTALL_DIR=%USERPROFILE%\java\java25"

echo.
echo === Java 25 Deinstallation ===
echo Zielverzeichnis: %INSTALL_DIR%
echo.

if not exist "%INSTALL_DIR%" (
    echo Hinweis: "%INSTALL_DIR%" existiert nicht.
) else (
    choice /c JN /m "Verzeichnis wirklich loeschen"
    if errorlevel 2 goto :cancelled
    rmdir /s /q "%INSTALL_DIR%"
    if errorlevel 1 (
        echo FEHLER: Verzeichnis konnte nicht geloescht werden.
        goto :fail
    )
    echo Verzeichnis entfernt.
)

echo Entferne Eintrag aus User-PATH ...

set "CURRENT_USER_PATH="
for /f "tokens=2,*" %%A in ('reg query "HKCU\Environment" /v Path 2^>nul ^| find /i "Path"') do set "CURRENT_USER_PATH=%%B"

if not defined CURRENT_USER_PATH (
    echo PATH war leer.
    goto :path_done
)

rem PATH in einzelne Eintraege aufsplitten, den Zielpfad auslassen, neu zusammensetzen.
set "NEW_USER_PATH="
for %%E in ("!CURRENT_USER_PATH:;=" "!") do (
    set "ENTRY=%%~E"
    if defined ENTRY (
        if /i not "!ENTRY!"=="%INSTALL_DIR%" (
            if defined NEW_USER_PATH (
                set "NEW_USER_PATH=!NEW_USER_PATH!;!ENTRY!"
            ) else (
                set "NEW_USER_PATH=!ENTRY!"
            )
        )
    )
)

if defined NEW_USER_PATH (
    setx Path "!NEW_USER_PATH!" >nul
) else (
    reg delete "HKCU\Environment" /v Path /f >nul
)
if errorlevel 1 (
    echo FEHLER: PATH konnte nicht aktualisiert werden.
    goto :fail
)
echo PATH aktualisiert.

:path_done
echo.
echo === Fertig ===
echo Bitte neues Terminal oeffnen, damit der PATH-Wechsel wirksam wird.
echo.
endlocal
exit /b 0

:cancelled
echo Abgebrochen.
endlocal
exit /b 1

:fail
endlocal
exit /b 1
