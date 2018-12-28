//����ԪMSConnection�����ӳ�
//by FLM
unit Intf_MsConnectionPool;

interface
uses
  Classes, SysUtils, SyncObjs,
  DateUtils,FireDAC.Comp.Client;
type
   //�Զ���������
    TPoolConnectionClass = class of TPoolConnection;
    TMSCustomConnectionPool = class;
    TExceptionEvent = procedure (Sender: TObject; E: Exception) of object;

  //��������
  TPoolConnection = class(TCollectionItem)
  private
    FBusy: Boolean;
    FConnection: TFDConnection;
    FbConnect:Boolean;
  protected
    procedure Lock; virtual;
    procedure Unlock; virtual;
    function Connected: Boolean; virtual;
    function CreateConnection: TFDConnection; virtual; abstract;
  public
    property Busy: Boolean read FBusy;
    property Connection: TFDConnection read FConnection;
    property ConnectOK: Boolean read FbConnect; 
    constructor Create(aCollection: TCollection); override;
    destructor Destroy; override;
  end;

  //�������ӳ�����
  TPoolConnections = class(TOwnedCollection)
  private
    function GetItem(aIndex: Integer): TPoolConnection;
    procedure SetItem(aIndex: Integer; const Value: TPoolConnection);
  public
    property Items[aIndex: LongInt]: TPoolConnection read GetItem write SetItem; default;
    function Add: TPoolConnection;
  {$IFNDEF VER140}
    function Owner: TPersistent;
  {$ENDIF}
  end;

    TMsCustomConnectionPool = class(TComponent)
  private
    FCS: TCriticalSection;
    FProviderName:String;
    FServerIP:String;
    FPort:Integer;
    FLoginPrompt:Boolean;
    FuserName:String;
    FPassword:String;
    FConnections: TPoolConnections;
    FMaxConnections: LongInt;
    FIniCount:LongInt;
    FOnLockConnection: TNotifyEvent;
    FOnLockFail: TExceptionEvent;
    FOnUnLockConnection: TNotifyEvent;
    FOnCreateConnection: TNotifyEvent;
    FOnFreeConnection: TNotifyEvent;
    function GetUnusedConnections: LongInt;
    function GetTotalConnections: LongInt;
  protected
    function GetPoolItemClass: TPoolConnectionClass; virtual; abstract;
    procedure DoLock; virtual;
    procedure DoLockFail(E: Exception); virtual;
    procedure DoUnlock; virtual;
    procedure DoCreateConnection; virtual;
    procedure DoFreeConnection; virtual;
  public
    constructor Create(aOwner: TComponent); override;
    destructor Destroy; override;


    procedure AssignTo(Dest: TPersistent); override;

   //���õ�����������
    property MaxConnections: LongInt read FMaxConnections write FMaxConnections default -1;
    
    //���ó�ʼ�����ӳ���
    property zIniCount: LongInt read FIniCount write FIniCount default 0;
   //�ӳ��л�ȡδ����������
    function GetConnection: TFDConnection;
   //���ӳ��ͷ�
    procedure FreeConnection(aConnection: TFDConnection);
   //���س���δʹ�õ�������
    property UnusedConnections: LongInt read GetUnusedConnections;

   //��ȡ�ܹ����ӳ�
    property TotalConnections: LongInt read GetTotalConnections;
   //�����ӳ�
    property OnLockConnection: TNotifyEvent read FOnLockConnection write FOnLockConnection;
   //�������ӳ�
    property OnUnlockConnection: TNotifyEvent read FOnUnlockConnection write FOnUnlockConnection;

  //�����µ����ӳ�
    property OnCreateConnection: TNotifyEvent read FOnCreateConnection write FOnCreateConnection;
  //�����ӳ�ʧ��
    property OnLockFail: TExceptionEvent read FOnLockFail write FOnLockFail;
  //�ͷ����ӳ�
    property OnFreeConnection: TNotifyEvent read FOnFreeConnection write FOnFreeConnection;
  end;




implementation

{$IFDEF TRIAL}
uses
  Windows;
{$ENDIF}


{ TPoolConnection }
{- protected ----------------------------------------------------------------- }
procedure TPoolConnection.Lock;
begin
  FBusy:= true;
  if not Connected then
  begin
    Connection.Open;
  end;
  TMsCustomConnectionPool(TPoolConnections(Collection).Owner).DoLock;
end;

procedure TPoolConnection.Unlock;
begin
  FBusy:= false;
  TMsCustomConnectionPool(TPoolConnections(Collection).Owner).DoUnLock;
end;

function TPoolConnection.Connected: Boolean;
begin
  Result:= Connection.Connected;
end;

{ - public ------------------------------------------------------------------- }
constructor TPoolConnection.Create(aCollection: TCollection);
begin
  inherited;
  FConnection:= CreateConnection;
  TMsCustomConnectionPool(TPoolConnections(Collection).Owner).DoCreateConnection;
end;

destructor TPoolConnection.Destroy;
begin
  if Busy then Unlock;
  FreeAndNil(FConnection);
  TMsCustomConnectionPool(TPoolConnections(Collection).Owner).DoFreeConnection;
  inherited;
end;

{ TPoolConnections }
{ - private ------------------------------------------------------------------ }
function TPoolConnections.GetItem(aIndex: Integer): TPoolConnection;
begin
  Result:= inherited GetItem(aIndex) as TPoolConnection;
end;

procedure TPoolConnections.SetItem(aIndex: Integer;
  const Value: TPoolConnection);
begin
  inherited SetItem(aIndex, Value);
end;

{ - public ------------------------------------------------------------------- }
function TPoolConnections.Add: TPoolConnection;
begin
  Result:= inherited Add as TPoolConnection;
end;

{$IFNDEF VER140}
function TPoolConnections.Owner: TPersistent;
begin
  Result:= GetOwner;
end;
{$ENDIF}

{ TCustomConnectionPool }
{ - private ------------------------------------------------------------------ }
function TMsCustomConnectionPool.GetUnusedConnections: LongInt;
var
  I: LongInt;
begin
  FCS.Enter;
  Result:= 0;
  try
    for I:= 0 to FConnections.Count - 1 do
      if not FConnections[I].Busy then
        Inc(Result);
  finally
    FCS.Leave;
  end;
end;

function TMsCustomConnectionPool.GetTotalConnections: LongInt;
begin
  Result:= FConnections.Count;
end;

{ - public ------------------------------------------------------------------- }
constructor TMsCustomConnectionPool.Create(aOwner: TComponent);
begin
  inherited;
  FCS:= TCriticalSection.Create;
  //FCS.SetLockName('FCS');
  FConnections:= TPoolConnections.Create(Self, GetPoolItemClass);
  FMaxConnections:= -1;
end;

destructor TMsCustomConnectionPool.Destroy;
begin
  FCS.Enter;
  try
      FConnections.Free;
  finally
    FCS.Leave;
  end;
  FreeAndNil(FCS);
  inherited;
end;

procedure TMsCustomConnectionPool.AssignTo(Dest: TPersistent);
begin
  if Dest is TMsCustomConnectionPool then
    TMsCustomConnectionPool(Dest).MaxConnections:= MaxConnections 
  else
    inherited AssignTo(Dest);
end;


function TMsCustomConnectionPool.GetConnection:TFDConnection;
var
  I: LongInt;
begin
  Result:= nil;
  FCS.Enter;  //??
  try
    try
    //Ԥ�Ȳ������ٸ��̳߳�
//      if FConnections.Count<FIniCount then
//      begin
//        for i := 0 to FIniCount-1 do
//        begin
//          FConnections.Add;
//        end;
//      end;
      I:= 0;
      while I < FConnections.Count do   //��ȡ��������
      begin
        if not FConnections[I].Busy then   //����ǿ��е�����
        begin
          Result:= FConnections[I].Connection;  //��ȡ������
          try
            FConnections[I].Lock;           //����������
            Break;
          except
            FConnections.Delete(I);   //�쳣�Ļ�,ɾ���˽���
            Continue;
          end;
        end;
        Inc(I);   //������1 
      end;

      if Result = nil then  //�������ûƥ�䵽
        if ((FConnections.Count < MaxConnections) or (MaxConnections = -1))
{$IFDEF TRIAL}
          and ((FindWindow('TAppBuilder', nil) <> 0) or (FConnections.Count  < MaxConnections))
{$ENDIF}
        then
        begin
          with FConnections.Add do      //����һ���µ�����
          begin
            Result:= Connection;
            Lock;
          end;
        end
        else   //���ӳس�������,�׳��쳣
          raise Exception.Create('����������������ӳ���.');
    except
      On E: Exception do
        DoLockFail(E);
    end;
  finally
    FCS.Leave;   //??
  end;
end;

procedure TMsCustomConnectionPool.FreeConnection(aConnection: TFDConnection);
var
  I: LongInt;
begin
  FCS.Enter;
  try
    for I:= 0 to FConnections.Count - 1 do
      if FConnections[I].Connection = aConnection then
      begin
        FConnections[I].Unlock;
        Break;
      end;
  finally
    FCS.Leave;
  end;
end;


procedure TMsCustomConnectionPool.DoLock;
begin
  if Assigned(FOnLockConnection) then
    FOnLockConnection(Self);
end;

procedure TMsCustomConnectionPool.DoUnlock;
begin
  if Assigned(FOnUnLockConnection) then
    FOnUnLockConnection(Self);
end;

procedure TMsCustomConnectionPool.DoCreateConnection;
begin
  if Assigned(FOnCreateConnection) then
    FOnCreateConnection(Self);
end;

procedure TMsCustomConnectionPool.DoLockFail(E: Exception);
begin
  if Assigned(FOnLockFail) then
    FOnLockFail(Self, E);
end;

procedure TMsCustomConnectionPool.DoFreeConnection;
begin
  if Assigned(FOnFreeConnection) then
    FOnFreeConnection(Self);
end;
end.
