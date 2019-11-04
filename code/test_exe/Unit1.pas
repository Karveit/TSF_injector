unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls,System.Math,System.DateUtils;

type
  TForm1 = class(TForm)
    Panel1: TPanel;
    Timer1: TTimer;
    Label1: TLabel;
    Label2: TLabel;
    TimeLabel: TLabel;
    Panel2: TPanel;
    Label3: TLabel;
    Label4: TLabel;
    hpLabel: TLabel;
    hitButton: TButton;
    Timer2: TTimer;
    ShowDmgLabel: TLabel;
    Timer3: TTimer;
    ResetButton: TButton;
    Label6: TLabel;
    Label8: TLabel;
    Label5: TLabel;
    Label7: TLabel;
    MPLabel: TLabel;
    Label9: TLabel;
    AntMpLabel: TLabel;
    Label11: TLabel;
    AnthpLabel: TLabel;
    AntShowDmgLabel: TLabel;
    Label14: TLabel;
    Label10: TLabel;
    WinTextLabel: TLabel;
    MsgEdit: TEdit;
    Label12: TLabel;
    ShowMsgButton: TButton;
    Timer4: TTimer;
    procedure Timer1Timer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure hitButtonClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Timer2Timer(Sender: TObject);
    procedure Timer3Timer(Sender: TObject);
    procedure ResetButtonClick(Sender: TObject);
    procedure ShowMsgButtonClick(Sender: TObject);
  private
    { Private declarations }
    procedure Hero_reset();  //�������HP
  public
    { Public declarations }
  end;



type THero=record
   Hp: LONG64;
   Mp: LONG64;
   Dps:LONG64;
   Def:LONG64;
end;
  PHero  =^ THero;

type TTestMen=record
   OneHero:PHero;   //�ѷ�
   AntHero:PHero;   //�ж�
end;
   PTestMen=^TTestMen;

var
  Form1: TForm1;
  all_user:PTestMen;


implementation
uses
HookUtils;
{$R *.dfm}





procedure TForm1.FormCreate(Sender: TObject);
var
tmp_hero: PHero;
tmp_anthero:PHero;
begin

{$IF Defined(CPUX86)}
Form1.Caption:= '���Գ��� [x86]'  ;
{$ELSEIF Defined(CPUX64)}
Form1.Caption:= '���Գ��� [x64]'  ;
{$IFEND}


  //��ʼ���ͷ�
  Dispose(all_user);

  New(all_user);
  new(tmp_hero);
  new(tmp_anthero);



  tmp_hero.Hp:=6000;
  tmp_hero.Mp:=5000;
  tmp_hero.Dps:=400;
  tmp_hero.Def:=5;

  tmp_anthero.Hp:=12000;
  tmp_anthero.Mp:=10000;
  tmp_anthero.Dps:=800;
  tmp_anthero.Def:=10;

  all_user.OneHero:= tmp_hero;
  all_user.AntHero:= tmp_anthero;


end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
     Dispose(all_user); //�ͷ�ָ��
end;

procedure TForm1.hitButtonClick(Sender: TObject);
var
tmp_dmg:LONG64;
tmp_antdmg:LONG64;
tmp_hero: PHero;
tmp_anthero:PHero;
begin

   tmp_hero:= all_user.OneHero;
   tmp_anthero:=all_user.AntHero;



    if (tmp_hero.Hp <= 0  ) or  (tmp_anthero.Hp <= 0  ) then
   begin
      showmessage('��Ϸ�ѽ���');
      exit;
   end;


   //һ�ι�����Ҫ400 MP���㲻�ܹ���
   if tmp_hero.Mp >= 400  then
   begin
      //������MP
      tmp_hero.Mp:=tmp_hero.Mp-400;

     //�ѷ���λ���ι������˺�
     //��� 1��DPS  = ���ι�����ԭʼ�˺�
     // ԭʼ�˺� �� �������  �õ���Ѫ����
     Randomize;
     tmp_dmg:=randomrange(1,tmp_hero.Dps);
     tmp_dmg:=tmp_dmg-tmp_anthero.Def;

      //�����Ѫ����Ϊ����
     if tmp_dmg < 0  then tmp_dmg := 0;


   end
    else
    begin
        //ûMP ���ι����˺�Ϊ��
        tmp_dmg := 0;
    end;


   if tmp_anthero.Mp >= 400  then
   begin
      //������MP
      tmp_anthero.Mp:=tmp_anthero.Mp-400;

      Randomize;
      tmp_antdmg:=randomrange(1,tmp_anthero.Dps);
      tmp_antdmg:=tmp_antdmg-tmp_hero.Def;
      if tmp_antdmg < 0  then tmp_antdmg := 0;


   end
    else
    begin
        tmp_antdmg := 0;
    end;


         //��ʾ�˺�,2���ر�
    ShowDmgLabel.Caption:=' -' + inttostr(tmp_antdmg);
    AntShowDmgLabel.Caption:=' -' + inttostr(tmp_dmg);



   //������Ѫ��
   tmp_hero.Hp:= tmp_hero.Hp - tmp_antdmg;
   tmp_anthero.Hp:= tmp_anthero.Hp - tmp_dmg;
   Timer3.Enabled:=true;


    if (tmp_hero.Hp <= 0  ) or  (tmp_anthero.Hp <= 0  ) then
   begin


      if tmp_anthero.Hp <= 0  then
      begin
         showmessage('��Ϸ����,�ѷ�Ӯ��');
      end
        else
        begin
           showmessage('��Ϸ����,�з�Ӯ��');
        end;

      exit;
   end;



end;


procedure TForm1.Hero_reset();
var
tmp_hero: PHero;
tmp_anthero:PHero;
tmp_index:integer;
tmp_ant_index:integer;
begin
    //��ʱ�ر���ʾʱ��ļ�ʱ��
   Timer1.Enabled:=false;

  tmp_hero:= all_user.OneHero;
  tmp_anthero:=all_user.AntHero;

  //��ʼ���ͷ�
  Dispose(tmp_hero);
  Dispose(tmp_anthero);
  Dispose(all_user);


  New(tmp_hero);
  New(tmp_anthero);
  New(all_user);


  tmp_hero.Hp:=6000;
  tmp_hero.Mp:=5000;
  tmp_hero.Dps:=400;
  tmp_hero.Def:=5;

  tmp_anthero.Hp:=12000;
  tmp_anthero.Mp:=10000;
  tmp_anthero.Dps:=800;
  tmp_anthero.Def:=10;

  all_user.OneHero:= tmp_hero;
  all_user.AntHero:= tmp_anthero;

  Timer1.Enabled:=true;   //�򿪼�ʱ����������ʾ�ڽ�����
end;


procedure TForm1.ResetButtonClick(Sender: TObject);
begin
  Hero_reset();
end;

procedure TForm1.ShowMsgButtonClick(Sender: TObject);
begin

  MessageBox(Handle, pwidechar(msgedit.text), '���ǵ�������Ϣ', 0);
end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
  //delphi now()�õ�GetLocalTime
  TimeLabel.Caption:= FormatDateTime('yyyy��mm��dd�� hh:nn:ss',now());
  WinTextLabel.Caption:=self.Caption;
end;

procedure TForm1.Timer2Timer(Sender: TObject);
var
tmp_hero: PHero;
tmp_anthero:PHero;
begin
  //hpLabel.Caption:= inttostr(LONG64(Test_HP^));
 tmp_hero:= all_user.OneHero;
 tmp_anthero:=all_user.AntHero;

 hpLabel.Caption:= inttostr(tmp_hero.Hp);
 mpLabel.Caption:= inttostr(tmp_hero.Mp);

 if tmp_hero.Hp <=0  then
 begin
    hpLabel.Font.Color:=clred;
 end
  else
  begin
    hpLabel.Font.Color:=clblack;
  end;


 if tmp_hero.Mp <=400  then
 begin
    mpLabel.Font.Color:=clred;
 end
  else
  begin
    mpLabel.Font.Color:=clblack;
  end;


 AnthpLabel.Caption:= inttostr(tmp_anthero.Hp);
 AntmpLabel.Caption:= inttostr(tmp_anthero.Mp);


 if tmp_anthero.Hp <=0  then
 begin
    AnthpLabel.Font.Color:=clred;
 end
  else
  begin
    AnthpLabel.Font.Color:=clblack;
  end;

 if tmp_anthero.Mp <=400  then
 begin
    AntmpLabel.Font.Color:=clred;
 end
  else
  begin
    AntmpLabel.Font.Color:=clblack;
  end;



end;

procedure TForm1.Timer3Timer(Sender: TObject);
begin
    Timer3.Enabled:=false;
    ShowDmgLabel.Caption:='';
    AntShowDmgLabel.Caption:='';
end;

end.
