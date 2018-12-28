unit uServerMain;

interface

uses Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.DateUtils,  System.ImageList, System.Classes,System.IniFiles,
  Vcl.ExtCtrls, Vcl.Dialogs,Vcl.ComCtrls, Vcl.Grids, Vcl.StdCtrls,Vcl.Imaging.pngimage,
  Vcl.ImgList, Vcl.Controls, Vcl.AppEvnts, Vcl.Menus,Vcl.Graphics, Vcl.Forms,
  PubConst,EDDES,GL_ServerFunction,GL_ServerConst,uPubHttpServer,
  QPlugins, QPlugins_loader_lib,QPlugins_Vcl_Messages;
  {$I SynDprUses.inc} // use FastMM4 on older Delphi, or set FPC threads

type
  TfrmServerMain = class(TForm)
    pnlTop: TPanel;
    Bevel2: TBevel;
    lblPrompt: TLabel;
    lblTitle: TLabel;
    lblVer: TLabel;
    lblOsInfo: TLabel;
    imgLog1: TImage;
    PageControl1: TPageControl;
    MainMenu1: TMainMenu;
    pmConnectSet: TMenuItem;
    pmiConnection: TMenuItem;
    N8: TMenuItem;
    pmRoServerSet: TMenuItem;
    pmRoServerStart: TMenuItem;
    pmRoServerStop: TMenuItem;
    N1: TMenuItem;
    statuBar: TStatusBar;
    TrayIcon1: TTrayIcon;
    ApplicationEvents1: TApplicationEvents;
    ilTrayIcon: TImageList;
    tmrStatus: TTimer;
    TabSheet5: TTabSheet;
    MmoLog: TMemo;
    N2: TMenuItem;
    N6: TMenuItem;
    N7: TMenuItem;
    TimerDelLog: TTimer;
    N_Exectetype: TMenuItem;
    tmr_AutoRun: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure pmRoServerStartClick(Sender: TObject);
    procedure pmRoServerStopClick(Sender: TObject);
    procedure tmrStatusTimer(Sender: TObject);
    procedure N8Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure ApplicationEvents1Minimize(Sender: TObject);
    procedure TrayIcon1DblClick(Sender: TObject);
    procedure TimerDelLogTimer(Sender: TObject);
    procedure N_ExectetypeClick(Sender: TObject);
    procedure tmr_AutoRunTimer(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    IsStared: Boolean;
    g_AutoRun: Byte;                  //�Զ����б�ʾ  0 �Զ����� 1 �ֶ�����
    { Private declarations }
  public
    SoftStartDateTime: TDateTime;              //�������ʱ��
    { Public declarations }
    //��־��ʾ
    procedure ShowMsgText(S: string);
    //״̬lan
    procedure ShowStausBarMsgText(S: string;index: Integer);
    Procedure ReadIniFile;
    //ֹͣ����״̬
    procedure StopListen;
    //��������״̬
    procedure StartListen;
    //���ز��
    procedure LoadPluginModule;
  end;

var
  frmServerMain: TfrmServerMain;
  aRestServer: TPubRestServer;
implementation

{$R *.dfm}

uses uServerSet;
procedure TfrmServerMain.LoadPluginModule;
var
  APath: String;
begin
  ReportMemoryLeaksOnShutdown := True;
  APath := ExtractFilePath(Application.ExeName);
  // ע��Ĭ�ϵ� DLL ����������չ�����Ը���ʵ�ʵ���������޸ģ������չ��֮���ö��Ż�ֺŷָ�
  PluginsManager.Loaders.Add(TQDLLLoader.Create(APath, '.dll'));
  // �������ע�ᣬ���Ҫ��ʾ���ؽ��ȣ�����ע��IQNotify��Ӧ������Ӧ����֪ͨ
  PluginsManager.Start;
end;

procedure TfrmServerMain.ShowMsgText(S: string);
begin
  if MmoLog.Lines.Count > 1000 then
  begin
    MmoLog.Lines.Clear;
  end;
  MmoLog.Lines.Add(FormatDateTime('YYYY-MM-DD HH:NN:SS',now)+' '+S);
end;
procedure TfrmServerMain.ShowStausBarMsgText(S: string;index: Integer);
begin
  statuBar.Panels[index].Text := S;
end;

procedure TfrmServerMain.ApplicationEvents1Minimize(Sender: TObject);
begin
  ShowWindow(self.Handle, SW_HIDE); //����������
end;

Procedure TfrmServerMain.ReadIniFile;
var
  ConfigIni: TIniFile;
  sport:String;
begin
  try
    ConfigIni := TIniFile.Create(VAR_ProgramPath+SystemSetFileName); //��ȡIni
    try
      ///���÷��������з�ʽ
      g_AutoRun  := StrToInt(ConfigIni.ReadString('AutoExecte', 'AutoRun', '1'));
      if g_AutoRun = 0 then N_Exectetype.Checked := True;
      if g_AutoRun = 1 then N_Exectetype.Checked := False;
      sPort := ConfigIni.readstring('ServerSet','TcpPort','211');
      Var_ServerInfo.TcpPort := StrToInt(sPort);
      sPort := ConfigIni.readstring('ServerSet','HttpPort','8080');
      Var_ServerInfo.HttpPort := StrToInt(sPort);
      Var_ServerInfo.bsetOK := True;
    except
    end;
  finally
    FreeAndNil(ConfigIni);
  end;
end;
procedure TfrmServerMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if  IsStared then StopListen;
  FreeAndNil(Var_ServerInfo);
end;

procedure TfrmServerMain.FormCreate(Sender: TObject);
var
  I: Integer;
begin
  //�������г�ʼ��һЩ��Ϣ
  VAR_ProgramPath := ExtractFilePath(Application.ExeName);       //����·����ȡ
  lblVer.Caption := 'v' + GetFileVersionStr(Application.ExeName);
  lblOsInfo.Caption := TOSVersion.ToString;
  lblPrompt.Caption := GetProcessorVersion + ',' + GetPhysicsMemoryTotalSize + 'GB RAM';
  //����������Ϣ��
  Var_ServerInfo :=TDataSnapServerInfo.Create;
  //��ȡ��������
  ReadIniFile;
  //���ز��
  LoadPluginModule;
end;
procedure TfrmServerMain.FormShow(Sender: TObject);
begin
  tmr_AutoRun.Enabled := True;
end;

procedure TfrmServerMain.N_ExectetypeClick(Sender: TObject);
var
  MIni: TIniFile;
begin
  try
    MIni := TIniFile.Create(VAR_ProgramPath+SystemSetFileName);
    if not N_Exectetype.Checked then
    begin
      MIni.WriteString('AutoExecte','AutoRun','0');
      g_AutoRun := 0;
      N_Exectetype.Checked := True;
    end
    else
    begin
      MIni.WriteString('AutoExecte','AutoRun','1');
      g_AutoRun := 1;
      N_Exectetype.Checked := False;
    end;
  finally
    MIni.Free;
  end;
end;

procedure TfrmServerMain.N8Click(Sender: TObject);
begin
  if IsStared then
  begin
    Application.MessageBox('��������������,���ܲ���','��ʾ',MB_OK+MB_ICONINFORMATION);
    Exit;
  end;
  Application.CreateForm(TfrmServerSet,frmServerSet);
  if frmServerSet.ShowModal = mrOk then
  begin
    ReadIniFile;
  end;
end;

procedure TfrmServerMain.pmRoServerStartClick(Sender: TObject);
begin
  StartListen;
end;

procedure TfrmServerMain.pmRoServerStopClick(Sender: TObject);
begin
  StopListen;
end;

procedure TfrmServerMain.StartListen;
begin
  tmr_AutoRun.Enabled := False;
  SoftStartDateTime := Now;
  if not DirectoryExists(ExtractFilePath(Application.ExeName)+'\Log') then
  begin
    ForceDirectories(ExtractFilePath(Application.ExeName)+'\Log');
  end;
  FLogFilePath := ExtractFilePath(Application.ExeName)+'\Log\';
  aRestServer := TPubRestServer.Create(ExtractFilePath(Application.ExeName),IntToStr(Var_ServerInfo.HttpPort));
  ShowStausBarMsgText(DateTimeToStr(Now),1);
  tmrStatus.Enabled :=True;
  TrayIcon1.Hint := Self.Caption;
  IsStared := True;
  pmRoServerStart.Enabled := False;
  pmRoServerStop.Enabled := True;
  TimerDelLog.Enabled := True;
  ShowMsgText('������������ɹ���');
end;
procedure TfrmServerMain.StopListen;
begin
  FreeAndNil(aRestServer);
  tmrStatus.Enabled :=False;
  TimerDelLog.Enabled := False;
  TrayIcon1.IconIndex := 0;
  TrayIcon1.Hint := Self.Caption;
  IsStared := False;
  pmRoServerStart.Enabled := True;
  pmRoServerStop.Enabled := False;
  ShowMsgText('��������Ѿ��رգ�');
end;
procedure TfrmServerMain.TimerDelLogTimer(Sender: TObject);
begin
  try
    TimerDelLog.Enabled := False;
    TPubMtdCmd.DeleteLogDirc(ExtractFilePath(Application.ExeName)+'Log\',30);
  finally
    TimerDelLog.Enabled := True
  end;
end;

procedure TfrmServerMain.tmrStatusTimer(Sender: TObject);
var
  TimeStamp ,TSNow: TTimeStamp;
  timeDiff : Int64;
begin
  // ����ʱ�����
  ShowStausBarMsgText(TPubMtdCmd.GetRunTimeINfo(SoftStartDateTime),3);
  //��������ʾ
  ShowStausBarMsgText('Get:'+IntToStr(aRestServer.GetRequestCount)+' Post:'+IntToStr(aRestServer.PostRequestCount),5);
end;

procedure TfrmServerMain.tmr_AutoRunTimer(Sender: TObject);
begin
  try
    tmr_AutoRun.Enabled := False;
    if (not IsStared) and (g_AutoRun = 0) then
    begin
      pmRoServerStart.OnClick(Sender);
    end;
  Except
  end;
end;

procedure TfrmServerMain.TrayIcon1DblClick(Sender: TObject);
begin
  ShowWindow(self.Handle,SW_SHOW);
  Self.WindowState := wsNormal;
end;

end.

