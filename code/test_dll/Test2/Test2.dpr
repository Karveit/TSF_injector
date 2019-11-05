library Test2;

{ Important note about DLL memory management: ShareMem must be the
  first unit in your library's USES clause AND your project's (select
  Project-View Source) USES clause if your DLL exports any procedures or
  functions that pass strings as parameters or function results. This
  applies to all strings passed to and from your DLL--even those that
  are nested in records and classes. ShareMem is the interface unit to
  the BORLNDMM.DLL shared memory manager, which must be deployed along
  with your DLL. To avoid using BORLNDMM.DLL, pass string information
  using PChar or ShortString parameters. }

uses
  System.SysUtils,
  System.Classes,
  Winapi.Windows,
  Winapi.Messages,
  System.DateUtils,
  Vcl.Dialogs,
  Vcl.StdCtrls,
  Vcl.Controls,
  Vcl.Forms,
  Unit1 in 'Unit1.pas' {Form1},
  HookUtils in 'HookSource\HookUtils.pas';

//�ر���־��ʾ
{$DEFINE OFFLOG}

{$R *.res}
type
  TMainWindow = packed record
    ProcessID: THandle;
    MainWindow: THandle;
  end;
  PMainWindow =^ TMainWindow;


type
   PEnumInfo = ^TEnumInfo;
   TEnumInfo = record
      ProcessID: DWORD;
      HWND: THandle;
   end;

var


P_hwd:HWND;   //Ŀ�괰�ڶ������
win_num:integer;  //ȫ���ۼ���.������ ��Ŀ��������.
  hButton    : HWND;
  hFontButton: HWND;
OldAppProc: Pointer;

//��ʱ��
timer_ptr_5:UIntPtr;
timer_ptr_4:UIntPtr;
timer_ptr_3:UIntPtr;
timer_ptr_2:UIntPtr;
timer_ptr_1:UIntPtr;
timer_ptr_0:UIntPtr;

fun_var_pid:DWORD;
fun_var_hwd:HWND;

MainHook:Uint64;


GetLocalTimeNext:procedure(var lpSystemTime: TSystemTime); stdcall;

MessageBoxNext: function (hWnd: HWND; lpText, lpCaption: PChar; uType: UINT): Integer; stdcall;





procedure writeWorkLog(sqlstr: string);
var
  filev: TextFile;
  ss: string;
begin

{$IFDEF OFFLOG}
exit;
{$ENDIF}

  sqlstr:=DateTimeToStr(Now)+' Log: '+sqlstr;

  ss:=GetEnvironmentVariable('USERPROFILE') + '\Desktop\DLLRunLog.txt';

  if FileExists(ss) then
  begin
    AssignFile(filev, ss);
    append(filev);
    writeln(filev, sqlstr);
  end else begin
    AssignFile(filev, ss);
    ReWrite(filev);
    writeln(filev, sqlstr);
  end;

  CloseFile(filev);
end;







function getparenthwd(var tmpHWND:HWND):DWORD;
var
tmp:HWND;
tmp2:HWND;
begin
    tmp2:=0;
    tmp:=GetParent(tmpHWND);


     while tmp >0 do
     begin
         tmp:=getparenthwd(tmp);
     end;
    if tmp <> 0  then tmp2:=tmp;

    Result:=tmp2;
end;


   function G_EnumWindowsProc(Wnd: HWND; var EI: TEnumInfo): Bool; stdcall;
   var
      PID: DWORD;
  h: THandle;
  arr: array[0..254] of Char;
  tmpIsFlag:Boolean;
  tmpThreadID:THandle;
   begin
      Result := True;
      GetWindowThreadProcessID(Wnd, @PID);


Result := (PID <> EI.ProcessID) or
(not IsWindowVisible(WND)) or
(not IsWindowEnabled(WND));

      if not Result then
        begin
          h := getparenthwd(WND);


          if h>0 then
          begin
            EI.HWND := h;
          end
            else
            begin
              EI.HWND := WND;
            end;
        end;



//      Result := (PID <> EI.ProcessID) or
//         (not IsWindowVisible(WND)) or
//         (not IsWindowEnabled(WND));
//      if not Result then EI.HWND := WND; //break on return FALSE
   end;

function G_FindMainWindow(PID: DWORD): DWORD;
   var
      EI: TEnumInfo;
   begin
      EI.ProcessID := PID;
      EI.HWND := 0;
      EnumWindows(@G_EnumWindowsProc, Integer(@EI));
      Result := EI.HWND;
   end;


//https://codeoncode.blogspot.com/2016/12/get-processid-by-programname-include.html
function GetHWndByPID(const hPID: THandle): THandle;
begin
   if hPID <> 0 then
      Result := G_FindMainWindow(hPID)
   else
      Result := 0;
end;




function _IsMainWindow(AHandle: HWND): BOOL;
begin
  Result :=(GetWindow(AHandle, GW_OWNER) = 0) and (IsWindowVisible(AHandle));
end;{ IsMainWindow }

function _fFindMainWindow(tmphWnd: DWORD; lParam: integer=0): BOOL; stdcall;
var
  vProcessID: DWORD;
begin
  GetWindowThreadProcessId(tmphWnd, addr(vProcessID));
  //and IsMainWindow(hWnd)

  if (fun_var_pid = vProcessID) and _IsMainWindow(tmphWnd) then
  begin
    //OutputDebugString(pwidechar('���pid: '+inttostr(fun_var_pid) + ' ö�پ��: ' + inttostr(tmphWnd)));
    fun_var_hwd := tmphWnd;
    Result := false;
  end else Result := True;
end;

//https://www.iteye.com/blog/huobengle-1382392
//�ж��Ƿ�������
//���Ҳ��֪��ԭ������˭,�ҾͿ��ö�ط�������ȥû��ԭ����.
function FindMainWindow(AProcessID: DWORD): THandle;
begin
  fun_var_pid:= AProcessID;
  fun_var_hwd:= 0 ;
  EnumWindows(@_fFindMainWindow,integer(0));
  Result := fun_var_hwd;
end;{ FindMainWindow }















//�ı�Ŀ��������
//��һ��ȫ���ۼ�����ֵ��ʾ��Ŀ�괰�ڵı�����
procedure SetWinTextTimerProc(hwnd:HWND;uMsg,idEvent:UINT;dwTime:DWORD); stdcall;
begin
    inc(win_num);
    SetWindowText(P_hwd,'��DLL�޸��˴�����--'+ inttostr(win_num));
end;

function  Change_From_Text():integer;stdcall;
begin
    timer_ptr_0:=SetTimer(P_hwd, 0, 1000, @SetWinTextTimerProc);
    Result:=0;
end;




//��HOME�����,һ����
//ͨ��GetAsyncKeyState�жϰ����Ƿ���
//������鲻�Ǻܺ�
procedure HomeFunTimerProc(hwnd:HWND;uMsg,idEvent:UINT;dwTime:DWORD); stdcall;
begin
  if GetAsyncKeyState(Vk_HOME)<> 0 then
  begin
    //KillTimer(P_hwd,2);  //���ֻ��Ҫ��Ӧһ�ξ;���Ҫ�رռ�ʱ��
    showmessage('������HOME');
  end;
end;

function  Home_KEY_FUN_1():integer;stdcall;
begin
    timer_ptr_2:= SetTimer(P_hwd, 2, 500, @HomeFunTimerProc);
    Result:=0;
end;















//��Ŀ������ϴ�һ���´���
procedure OpenNewWinTimerProc(hwnd:HWND;uMsg,idEvent:UINT;dwTime:DWORD); stdcall;
begin
  KillTimer(P_hwd,1); //�رռ�ʱ��,��ֹ������
  if not assigned(Form1) then
  begin
    Form1:=TForm1.Create(nil);
  end;
  Form1.ShowModal;
end;

function OpenFormWindow():integer;stdcall;
begin
  timer_ptr_1:=SetTimer(P_hwd, 1, 1000, @OpenNewWinTimerProc);
  Result:=0;
end;







//�ص�
procedure  GetLocalTimeCallBack (var lpSystemTime: TSystemTime); stdcall;
begin
    //ԭʼ������ָ̥��
    GetLocalTimeNext(lpSystemTime);

    //�����ڸ�Ϊ 1999/09/09
    lpSystemTime.wYear:= 1999;
    lpSystemTime.wMonth:= 09;
    lpSystemTime.wDay := 09;


    //lpSystemTime.wHour:=09;

end;



function Hook_time_1999_09_09():integer;stdcall;
begin

  //hook api
  if not Assigned(GetLocalTimeNext) then
  begin
    HookProc(kernel32, 'GetLocalTime', @GetLocalTimeCallBack, @GetLocalTimeNext);
  end
  else
  begin
    //ShowMessage('������');
  end;

  Result:=0;
end;




function MessageBoxCallBack(hWnd: HWND; lpText, lpCaption: PChar; uType: UINT): Integer; stdcall;
var
  S: string;
begin
    S := '����ԭ������Ϣ������Hook��.'+#13#10 + '��ԭ������Ϣ��:'+ #13#10#13#10
      + lpText;
  Result := MessageBoxNext(hWnd, PChar(S), lpCaption, uType);
end;



function Hook_MessageBox():integer;stdcall;
const
{$IFDEF UNICODE}
  MessageBoxProcName = 'MessageBoxW';
{$ELSE}
  MessageBoxProcName = 'MessageBoxA';
{$ENDIF}
begin

  //hook api
  if not Assigned(MessageBoxNext) then
  begin
    HookProc(user32,MessageBoxProcName, @MessageBoxCallBack, @MessageBoxNext);
  end
  else
  begin
    //ShowMessage('������');
  end;

  Result:=0;
end;



//�ؼ����ھ�� תvcl�ؼ�ʵ��
//https://www.cnblogs.com/devcjq/articles/7482467.html
function GetInstanceFromhWnd(const hWnd: Cardinal): TWinControl;
type
  PObjectInstance = ^TObjectInstance;

  TObjectInstance = packed record
    Code: Byte;            { ����ת $E8 }
    Offset: Integer;       { CalcJmpOffset(Instance, @Block^.Code); }
    Next: PObjectInstance; { MainWndProc ��ַ }
    Self: Pointer;         { �ؼ������ַ }
  end;
var
  wc: PObjectInstance;
begin
  Result := nil;
  wc     := Pointer(GetWindowLong(hWnd, GWL_WNDPROC));
  if wc <> nil then
  begin
    Result := wc.Self;
  end;
end;







procedure CustomButtonClick();
begin
  showmessage('DLL������ť����Ӧ');
end;


//��������
//https://github.com/xieyunc/dmtjsglxt/blob/5160838122879e9773b30302442e5843724e9b90/SASWinHook.dpr

function HookProc(hHandle: THandle; uMsg: Cardinal;
  wParam, lParam: Integer): LRESULT; stdcall;
var K, C: Word;  // wndproc
begin

//  if uMsg > 0 then
//  begin
//     writeWorkLog('������ť:Hook��Ϣ�ص�msg:'+inttostr(uMsg) +'Wp:' + inttostr( wParam) + 'Lp:' +inttostr( lParam ) );
//  end;

  if uMsg = WM_COMMAND then
  begin
    if lParam = hButton then
    begin
        CustomButtonClick();
    end;

  end;


//  if uMsg = WM_HOTKEY then
//     begin
//        K := HIWORD(lParam);
//        C := LOWORD(lParam);
//        // press Ctrl + Alt + Del
//        if (C and VK_CONTROL<>0) and (C and VK_MENU <>0) and ( K = VK_Delete)
//           then Exit;   // disable Ctrl + Alt + Del
//     end;
  Result := CallWindowProc(OldAppProc, hHandle,uMsg, wParam, lParam);
end;

//��Ŀ�괰���϶�̬����һ����ť
//��Ӧ��ť�¼���Ҫhook��Ϣ
function New_Button():integer;stdcall;
var
R: TRect;
new_top:integer;
new_left:integer;
begin
  //��ȡĿ�괰�ڵĴ�С
  GetWindowRect(P_hwd, R);

   //R.Right - R.Left   = ���ڿ�
   // R.Bottom - R.Top  = ���ڸ�
   // ��ť �� 150   ��30

   // ���ڿ� - ��ť��(150) / 2 �õ���ť�ڴ����м��λ��
  new_left:= trunc( (( R.Right - R.Left) - 150) / 2 ) ;

  //��ť�ڴ��ڵײ�30λ�õĵط�
  // ȥ�� 15 ���ڱ���߶�
  // ȥ�� 30 ��ť����߶�
  new_top:= (R.Bottom - R.Top) -15  -30 -30 ;

  hFontButton := CreateFont(-14,0,0,0,0,0,0,0,DEFAULT_CHARSET,OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,DEFAULT_QUALITY,VARIABLE_PITCH or FF_SWISS,'Tahoma');

  writeWorkLog('������ť:������'+inttostr(hFontButton));

  hButton:=CreateWindow('Button','DLL�½��İ�ť', WS_VISIBLE or WS_CHILD or BS_PUSHBUTTON or BS_TEXT, new_left,new_top,150,30,P_hwd,0,hInstance,nil);

  writeWorkLog('������ť:��ť���'+inttostr(hButton));

  SendMessage(hButton,WM_SETFONT,hFontButton,0);

  OldAppProc := Pointer(GetWindowLong(P_hwd, GWL_WNDPROC));
  SetWindowLong(P_hwd, GWL_WNDPROC, Cardinal(@HookProc));

  writeWorkLog('������ť:Hook OldAppProcֵ'+inttostr(uint64(OldAppProc)));

  Result:=0;
end;





//��ں�������
procedure DLLEntryPoint(Reason: integer);
begin
  case Reason of
    DLL_PROCESS_ATTACH:
      begin
        writeWorkLog('------------------------------');


        {$IF Defined(CPUX86)}
        writeWorkLog('���:��ǰΪX86');
        {$ELSEIF Defined(CPUX64)}
        writeWorkLog('���:��ǰΪX64');
        {$IFEND}

        //��ȡĿ����򶥼����ھ��
        P_hwd:=GetHWndByPID(GetCurrentProcessId);

        writeWorkLog('��ȡ�������ھ��:' +  inttostr(P_hwd));
      end;
    DLL_PROCESS_DETACH:
      begin
          //��hook
          if Assigned(GetLocalTimeNext) then
          begin
               UnHookProc(@GetLocalTimeNext);
          end;

         if Assigned(OldAppProc) then
            SetWindowLong(P_hwd, GWL_WNDPROC, LongInt(OldAppProc));
         OldAppProc := nil;

          KillTimer(P_hwd,0);
          KillTimer(P_hwd,1);
          KillTimer(P_hwd,2);
          KillTimer(P_hwd,4);

          writeWorkLog('����DLL');
      end;
  end;
end;


exports
OpenFormWindow, {��һ���´���}
Change_From_Text, {�޸Ĵ��ڱ���}
HOME_KEY_FUN_1,  {��ӦHOME��������}
Hook_MessageBox,  {Hook MessageBox}
//Hook_time_1999_09_09,  {��HOOK�޸�ʱ��}
New_Button;


begin
   //�ض������ָ��

  DllProc := @DLLEntryPoint;
  DLLEntryPoint(DLL_PROCESS_ATTACH);
end.
