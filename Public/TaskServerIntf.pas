{
���ܣ���ҵ�ʸ�ҵ��ӿڵ�Ԫ
author : zhyhui
date: 2018-12-08
}
unit TaskServerIntf;

interface
  uses SynCommons,mORMot;
type
  IRemoteSQL = interface(IInvokable)
   ['{051C8EC8-921D-4248-88E8-489E3B869F50}']
    //���������ܴ���
    function RecvDataGeneralControl(aUrlPath,aRecvStr: AnsiString; var Error: string): RawJSON;
    //У��������ȷ���
    function CheckRecvData(aRecvStr: AnsiString; var Error: string): Boolean;
    //��¼��֤
    function Login(aRecvStr: AnsiString; var Error: string): RawJSON;
  end;
implementation

end.
