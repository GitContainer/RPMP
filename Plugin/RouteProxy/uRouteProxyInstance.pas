{
���ܣ������ӿ�ʵ�ֵ�Ԫ
����: zhyhui
Date: 2018-12-07
}
unit uRouteProxyInstance;

interface
uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes,qjson, QString, QPlugins, Vcl.Imaging.jpeg,qplugins_base,
  uRouteProxyFunc,SynCommons,TaskServerIntf;
type

  TPubRouteProxy = class(TQService, IRouteProxy)
  private
    RecvJson,aQjson: TQJson;
  protected
    //ҵ��У��������ȷ���
    function CheckWorkData(aRecvStr: AnsiString; var Error: string): Boolean; stdcall;
    //ҵ��·�ɷ���
    function RouteWorkData(aRecvStr: AnsiString; var Error: string): RawJSON; overload;  stdcall;
    //ҵ��·�ɷ���
    function RouteWorkData(aUrlPath,aRecvStr: AnsiString; var Error: string): RawJSON; overload; stdcall;
  public
    constructor Create(const AId: TGuid; AName: QStringW); overload; override;
    destructor Destroy; override;
  end;


implementation

constructor TPubRouteProxy.Create(const AId: TGuid; AName: QStringW);
begin
  inherited Create(AId, AName);
  RecvJson := TQJson.Create;
  aQjson := TQJson.Create;
end;

destructor TPubRouteProxy.Destroy;
begin
  FreeAndNil(RecvJson);
  FreeAndNil(aQjson);
  inherited;
end;

function TPubRouteProxy.CheckWorkData(aRecvStr: AnsiString; var Error: string): Boolean;
begin
  result := False;
end;
function  TPubRouteProxy.RouteWorkData(aRecvStr: AnsiString; var Error: string): RawJSON;
begin
  result := '';
end;
function  TPubRouteProxy.RouteWorkData(aUrlPath,aRecvStr: AnsiString; var Error: string): RawJSON;
var
  ACtrl: IRemoteSQL;
  AppTaskNo,AppTaskUserNo,vStr,vData: string;
begin
  try
    result := '{}';
    RecvJson.Clear;
    {$REGION '���Խ�������'}
    if not RecvJson.TryParse(aRecvStr) then
    begin
      aQjson.Clear;
      aQjson.Add('message','error',jdtString);
      vData := 'json������ʧ��,���ǺϷ�json��ʽ����';
      vStr := '1'+vData;
      aQjson.Add('perjmcode','',jdtString);
      aQjson.Add('resultdata','1',jdtString);
      aQjson.Add('data',vData,jdtString) ;
      Error := aQjson.ToString;
      result := aQjson.ToString;
      Exit;
    end;
    {$ENDREGION}
    //��������
    RecvJson.Parse(aRecvStr);
    {$REGION '�쳣���'}
    if RecvJson.IndexOf('usercode') = -1 then
    begin
      aQjson.Clear;
      aQjson.Add('message','error',jdtString);
      vData := 'δ���ҵ��û�����ڵ�,���ǺϷ�json��ʽ����';
      vStr := '1'+vData;
      aQjson.Add('perjmcode','',jdtString);
      aQjson.Add('resultdata','1',jdtString);
      aQjson.Add('data',vData,jdtString) ;
      Error := aQjson.ToString;
      result := aQjson.ToString;
      Exit;
    end;
    if RecvJson.IndexOf('perjmcode') = -1 then
    begin
      aQjson.Clear;
      aQjson.Add('message','error',jdtString);
      vData := 'δ���ҵ�ǩ������ڵ�,���ǺϷ�json��ʽ����';
      vStr := '1'+vData;
      aQjson.Add('perjmcode','',jdtString);
      aQjson.Add('resultdata','1',jdtString);
      aQjson.Add('data',vData,jdtString) ;
      Error := aQjson.ToString;
      result := aQjson.ToString;
      Exit;
    end;
    if RecvJson.IndexOf('tasktype') = -1 then
    begin
      aQjson.Clear;
      aQjson.Add('message','error',jdtString);
      vData := 'δ���ҵ�ҵ����ڵ�,���ǺϷ�json��ʽ����';
      vStr := '1'+vData;
      aQjson.Add('perjmcode','',jdtString);
      aQjson.Add('resultdata','1',jdtString);
      aQjson.Add('data',vData,jdtString) ;
      Error := aQjson.ToString;
      result := aQjson.ToString;
      Exit;
    end;
    if RecvJson.IndexOf('taskuser') = -1 then
    begin
      aQjson.Clear;
      aQjson.Add('message','error',jdtString);
      vData := 'δ���ҵ��û���ڵ�,���ǺϷ�json��ʽ����';
      vStr := '1'+vData;
      aQjson.Add('perjmcode','',jdtString);
      aQjson.Add('resultdata','1',jdtString);
      aQjson.Add('data',vData,jdtString) ;
      Error := aQjson.ToString;
      result := aQjson.ToString;
      Exit;
    end;
    {$ENDREGION}
    {
    ������: ͨ��url·�ɷ�ʽ����·�ɷ���,����ͨ��һ���Ľ����ж�URL��ַ���벻ͬ��ҵ����ģ��
    Ŀǰ�ṩ������·�ɷ�ʽ��
      1�� ���Ե���ʹ��url·�ɷ�ʽ��
      2�� ���Ե���ʹ��ҵ��json��·�ɷ�ʽ��
      3�� ���������߽��һ��ʹ��
    Ŀǰ�Ĵ���������ַ�ʽ���ʹ��,������ôʹ�ã������Լ�������ѡ�񼴿�
    /* mORmot �������Ǳ�̬�����������ĺ��� PosEx��ȫ�ǻ��ʵ��,�ֲ���������ôǿ�� */
    }
    //urlʾ��: http://127.0.0.1:8080/RpmpData/logininfo/1.0
    if PosEx('/RpmpData',aUrlPath) > 0 then
    begin
      {$REGION '������ͨ��ҵ��josn��������·�ɷ���'}
      AppTaskNo := RecvJson.ItemByName('tasktype').AsString;
      case StrToInt(AppTaskNo) of
        100:
        Begin
          {$REGION 'ƻ��ҵ��'}
          AppTaskUserNo := RecvJson.ItemByName('taskuser').AsString;
          case StrToInt(AppTaskUserNo)of
            100101:
            Begin
              {$REGION '�����ͻ�'}
              ACtrl := PluginsManager.ByPath(PWideChar('Services/'+AppTaskNo+'/'+AppTaskUserNo)) as IRemoteSQL;
              if  Assigned(ACtrl) then
              begin
                Result := ACtrl.RecvDataGeneralControl(aUrlPath,aRecvStr,Error);
              end
              else
              begin
                aQjson.Clear;
                aQjson.Add('message','error',jdtString);
                vData := 'ҵ�����쳣,δ���ҵ�ҵ����ģ��';
                vStr := '1'+vData;
                aQjson.Add('perjmcode','',jdtString);
                aQjson.Add('resultdata','1',jdtString);
                aQjson.Add('data',vData,jdtString) ;
                Error := aQjson.ToString;
                result := aQjson.ToString;
              end;
              {$ENDREGION}
            end;
            100102:
            Begin
              {$REGION '�Ϻ��ͻ�'}
              ACtrl := PluginsManager.ByPath(PWideChar('Services/'+AppTaskNo+'/'+AppTaskUserNo)) as IRemoteSQL;
              if  Assigned(ACtrl) then
              begin
                Result := ACtrl.RecvDataGeneralControl(aUrlPath,aRecvStr,Error);
              end
              else
              begin
                aQjson.Clear;
                aQjson.Add('message','error',jdtString);
                vData := 'ҵ�����쳣,δ���ҵ�ҵ����ģ��';
                vStr := '1'+vData;
                aQjson.Add('perjmcode','',jdtString);
                aQjson.Add('resultdata','1',jdtString);
                aQjson.Add('data',vData,jdtString) ;
                Error := aQjson.ToString;
                result := aQjson.ToString;
              end;
              {$ENDREGION}
            end;
          else
          begin
            aQjson.Clear;
            aQjson.Add('message','error',jdtString);
            vData := '��ҵ���벻����';
            vStr := '1'+vData;
            aQjson.Add('perjmcode','',jdtString);
            aQjson.Add('resultdata','1',jdtString);
            aQjson.Add('data',vData,jdtString) ;
            Error := aQjson.ToString;
            result := aQjson.ToString;
          end;
          end
          {$ENDREGION}
        end;
        200:
        Begin
          {$REGION '�㽶ҵ��'}
          AppTaskUserNo := RecvJson.ItemByName('taskuser').AsString;
          case StrToInt(AppTaskUserNo)of
            200101:
            Begin
              {$REGION '����'}
              ACtrl := PluginsManager.ByPath(PWideChar('Services/'+AppTaskNo+'/'+AppTaskUserNo)) as IRemoteSQL;
              if  Assigned(ACtrl) then
              begin
                Result := ACtrl.RecvDataGeneralControl(aUrlPath,aRecvStr,Error);
              end
              else
              begin
                aQjson.Clear;
                aQjson.Add('message','error',jdtString);
                vData := 'ҵ�����쳣,δ���ҵ�ҵ����ģ��';
                vStr := '1'+vData;
                aQjson.Add('perjmcode','',jdtString);
                aQjson.Add('resultdata','1',jdtString);
                aQjson.Add('data',vData,jdtString) ;
                Error := aQjson.ToString;
                result := aQjson.ToString;
              end;
              {$ENDREGION}
            end;
            200102:
            Begin
              {$REGION '�Ϻ�'}
              ACtrl := PluginsManager.ByPath(PWideChar('Services/'+AppTaskNo+'/'+AppTaskUserNo)) as IRemoteSQL;
              if  Assigned(ACtrl) then
              begin
                Result := ACtrl.RecvDataGeneralControl(aUrlPath,aRecvStr,Error);
              end
              else
              begin
                aQjson.Clear;
                aQjson.Add('message','error',jdtString);
                vData := 'ҵ�����쳣,δ���ҵ�ҵ����ģ��';
                vStr := '1'+vData;
                aQjson.Add('perjmcode','',jdtString);
                aQjson.Add('resultdata','1',jdtString);
                aQjson.Add('data',vData,jdtString) ;
                Error := aQjson.ToString;
                result := aQjson.ToString;
              end;
              {$ENDREGION}
            end;
          else
          begin
            aQjson.Clear;
            aQjson.Add('message','error',jdtString);
            vData := '��ҵ���벻����';
            vStr := '1'+vData;
            aQjson.Add('perjmcode','',jdtString);
            aQjson.Add('resultdata','1',jdtString);
            aQjson.Add('data',vData,jdtString) ;
            Error := aQjson.ToString;
            result := aQjson.ToString;
          end;
          end
          {$ENDREGION}
        end;
      else
      begin
        aQjson.Clear;
        aQjson.Add('message','error',jdtString);
        vData := '��ҵ���벻����';
        vStr := '1'+vData;
        aQjson.Add('perjmcode','',jdtString);
        aQjson.Add('resultdata','1',jdtString);
        aQjson.Add('data',vData,jdtString) ;
        Error := aQjson.ToString;
        result := aQjson.ToString;
      end;
      end;
      {$ENDREGION}
    end;
    //urlʾ��: http://127.0.0.1:8080/RpmpQuery/QueryData/logininfo/1.0
    if PosEx('/RpmpQuery',aUrlPath) > 0 then
    begin
      if PosEx('/QueryData',aUrlPath) > 0 then
      begin
        {$REGION '������ͨ��ҵ��josn��������·�ɷ���'}
        AppTaskNo := RecvJson.ItemByName('tasktype').AsString;
        case StrToInt(AppTaskNo) of
          100:
          Begin
            {$REGION 'ƻ��ҵ��'}
            AppTaskUserNo := RecvJson.ItemByName('taskuser').AsString;
            case StrToInt(AppTaskUserNo)of
              100101:
              Begin
                {$REGION '�����ͻ�'}
                ACtrl := PluginsManager.ByPath(PWideChar('Services/'+AppTaskNo+'/'+AppTaskUserNo)) as IRemoteSQL;
                if  Assigned(ACtrl) then
                begin
                  Result := ACtrl.RecvDataGeneralControl(aUrlPath,aRecvStr,Error);
                end
                else
                begin
                  aQjson.Clear;
                  aQjson.Add('message','error',jdtString);
                  vData := 'ҵ�����쳣,δ���ҵ�ҵ����ģ��';
                  vStr := '1'+vData;
                  aQjson.Add('perjmcode','',jdtString);
                  aQjson.Add('resultdata','1',jdtString);
                  aQjson.Add('data',vData,jdtString) ;
                  Error := aQjson.ToString;
                  result := aQjson.ToString;
                end;
                {$ENDREGION}
              end;
              100102:
              Begin
                {$REGION '�Ϻ��ͻ�'}
                ACtrl := PluginsManager.ByPath(PWideChar('Services/'+AppTaskNo+'/'+AppTaskUserNo)) as IRemoteSQL;
                if  Assigned(ACtrl) then
                begin
                  Result := ACtrl.RecvDataGeneralControl(aUrlPath,aRecvStr,Error);
                end
                else
                begin
                  aQjson.Clear;
                  aQjson.Add('message','error',jdtString);
                  vData := 'ҵ�����쳣,δ���ҵ�ҵ����ģ��';
                  vStr := '1'+vData;
                  aQjson.Add('perjmcode','',jdtString);
                  aQjson.Add('resultdata','1',jdtString);
                  aQjson.Add('data',vData,jdtString) ;
                  Error := aQjson.ToString;
                  result := aQjson.ToString;
                end;
                {$ENDREGION}
              end;
            else
            begin
              aQjson.Clear;
              aQjson.Add('message','error',jdtString);
              vData := '��ҵ���벻����';
              vStr := '1'+vData;
              aQjson.Add('perjmcode','',jdtString);
              aQjson.Add('resultdata','1',jdtString);
              aQjson.Add('data',vData,jdtString) ;
              Error := aQjson.ToString;
              result := aQjson.ToString;
            end;
            end
            {$ENDREGION}
          end;
          200:
          Begin
            {$REGION '�㽶ҵ��'}
            AppTaskUserNo := RecvJson.ItemByName('taskuser').AsString;
            case StrToInt(AppTaskUserNo)of
              200101:
              Begin
                {$REGION '����'}
                ACtrl := PluginsManager.ByPath(PWideChar('Services/'+AppTaskNo+'/'+AppTaskUserNo)) as IRemoteSQL;
                if  Assigned(ACtrl) then
                begin
                  Result := ACtrl.RecvDataGeneralControl(aUrlPath,aRecvStr,Error);
                end
                else
                begin
                  aQjson.Clear;
                  aQjson.Add('message','error',jdtString);
                  vData := 'ҵ�����쳣,δ���ҵ�ҵ����ģ��';
                  vStr := '1'+vData;
                  aQjson.Add('perjmcode','',jdtString);
                  aQjson.Add('resultdata','1',jdtString);
                  aQjson.Add('data',vData,jdtString) ;
                  Error := aQjson.ToString;
                  result := aQjson.ToString;
                end;
                {$ENDREGION}
              end;
              200102:
              Begin
                {$REGION '�Ϻ�'}
                ACtrl := PluginsManager.ByPath(PWideChar('Services/'+AppTaskNo+'/'+AppTaskUserNo)) as IRemoteSQL;
                if  Assigned(ACtrl) then
                begin
                  Result := ACtrl.RecvDataGeneralControl(aUrlPath,aRecvStr,Error);
                end
                else
                begin
                  aQjson.Clear;
                  aQjson.Add('message','error',jdtString);
                  vData := 'ҵ�����쳣,δ���ҵ�ҵ����ģ��';
                  vStr := '1'+vData;
                  aQjson.Add('perjmcode','',jdtString);
                  aQjson.Add('resultdata','1',jdtString);
                  aQjson.Add('data',vData,jdtString) ;
                  Error := aQjson.ToString;
                  result := aQjson.ToString;
                end;
                {$ENDREGION}
              end;
            else
            begin
              aQjson.Clear;
              aQjson.Add('message','error',jdtString);
              vData := '��ҵ���벻����';
              vStr := '1'+vData;
              aQjson.Add('perjmcode','',jdtString);
              aQjson.Add('resultdata','1',jdtString);
              aQjson.Add('data',vData,jdtString) ;
              Error := aQjson.ToString;
              result := aQjson.ToString;
            end;
            end
            {$ENDREGION}
          end;
        else
        begin
          aQjson.Clear;
          aQjson.Add('message','error',jdtString);
          vData := '��ҵ���벻����';
          vStr := '1'+vData;
          aQjson.Add('perjmcode','',jdtString);
          aQjson.Add('resultdata','1',jdtString);
          aQjson.Add('data',vData,jdtString) ;
          Error := aQjson.ToString;
          result := aQjson.ToString;
        end;
        end;
        {$ENDREGION}
      end
    end;
  except
    on e: Exception do
    begin
      aQjson.Clear;
      aQjson.Add('message','error',jdtString);
      vData := 'δ֪����,������Ϣ: '+e.Message;
      vStr := '1'+vData;
      aQjson.Add('perjmcode','',jdtString);
      aQjson.Add('resultdata','1',jdtString);
      aQjson.Add('data',vData,jdtString) ;
      Error := aQjson.ToString;
      result := aQjson.ToString;
    end;
  end;
end;

initialization
// ע�� /Services/PubRouteProxys/PubRouteProxy ����
RegisterServices('Services/PubRouteProxys',
  [TPubRouteProxy.Create(NewId, 'PubRouteProxy')]);
finalization
// ȡ������ע��
UnregisterServices('Services/PubRouteProxys', ['PubRouteProxy']);
end.
