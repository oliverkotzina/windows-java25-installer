# java25-installer

Windows-CMD-Skripte, die **Eclipse Temurin JDK 25** im Benutzerverzeichnis
installieren und den Befehl `java25` global verfügbar machen — ohne
Administratorrechte und ohne eine vorhandene `java`-Installation zu verändern.

## Voraussetzungen

- Windows 10 / 11 (x64)
- PowerShell 5.0 oder neuer (in Windows 10/11 Standard)
- Internetzugang zu `api.adoptium.net`

## Installation

1. `install-java25.cmd` per Doppelklick oder in einer `cmd`-Shell starten.
2. Das Skript lädt den aktuellen Temurin JDK 25 GA-Build herunter, entpackt
   ihn nach `%USERPROFILE%\java\java25` und ergänzt diesen Pfad im
   **User-PATH**.
3. Ein **neues** Terminal öffnen und prüfen:

   ```cmd
   java25 -version
   where java25
   ```

   Erwartete Ausgabe: `openjdk version "25..."` bzw. der Pfad
   `%USERPROFILE%\java\java25\java25.cmd`.

## Deinstallation

`uninstall-java25.cmd` ausführen. Das Skript löscht den Ordner
`%USERPROFILE%\java\java25` und entfernt den PATH-Eintrag wieder.

## Wie funktioniert `java25`?

Im Installationsordner wird ein Wrapper `java25.cmd` angelegt:

```cmd
@echo off
"%~dp0bin\java.exe" %*
```

Da der Installationsordner im PATH steht, kann der Wrapper aus jedem Terminal
als `java25` aufgerufen werden und reicht alle Argumente an die echte
`java.exe` aus dem zugehörigen JDK-25-Bin-Verzeichnis weiter. Eine eventuell
parallel installierte `java.exe` einer anderen Version bleibt unverändert.

## Download-Quelle

Der Installer verwendet die Adoptium-API, die immer auf den aktuellen GA-Build
verweist:

```
https://api.adoptium.net/v3/binary/latest/25/ga/windows/x64/jdk/hotspot/normal/eclipse
```

## Hinweise

- Der ursprünglich gewünschte Pfad `C:\java\java25` wurde bewusst durch
  `%USERPROFILE%\java\java25` ersetzt, da letzterer ohne Admin-Rechte
  beschreibbar ist.
- `setx` wird absichtlich **nicht** verwendet, da es den PATH auf 1024 Zeichen
  kürzt. Stattdessen setzt das Skript den User-PATH direkt über
  `[Environment]::SetEnvironmentVariable(..., 'User')`; das löst zusätzlich den
  `WM_SETTINGCHANGE`-Broadcast aus, sodass neu geöffnete Terminals den
  aktualisierten PATH sofort sehen.
