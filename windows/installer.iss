[Setup]
AppName=Myriad Monitor
AppVersion=0.0.1
AppPublisher=辰渊尘
AppPublisherURL=https://github.com/mcxiaochenn/myriad-monitor
AppSupportURL=https://github.com/mcxiaochenn/myriad-monitor/issues
DefaultDirName={autopf}\Myriad Monitor
DefaultGroupName=Myriad Monitor
LicenseFile=..\LICENSE
OutputDir=..\build\windows\installer
OutputBaseFilename=myriad-monitor-windows-installer
Compression=lzma2
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs

[Icons]
Name: "{group}\Myriad Monitor"; Filename: "{app}\myriad_monitor.exe"
Name: "{group}\{cm:UninstallProgram,Myriad Monitor}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\Myriad Monitor"; Filename: "{app}\myriad_monitor.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\myriad_monitor.exe"; Description: "{cm:LaunchProgram,Myriad Monitor}"; Flags: nowait postinstall skipifsilent
