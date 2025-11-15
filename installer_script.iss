[Setup]
AppName=Logiciel P.O.S Tranombarotra
AppVersion=1.0
DefaultDirName={pf}\Tranombarotra POS
DefaultGroupName=Tranombarotra POS
OutputDir=installer
OutputBaseFilename=Tranombarotra_POS_Setup
Compression=lzma
SolidCompression=yes
SetupIconFile=assets\images\logo.ico

[Languages]
Name: "french"; MessagesFile: "compiler:Languages\French.isl"

[Tasks]
Name: "desktopicon"; Description: "Créer un raccourci sur le bureau"; GroupDescription: "Raccourcis supplémentaires:"

[Files]
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Tranombarotra POS"; Filename: "{app}\magasin_grossiste.exe"
Name: "{commondesktop}\Tranombarotra POS"; Filename: "{app}\magasin_grossiste.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\magasin_grossiste.exe"; Description: "Lancer Tranombarotra POS"; Flags: nowait postinstall skipifsilent