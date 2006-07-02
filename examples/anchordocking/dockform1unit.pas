unit DockForm1Unit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LCLProc, LResources, Forms, Controls, Graphics, Dialogs,
  DockForm2Unit, Buttons, Menus, LDockCtrl, XMLPropStorage;

type

  { TMainForm }

  TMainForm = class(TForm)
    SaveLayoutButton: TButton;
    CreateNewFormButton: TButton;
    MainPopupMenu: TPopupMenu;
    procedure CreateNewFormButtonClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormPaint(Sender: TObject);
    procedure SaveLayoutButtonClick(Sender: TObject);
  private
    function CreateNewForm: TCustomForm;
  public
    DockerForm1: TLazControlDocker;
    DockingManager: TLazDockingManager;
  end;

var
  MainForm: TMainForm;

implementation

{ TMainForm }

procedure TMainForm.FormPaint(Sender: TObject);
begin
  if Sender=nil then ;
  PaintBoundaries(Self,clBlue);
end;

procedure TMainForm.SaveLayoutButtonClick(Sender: TObject);
var
  Config: TXMLConfigStorage;
begin
  Config:=TXMLConfigStorage.Create('config.xml',false);
  DockingManager.SaveToConfig(Config);
  Config.WriteToDisk;
  Config.Free;
end;

function TMainForm.CreateNewForm: TCustomForm;
var
  DockForm: TDockFormX;
begin
  DockForm:=TDockFormX.Create(Self);
  Result:=DockForm;
  DockForm.Docker.Manager:=DockingManager;
  DockForm.Name:=DockForm.Docker.DockerName;
  DockForm.Docker.Name:='Docker'+DockForm.Name;
  DockForm.Visible:=true;
  DebugLn('TMainForm.CreateNewForm ',DockForm.Name,' ',DockingManager.FindDockerByControl(DockForm,nil).DockerName,' ',DockingManager.GetControlConfigName(DockForm));
end;

procedure TMainForm.CreateNewFormButtonClick(Sender: TObject);
begin
  if Sender=nil then ;
  CreateNewForm;
end;

procedure TMainForm.FormCreate(Sender: TObject);
var
  Form2: TCustomForm;
  Form3: TCustomForm;
  Config: TXMLConfigStorage;
  UseConfig: Boolean;
begin
  if Sender=nil then ;
  DockingManager:=TLazDockingManager.Create(Self);
  
  UseConfig:=FileExists('config.xml');
  if UseConfig then begin
    Config:=TXMLConfigStorage.Create('config.xml',true);
    DockingManager.LoadFromConfig(Config);
    Config.Free;
  end;

  DockerForm1:=TLazControlDocker.Create(Self);
  DockerForm1.Name:='DockerForm1';
  DockerForm1.Manager:=DockingManager;
  
  Form2:=CreateNewForm;
  Form3:=CreateNewForm;

  if not UseConfig then begin
    DebugLn(['TMainForm.FormCreate AAAAAA']);
    DockingManager.Manager.InsertControl(Form2,alLeft,Self);
    DockingManager.Manager.InsertControl(Form3,alBottom,Self);
  end;
  
  DockingManager.WriteDebugReport;
  
  DockerForm1.GetLayoutFromControl;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  if Sender=nil then ;
  DockingManager.Free;
end;

initialization
  {$I dockform1unit.lrs}

end.

