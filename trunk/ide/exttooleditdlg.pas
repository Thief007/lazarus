{
/***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/

  Author: Mattias Gaertner

  Abstract:
    Defines the TExternalToolOptions which stores the settings of a single
    external tool. (= Programfilename and parameters)
    All TExternalToolOptions are stored in a TExternalToolList
    (see exttooldialog.pas).
    And provides TExternalToolOptionDlg which is a dialog for editing a
    TExternalToolOptions;
    
}
unit ExtToolEditDlg;

{$mode objfpc}
{$H+}

{$I ide.inc}

interface

uses
  {$IFDEF IDE_MEM_CHECK}
  MemCheck,
  {$ENDIF}
  Classes, SysUtils, LCLLinux, Controls, Forms, Buttons, StdCtrls, ComCtrls,
  Dialogs, ExtCtrls, LResources, XMLCfg, KeyMapping, TransferMacros;

{ The xml format version:
    When the format changes (new values, changed formats) we can distinguish old
    files and are able to convert them.
} 
const ExternalToolOptionsFormat = '1.0';

type
  {
    the storage object for a single external tool
  }
  TExternalToolOptions = class
  private
    fTitle: string;
    fFilename: string;
    fCmdLineParams: string;
    fWorkingDirectory: string;
    fKey: word;
    fShift: TShiftState;
  public
    procedure Assign(Source: TExternalToolOptions);
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    function Load(XMLConfig: TXMLConfig; const Path: string): TModalResult;
    function Save(XMLConfig: TXMLConfig; const Path: string): TModalResult;
    function ShortDescription: string;
    
    property Title: string read fTitle write fTitle;
    property Filename: string read fFilename write fFilename;
    property CmdLineParams: string read fCmdLineParams write fCmdLineParams;
    property WorkingDirectory: string
           read fWorkingDirectory write fWorkingDirectory;
    property Key: word read fKey write fKey;
    property Shift: TShiftState read fShift write fShift;
  end;

  {
    the editor dialog for a single external tool
  }
  TExternalToolOptionDlg = class(TForm)
    TitleLabel: TLabel;
    TitleEdit: TEdit;
    FilenameLabel: TLabel;
    FilenameEdit: TEdit;
    ParametersLabel: TLabel;
    ParametersEdit: TEdit;
    WorkingDirLabel: TLabel;
    WorkingDirEdit: TEdit;
    KeyGroupBox: TGroupBox;
    KeyCtrlCheckBox: TCheckBox;
    KeyAltCheckBox: TCheckBox;
    KeyShiftCheckBox: TCheckBox;
    KeyComboBox: TComboBox;
    KeyGrabButton: TButton;
    MacrosGroupbox: TGroupbox;
    MacrosListbox: TListbox;
    MacrosInsert: TButton;
    OkButton: TButton;
    CancelButton: TButton;
    procedure CancelButtonClick(Sender: TObject);
    procedure OkButtonClick(Sender: TObject);
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift:TShiftState);
    procedure KeyGrabButtonClick(Sender: TObject);
    procedure MacrosInsertClick(Sender: TObject);
  private
    fOptions: TExternalToolOptions; 
    fTransferMacros: TTransferMacroList;
    GrabbingKey: integer; // 0=none, 1=Default key
    procedure ActivateGrabbing(AGrabbingKey: integer);
    procedure DeactivateGrabbing;
    procedure FillMacroList;
    procedure LoadFromOptions;
    procedure SaveToOptions;
    procedure SetComboBox(AComboBox: TComboBox; const AValue: string);
    procedure SetOptions(TheOptions: TExternalToolOptions);
    procedure SetTransferMacros(TransferMacroList: TTransferMacroList);
  public
    constructor Create(AnOwner: TComponent); override;
    destructor Destroy; override;
    property Options: TExternalToolOptions read fOptions write SetOptions;
    property MacroList: TTransferMacroList
           read fTransferMacros write SetTransferMacros;
  end;


function ShowExtToolOptionDlg(TransferMacroList: TTransferMacroList;
  ExternalToolOptions: TExternalToolOptions):TModalResult;


implementation


function ShowExtToolOptionDlg(TransferMacroList: TTransferMacroList;
  ExternalToolOptions: TExternalToolOptions):TModalResult;
var ExternalToolOptionDlg: TExternalToolOptionDlg;
begin
  Result:=mrCancel;
  ExternalToolOptionDlg:=TExternalToolOptionDlg.Create(Application);
  try
    ExternalToolOptionDlg.Options:=ExternalToolOptions;
    ExternalToolOptionDlg.MacroList:=TransferMacroList;
    Result:=ExternalToolOptionDlg.ShowModal;
    if Result=mrOk then
      ExternalToolOptions.Assign(ExternalToolOptionDlg.Options);
  finally
    ExternalToolOptionDlg.Free;
  end;
end;

{ TExternalToolOptions }

procedure TExternalToolOptions.Assign(Source: TExternalToolOptions);
begin
  if Source=Self then exit;
  if Source=nil then
    Clear
  else begin
    fTitle:=Source.fTitle;
    fFilename:=Source.fFilename;
    fCmdLineParams:=Source.fCmdLineParams;
    fWorkingDirectory:=Source.fWorkingDirectory;
    fKey:=Source.fKey;
    fShift:=Source.fShift;
  end;
end;

constructor TExternalToolOptions.Create;
begin
  inherited Create;
  Clear;
end;

destructor TExternalToolOptions.Destroy;
begin
  inherited Destroy;
end;

procedure TExternalToolOptions.Clear;
begin
  fTitle:='';
  fFilename:='';
  fCmdLineParams:='';
  fWorkingDirectory:='';
  fKey:=VK_UNKNOWN;
  fShift:=[];
end;

function TExternalToolOptions.Load(XMLConfig: TXMLConfig;
  const Path: string): TModalResult;
begin
  Clear;
  fTitle:=XMLConfig.GetValue(Path+'Title/Value',fTitle);
  fFilename:=XMLConfig.GetValue(Path+'Filename/Value',fFilename);
  fCmdLineParams:=XMLConfig.GetValue(Path+'CmdLineParams/Value',fCmdLineParams);
  fWorkingDirectory:=XMLConfig.GetValue(
                                    Path+'WorkingDirectory/Value',fWorkingDirectory);
  // key and shift will be saved with the keymapping in the editoroptions
  Result:=mrOk;
end;

function TExternalToolOptions.Save(XMLConfig: TXMLConfig;
  const Path: string): TModalResult;
begin
  XMLConfig.SetValue(Path+'Format/Version',ExternalToolOptionsFormat);
  XMLConfig.SetValue(Path+'Title/Value',fTitle);
  XMLConfig.SetValue(Path+'Filename/Value',fFilename);
  XMLConfig.SetValue(Path+'CmdLineParams/Value',fCmdLineParams);
  XMLConfig.SetValue(Path+'WorkingDirectory/Value',fWorkingDirectory);
  Result:=mrOk;
end;

function TExternalToolOptions.ShortDescription: string;
begin
  Result:=Title;
end;


{ TExternalToolOptionDlg }

constructor TExternalToolOptionDlg.Create(AnOwner: TComponent);
var
  i: integer;
  s: string;
begin
  inherited Create(AnOwner);
  GrabbingKey:=0;
  if LazarusResources.Find(ClassName)=nil then begin
  
    Caption:='Edit Tool';
    SetBounds((Screen.Width-560) div 2,(Screen.Height-450) div 2,560,450);
    OnKeyUp:=@FormKeyUp;
  
    TitleLabel:=TLabel.Create(Self);
    with TitleLabel do begin
      Name:='TitleLabel';
      Parent:=Self;
      SetBounds(5,5,110,22);
      Caption:='Title:';
      Visible:=true; 
    end;
    
    TitleEdit:=TEdit.Create(Self);
    with TitleEdit do begin
      Name:='TitleEdit';
      Parent:=Self;
      Left:=TitleLabel.Left+TitleLabel.Width+5;
      Top:=TitleLabel.Top+2;
      Width:=Self.ClientWidth-Left-10;
      Height:=25;
      Visible:=true; 
    end;
    
    FilenameLabel:=TLabel.Create(Self);
    with FilenameLabel do begin
      Name:='FilenameLabel';
      Parent:=Self;
      SetBounds(TitleLabel.Left,TitleLabel.Top+TitleLabel.Height+10,
        TitleLabel.Width,TitleLabel.Height);
      Caption:='Programfilename:';
      Visible:=true; 
    end;
    
    FilenameEdit:=TEdit.Create(Self);
    with FilenameEdit do begin
      Name:='FilenameEdit';
      Parent:=Self;
      SetBounds(TitleEdit.Left,FilenameLabel.Top+2,TitleEdit.Width,
        TitleEdit.Height);
      Visible:=true; 
    end;
    
    ParametersLabel:=TLabel.Create(Self);
    with ParametersLabel do begin
      Name:='ParametersLabel';
      Parent:=Self;
      SetBounds(FilenameLabel.Left,FilenameLabel.Top+FilenameLabel.Height+10,
        FilenameLabel.Width,FilenameLabel.Height);
      Caption:='Parameters:';
      Visible:=true; 
    end;
    
    ParametersEdit:=TEdit.Create(Self);
    with ParametersEdit do begin
      Name:='ParametersEdit';
      Parent:=Self;
      SetBounds(FilenameEdit.Left,ParametersLabel.Top+2,FilenameEdit.Width,
        FilenameEdit.Height);
      Visible:=true; 
    end;
    
    WorkingDirLabel:=TLabel.Create(Self);
    with WorkingDirLabel do begin
      Name:='WorkingDirLabel';
      Parent:=Self;
      SetBounds(ParametersLabel.Left,
        ParametersLabel.Top+ParametersLabel.Height+10,ParametersLabel.Width,
        ParametersLabel.Height);
      Caption:='Working Directory:';
      Visible:=true; 
    end;
    
    WorkingDirEdit:=TEdit.Create(Self);
    with WorkingDirEdit do begin
      Name:='WorkingDirEdit';
      Parent:=Self;
      SetBounds(ParametersEdit.Left,WorkingDirLabel.Top+2,ParametersEdit.Width,
        ParametersEdit.Height);
      Visible:=true; 
    end;
    
    KeyGroupBox:=TGroupBox.Create(Self);
    with KeyGroupBox do begin
      Name:='KeyGroupBox';
      Parent:=Self;
      Caption:='Key';
      Left:=5;
      Top:=WorkingDirLabel.Top+WorkingDirLabel.Height+12;
      Width:=Self.ClientWidth-Left-Left;
      Height:=50;
      Visible:=true; 
    end;

    KeyCtrlCheckBox:=TCheckBox.Create(Self);
    with KeyCtrlCheckBox do begin
      Name:='KeyCtrlCheckBox';
      Parent:=KeyGroupBox;
      Caption:='Ctrl';
      Left:=5;
      Top:=2;
      Width:=50;
      Height:=20;
      Visible:=true; 
    end;

    KeyAltCheckBox:=TCheckBox.Create(Self);
    with KeyAltCheckBox do begin
      Name:='KeyAltCheckBox';
      Parent:=KeyGroupBox;
      Caption:='Alt';
      Left:=KeyCtrlCheckBox.Left+KeyCtrlCheckBox.Width+10;
      Top:=KeyCtrlCheckBox.Top;
      Height:=20;
      Width:=KeyCtrlCheckBox.Width;
      Visible:=true; 
    end;

    KeyShiftCheckBox:=TCheckBox.Create(Self);
    with KeyShiftCheckBox do begin
      Name:='KeyShiftCheckBox';
      Parent:=KeyGroupBox;
      Caption:='Shift';
      Left:=KeyAltCheckBox.Left+KeyAltCheckBox.Width+10;
      Top:=KeyCtrlCheckBox.Top;
      Height:=20;
      Width:=KeyCtrlCheckBox.Width;
      Visible:=true; 
    end;

    KeyComboBox:=TComboBox.Create(Self);
    with KeyComboBox do begin
      Name:='KeyComboBox';
      Parent:=KeyGroupBox;
      Left:=KeyShiftCheckBox.Left+KeyShiftCheckBox.Width+10;
      Top:=KeyCtrlCheckBox.Top;
      Width:=190;
      Items.BeginUpdate;
      Items.Add('none');
      for i:=1 to 145 do begin
        s:=KeyAndShiftStateToStr(i,[]);
        if lowercase(copy(s,1,5))<>'word(' then
          Items.Add(s);
      end;
      Items.EndUpdate;
      ItemIndex:=0;
      Visible:=true; 
    end;
    
    KeyGrabButton:=TButton.Create(Self);
    with KeyGrabButton do begin
      Parent:=KeyGroupBox;
      Left:=KeyComboBox.Left+KeyComboBox.Width+10;
      Top:=KeyCtrlCheckBox.Top;
      Width:=150;
      Height:=25;
      Caption:='Grab Key';
      Name:='KeyGrabButton';
      OnClick:=@KeyGrabButtonClick;
      Visible:=true; 
    end;

    MacrosGroupbox:=TGroupbox.Create(Self);
    with MacrosGroupbox do begin
      Name:='MacrosGroupbox';
      Parent:=Self;
      Left:=KeyGroupBox.Left;
      Top:=KeyGroupBox.Top+KeyGroupBox.Height+10;
      Width:=KeyGroupBox.Width;
      Height:=Self.ClientHeight-50-Top;
      Caption:='Macros';
      Visible:=true; 
    end;
    
    MacrosListbox:=TListbox.Create(Self);
    with MacrosListbox do begin
      Name:='MacrosListbox';
      Parent:=MacrosGroupbox;
      SetBounds(5,5,MacrosGroupbox.ClientWidth-120,
                   MacrosGroupbox.ClientHeight-30);
      Visible:=true; 
    end;
    
    MacrosInsert:=TButton.Create(Self);
    with MacrosInsert do begin
      Name:='MacrosInsert';
      Parent:=MacrosGroupbox;
      SetBounds(MacrosGroupbox.ClientWidth-90,5,70,25);
      Caption:='Insert';
      OnClick:=@MacrosInsertClick;
      Visible:=true; 
    end;
    
    OkButton:=TButton.Create(Self);
    with OkButton do begin
      Name:='OkButton';
      Parent:=Self;
      SetBounds(270,Self.ClientHeight-40,100,25);
      Caption:='Ok';
      OnClick:=@OkButtonClick;
      Visible:=true;
    end;
    
    CancelButton:=TButton.Create(Self);
    with CancelButton do begin
      Name:='CancelButton';
      Parent:=Self;
      SetBounds(390,OkButton.Top,100,25);
      Caption:='Cancel';
      OnClick:=@CancelButtonClick;
      Visible:=true;
    end;
  end;
  fOptions:=TExternalToolOptions.Create;
end;

destructor TExternalToolOptionDlg.Destroy;
begin
  fOptions.Free;
  inherited Destroy;
end;

procedure TExternalToolOptionDlg.SaveToOptions;
begin
  fOptions.Title:=TitleEdit.Text;
  fOptions.Filename:=FilenameEdit.Text;
  fOptions.CmdLineParams:=ParametersEdit.Text;
  fOptions.WorkingDirectory:=WorkingDirEdit.Text;
  fOptions.Key:=StrToVKCode(KeyComboBox.Text);
  fOptions.Shift:=[];
  if fOptions.Key<>VK_UNKNOWN then begin
    if KeyCtrlCheckBox.Checked then include(fOptions.fShift,ssCtrl);
    if KeyAltCheckBox.Checked then include(fOptions.fShift,ssAlt);
    if KeyShiftCheckBox.Checked then include(fOptions.fShift,ssShift);
  end;
end;

procedure TExternalToolOptionDlg.LoadFromOptions;
begin
  TitleEdit.Text:=fOptions.Title;
  FilenameEdit.Text:=fOptions.Filename;
  ParametersEdit.Text:=fOptions.CmdLineParams;
  WorkingDirEdit.Text:=fOptions.WorkingDirectory;
  SetComboBox(KeyComboBox,KeyAndShiftStateToStr(fOptions.Key,[]));
  KeyCtrlCheckBox.Checked:=(ssCtrl in fOptions.Shift);
  KeyShiftCheckBox.Checked:=(ssShift in fOptions.Shift);
  KeyAltCheckBox.Checked:=(ssAlt in fOptions.Shift);
end;

procedure TExternalToolOptionDlg.OkButtonClick(Sender: TObject);
begin
  if (TitleEdit.Text='') or (FilenameEdit.Text='') then begin
    MessageDlg('Title and Filename required',
                  'A valid tool needs at least a title and a filename.',
                  mtError, [mbCancel], 0);
    exit;
  end;
  SaveToOptions;
  ModalResult:=mrOk;
end;

procedure TExternalToolOptionDlg.CancelButtonClick(Sender: TObject);
begin
  ModalResult:=mrCancel;
end;

procedure TExternalToolOptionDlg.KeyGrabButtonClick(Sender: TObject);
begin
  ActivateGrabbing(1);
end;

procedure TExternalToolOptionDlg.SetOptions(TheOptions: TExternalToolOptions);
begin
  if fOptions=TheOptions then exit;
  fOptions.Assign(TheOptions);
  LoadFromOptions;
end;

procedure TExternalToolOptionDlg.SetTransferMacros(
  TransferMacroList: TTransferMacroList);
begin
  if fTransferMacros=TransferMacroList then exit;
  fTransferMacros:=TransferMacroList;
  if MacrosListbox=nil then exit;
  FillMacroList;
end;

procedure TExternalToolOptionDlg.FillMacroList;
var i: integer;
begin
  MacrosListbox.Items.BeginUpdate;
  MacrosListbox.Items.Clear;
  if fTransferMacros<>nil then begin
    for i:=0 to fTransferMacros.Count-1 do begin
      if fTransferMacros[i].MacroFunction=nil then begin
        MacrosListbox.Items.Add('$('+fTransferMacros[i].Name+') - '
                    +fTransferMacros[i].Description);
      end else begin
        MacrosListbox.Items.Add('$'+fTransferMacros[i].Name+'() - '
                    +fTransferMacros[i].Description);
      end;
    end;
  end;
  MacrosListbox.Items.EndUpdate;
end;

procedure TExternalToolOptionDlg.SetComboBox(
  AComboBox: TComboBox; const AValue: string);
var i: integer;
begin
  i:=AComboBox.Items.IndexOf(AValue);
  if i>=0 then
    AComboBox.ItemIndex:=i
  else begin
    AComboBox.Items.Add(AValue);
    AComboBox.ItemIndex:=AComboBox.Items.IndexOf(AValue);
  end;
end;

procedure TExternalToolOptionDlg.DeactivateGrabbing;
var i: integer;
begin
  if GrabbingKey=0 then exit;
  // enable all components
  for i:=0 to ComponentCount-1 do begin
    if (Components[i] is TWinControl) then
      TWinControl(Components[i]).Enabled:=true;
  end;
  if GrabbingKey=1 then
    KeyGrabButton.Caption:='Grab Key';
  GrabbingKey:=0;
end;

procedure TExternalToolOptionDlg.ActivateGrabbing(AGrabbingKey: integer);
var i: integer;
begin
  if GrabbingKey>0 then exit;
  GrabbingKey:=AGrabbingKey;
  if GrabbingKey=0 then exit;
  // disable all components
  for i:=0 to ComponentCount-1 do begin
    if (Components[i] is TWinControl) then begin
      if ((GrabbingKey=1) and (Components[i]<>KeyGrabButton)
      and (Components[i]<>KeyGroupBox)) then
        TWinControl(Components[i]).Enabled:=false;
    end;
  end;
  if GrabbingKey=1 then
    KeyGrabButton.Caption:='Please press a key ...'
end;

procedure TExternalToolOptionDlg.FormKeyUp(Sender: TObject; var Key: Word;
  Shift:TShiftState);
begin
  //writeln('TExternalToolOptionDlg.FormKeyUp Sender=',Classname
  //   ,' Key=',Key,' Ctrl=',ssCtrl in Shift,' Shift=',ssShift in Shift
  //   ,' Alt=',ssAlt in Shift,' AsString=',KeyAndShiftStateToStr(Key,Shift)
  //   );
  if Key in [VK_CONTROL, VK_SHIFT, VK_LCONTROL, VK_RCONTROl,
             VK_LSHIFT, VK_RSHIFT] then exit;
  if (GrabbingKey in [1]) then begin
    if GrabbingKey=1 then begin
      KeyCtrlCheckBox.Checked:=(ssCtrl in Shift);
      KeyShiftCheckBox.Checked:=(ssShift in Shift);
      KeyAltCheckBox.Checked:=(ssAlt in Shift);
      SetComboBox(KeyComboBox,KeyAndShiftStateToStr(Key,[]));
    end;
    DeactivateGrabbing;
  end;
end;

procedure TExternalToolOptionDlg.MacrosInsertClick(Sender: TObject);
var i: integer;
  s: string;
begin
  i:=MacrosListbox.ItemIndex;
  if i<0 then exit;
  if fTransferMacros[i].MacroFunction=nil then
    s:='$('+fTransferMacros[i].Name+')'
  else
    s:='$'+fTransferMacros[i].Name+'()';
  ParametersEdit.Text:=ParametersEdit.Text+s;
end;

end.
