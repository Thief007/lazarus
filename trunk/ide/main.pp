{  $Id$  }
{
 /***************************************************************************
                          main.pp  -  Toolbar
                             -------------------
                   TMain is the application toolbar window.


                   Initial Revision  : Sun Mar 28 23:15:32 CST 1999


 ***************************************************************************/

/***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/
}
{$H+}
unit main;

{$mode objfpc}

interface

uses
  Classes, LclLinux, compiler, stdctrls, forms, buttons, menus, comctrls,
  Spin, project,sysutils, global,
  compileroptions, Controls, graphics, extctrls, Dialogs, dlgMEssage,
  Designer, process, idecomp, Find_dlg, FormEditor, AbstractFormEditor,
  CustomFormEditor, ObjectInspector, ControlSelection, PropEdits, UnitEditor;

const
  STANDARDBTNCOUNT = 50;

type

  TForm1 = class(TFORM)
    FontDialog1  : TFontDialog;
    ColorDialog1 : TColorDialog;
    FindDialog1  : TFindDialog;
    ToolBar1     : TToolBar;
    Toolbutton1  : TToolButton;
    Toolbutton2  : TToolButton;
    Toolbutton3  : TToolButton;
    Toolbutton4  : TToolButton;
    Pixmap1      : TPixmap;//used to assign the tspeedbutton its image
    Bitmap1      : TBitmap;
    SpeedButton1 : TSpeedButton;
    SpeedButton2 : TSpeedButton;
    SpeedButton3 : TSpeedButton;
    SpeedButton4 : TSpeedButton;
    SpeedButton5 : TSpeedButton;
    SpeedButton6 : TSpeedButton;
    SpeedButton7 : TSpeedButton;
    SpeedButton8 : TSpeedButton;
    ComboBox1 : TComboBox;
    Edit1: TEdit;
    SpinEdit1 : TSpinEdit;
    ListBox1 : TListBox;
    mnuMain: TMainMenu;

    mnuFile: TMenuItem;
    mnuEdit: TMenuItem; 
    mnuSearch: TMenuItem;
    mnuView: TMenuItem; 
    mnuProject: TMenuItem; 
    mnuEnvironment:TMenuItem;

    itmSeperator: TMenuItem;

    itmFileNew : TMenuItem;

    itmProjectNew: TMenuItem;
    itmProjectOpen: TMenuItem;
    itmProjectSave: TMenuItem;
    itmProjectBuild: TMenuItem;
    itmProjectRun: TMenuItem;

    itmFileNewForm : TMenuItem;
    itmFileOpen: TMenuItem;
    itmFileSave: TMenuItem; 
    itmFileSaveAs: TMenuItem; 
    itmFileSaveAll: TMenuItem; 
    itmFileClose: TMenuItem; 
    itmFileQuit: TMenuItem; 
    itmEditUndo: TMenuItem; 
    itmEditRedo: TMenuItem; 
    itmEditCut: TMenuItem; 
    itmEditCopy: TMenuItem; 
    itmEditPaste: TMenuItem; 
    itmSearchfind: TMenuItem;
    itmSearchFindAgain: TMenuItem;
    itmViewInspector: TMenuItem;
    itmViewProject: TMenuItem; 
    itmViewProjectOptions: TMenuItem;
    itmViewUnits : TMenuItem;
    itmViewCodeExplorer : TMenuItem;
    itmViewForms : TMenuItem;
    itmViewFile : TMenuItem;
    itmViewColors : TMenuItem;
    itmViewFont : TMenuItem;
    itmViewMessage : TMenuItem;
    itmViewCompilerSettings: TMenuItem;
    itmEnvironmentOptions: TMenuItem; 
    CheckBox1 : TCheckBox; 
//    Notebook1 : TTabbedNotebook;
    notebook1 : TNotebook;
    cmdTest: TButton;
    cmdTest2: TButton;
    LAbel2 : TLabel;
{ event handlers }
    procedure mnuNewFormClicked(Sender : TObject);
    procedure mnuOpenClicked(Sender : TObject);
    procedure mnuSaveClicked(Sender : TObject);
    procedure mnuSaveAsClicked(Sender : TObject);
    procedure mnuSaveAllClicked(Sender : TObject);
    procedure mnuCloseClicked(Sender : TObject);
    procedure mnuQuitClicked(Sender : TObject);
    procedure mnuViewInspectorClicked(Sender : TObject);
    procedure mnuViewCompilerSettingsClicked(Sender : TObject);
    Procedure mnuViewUnitsClicked(Sender : TObject);
    Procedure mnuViewFormsClicked(Sender : TObject);

    Procedure mnuToggleFormClicked(Sender : TObject);
    Procedure CodeorFormActivated(Sender : TObject);

    Procedure mnuViewColorClicked(Sender : TObject);
    Procedure mnuViewFontClicked(Sender : TObject);
    procedure mnuNewProjectClicked(Sender : TObject);
    procedure mnuOpenProjectClicked(Sender : TObject);
    procedure mnuSaveProjectClicked(Sender : TObject);
    procedure mnuBuildProjectClicked(Sender : TObject);
    procedure mnuRunProjectClicked(Sender : TObject);
    procedure mnuViewCodeExplorerClick(Sender : TObject);
    procedure mnuViewMessagesClick(Sender : TObject);
    procedure mnuSearchFindClicked(Sender : TObject);
    procedure mnuSearchFindAgainClicked(Sender : TObject);

    procedure MouseDownOnControl(Sender : TObject; Button: TMouseButton; Shift : TShiftState; X, Y: Integer);
    procedure MouseMoveOnControl(Sender : TObject; Shift : TShiftState; X, Y: Integer);
    procedure MouseUpOnControl(Sender : TObject; Button: TMouseButton; Shift : TShiftState; X, Y: Integer);
    procedure ControlClick(Sender : TObject);
    procedure MessageViewDblClick(Sender : TObject);

    function FindDesigner(ChildComponent:TComponent):TDesigner;
    procedure SelectOnlyThisComponent(AComponent:TComponent);
    procedure OIOnAddAvailableComponent(AComponent:TComponent; var Allowed:boolean);
    procedure OIOnSelectComponent(AComponent:TComponent);
  private
    FCodeLastActivated : Boolean; //used for toggling between code and forms
    FControlLastActivated : TObject;
    Function CreateSeperator : TMenuItem;
    Procedure SetBtnDefaults(Control : Pointer;I,Page : Integer);
    Function ReturnActiveUnitList : TUnitInfo;
    Procedure UpdateViewDialogs;
 protected
    procedure DoFind(Sender : TObject);

    procedure FormShow(Sender : TObject);
    procedure ButtonCLick(Sender : TObject);
    procedure ToolButtonCLick(Sender : TObject);
//    Procedure Paint; override;
    Function ReturnFormName(Source : TStringList) : String;

    Standardbtn : Array[1..STANDARDBTNCOUNT] of TSpeedbutton;

  public
    constructor Create(AOwner: TComponent); override; 
    procedure LoadMainMenu;
    Procedure FormKill(Sender : TObject);
    Procedure SetFlags(SLIst : TUnitInfo);
    Procedure SetName_Form(SList : TUnitInfo);

    procedure FormPaint(Sender : TObject);
    //these numbers are used to determine where the mouse was when the button was pressed
    MouseDownPos, MouseUpPos, LastMouseMovePos : TPoint;
    MouseDownControl: TObject;
    bpressed : Integer;
  end;




const
  CapLetters = ['A'..'Z'];
  SmallLetters = ['a'..'z'];
  Numbers = ['0'..'1'];

var
  Form1 : TForm1;
  FormEditor1 : TFormEditor;
  // this should be moved to FormEditor <...
  ObjectInspector1 : TObjectInspector;
  PropertyEditorHook1 : TPropertyEditorHook;
  // ...>
  SourceNotebook : TSourceNotebook;
  TagInc : Integer;


implementation

uses
  TestForm, ViewUnit_dlg,ViewForm_dlg, Math;

{ TForm1 }

constructor TForm1.Create(AOwner: TComponent);  
var
  Filename : String;
  S : TStream;
  i : Integer;
  R : TRect;
  IDEControl : pointer;
begin
  inherited Create(AOwner);

  Caption := Format('Lazarus Editor v 0.5- Lazarus path = %s    Highlight colors: %d , %d , %d ,%d ,%d',[Application.exename,clHighlight, clHighlighttext, clRed,clBlue,clYellow]);

  Left := 0;
  Top := 0;
  Width := Screen.Width-5;
  height := 125;
  Position:= poDesigned;
  Name := 'Form1';


  LoadMainMenu;

  MouseDownControl:=nil;

  Bitmap1 := TBitmap.Create;
  Bitmap1.Handle := CreatePixmapIndirect(@IMGOK_Check, ColorToRGB(clBtnFace));

{ ToolBar1 := TToolbar.Create(Self);
  with Toolbar1 do
  begin
    Parent := Self;
    Align := alTop;
    ShowCaptions := True;
    Height := 25;
    Left := 1;
    Top := 25;
    Width := ClientWidth;
    Show;
  end;
} 
  Notebook1 := TNotebook.Create(Self);
  Notebook1.Parent := Self;
  Notebook1.Align := alBottom;
  Notebook1.Left := 0;
//  Notebook1.Top :=50+ mnuBarMain.Top+MnuBarMain.Height + 2;
  Notebook1.Top :=50+ 2;
  Notebook1.Width := ClientWidth;
  Notebook1.Height := 100; //ClientHeight - Notebook1.Top;
  Notebook1.Pages.Strings[0] := 'Standard';
  Notebook1.Pages.Add('Additional');
  Notebook1.Pages.Add('Samples');
  Notebook1.Pages.Add('System');
  Notebook1.Pages.Add('Internet');
  Notebook1.PageIndex := 0;   // Set it to the first page
  Notebook1.Show;
  Notebook1.OnPageChanged := @ControlClick;
  Notebook1.Name := 'Notebook1';
  S := TFileStream.Create('./images/viewunits.xpm', fmOpenRead);
  try
    Pixmap1 := TPixmap.Create;
    Pixmap1.TransparentColor := clBtnFace;
    Pixmap1.LoadFromStream(S);
  finally
    S.Free;
  end;

  SpeedButton1 := TSpeedButton.Create(Self);
  with Speedbutton1 do
   Begin
    Parent := self;
    Enabled := True;
    Top := 25;
    OnClick := @mnuViewUnitsCLicked;
    Glyph := Pixmap1;
    Visible := True;
    Flat := False;
    Name := 'Speedbutton1';
   end;


  S := TFileStream.Create('./images/viewforms.xpm', fmOpenRead);
  try
    Pixmap1 := TPixmap.Create;
    Pixmap1.TransparentColor := clBtnFace;
    Pixmap1.LoadFromStream(S);
  finally
    S.Free;
  end;

  SpeedButton2 := TSpeedButton.Create(Self);
  with Speedbutton2 do
   Begin
    Parent := self;
    Enabled := True;
    Top := 25;
    Left := Speedbutton1.Left + 26;
    OnClick := @mnuViewFormsCLicked;
    Glyph := Pixmap1;
    Visible := True;
    Name := 'Speedbutton2';
   end;



  S := TFileStream.Create('./images/newunit.xpm', fmOpenRead);
  try
    Pixmap1 := TPixmap.Create;
    Pixmap1.TransparentColor := clBtnFace;
    Pixmap1.LoadFromStream(S);
  finally
    S.Free;
  end;

  SpeedButton3 := TSpeedButton.Create(Self);
  with Speedbutton3 do
   Begin
    Parent := self;
    Enabled := True;
    Top := 25;
    Left := Speedbutton2.Left + 26;
//    OnClick := @mnuNewCLicked;
    Glyph := Pixmap1;
    Visible := True;
    Name := 'Speedbutton3';
   end;

  S := TFileStream.Create('./images/openfile.xpm', fmOpenRead);
  try
    Pixmap1 := TPixmap.Create;
    Pixmap1.TransparentColor := clBtnFace;
    Pixmap1.LoadFromStream(S);
  finally
    S.Free;
  end;

  SpeedButton4 := TSpeedButton.Create(Self);
  with Speedbutton4 do
   Begin
    Parent := self;
    Enabled := True;
    Top := 25;
    Left := Speedbutton3.Left + 26;
    OnClick := @mnuOpenCLicked;
    Glyph := Pixmap1;
    Visible := True;
    Name := 'Speedbutton4';
   end;

  S := TFileStream.Create('./images/save.xpm', fmOpenRead);
  try
    Pixmap1 := TPixmap.Create;
    Pixmap1.TransparentColor := clBtnFace;
    Pixmap1.LoadFromStream(S);
  finally
    S.Free;
  end;

  SpeedButton5 := TSpeedButton.Create(Self);
  with Speedbutton5 do
   Begin
    Parent := self;
    Enabled := True;
    Top := 25;
    Left := Speedbutton4.Left + 26;
    OnClick := @mnuSaveCLicked;
    Glyph := Pixmap1;
    Visible := True;
    Name := 'Speedbutton5';
   end;

  S := TFileStream.Create('./images/saveall.xpm', fmOpenRead);
  try
    Pixmap1 := TPixmap.Create;
    Pixmap1.TransparentColor := clBtnFace;
    Pixmap1.LoadFromStream(S);
  finally
    S.Free;
  end;

  SpeedButton6 := TSpeedButton.Create(Self);
  with Speedbutton6 do
   Begin
    Parent := self;
    Enabled := True;
    Top := 25;
    Left := Speedbutton5.left + 26;
    OnClick := @mnuSaveAllCLicked;
    Glyph := Pixmap1;
    Visible := True;
    Name := 'Speedbutton6';
   end;

  S := TFileStream.Create('./images/toggleform.xpm', fmOpenRead);
  try
    Pixmap1 := TPixmap.Create;
    Pixmap1.TransparentColor := clBtnFace;
    Pixmap1.LoadFromStream(S);
  finally
    S.Free;
  end;

  SpeedButton7 := TSpeedButton.Create(Self);
  with Speedbutton7 do
   Begin
    Parent := self;
    Enabled := True;
    Top := 25;
    Left := Speedbutton6.Left + 26;
    OnClick := @mnuToggleFormCLicked;
    Glyph := Pixmap1;
    Visible := True;
    Name := 'Speedbutton7';
   end;

  S := TFileStream.Create('./images/newform.xpm', fmOpenRead);
  try
    Pixmap1 := TPixmap.Create;
    Pixmap1.TransparentColor := clBtnFace;
    Pixmap1.LoadFromStream(S);
  finally
    S.Free;
  end;

  SpeedButton8 := TSpeedButton.Create(Self);
  with Speedbutton8 do
   Begin
    Parent := self;
    Enabled := True;
    Top := 25;
    Left := Speedbutton7.Left + 26;
    OnClick := @mnuNewFormCLicked;
    Glyph := Pixmap1;
    Visible := True;
    Name := 'Speedbutton8';
   end;

  //start creating the components based on the TIDECOmponent classes
  I := 1;
  idecontrol := TIDEMouse.Create;
  SetBtnDefaults(idecontrol,i,0);
  inc(i);
  idecontrol := TIDEMenu.Create;
  SetBtnDefaults(idecontrol,I,0);
  inc(i);
  idecontrol := TIDEPopup.Create;
  SetBtnDefaults(idecontrol,I,0);
  inc(i);
  idecontrol := TIDEEdit.Create;
  SetBtnDefaults(idecontrol,I,0);
  inc(i);
  idecontrol := TIDELabel.Create;
  SetBtnDefaults(idecontrol,I,0);
  inc(i);
  idecontrol := TIDEButton.Create;
  SetBtnDefaults(idecontrol,I,0);
  inc(i);
  idecontrol := TIDEMemo.Create;
  SetBtnDefaults(idecontrol,I,0);
  inc(i);
  idecontrol := TIDECheckbox.Create;
  SetBtnDefaults(idecontrol,I,0);
  inc(i);
  idecontrol := TIDERadioButton.Create;
  SetBtnDefaults(idecontrol,I,0);
  inc(i);
  idecontrol := TIDEListbox.Create;
  SetBtnDefaults(idecontrol,I,0);
  inc(i);
  idecontrol := TIDEComboBox.Create;
  SetBtnDefaults(idecontrol,I,0);
  inc(i);

  //we want the mouse on the second tab too!
  SetBtnDefaults(ideCompList.Items[0],i,1);
  StandardBtn[i].Tag := 1;
  inc(i);
  idecontrol := TIDEBitbtn.Create;
  SetBtnDefaults(idecontrol,I,1);
  inc(i);
  idecontrol := TIDESpeedbutton.Create;
  SetBtnDefaults(idecontrol,I,1);
  inc(i);
  idecontrol := TIDENotebook.Create;
  SetBtnDefaults(idecontrol,I,1);
  inc(i);

  //we want the mouse on the second tab too!
  SetBtnDefaults(ideCompList.Items[0],i,2);
  StandardBtn[i].Tag := 1;
  inc(i);
  idecontrol := TIDESpinEdit.Create;
  SetBtnDefaults(idecontrol,I,2);
  inc(i);


  StandardBtn[1].Down := True;
  bpressed := 1;  //the speedbutton that's pressed

{  This spin edit code crashes}
{  Setting the parent is what does it}

{   SpinEdit1 := TSpinEdit.Create(self);
   with SpinEdit1 do
     Begin
    Parent := Notebook1.Page[0];
    Left := 350;
    Width := 100;
    Height := 25;
//    Parent := Self;
    Visible := True;
//    OnClick := @ButtonClick;
      end;
 }

{  cmdTest := TButton.Create(Self);
  with cmdTest do
  begin
    Left := 350;
    Width := 100;
    Height := 25;
    Parent := Notebook1.Page[0];
//    Parent := Self;
    Caption := 'TestForm / Editor';
    Visible := True;
    OnClick := @ButtonClick; 
  end;
 }
{  ListBox1 := TListBox.Create(Self);
  ListBox1.Parent:= Notebook1.Page[1];
  ListBox1.Left := 20;
  ListBox1.Top := 20;
  ListBox1.Height := 100;
  ListBox1.Width := 100;
  ListBox1.Align:= alClient;
  ListBox1.Items.Add('Hello');
  ListBox1.Items.Add('world.');
  ListBox1.Items.Add('It''s just a perfect day.');
  ListBox1.Visible:= true;

 }


  if Assigned(Toolbar1) then
  begin
  Assert(False, 'Trace:*1*');
  Toolbutton1 := TToolButton.Create(Toolbar1);
  with ToolButton1 do
    begin
     Assert(False, 'Trace:SETTING PARENT');
      Parent := Toolbar1;
      Caption := '1';   
      Style := tbsButton;
      Top := 1;
      Left := 1;
      OnClick := @Toolbuttonclick;
      Show;
    end;
  
    Assert(False, 'Trace:*2*');
    Toolbutton2 := TToolButton.Create(Toolbar1);
    with ToolButton2 do
    begin
      Assert(False, 'Trace:SETTING PARENT');
      Parent := Toolbar1;
      Caption := '2';   
      Style := tbsButton;
  //    Top := 1;
      Left := Toolbutton1.Left+1;
      Show;
    end;
  
    Assert(False, 'Trace:*3*');
    Toolbutton3 := TToolButton.Create(Toolbar1);
    with ToolButton3 do
    begin
      Assert(False, 'Trace:SETTING PARENT');
      Parent := Toolbar1;
      Caption := '3';   
      Style := tbsButton;
  //    Top := 1;
      Left := 1;
      Show;
    end;
  
    Assert(False, 'Trace:*4*');
    Toolbutton4 := TToolButton.Create(Toolbar1);
    with ToolButton4 do 
    begin
      Assert(False, 'Trace:SETTING PARENT');
      Parent := Toolbar1;
      Caption := '4';   
      Style := tbsButton;
  //    Top := 1;
  //    Left := 1;
      Show;
    end;
  
    ComboBox1 := TComboBox.Create(Self);
    with ComboBox1 do
    begin
      Assert(False, 'Trace:SETTING PARENT');
      Parent := Toolbar1;
      Items.Add('Item1');
      Items.Add('Item2');
      Items.Add('Item3');
      Items.Add('Item4');
      Items.Add('Item5');
      Items.Add('Item6');
      ItemIndex := 0;
  //    Top := 1;
  //    Left := 1;
      Show;
    end;
  end;  //If toolbar1 assigned
  
  FontDialog1 := TFontDialog.Create(self);
  ColorDialog1 := TColorDialog.Create(self);
  FindDialog1 := TFindDialog.Create(self);
  FindDialog1.OnFind := @DoFind;

  //?? dont need these handlers.
  // Form will kill itself
  //OnDestroy := @FormKill;
  //Onpaint := @FormPaint;


  Project1 := TProject.Create;
  Self.OnShow := @FormShow;
  MessageDlg := TMessageDlg.Create(self);
  MessageDlg.Caption := 'Compiler Messages';
  MessageDlg.MessageView.OnDblClick := @MessageViewDblClick;

  Compiler1 := TCompiler.Create;
  Compiler1.OutputString := @Messagedlg.Add;

{ Create other forms }
  ObjectInspector1 := TObjectInspector.Create(Self);
  ObjectInspector1.SetBounds(0,Top+Height+5,230,600);
  ObjectInspector1.OnAddAvailComponent:=@OIOnAddAvailableComponent;
  ObjectInspector1.OnSelectComponentInOI:=@OIOnSelectComponent;
  PropertyEditorHook1:=TPropertyEditorHook.Create;
  ObjectInspector1.PropertyEditorHook:=PropertyEditorHook1;
  ObjectInspector1.Show;

  FormEditor1 := TFormEditor.Create;
  FormEditor1.Obj_Inspector := ObjectInspector1;

  SourceNotebook := TSourceNotebook.Create(self);
  SourceNotebook.OnActivate := @CodeorFormActivated;
  itmFileSave.OnClick := @SourceNotebook.SaveClicked;
  itmFileSaveAs.OnClick := @SourceNotebook.SaveAsClicked;
  itmFileSaveAll.OnClick := @SourceNotebook.SaveAllClicked;
  itmFileClose.OnClick := @SourceNotebook.CloseClicked;
  itmFileNew.OnClick := @SourceNotebook.NewClicked;
  itmFileOpen.OnClick := @SourceNotebook.OpenClicked;
  SpeedButton4.OnClick := @SourceNotebook.OpenClicked;
  SpeedButton5.OnClick := @SourceNotebook.SaveClicked;
  SpeedButton6.OnClick := @SourceNotebook.SaveAllClicked;

end;

procedure TForm1.OIOnAddAvailableComponent(AComponent:TComponent;
var Allowed:boolean);
begin
  Allowed:=(not (AComponent is TGrabber));
end;

procedure TForm1.OIOnSelectComponent(AComponent:TComponent);
begin
  SelectOnlyThisComponent(AComponent);
end;

Procedure TForm1.ToolButtonCLick(Sender : TObject);
Begin
  Assert(False, 'Trace:TOOL BUTTON CLICK!');


{if ComboBox1.Parent = Toolbar1 then
  Begin
   ComboBox1.Parent := Form1;
   ComboBox1.Left := 25;
   ComboBox1.top := 25;
  end
  else
   ComboBox1.Parent := Toolbar1;}

end;

Procedure TForm1.FormPaint(Sender : TObject);
begin

end;


procedure TForm1.ButtonClick(Sender : TObject);
Begin
End;

{------------------------------------------------------------------------------}
procedure TForm1.FormShow(Sender : TObject);
Begin

end;

procedure TForm1.FormKill(Sender : TObject);
Begin
Assert(False, 'Trace:DESTROYING FORM');
End;

{------------------------------------------------------------------------------}
procedure TForm1.LoadMainMenu;
var

fContext : Integer;
R : TRect;
begin



//--------------
// The Menu
//--------------

  mnuMain := TMainMenu.Create(Self);
  Menu := mnuMain;

//--------------
// Main menu
//--------------

  mnuFile := TMenuItem.Create(Self);
  mnuFile.Caption := '&File';
  mnuMain.Items.Add(mnuFile);

  mnuEdit := TMenuItem.Create(Self);
  mnuEdit.Caption := '&Edit';
  mnuMain.Items.Add(mnuEdit);

  mnuSearch := TMenuItem.Create(Self);
  mnuSearch.Caption := '&Search';
  mnuMain.Items.Add(mnuSearch);

  mnuView := TMenuItem.Create(Self);
  mnuView.Caption := '&View';
  mnuMain.Items.Add(mnuView);

  mnuProject := TMenuItem.Create(Self);
  mnuProject.Caption := '&Project';
  mnuMain.Items.Add(mnuProject);

  mnuEnvironment := TMenuItem.Create(Self);
  mnuEnvironment.Caption := 'E&nvironment';
  mnuMain.Items.Add(mnuEnvironment);


//--------------
// File
//--------------

  
  itmFileNew := TMenuItem.Create(Self);
  itmFileNew.Caption := 'New Unit';
//  itmFileNew.OnClick := @mnuNewClicked;
  mnuFile.Add(itmFileNew);

  itmFileNewForm := TMenuItem.Create(Self);
  itmFileNewForm.Caption := 'New Form';
  itmFileNewForm.OnClick := @mnuNewFormClicked;
  mnuFile.Add(itmFileNewForm);

  itmFileOpen := TMenuItem.Create(Self);
  itmFileOpen.Caption := 'Open';
  itmFileOpen.OnClick := @mnuOpenClicked;
  mnuFile.Add(itmFileOpen);

  itmFileSave := TMenuItem.Create(Self);
  itmFileSave.Caption := 'Save';
  mnuFile.Add(itmFileSave);

  itmFileSaveAs := TMenuItem.Create(Self);
  itmFileSaveAs.Caption := 'Save As';
  mnuFile.Add(itmFileSaveAs);

  itmFileSaveAll := TMenuItem.Create(Self);
  itmFileSaveAll.Caption := 'Save All';
  mnuFile.Add(itmFileSaveAll);


  itmFileClose := TMenuItem.Create(Self);
  itmFileClose.Caption := 'Close';
  itmFileClose.Enabled := False;
  mnuFile.Add(itmFileClose);

  mnuFile.Add(CreateSeperator);

  itmFileQuit := TMenuItem.Create(Self);
  itmFileQuit.Caption := 'Quit';
  itmFileQuit.OnClick := @mnuQuitClicked;
  mnuFile.Add(itmFileQuit);

//--------------
// Edit
//--------------


  itmEditUndo := TMenuItem.Create(nil);
  itmEditUndo.Caption := 'Undo';
  mnuEdit.Add(itmEditUndo);

  itmEditRedo := TMenuItem.Create(nil);
  itmEditRedo.Caption := 'Redo';
  mnuEdit.Add(itmEditRedo);

  mnuEdit.Add(CreateSeperator);

  itmEditCut  := TMenuItem.Create(nil);
  itmEditCut.Caption := 'Cut';
  mnuEdit.Add(itmEditCut);

  itmEditCopy := TMenuItem.Create(nil);
  itmEditCopy.Caption := 'Copy';
  mnuEdit.Add(itmEditCopy);

  itmEditPaste := TMenuItem.Create(nil);
  itmEditPaste.Caption := 'Paste';
  mnuEdit.Add(itmEditPaste);


//--------------
// Search
//--------------
  itmSearchFind := TMenuItem.Create(nil);
  itmSearchFind.caption := 'Find';
  itmSearchFind.OnClick := @mnuSearchFindClicked;
  mnuSearch.add(itmSearchFind);

  itmSearchFindAgain := TMenuItem.Create(nil);
  itmSearchFindAgain.caption := 'Find &Again';
  itmSearchFindAgain.OnClick := @mnuSearchFindAgainClicked;
  itmSearchFindAgain.Enabled := False;
  mnuSearch.add(itmSearchFindAgain);
//--------------
// View
//--------------

  itmViewInspector := TMenuItem.Create(Self);
  itmViewInspector.Caption := 'Object Inspector';
  itmViewInspector.OnClick := @mnuViewInspectorClicked;
  mnuView.Add(itmViewInspector);

  itmViewProject  := TMenuItem.Create(Self);
  itmViewProject.Caption := 'Project Explorer';
  mnuView.Add(itmViewProject);

  mnuView.Add(CreateSeperator);

  itmViewProjectOptions := TMenuItem.Create(Self);
  itmViewProjectOptions.Caption := 'Project Options';
  mnuView.Add(itmViewProjectOptions);

  itmViewCompilerSettings := TMenuItem.Create(Self);
  itmViewCompilerSettings.Caption := 'Compiler Options';
  itmViewCompilerSettings.OnClick := @mnuViewCompilerSettingsClicked;
  mnuView.Add(itmViewCompilerSettings);
  
  itmViewCodeExplorer := TMenuItem.Create(Self);
  itmViewCodeExplorer.Caption := 'Code Explorer';
  itmViewCodeExplorer.OnClick := @mnuViewCodeExplorerClick;
  mnuView.Add(itmViewCodeExplorer);

  mnuView.Add(CreateSeperator);

  itmViewUnits := TMenuItem.Create(Self);
  itmViewUnits.Caption := 'Units...';
  itmViewUnits.OnClick := @mnuViewUnitsClicked;
  mnuView.Add(itmViewUnits);

  itmViewForms := TMenuItem.Create(Self);
  itmViewForms.Caption := 'Forms...';
  itmViewForms.OnClick := @mnuViewFormsClicked;
  mnuView.Add(itmViewForms);

  itmViewColors := TMenuItem.Create(Self);
  itmViewCOlors.Caption := 'Color Dialog';
  itmViewColors.OnClick := @mnuViewColorClicked;
  mnuView.Add(itmViewColors);


  itmViewFont := TMenuItem.Create(Self);
  itmViewFont.Caption := 'Font...';
  itmViewFont.OnClick := @mnuViewFontClicked;
  mnuView.Add(itmViewFont);

  mnuView.Add(CreateSeperator);


  itmViewMEssage := TMenuItem.Create(Self);
  itmViewMessage.Caption := 'Messages';
  itmViewMessage.OnClick := @mnuViewMessagesClick;
  mnuView.Add(itmViewMessage);


//--------------
// Project
//--------------

  itmProjectNew := TMenuItem.Create(Self);
  itmProjectNew.Caption := 'New Project';
  itmProjectNew.OnClick := @mnuNewProjectClicked;
  mnuProject.Add(itmProjectNew);

  itmProjectOpen := TMenuItem.Create(Self);
  itmProjectOpen.Caption := 'Open Project';
  itmProjectOpen.OnClick := @mnuOpenProjectClicked;
  mnuProject.Add(itmProjectOpen);

  itmProjectSave := TMenuItem.Create(Self);
  itmProjectSave.Caption := 'Save Project';
  itmProjectSave.OnClick := @mnuSaveProjectClicked;
  mnuProject.Add(itmProjectSave);


  mnuProject.Add(CreateSeperator);

  itmProjectBuild := TMenuItem.Create(Self);
  itmProjectBuild.Caption := 'Build';
  itmProjectBuild.OnClick := @mnuBuildProjectClicked;
  itmProjectBuild.Enabled := False;
  mnuProject.Add(itmProjectBuild);

  itmProjectRun := TMenuItem.Create(Self);
  itmProjectRun.Caption := 'Run';
  itmProjectRun.OnClick := @mnuRunProjectClicked;
  mnuProject.Add(itmProjectRun);

//--------------
// Environment
//--------------

  itmEnvironmentOptions := TMenuItem.Create(nil);
  itmEnvironmentOptions.Caption := 'Options';
  mnuEnvironment.Add(itmEnvironmentOptions);



end;
{------------------------------------------------------------------------------}
{------------------------------------------------------------------------------}
{------------------------------------------------------------------------------}
{PRIVATE METHOD}

procedure TForm1.SetBtnDefaults(Control : Pointer; I,Page : Integer);
begin
  ideCompList.Add(Control);
  StandardBtn[i] := TIDEMouse(Control).Speedbutton(self,Notebook1.page[Page]);
  if I > 1 then
  StandardBtn[i].left := (Notebook1.page[Page].ControlCount-1)*26
  else
  StandardBtn[i].left := 0;  //the mouse

  StandardBtn[i].Top := 2;
  StandardBtn[i].Tag := I;
  StandardBtn[i].OnClick := @controlclick;
end;

function TForm1.CreateSeperator : TMenuItem;
begin
  itmSeperator := TMenuItem.Create(Self);
  itmSeperator.Caption := '-';
  Result := itmSeperator;
end;

function TForm1.ReturnActiveUnitList : TUnitInfo;
var
  I : Integer;
  SList : TUnitInfo;
  TempNum : Integer;
begin

end;


{------------------------------------------------------------------------------}
{Fills the View Units dialog and the View Forms dialog}
{------------------------------------------------------------------------------}

Procedure TForm1.UpdateViewDialogs;
Var
I : Integer;
SList : TUnitInfo;
Begin
ViewUnits1.Listbox1.Items.Clear;
ViewForms1.Listbox1.Items.Clear;
For I := 0 to Project1.UnitList.Count -1 do
   Begin
    SList := TUnitInfo(Project1.UnitList.Items[I]);
    ViewUnits1.Listbox1.Items.Add(SList.Name);
    if SList.FormName <> '' then
    ViewForms1.Listbox1.Items.Add(SList.FormName);
   end;
End;



{------------------------------------------------------------------------------}
{------------------------------------------------------------------------------}
{------------------------------------------------------------------------------}
{------------------------------------------------------------------------------}






Procedure TForm1.SetFlags(SList : TUnitInfo);
var
Texts : String;
tempNUm1, TempNUm2 : Integer;
Begin
      Assert(False, 'Trace:SList.filename = '+SList.Filename);
      Texts := Uppercase(ExtractFileName(SList.Filename));
      Assert(False, 'Trace:Texts := '+Texts);
      tempNum1 := pos('.',Texts);
      Assert(False, 'Trace:Tempnum1 = '+inttostr(tempnum1));
      Texts := Copy(Texts,tempNum1+1,Length(Texts)-tempNum1);
      Assert(False, 'Trace:Texts = '+Texts);
      if (Texts = 'PP') or (Texts = 'PAS') then
        SList.Flags := pfSource
      else
      if (Texts = 'LPR') or (Texts = 'DPR') then
        SList.Flags := pfProject
      else
       SList.Flags := pfNone;
{debugging}
if SList.Flags = pfProject then
   Assert(False, 'Trace:' + SLIst.FileName+' is set to pfProject')
else
if SList.Flags = pfSource then
   Assert(False, 'Trace:' + SLIst.FileName+'  is set to pfSource')
else
if SList.Flags = pfNone then
   Assert(False, 'Trace:' + SLIst.FileName+'  is set to pfNone');

end;

Procedure TForm1.SetName_Form(SList : TUnitInfo);
Begin
  if (SList.flags = pfSource) or (SList.Flags = pfProject) then
     Begin
     Assert(False, 'Trace:filename is '+SList.Filename);
     Assert(False, 'Trace:pos is '+inttostr(pos('.',SList.Filename)));
     if pos('.',SList.Filename) > 0 then
     SList.Name := Copy(ExtractFileName(SList.Filename),1,pos('.',ExtractFileName(SList.Filename))-1)
     else
     SList.Name := ExtractFileName(SList.Filename);

     Assert(False, 'Trace:Name of new unit is '+SList.Name);
     end;

  if SList.flags = pfSource then
     Begin
     SList.FormName := ReturnFormname(SList.Source);
     if SList.FormName <> '' then
        SList.Flags := pfForm;
     end;
  Assert(False, 'Trace:Exiting SetName_Form');
end;

procedure TForm1.mnuSaveClicked(Sender : TObject);
begin
//this is no longer used.  TSourceNotebook.SaveClicked is called
end;

{------------------------------------------------------------------------------}

Procedure TForm1.mnuSaveAsClicked(Sender : TObject);
Begin
//this is no longer used.  TSourceNotebook.SaveAsClicked is called
end;

Procedure TForm1.mnuSaveAllClicked(Sender : TObject);
Begin
//this is no longer used.  TSourceNotebook.SaveAllClicked is called

End;


Procedure TForm1.mnuToggleFormClicked(Sender : TObject);
Begin
writeln('Toggle form clicked');

if FCodeLastActivated then
   SourceNotebook.DisplayFormforActivePage
   else
   SourceNotebook.DisplayCodeforControl(FControlLastActivated);
end;


Procedure TForm1.CodeorFormActivated(Sender : TObject);
Begin
FCodeLastActivated := (TForm(Sender) = TForm(SourceNotebook));
if FCodeLastActivated then Writeln('TRUE') else Writeln('False');

FControlLastActivated := Sender;

end;


{
------------------------------------------------------------------------
------------------------------------------------------------------------
-------------------ControlClick-----------------------------------------
------------------------------------------------------------------------
------------------------------------------------------------------------
}

Procedure TForm1.ControlClick(Sender : TObject);
var
  Page : Integer;
  I : Integer;
begin
  if bpressed > -1 then
  if (bpressed = 1) and (sender <> Notebook1) then
    // 1 is really just the FIRST one on the notebook page.
    Begin
    //raise the 1st button on that page.
    Page := Notebook1.Pageindex;
    For I := 0 to Notebook1.Page[Page].ControlCount-1 do
       Begin
         if (Notebook1.PAge[page].Controls[i] is TSpeedButton) then
	     Begin
              TSpeedButton(Notebook1.PAge[page].Controls[i]).Down := False;
              break;
             end;
       end;

   end
   else
   StandardBtn[bpressed].Down := False;

if (Sender = Notebook1) then
begin
bpressed := 1;
end
else
bpressed := tspeedbutton(Sender).Tag;

if bpressed = 1 then
   begin
    //depress the 1st button on that page.
   Page := Notebook1.Pageindex;
   For I := 0 to Notebook1.Page[Page].ControlCount-1 do
       Begin
         if (Notebook1.PAge[page].Controls[i] is TSpeedButton) then
	     Begin
              TSpeedButton(Notebook1.PAge[page].Controls[i]).Down := True;
              Break;
             end;
      end;
   end
   else
   StandardBtn[bpressed].Down := True;

end;


function TForm1.FindDesigner(ChildComponent:TComponent):TDesigner;
begin
  if ChildComponent is TForm then
    Result:=TDesigner(TForm(ChildComponent).Designer)
  else if Assigned(ChildComponent.Owner)
  and (ChildComponent.Owner is TForm) then
    Result:=TDesigner(TForm(ChildComponent.Owner).Designer)
  else
    Result:=nil;
end;

procedure TForm1.SelectOnlyThisComponent(AComponent:TComponent);
var
  CurDesigner:TDesigner;
begin
  // select control in Designer
  CurDesigner:=FindDesigner(AComponent);
  if (CurDesigner<>nil) then begin
    CurDesigner.ControlSelection.Clear;
    CurDesigner.ControlSelection.Add(TControl(AComponent));
  end;
  FormEditor1.ClearSelected;
  // this will automatically inform the object inspector
  FormEditor1.AddSelected(AComponent);
end;

{------------------------------------------------------------------------------}
{------------------------------------------------------------------------------}
{
   Currently Unused !
          Used when we a control is clicked.  This is used
            to update the Object Inspector.
}
{------------------------------------------------------------------------------}
{------------------------------------------------------------------------------}
{------------------------------------------------------------------------------}
{Procedure TForm1.ClickOnControl(Sender : TObject);
// We clicked on the form.  Let's see what the active selection is in the IDE
// control bar. If it's the pointer, then we set the
// FormEditor1.SelectedComponents to Sender,
// otherwise we drop a control and call the CreateComponent function.
var
  ParentCI, NewCI : TComponentInterface;
  CurDesigner:TDesigner;
  NewLeft, NewTop, NewWidth, NewHeight : Integer;
Begin
  if BPressed = 1 then
  Begin //mouse button pressed.
    FormEditor1.ClearSelected;
    Writeln('Clicked on the control!!!!!  Control name is '+TControl(sender).name);
    // this will automatically inform the object inspector
    FormEditor1.AddSelected(TComponent(Sender));
  end
  else
  Begin  //add a new control
    ParentCI:=TComponentInterface(FormEditor1.FindComponent(TComponent(Sender)));
    if Assigned(ParentCI) then begin
      NewLeft:=Min(MouseDownPos.X,MouseUpPos.X);
      NewWidth:=Abs(MouseUpPos.X-MouseDownPos.X);
      NewTop:=Min(MouseDownPos.Y,MouseUpPos.Y);
      NewHeight:=Abs(MouseUpPos.Y-MouseDownPos.Y);
      NewCI := TComponentInterface(FormEditor1.CreateComponent(ParentCI,
        TComponentClass(TIdeComponent(ideComplist.items[bpressed-1]).ClassType)
        ,NewLeft,NewTop,NewWidth,NewHeight));
      NewCI.SetPropByName('Visible',True); //Control).Visible := True;

      //set the ONCLICK event so we know when the control is selected;
      TControl(NewCI.Control).OnClick := @ClickOnControl;

      if NewCI.Control is TControl then begin
        NewCI.SetPropByName('OnClick',@ClickOnControl);
        // select form in Designer
        if ParentCI.Control is TForm then
          CurDesigner:=TDesigner(TForm(ParentCI.Control).Designer)
        else if Assigned(ParentCI.Control.Owner)
        and (ParentCI.Control.Owner is TForm) then
          CurDesigner:=TDesigner(TForm(ParentCI.Control.Owner).Designer)
        else
          CurDesigner:=nil;
        if (CurDesigner<>nil) then begin
          CurDesigner.ControlSelection.Clear;
          CurDesigner.ControlSelection.Add(TControl(NewCI.Control));
        end;
      end;
    end;
  end;

  ControlClick(Notebook1);  //this resets it to the mouse.
end;}

{------------------------------------------------------------------------------}
{------------------------------------------------------------------------------}
{
          Used when we click on a control that was created.
                  This can be used to detect when
                 a control is dropped onto a form
}
{------------------------------------------------------------------------------}
{------------------------------------------------------------------------------}
{------------------------------------------------------------------------------}
procedure TForm1.MouseDownOnControl(Sender : TObject; Button: TMouseButton;
Shift : TShiftState; X, Y: Integer);
Begin
  if GetCaptureGrabber<>nil then exit;

  MouseDownPos.X := X;
  MouseDownPos.Y := Y;
  if not (Sender is TCustomForm) then begin
    inc(MouseDownPos.X,TControl(Sender).Left);
    inc(MouseDownPos.Y,TControl(Sender).Top);
  end;
  MouseDownControl:=Sender;
  LastMouseMovePos:=MouseDownPos;
  Writeln(TComponent(Sender).Name+'.OnMouseDown at '+inttostr(MouseDownPos.x)
    +','+inttostr(MouseDownPos.Y)+' x='+IntToStr(x));

  if BPressed = 1 then
  Begin //mouse pointer button pressed.
    if not (Sender is TCustomForm) then begin
      SelectOnlyThisComponent(TComponent(Sender));
    end;
  end;
End;

procedure TForm1.MouseMoveOnControl(Sender : TObject;
Shift : TShiftState; X, Y: Integer);
var
  CurDesigner: TDesigner;
  CaptureGrabber:TGrabber;
Begin
  CaptureGrabber:=GetCaptureGrabber;
  if CaptureGrabber<>nil then begin
    CaptureGrabber.CaptureMouseMove(TControl(Sender),Shift,X,Y);
  end else begin
    CurDesigner:=FindDesigner(TComponent(Sender));
    if Assigned(MouseDownControl) then begin
      if BPressed = 1 then begin
        // mouse pointer button pressed
        if not (Sender is TCustomForm) then begin
          // move selection
          if Assigned(CurDesigner) then begin
            CurDesigner.ControlSelection.MoveSelection(
              X-LastMouseMovePos.X, Y-LastMouseMovePos.Y);
            LastMouseMovePos:=Point(X,Y);
          end;
        end;
      end;
    end;
  end;
End;

procedure TForm1.MouseUpOnControl(Sender : TObject; Button: TMouseButton;
Shift : TShiftState; X, Y: Integer);
// We clicked on the form.  Let's see what the active selection is in the IDE
// control bar. If it's the pointer, then we set the
// FormEditor1.SelectedComponents to Sender,
// otherwise we drop a control and call the CreateComponent function.
var
  ParentCI, NewCI : TComponentInterface;
  NewLeft, NewTop, NewWidth, NewHeight : Integer;
//  CInterface : TComponentInterface;
  CaptureGrabber:TGrabber;
Begin
  CaptureGrabber:=GetCaptureGrabber;
  if CaptureGrabber<>nil then begin
    CaptureGrabber.CaptureMouseUp(TControl(Sender),Button,Shift,X,Y);
    exit;
  end;

  MouseUpPos.X := X;
  MouseUpPos.Y := Y;
  if not (Sender is TCustomForm) then begin
    inc(MouseUpPos.X,TControl(Sender).Left);
    inc(MouseUpPos.Y,TControl(Sender).Top);
  end;
  Writeln(TComponent(Sender).Name+'.OnMouseUp at '+inttostr(x)+','+inttostr(y));

  if BPressed = 1 then
  Begin //mouse pointer button pressed.
    if Sender is TCustomForm then
      SelectOnlyThisComponent(TComponent(Sender));
  end
  else
  Begin  //add a new control
    ParentCI:=TComponentInterface(FormEditor1.FindComponent(TComponent(Sender)));
    if (TComponent(Sender) is TWinControl)
      and (not (csAcceptsControls in TWinControl(Sender).ControlStyle)) then
    begin
      ParentCI:=TComponentInterface(
        FormEditor1.FindComponent(TWinControl(Sender).Parent));
    end;
    if Assigned(ParentCI) then begin
      NewLeft:=Min(MouseDownPos.X,MouseUpPos.X);
      NewWidth:=Abs(MouseUpPos.X-MouseDownPos.X);
      NewTop:=Min(MouseDownPos.Y,MouseUpPos.Y);
      NewHeight:=Abs(MouseUpPos.Y-MouseDownPos.Y);
      if Abs(NewWidth+NewHeight)<7 then begin
        // this very small component is probably only a wag, take default size
        NewWidth:=0;
        NewHeight:=0;
      end;
      NewCI := TComponentInterface(FormEditor1.CreateComponent(ParentCI,
        TComponentClass(TIdeComponent(ideComplist.items[bpressed-1]).ClassType)
        ,NewLeft,NewTop,NewWidth,NewHeight));
      NewCI.SetPropByName('Visible',True); //Control).Visible := True;

      ObjectInspector1.FillComponentComboBox;
      TDesigner(TForm(NewCI.Control.Owner).Designer).AddControlCode(NewCI.Control);

      if NewCI.Control is TControl then begin
        // set the OnMouseDown and OnMouseUp event so we know when the control
        // is selected or a new control is dropped
writeln('NewComponent is TControl');
        NewCI.SetPropByName('OnMouseUp',@MouseUpOnControl);
        NewCI.SetPropByName('OnMouseDown',@MouseDownOnControl);
        NewCI.SetPropByName('OnMouseMove',@MouseMoveOnControl);
        SelectOnlyThisComponent(TComponent(NewCI.Control));
      end;
    end;
  end;

  MouseDownControl:=nil;
  ControlClick(Notebook1);  //this resets it to the mouse.
end;

{------------------------------------------------------------------------------}
procedure TForm1.mnuNewFormClicked(Sender : TObject);
var
  I,N: Integer;
  SList : TUnitInfo;
  TempName : String;
  TempFormName : String;
  Found : Boolean;
  TempForm : TForm;
  CInterface : TComponentInterface;
begin
  //TempForm := TForm.Create(Self);
  //TempForm.Parent := Self;
  if not Assigned(FormEditor1) then
  FormEditor1 := TFormEditor.Create;
  FormEditor1.SelectedComponents.Clear;

  CInterface := TComponentInterface(
    FormEditor1.CreateComponent(nil,TForm,
       ObjectInspector1.Left+ObjectInspector1.Width+5,ObjectInspector1.Top,
       400,300));
  TempForm:=TForm(CInterface.Control);
  TempForm.Designer :=
    TDesigner.Create(TCustomForm(CInterface.Control));
  TDesigner(TempForm.Designer).FormEditor := FormEditor1;

  TDesigner(tempForm.Designer).SourceEditor := SourceNotebook.CreateUnitFromForm(TempForm);

  TempForm.OnMouseDown := @MouseDownOnControl;
  TempForm.OnMouseUp := @MouseUpOnControl;
  TempForm.OnMouseMove := @MouseMoveOnControl;
  TempForm.OnActivate := @CodeOrFormActivated;
  TempForm.Show;

  PropertyEditorHook1.LookupRoot := TForm(CInterface.Control);
  FormEditor1.ClearSelected;
  FormEditor1.AddSelected(TComponent(CInterface.Control));
end;


{------------------------------------------------------------------------------}
procedure TForm1.mnuOpenClicked(Sender : TObject);
var
  Str : TStringList;
  SList : TUnitInfo;
  Texts : String;
begin

end;
{------------------------------------------------------------------------------}

Procedure TForm1.mnuCloseClicked(Sender : TObject);
Begin

end;

{------------------------------------------------------------------------------}

procedure TForm1.mnuQuitClicked(Sender : TObject);
var
I : Integer;
SList : TUnitInfo;
begin
//if there is a project loaded, check if it should be saved

//free the unitlist objects
if Project1.UnitList.Count > 0 then
  For I := 0 to Project1.UnitList.Count -1 do
            Begin
            SList := TUnitInfo(Project1.UnitList.Items[I]);
            SList.Destroy;
            end;

Project1.UnitList.Free;

Close;
end;


{------------------------------------------------------------------------------}
procedure TForm1.mnuViewInspectorClicked(Sender : TObject);
begin
 ObjectInspector1.Show;
end;


{------------------------------------------------------------------------------}
procedure TForm1.mnuViewCompilerSettingsClicked(Sender : TObject);
begin
 frmCompilerOptions.Show;
end;

Procedure TForm1.mnuViewUnitsClicked(Sender : TObject);
Begin

end;

Procedure TForm1.mnuViewFormsClicked(Sender : TObject);
Begin

end;

Procedure TForm1.mnuViewCodeExplorerClick(Sender : TObject);
begin
SourceNotebook.Show;
end;

Procedure TForm1.mnuViewMessagesClick(Sender : TObject);
Begin
  Messagedlg.Show;
End;

Procedure TForm1.DoFind(Sender : TObject);
Begin

end;

Procedure TForm1.mnuSearchFindClicked(Sender : TObject);
Begin
itmSearchFindAgain.Enabled := True;
FindDialog1.ShowModal;
End;

Procedure TForm1.mnuSearchFindAgainClicked(Sender : TObject);
Begin
DoFind(itmSearchFindAgain);
End;

Procedure TForm1.mnuNewProjectClicked(Sender : TObject);
var
  SList : TUnitInfo;
Begin
  Assert(False, 'Trace:New Project Clicked');
end;

{------------------------------------------------------------}

Procedure TForm1.mnuOpenProjectClicked(Sender : TObject);
Begin

end;

Procedure TForm1.mnuSaveProjectClicked(Sender : TObject);
Begin

end;


Procedure TForm1.mnuBuildProjectClicked(Sender : TObject);
Begin
//for now just compile the active unit;
SourceNotebook.SaveClicked(Sender);

if not(MessageDlg.Visible) then
   Begin  //display the dialog under the TSourceNotebook
      MessageDlg.Show;
      MessageDlg.Top := Screen.Height - 150;
      MessageDlg.Height := 150;
{      if (SourceNotebook.Top+SourceNotebook.Height) > MEssageDlg.Top then
          SourceNotebook.Height := SourceNotebook.Height - (ABS(MessageDlg.Top - (SourceNotebook.Top+SourceNotebook.Height)));
 }
     MessageDlg.Left := SourceNotebook.Left;
      MessageDlg.Width := SourceNotebook.Width;
   end;
MessageDlg.Clear;
Compiler1.Compile(SourceNotebook.ActiveUnitName);

end;


Procedure TForm1.mnuRunProjectClicked(Sender : TObject);
var
Filename : String;
Begin
end;


Procedure TForm1.mnuViewColorClicked(Sender : TObject);
begin

ColorDialog1.Execute;


end;


Procedure TForm1.mnuViewFontClicked(Sender : TObject);
Begin
FontDialog1.Execute;

end;

Function TForm1.ReturnFormName(Source : TStringlist) : String;
Var
I : Integer;
Num,Num2 : Integer;
Found : Boolean;
Texts : String;
Temp : String;
Temp2 : String;

Begin
//Assert(False, 'Trace:************************************************');
//Assert(False, 'Trace:************************************************');
//Assert(False, 'Trace:************************************************');
//Assert(False, 'Trace:************************************************');
//Assert(False, 'Trace:************************************************');

//move to TUnitInfo
//parse file for the first class(TForm) I guess
Found := False;
for I := 0 to Source.Count-1 do
  Begin
    Num := pos(uppercase('class(TForm)'),uppercase(Source.Strings[I]));
    if Num <> 0 then
       Begin
         Temp := Source.Strings[i];
          //pull out class name
          Texts := '';
            for Num2 := 1 to length(Temp) do
              Begin
               if (Temp[num2] in ['a'..'z']) or (Temp[num2] in ['A'..'Z']) or (Temp[num2] in ['0'..'1'])then
                 Texts := Texts + Temp[num2]
                 else
                 if Length(Texts) <> 0 then Break;
              end;
         temp := Texts;
//	Assert(False, 'Trace:*******************');
//	Assert(False, 'Trace:Temp := '+Temp);
         Found := True;
         Break;
       end;
  end;
if Found then
   Begin
{Temp now holds TFORM1 or whatever the name of the class is}
{Search for the var statement from the I line down}
   Texts := '';
   Num := I;

for I := Num to Source.Count-1 do
  Begin
   Found := False;
   Num := pos('VAR',uppercase(Source.Strings[I]));
    if Num <> 0 then
       Begin
       Temp2 := Source.Strings[I];
        //Check around the VAR to see either spaces or begin/end of line
       if (Length(Temp2) = 3) then
          Begin
           Found := True;
//           Assert(False, 'Trace:1');
           Num := I;
           Break;
          end;

//var in the beginning of a sentence
       if (Num = 1) and (  not ( (Temp2[4] in CapLetters) or (Temp2[4] in SmallLetters) or (Temp2[4] in Numbers))) then
           Begin
            Found := True;
           Num := I;
//           Assert(False, 'Trace:2');
            Break;
           end;

       if ((Num+2) = length(Temp2)) and not ( (Temp2[Num-1] in CapLetters) or (Temp2[Num-1] in SmallLetters) or (Temp2[Num-1] in Numbers)) then
           Begin
            Found := True;
           Num := I;
//           Assert(False, 'Trace:3');
            Break;
           end;


       if  not ( (Temp2[Num-1] in CapLetters) or (Temp2[Num-1] in SmallLetters) or (Temp2[Num-1] in Numbers))  and  not ( (Temp2[Num+3] in CapLetters) or (Temp2[Num+3] in SmallLetters) or (Temp2[Num+3] in Numbers)) then
           Begin
            Found := True;
           Num := I;
//           Assert(False, 'Trace:4');
            Break;
           end;
       end;
   end;

 end;
Assert(False, 'Trace:Length of temp2 is '+inttostr(Length(Temp2)));

if Found then
   begin
   for I := Num to Source.Count-1 do
   Begin
    Found := False;
    Num := pos(uppercase(temp),uppercase(Source.Strings[I]));
    if num <> 0 then
     begin
      num2 := pos(':', Source.Strings[i]);
       if num2 <> 0 then
          Begin
           Temp2 := Source.Strings[i];
            for num := 1 to num2 do
              Begin
               if (Temp2[num] in ['a'..'z']) or (Temp2[num] in ['A'..'Z']) or (Temp2[num] in ['0'..'1'])then
                 Texts := Texts + Temp2[num]
                 else
                 if Length(Texts) <> 0 then Break;
              end;
           break;
          end;
     end;
   end;
  end;

result := Texts;
end;

Procedure TForm1.MessageViewDblClick(Sender : TObject);
Begin

end;


end.



{ =============================================================================

  $Log$
  Revision 1.22  2000/12/20 20:04:30  lazarus
  Made PRoject Build compile the active unit.  This way we can actually play with it by compiling units.

  Revision 1.19  2000/12/19 18:43:12  lazarus
  Removed IDEEDITOR.  This causes the PROJECT class to not function.
  Saving projects no longer works.

  I added TSourceNotebook and TSourceEditor.  They do all the work for saving/closing/opening units.  Somethings work but they are in early development.
  Shane

  Revision 1.18  2000/12/15 18:25:16  lazarus
  Changes from Mattias and I.
  Shane

  Revision 1.16  2000/12/01 20:23:34  lazarus
  renamed Object_Inspector and Prop_edits by removing the underline.
  Shane

  Revision 1.5  2000/08/10 13:22:51  lazarus
  Additions for the FIND dialog
  Shane

  Revision 1.4  2000/08/09 18:32:10  lazarus
  Added more code for the find function.
  Shane

  Revision 1.2  2000/08/07 19:15:05  lazarus
  Added the Search menu to the IDE.
  Shane

  Revision 1.1  2000/07/13 10:27:47  michael
  + Initial import

  Revision 1.152  2000/07/09 20:18:55  lazarus
  MWE:
    + added new controlselection
    + some fixes
    ~ some cleanup

  Revision 1.151  2000/06/29 18:08:56  lazarus
  Shane
    Looking for the editor problem I made a few changes.  I changed everything back to the original though.

  Revision 1.139  2000/06/12 18:33:45  lazarus
  Got the naming to work
  Shane

  Revision 1.136  2000/06/08 17:32:53  lazarus
  trying to add accel to menus.
  Shane

  Revision 1.135  2000/05/10 02:34:43  lazarus
  Changed writelns to Asserts except for ERROR and WARNING messages.   CAW

  Revision 1.134  2000/05/09 18:37:02  lazarus
  *** empty log message ***

  Revision 1.133  2000/05/09 12:52:02  lazarus
  *** empty log message ***

  Revision 1.132  2000/05/08 16:07:32  lazarus
  fixed screentoclient and clienttoscreen
  Shane

  Revision 1.130  2000/05/03 17:19:29  lazarus
  Added the TScreem forms code by hongli@telekabel.nl
  Shane

  Revision 1.124  2000/03/31 18:41:02  lazarus
  Implemented MessageBox / Application.MessageBox calls. No icons yet, though...

  Revision 1.123  2000/03/30 18:23:07  lazarus
  Pulled unneeded code out of main.pp
  Shane

  Revision 1.121  2000/03/24 14:40:41  lazarus
  A little polishing and bug fixing.

  Revision 1.120  2000/03/23 20:40:02  lazarus
  Added some drag code
  Shane

  Revision 1.119  2000/03/22 17:09:28  lazarus
  *** empty log message ***

  Revision 1.118  2000/03/21 21:09:19  lazarus
  *** empty log message ***

  Revision 1.113  2000/03/19 23:01:41  lazarus
  MWE:
    = Changed splashscreen loading/colordepth
    = Chenged Save/RestoreDC to platform  dependent, since they are
      relative to a DC

  Revision 1.112  2000/03/19 03:52:08  lazarus
  Added onclick events for the speedbuttons.
  Shane

  Revision 1.111  2000/03/18 03:08:35  lazarus
  MWE:
    ~ Enabled slpash code again (cvs didn't update spash.pp at first)

  Revision 1.110  2000/03/18 01:08:30  lazarus
  MWE:
    ~ Commentedout SplashScreen (missing)
    + Fixed Speedbutton drawing

  Revision 1.109  2000/03/17 18:47:53  lazarus
  Added a generic splash form
  Shane

  Revision 1.106  2000/03/15 20:15:31  lazarus
  MOdified TBitmap but couldn't get it to work
  Shane

  Revision 1.105  2000/03/15 00:51:57  lazarus
  MWE:
    + Added LM_Paint on expose
    + Added forced creation of gdkwindow if needed
    ~ Modified DrawFrameControl
    + Added BF_ADJUST support on DrawEdge
    - Commented out LM_IMAGECHANGED in TgtkObject.IntSendMessage3
       (It did not compile)

  Revision 1.104  2000/03/14 19:49:04  lazarus
  Modified the painting process for TWincontrol.  Now it runs throug it's FCONTROLS list and paints all them
  Shane

  Revision 1.103  2000/03/14 05:54:01  lazarus
  Changed the name of the compiler options form.        CAW

  Revision 1.102  2000/03/10 18:31:09  lazarus
  Added TSpeedbutton code
  Shane

  Revision 1.101  2000/03/09 23:37:51  lazarus
  MWE:
    * Fixed colorcache
    * Fixed black window in new editor
    ~ Did some cosmetic stuff

  From Peter Dyson <peter@skel.demon.co.uk>:
    + Added Rect api support functions
    + Added the start of ScrollWindowEx

  Revision 1.100  2000/03/09 20:49:25  lazarus
  Added menus for Project Run and Project Build.  They don't do anything yet.

  Revision 1.99  2000/03/07 16:52:58  lazarus
  Fixxed a problem with the main.pp unit determining a new files FORM name.
  Shane

  Revision 1.98  2000/03/03 22:58:25  lazarus
  MWE:
    Fixed focussing problem.
      LM-FOCUS was bound to the wrong signal
    Added GetKeyState api func.
      Now LCL knows if shift/trl/alt is pressed (might be handy for keyboard
      selections ;-)

  Revision 1.97  2000/03/03 20:22:02  lazarus
  Trying to add TBitBtn
  Shane

  Revision 1.95  2000/03/01 00:41:02  lazarus
  MWE:
    Fixed updateshowing problem
    Added some debug code to display the name of messages
    Did a bit of cleanup in main.pp to get the code a bit more readable
      (my editor does funny things with tabs if the indent differs)

  Revision 1.94  2000/02/29 23:00:04  lazarus
  Adding code for the ide.
  Shane

  Revision 1.93  2000/02/28 19:16:03  lazarus
  Added code to the FILE CLOSE to check if the file was modified.  HAven't gotten the application.messagebox working yet though.  It won't stay visible.
  Shane

  Revision 1.92  2000/02/25 19:28:34  lazarus
  Played with TNotebook to see why it crashes when I add a tab and the tnotebook is showing.  Havn't figured it out
  Shane

  Revision 1.91  2000/02/24 21:15:29  lazarus
  Added TCustomForm.GetClientRect and RequestAlign to try and get the controls to align correctly when a MENU is present.  Not Complete yet.

  Fixed the bug in TEdit that caused it not to update it's text property.  I will have to
  look at TMemo to see if anything there was affected.

  Added SetRect to WinAPI calls
  Added AdjustWindowRectEx to WINAPI calls.
  Shane

  Revision 1.90  2000/02/23 14:19:09  lazarus
  Fixed the conflicts caused when two people worked on the ShowModal method for CustomForm and CustomDialog at the same time.
  Shane

  Revision 1.89  2000/02/22 22:19:49  lazarus
  TCustomDialog is a descendant of TComponent.
  Initial cuts a form's proper Close behaviour.

  Revision 1.88  2000/02/22 21:29:42  lazarus
  Added a few more options in the editor like closeing a unit.  Also am keeping track of what page , if any, they are currently on.
  Shane

  Revision 1.85  2000/02/21 17:38:04  lazarus
  Added modalresult to TCustomForm
  Added a View Units dialog box
  Added a View Forms dialog box
  Added a New Unit menu selection
  Added a New Form menu selection
  Shane

  Revision 1.84  2000/02/20 20:13:46  lazarus
  On my way to make alignments and stuff work :-)

  Revision 1.83  2000/02/18 19:38:52  lazarus
  Implemented TCustomForm.Position
  Better implemented border styles. Still needs some tweaks.
  Changed TComboBox and TListBox to work again, at least partially.
  Minor cleanups.

  Revision 1.82  2000/01/31 20:00:21  lazarus
  Added code for Application.ProcessMessages.  Needs work.
  Added TScreen.Width and TScreen.Height.  Added the code into
  GetSystemMetrics for these two properties.
  Shane

  Revision 1.81  2000/01/18 21:47:00  lazarus
  Added OffSetRec

  Revision 1.80  2000/01/10 00:07:12  lazarus
  MWE:
    Added more scrollbar support for TWinControl
    Most signals for TWinContorl are jet connected to the wrong widget
      (now scrolling window, should be fixed)
    Added some cvs entries

  Revision 1.79  2000/01/05 23:13:13  lazarus
  MWE:
    Made some changes to the ideeditor to track notebook problems

  Revision 1.78  2000/01/04 23:12:46  lazarus
  MWE:
    Fixed LM_CHAR message. It is now after the LM_KEYUP message
    Fixed Menus at checkbox example.
    Removed references to TTabbedNtBK (somebody removed the files) and
      chanched it on the compileroptions form

  Revision 1.77  2000/01/04 21:00:34  lazarus
  *** empty log message ***

  Revision 1.76  2000/01/04 19:19:56  lazarus
  Modified notebook.inc so it works.  Don't need tabnotbk.pp anymore...

  Shane

  Revision 1.74  2000/01/03 00:19:20  lazarus
  MWE:
    Added keyup and buttonup events
    Added LM_MOUSEMOVE callback
    Started with scrollbars in editor

  Revision 1.73  1999/12/30 19:49:07  lazarus
  *** empty log message ***

  Revision 1.71  1999/12/29 20:38:22  lazarus
  Modified the toolbar so it now displays itself.  However, I can only add one button at this point.  I will fix that soon....

  Shane

  Revision 1.70  1999/12/23 21:48:13  lazarus
  *** empty log message ***

  Revision 1.66  1999/12/22 01:16:03  lazarus
  MWE:
    Changed/recoded keyevent callbacks
    We Can Edit!
    Commented out toolbar stuff

  Revision 1.65  1999/12/21 21:35:52  lazarus
  committed the latest toolbar code.  Currently it doesn't appear anywhere and I have to get it to add buttons correctly through (I think) setstyle.  I think I'll implement the LM_TOOLBARINSERTBUTTON call there.
  Shane

  Revision 1.64  1999/12/08 00:56:06  lazarus
  MWE:
    Fixed menus. Events aren't enabled yet (dumps --> invalid typecast ??)

  Revision 1.63  1999/11/30 21:30:06  lazarus
  Minor Issues
  Shane

  Revision 1.62  1999/11/25 23:45:08  lazarus
  MWE:
    Added font as GDIobject
    Added some API testcode to testform
    Commented out some more IFDEFs in mwCustomEdit

  Revision 1.61  1999/11/24 18:54:13  lazarus
  Added a unit called ideeditor.pp
  Shane

  Revision 1.60  1999/11/23 22:06:27  lazarus
  Minor changes to get it running again with the latest compiler.  There is something wrong with the compiler that is preventing certain things from working.
  Shane

  Revision 1.59  1999/11/19 14:44:37  lazarus
  Changed the FONTSETNAME to try and load a default font if the first one doesn't work.  This is being done for testing and probably will be removed later.
  Shane

  Revision 1.58  1999/11/17 01:12:52  lazarus
  MWE:
    Added a TestForm and moved mwEdit to that form. The form popsup after
    pressing the testform buttomn

  Revision 1.57  1999/11/05 17:48:17  lazarus
  Added a mwedit1 component to lazarus (MAIN.PP)
  It crashes on create.
  Shane

  Revision 1.56  1999/11/05 00:34:10  lazarus
  MWE: Menu structure updated, events and visible code not added yet

  Revision 1.55  1999/11/01 01:28:28  lazarus
  MWE: Implemented HandleNeeded/CreateHandle/CreateWND
       Now controls are created on demand. A call to CreateComponent shouldn't
       be needed. It is now part of CreateWnd

  Revision 1.54  1999/10/28 23:48:57  lazarus
  MWE: Added new menu classes and started to use handleneeded

  Revision 1.53  1999/10/28 17:17:41  lazarus
  Removed references to FCOmponent.
  Shane

  Revision 1.52  1999/10/19 19:16:51  lazarus
  renamed stdcontrols.pp stdctrls.pp
  Shane

  Revision 1.51  1999/09/30 21:59:00  lazarus
  MWE: Fixed TNoteBook problems
       Modifications: A few
       - Removed some debug messages
       + Added some others
       * changed fixed widged of TPage. Code is still broken.
       + TWinControls are also added to the Controls collection
       + Added TControl.Controls[] property

  Revision 1.50  1999/09/22 20:29:52  lazarus
  *** empty log message ***

  Revision 1.47  1999/07/30 18:18:05  lazarus
  Changes made:  Added a LM_FONTGETSIZE call so you get the size, width and height of the current font.   Not sure if height and size are the same or not.

  Added a cursor to the editor.  When you click you should see it.  Not sure if it works because I can't run Lazarus due to the linking problem.

  Shane

  Revision 1.46  1999/07/27 15:39:42  lazarus
  Changed version number.
  Shane

  Revision 1.45  1999/07/23 17:12:57  lazarus
  TCanvas seems to be working.
  Added Canvas.
     LineTo
     rectangle
     TextOut
     Line

  Shane

  Revision 1.44  1999/07/22 20:55:07  lazarus
  *** empty log message ***

  Revision 1.43  1999/07/18 03:57:32  lazarus
  Minor changes to help diagnose te Canvas and Resize problem.

  Revision 1.40  1999/07/17 06:14:26  lazarus
  TCanvas is almost working.  Added TCanvas.FillRect procedure.
  TCanvas is still getting over written by something.

  Revision 1.39  1999/07/13 02:08:16  lazarus
  no message

  Revision 1.35  1999/07/09 13:54:43  lazarus
  Changed to use Dispatch instead of DispatchStr for messaging.
  You pass it LM_Message which is an integer value and therefore you
  can now use Dispatch to send the integer value back to the class.
  There is currently a problem with having multiple "message" procedures
  in one class so I commented them out for now.

  Shane

  Revision 1.34  1999/06/27 21:34:39  lazarus
  Minor messaging changes.
  Changed from TMyNotifyEvent to TNotifyEvent procedures

  Revision 1.33  1999/05/24 21:20:20  lazarus
  *** empty log message ***

  Revision 1.32  1999/05/20 02:04:58  lazarus
  Modified MAIN so the FILE SAVE menu item tries to save the last activepage

  Revision 1.29  1999/05/17 22:22:38  lazarus
  *** empty log message ***

  Revision 1.28  1999/05/17 04:16:26  lazarus
  TMemo colors files now.
  Still crashes once in a while.  Certain files seem to make it crash.
  Try open buttons.pp

  Revision 1.26  1999/05/15 21:15:06  lazarus
  *** empty log message ***

  Revision 1.25  1999/05/14 18:44:14  lazarus
  *** empty log message ***

  Revision 1.24  1999/05/14 14:53:07  michael
  + Removed objpas from uses clause

  Revision 1.23  1999/05/07 05:46:53  lazarus
  *** empty log message ***

  Revision 1.20  1999/05/03 05:43:06  lazarus
  *** empty log message ***

  Revision 1.19  1999/05/01 03:55:28  lazarus
  *** empty log message ***

  Revision 1.18  1999/04/30 05:28:53  lazarus
  *** empty log message ***

  Revision 1.17  1999/04/28 05:29:36  lazarus
  *** empty log message ***

  Revision 1.16  1999/04/28 05:21:08  lazarus
  *** empty log message ***

  Revision 1.15  1999/04/27 05:08:47  lazarus
  *** empty log message ***

  Revision 1.14  1999/04/26 06:18:25  lazarus
  *** empty log message ***

  Revision 1.13  1999/04/24 03:59:14  lazarus
  *** empty log message ***

  Revision 1.12  1999/04/23 19:42:10  lazarus
  *** empty log message ***

  Revision 1.11  1999/04/23 14:54:58  lazarus
  Added a class TStatusBar and TAling into Comctrls.pp
  Added a class TStatusbar and TAlign into comctrls.pp  They do not work exactly how they were planned.  Plan is to create an Align widget, then a statusbar with an owner of TAlign type.  TAlign would force the TStatusbar to remian on the bottom of the page during a form resize.

  Revision 1.10  1999/04/22 13:46:31  lazarus
  Added ToolTips.
     TControl contains FToolTip, TShowToolTip along with the "Set" methods for these properties.  Every class descendant from TControl can have a TToolTip simply by setting it's pubplic property ToolTip and ShowToolTip := True
     04/22/1999  Shane Miller

  Revision 1.9  1999/04/21 20:58:56  lazarus
  TRadioButton was added in stdControls.  A problem exists in recreating them if the caption changes, but they are functional for now.
  Also, main.pp was modified just to show the use of radiobuttons.

  Revision 1.8  1999/04/21 14:17:45  lazarus
  TToggleBox added.\

  Minor changes have been made to remove excess code once thought required.

  Revision 1.7  1999/04/21 06:12:07  lazarus
  *** empty log message ***

  Revision 1.5  1999/04/20 05:10:39  lazarus
  *** empty log message ***

  Revision 1.4  1999/04/20 03:28:50  lazarus
  *** empty log message ***

  Revision 1.3  1999/04/20 02:56:44  lazarus
  *** empty log message ***

  Revision 1.2  1999/04/18 05:42:11  lazarus
  *** empty log message ***

  Revision 1.1  1999/04/14 07:31:44  michael
  + Initial implementation
}
