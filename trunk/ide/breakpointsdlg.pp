unit breakpointsdlg;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, LResources, StdCtrls,Buttons,Extctrls,ComCtrls;

type

  TBreakPointAddedEvent = procedure (sender : TObject; Expression : String) of Object;
  TBreakPointsdlg = class(TForm)
    ListView1: TListView;
  private
    { private declarations }
    FOnBreakpointAddedEvent : TBreakPointAddedEvent;
  protected
  public
    { public declarations }
    constructor Create(AOwner : TComponent); override;
    destructor Destroy; override;
    property OnBreakpointAddedEvent : TBreakPointAddedEvent read FOnBreakPointAddedEvent write FOnBreakPointAddedEvent;

  end;

{  TInsertWatch = class(TForm)
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
 }
var
  Breakpoints_Dlg  : TBreakPointsDlg;
//  InsertWatch  : TInsertWatch;
implementation

constructor TBreakPointsdlg.Create(AOwner : TComponent);
Begin
  inherited;
  if LazarusResources.Find(Classname)=nil then
  begin
  ListView1 := TListView.Create(self);
  with ListView1 do
    Begin
      Parent := self;
      Align := alClient;
      Visible := True;
      Name := 'ListView1';
      Columns.Clear;
      Columns.Add('Filename/Address');
      Columns.Add('Line/Length');
      Columns.Add('Condition');
      Columns.Add('Action');
      Columns.Add('Pass Count');
      Columns.Add('Group');
      ViewStyle := vsReport;
    end;
  Caption := 'Breakpoints';
  Name := 'BreakPointsDlg';
  Width := 350;
  Height := 100;

  end;


End;

destructor TBreakPointsDlg.Destroy;
Begin
  inherited;
end;


initialization

end.

