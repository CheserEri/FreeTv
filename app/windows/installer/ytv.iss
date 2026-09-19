; YTV 安装包脚本（Inno Setup 6）
;
; 用途：把 flutter build windows --release 的产物打包成单文件安装程序，
; 通过 GitHub Releases 公开分发。分发边界的决策记录与风险说明见
; docs/08-项目管理/实施路线与验收-v0.1.md 的「分发边界」一节。
;
; 编译：
;   & "C:\Users\chese\AppData\Local\Programs\Inno Setup 6\ISCC.exe" ytv.iss
; 产物：
;   windows\installer\Output\YTV-Setup.exe
;
; 前提：先执行过 flutter build windows --release。

#define AppName "YTV"
#define AppVersion "0.1.0"
#define AppPublisher "YTV"
#define AppExeName "ytv.exe"
#define ReleaseDir "..\..\build\windows\x64\runner\Release"

[Setup]
; AppId 是安装标识，升级安装时靠它识别同一应用，一经发布不要再改。
AppId={{8F3A6C21-5D74-4E19-9B02-7C1E4A8D5F63}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
; 公开分发须用标准安装位置：本机自用时写的是 D:\SoftWare\YTV，
; 但多数目标机器没有 D 盘，那样会安装失败。安装向导仍允许改路径。
DefaultDirName={autopf}\YTV
DisableDirPage=no
DisableProgramGroupPage=yes
OutputDir=Output
OutputBaseFilename=YTV-Setup
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
; 应用图标复用 runner 资源，快捷方式与「应用和功能」里都用它。
SetupIconFile=..\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#AppExeName}
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
; 覆盖前自动关闭正在运行的 YTV，避免文件占用导致安装失败。
CloseApplications=yes
RestartApplications=no

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
; 整个 Release 目录必须一起装：ytv.exe 只是启动器，
; 依赖同级的 flutter_windows.dll、三个插件 dll 与 data 目录。
Source: "{#ReleaseDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#AppName}"; Filename: "{app}\{#AppExeName}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#AppExeName}"; Description: "{cm:LaunchProgram,{#AppName}}"; Flags: nowait postinstall skipifsilent
