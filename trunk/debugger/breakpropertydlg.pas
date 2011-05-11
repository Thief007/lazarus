unit BreakPropertyDlg;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, LCLProc,
  ExtCtrls, StdCtrls, Buttons, ButtonPanel, EditBtn, Spin,
  IDEHelpIntf,
  DebuggerDlg, Debugger, BaseDebugManager, LazarusIDEStrConsts, InputHistory;

type

  { TBreakPropertyDlg }

  TBreakPropertyDlg = class(TDebuggerDlg)
    ButtonPanel: TButtonPanel;
    chkEnableGroups: TCheckBox;
    chkDisableGroups: TCheckBox;
    chkEvalExpression: TCheckBox;
    chkLogMessage: TCheckBox;
    chkActionBreak: TCheckBox;
    cmbGroup: TComboBox;
    edtCondition: TComboBox;
    edtEvalExpression: TEdit;
    edtLine: TSpinEdit;
    edtLogMessage: TEdit;
    edtEnableGroups: TEditButton;
    edtDisableGroups: TEditButton;
    edtAutocontinueMS: TEdit;
    edtCounter: TEdit;
    edtFilename: TEdit;
    gbActions: TGroupBox;
    lblMS: TLabel;
    lblFileName: TLabel;
    lblLine: TLabel;
    lblCondition: TLabel;
    lblHitCount: TLabel;
    lblGroup: TLabel;
    lblAutoContinue: TLabel;
    procedure btnHelpClick(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure BreakPointRemove(const ASender: TIDEBreakPoints;
      const ABreakpoint: TIDEBreakPoint);
    procedure BreakPointUpdate(const ASender: TIDEBreakPoints;
      const ABreakpoint: TIDEBreakPoint);
    procedure chkLogMessageChange(Sender: TObject);
  private
    FBreakpointsNotification : TIDEBreakPointsNotification;
    FBreakpoint: TIDEBreakPoint;
  protected
    procedure DoEndUpdate; override;
    procedure UpdateInfo;
  public
    constructor Create(AOwner: TComponent; ABreakPoint: TIDEBreakPoint);overload;
    destructor Destroy; override;
  end;

implementation

{$R *.lfm}

{ TBreakPropertyDlg }

procedure TBreakPropertyDlg.BreakPointUpdate(
  const ASender: TIDEBreakPoints; const ABreakpoint: TIDEBreakPoint);
begin
  UpdateInfo;
end;

procedure TBreakPropertyDlg.chkLogMessageChange(Sender: TObject);
begin
  edtLogMessage.Enabled := chkLogMessage.Checked;
end;

procedure TBreakPropertyDlg.btnHelpClick(Sender: TObject);
begin
  LazarusHelp.ShowHelpForIDEControl(Self);
end;

procedure TBreakPropertyDlg.BreakPointRemove(
  const ASender: TIDEBreakPoints; const ABreakpoint: TIDEBreakPoint);
begin
  if ABreakpoint = FBreakpoint
  then ModalResult := mrCancel;
end;

procedure TBreakPropertyDlg.btnOKClick(Sender: TObject);
var
  Actions: TIDEBreakPointActions;
begin
  if FBreakpoint = nil then Exit;

  FBreakpointsNotification.OnUpdate := nil;
  case FBreakpoint.Kind of
    bpkSource:
      begin
        // filename + line
        FBreakpoint.SetLocation(edtFilename.Text, edtLine.Value);
      end;
    bpkAddress:
      begin
        FBreakpoint.SetAddress(StrToQWordDef(edtFilename.Text, 0));
      end;
  end;
  // expression
  FBreakpoint.Expression := edtCondition.Text;
  // hitcount
  FBreakpoint.BreakHitCount := StrToIntDef(edtCounter.Text, FBreakpoint.HitCount);
  //auto continue
  FBreakpoint.AutoContinueTime := StrToIntDef(edtAutocontinueMS.Text, FBreakpoint.AutoContinueTime);
  // group
  FBreakpoint.Group := DebugBoss.BreakPointGroups.GetGroupByName(cmbGroup.Text);
  // actions
  Actions := [];
  if chkActionBreak.Checked then Include(Actions, bpaStop);
  if chkDisableGroups.Checked then Include(Actions, bpaDisableGroup);
  if chkEnableGroups.Checked then Include(Actions, bpaEnableGroup);
//  if chkEvalExpression.Checked then Include(Actions, bpaEValExpression);
  if chkLogMessage.Checked then Include(Actions, bpaLogMessage);
  FBreakpoint.Actions := Actions;
  FBreakpoint.LogMessage := edtLogMessage.Text;

  InputHistories.HistoryLists.GetList('BreakPointExpression', True).Add(edtCondition.Text);
end;

procedure TBreakPropertyDlg.DoEndUpdate;
begin
  inherited DoEndUpdate;
  UpdateInfo;
end;

procedure TBreakPropertyDlg.UpdateInfo;
var
  Actions: TIDEBreakPointActions;
begin
  if FBreakpoint = nil then Exit;
  case FBreakpoint.Kind of
    bpkSource:
      begin
        // filename
        edtFilename.Text := FBreakpoint.Source;
        // line
        if FBreakpoint.Line > 0
        then edtLine.Value := FBreakpoint.Line
        else edtLine.Value := 0;
      end;
    bpkAddress:
      begin
        edtFilename.Text := '$' + IntToHex(FBreakpoint.Address, 8); // todo: 8/16 depends on platform
      end;
  end;
  // expression
  edtCondition.Text := FBreakpoint.Expression;
  // hitcount
  edtCounter.Text := IntToStr(FBreakpoint.BreakHitCount);
  // auto continue
  edtAutocontinueMS.Text := IntToStr(FBreakpoint.AutoContinueTime);
  // group
  if FBreakpoint.Group = nil
  then cmbGroup.Text := ''
  else cmbGroup.Text := FBreakpoint.Group.Name;

  // actions
  Actions := FBreakpoint.Actions;
  chkActionBreak.Checked := bpaStop in Actions;
  chkDisableGroups.Checked := bpaDisableGroup in Actions;
  chkEnableGroups.Checked := bpaEnableGroup in Actions;
//  chkEvalExpression.Checked := bpaEValExpression in Actions;
  chkLogMessage.Checked := bpaLogMessage in Actions;
  edtLogMessage.Text := FBreakpoint.LogMessage;
end;

constructor TBreakPropertyDlg.Create(AOwner: TComponent; ABreakPoint: TIDEBreakPoint);
begin
  inherited Create(AOwner);

  Caption := lisBreakPointProperties;
  case ABreakPoint.Kind of
    bpkSource:
      begin
        lblFileName.Caption := lisPEFilename;
        lblLine.Caption := lisLine;
      end;
    bpkAddress:
      begin
        lblFileName.Caption := lisAddress;
        lblLine.Visible := False;
        edtLine.Visible := False;
        edtFilename.ReadOnly := False;
        edtFilename.Color := clDefault;
      end;
  end;
  lblCondition.Caption := lisCondition + ':';
  lblHitCount.Caption := lisHitCount + ':';
  lblAutoContinue.Caption := lisAutoContinueAfter;
  lblMS.Caption := lisMS;
  lblGroup.Caption := lisGroup + ':';
  gbActions.Caption := lisActions;
  chkActionBreak.Caption := lisBreak;
  chkEnableGroups.Caption := lisEnableGroup;
  chkDisableGroups.Caption := lisDisableGroup;
  chkEvalExpression.Caption := lisEvalExpression;
  chkLogMessage.Caption := lisLogMessage;
  edtCondition.Items.Assign(InputHistories.HistoryLists.GetList('BreakPointExpression', True));

  FBreakpoint := ABreakPoint;
  FBreakpointsNotification := TIDEBreakPointsNotification.Create;
  FBreakpointsNotification.AddReference;
  FBreakpointsNotification.OnUpdate := @BreakPointUpdate;
  FBreakpointsNotification.OnRemove := @BreakPointRemove;
  UpdateInfo;

  ButtonPanel.OKButton.Caption:=lisOk;
  ButtonPanel.HelpButton.Caption:=lisMenuHelp;
  ButtonPanel.CancelButton.Caption:=dlgCancel;
end;

destructor TBreakPropertyDlg.Destroy;
begin
  FBreakpointsNotification.OnUpdate := nil;
  FBreakpointsNotification.OnRemove := nil;
  FBreakpointsNotification.ReleaseReference;
  FBreakpointsNotification := nil;
  inherited Destroy;
end;

end.

