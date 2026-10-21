; JO-Launcher Windows installer (Inno Setup)
; Build first: flutter build windows --release

#define MyAppName "JO-Launcher"
#define MyAppPublisher "JO-Beacon"
#define MyAppExeName "JO-Launcher.exe"

; Version is passed by build.ps1 from pubspec.yaml (ISCC /DMyAppVersion=... /DMyAppFullVersion=...).
; These defaults are used when compiling this file directly.
#ifndef MyAppVersion
  #define MyAppVersion "0.0.0"
#endif
#ifndef MyAppFullVersion
  #define MyAppFullVersion MyAppVersion
#endif

[Setup]
AppId={{1B7249ED-16DB-4C09-8159-95B1F6E42566}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={localappdata}\Programs\JO-Launcher
DefaultGroupName={#MyAppName}
UsePreviousAppDir=no
UninstallDisplayIcon={app}\{#MyAppExeName}
SetupIconFile=..\windows\runner\resources\app_icon.ico
; Show the license during setup.
LicenseFile=..\LICENSE
OutputDir=..\dist
OutputBaseFilename=JO-Launcher-Setup-{#MyAppFullVersion}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

[Files]
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\LICENSE"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\NOTICE"; DestDir: "{app}"; Flags: ignoreversion

[Tasks]
Name: "startmenu"; Description: "Create a Start Menu shortcut"; GroupDescription: "Shortcuts:"
Name: "desktopicon"; Description: "Create a desktop shortcut"; GroupDescription: "Shortcuts:"; Flags: unchecked

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: startmenu
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Launch {#MyAppName}"; Flags: nowait postinstall skipifsilent
