{
 /***************************************************************************
                               extdlgs.pas
                               -----------
                Component Library Extended dialogs Controls


 ***************************************************************************/

 *****************************************************************************
 *                                                                           *
 *  This file is part of the Lazarus Component Library (LCL)                 *
 *                                                                           *
 *  See the file COPYING.LCL, included in this distribution,                 *
 *  for details about the copyright.                                         *
 *                                                                           *
 *  This program is distributed in the hope that it will be useful,          *
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of           *
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                     *
 *                                                                           *
 *****************************************************************************
}
unit ExtDlgs;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LCLProc, LResources, VCLGlobals, LCLType, LCLStrConsts,
  Controls, Dialogs, GraphType, Graphics, ExtCtrls, StdCtrls, Forms, FileCtrl,
  Calendar, Buttons;

type

  { TPreviewFileControl }

  TPreviewFileDialog = class;

  TPreviewFileControl = class(TWinControl)
  private
    FPreviewFileDialog: TPreviewFileDialog;
  protected
    procedure SetPreviewFileDialog(const AValue: TPreviewFileDialog);
    procedure CreateParams(var Params: TCreateParams); override;
  public
    constructor Create(TheOwner: TComponent); override;
    property PreviewFileDialog: TPreviewFileDialog read FPreviewFileDialog
                                                   write SetPreviewFileDialog;
  end;


  { TPreviewFileDialog }

  TPreviewFileDialog = class(TOpenDialog)
  private
    FPreviewFileControl: TPreviewFileControl;
  protected
    procedure CreatePreviewControl; virtual;
    procedure InitPreviewControl; virtual;
  public
    function Execute: boolean; override;
    constructor Create(TheOwner: TComponent); override;
    property PreviewFileControl: TPreviewFileControl read FPreviewFileControl;
  end;


  { TOpenPictureDialog }

  TOpenPictureDialog = class(TPreviewFileDialog)
  private
    FDefaultFilter: string;
    FImageCtrl: TImage;
    FPictureGroupBox: TGroupBox;
    FPreviewFilename: string;
  protected
    function  IsFilterStored: Boolean; virtual;
    procedure PreviewKeyDown(Sender: TObject; var Key: word); virtual;
    procedure PreviewClick(Sender: TObject); virtual;
    procedure DoClose; override;
    procedure DoSelectionChange; override;
    procedure DoShow; override;
    property ImageCtrl: TImage read FImageCtrl;
    property PictureGroupBox: TGroupBox read FPictureGroupBox;
    procedure InitPreviewControl; override;
    procedure ClearPreview; virtual;
    procedure UpdatePreview; virtual;
  public
    constructor Create(TheOwner: TComponent); override;
    property DefaultFilter: string read FDefaultFilter;
  published
    property Filter stored IsFilterStored;
  end;


  { TSavePictureDialog }

  TSavePictureDialog = class(TOpenPictureDialog)
  public
    constructor Create(TheOwner: TComponent); override;
  end;

{ ---------------------------------------------------------------------
  Calculator Dialog
  ---------------------------------------------------------------------}

const
  DefCalcPrecision = 15;

type
  TCalcState = (csFirst, csValid, csError);
  TCalculatorLayout = (clNormal, clSimple);
  TCalculatorForm = class;

{ TCalculatorDialog }

  TCalculatorDialog = class(TCommonDialog)
  private
    FLayout: TCalculatorLayout;
    FValue: Double;
    FMemory: Double;
    FTitle: String;
    FCtl3D: Boolean;
    FPrecision: Byte;
    FBeepOnError: Boolean;
    FHelpContext: THelpContext;
    FCalc: TCalculatorForm;
    FOnChange: TNotifyEvent;
    FOnCalcKey: TKeyPressEvent;
    FOnDisplayChange: TNotifyEvent;
    function GetDisplay: Double;
    function GetTitle: string;
    procedure SetTitle(const AValue: string);
    function TitleStored: Boolean;
  protected
    procedure Change; dynamic;
    procedure CalcKey(var Key: TCharacter); dynamic;
    procedure DisplayChange; dynamic;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function Execute: Boolean; override;
    property CalcDisplay: Double read GetDisplay;
    property Memory: Double read FMemory;
  published
    property BeepOnError: Boolean read FBeepOnError write FBeepOnError default True;
    property Ctl3D: Boolean read FCtl3D write FCtl3D default True;
    property HelpContext: THelpContext read FHelpContext write FHelpContext default 0;
    Property CalculatorLayout : TCalculatorLayout Read FLayout Write Flayout;
    property Precision: Byte read FPrecision write FPrecision default DefCalcPrecision;
    property Title: string read GetTitle write SetTitle stored TitleStored;
    property Value: Double read FValue write FValue;
    property OnCalcKey: TKeyPressEvent read FOnCalcKey write FOnCalcKey;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property OnDisplayChange: TNotifyEvent read FOnDisplayChange write FOnDisplayChange;
  end;

{ TCalculatorForm }

  TCalculatorForm = class(TForm)
  private
    FMainPanel: TPanel;
    FCalcPanel: TPanel;
    FDisplayPanel: TPanel;
    FDisplayLabel: TLabel;
    procedure FormKeyPress(Sender: TObject; var Key: TCharacter);
    procedure CopyItemClick(Sender: TObject);
    function GetValue: Double;
    procedure PasteItemClick(Sender: TObject);
    procedure SetValue(const AValue: Double);
  protected
    procedure OkClick(Sender: TObject);
    procedure CancelClick(Sender: TObject);
    procedure CalcKey(Sender: TObject; var Key: TCharacter);
    procedure DisplayChange(Sender: TObject);
    Procedure InitForm(ALayout : TCalculatorLayout); virtual;
    Property MainPanel: TPanel Read FMainPanel;
    Property CalcPanel: TPanel Read FCalcPanel;
    Property DisplayPanel: TPanel Read FDisplayPanel;
    Property DisplayLabel: TLabel Read FDisplayLabel;
  public
    constructor Create(AOwner: TComponent); override;
    constructor CreateLayout(AOwner: TComponent;ALayout : TCalculatorLayout);
    Property Value : Double Read GetValue Write SetValue;
  end;

function CreateCalculatorForm(AOwner: TComponent; ALayout : TCalculatorLayout; AHelpContext: THelpContext): TCalculatorForm;

{ ---------------------------------------------------------------------
  Date Dialog
  ---------------------------------------------------------------------}


Type
  TCalendarDialogForm = Class(TForm)
  private
    FCalendar : TCalendar;
    FPanel : TPanel;
    FOK : TButton;
    FCancel : TButton;
    function GetDate: TDateTime;
    Procedure SetDate (Value : TDateTime);
    function GetDisplaySettings: TDisplaySettings;
    procedure SetDisplaySettings(const AValue: TDisplaySettings);
  Protected
    Property Calendar : TCalendar Read FCalendar;
    Property ButtonPanel : TPanel Read FPanel;
    Property OKButton : TButton Read FOK;
    Property CancelButton : TButton Read FCancel;
    Procedure InitForm; virtual;
  Public
    Constructor Create(AOwner : TComponent); override;
    Destructor Destroy; override;
    Property Date : TDateTime Read GetDate Write SetDate;
    Property DisplaySettings : TDisplaySettings Read GetDisplaySettings Write SetDisplaySettings;
  end;

  TCalendarDialog = class(TCommonDialog)
  private
    FDate: TDateTime;
    FDayChanged: TNotifyEvent;
    FDisplaySettings: TDisplaySettings;
    FHelpContext: THelpContext;
    FMonthChanged: TNotifyEvent;
    FYearChanged: TNotifyEvent;
    function GetDialogTitle: String;
    procedure SetDialogTitle(const AValue: String);
    Function IsTitleStored: Boolean;
  Public
    Constructor Create(AOwner: TComponent); override;
    Destructor Destroy; override;
    Function Execute: Boolean; override;
    Function CreateForm: TCalendarDialogForm; virtual;
  Published
    Property DialogTitle: String Read GetDialogTitle Write SetDialogTitle Stored IsTitleStored;
    Property Date: TDateTime Read FDate Write FDate;
    Property DisplaySettings: TDisplaySettings Read FDisplaySettings Write FDisplaySettings;
    property HelpContext: THelpContext read FHelpContext write FHelpContext default 0;
    property OnDayChanged: TNotifyEvent read FDayChanged write FDayChanged;
    property OnMonthChanged: TNotifyEvent read FMonthChanged write FMonthChanged;
    property OnYearChanged: TNotifyEvent read FYearChanged write FYearChanged;
  end;

function CreateCalendarForm(AOwner: TComponent; AHelpContext: THelpContext): TCalendarDialogForm;


procedure Register;


implementation


procedure Register;
begin
  RegisterComponents('Dialogs',[TOpenPictureDialog,TSavePictureDialog,
                                TCalendarDialog,TCalculatorDialog]);
end;

{ TPreviewFileControl }

procedure TPreviewFileControl.SetPreviewFileDialog(
  const AValue: TPreviewFileDialog);
begin
  if FPreviewFileDialog=AValue then exit;
  FPreviewFileDialog:=AValue;
end;

procedure TPreviewFileControl.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  Params.Style := Params.Style and DWORD(not WS_CHILD);
end;

constructor TPreviewFileControl.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  FCompStyle:=csPreviewFileControl;
  SetInitialBounds(0,0,200,200);
end;

{ TPreviewFileDialog }

procedure TPreviewFileDialog.CreatePreviewControl;
begin
  if FPreviewFileControl<>nil then exit;
  FPreviewFileControl:=TPreviewFileControl.Create(Self);
  FPreviewFileControl.PreviewFileDialog:=Self;
  InitPreviewControl;
end;

procedure TPreviewFileDialog.InitPreviewControl;
begin
  FPreviewFileControl.Name:='PreviewFileControl';
end;

function TPreviewFileDialog.Execute: boolean;
begin
  CreatePreviewControl;
  Result:=inherited Execute;
end;

constructor TPreviewFileDialog.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  FCompStyle:=csPreviewFileDialog;
end;

{ TOpenPictureDialog }

function TOpenPictureDialog.IsFilterStored: Boolean;
begin
  Result := (Filter<>FDefaultFilter);
end;

procedure TOpenPictureDialog.PreviewKeyDown(Sender: TObject; var Key: word);
begin
  if Key = VK_ESCAPE then TForm(Sender).Close;
end;

procedure TOpenPictureDialog.PreviewClick(Sender: TObject);
begin

end;

procedure TOpenPictureDialog.DoClose;
begin
  ClearPreview;
  inherited DoClose;
end;

procedure TOpenPictureDialog.DoSelectionChange;
begin
  UpdatePreview;
  inherited DoSelectionChange;
end;

procedure TOpenPictureDialog.DoShow;
begin
  ClearPreview;
  inherited DoShow;
end;

procedure TOpenPictureDialog.InitPreviewControl;
begin
  inherited InitPreviewControl;
  FPictureGroupBox.Parent:=PreviewFileControl;
end;

procedure TOpenPictureDialog.ClearPreview;
begin
  FPictureGroupBox.Caption:='None';
  FImageCtrl.Picture:=nil;
end;

procedure TOpenPictureDialog.UpdatePreview;
var
  CurFilename: String;
  FileIsValid: boolean;
begin
  CurFilename := FileName;
  if CurFilename = FPreviewFilename then exit;

  FPreviewFilename := CurFilename;
  FileIsValid := FileExists(FPreviewFilename)
                 and (not DirPathExists(FPreviewFilename))
                 and FileIsReadable(FPreviewFilename);
  if FileIsValid then
    try
      FImageCtrl.Picture.LoadFromFile(FPreviewFilename);
      FPictureGroupBox.Caption := Format('(%dx%d)',
        [FImageCtrl.Picture.Width, FImageCtrl.Picture.Height]);
    except
      FileIsValid := False;
    end;
  if not FileIsValid then
    ClearPreview;
end;

constructor TOpenPictureDialog.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  FDefaultFilter := 'All files ('+GetAllFilesMask+')|'+GetAllFilesMask+'|'
                    +GraphicFilter(TGraphic);
  Filter:=FDefaultFilter;

  FPictureGroupBox:=TGroupBox.Create(Self);
  with FPictureGroupBox do begin
    Name:='FPictureGroupBox';
    Align:=alClient;
  end;

  FImageCtrl:=TImage.Create(Self);
  with FImageCtrl do begin
    Name:='FImageCtrl';
    Parent:=FPictureGroupBox;
    Align:=alClient;
    Center:=true;
    Proportional:=true;
  end;
end;

{ TSavePictureDialog }

constructor TSavePictureDialog.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  Title:=rsfdFileSaveAs;
end;

type
  TCalcBtnKind =
   (cbNone, cbNum0, cbNum1, cbNum2, cbNum3, cbNum4, cbNum5, cbNum6,
    cbNum7, cbNum8, cbNum9, cbSgn, cbDcm, cbDiv, cbMul, cbSub,
    cbAdd, cbSqr, cbPcnt, cbRev, cbEql, cbBck, cbClr, cbMP,
    cbMS, cbMR, cbMC, cbOk, cbCancel);

const
  BtnPos: array[TCalculatorLayout, TCalcBtnKind] of TPoint =
  (((X: -1; Y: -1), (X: 47; Y: 104), (X: 47; Y: 80), (X: 85; Y: 80),
    (X: 123; Y: 80), (X: 47; Y: 56), (X: 85; Y: 56), (X: 123; Y: 56),
    (X: 47; Y: 32), (X: 85; Y: 32), (X: 123; Y: 32), (X: 85; Y: 104),
    (X: 123; Y: 104), (X: 161; Y: 32), (X: 161; Y: 56), (X: 161; Y: 80),
    (X: 161; Y: 104), (X: 199; Y: 32), (X: 199; Y: 56), (X: 199; Y: 80),
    (X: 199; Y: 104), (X: 145; Y: 6), (X: 191; Y: 6), (X: 5; Y: 104),
    (X: 5; Y: 80), (X: 5; Y: 56), (X: 5; Y: 32),
    (X: 47; Y: 6), (X: 85; Y: 6)),
   ((X: -1; Y: -1), (X: 6; Y: 75), (X: 6; Y: 52), (X: 29; Y: 52),
    (X: 52; Y: 52), (X: 6; Y: 29), (X: 29; Y: 29), (X: 52; Y: 29),
    (X: 6; Y: 6), (X: 29; Y: 6), (X: 52; Y: 6), (X: 52; Y: 75),
    (X: 29; Y: 75), (X: 75; Y: 6), (X: 75; Y: 29), (X: 75; Y: 52),
    (X: 75; Y: 75), (X: -1; Y: -1), (X: -1; Y: -1), (X: -1; Y: -1),
    (X: 52; Y: 98), (X: 29; Y: 98), (X: 6; Y: 98), (X: -1; Y: -1),
    (X: -1; Y: -1), (X: -1; Y: -1), (X: -1; Y: -1),
    (X: -1; Y: -1), (X: -1; Y: -1)));
  BtnSizes: array[TCalculatorLayout,1..2] of Integer =
    ((36,22),(21,21));
  PanelSizes: array[TCalculatorLayout,1..2] of Integer =
    ((129,140),(124,98));
  ResultKeys = [#13, '=', '%'];
  BtnGlyphs: array[TCalculatorLayout,cbSgn..cbCancel] of String =
   (('btncalcpmin','','','btncalcmul','btncalcmin','btncalcplus', '',
     '','','','','','','','','', 'btncalcok', 'btncalccancel'),
    ('btncalcpmin','','','btncalcmul','btncalcmin','btncalcplus', '',
     '','','','','','','','','', 'btncalcok', 'btncalccancel')
   );
  BtnCaptions: array[cbSgn..cbMC] of String =
   ('�', ',', '/', '*', '-', '+', 'sqrt', '%', '1/x', '=', '<-', 'C',
    'MP', 'MS', 'MR', 'MC');

{ ---------------------------------------------------------------------
  Auxiliary
  ---------------------------------------------------------------------}

procedure SetDefaultFont(AFont: TFont; Layout: TCalculatorLayout);

begin
  with AFont do
    begin
    Color:=clWindowText;
    Name:='MS Sans Serif';
    Size:=8;
    Style:=[fsBold];
    end;
end;

function CreateCalculatorForm(AOwner: TComponent; ALayout : TCalculatorLayout; AHelpContext: THelpContext): TCalculatorForm;
begin
  Result:=TCalculatorForm.Create(AOwner);
  with Result do
    try
      HelpContext:=AHelpContext;
      if Screen.PixelsPerInch <> 96 then
        begin { scale to screen res }
        SetDefaultFont(Font, ALayout);
        Left:=(Screen.Width div 2) - (Width div 2);
        Top:=(Screen.Height div 2) - (Height div 2);
        end;
    except
      Free;
      raise;
    end;
end;

function CreateCalendarForm(AOwner: TComponent; AHelpContext: THelpContext
  ): TCalendarDialogForm;
begin
  Result:=TCalendarDialogForm.Create(AOwner);
  With Result do
    Try
      HelpContext:=AHelpContext;
      Left:=(Screen.Width div 2) - (Width div 2);
      Top:=(Screen.Height div 2) - (Height div 2);
    except
      Free;
      Raise;
    end;
end;

{ ---------------------------------------------------------------------
  Calculator Dialog
  ---------------------------------------------------------------------}


{ TCalcButton }

type
  TCalcButton = class(TCustomSpeedButton)
  private
    FKind: TCalcBtnKind;
  public
    constructor CreateKind(AOwner: TComponent; AKind: TCalcBtnKind);
    property Kind: TCalcBtnKind read FKind;
    property ParentFont;
  end;

constructor TCalcButton.CreateKind(AOwner: TComponent; AKind: TCalcBtnKind);
begin
  inherited Create(AOwner);
  FKind:=AKind;
  if FKind in [cbNum0..cbClr] then
    Tag:=Ord(Kind) - 1
  else
    Tag:=-1;
end;

function CreateCalcBtn(AParent: TWinControl; AKind: TCalcBtnKind;
  AOnClick: TNotifyEvent; ALayout: TCalculatorLayout): TCalcButton;

begin
  Result:=TCalcButton.CreateKind(AParent, AKind);
  with Result do
    try
      if Kind in [cbNum0..cbNum9] then
        Caption:=IntToStr(Tag)
      else if Kind = cbDcm then
        Caption:=DecimalSeparator
      else if Kind in [cbSgn..cbMC] then
        Caption:=BtnCaptions[Kind];
      Left:=BtnPos[ALayout, Kind].X;
      Top:=BtnPos[ALayout, Kind].Y;
      Width:=BtnSizes[ALayout,1];
      Height:=BtnSizes[ALayout,2];
      OnClick:=AOnClick;
      ParentFont:=True;
      Parent:=AParent;
    except
      Free;
      raise;
    end;
end;

{ TCalculatorPanel }

type
  TCalculatorPanel = class(TPanel)
  private
    FText: string;
    FStatus: TCalcState;
    FOperator: Char;
    FOperand: Double;
    FMemory: Double;
    FPrecision: Byte;
    FBeepOnError: Boolean;
    FMemoryPanel: TPanel;
    FMemoryLabel: TLabel;
    FOnError: TNotifyEvent;
    FOnOk: TNotifyEvent;
    FOnCancel: TNotifyEvent;
    FOnResult: TNotifyEvent;
    FOnTextChange: TNotifyEvent;
    FOnCalcKey: TKeyPressEvent;
    FOnDisplayChange: TNotifyEvent;
    FControl: TControl;
    procedure SetCalcText(const Value: string);
    procedure CheckFirst;
    procedure CalcKey(Key: TCharacter);
    procedure Clear;
    procedure Error;
    procedure SetDisplay(R: Double);
    function GetDisplay: Double;
    procedure UpdateMemoryLabel;
    function FindButton(Key: Char): TCustomSpeedButton;
    procedure BtnClick(Sender: TObject);
  protected
    procedure ErrorBeep;
    procedure TextChanged; virtual;
  public
    constructor CreateLayout(AOwner: TComponent; ALayout: TCalculatorLayout);
    procedure CalcKeyPress(Sender: TObject; var Key: TCharacter);
    procedure Copy;
    procedure Paste;
    Function WorkingPrecision : Integer;
    property DisplayValue: Double read GetDisplay write SetDisplay;
    property Text: string read FText;
    property OnOkClick: TNotifyEvent read FOnOk write FOnOk;
    property OnCancelClick: TNotifyEvent read FOnCancel write FOnCancel;
    property OnResultClick: TNotifyEvent read FOnResult write FOnResult;
    property OnError: TNotifyEvent read FOnError write FOnError;
    property OnTextChange: TNotifyEvent read FOnTextChange write FOnTextChange;
    property OnCalcKey: TKeyPressEvent read FOnCalcKey write FOnCalcKey;
    property OnDisplayChange: TNotifyEvent read FOnDisplayChange write FOnDisplayChange;
    property Color default clBtnFace;
  end;

constructor TCalculatorPanel.CreateLayout(AOwner: TComponent;
  ALayout: TCalculatorLayout);

var
  I: TCalcBtnKind;

begin
  inherited Create(AOwner);
  ParentColor:=False;
  Color:=clBtnFace;
  Height:=PanelSizes[ALayout,1];
  Width:=PanelSizes[ALayout,2];
  SetDefaultFont(Font, ALayout);
  ParentFont:=False;
  BevelOuter:=bvNone;
  BevelInner:=bvNone;
  ParentColor:=True;
  ParentCtl3D:=True;
  for I:=cbNum0 to cbCancel do
    begin
    if BtnPos[ALayout, I].X > 0 then
      with CreateCalcBtn(Self, I, @BtnClick, ALayout) do
        begin
        if ALayout = clNormal then
          begin
          if (Kind in [cbBck, cbClr]) then
            Width:=44;
          if (Kind in [cbSgn..cbCancel]) then
            if (BtnGlyphs[ALayout,Kind]<>'') then
              begin
              Caption:='';
              Glyph.LoadFromLazarusResource(BtnGlyphs[ALayout,Kind]);
              end;
          end
        else
          begin
          if Kind in [cbEql] then Width:=44;
          end;
        end;
    end;
  if ALayout = clNormal then
    begin
    { Memory panel }
    FMemoryPanel:=TPanel.Create(Self);
    with FMemoryPanel do
      begin
      SetBounds(6, 7, 34, 20);
      BevelInner:=bvLowered;
      BevelOuter:=bvNone;
      ParentColor:=True;
      Parent:=Self;
      end;
    FMemoryLabel:=TLabel.Create(Self);
    with FMemoryLabel do
      begin
      SetBounds(3, 3, 26, 14);
      Alignment:=taCenter;
      AutoSize:=False;
      Parent:=FMemoryPanel;
      Font.Style:=[];
      end;
    end;
  FText:='0';
  FMemory:=0.0;
  FPrecision:=DefCalcPrecision;
  FBeepOnError:=True;
end;

procedure TCalculatorPanel.SetCalcText(const Value: string);
begin
  if FText <> Value then
    begin
    FText:=Value;
    TextChanged;
    end;
end;

procedure TCalculatorPanel.TextChanged;
begin
  if Assigned(FControl) then
    TLabel(FControl).Caption:=FText;
  if Assigned(FOnTextChange) then
    FOnTextChange(Self);
end;

procedure TCalculatorPanel.ErrorBeep;

begin
 if FBeepOnError then
   // MessageBeep(0);
end;

procedure TCalculatorPanel.Error;
begin
  FStatus:=csError;
  SetCalcText(rsError);
  ErrorBeep;
  if Assigned(FOnError) then
    FOnError(Self);
end;

procedure TCalculatorPanel.SetDisplay(R: Double);
var
  S: string;
begin
  S:=FloatToStrF(R, ffGeneral, WorkingPrecision, 0);
  if FText <> S then
    begin
    SetCalcText(S);
    if Assigned(FOnDisplayChange) then
      FOnDisplayChange(Self);
    end;
end;

function TCalculatorPanel.GetDisplay: Double;
begin
  if (FStatus=csError) then
    Result:=0.0
  else
    Result:=StrToDouble(Trim(FText));
end;

procedure TCalculatorPanel.CheckFirst;
begin
  if (FStatus=csFirst) then
    begin
    FStatus:=csValid;
    SetCalcText('0');
    end;
end;

procedure TCalculatorPanel.UpdateMemoryLabel;
begin
  if (FMemoryLabel<>nil) then
    if (FMemory<>0.0) then
      FMemoryLabel.Caption:='M'
    else
      FMemoryLabel.Caption:='';
end;

Function TCalculatorPanel.WorkingPrecision : Integer;

begin
  Result:=2;
  If FPrecision>2 then
    Result:=FPrecision;
end;


procedure TCalculatorPanel.CalcKey(Key: TCharacter);
var
  R: Double;
begin
{$IFDEF GTK1}
  Key:=UpCase(Key);
{$ENDIF GTK1}
  if (FStatus = csError) and (Key <> 'C') then
    Key:=#0;
  if Assigned(FOnCalcKey) then
    FOnCalcKey(Self, Key);
  if Key in [DecimalSeparator, '.', ','] then
    begin
    CheckFirst;
    if Pos(DecimalSeparator, FText) = 0 then
      SetCalcText(FText + DecimalSeparator);
    end
  else
    case Key of
      'R':
        if (FStatus in [csValid, csFirst]) then
          begin
          FStatus:=csFirst;
          if GetDisplay = 0 then
            Error
          else
            SetDisplay(1.0 / GetDisplay);
          end;
      'Q':
        if FStatus in [csValid, csFirst] then
          begin
          FStatus:=csFirst;
          if GetDisplay < 0 then
            Error
          else
            SetDisplay(Sqrt(GetDisplay));
          end;
      '0'..'9':
        begin
        CheckFirst;
        if (FText='0') then
          SetCalcText('');
        if (Pos('E', FText)=0) then
          begin
          if (Length(FText) < WorkingPrecision + Ord(Boolean(Pos('-', FText)))) then
            SetCalcText(FText + Key)
          else
            ErrorBeep;
          end;
        end;
      #8:
        begin
        CheckFirst;
        if ((Length(FText)=1) or ((Length(FText)=2) and (FText[1]='-'))) then
          SetCalcText('0')
        else
          SetCalcText(System.Copy(FText,1,Length(FText)-1));
        end;
      '_':
        SetDisplay(-GetDisplay);
      '+', '-', '*', '/', '=', '%', #13:
        begin
        if (FStatus=csValid) then
          begin
          FStatus:=csFirst;
          R:=GetDisplay;
          if (Key='%') then
            case FOperator of
              '+', '-': R:=(FOperand*R)/100.0;
              '*', '/': R:=R/100.0;
            end;
          case FOperator of
            '+': SetDisplay(FOperand+R);
            '-': SetDisplay(FOperand-R);
            '*': SetDisplay(FOperand*R);
            '/': if R = 0 then
                   Error
                 else
                   SetDisplay(FOperand / R);
          end;
        end;
        FOperator:=Key;
        FOperand:=GetDisplay;
        if (Key in ResultKeys) and Assigned(FOnResult) then
          FOnResult(Self);
        end;
      #27, 'C':
        Clear;
      ^C:
        Copy;
      ^V:
        Paste;
    end;
end;

procedure TCalculatorPanel.Clear;
begin
  FStatus:=csFirst;
  SetDisplay(0.0);
  FOperator:='=';
end;

procedure TCalculatorPanel.CalcKeyPress(Sender: TObject; var Key: TCharacter);

var
  Btn: TCustomSpeedButton;

begin
  Btn:=FindButton(Key);
  if Assigned(Btn) then
    Btn.Click
  else
    CalcKey(Key);
end;

function TCalculatorPanel.FindButton(Key: Char): TCustomSpeedButton;
const
  ButtonChars = '0123456789_./*-+Q%R='#8'C';
var
  I: Integer;
  BtnTag: Longint;
begin
  if Key in [DecimalSeparator, '.', ','] then
    Key:='.'
  else if Key = #13 then
    Key:='='
  else if Key = #27 then
    Key:='C';
  Result:=nil;
  BtnTag:=Pos(UpCase(Key), ButtonChars) - 1;
  if (BtnTag>=0) then
    begin
    I:=0;
    While (Result=Nil) and (I<ControlCount) do
      begin
      if Controls[I] is TCustomSpeedButton then
        If BtnTag=TCustomSpeedButton(Controls[I]).Tag then
          Result:=TCustomSpeedButton(Controls[I]);
      Inc(I);
      end;
    end;
end;

procedure TCalculatorPanel.BtnClick(Sender: TObject);
begin
  case TCalcButton(Sender).Kind of
    cbNum0..cbNum9: CalcKey(Char(TComponent(Sender).Tag + Ord('0')));
    cbSgn: CalcKey('_');
    cbDcm: CalcKey(DecimalSeparator);
    cbDiv: CalcKey('/');
    cbMul: CalcKey('*');
    cbSub: CalcKey('-');
    cbAdd: CalcKey('+');
    cbSqr: CalcKey('Q');
    cbPcnt: CalcKey('%');
    cbRev: CalcKey('R');
    cbEql: CalcKey('=');
    cbBck: CalcKey(#8);
    cbClr: CalcKey('C');
    cbMP:
      if (FStatus in [csValid, csFirst]) then
        begin
        FStatus:=csFirst;
        FMemory:=FMemory + GetDisplay;
        UpdateMemoryLabel;
        end;
    cbMS:
      if FStatus in [csValid, csFirst] then
        begin
        FStatus:=csFirst;
        FMemory:=GetDisplay;
        UpdateMemoryLabel;
        end;
    cbMR:
      if (FStatus in [csValid, csFirst]) then
        begin
        FStatus:=csFirst;
        CheckFirst;
        SetDisplay(FMemory);
        end;
    cbMC:
        begin
        FMemory:=0.0;
        UpdateMemoryLabel;
        end;
    cbOk:
        begin
        if FStatus <> csError then
          begin
          DisplayValue:=DisplayValue; { to raise exception on error }
          if Assigned(FOnOk) then
            FOnOk(Self);
          end
        else
          ErrorBeep;
        end;
    cbCancel:
        if Assigned(FOnCancel) then
          FOnCancel(Self);
  end;
end;

procedure TCalculatorPanel.Copy;
begin
  // Clipboard.AsText:=FText;
end;

procedure TCalculatorPanel.Paste;
begin
{  if Clipboard.HasFormat(CF_TEXT) then
    try
      SetDisplay(StrToFloat(Trim(ReplaceStr(Clipboard.AsText,
        CurrencyString, ''))));
    except
      SetCalcText('0');
    end;
}
end;

{ TCalculatorDialog }

constructor TCalculatorDialog.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FTitle:=rsCalculator;
  FCtl3D:=True;
  FPrecision:=DefCalcPrecision;
  FBeepOnError:=True;
end;

destructor TCalculatorDialog.Destroy;
begin
  FOnChange:=nil;
  FOnDisplayChange:=nil;
  inherited Destroy;
end;

function TCalculatorDialog.GetTitle: string;
begin
  Result:=FTitle;
end;

procedure TCalculatorDialog.SetTitle(const AValue: string);
begin
  FTitle:=AValue;
end;

function TCalculatorDialog.TitleStored: Boolean;
begin
  Result:=Title <> rsCalculator;
end;

function TCalculatorDialog.GetDisplay: Double;
begin
  if Assigned(FCalc) then
    Result:=TCalculatorPanel(FCalc.FCalcPanel).GetDisplay
  else Result:=FValue;
end;

procedure TCalculatorDialog.CalcKey(var Key: TCharacter);
begin
  if Assigned(FOnCalcKey) then FOnCalcKey(Self, Key);
end;

procedure TCalculatorDialog.DisplayChange;
begin
  if Assigned(FOnDisplayChange) then FOnDisplayChange(Self);
end;

procedure TCalculatorDialog.Change;
begin
  if Assigned(FOnChange) then FOnChange(Self);
end;

function TCalculatorDialog.Execute: Boolean;
begin
  FCalc:=CreateCalculatorForm(Self, FLayout, HelpContext);
  with FCalc do
  try
    Ctl3D:=FCtl3D;
    Caption:=Self.Title;
    TCalculatorPanel(FCalcPanel).FMemory:=Self.FMemory;
    TCalculatorPanel(FCalcPanel).UpdateMemoryLabel;
    If Self.Precision>2 then
      TCalculatorPanel(FCalcPanel).FPrecision:=Self.Precision
    else
      TCalculatorPanel(FCalcPanel).FPrecision:=2;
    TCalculatorPanel(FCalcPanel).FBeepOnError:=Self.BeepOnError;
    if Self.FValue <> 0 then begin
      TCalculatorPanel(FCalcPanel).DisplayValue:=Self.FValue;
      TCalculatorPanel(FCalcPanel).FStatus:=csFirst;
      TCalculatorPanel(FCalcPanel).FOperator:='=';
    end;
    Result:=(ShowModal = mrOk);
    if Result then begin
      Self.FMemory:=TCalculatorPanel(FCalcPanel).FMemory;
      if (TCalculatorPanel(FCalcPanel).DisplayValue <> Self.FValue) then begin
        Self.FValue:=TCalculatorPanel(FCalcPanel).DisplayValue;
        Change;
      end;
    end;
  finally
    Free;
    FCalc:=nil;
  end;
end;

{ TCalculatorForm }

constructor TCalculatorForm.Create(AOwner: TComponent);

begin
  inherited CreateNew(AOwner, 0);
  InitForm(clNormal);
end;

constructor TCalculatorForm.CreateLayout(AOwner: TComponent;ALayout : TCalculatorLayout);

begin
  inherited CreateNew(AOwner, 0);
  InitForm(ALayout);
end;


Procedure TCalculatorForm.InitForm(ALayout : TCalculatorLayout);
begin
  BorderStyle:=bsDialog;
  Caption:=rsCalculator;
  ClientHeight:=159;
  ClientWidth:=242;
  SetDefaultFont(Font, ALayout);
  KeyPreview:=True;
  PixelsPerInch:=96;
  Position:=poScreenCenter;
  OnKeyPress:=@FormKeyPress;
  { MainPanel }
  FMainPanel:=TPanel.Create(Self);
  with FMainPanel do
    begin
    Align:=alClient;
    Parent:=Self;
    BevelOuter:=bvLowered;
    ParentColor:=True;
    end;
  { DisplayPanel }
  FDisplayPanel:=TPanel.Create(Self);
  with FDisplayPanel do
    begin
    SetBounds(6, 6, 230, 23);
    Parent:=FMainPanel;
    BevelOuter:=bvLowered;
    Color:=clWhite;
    Ctl3D:=False;
    Font:=Self.Font;
    end;
  FDisplayLabel:=TLabel.Create(Self);
  with FDisplayLabel do
    begin
    AutoSize:=False;
    Alignment:=taRightJustify;
    SetBounds(5, 2, 217, 15);
    Parent:=FDisplayPanel;
    Caption:='0';
    Font.Color:=clBlack;
    end;
  { CalcPanel }
  FCalcPanel:=TCalculatorPanel.CreateLayout(Self, ALayout);
  with TCalculatorPanel(FCalcPanel) do
    begin
    Align:=alBottom;
    Top:=17;
    Anchors:=[akLeft,akRight,AkBottom];
    Parent:=FMainPanel;
    OnOkClick:=@Self.OkClick;
    OnCancelClick:=@Self.CancelClick;
    OnCalcKey:=@Self.CalcKey;
    OnDisplayChange:=@Self.DisplayChange;
    FControl:=FDisplayLabel;
    end;
end;


procedure TCalculatorForm.FormKeyPress(Sender: TObject; var Key: TCharacter);
begin
  TCalculatorPanel(FCalcPanel).CalcKeyPress(Sender, Key);
end;

procedure TCalculatorForm.CopyItemClick(Sender: TObject);
begin
  TCalculatorPanel(FCalcPanel).Copy;
end;

function TCalculatorForm.GetValue: Double;
begin
  Result:=TCalculatorPanel(FCalcPanel).DisplayValue
end;

procedure TCalculatorForm.PasteItemClick(Sender: TObject);
begin
  TCalculatorPanel(FCalcPanel).Paste;
end;

procedure TCalculatorForm.SetValue(const AValue: Double);
begin
  TCalculatorPanel(FCalcPanel).DisplayValue:=AValue;
end;

procedure TCalculatorForm.OkClick(Sender: TObject);
begin
  ModalResult:=mrOk;
end;

procedure TCalculatorForm.CancelClick(Sender: TObject);
begin
  ModalResult:=mrCancel;
end;

procedure TCalculatorForm.CalcKey(Sender: TObject; var Key: TCharacter);
begin
  if (Owner <> nil) and (Owner is TCalculatorDialog) then
    TCalculatorDialog(Owner).CalcKey(Key);
end;

procedure TCalculatorForm.DisplayChange(Sender: TObject);
begin
  if (Owner <> nil) and (Owner is TCalculatorDialog) then
    TCalculatorDialog(Owner).DisplayChange;
end;

{ ---------------------------------------------------------------------
  TCalendarDialog
  ---------------------------------------------------------------------}

{ TCalendarDialogForm }

function TCalendarDialogForm.GetDate: TDateTime;
begin
  Try
    Result:=StrToDate(FCalendar.Date);
  Except
    Result:=0;
  end;
end;

procedure TCalendarDialogForm.SetDate(Value: TDateTime);
begin
  FCalendar.Date:=DateToStr(Date);
end;

function TCalendarDialogForm.GetDisplaySettings: TDisplaySettings;
begin
  Result:=FCalendar.DisplaySettings;
end;

procedure TCalendarDialogForm.SetDisplaySettings(const AValue: TDisplaySettings);
begin
  FCalendar.DisplaySettings:=AValue;
end;

procedure TCalendarDialogForm.InitForm;

begin
  Height:=150;
  Width:=200;
  Position:=poScreenCenter;
  BorderStyle:=bsDialog;
  FCalendar:=TCalendar.Create(Self);
  With FCalendar do
    begin
    Parent:=Self;
    SetBounds(0,0,Self.Width,98);
    Align:=alClient;
    //Anchors:=[akLeft,akRight,akTop,akBottom];
    end;
  FPanel:=TPanel.Create(Self);
  With FPanel do
    begin
    Parent:=Self;
    Top:=99;
    Height:=32;
    Width:=200;
    Align:=alBottom;
    Anchors:=[akLeft,akRight,akBottom];
    Caption:='';
    BevelOuter:=bvLowered;
    end;
  FOK:=TButton.Create(Self);
  With FOK do
    begin
    Parent:=FPanel;
    Caption:='&OK';
    Top:=4;
    Height:=24;
    Width:=50;
    Left:=Self.Width-FOK.Width-4;
    Anchors:=[akRight,akTop];
    Default:=True;
    ModalResult:=MrOK;
    end;
  FCancel:=TButton.Create(Self);
  With FCancel do
    begin
    Parent:=FPanel;
    Caption:='&Cancel';
    Height:=24;
    Top:=4;
    Width:=50;
    Left:=FOK.Left-FCancel.Width-4;
    Anchors:=[akright,aktop];
    Cancel:=True;
    ModalResult:=MrCancel;
    end;
end;

constructor TCalendarDialogForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  InitForm;
end;

destructor TCalendarDialogForm.Destroy;
begin
  FCalendar.Free;
  FOK.Free;
  FCancel.Free;
  FPanel.Free;
  inherited Destroy;
end;

{ TCalendarDialog }

function TCalendarDialog.IsTitleStored: Boolean;
begin
  Result:=Title<>rsPickDate;
end;

function TCalendarDialog.GetDialogTitle: String;
begin
  Result:=Title;
end;

procedure TCalendarDialog.SetDialogTitle(const AValue: String);
begin
  Title:=AValue;
end;

constructor TCalendarDialog.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FDate:=Sysutils.Date;
  Title:=rsPickDate;
end;

destructor TCalendarDialog.Destroy;
begin
  inherited Destroy;
end;

function TCalendarDialog.Execute: Boolean;
Var
  Dlg: TCalendarDialogForm;
  D: TDateTime;
begin
  Dlg:=CreateForm;
  With Dlg do
    Try
      D:=FDate;
      Dlg.Date:=D;
      Result:=ShowModal=mrOK;
      If Result then
        Self.Date:=Dlg.Date;
    Finally
      Free;
    end;
end;

function TCalendarDialog.CreateForm: TCalendarDialogForm;
begin
  Result:=CreateCalendarForm(Self,HelpContext);
  Result.Caption:=DialogTitle;
  With Result.Calendar do
    begin
    displaySettings:=Self.DisplaySettings;
    OnDayChanged:=Self.OnDayChanged;
    OnMonthChanged:=Self.OnMonthChanged;
    OnYearChanged:=Self.OnYearChanged;
    end;
end;

Initialization
{$i extdlgs.lrs}

end.

