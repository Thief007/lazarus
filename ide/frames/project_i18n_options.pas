unit project_i18n_options;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs,
  StdCtrls, Project, IDEProcs, IDEOptionsIntf, LazarusIDEStrConsts, IDEDialogs;

type

  { TProjectI18NOptionsFrame }

  TProjectI18NOptionsFrame = class(TAbstractIDEOptionsEditor)
    EnableI18NCheckBox: TCheckBox;
    I18NGroupBox: TGroupBox;
    POOutDirButton: TButton;
    POOutDirEdit: TEdit;
    PoOutDirLabel: TLabel;
    procedure EnableI18NCheckBoxChange(Sender: TObject);
    procedure POOutDirButtonClick(Sender: TObject);
  private
    FProject: TProject;
    procedure Enablei18nInfo(Usei18n: boolean);
  public
    function GetTitle: string; override;
    procedure Setup(ADialog: TAbstractOptionsEditorDialog); override;
    procedure ReadSettings(AOptions: TAbstractIDEOptions); override;
    procedure WriteSettings(AOptions: TAbstractIDEOptions); override;
    class function SupportedOptionsClass: TAbstractIDEOptionsClass; override;
  end;

implementation

{$R *.lfm}

{ TProjectI18NOptionsFrame }

procedure TProjectI18NOptionsFrame.EnableI18NCheckBoxChange(Sender: TObject);
begin
  Enablei18nInfo(EnableI18NCheckBox.Checked);
end;

procedure TProjectI18NOptionsFrame.POOutDirButtonClick(Sender: TObject);
var
  NewDirectory: string;
begin
  NewDirectory := LazSelectDirectory(lisPOChoosePoFileDirectory,
                                     FProject.ProjectDirectory);
  if NewDirectory = '' then Exit;
  if not FProject.IsVirtual then
    NewDirectory:=CreateRelativePath(NewDirectory,FProject.ProjectDirectory);
  POOutDirEdit.Text := NewDirectory;
end;

procedure TProjectI18NOptionsFrame.Enablei18nInfo(Usei18n: boolean);
begin
  I18NGroupBox.Enabled := Usei18n;
end;

function TProjectI18NOptionsFrame.GetTitle: string;
begin
  Result := dlgPOI18n;
end;

procedure TProjectI18NOptionsFrame.Setup(ADialog: TAbstractOptionsEditorDialog);
begin
  EnableI18NCheckBox.Caption := rsEnableI18n;
  I18NGroupBox.Caption := rsI18nOptions;
  PoOutDirLabel.Caption := rsPOOutputDirectory;
end;

procedure TProjectI18NOptionsFrame.ReadSettings(AOptions: TAbstractIDEOptions);
var
  AFilename: String;
begin
  FProject := AOptions as TProject;
  with FProject do
  begin
    AFilename := POOutputDirectory;
    ShortenFilename(AFilename);
    POOutDirEdit.Text := AFilename;
    EnableI18NCheckBox.Checked := Enablei18n;
    Enablei18nInfo(Enablei18n);
  end;
end;

procedure TProjectI18NOptionsFrame.WriteSettings(AOptions: TAbstractIDEOptions);
var
  AFilename: String;
begin
  with AOptions as TProject do
  begin
    AFilename := TrimFilename(POOutDirEdit.Text);
    LongenFilename(AFilename);
    POOutputDirectory := AFilename;
    EnableI18N := EnableI18NCheckBox.Checked;
  end;
end;

class function TProjectI18NOptionsFrame.SupportedOptionsClass: TAbstractIDEOptionsClass;
begin
  Result := TProject;
end;

initialization
  RegisterIDEOptionsEditor(GroupProject, TProjectI18NOptionsFrame, ProjectOptionsI18N);

end.

