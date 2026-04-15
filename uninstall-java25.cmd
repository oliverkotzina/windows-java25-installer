@echo off
setlocal EnableExtensions

rem ---------------------------------------------------------------------------
rem  uninstall-java25.cmd
rem  Entfernt die durch install-java25.cmd angelegte Java-25-Installation
rem  sowie den zugehoerigen User-PATH-Eintrag.
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
powershell -NoProfile -ExecutionPolicy Bypass -Command "$t='%INSTALL_DIR%'; $p=[Environment]::GetEnvironmentVariable('Path','User'); if ([string]::IsNullOrEmpty($p)) { Write-Host 'PATH war leer.'; exit 0 }; $parts=@(($p -split ';') | Where-Object { $_ -ne '' -and $_ -ine $t }); $new=$parts -join ';'; [Environment]::SetEnvironmentVariable('Path',$new,'User'); Write-Host 'PATH aktualisiert.'"
if errorlevel 1 (
    echo FEHLER: PATH konnte nicht aktualisiert werden.
    goto :fail
)

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
