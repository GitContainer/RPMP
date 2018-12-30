{
���ܣ�ҵ��ӿ�ʵ�ֵ�Ԫ
author : zhyhui
date: 2018-12-08
}

unit uTaskPlugDLL;

interface

uses
  Winapi.Windows,Graphics, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  TaskServerIntf,SynCommons,System.StrUtils,System.DateUtils,sfLog,
  QString, QPlugins,qplugins_base;
const
  ConstAppTaskNo = '100';    //ƻ��ҵ��
  ConstAppTaskUserNo = '100101';   //�����ͻ�
type
  TServiceRemoteSQL = class(TQService, IRemoteSQL)
  private
    FAppTaskNo: string;          //ҵ��ģ�ͱ��
    FAppTaskUserNo: string;      //ҵ��ͻ����
  public
    constructor Create(const AId: TGuid; AName: QStringW); overload; override;
    destructor Destroy; override;
    //��ȡ���key
    function GetPlugKey: string;
    //���������ܴ���
    function RecvDataGeneralControl(aUrlPath,aRecvStr: AnsiString; var Error: string): RawJSON;
    //У��������ȷ���
    function CheckRecvData(aRecvStr: AnsiString; var Error: string): Boolean;
    //��¼��֤
    function Login(aRecvStr: AnsiString; var Error: string): RawJSON;
    property AppTaskNo: string  read FAppTaskNo;
    property AppTaskUserNo: string read FAppTaskUserNo;
  end;

  TRemoteSQLService = class(TQService)
  public
    function GetInstance: IQService; override; stdcall;
  end;

implementation
function TServiceRemoteSQL.GetPlugKey: string;
begin
  Result := FAppTaskNo+'-'+FAppTaskUserNo;
end;
constructor  TServiceRemoteSQL.create(const AId: TGuid; AName: QStringW);
begin
  inherited Create(AId, AName);
  FAppTaskNo := ConstAppTaskNo;
  FAppTaskUserNo := ConstAppTaskUserNo;
end;
destructor TServiceRemoteSQL.Destroy;
begin
  inherited;
end;
function TServiceRemoteSQL.CheckRecvData(aRecvStr: AnsiString; var Error: string): Boolean;
begin
  //��������������ȫ���,�Ժ���ڴ��������ͳһ����Ȩ�����ص�
  Result := True;
end;
function TServiceRemoteSQL.Login(aRecvStr: AnsiString; var Error: string): RawJSON;
begin
  Result := '{"data":"��¼�ɹ�"}';
end;
function TServiceRemoteSQL.RecvDataGeneralControl(aUrlPath,aRecvStr: AnsiString; var Error: string): RawJSON;
begin
  Result := '';
  {$REGION '��¼'}
  if PosEx('logininfo/1.0',aUrlPath) > 0 then
  begin
    if not CheckRecvData(aRecvStr,Error) then
    begin
      Exit;
    end
    else
    begin
      Result := Login(aRecvStr,Error);
    end;
  end;
  {$ENDREGION}
end;

function TRemoteSQLService.GetInstance: IQService;
begin
  Result := TServiceRemoteSQL.Create(NewId, ConstAppTaskNo+ConstAppTaskUserNo+'Service');
end;
initialization
// ע�����
RegisterServices('Services/'+ConstAppTaskNo,
  [TRemoteSQLService.Create(IRemoteSQL, ConstAppTaskUserNo)]);
finalization
// ȡ������ע��
UnregisterServices('Services/'+ConstAppTaskNo, [ConstAppTaskUserNo]);
end.
