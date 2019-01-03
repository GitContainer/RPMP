{
���ܣ�ҵ��ӿ�ʵ�ֵ�Ԫ
author : zhyhui
date: 2018-12-08
}

unit uTaskPlugDBDLL;

interface

uses
  Winapi.Windows,Graphics, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  TaskServerIntf,SynCommons,System.StrUtils,System.DateUtils,sfLog,GL_ServerFunction,Gl_ServerConst,
  Data.DB,FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf,
  FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async,
  FireDAC.Phys, FireDAC.Comp.Client, FireDAC.Stan.Param, FireDAC.DatS,
  FireDAC.DApt.Intf, FireDAC.DApt, FireDAC.Comp.DataSet, FireDAC.Phys.MSSQLDef,
  FireDAC.Phys.ODBCBase, FireDAC.Phys.MSSQL, FireDAC.VCLUI.Wait, FireDAC.Comp.UI,
  Datasnap.DBClient, FireDAC.Stan.StorageJSON, FireDAC.Stan.StorageXML,
  FireDAC.Stan.StorageBin,Data.FireDACJSONReflect,Data.DBXPlatform,
  qjson,QString, QPlugins,qplugins_base;
const
  ConstAppTaskNo = '200';    //�㽶ҵ��
  ConstAppTaskUserNo = '200101';   //�����ͻ�
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
  //�������ݿ����ӳ�
  Var_ServerInfo :=TDataSnapServerInfo.Create;
  //���������ݿ������ַ���,���ݿ�Ŀǰʹ�õ� MSSQL ,����Ի��� mysql �ȵ�,Firdac֧��N�����ݿ⣬�����Ӧ��
  Var_ServerInfo.ADOConnetStr := 'Name=Unnamed;DriverID=MSSQL;Server=.;Database=kbg;User_Name=sa;Password=sql';
  SetLength(arrDataBasePool,1);
  SetLength(VAR_ArrSQLConStr,1);
  Var_ServerInfo.ConnectionCount := 2;
  VAR_ArrSQLConStr[0] := Var_ServerInfo.ADOConnetStr; //��һ�����ӳس�ʼ��
  CreateDataBasePool(0,Var_ServerInfo.ConnectionCount);

end;
destructor TServiceRemoteSQL.Destroy;
begin
  //�ر����ݿ�����
  CloseDataBasePool;
  FreeAndNil(Var_ServerInfo);
  inherited;
end;
function TServiceRemoteSQL.CheckRecvData(aRecvStr: AnsiString; var Error: string): Boolean;
begin
  //��������������ȫ���,�Ժ���ڴ��������ͳһ����Ȩ�����ص�
  Result := True;
end;
function TServiceRemoteSQL.Login(aRecvStr: AnsiString; var Error: string): RawJSON;
var
  Connection: TFDConnection;
  TempQuery :TFDQuery;
  aQjson,tmpQjson,resultqjson: TQJson;
  kwArry: array of TQJson;
  i: Integer;
  QSQL,vData: string;
begin
  try
    aQjson := TQJson.create;
    tmpQjson := TQJson.create;
    Connection := arrDataBasePool[0].GetConnectionDB;    //������ƥ��һ���̳߳�
    TempQuery := TFDQuery.Create(nil);
    TempQuery.Connection := TFDConnection(Connection); //ʵ����
    QSQL := 'select * from T_PersonInfo';  //
    with TempQuery do
    begin
      SQL.Text := QSQL;
      FetchOptions.Mode := fmAll;
      Open;
      if recordcount > 0 then
      begin
        SetLength(kwArry,TempQuery.RecordCount);
        i := 0;
        while not TempQuery.eof do
        begin
          tmpqjson := TQJson.Create;
          tmpQjson.Clear;
          tmpQjson.Add('ID',TempQuery.FieldByName('ID').AsString,jdtString);
          tmpQjson.Add('PerName',TempQuery.FieldByName('PerName').AsString,jdtString);
          tmpQjson.Add('PerIdCard',TempQuery.FieldByName('PerIdCard').AsString,jdtString);
          kwArry[i] := tmpQjson;
          Inc(i);
          TempQuery.Next;
        end;
        //��֯�������
        aQjson.Clear;
        aQjson.Add('message','ok',jdtString);
        vData := '';
        aQjson.Add('perjmcode','',jdtString);
        aQjson.Add('datacount', IntToStr(TempQuery.RecordCount),jdtString);
        resultqjson := aQjson.AddArray('datalist');
        for I := Low(kwArry) to High(kwArry) do
         resultqjson.Add(kwArry[i]);
        aQjson.Add('resultdata','0',jdtString);
        aQjson.Add('data',vData,jdtString);
        Result := aQjson.ToString;
      end
      else
      begin
        //��֯�������
        aQjson.Clear;
        aQjson.Add('message','ok',jdtString);
        vData := '';
        aQjson.Add('perjmcode','',jdtString);
        aQjson.Add('datacount','0',jdtString);
        aQjson.AddArray('datalist');
        aQjson.Add('resultdata','0',jdtString);
        aQjson.Add('data',vData,jdtString);
        Result := aQjson.ToString;
      end;
    end;
  finally
    arrDataBasePool[0].FreeConnectionDB(Connection);  //����һ���̳߳�
    TempQuery.Close;                            //�ͷ����ݼ�
    FreeAndNil(TempQuery);
    FreeAndNil(aQjson);
  end;
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
