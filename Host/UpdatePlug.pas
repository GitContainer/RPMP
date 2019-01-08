unit UpdatePlug;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, qplugins,qplugins_base,qplugins_params,
  qplugins_loader_lib, Vcl.ComCtrls, qplugins_formsvc,qplugins_vcl_formsvc, Vcl.Buttons,IOUtils;

type
  TfrmUpdatePlug = class(TForm, IQNotify)
    Panel1: TPanel;
    Button2: TButton;
    mmLogs: TMemo;
    dlgOpen: TOpenDialog;
    edtPluginsFile: TEdit;
    SpeedButton1: TSpeedButton;
    Label1: TLabel;
    Label2: TLabel;
    edtRouter: TEdit;
    procedure Button2Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
  private
    { Private declarations }
  public
    FHoldService: IQService;
    procedure Notify(const AId: Cardinal; AParams: IQParams;
      var AFireNext: Boolean); stdcall;
    /// <summary>
    /// ����·��·��ж����Ӧ���
    /// </summary>
    /// <param name="RoutePath">
    /// ����·�����м���/�ָ��������ִ�Сд
    /// </param>
    /// <returns>
    /// ����ж���Ƿ�ɹ�  true ж�سɹ� false ж��ʧ��
    /// </returns>
    function UnLoadPlug(RoutePath: string): Boolean;
    /// <summary>
    /// ���ز��
    /// </summary>
    /// <param name="AFileName">
    /// ����ļ�·��
    ///</param>
    /// <returns>
    /// ��
    ///</returns>
    procedure LoadPlug(AFileName: string);
    procedure EnumFileServices(const AFileName: String);
    { Public declarations }
  end;

var
  frmUpdatePlug: TfrmUpdatePlug;

implementation

{$R *.dfm}
procedure TfrmUpdatePlug.EnumFileServices(const AFileName: String);
var
  AInst: HINST;
  procedure EnumServices(AService: IQService);
  var
    AList: IQServices;
    I: Integer;
  begin
    if Supports(AService, IQServices, AList) then
    begin
      for I := 0 to AList.Count - 1 do
        EnumServices(AList.Items[I]);
    end
    else
    begin
      if AService.GetOwnerInstance = AInst then
        mmLogs.Lines.Add(ServicePath(AService));
    end;
  end;

begin
  AInst := GetModuleHandle(PChar(AFileName));
  mmLogs.Lines.Add(AFileName + ' ע��ķ���(��ַ:' + IntToHex(AInst, 8) + ')');
  EnumServices(PluginsManager as IQService);
end;
procedure TfrmUpdatePlug.LoadPlug(AFileName: string);
var
  ALoader: IQLoader;
begin
  if FileExists(AFileName) then
  begin
    ALoader := PluginsManager.ByPath('/Loaders/Loader_DLL') as IQLoader;
    if Assigned(ALoader) then
      ALoader.LoadServices(PWideChar(AFileName));
  end;
end;
function TfrmUpdatePlug.UnLoadPlug(RoutePath: string): Boolean;
var
  AModule: HMODULE;
  ALoader: IQLoader;
  FPlugService: IQService;
  function ServiceModule(FService: IQService): HMODULE;
  begin
    if Assigned(FService) then
      Result := FService.GetOwnerInstance
    else
      Result := 0;
  end;
begin
  Result := False;
  //����·��·�������Ѽ��ط���
  FPlugService := PluginsManager.ByPath(PWideChar(RoutePath));
  if Assigned(FPlugService) then
  begin
    //��ȡ�Ѽ��ط�����
    AModule := ServiceModule(FPlugService);
    if AModule <> 0 then
    begin
      //��ȡ������
      ALoader := PluginsManager.ByPath('/Loaders/Loader_DLL') as IQLoader;
      if Assigned(ALoader) then
      begin
        //ж�ز��
        Result := ALoader.UnloadServices(AModule);
      end;
    end;
  end;
end;
procedure TfrmUpdatePlug.Button2Click(Sender: TObject);
var
  FFileName: String;
begin
  if Trim(edtPluginsFile.Text) = '' then
  begin
    mmLogs.Lines.Add('��ѡ����...');
    Exit;
  end;
  if Trim(edtRouter.Text) = '' then
  begin
    mmLogs.Lines.Add('����д���·��·��...');
    Exit;
  end;
  //ж�ز��
  if UnLoadPlug(Trim(edtRouter.Text)) then
  begin
    //�����滻
    FFileName := ExtractFilePath(Application.ExeName)+ExtractFileName(Trim(edtPluginsFile.Text));
    CopyFile(PChar(Trim(edtPluginsFile.Text)),PChar(FFileName), False);
    //���¼���
    LoadPlug(FFileName);
    mmLogs.Lines.Add('������³ɹ�...');
  end
  else
  begin
    mmLogs.Lines.Add('ж�ز��ʧ��...');
    Exit;
  end;
end;

procedure TfrmUpdatePlug.FormCreate(Sender: TObject);
begin
  with PluginsManager as IQNotifyManager do
  begin
    Subscribe(NID_PLUGIN_LOADING, Self);
    Subscribe(NID_PLUGIN_UNLOADING, Self);
    Subscribe(NID_PLUGIN_LOADED, Self);
  end;
end;

procedure TfrmUpdatePlug.FormDestroy(Sender: TObject);
begin
  with PluginsManager as IQNotifyManager do
  begin
    Unsubscribe(NID_PLUGIN_LOADING, Self);
    Unsubscribe(NID_PLUGIN_UNLOADING, Self);
    Unsubscribe(NID_PLUGIN_LOADED, Self);
  end;
end;
procedure TfrmUpdatePlug.Notify(const AId: Cardinal; AParams: IQParams;
  var AFireNext: Boolean);
var
  AParam: IQParam;
begin
 { if Assigned(AParams) then
  begin
    case AId of
      NID_PLUGIN_LOADING:
        begin
          AParam := AParams.ByName('File');
          mmLogs.Lines.Add('���ڼ��ز�� ' + ParamAsString(AParam) + ' ...');
        end;
      NID_PLUGIN_LOADED:
        begin
          FHoldService := PluginsManager.ByPath(PWideChar(Trim(edtRouter.Text)));
          if Assigned(FHoldService) then
            mmLogs.Lines.Add('HoldService �Ѿ��ɹ�����');
        end;
      NID_PLUGIN_UNLOADING:
        begin
          AParam := AParams.ByName('Instance');
          if Assigned(AParam) and
            (FHoldService.GetOwnerInstance = AParam.AsInt64) then
          begin
            FHoldService := nil;
            AParam := AParams.ByName('File');
            mmLogs.Lines.Add('����ж�ز��' + ParamAsString(AParam) + '���Ƴ��������� ...');
          end;
        end;
    end;
  end;     }
end;
procedure TfrmUpdatePlug.SpeedButton1Click(Sender: TObject);
begin
  if dlgOpen.Execute then
  begin
    edtPluginsFile.Text := dlgOpen.FileName;
  end;
  EnumFileServices(dlgOpen.FileName);
end;

end.
