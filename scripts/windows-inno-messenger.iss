#define MyAppName "RaccoonLine Messenger"
#define MyAppVersion "0.5.0.5"
#define MyAppPublisher "RaccoonLine Messenger"
#define MyAppExeName "RaccoonLineMessenger.exe"

[Setup]
AppId=ab0e50ba-c334-4ffa-bb44-7f666aefa2f9
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf64}\{#MyAppName}
DisableProgramGroupPage=yes
OutputBaseFilename=RaccoonLine_Messenger_Setup_{#MyAppVersion}
Compression=lzma
SolidCompression=yes
WizardStyle=modern
CloseApplications=force
CloseApplicationsFilter={#MyAppExeName}
SetupIconFile=..\..\UI\Images\raccoonline.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
WizardSmallImageFile=..\..\UI\Images\raccoonline_install.bmp
PrivilegesRequired=admin
UsedUserAreasWarning=no

[Dirs]
Name: "{app}"; Permissions: users-full
// Name: "{app}\data"; Permissions: users-full
// Name: "{localappdata}\{#MyAppName}"; Permissions: users-full

[UninstallDelete]
Type: filesandordirs; Name: "{app}"
Type: filesandordirs; Name: "{localappdata}\{#MyAppName}"

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
Source: "RaccoonLineMessenger.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "*.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "generic\*"; DestDir: "{app}\generic"; Flags: ignoreversion recursesubdirs
Source: "iconengines\*"; DestDir: "{app}\iconengines"; Flags: ignoreversion recursesubdirs
Source: "imageformats\*"; DestDir: "{app}\imageformats"; Flags: ignoreversion recursesubdirs
Source: "networkinformation\*"; DestDir: "{app}\networkinformation"; Flags: ignoreversion recursesubdirs
// Source: "platforminputcontexts\*"; DestDir: "{app}\platforminputcontexts"; Flags: ignoreversion recursesubdirs
Source: "platforms\*"; DestDir: "{app}\platforms"; Flags: ignoreversion recursesubdirs
Source: "qml\*"; DestDir: "{app}\qml"; Flags: ignoreversion recursesubdirs
Source: "tls\*"; DestDir: "{app}\tls"; Flags: ignoreversion recursesubdirs
Source: "translations\*"; DestDir: "{app}\translations"; Flags: ignoreversion recursesubdirs
// Source: "raccoon-core\*"; DestDir: "{app}\raccoon-core"; Flags: ignoreversion recursesubdirs
Source: "..\..\UI\Images\raccoonline.ico"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\..\VC_redist.x64.exe"; DestDir: "{tmp}"; Flags: deleteafterinstall

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\raccoonline.ico"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon; IconFilename: "{app}\raccoonline.ico"

[Run]
Filename: "{tmp}\VC_redist.x64.exe"; \
    Description: "Install Microsoft Visual C++ Redistributable"; \
    Parameters: ""; \
    Flags: waituntilterminated runascurrentuser; \
    Check: VCRedistNeedsInstall

Filename: "{app}\{#MyAppExeName}"; \
    Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; \
    Flags: nowait postinstall skipifsilent runascurrentuser

[Code]
function VCRedistNeedsInstall: Boolean;
var
    Version: String;
begin
    // if RegQueryStringValue(HKEY_LOCAL_MACHINE,
    //    'SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64',
    //    'Version', Version) then
    // begin
       // if Copy(Version, 1, 1) = 'v' then
         //   Delete(Version, 1, 1);

        //Result := (Version < '14.42.34433');
    // end
    // else
    // begin
        Result := True;
    // end;
end;
