unit watchesdlg;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, LResources, StdCtrls,Buttons,Extctrls;

type

  TWatchAddedEvent = procedure (sender : TObject; Expression : String) of Object;
  TWatchesdlg = class(TForm)
    Listbox1: TLISTBOX;
    procedure WatchesdlgResize(Sender: TObject);
  private
    { private declarations }
    FOnWatchAddedEvent : TWatchAddedEvent;
  protected
    Procedure Listbox1KeyDown(Sender: TObject; var Key: Word; Shift:TShiftState);
  public
    { public declarations }
    constructor Create(AOwner : TComponent); override;
    destructor Destroy; override;
    Procedure AddWatch(WatchVar : String);
    Procedure UpdateWatch(WatchVar, NewDisplay : String);
    property OnWatchAddedEvent : TWatchAddedEvent read FOnWatchAddedEvent write FOnWatchAddedEvent;
    
  end;

  TInsertWatch = class(TForm)
    lblExpression : TLabel;
    lblRepCount   : TLabel;
    lblDigits     : TLabel;
    cbEnabled    : TCHeckbox;
    cbAllowFunc  : TCheckbox;
    Style        : TRadioGroup;
    btnOK        : TButton;
    btnCancel    : TButton;
    btnHelp      : TButton;
    edtExpression: TEdit;
    edtRepCount  : TEdit;
    edtDigits    : TEdit;
  private

  public
    constructor Create(AOWner : TCOmponent); override;
    destructor Destroy; override;
  end;
  
var
  Watches_Dlg  : TWatchesDlg;
  InsertWatch  : TInsertWatch;
implementation

constructor TWatchesdlg.Create(AOwner : TComponent);
Begin
  inherited;
  if LazarusResources.Find(Classname)=nil then begin
    Caption := 'Watches';
    Name := 'WatchesDlg';
    Width := 250;
    Height := 100;

    //TListBox currently does NOT fire keypress, keyDown, KeyUp events.  This is a fix for now.
    OnKeyDown := @ListBox1KeyDown;
    Position := poScreenCenter;
    OnResize:=@WatchesdlgResize;

    Listbox1 := TListbox.Create(self);
    with Listbox1 do
      Begin
        Parent := self;
        Align := alClient;
        Visible := True;
        Name := 'ListBox1';
        OnKeyDown := @Listbox1KeyDown;

      end;
  end;
  
  //unitl events are saved in the lfm
  Listbox1.OnKeyDown := @Listbox1KeyDown;
  //until the listbox events actually fire...
  OnKeyDown := @ListBox1KeyDown;

  WatchesdlgResize(nil);
  InsertWatch := TInsertWatch.Create(nil);
End;

destructor TWatchesDlg.Destroy;
Begin
  InsertWatch.Free;
  inherited;
end;

procedure TWatchesdlg.WatchesdlgResize(Sender: TObject);
begin

end;

Procedure TWatchesDlg.Listbox1KeyDown(Sender : TObject; var Key : Word; Shift : TShiftState);
var
  Count : Integer;
Begin

Writeln('Key is ',Key);
case Key of
   45 : begin //insert
          if InsertWatch.ShowMOdal = mrOK then
             Begin
                //just for now...
                if InsertWatch.edtExpression.Text <> '' then
                      AddWatch(InsertWatch.edtExpression.Text);
             end;
             
        end;
   46 : begin //delete
          if Listbox1.SelCount > 0 then
             Begin
                Count := 0;
                while Count <= Listbox1.Items.Count-1 do
                   if Listbox1.Selected[Count] then
                      Listbox1.Items.Delete(Count)
                      else
                      Inc(Count);
             end;
        end;
   end; //case
end;


//This is used by MAIN to add a watch to the list.  It should have already been added to TDebugger.
//In the future, maybe pass in a TWatch or something similiar
Procedure TWatchesDlg.AddWatch(WatchVar : String);
Begin
  if pos(':',WatchVar) = 0 then
  ListBox1.Items.Add(WatchVar+':')
  else
  ListBox1.Items.Add(WatchVar);
  
  if Assigned(OnWatchAddedEvent) then
     OnWatchAddedEvent(self,watchVar);
end;

{This is used by MAin.pp.  It passed the Watchvar, we look for it in our list and then set that line to display NewDisplay.
 New display is added to WatchVar so we end up with WatchVar ':'+ NewDisplay.
 Watchvar is usually sometyhnig like
 I
 or
 Texts
 a Colon is added, then we search.  When found we add Watchvar + ':' + Newdisplay
 }
Procedure TWatchesDlg.UpdateWatch(WatchVar, NewDisplay : String);
Var
  I : Integer;

Begin
  //search for watchvar
  for I := 0 to ListBox1.Items.count-1 do
       if pos(WatchVar+':',Listbox1.Items[i]) = 1 then
            Listbox1.Items[i] := WatchVar+':'+NewDisplay;
end;


{ TInsertWatch }
constructor TInsertWatch.Create(AOwner : TComponent);
Begin
  inherited;
  if LazarusResources.Find(Classname)=nil then
  begin
  Width := 420;
  Height := 200;
  Position := poScreenCenter;
  Caption := 'Watch Properties';
  lblExpression := TLabel.Create(self);
  with lblExpression do
     Begin
       Parent := self;
       Caption := 'Expression:';
       Name := 'lblExpression';
       Left := 15;
       Top := 20;
       Visible := TRue;
     end;
     
  edtExpression := TEdit.Create(self);
  with edtExpression do
     Begin
       Parent := Self;
       Name := 'edtExpression';
       Left := lblExpression.Left+lblExpression.Width+25;
       top := lblExpression.top-3;
       Width := self.width-left-15;
       Visible := TRue;
       Text := '';
     end;
     
     
  lblRepCount := TLabel.Create(self);
  with lblRepCount do
     Begin
       Parent := self;
       Caption := 'Repeat Count:';
       Name := 'lblRepCount';
       Left := 15;
       Top := 45;
       Width := 80;
       Visible := TRue;
     end;
     
  edtRepCount := TEdit.Create(self);
  with edtRepCount do
     Begin
        Parent := Self;
        Text := '0';
        NAme := 'edtRepCount';
        Left := lblExpression.Left+lblExpression.Width+25;
        Top := lblRepCount.Top -3;
        Width := 60;
       Visible := TRue;
     end;

  lblDigits := TLAbel.Create(self);
  with lblDigits do
     Begin
       Parent := self;
       Caption := 'Digits:';
       Name := 'lblDigits';
       Left := edtRepCount.left+edtRepCount.Width+10;
       Width := 40;
       Top := lblRepCount.Top;
       Visible := TRue;
     end;

  edtDigits := TEdit.Create(self);
  with edtDigits do
     Begin
       Parent := self;
       Text := '0';
       Name := 'edtDigits';
       Left := lblDigits.Left+lblDigits.Width+10;
       Top := lblRepCount.Top;
       Width := self.width-left-15;
        Visible := TRue;
    end;
     
  cbEnabled := TCheckbox.Create(self);
  with cbEnabled do
     Begin
       Parent := self;
       Left := 15;
       Top := lblDigits.Top+20;

       Name := 'cbEnabled';
       Text := 'Enabled';
       Width := 60;
       Checked := True;
       Visible := TRue;
     end;
     
  cbAllowFunc := TCheckBox.Create(self);
  with cbAllowFunc do
     Begin
       Parent := self;
       Left := edtRepCount.Left;
       Text := 'Allow Function Calls';
       Name := 'cbAllowFunc';
       Checked := False;
       Top := cbEnabled.Top;
       Visible := TRue;
     end;
     
     

  Style := TRadioGroup.Create(self);
  with Style do
     Begin
       Parent := self;
       Name := 'Style';
       Left := 15;
       Top := cbEnabled.Top + 25;
       Width := self.width-left-15;
       Columns := 3;
       Items.Add('Character');
       Items.Add('String');
       Items.Add('Decimal');
       Items.Add('Hexadecimal');
       Items.Add('Floating Point');
       Items.Add('Pointer');
       Items.Add('Record/Structure');
       Items.Add('Default');
       Items.Add('Memory Dump');
       ItemIndex := 7;  //default
       Height := self.height-top-40;
       Visible := True;
     end;
     
   btnOK := TButton.Create(self);
   with btnOK do
      Begin
        Parent := self;
        caption := 'OK';
        Left := (self.width div 2) -25 -15;
        Top := Self.Height-30;
        ModalResult := mrOK;
        Visible := TRue;
      end;
      
   btnCancel := TButton.Create(self);
   with btncancel do
      Begin
        Parent := self;
        caption := 'Cancel';
        Left := (self.width div 2) -25+Width+5 -15;
        Top := Self.Height-30;
        ModalResult := mrCancel;
        Visible := TRue;
      end;

   btnHelp := TButton.Create(self);
   with btnHelp do
      Begin
        Parent := self;
        caption := 'Help';
        Left := (self.width div 2) -25+(2*width)+10 -15;
        Top := Self.Height-30;
//        ModalResult := mrHelp;
        Enabled := FAlse;
        Visible := TRue;
      end;
   end;
   
  
end;

destructor TInsertWatch.destroy;
begin
  inherited;
end;

initialization
{$I watches_dlg.lrs}
{$I insertwatch.lrs}



end.

