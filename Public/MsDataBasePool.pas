{���ӳ���,���Գ�ʼ��������ӳ�,ÿ���ص������ַ�����һ��,�ﵽ����Ч��}
unit MsDataBasePool;
interface
uses
  SysUtils,FireDAC.Comp.Client,
  Intf_MsConnectionPool,Impl_MsConnectionPool;
type
  TDataBasePool = Class
  private
    MSConnectionPool: TMsConnectionPool;
  public
    constructor Create(iType:Integer;iCount:Integer);
    destructor Destroy; override;
    function GetConnectionDB:TFDConnection;
    procedure FreeConnectionDB(QConnection:TFDConnection);
  end;

implementation
uses GL_ServerConst,GL_ServerFunction;
constructor TDataBasePool.Create(iType:Integer;iCount:Integer);
var i:Integer;
begin
  inherited Create;
    MSConnectionPool := TMSConnectionPool.Create(nil,iCount);
    MSConnectionPool.ConnectString := VAR_ArrSQLConStr[iType];
end;

destructor TDataBasePool.Destroy;
begin
  FreeAndNil(MSConnectionPool);
  inherited Destroy;
end;
function TDataBasePool.GetConnectionDB:TFDConnection;
begin
  Result := MsConnectionPool.GetConnection;
end;
procedure TDataBasePool.FreeConnectionDB(QConnection:TFDConnection);
begin
  MsConnectionPool.FreeConnection(QConnection);
end;

end.
