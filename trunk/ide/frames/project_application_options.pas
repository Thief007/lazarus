unit project_application_options;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  ExtCtrls, StdCtrls, Buttons, ComCtrls, ExtDlgs, Math, LCLType, IDEOptionsIntf,
  Project, LazarusIDEStrConsts, EnvironmentOpts, ApplicationBundle;

type

  { TProjectApplicationOptionsFrame }

  TProjectApplicationOptionsFrame = class(TAbstractIDEOptionsEditor)
    AppSettingsGroupBox: TGroupBox;
    ClearIconButton: TBitBtn;
    CreateAppBundleButton: TBitBtn;
    IconImage: TImage;
    IconLabel: TLabel;
    IconPanel: TPanel;
    IconTrack: TTrackBar;
    IconTrackLabel: TLabel;
    LoadIconButton: TBitBtn;
    OpenPictureDialog1: TOpenPictureDialog;
    OutputSettingsGroupBox: TGroupBox;
    SaveIconButton: TBitBtn;
    SavePictureDialog1: TSavePictureDialog;
    TargetFileEdit: TEdit;
    TargetFileLabel: TLabel;
    TitleEdit: TEdit;
    TitleLabel: TLabel;
    UseAppBundleCheckBox: TCheckBox;
    UseXPManifestCheckBox: TCheckBox;
    procedure ClearIconButtonClick(Sender: TObject);
    procedure CreateAppBundleButtonClick(Sender: TObject);
    procedure IconImagePictureChanged(Sender: TObject);
    procedure IconTrackChange(Sender: TObject);
    procedure LoadIconButtonClick(Sender: TObject);
    procedure SaveIconButtonClick(Sender: TObject);
  private
    FProject: TProject;
    procedure SetIconFromStream(Value: TStream);
    function GetIconAsStream: TStream;
  public
    function GetTitle: string; override;
    procedure Setup(ADialog: TAbstractOptionsEditorDialog); override;
    procedure ReadSettings(AOptions: TAbstractIDEOptions); override;
    procedure WriteSettings(AOptions: TAbstractIDEOptions); override;
    class function SupportedOptionsClass: TAbstractIDEOptionsClass; override;
  end;

implementation

function CreateProjectApplicationBundle(AProject: TProject): boolean;
var
  TargetExeName: string;
begin
  Result := False;
  if AProject.MainUnitInfo = nil then
    Exit;
  if AProject.IsVirtual then
    TargetExeName := EnvironmentOptions.GetTestBuildDirectory +
      ExtractFilename(AProject.MainUnitInfo.Filename)
  else
    TargetExeName := AProject.CompilerOptions.CreateTargetFilename(
      AProject.MainFilename);

  if not (CreateApplicationBundle(TargetExeName, AProject.Title, True) in
    [mrOk, mrIgnore]) then
    Exit;
  if not (CreateAppBundleSymbolicLink(TargetExeName, True) in [mrOk, mrIgnore]) then
    Exit;
  Result := True;
end;

{ TProjectApplicationOptionsFrame }

procedure TProjectApplicationOptionsFrame.IconImagePictureChanged(Sender: TObject);
var
  HasIcon: boolean;
  cx, cy: integer;
begin
  HasIcon := (IconImage.Picture.Graphic <> nil) and
    (not IconImage.Picture.Graphic.Empty);
  IconTrack.Enabled := HasIcon;
  if HasIcon then
  begin
    IconTrack.Min := 0;
    IconTrack.Max := IconImage.Picture.Icon.Count - 1;
    IconTrack.Position := IconImage.Picture.Icon.Current;
    IconImage.Picture.Icon.GetSize(cx, cy);
    IconTrackLabel.Caption :=
      Format(dlgPOIconDesc, [cx, cy, PIXELFORMAT_BPP[IconImage.Picture.Icon.PixelFormat]]);
  end
  else
    IconTrackLabel.Caption := dlgPOIconDescNone;
end;

procedure TProjectApplicationOptionsFrame.IconTrackChange(Sender: TObject);
begin
  IconImage.Picture.Icon.Current :=
    Max(0, Min(IconImage.Picture.Icon.Count - 1, IconTrack.Position));
end;

procedure TProjectApplicationOptionsFrame.ClearIconButtonClick(Sender: TObject);
begin
  IconImage.Picture.Clear;
end;

procedure TProjectApplicationOptionsFrame.CreateAppBundleButtonClick(Sender: TObject);
begin
  CreateProjectApplicationBundle(FProject);
end;

procedure TProjectApplicationOptionsFrame.LoadIconButtonClick(Sender: TObject);
begin
  if OpenPictureDialog1.Execute then
    IconImage.Picture.LoadFromFile(OpenPictureDialog1.FileName);
end;

procedure TProjectApplicationOptionsFrame.SaveIconButtonClick(Sender: TObject);
begin
  if SavePictureDialog1.Execute then
    IconImage.Picture.SaveToFile(SavePictureDialog1.FileName);
end;

procedure TProjectApplicationOptionsFrame.SetIconFromStream(Value: TStream);
begin
  IconImage.Picture.Clear;
  if Value <> nil then
    try
      IconImage.Picture.Icon.LoadFromStream(Value);
    except
      on E: Exception do
        MessageDlg(E.Message, mtError, [mbOK], 0);
    end;
end;

function TProjectApplicationOptionsFrame.GetIconAsStream: TStream;
begin
  Result := nil;
  if not ((IconImage.Picture.Graphic = nil) or IconImage.Picture.Graphic.Empty) then
  begin
    Result := TMemoryStream.Create;
    IconImage.Picture.Icon.SaveToStream(Result);
    Result.Position := 0;
  end;
end;

function TProjectApplicationOptionsFrame.GetTitle: string;
begin
  Result := dlgPOApplication;
end;

procedure TProjectApplicationOptionsFrame.Setup(ADialog: TAbstractOptionsEditorDialog);
begin
  AppSettingsGroupBox.Caption := dlgApplicationSettings;
  TitleLabel.Caption := dlgPOTitle;
  TitleEdit.Text := '';
  OutputSettingsGroupBox.Caption := dlgPOOutputSettings;
  TargetFileLabel.Caption := dlgPOTargetFileName;
  TargetFileEdit.Text := '';
  UseAppBundleCheckBox.Caption := dlgPOUseAppBundle;
  UseAppBundleCheckBox.Checked := False;
  UseXPManifestCheckBox.Caption := dlgPOUseManifest;
  UseXPManifestCheckBox.Checked := False;
  CreateAppBundleButton.Caption := dlgPOCreateAppBundle;
  CreateAppBundleButton.LoadGlyphFromLazarusResource('pkg_compile');

  // icon
  IconLabel.Caption := dlgPOIcon;
  LoadIconButton.Caption := dlgPOLoadIcon;
  SaveIconButton.Caption := dlgPOSaveIcon;
  ClearIconButton.Caption := dlgPOClearIcon;
  LoadIconButton.LoadGlyphFromStock(idButtonOpen);
  if LoadIconButton.Glyph.Empty then
    LoadIconButton.LoadGlyphFromLazarusResource('laz_open');
  SaveIconButton.LoadGlyphFromStock(idButtonSave);
  if SaveIconButton.Glyph.Empty then
    SaveIconButton.LoadGlyphFromLazarusResource('laz_save');
  ClearIconButton.LoadGlyphFromLazarusResource('menu_clean');
  IconImagePictureChanged(nil);
end;

procedure TProjectApplicationOptionsFrame.ReadSettings(AOptions: TAbstractIDEOptions);
var
  AStream: TStream;
begin
  FProject := AOptions as TProject;
  with FProject do
  begin
    TitleEdit.Text := Title;
    TargetFileEdit.Text := TargetFilename;
    UseAppBundleCheckBox.Checked := UseAppBundle;
    UseXPManifestCheckBox.Checked := Resources.XPManifest.UseManifest;
    AStream := Resources.ProjectIcon.GetStream;
    try
      SetIconFromStream(AStream);
    finally
      AStream.Free;
    end;
  end;
end;

procedure TProjectApplicationOptionsFrame.WriteSettings(AOptions: TAbstractIDEOptions);
var
  AStream: TStream;
begin
  with AOptions as TProject do
  begin
    Title := TitleEdit.Text;
    AStream := GetIconAsStream;
    try
      Resources.ProjectIcon.SetStream(AStream);
    finally
      AStream.Free;
    end;
    TargetFilename := TargetFileEdit.Text;
    UseAppBundle := UseAppBundleCheckBox.Checked;
    Resources.XPManifest.UseManifest := UseXPManifestCheckBox.Checked;
  end;
end;

class function TProjectApplicationOptionsFrame.SupportedOptionsClass:
TAbstractIDEOptionsClass;
begin
  Result := TProject;
end;

initialization
  {$I project_application_options.lrs}
  RegisterIDEOptionsEditor(GroupProject, TProjectApplicationOptionsFrame, ProjectOptionsApplication);

end.

