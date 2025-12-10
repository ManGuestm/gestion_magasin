[Setup]
AppName=Gestion Grossiste
AppVersion=1.0.2
AppPublisher=Parfait Rakotoarisaona
DefaultDirName={autopf}\Gestion Grossiste
DefaultGroupName=Gestion Grossiste
OutputDir=installer
OutputBaseFilename=Gestion_Grossiste_Setup
Compression=lzma
SolidCompression=yes
SetupIconFile=assets\images\logo.ico
UninstallDisplayIcon={app}\gestion_magasin.exe
AppVerName=Gestion Grossiste - Solution ERP Commerciale Professionnelle


[Languages]
Name: "french"; MessagesFile: "compiler:Languages\French.isl"

[Tasks]
Name: "desktopicon"; Description: "Créer un raccourci sur le bureau"; GroupDescription: "Raccourcis supplémentaires:"

[Files]
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Gestion Grossiste"; Filename: "{app}\gestion_magasin.exe"; IconFilename: "{app}\data\flutter_assets\assets\images\logo.ico"
Name: "{commondesktop}\Gestion Grossiste"; Filename: "{app}\gestion_magasin.exe"; IconFilename: "{app}\data\flutter_assets\assets\images\logo.ico"; Tasks: desktopicon

[Run]
Filename: "{app}\gestion_magasin.exe"; Description: "Lancer Gestion Grossiste"; Flags: nowait postinstall skipifsilent