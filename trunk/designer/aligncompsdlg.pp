{
  Author: Mattias Gaertner

  Abstract:
    Defines TAlignComponentsDialog.
}
unit AlignCompsDlg;

{$mode objfpc}{$H+}

interface

uses
  Classes, LCLLinux, Forms, Controls, Buttons, ExtCtrls, LResources;

type
  TAlignComponentsDialog = class(TForm)
    HorizontalRadioGroup: TRadioGroup;
    VerticalRadioGroup: TRadioGroup;
    OkButton: TButton;
    CancelButton: TButton;
    procedure OkButtonClick(Sender: TObject);
    procedure CancelButtonClick(Sender: TObject);
  public
    constructor Create(AOwner: TComponent);  override;
  end;

var AlignComponentsDialog: TAlignComponentsDialog;

function ShowAlignComponentsDialog: TModalResult;

implementation

function ShowAlignComponentsDialog: TModalResult;
begin
  if AlignComponentsDialog=nil then
    AlignComponentsDialog:=TAlignComponentsDialog.Create(Application);
  with AlignComponentsDialog do begin
    SetBounds((Screen.Width-365) div 2,(Screen.Height-225) div 2,355,215);
    HorizontalRadioGroup.ItemIndex:=0;
    VerticalRadioGroup.ItemIndex:=0;
    Result:=ShowModal;
  end;
end;


{ TAlignComponentsDialog }

constructor TAlignComponentsDialog.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  if LazarusResources.Find(Classname)=nil then begin
    SetBounds((Screen.Width-365) div 2,(Screen.Height-225) div 2,355,215);
    Caption:='Alignment';

    HorizontalRadioGroup:=TRadioGroup.Create(Self);
    with HorizontalRadioGroup do begin
      Name:='HorizontalRadioGroup';
      Parent:=Self;
      Left:=5;
      Top:=5;
      Width:=170;
      Height:=165;
      Caption:='Horizontal';
      with Items do begin
        BeginUpdate;
        Add('No change');
        Add('Left sides');
        Add('Centers');
        Add('Right sides');
        Add('Center in window');
        Add('Space equally');
        Add('Left space equally');
        Add('Right space equally');
        EndUpdate;
      end;
      Show;
    end;

    VerticalRadioGroup:=TRadioGroup.Create(Self);
    with VerticalRadioGroup do begin
      Name:='VerticalRadioGroup';
      Parent:=Self;
      Left:=180;
      Top:=5;
      Width:=170;
      Height:=165;
      Caption:='Vertical';
      with Items do begin
        BeginUpdate;
        Add('No change');
        Add('Tops');
        Add('Centers');
        Add('Bottoms');
        Add('Center in window');
        Add('Space equally');
        Add('Top space equally');
        Add('Bottom space equally');
        EndUpdate;
      end;
      Show;
    end;

    OkButton:=TButton.Create(Self);
    with OkButton do begin
      Name:='OkButton';
      Parent:=Self;
      Left:=145;
      Top:=179;
      Width:=75;
      Height:=25;
      Caption:='Ok';
      OnClick:=@OkButtonClick;
      Show;
    end;

    CancelButton:=TButton.Create(Self);
    with CancelButton do begin
      Name:='CancelButton';
      Parent:=Self;
      Left:=235;
      Top:=OkButton.Top;
      Width:=75;
      Height:=25;
      Caption:='Cancel';
      OnClick:=@CancelButtonClick;
      Show;
    end;
  end;
end;

procedure TAlignComponentsDialog.OkButtonClick(Sender: TObject);
begin
  ModalResult:=mrOk;
end;

procedure TAlignComponentsDialog.CancelButtonClick(Sender: TObject);
begin
  ModalResult:=mrCancel;
end;

initialization
  AlignComponentsDialog:=nil;

end.
