unit Gl_ServerConst;
interface
Const
    SystemSetFileName  = 'SystemConfig.ini';
   //������Ϣ
type
  //���ݿ�ṹ
  TDatabaseParam = record
    ServerName: string;
    UserNmae: string;
    PassName: string;
    DatebaseName: string;
  end;
  TOnConnectEvent  = procedure (CIDStr,IPStr,LoginTimeStr,PortStr : string) of object;
  TConnectInfo=class(TObject)
  public
   ConnetString:string;
  end;
  //��������Ϣ
  TDataSnapServerInfo=class(TObject)
  public
   OnAddConnectEvent: TOnConnectEvent; //�����¼�
   OnDeleteConnectEvent: TOnConnectEvent; //�����¼�
   TcpServerIP: string;        //��������ַ(Tcp)
   TcpPort:Integer;            //����˶˿�(Tcp)
   HttpServerIP: string;       //��������ַ(Http)
   HttpPort: Integer;          //����˶˿�(Http)
   bActive:Boolean;            //������
   ConnectionCount:Integer;    //���ݿ����ӳ���
   ConnectCount:Integer;       //��������������
   iFactoryMode:Integer;       //����˷���ģʽ
   DriverName:string;          //���ݿ�����
   ADOConnetStr:String;        //���ݿ������ַ���
   DatabaseParam: TDatabaseParam; //���ݿ����Ӳ���
   bLoginOnly:Boolean;         //ͬһ�û������ظ���½
   bsetOK:Boolean;             //�����޴�
   ConnLoginUser: string;      //���ӷ��������û���
   ConnLoginPassword: string;  //���ӷ�����������
end;
var
  VAR_ProgramPath:String;
  FLogFilePath: string;
  VAR_SQLDBCount:Integer;
  Var_ConnectInfo:TConnectInfo;
  Var_ServerInfo:TDataSnapServerInfo;
implementation

end.

