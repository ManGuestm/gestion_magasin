[Setup]
AppName=Gestion Grossiste
AppVersion=1.0.1+2
DefaultDirName={pf}\Gestion Grossiste
DefaultGroupName=Gestion Grossiste
OutputDir=installer
OutputBaseFilename=Gestion_Grossiste_Setup
Compression=lzma
SolidCompression=yes
SetupIconFile=assets\images\logo.ico
AppVerName=Beta


[Languages]
Name: "french"; MessagesFile: "compiler:Languages\French.isl"

[Tasks]
Name: "desktopicon"; Description: "Créer un raccourci sur le bureau"; GroupDescription: "Raccourcis supplémentaires:"

[Files]
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Gestion Grossiste"; Filename: "{app}\magasin_grossiste.exe"
Name: "{commondesktop}\Gestion Grossiste"; Filename: "{app}\magasin_grossiste.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\magasin_grossiste.exe"; Description: "Lancer Gestion Grossiste"; Flags: nowait postinstall skipifsilent