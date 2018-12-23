unit PubConst;

interface
uses
  Windows, Messages, SysUtils, Variants, Classes,ShellAPI,DateUtils,Graphics,jpeg,EncdDecd;
Type
  TPubMtdCmd = class
  public
  {----------------------------------------------------------------
  Unixʱ��ת����delphiʱ��
  @param  UnixDateTime   Unix��ʽʱ��
  @return          ����delphi��ʽʱ��
  -----------------------------------------------------------------}
  class function UnixDateTimeToDelphiDateTime(UnixDateTime: Integer): TDateTime;
  {----------------------------------------------------------------
  delphiʱ��ת����Unixʱ��
  @param  DTime   delphi��ʽʱ��
  @return          ����Unix��ʽʱ��
  -----------------------------------------------------------------}
  class  function DelphiDateTimeToUnixDateTime(DTime: TDateTime): Integer;
  {*-----------------------------------------------------------------------
  ����ɾ����־Ŀ¼
  @param DirecName
  @return ��
  -------------------------------------------------------------------------}
  class procedure RemoveLogDirectory(DirecName : string);
  {*-----------------------------------------------------------------------
  ���Ҳ�ɾ�����ڵ���־Ŀ¼
  @param LogPath ��Ҫ�鵽��������־���ϼ�Ŀ¼
  @param Days  ����
  @return ��
  -------------------------------------------------------------------------}
  class procedure DeleteLogDirc(LogPath : string;Days: Integer);
  {*-----------------------------------------------------------------------
  ��ȡGUID
  @param ��
  @return ����GUID
  -------------------------------------------------------------------------}
  class function GetGUID: string;
  {------------------------------------------------------------------------
   ����: ���������������ʱ��
  @param  startTime : �������ʱ��
  @return ����ֵ  �����������ʱ��
  -------------------------------------------------------------------------}
  class function GetRunTimeINfo(startTime: TDateTime): String;
  {------------------------------------------------------------------------
   ����: ��������ʱ��Ĳ�ֵ(����) �� MinutesBetween ׼ȷ
  @param  ANow : ��ǰʱ��
  @param  AThen : ����ʱ��
  @return ����ֵ  ����ʱ��֮��Ĳ�ֵ(������)
  -------------------------------------------------------------------------}
  class function MyMinutesBetween(const ANow, AThen: TDateTime): integer;
  {------------------------------------------------------------------------
   ����: ��base64�ַ���ת��ΪJpegͼƬ
  @param  ImgStr : base64�ַ���
  @return ����ֵ  JpegͼƬ
  -------------------------------------------------------------------------}
  class function Base64StringToJpeg(ImgStr:string):TJPEGImage;
  constructor Create;
  destructor Destroy; override;
  end;
implementation
constructor TPubMtdCmd.Create;
begin
end;
destructor TPubMtdCmd.Destroy;
begin
 Inherited;
end;
class function TPubMtdCmd.GetRunTimeINfo(startTime: TDateTime): String;
var
  lvMSec, lvRemain:Int64;
  lvDay, lvHour, lvMin, lvSec:Integer;
begin
  lvMSec := MilliSecondsBetween(Now(), startTime);
  lvDay := Trunc(lvMSec / MSecsPerDay);
  lvRemain := lvMSec mod MSecsPerDay;
  lvHour := Trunc(lvRemain / (MSecsPerSec * 60 * 60));
  lvRemain := lvRemain mod (MSecsPerSec * 60 * 60);
  lvMin := Trunc(lvRemain / (MSecsPerSec * 60));
  lvRemain := lvRemain mod (MSecsPerSec * 60);
  lvSec := Trunc(lvRemain / (MSecsPerSec));
  if lvDay > 0 then
    Result := Result + IntToStr(lvDay) + ' d ';
  if lvHour > 0 then
    Result := Result + IntToStr(lvHour) + ' h ';
  if lvMin > 0 then
    Result := Result + IntToStr(lvMin) + ' m ';
  if lvSec > 0 then
    Result := Result + IntToStr(lvSec) + ' s ';
end;
class function TPubMtdCmd.GetGUID: string;        //add lgm
var
  LTep: TGUID;
  sGUID :string;
begin
  CreateGUID(LTep);
  sGUID := GUIDToString(LTep);
  sGUID := StringReplace(sGUID,'-','',[rfReplaceAll]);
  sGUID := Copy(sGUID,2,Length(sGUID)-2);
  Result :=  sGUID;
end;
class function TPubMtdCmd.DelphiDateTimeToUnixDateTime(DTime: TDateTime): Integer;
begin
  Result := SecondsBetween(DTime,EncodeDateTime(1970,1,1,0,0,0,0));
end;
class function TPubMtdCmd.UnixDateTimeToDelphiDateTime(UnixDateTime: Integer): TDateTime;
begin
  Result := EncodeDate(1970,1,1)+(UnixDateTime/86400);
end;
class procedure  TPubMtdCmd.DeleteLogDirc(LogPath: string;Days: Integer);
var
  Sr1 : TsearchRec;
  PathStr : string;
begin
  PathStr := LogPath;
  if FindFirst(PathStr+'*.*',faAnyFile,SR1)=0 then
  begin
    if (Sr1.Name <>'.') and (SR1.Name <> '..') then
    begin
      if SR1.Attr = faDirectory then
      begin
        if Sr1.Name <(FormatDateTime('YYYYMMDD',IncDay(Now,-Days))) then
          RemoveLogDirectory(PathStr+Sr1.Name);
      end;
    end;
    while FindNext(SR1)=0 do
    begin
      if (Sr1.Name <>'.') and (SR1.Name <> '..') then
      begin
        if SR1.Attr = faDirectory then
        begin
          if Sr1.Name <(FormatDateTime('YYYYMMDD',IncDay(Now,-Days))) then
            RemoveLogDirectory(PathStr+Sr1.Name);
        end;
      end;
    end;
    FindClose(SR1);
  end;
end;
class procedure  TPubMtdCmd.RemoveLogDirectory(DirecName: string);
var
  F: TSHFILEOPSTRUCT;
begin
  try
    FillChar(F, SizeOf(F), 0);
    with F do
    begin
      Wnd := 0;
      wFunc := FO_DELETE;
      pFrom := PChar(DirecName+#0);
      pTo := PChar(DirecName+#0);
      ///�ɻ�ԭ��ȷ�ϴ�����ʾ
      fFlags := FOF_NOCONFIRMATION+FOF_NOERRORUI;
    end;
    SHFileOperation(F);
  except
  end;
end;
class function  TPubMtdCmd.MyMinutesBetween(const ANow, AThen: TDateTime): integer;
begin
  Result := round(MinuteSpan(ANow, AThen));
end;
class function  TPubMtdCmd.Base64StringToJpeg(ImgStr:string):TJPEGImage;
var ss:TStringStream;
    ms:TMemoryStream;
    jpg:TJPEGImage;
begin
  try
    ss := TStringStream.Create(imgStr);
    ms := TMemoryStream.Create;
    DecodeStream(ss,ms);//��base64�ַ�����ԭΪ�ڴ���
    ms.Position:=0;
    jpg := TJPEGImage.Create;
    jpg.LoadFromStream(ms);
    ss.Free;
    ms.Free;
    result :=jpg;
  except
  end;
end;
end.
