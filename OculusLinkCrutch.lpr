program OculusLinkCrutch;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils, CustApp, LazUTF8, Windows, JWatlHelp32, Process, IniFiles;

type

  { TOculusLinkCrutch }

  TOculusLinkCrutch = class(TCustomApplication)
  protected
    procedure DoRun; override;
  public
    constructor Create(TheOwner: TComponent); override;
  end;

{ TOculusLinkCrutch }

function GetOculusProcessPriorety: DWORD;
var
  Snapshot,
  Process: THandle;
  PERec: TProcessEntry32;
begin
  Result:=9999;
  try
    Snapshot:= CreateToolhelp32Snapshot(TH32CS_SNAPALL, 0);
    try
     PERec.dwSize:= SizeOf(PERec);
     if Process32First(Snapshot, PERec) then
      while Process32Next(Snapshot, PERec) do
       begin
       if PERec.szExeFile='OVRServer_x64.exe' then
        begin
          try
           Process:= OpenProcess(PROCESS_QUERY_INFORMATION, False, PERec.th32ProcessID);
           Result:= GetPriorityClass(Process);
          finally
           CloseHandle(Process);
          end;
        end;
       end;
    finally
     CloseHandle(Snapshot);
    end;
  except
  end;
end;

procedure SetOculusProcessPriorety(Priorety: DWORD);
var
  Snapshot,
  Process: THandle;
  PERec: TProcessEntry32;
begin
  try
    Snapshot:= CreateToolhelp32Snapshot(TH32CS_SNAPALL, 0);
    try
     PERec.dwSize:= SizeOf(PERec);
     if Process32First(Snapshot, PERec) then
      while Process32Next(Snapshot, PERec) do
       begin
       if PERec.szExeFile='OVRServer_x64.exe' then
        begin
          try
           Process:= OpenProcess(PROCESS_SET_INFORMATION, False, PERec.th32ProcessID);
           SetPriorityClass(Process, Priorety);
          finally
           CloseHandle(Process);
          end;
        end;
       end;
    finally
     CloseHandle(Snapshot);
    end;
  except
  end;
end;

procedure TOculusLinkCrutch.DoRun;
var
  ini: TIniFile;
  iniProirity: Integer;
  iniFile,
  fn: String;
  Priorety: DWORD;
begin
  iniFile:=    'C:\Program Files\Oculus\Support\oculus-diagnostics\OculusDebugTool.exe';
  iniProirity:= 2;  // 0 - Normal, 1 - Hi, 2 - Real

  fn:= ChangeFileExt(ParamStr(0), '.ini');
  ini:= TIniFile.Create(fn);

  if FileExists(fn) then
   begin
   iniFile:=     ini.ReadString( 'settings', 'OculusDebugToolFullPath', iniFile);
   iniProirity:= ini.ReadInteger('settings', 'OVRServerMaxPriorety',    iniProirity);
   end
    else
     begin
     ini.WriteString( 'settings', 'OculusDebugToolFullPath', iniFile);
     ini.WriteInteger('settings', 'OVRServerMaxPriorety',    iniProirity);
     end;

  ini.Free;

  if GetOculusProcessPriorety=NORMAL_PRIORITY_CLASS then
   begin
    Case iniProirity of
     0: Priorety:= NORMAL_PRIORITY_CLASS;
     1: Priorety:= HIGH_PRIORITY_CLASS;
     2: Priorety:= REALTIME_PRIORITY_CLASS;
     else Priorety:= NORMAL_PRIORITY_CLASS;
    end;
   end
    else Priorety:= NORMAL_PRIORITY_CLASS;

   try
    if RunCommand(iniFile,
                  ['--ToggleConsoleVisibility',  '--RestartService',  '--exit'],
                  fn,
                  [poWaitOnExit],
                  swoHIDE) then SetOculusProcessPriorety(Priorety);
   except
   end;

  Terminate;
end;

constructor TOculusLinkCrutch.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  StopOnException:=True;
end;

var
  Application: TOculusLinkCrutch;

{$R *.res}

begin
  Application:=TOculusLinkCrutch.Create(nil);
  Application.Title:='Oculus Link Crutch';
  Application.Run;
  Application.Free;
end.

