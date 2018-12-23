unit GL_ServerFunction;
interface
uses
   System.Classes,IniFiles,SysUtils,System.Win.Registry,Forms,Windows,Winapi.PsAPI,
   Gl_ServerConst,MsDataBasePool;
 type
   {�ļ��汾�� }
   TVersionNumber = packed record
    Major: Word;
    Minor: Word;
    Release: Word;
    Build: Word;
   end;
   TResultArray = array of string;
   function IsServerIniExist(aFileName:string;bCreate:Boolean=False):Integer;           //�Ƿ���ڷ���������Ini�������Զ�����
   function IIF(check: boolean; const v1, v2: Variant): Variant;  //��Ԫif����
   function FormatMillisecond(AElapsedMilliseconds: Int64): string;  //ʱ��ת��
   function GetCpuUsage: Single;       //ȡCPUֵ
   function GetMemoryUsed: Int64;      //ȡ�ڴ�ֵ
   function FormatByteNumber(ASize: Int64; const ADecimals: Byte = 1): string;
   function GetFileVersionNumber(const FileName: string): TVersionNumber;
   function GetFileVersionStr(const FileName: string): string;//�汾��
   function GetProcessorVersion: string;
   function GetPhysicsMemoryTotalSize: string;
   procedure OkMsg(aMsg: string; aTitle: string='');              //��Ϣ���ѿ�
   procedure CreateDataBasePool(iType:Integer;InitCount:Integer);
   procedure CloseDataBasePool;
 var
   SystemTimes: TThread.TSystemTimes;
   arrDataBasePool:array of TDataBasePool;
   VAR_ArrSQLConStr:array of string;
   Var_DefPublicDataGUID:array of String;
   Var_DefPublicDataCount:Integer;
   var_otherServer:Variant;
implementation
//iType �ĸ����ӿ�,  InitCount ��ʼ�����ٸ��߳�
procedure CreateDataBasePool(iType:Integer;InitCount:Integer);
begin
  //�ܵ����ӳ� ,ʵ�����ܵ����ӳ�,����ͬ�����ӿ�
  arrDataBasePool[iType] := TDataBasePool.Create(iType,InitCount);
end;
procedure CloseDataBasePool;
var
  i: Integer;
begin
  for i := Low(arrDataBasePool) to High(arrDataBasePool) do
  begin
    arrDataBasePool[i].Free;
  end;
end;
function IsServerIniExist(aFileName:string;bCreate:Boolean=False):Integer;
var
  myIniFile:TIniFile;
  aFilestr:String;
  hd: Integer;
begin
  Result := 0;
  if aFileName='' then   Exit;
  aFilestr := VAR_ProgramPath+aFileName;
  //�ж��Ƿ����SerVerIni
  if Not FileExists(aFilestr) then
  begin
    if bCreate then
    begin
      //�����ڵĻ��½�һ��Int����
      hd := filecreate(aFilestr);
      FileClose(hd);
      try
        myIniFile := TIniFile.Create(aFilestr);
        myIniFile.WriteString('ServerSet','iPort','-1');
        myIniFile.WriteString('ServerSet','Active','0');
        myIniFile.WriteString('ServerSet','iCount','0');
        myIniFile.WriteString('ServerSet','iFactoryMode','2');
        myIniFile.WriteString('ServerSet','LoginOnly','0');
        myIniFile.WriteString('ServerSet','ADOConnectStr','');
        myIniFile.WriteInteger('ServerSet','RunOnePort',22222);
        myIniFile.WriteString('ServerSet','ServerDBType','MSSQL');
        myIniFile.WriteString('ServerSet','MainExeName','PJ_FlmServerClient.exe');
      finally
        myIniFile.Free;
        Result := 2;
      end;
    end;

  end
  else
  begin
    Result := 1;
  end;
  try
    if not DirectoryExists(VAR_ProgramPath+'Update\MainExe') then //�ж�Ŀ¼�Ƿ����
    begin
      ForceDirectories(VAR_ProgramPath+'Update\MainExe')//����Ŀ¼
    end;
  except

  end;


end;

procedure OkMsg(aMsg: string; aTitle: string='');     //��ʾ��ʾ��Ϣ
begin
  if aTitle<>'' then
    Application.MessageBox(PChar(aMsg), PChar(aTitle), MB_OK + MB_ICONINFORMATION + MB_TOPMOST)  
  else
    Application.MessageBox(PChar(aMsg), PChar('��ʾ��Ϣ'), MB_OK + MB_ICONINFORMATION + MB_TOPMOST);
end;

function IIF(check: boolean; const v1, v2: Variant): Variant;
begin
  if check then
    Result := v1
  else
    Result := v2;
end;

function FormatMillisecond(AElapsedMilliseconds: Int64): string;
const
  DAY_UNIT    = '��';
  TIME_FORMAT = 'h Сʱ n ���� s ��';
var
  LDays: Integer;
  LDateTime: TDateTime;
begin
  LDateTime := AElapsedMilliseconds / MSecsPerSec / SecsPerDay;
  LDays := Trunc(LDateTime);
  if LDays > 0 then
    Result := Format('%d %s %s', [LDays, DAY_UNIT, FormatDateTime(TIME_FORMAT, Frac(LDateTime))])
  else
    Result := Format('%s', [FormatDateTime(TIME_FORMAT, Frac(LDateTime))]);
end;

function GetCpuUsage: Single;
begin
  Result := TThread.GetCpuUsage(SystemTimes);
end;

function FormatByteNumber(ASize: Int64; const ADecimals: Byte = 1): string;
const
  NAME_BYTE = ' B';
  NAME_KB   = ' KB';
  NAME_MB   = ' MB';
  NAME_GB   = ' GB';
  NAME_TB   = ' TB';
  NAME_PB   = ' PB';

  BYTES: array [0 .. 5] of Int64 = (
    1024,
    1048576,
    1073741824,
    1099511627776,
    1125899906842624,
    1152921504606846976);
begin
  if ASize < BYTES[0] then
    Result := Format('%d B', [ASize])
  else if ASize < BYTES[1] then
    Result := Format('%0.1f KB', [ASize / BYTES[0]])
  else if ASize < BYTES[2] then
    Result := Format('%0.1f MB', [ASize / BYTES[1]])
  else if ASize < BYTES[3] then
    Result := Format('%0.1f GB', [ASize / BYTES[2]])
  else if ASize < BYTES[4] then
    Result := Format('%0.1f TB', [ASize / BYTES[3]])
  else if ASize < BYTES[5] then
    Result := Format('%0.1f PB', [ASize / BYTES[4]])
  else
    Result := 'big';
end;

function GetMemoryUsed: Int64;
var
  MemCounters: TProcessMemoryCounters;
begin
  Result := 0;
  MemCounters.cb := SizeOf(MemCounters);
  if GetProcessMemoryInfo(GetCurrentProcess, @MemCounters, SizeOf(MemCounters)) then
    Result := MemCounters.WorkingSetSize;
end;

function GetFileVersionStr(const FileName: string): string;
begin
  with GetFileVersionNumber(FileName) do
    Result := Format('%d.%d.%d.%d', [Major, Minor, Release, Build]);
end;

 function GetFileVersionNumber(const FileName: string): TVersionNumber;
var
  VersionInfoBufferSize: DWORD;
  dummyHandle: DWORD;
  VersionInfoBuffer: Pointer;
  FixedFileInfoPtr: PVSFixedFileInfo;
  VersionValueLength: UINT;
begin
  FillChar(Result, SizeOf(Result), 0);
  if not FileExists(FileName) then
    Exit;
  VersionInfoBufferSize := GetFileVersionInfoSize(PChar(FileName), dummyHandle);
  if VersionInfoBufferSize = 0 then
    Exit;
  GetMem(VersionInfoBuffer, VersionInfoBufferSize);
  try
    try
      Win32Check(GetFileVersionInfo(PChar(FileName), dummyHandle, VersionInfoBufferSize, VersionInfoBuffer));
      Win32Check(VerQueryValue(VersionInfoBuffer, '\', Pointer(FixedFileInfoPtr), VersionValueLength));
    except
      Exit;
    end;
    Result.Major := FixedFileInfoPtr^.dwFileVersionMS shr 16;
    Result.Minor := FixedFileInfoPtr^.dwFileVersionMS;
    Result.Release := FixedFileInfoPtr^.dwFileVersionLS shr 16;
    Result.Build := FixedFileInfoPtr^.dwFileVersionLS;
  finally
    FreeMem(VersionInfoBuffer);
  end;

end;

function GetProcessorVersion: string;
var
  Reg: TRegistry;
begin
  Reg := TRegistry.Create;
  try
    Reg.RootKey := HKEY_LOCAL_MACHINE;
    if Reg.OpenKey('\Hardware\Description\System\CentralProcessor\0', False) then
      Result := Reg.ReadString('ProcessorNameString');
  finally
    FreeAndNil(Reg);
  end;
end;

function GetPhysicsMemoryTotalSize: string;
var
  Ms: TMemoryStatusEx;
begin
  FillChar(Ms, SizeOf(TMemoryStatusEx), #0);
  Ms.dwLength := SizeOf(TMemoryStatusEx);
  GlobalMemoryStatusEx(Ms);
  Result := Format('%.1f', [Ms.ullTotalPhys / (1024 * 1024 * 1024)]);
end;

end.
