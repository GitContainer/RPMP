{
���ܣ������ӿڵ�Ԫ
@author: zhyhui
@date:  2018-12-07
}
unit uRouteProxyFunc;

interface
uses
  Winapi.Windows, Winapi.Messages,System.SysUtils, System.Variants,System.Classes,SynCommons;
type
  IRouteProxy = interface
    ['{CB30EDE0-6FDF-4E0E-B520-88AE9374D1C1}']
    //ҵ��У��������ȷ���
    function CheckWorkData(aRecvStr: AnsiString; var Error: string): Boolean; stdcall;
    //ҵ��·�ɷ���
    function RouteWorkData(aRecvStr: AnsiString; var Error: string): RawJSON; overload; stdcall;
    //ҵ��·�ɷ���
    function RouteWorkData(aUrlPath,aRecvStr: AnsiString; var Error: string): RawJSON; overload; stdcall;
  end;
implementation

end.
