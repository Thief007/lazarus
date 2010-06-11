unit Unit1; 

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LCLProc, FileUtil, Forms, Controls, Graphics, Dialogs,
  Menus, ExtCtrls, Buttons, ComCtrls, SimpleFrm,
  AnchorDocking, AnchorDockStorage, XMLPropStorage;

type

  { TMainIDE }

  TMainIDE = class(TForm)
    ImageList1: TImageList;
    MainMenu1: TMainMenu;
    ComponentPalette: TNotebook;
    NewFileMenuItem: TMenuItem;
    OpenFileMenuItem: TMenuItem;
    Page1: TPage;
    Page2: TPage;
    BtnPanel: TPanel;
    QuitMenuItem: TMenuItem;
    FileMenuItem: TMenuItem;
    ToolBar1: TToolBar;
    ToolBar2: TToolBar;
    SaveLayoutToolButton: TToolButton;
    LoadLayoutToolButton: TToolButton;
    ViewDbgOutToolButton: TToolButton;
    ViewProjInspToolButton: TToolButton;
    ViewFPDocEditorToolButton: TToolButton;
    ViewMessagesToolButton: TToolButton;
    ViewOIToolButton: TToolButton;
    ViewCodeExplToolButton: TToolButton;
    ViewSrcEdit2ToolButton: TToolButton;
    ViewSrcEditor1ToolButton: TToolButton;
    procedure FileMenuItemClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure LoadLayoutToolButtonClick(Sender: TObject);
    procedure QuitMenuItemClick(Sender: TObject);
    procedure SaveLayoutToolButtonClick(Sender: TObject);
    procedure ViewCodeExplToolButtonClick(Sender: TObject);
    procedure ViewDbgOutToolButtonClick(Sender: TObject);
    procedure ViewFPDocEditorToolButtonClick(Sender: TObject);
    procedure ViewMessagesToolButtonClick(Sender: TObject);
    procedure ViewOIToolButtonClick(Sender: TObject);
    procedure ViewProjInspToolButtonClick(Sender: TObject);
    procedure ViewSrcEdit2ToolButtonClick(Sender: TObject);
    procedure ViewSrcEditor1ToolButtonClick(Sender: TObject);
  private
    procedure DockMasterCreateControl(Sender: TObject; aName: string; var
      AControl: TControl; DoDisableAutoSizing: boolean);
  public
    procedure ShowForm(AForm: TCustomForm; FormEnableAutosizing: boolean);
    procedure SaveLayout(Filename: string);
    procedure LoadLayout(Filename: string);
  end;

var
  MainIDE: TMainIDE;

implementation

{$R *.lfm}

{ TMainIDE }

procedure TMainIDE.FileMenuItemClick(Sender: TObject);
begin
  close;
end;

procedure TMainIDE.DockMasterCreateControl(Sender: TObject; aName: string; var
  AControl: TControl; DoDisableAutoSizing: boolean);

  procedure CreateForm(Caption: string; NewBounds: TRect);
  begin
    AControl:=CreateSimpleForm(aName,Caption,NewBounds,DoDisableAutoSizing);
  end;

begin
  AControl:=Screen.FindForm(aName);
  if AControl<>nil then begin
    if DoDisableAutoSizing then
      AControl.DisableAutoSizing;
    exit;
  end;
  if aName='CodeExplorer' then
    CreateForm('Code Explorer',Bounds(700,230,100,250))
  else if aName='FPDocEditor' then
    CreateForm('FPDoc Editor',Bounds(200,720,300,100))
  else if aName='Messages' then
    CreateForm('Messages',Bounds(230,650,350,100))
  else if aName='ObjectInspector' then
    CreateForm('Object Inspector',Bounds(10,200,100,350))
  else if aName='SourceEditor1' then
    CreateForm('Source Editor 1',Bounds(230,200,400,400))
  else if aName='SourceEditor2' then
    CreateForm('Source Editor 2',Bounds(260,230,350,350))
  else if aName='ProjectInspector' then
    CreateForm('Project Inspector',Bounds(10,230,150,250))
  else if aName='DebugOutput' then
    CreateForm('Debug Output',Bounds(400,400,350,150));
end;

procedure TMainIDE.FormCreate(Sender: TObject);
begin
  ViewOIToolButton.Hint:='View Object Inspector';
  ViewCodeExplToolButton.Hint:='View Code Explorer';
  ViewSrcEditor1ToolButton.Hint:='View Source Editor 1';
  ViewSrcEdit2ToolButton.Hint:='View Source Editor 2';
  ViewFPDocEditorToolButton.Hint:='View FPDoc Editor';
  ViewMessagesToolButton.Hint:='View Messages';
  ViewProjInspToolButton.Hint:='View Project Inspector';
  ViewDbgOutToolButton.Hint:='View Debug Output';
  SaveLayoutToolButton.Hint:='Save Layout to layout.xml';
  LoadLayoutToolButton.Hint:='Load layout from layout.xml';

  DockMaster.MakeDockSite(Self,[akBottom],admrpChild);
  DockMaster.OnCreateControl:=@DockMasterCreateControl;

  SetBounds(100,50,600,80);
  ViewSrcEditor1ToolButtonClick(Self);
  //ViewMessagesToolButtonClick(Self);
  //ViewOIToolButtonClick(Self);
end;

procedure TMainIDE.LoadLayoutToolButtonClick(Sender: TObject);
begin
  LoadLayout('layout.xml');
end;

procedure TMainIDE.QuitMenuItemClick(Sender: TObject);
begin
  Close;
end;

procedure TMainIDE.SaveLayoutToolButtonClick(Sender: TObject);
begin
  SaveLayout('layout.xml');
end;

procedure TMainIDE.ViewCodeExplToolButtonClick(Sender: TObject);
begin
  DockMaster.ShowControl('CodeExplorer',true);
end;

procedure TMainIDE.ViewDbgOutToolButtonClick(Sender: TObject);
begin
  DockMaster.ShowControl('DebugOutput',true);
end;

procedure TMainIDE.ViewFPDocEditorToolButtonClick(Sender: TObject);
begin
  DockMaster.ShowControl('FPDocEditor',true);
end;

procedure TMainIDE.ViewMessagesToolButtonClick(Sender: TObject);
begin
  DockMaster.ShowControl('Messages',true);
end;

procedure TMainIDE.ViewOIToolButtonClick(Sender: TObject);
begin
  DockMaster.ShowControl('ObjectInspector',true);
end;

procedure TMainIDE.ViewProjInspToolButtonClick(Sender: TObject);
begin
  DockMaster.ShowControl('ProjectInspector',true);
end;

procedure TMainIDE.ViewSrcEdit2ToolButtonClick(Sender: TObject);
begin
  DockMaster.ShowControl('SourceEditor2',true);
end;

procedure TMainIDE.ViewSrcEditor1ToolButtonClick(Sender: TObject);
begin
  DockMaster.ShowControl('SourceEditor1',true);
end;

procedure TMainIDE.ShowForm(AForm: TCustomForm; FormEnableAutosizing: boolean);
begin
  DockMaster.MakeDockable(AForm);
  if FormEnableAutosizing then
    AForm.EnableAutoSizing;
end;

procedure TMainIDE.SaveLayout(Filename: string);
var
  XMLConfig: TXMLConfigStorage;
begin
  try
    XMLConfig:=TXMLConfigStorage.Create(Filename,false);
    try
      DockMaster.SaveLayoutToConfig(XMLConfig);
      XMLConfig.WriteToDisk;
    finally
      XMLConfig.Free;
    end;
  except
    on E: Exception do begin
      MessageDlg('Error',
        'Error saving layout to file '+Filename+':'#13+E.Message,mtError,
        [mbCancel],0);
    end;
  end;
end;

procedure TMainIDE.LoadLayout(Filename: string);
var
  XMLConfig: TXMLConfigStorage;
begin
  try
    XMLConfig:=TXMLConfigStorage.Create(Filename,True);
    try
      DockMaster.LoadLayoutFromConfig(XMLConfig);
    finally
      XMLConfig.Free;
    end;
  except
    on E: Exception do begin
      MessageDlg('Error',
        'Error loading layout from file '+Filename+':'#13+E.Message,mtError,
        [mbCancel],0);
    end;
  end;
end;

end.

