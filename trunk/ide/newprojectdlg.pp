{
  Author: Mattias Gaertner

  Abstract:
    The new project dialog for lazarus.

}
unit NewProjectDlg;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Graphics, Controls, LResources, Project, Buttons,
  StdCtrls;

type
  TNewProjectDialog = class(TForm)
    CreateButton: TButton;
    CancelButton: TButton;
    ListBox: TListBox;
    HelpLabel: TLabel;
    procedure CreateButtonClick(Sender:TObject);
    procedure CancelButtonClick(Sender:TObject);
    procedure ListBoxMouseUp(Sender:TObject;
       Button:TMouseButton;  Shift:TShiftState;  X,Y:integer);
    procedure NewProjectDialogResize(Sender: TObject);
  private
    procedure FillHelpLabel;
  public
    constructor Create(AOwner: TComponent); override;
  end;

function ChooseNewProject(var ProjectType: TProjectType):TModalResult;

implementation

function ChooseNewProject(var ProjectType: TProjectType):TModalResult;
var NewProjectDialog: TNewProjectDialog;
  i:integer;
  pt:TProjectType;
begin
  NewProjectDialog:=TNewProjectDialog.Create(Application);
  try
    Result:=NewProjectDialog.ShowModal;
    if Result=mrOk then begin
      i:=0;
      for pt:=Low(TProjectType) to High(TProjectType) do begin
        if i=NewProjectDialog.ListBox.ItemIndex then
          ProjectType:=pt;
        inc(i);
      end;
    end;
  finally
    NewProjectDialog.Free;
  end;
end;

{ NewProjectDialog }

constructor TNewProjectDialog.Create(AOwner: TComponent);
var pt:TProjectType;
  MaxX, MaxY:integer;
begin
  inherited Create(AOwner);
  if LazarusResources.Find(ClassName)=nil then begin
    Width:=390;
    Height:=240;
    Position:=poScreenCenter;
    Caption:='Create a new project';
    OnResize:=@NewProjectDialogResize;
    MaxX:=386;
    MaxY:=238;

    ListBox:=TListBox.Create(Self);
    with ListBox do begin
      Parent:=Self;
      Name:='ListBox';
      Left:=5;
      Top:=5;
      Width:=150;
      Height:=MaxY-50;
      with Items do begin
        BeginUpdate;
        for pt:=Low(TProjectType) to High(TProjectType) do
          Add(ProjectTypeNames[pt]);
        EndUpdate;
      end;
      ItemIndex:=0;
      OnMouseUp:=@ListBoxMouseUp;
      Show;
    end;

    HelpLabel:=TLabel.Create(Self);
    with HelpLabel do begin
      Parent:=Self;
      Name:='HelpLabel';
      Left:=ListBox.Left+ListBox.Width+10;
      Top:=ListBox.Top+2;
      Width:=MaxX-5-Left;
      Height:=ListBox.Height-2;
      WordWrap:=true;
      Caption:='Select a project type';
      Show;
    end;

    CreateButton:=TButton.Create(Self);
    with CreateButton do begin
      Parent:=Self;
      Name:='CreateButton';
      Width:=80;
      Height:=23;
      Left:=Self.ClientWidth-Width*2-2*15;
      Top:=Self.ClientHeight-40;
      OnClick:=@CreateButtonClick;
      Caption:='Create';
      Show;
    end;

    CancelButton:=TButton.Create(Self);
    with CancelButton do begin
      Parent:=Self;
      Name:='CancelButton';
      Width:=80;
      Height:=23;
      Left:=Self.ClientWidth-Width-15;
      Top:=CreateButton.Top;
      OnClick:=@CancelButtonClick;
      Caption:='Cancel';
      Show;
    end;

  end;
  NewProjectDialogResize(nil);
  FillHelpLabel;
end;

procedure TNewProjectDialog.FillHelpLabel;
var i:integer;
  pt:TProjectType;
begin
  i:=0;
  for pt:=Low(TProjectType) to High(TProjectType) do begin
    if i=ListBox.ItemIndex then begin
      HelpLabel.Caption:=ProjectTypeDescriptions[pt];
      HelpLabel.Width:=ClientWidth-HelpLabel.Left-10;
    end;
    inc(i);
  end;
end;

procedure TNewProjectDialog.CreateButtonClick(Sender:TObject);
begin
  ModalResult:=mrOk;
end;

procedure TNewProjectDialog.CancelButtonClick(Sender:TObject);
begin
  ModalResult:=mrCancel;
end;

procedure TNewProjectDialog.ListBoxMouseUp(Sender:TObject;
  Button:TMouseButton;  Shift:TShiftState;  X,Y:integer);
begin
  FillHelpLabel;
end;

procedure TNewProjectDialog.NewProjectDialogResize(Sender: TObject);
var
  MaxX, MaxY:integer;
begin
  MaxX:=ClientWidth;
  MaxY:=ClientHeight;

  with ListBox do begin
    Left:=5;
    Top:=5;
    Width:=MaxX-200;
    Height:=MaxY-50;
  end;

  with HelpLabel do begin
    Left:=ListBox.Left+ListBox.Width+10;
    Top:=ListBox.Top+2;
    Width:=MaxX-5-Left;
    Height:=ListBox.Height-2;
  end;

  with CreateButton do begin
    Width:=80;
    Height:=23;
    Left:=Self.ClientWidth-Width*2-2*15;
    Top:=Self.ClientHeight-40;
  end;

  with CancelButton do begin
    Width:=80;
    Height:=23;
    Left:=Self.ClientWidth-Width-15;
    Top:=CreateButton.Top;
  end;
end;

end.
