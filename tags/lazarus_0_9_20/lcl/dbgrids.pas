{ $Id$}
{
 /***************************************************************************
                               DBGrids.pas
                               -----------
                     An interface to DB aware Controls
                     Initial Revision : Sun Sep 14 2003


 ***************************************************************************/

 *****************************************************************************
 *                                                                           *
 *  This file is part of the Lazarus Component Library (LCL)                 *
 *                                                                           *
 *  See the file COPYING.modifiedLGPL, included in this distribution,        *
 *  for details about the copyright.                                         *
 *                                                                           *
 *  This program is distributed in the hope that it will be useful,          *
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of           *
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                     *
 *                                                                           *
 *****************************************************************************
}
{
TDBGrid and TComponentDataLink for Lazarus
Copyright (C) 2003  Jesus Reyes Aguilar.
email: jesusrmx@yahoo.com.mx

TComponentDatalink idea was taken from Joanna Carter's article
"The Ultimate Datalink?" Delphi Magazine Issue #30 February 1998
}
unit DBGrids;

{$mode objfpc}{$H+}
{$define EnableIsSeq}

{$IF defined(VER2_0_2) and defined(win32)}
// FPC <= 2.0.2 compatibility code
// WINDOWS define was added after FPC 2.0.2
  {$define WINDOWS}
{$endif}

interface

uses
  Classes, LCLIntf, LCLProc, Graphics, SysUtils, LCLType, stdctrls, DB,
  LMessages, Grids, Dialogs, Controls;

type
  TCustomDbGrid = class;
  TColumn = class;
  EInvalidGridOperation = class(Exception);


  TDBGridOption = (
    dgEditing,                          // Ya
    dgTitles,                           // Ya
    dgIndicator,                        // Ya
    dgColumnResize,                     // Ya
    dgColumnMove,                       // Ya
    dgColLines,                         // Ya
    dgRowLines,                         // Ya
    dgTabs,                             // Ya
    dgAlwaysShowEditor,                 // Ya
    dgRowSelect,                        // Ya
    dgAlwaysShowSelection,              // Ya
    dgConfirmDelete,
    dgCancelOnExit,                     // Ya
    dgMultiselect                       // Ya
  );
  TDbGridOptions = set of TDbGridOption;

  TDbGridExtraOption = (
    dgeAutoColumns,       // if uncustomized columns, add them anyway?
    dgeCheckboxColumn     // enable the use of checkbox in columns
  );
  TDbGridExtraOptions = set of TDbGridExtraOption;

  TDbGridStatusItem = (gsVisibleMove, gsUpdatingData, gsAddingAutoColumns,
                       gsRemovingAutoColumns);
  TDbGridStatus = set of TDbGridStatusItem;

  TDBGridCheckBoxState = (gcbpUnChecked, gcbpChecked, gcbpGrayed);

  TDataSetScrolledEvent =
    procedure(DataSet: TDataSet; Distance: Integer) of object;

  TDBGridClickEvent =
    procedure(Column: TColumn) of object;
    
  TMovedEvent =
    procedure(Sender: TObject; FromIndex, ToIndex: Integer) of object;
    
  TDrawColumnCellEvent =
    procedure(Sender: TObject; const Rect: TRect; DataCol: Integer;
              Column: TColumn; State: TGridDrawState) of object;
              
  TGetDbEditMaskEvent =
    procedure (Sender: TObject; const Field: TField;
               var Value: string) of object;
               
  TUserCheckBoxBitmapEvent =
    procedure(Sender: TObject; const CheckedState: TDbGridCheckboxState;
              ABitmap: TBitmap) of object;

type

  { TBookmarkList }

  TBookmarkList=class
  private
    FList: TStringlist;
    FGrid: TCustomDbGrid;
    function GetCount: integer;
    function GetCurrentRowSelected: boolean;
    function GetItem(AIndex: Integer): TBookmarkStr;
    procedure SetCurrentRowSelected(const AValue: boolean);
    procedure CheckActive;
  public
    constructor Create(AGrid: TCustomDbGrid);
    destructor Destroy; override;
    
    procedure Clear;
    procedure Delete;
    function  Find(const Item: TBookmarkStr; var AIndex: Integer): boolean;
    function  IndexOf(const Item: TBookmarkStr): Integer;
    function  Refresh: boolean;

    property Count: integer read GetCount;
    property CurrentRowSelected: boolean
      read GetCurrentRowSelected write SetCurrentRowSelected;
    property Items[AIndex: Integer]: TBookmarkStr read GetItem; default;
  end;

  { TComponentDataLink }

  TComponentDataLink=class(TDatalink)
  private
    FDataSet: TDataSet;
    FDataSetName: string;
    FModified: Boolean;
    FOnDatasetChanged: TDatasetNotifyEvent;
    fOnDataSetClose: TDataSetNotifyEvent;
    fOnDataSetOpen: TDataSetNotifyEvent;
    FOnDataSetScrolled: TDataSetScrolledEvent;
    FOnEditingChanged: TDataSetNotifyEvent;
    fOnInvalidDataSet: TDataSetNotifyEvent;
    fOnInvalidDataSource: TDataSetNotifyEvent;
    FOnLayoutChanged: TDataSetNotifyEvent;
    fOnNewDataSet: TDataSetNotifyEvent;
    FOnRecordChanged: TFieldNotifyEvent;
    FOnUpdateData: TDataSetNotifyEvent;
    fOldFirstRecord: Integer;

    function GetDataSetName: string;
    function GetFields(Index: Integer): TField;
    procedure SetDataSetName(const AValue: string);
  protected
    procedure RecordChanged(Field: TField); override;
    procedure DataSetChanged; override;
    procedure ActiveChanged; override;
    procedure LayoutChanged; override;
    procedure DataSetScrolled(Distance: Integer); override;
    procedure FocusControl(Field: TFieldRef); override;
    // Testing Events
    procedure CheckBrowseMode; override;
    function  CheckFirstRecord: boolean;
    procedure EditingChanged; override;
    procedure UpdateData; override;
    function  MoveBy(Distance: Integer): Integer; override;
    property  Modified: Boolean read FModified write FModified;
  public
    Property OnRecordChanged: TFieldNotifyEvent read FOnRecordChanged write FOnRecordChanged;
    Property OnDataSetChanged: TDatasetNotifyEvent read FOnDatasetChanged write FOnDataSetChanged;
    property OnNewDataSet: TDataSetNotifyEvent read fOnNewDataSet write fOnNewDataSet;
    property OnDataSetOpen: TDataSetNotifyEvent read fOnDataSetOpen write fOnDataSetOpen;
    property OnInvalidDataSet: TDataSetNotifyEvent read fOnInvalidDataSet write fOnInvalidDataSet;
    property OnInvalidDataSource: TDataSetNotifyEvent read fOnInvalidDataSource write fOnInvalidDataSource;
    property OnLayoutChanged: TDataSetNotifyEvent read FOnLayoutChanged write FOnLayoutChanged;
    property OnDataSetClose: TDataSetNotifyEvent read fOnDataSetClose write fOnDataSetClose;
    property OnDataSetScrolled: TDataSetScrolledEvent read FOnDataSetScrolled write FOnDataSetScrolled;
    property OnEditingChanged: TDataSetNotifyEvent read FOnEditingChanged write FOnEditingChanged;
    property OnUpdateData: TDataSetNotifyEvent read FOnUpdateData write FOnUpdateData;
    property DataSetName:string read GetDataSetName write SetDataSetName;
    Property Fields[Index: Integer]: TField read GetFields;
    Property VisualControl;
  end;

  { TColumn }

  TColumnTitle = class(TGridColumnTitle)
  protected
    function  GetDefaultCaption: string; override;
  end;

  { TColumn }

  TColumn = class(TGridColumn)
  private
    FDisplayFormat: String;
    FDisplayFormatChanged: boolean;
    FFieldName: String;
    FField: TField;
    FIsAutomaticColumn: boolean;
    FDesignIndex: Integer;
    FValueChecked,FValueUnchecked: PChar;
    procedure ApplyDisplayFormat;
    function  GetDataSet: TDataSet;
    function  GetDisplayFormat: string;
    function  GetField: TField;
    function  GetIsDesignColumn: boolean;
    function  GetValueChecked: string;
    function  GetValueUnchecked: string;
    function  IsDisplayFormatStored: boolean;
    function  IsValueCheckedStored: boolean;
    function  IsValueUncheckedStored: boolean;
    procedure SetDisplayFormat(const AValue: string);
    procedure SetField(const AValue: TField);
    procedure SetFieldName(const AValue: String);
    procedure SetValueChecked(const AValue: string);
    procedure SetValueUnchecked(const AValue: string);
  protected
    procedure Assign(Source: TPersistent); override;
    function  CreateTitle: TGridColumnTitle; override;
    function  GetDefaultAlignment: TAlignment; override;
    function  GetDefaultDisplayFormat: string;
    function  GetDefaultValueChecked: string; virtual;
    function  GetDefaultValueUnchecked: string; virtual;
    function  GetDefaultVisible: boolean; override;
    function  GetDisplayName: string; override;
    function  GetDefaultReadOnly: boolean; override;
    function  GetDefaultWidth: Integer; override;
    property  IsAutomaticColumn: boolean read FIsAutomaticColumn;
    property  IsDesignColumn: boolean read GetIsDesignColumn;
    procedure LinkField;
  public
    constructor Create(ACollection: TCollection); override;
    destructor Destroy; override;
    function  IsDefault: boolean; override;
    property  DesignIndex: integer read FDesignIndex;
    property  Field: TField read GetField write SetField;
  published
    property  FieldName: String read FFieldName write SetFieldName;
    property DisplayFormat: string read GetDisplayFormat write SetDisplayFormat
      stored IsDisplayFormatStored;
    property ValueChecked: string read GetValueChecked write SetValueChecked
      stored IsValueCheckedStored;
    property ValueUnchecked: string read GetValueUnchecked write SetValueUnchecked
      stored IsValueUncheckedStored;
  end;

  TColumnOrder = (coDesignOrder, coFieldIndexOrder);

  { TDBGridColumns }
  TDBGridColumns = class(TGridColumns)
  private
    function GetColumn(Index: Integer): TColumn;
    procedure SetColumn(Index: Integer; Value: TColumn);
  protected
    procedure Update(Item: TCollectionItem); override;
    function ColumnFromField(Field: TField): TColumn;
    function  HasAutomaticColumns: boolean;
    function  HasDesignColumns: boolean;
    procedure RemoveAutoColumns;
  public
    function  Add: TColumn;
    procedure LinkFields;
    procedure ResetColumnsOrder(ColumnOrder: TColumnOrder);
    property Items[Index: Integer]: TColumn read GetColumn write SetColumn; default;
  end;

  { TCustomDBGrid }

  TCustomDBGrid=class(TCustomGrid)
  private
    FDataLink: TComponentDataLink;
    FExtraOptions: TDBGridExtraOptions;
    FOnCellClick: TDBGridClickEvent;
    FOnColEnter,FOnColExit: TNotifyEvent;
    FOnColumnMoved: TMovedEvent;
    FOnColumnSized: TNotifyEvent;
    FOnDrawColumnCell: TDrawColumnCellEvent;
    FOnFieldEditMask: TGetDbEditMaskEvent;
    FOnTitleClick: TDBGridClickEvent;
    FOnUserCheckboxBitmap: TUserCheckboxBitmapEvent;
    FOptions: TDBGridOptions;
    FReadOnly: Boolean;
    FColEnterPending: Boolean;
    FLayoutChangedCount: integer;
    //FUseAutoColumns: boolean;
    //FUseCheckBoxColumn: boolean;
    FVisualChangeCount: Integer;
    FSelectionLock: Boolean;
    FTempText : string;
    FDrawingActiveRecord: Boolean;
    FDrawingMultiSelRecord: Boolean;
    FDrawingEmptyDataset: Boolean;
    FEditingColumn: Integer;
    FOldPosition: Integer;
    FDefaultColWidths: boolean;
    FGridStatus: TDBGridStatus;
    FOldControlStyle: TControlStyle;
    FIsEditingCheckBox: Boolean;  // For checkbox column editing emulation (by SSY)
    FCheckedBitmap, FUnCheckedBitmap, FGrayedBitmap: TBitmap;
    FNeedUpdateWidths: boolean;
    FSelectedRows: TBookmarkList;
    procedure EmptyGrid;
    procedure CheckWidths;
    function GetCurrentColumn: TColumn;
    function GetCurrentField: TField;
    function GetDataSource: TDataSource;
    function GetRecordCount: Integer;
    function GetSelectedIndex: Integer;
    function GetThumbTracking: boolean;
    procedure OnRecordChanged(Field:TField);
    procedure OnDataSetChanged(aDataSet: TDataSet);
    procedure OnDataSetOpen(aDataSet: TDataSet);
    procedure OnDataSetClose(aDataSet: TDataSet);
    procedure OnEditingChanged(aDataSet: TDataSet);
    procedure OnInvalidDataSet(aDataSet: TDataSet);
    procedure OnInvalidDataSource(aDataSet: TDataset);
    procedure OnLayoutChanged(aDataSet: TDataSet);
    procedure OnNewDataSet(aDataSet: TDataset);
    procedure OnDataSetScrolled(aDataSet:TDataSet; Distance: Integer);
    procedure OnUpdateData(aDataSet: TDataSet);
    //procedure ReadColumns(Reader: TReader);
    //procedure SetColumns(const AValue: TDBGridColumns);
    procedure SetCurrentField(const AValue: TField);
    procedure SetDataSource(const AValue: TDataSource);
    procedure SetExtraOptions(const AValue: TDBGridExtraOptions);
    procedure SetOptions(const AValue: TDBGridOptions);
    procedure SetSelectedIndex(const AValue: Integer);
    procedure SetThumbTracking(const AValue: boolean);
    procedure UpdateBufferCount;

    // Temporal
    function GetColumnCount: Integer;

    function DefaultFieldColWidth(F: TField): Integer;

    procedure UpdateGridColumnSizes;
    procedure UpdateScrollbarRange;
    procedure BeginVisualChange;
    procedure EndVisualChange;
    procedure DoLayoutChanged;
    //procedure WriteColumns(Writer: TWriter);

    procedure RestoreEditor;
    function  ISEOF: boolean;
    function  ValidDataSet: boolean;
    function  InsertCancelable: boolean;
    procedure StartUpdating;
    procedure EndUpdating;
    function  UpdatingData: boolean;
    procedure SwapCheckBox;
    function  ValueMatch(const BaseValue, TestValue: string): Boolean;
    procedure ToggleSelectedRow;
    procedure SelectRecord(AValue: boolean);
  protected
    procedure AddAutomaticColumns;
    procedure BeforeMoveSelection(const DCol,DRow: Integer); override;
    procedure BeginLayout;
    procedure CellClick(const aCol,aRow: Integer); override;
    procedure ChangeBounds(ALeft, ATop, AWidth, AHeight: integer); override;
    procedure ColRowMoved(IsColumn: Boolean; FromIndex,ToIndex: Integer); override;
    function  ColumnEditorStyle(aCol: Integer; F: TField): TColumnButtonStyle;
    function  CreateColumns: TGridColumns; override;
    procedure CreateWnd; override;
    procedure DefineProperties(Filer: TFiler); override;
    procedure DefaultDrawCell(aCol,aRow: Integer; aRect: TRect; aState: TGridDrawState);
    procedure DoExit; override;
    function  DoMouseWheelDown(Shift: TShiftState; MousePos: TPoint): Boolean; override;
    function  DoMouseWheelUp(Shift: TShiftState; MousePos: TPoint): Boolean; override;
    procedure DoOnChangeBounds; override;
    procedure DrawAllRows; override;
    procedure DrawFocusRect(aCol,aRow:Integer; ARect:TRect); override;
    procedure DrawRow(ARow: Integer); override;
    procedure DrawCell(aCol,aRow: Integer; aRect: TRect; aState:TGridDrawState); override;
    procedure DrawCheckboxBitmaps(aCol: Integer; aRect: TRect; F: TField);
    procedure EditingColumn(aCol: Integer; Ok: boolean);
    procedure EditorCancelEditing;
    procedure EditorDoGetValue; override;
    function  EditorCanAcceptKey(const ch: Char): boolean; override;
    function  EditorIsReadOnly: boolean; override;
    procedure EndLayout;
    function  FieldIndexFromGridColumn(Column: Integer): Integer;
    function  GetDefaultColumnAlignment(Column: Integer): TAlignment; override;
    function  GetDefaultColumnWidth(Column: Integer): Integer; override;
    function  GetDefaultColumnReadOnly(Column: Integer): boolean; override;
    function  GetDefaultColumnTitle(Column: Integer): string; override;
    function  GetDsFieldFromGridColumn(Column: Integer): TField;
    function  GetEditMask(aCol, aRow: Longint): string; override;
    function  GetEditText(aCol, aRow: Longint): string; override;
    function  GetFieldFromGridColumn(Column: Integer): TField;
    function  GetGridColumnFromField(F: TField): Integer;
    function  GetImageForCheckBox(CheckBoxView: TDBGridCheckBoxState): TBitmap;
    function  GetIsCellSelected(aCol, aRow: Integer): boolean; override;
    function  GridCanModify: boolean;
    procedure HeaderClick(IsColumn: Boolean; index: Integer); override;
    procedure HeaderSized(IsColumn: Boolean; Index: Integer); override;
    procedure KeyDown(var Key : Word; Shift : TShiftState); override;
    procedure LinkActive(Value: Boolean); virtual;
    procedure LayoutChanged; virtual;
    procedure Loaded; override;
    procedure MoveSelection; override;
    procedure MouseDown(Button: TMouseButton; Shift:TShiftState; X,Y:Integer); override;
    procedure Paint; override;
    procedure PrepareCanvas(aCol,aRow: Integer; aState:TGridDrawState); override;
    procedure RemoveAutomaticColumns;
    procedure SelectEditor; override;
    procedure SetEditText(ACol, ARow: Longint; const Value: string); override;
    function  ScrollBarAutomatic(Which: TScrollStyle): boolean; override;
    function  SelectCell(aCol, aRow: Integer): boolean; override;
    procedure UpdateActive; virtual;
    procedure UpdateData; virtual;
    function  UpdateGridCounts: Integer;
    procedure UpdateVertScrollbar(const aVisible: boolean; const aRange,aPage: Integer); override;
    procedure VisualChange; override;
    procedure WMVScroll(var Message : TLMVScroll); message LM_VScroll;
    procedure WndProc(var TheMessage : TLMessage); override;

    property GridStatus: TDBGridStatus read FGridStatus write FGridStatus;
    property DataSource: TDataSource read GetDataSource write SetDataSource;
    property NeedUpdateWidths: boolean write FNeedUpdateWidths;
    property Options: TDBGridOptions read FOptions write SetOptions;
    property OptionsExtra: TDBGridExtraOptions read FExtraOptions write SetExtraOptions;
    property ReadOnly: Boolean read FReadOnly write FReadOnly default false;
    property SelectedRows: TBookmarkList read FSelectedRows;

    property OnCellClick: TDBGridClickEvent read FOnCellClick write FOnCellClick;
    property OnColEnter: TNotifyEvent read FOnColEnter write FOnColEnter;
    property OnColExit: TNotifyEvent read FOnColExit write FOnColExit;
    property OnColumnMoved: TMovedEvent read FOnColumnMoved write FOnColumnMoved;
    property OnColumnSized: TNotifyEvent read FOnColumnSized write FOnColumnSized;
    property OnDrawColumnCell: TDrawColumnCellEvent read FOnDrawColumnCell write FOnDrawColumnCell;
    property OnFieldEditMask: TGetDbEditMaskEvent read FOnFieldEditMask write FOnFieldEditMask;
    property OnTitleClick: TDBGridClickEvent read FOnTitleClick write FOnTitleClick;
    property OnUserCheckboxBitmap: TUserCheckboxBitmapEvent read FOnUserCheckboxBitmap write FOnUserCheckboxBitmap;
  public
    constructor Create(AOwner: TComponent); override;
    procedure InitiateAction; override;
    procedure DefaultDrawColumnCell(const Rect: TRect; DataCol: Integer; Column: TColumn; State: TGridDrawState);
    function  EditorByStyle(Style: TColumnButtonStyle): TWinControl; override;
    procedure ResetColWidths;
    destructor Destroy; override;
    property SelectedField: TField read GetCurrentField write SetCurrentField;
    property SelectedIndex: Integer read GetSelectedIndex write SetSelectedIndex;
    property SelectedColumn: TColumn read GetCurrentColumn;
    property ThumbTracking: boolean read GetThumbTracking write SetThumbTracking;
  end;

  TDBGrid=class(TCustomDBGrid)
  public
    property BorderColor;
    property Canvas;
    property DefaultTextStyle;
    property EditorBorderStyle;
    property EditorMode;
    property ExtendedColSizing;
    property FastEditing;
    property FocusColor;
    property FocusRectVisible;
    property GridLineColor;
    property GridLineStyle;
    property SelectedColor;
    property SelectedRows;
  published
    property Align;
    property AlternateColor;
    property Anchors;
    property AutoAdvance default aaRightDown;
    property AutoFillColumns;
    //property BiDiMode;
    property BorderSpacing;
    property BorderStyle;
    property Color;
    property Columns; // stored false;
    property Constraints;
    property DataSource;
    property DefaultDrawing;
    property DefaultRowHeight default 18;
    //property DragCursor;
    //property DragKind;
    //property DragMode;
    property Enabled;
    property FixedColor;
    property Flat;
    property Font;
    //property ImeMode;
    //property ImeName;
    property Options;
    property OptionsExtra;
    //property ParentBiDiMode;
    property ParentColor;
    //property ParentCtl3D;
    property ParentFont;
    //property ParentShowHint;
    property PopupMenu;
    property ReadOnly;
    property Scrollbars default ssBoth;
    property ShowHint;
    property TabOrder;
    property TabStop;
    property TitleFont;
    property TitleStyle;
    property Visible;
    property OnCellClick;
    property OnColEnter;
    property OnColExit;
    property OnColumnMoved;
    property OnColumnSized;
    property OnDrawColumnCell;
    property OnDblClick;
    //property OnDragDrop;
    //property OnDragOver;
    property OnEditButtonClick;
    //property OnEndDock;
    //property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnFieldEditMask;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnPrepareCanvas;
    //property OnStartDock;
    //property OnStartDrag;
    property OnTitleClick;
    property OnUserCheckboxBitmap;
  end;

  PCharArray   = Array[0..6+13] of PChar;

const
  IMGDBGrayedBox : PCharArray =
    (
  '13 13 6 1',
  ' 	c None',
  '.	c #808080',
  '+	c #FFFFFF',
  '@	c #404040',
  '#	c #D4D0C8',
  '$	c #000000',

  '############+',
  '#..........#+',
  '#.##########+',
  '#.#######.##+',
  '#.######..##+',
  '#.#.###...##+',
  '#.#..#...###+',
  '#.#.....####+',
  '#.##...#####+',
  '#.###.######+',
  '#.##########+',
  '############+',
  '+++++++++++++');

  IMGDBCheckedBox : PCharArray =
    (
  '13 13 6 1',
  ' 	c None',
  '.	c #808080',
  '+	c #FFFFFF',
  '@	c #404040',
  '#	c #D4D0C8',
  '$	c #000000',

  '............+',
  '.@@@@@@@@@@#+',
  '.@+++++++++#+',
  '.@+++++++$+#+',
  '.@++++++$$+#+',
  '.@+$+++$$$+#+',
  '.@+$$+$$$++#+',
  '.@+$$$$$+++#+',
  '.@++$$$++++#+',
  '.@+++$+++++#+',
  '.@+++++++++#+',
  '.###########+',
  '+++++++++++++');

  IMGDBUnCheckedBox : PCharArray =
    (
  '13 13 6 1',
  ' 	c None',
  '.	c #808080',
  '+	c #FFFFFF',
  '@	c #404040',
  '#	c #D4D0C8',
  '$	c #000000',

  '............+',
  '.@@@@@@@@@@#+',
  '.@+++++++++#+',
  '.@+++++++++#+',
  '.@+++++++++#+',
  '.@+++++++++#+',
  '.@+++++++++#+',
  '.@+++++++++#+',
  '.@+++++++++#+',
  '.@+++++++++#+',
  '.@+++++++++#+',
  '.###########+',
  '+++++++++++++');

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Data Controls',[TDBGrid]);
end;

procedure DrawIndicator(Canvas: TCanvas; R: TRect; Opt: TDataSetState;
  MultiSel: boolean);
var
  dx,dy, x, y: Integer;
  procedure CenterY;
  begin
    y := R.Top + (R.Bottom-R.Top) div 2-1;
  end;
  procedure CenterX;
  begin
    X := R.Left + (R.Right-R.Left) div 2-1;
  end;
  procedure DrawEdit(clr: Tcolor);
  begin
    Canvas.Pen.Color := clr;
    CenterY;
    CenterX;
    Canvas.MoveTo(X-2, Y-Dy-1);
    Canvas.LineTo(X+3, Y-Dy-1);
    Canvas.MoveTo(X, Y-Dy);
    Canvas.LineTo(X, Y+Dy);
    Canvas.MoveTo(X-2, Y+Dy);
    Canvas.LineTo(X+3, Y+Dy);
  end;
begin
  dx := 6;
  dy := 6;
  case Opt of
    dsBrowse:
      begin //
        Canvas.Brush.Color:=clBlack;
        Canvas.Pen.Color:=clBlack;
        CenterY;
        x:= R.Left+3;
        if MultiSel then begin
          Canvas.Polyline([point(x,y-dy),  point(x+dx,y),point(x,y+dy), point(x,y+dy-1)]);
          Canvas.Polyline([point(x,y-dy+1),point(x+dx-1,y),point(x, y+dy-1), point(x,y+dy-2)]);
          CenterX;
          Dec(X,2);
          Canvas.Ellipse(Rect(X-2,Y-2,X+2,Y+2));
        end else
          Canvas.Polygon([point(x,y-dy),point(x+dx,y),point(x, y+dy),point(x,y-dy)]);
       end;
    dsEdit:
      DrawEdit(clBlack);
    dsInsert:
      DrawEdit(clGreen);
    else
    if MultiSel then begin
      Canvas.Brush.Color:=clBlack;
      Canvas.Pen.Color:=clBlack;
      CenterX;
      CenterY;
      Canvas.Ellipse(Rect(X-3,Y-3,X+3,Y+3));
    end;
  end;
end;

function CalcCanvasCharWidth(Canvas:TCanvas): integer;
begin
  if Canvas.HandleAllocated then
    result := Canvas.TextWidth('MX') div 2
  else
    result := 8;
end;

function CalcColumnFieldWidth(Canvas: TCanvas; hasTitle: boolean;
  aTitle: String; aTitleFont: TFont; Field: TField): Integer;
var
  aCharWidth: Integer;
  aFont: TFont;
  UseTitleFont: boolean;
begin
  if (Field=nil) or (Field.DisplayWidth=0) then
    Result := DEFCOLWIDTH
  else begin
  
    aCharWidth := CalcCanvasCharWidth(Canvas);
    if Field.DisplayWidth>Length(aTitle) then
      result := aCharWidth * Field.DisplayWidth
    else
      result := aCharWidth * Length(aTitle);

    if HasTitle then begin
      UseTitleFont :=
        (Canvas.Font.Size<>aTitleFont.Size) or
        (Canvas.Font.Style<>aTitleFont.Style) or
        (Canvas.Font.CharSet<>aTitleFont.CharSet) or
        (Canvas.Font.Name<>aTitleFont.Name);
      if UseTitleFont then begin
        aFont := TFont.Create;
        aFont.Assign(Canvas.Font);
        Canvas.Font := aTitleFont;
      end;
      try
        aCharWidth := Canvas.TextWidth(ATitle)+6;
        if aCharWidth>Result then
          Result := aCharWidth;
      finally
        if UseTitleFont then begin
          Canvas.Font := aFont;
          aFont.Free;
        end;
      end;
    end; // if HasTitle ...
    
  end; // if (Field=nil) or (Field.DisplayWidth=0) ...
end;

{ TCustomDBGrid }

procedure TCustomDBGrid.OnRecordChanged(Field: TField);
var
  c: Integer;
begin
  {$IfDef dbgDBGrid}
  DBGOut('('+name+') ','TCustomDBGrid.OnRecordChanged(Field=');
  if Field=nil then DebugLn('nil)')
  else              DebugLn(Field.FieldName,')');
  {$Endif}
  if Field=nil then
    UpdateActive
  else begin
    c := GetGridColumnFromField(Field);
    if c>0 then
      InvalidateCell(C, Row)
    else
      UpdateActive;
  end;
end;

function TCustomDBGrid.GetDataSource: TDataSource;
begin
  Result:= FDataLink.DataSource;
end;

function TCustomDBGrid.GetRecordCount: Integer;
begin
  result := FDataLink.DataSet.RecordCount;
end;

function TCustomDBGrid.GetSelectedIndex: Integer;
begin
  if Columns.Enabled then
    Result := ColumnIndexFromGridColumn( Col )
  else
    Result := FieldIndexFromGridColumn( Col );
end;

function TCustomDBGrid.GetThumbTracking: boolean;
begin
  Result :=  goThumbTracking in inherited Options;
end;

procedure TCustomDBGrid.EmptyGrid;
begin
  ColCount := 2;
  RowCount := 2;
  FixedCols := 1;
  FixedRows := 1;
  ColWidths[0]:=12;
end;

procedure TCustomDBGrid.CheckWidths;
begin
  if FNeedUpdateWidths then begin
    BeginUpdate;
    VisualChange;
    EndUpdate(uoNone);
    FNeedUpdateWidths := False;
  end;
end;

function TCustomDBGrid.GetCurrentColumn: TColumn;
begin
  if Columns.Enabled then
    Result := TColumn(Columns[SelectedIndex])
  else
    Result := nil;
end;

function TCustomDBGrid.GetCurrentField: TField;
begin
  result := GetFieldFromGridColumn( Col );
end;

procedure TCustomDBGrid.OnDataSetChanged(aDataSet: TDataSet);
begin
  {$Ifdef dbgDBGrid}
  DBGOut('('+name+') ','TCustomDBDrid.OnDataSetChanged(aDataSet=');
  if aDataSet=nil then DebugLn('nil)')
  else DebugLn(aDataSet.Name,')');
  {$endif}
  if not (gsVisibleMove in FGridStatus) or FDatalink.CheckFirstRecord then
    LayoutChanged
  else
    UpdateScrollBarRange;

  UpdateActive;
  //RestoreEditor;
end;

procedure TCustomDBGrid.OnDataSetOpen(aDataSet: TDataSet);
begin
  {$Ifdef dbgDBGrid}
  DebugLn('(',name,') ','TCustomDBGrid.OnDataSetOpen');
  {$endif}
  FDefaultColWidths := True;
  LinkActive(True);
  UpdateActive;
end;

procedure TCustomDBGrid.OnDataSetClose(aDataSet: TDataSet);
begin
  {$ifdef dbgDBGrid}
  DebugLn('(',name,') ','TCustomDBGrid.OnDataSetClose');
  {$endif}
  LinkActive(False);
end;

procedure TCustomDBGrid.OnEditingChanged(aDataSet: TDataSet);
begin
  {$ifdef dbgDBGrid}
  DebugLn('(',name,') ','TCustomDBGrid.OnEditingChanged');
  if aDataSet<>nil then begin
    DebugLn('Editing=', BoolToStr(dsEdit = aDataSet.State));
    DebugLn('Inserting=',BoolToStr(dsInsert = aDataSet.State));
  end else
    DebugLn('Dataset=nil');
  {$endif}
  FDataLink.Modified := False;
  UpdateActive;
end;

procedure TCustomDBGrid.OnInvalidDataSet(aDataSet: TDataSet);
begin
  {$ifdef dbgDBGrid}
  DebugLn('(',name,') ','TCustomDBGrid.OnInvalidDataSet');
  {$endif}
  LinkActive(False);
end;

procedure TCustomDBGrid.OnInvalidDataSource(aDataSet: TDataset);
begin
  {$ifdef dbgDBGrid}
  DebugLn('(',name,') ','TCustomDBGrid.OnInvalidDataSource');
  {$endif}
  LinkActive(False);
end;

procedure TCustomDBGrid.OnLayoutChanged(aDataSet: TDataSet);
begin
  {$ifdef dbgDBGrid}
  DebugLn('(',name,') ','TCustomDBGrid.OnLayoutChanged');
  {$endif}
  LayoutChanged;
end;

procedure TCustomDBGrid.OnNewDataSet(aDataSet: TDataset);
begin
  {$ifdef dbgDBGrid}
  DebugLn('(',name,') ','TCustomDBGrid.OnNewDataSet');
  {$endif}
  FDefaultColWidths := True;
  LinkActive(True);
  UpdateActive;
end;

procedure TCustomDBGrid.OnDataSetScrolled(aDataset: TDataSet; Distance: Integer);
begin
  {$ifdef dbgDBGrid}
  DebugLn(ClassName, ' (',name,')', '.OnDataSetScrolled(',IntToStr(Distance),')');
  Debugln('Dataset.RecordCount=',IntToStr(aDataSet.RecordCount));
  {$endif}
  UpdateScrollBarRange;
  // todo: Use a fast interface method to scroll a rectangular section of window
  //       if distance=+, Row[Distance] to Row[RowCount-2] UP
  //       if distance=-, Row[FixedRows+1] to Row[RowCount+Distance] DOWN
  if Distance<>0 then begin
    Row:= FixedRows + FDataLink.ActiveRecord;
    Invalidate
  end else
    UpdateActive;
end;

procedure TCustomDBGrid.OnUpdateData(aDataSet: TDataSet);
begin
  UpdateData;
end;
{
procedure TCustomDBGrid.ReadColumns(Reader: TReader);
begin
  Columns.Clear;
  Reader.ReadValue;
  Reader.ReadCollection(Columns);
end;
procedure TCustomDBGrid.SetColumns(const AValue: TDBGridColumns);
begin
  Columns.Assign(AValue);
end;
}
procedure TCustomDBGrid.SetCurrentField(const AValue: TField);
var
  i: Integer;
begin
  if Avalue<>SelectedField then begin
    i := GetGridColumnFromField( AValue );
    if i>FixedCols then
      Col := i;
  end;
end;

procedure TCustomDBGrid.SetDataSource(const AValue: TDataSource);
begin
  if AValue = FDatalink.Datasource then Exit;
  FDefaultColWidths := True;
  FDataLink.DataSource := AValue;
  UpdateActive;
end;

procedure TCustomDBGrid.SetExtraOptions(const AValue: TDBGridExtraOptions);
var
  OldOptions: TDBGridExtraOptions;

  function IsOptionChanged(Op: TDBGridExtraOption): boolean;
  begin
    result := ((op in OldOptions) and not (op in AValue)) or
      (not (op in OldOptions) and (op in AValue));
  end;

begin
  if FExtraOptions=AValue then exit;
  OldOptions := FExtraOptions;
  FExtraOptions := AValue;

  if IsOptionChanged(dgeCheckboxColumn) then
    Invalidate;

  if IsOptionChanged(dgeAutoColumns) then begin
    if dgeAutoColumns in aValue then
      AddAutomaticColumns
    else if TDBGridColumns(Columns).HasAutomaticColumns then
      RemoveAutomaticColumns;
    UpdateActive;
  end;

end;

procedure TCustomDBGrid.SetOptions(const AValue: TDBGridOptions);
var
  OldOptions: TGridOptions;
  MultiSel: boolean;
begin
  if FOptions<>AValue then begin
    MultiSel := dgMultiSelect in FOptions;
    FOptions:=AValue;
    OldOptions := inherited Options;

   if dgRowSelect in FOptions then
    FOptions := FOptions - [dgEditing, dgAlwaysShowEditor];

    BeginLayout;

    if dgRowLines in fOptions then
      Include(OldOptions, goHorzLine)
    else
      Exclude(OldOptions, goHorzLine);

    if dgColLines in fOptions then
      Include(OldOptions, goVertLine)
    else
      Exclude(OldOptions, goVertLine);

    if dgColumnResize in fOptions then
      Include(OldOptions, goColSizing)
    else
      Exclude(OldOptions, goColSizing);
      
    if dgColumnMove in fOptions then
      Include(OldOptions, goColMoving)
    else
      Exclude(OldOptions, goColMoving);

    if dgAlwaysShowEditor in FOptions then
      Include(OldOptions, goAlwaysShowEditor)
    else
      Exclude(OldOptions, goAlwaysShowEditor);

    if dgRowSelect in FOptions then
      Include(OldOptions, goRowSelect)
    else
      Exclude(OldOptions, goRowSelect);

    if dgEditing in FOptions then
      Include(OldOptions, goEditing)
    else
      Exclude(OldOptions, goediting);

    if dgTabs in FOptions then
      Include(OldOptions, goTabs)
    else
      Exclude(OldOptions, goTabs);

    inherited Options := OldOptions;
    
    if MultiSel and not (dgMultiSelect in FOptions) then
      FSelectedRows.Clear;

    EndLayout;
  end;
end;

procedure TCustomDBGrid.SetSelectedIndex(const AValue: Integer);
begin
  Col := FixedCols + AValue;
end;

procedure TCustomDBGrid.SetThumbTracking(const AValue: boolean);
begin
  BeginUpdate;
  if Avalue then
    inherited Options := Inherited Options + [goThumbTracking]
  else
    inherited Options := Inherited Options - [goThumbTracking];
  EndUpdate(uoNone);
end;

procedure TCustomDBGrid.UpdateBufferCount;
var
  BuffCount: Integer;
begin
  if FDataLink.Active then begin
    BuffCount := GCache.ClientHeight div DefaultRowHeight;
    if dgTitles in Options then Dec(BuffCount, 1);
    FDataLink.BufferCount:= BuffCount;
    {$ifdef dbgDBGrid}
    DebugLn(ClassName, ' (',name,')', ' FdataLink.BufferCount=' + IntToStr(Fdatalink.BufferCount));
    {$endif}
  end;
end;

procedure TCustomDBGrid.UpdateData;
var
  selField,edField: TField;
begin
  // get Editor text and update field content
  if not UpdatingData and (FEditingColumn>-1) and FDatalink.Editing then begin
    SelField := SelectedField;
    edField := GetFieldFromGridColumn(FEditingColumn);

    if (edField<>nil) and (edField = SelField) then begin
      {$ifdef dbgDBGrid}
      DebugLn('---> UpdateData: Field[', edField.Fieldname, '(',edField.AsString,')]=', FTempText,' INIT');
      {$endif}

      StartUpdating;
      edField.AsString := FTempText;
      EndUpdating;

      EditingColumn(FEditingColumn, False);
      {$ifdef dbgDBGrid}
      DebugLn('<--- UpdateData: Chk: Field:=',edField.ASString,' END');
      {$endif}
    end;

  end;
end;

{$ifdef dbgDBGrid}
function SBCodeToStr(Code: Integer): String;
begin
  Case Code of
    SB_LINEUP : result := 'SB_LINEUP';
    SB_LINEDOWN: result := 'SB_LINEDOWN';
    SB_PAGEUP: result := 'SB_PAGEUP';
    SB_PAGEDOWN: result := 'SB_PAGEDOWN';
    SB_THUMBTRACK: result := 'SB_THUMBTRACK';
    SB_THUMBPOSITION: result := 'SB_THUMBPOSITION';
    SB_ENDSCROLL: result := 'SB_SCROLLEND';
    SB_TOP: result := 'SB_TOP';
    SB_BOTTOM: result := 'SB_BOTTOM';
    else result :=IntToStr(Code)+ ' -> ?';
  end;
end;
{$endif}

procedure TCustomDBGrid.WMVScroll(var Message: TLMVScroll);
var
  IsSeq: boolean;
  aPos: Integer;
  DeltaRec: integer;

  function MaxPos: Integer;
  begin
    if IsSeq then
      result := GetRecordCount
    else
      result := 4;
  end;

  procedure CalcPos(Delta: Integer);
  begin
    if FDataLink.Dataset.BOF then
      aPos := 0
    else if FDatalink.DataSet.EOF then
      aPos := MaxPos
    else if IsSeq then
      aPos := FOldPosition + Delta
    else
      aPos := 2;
  end;

  procedure DsMoveBy(Delta: Integer);
  begin
    FDataLink.MoveBy(Delta);
    CalcPos(Delta);
  end;

  procedure DsGoto(BOF: boolean);
  begin
    if BOF then FDatalink.DataSet.First
    else        FDataLink.DataSet.Last;
    CalcPos(0);
  end;

begin
  if not FDatalink.Active then exit;

  {$ifdef dbgDBGrid}
  DebugLn('VSCROLL: Code=',SbCodeToStr(Message.ScrollCode),
          ' Position=', dbgs(Message.Pos),' OldPos=',Dbgs(FOldPosition));
  {$endif}

  IsSeq := FDatalink.DataSet.IsSequenced {$ifndef EnableIsSeq} and false {$endif};
  case Message.ScrollCode of
    SB_TOP:
      DsGoto(True);
    SB_BOTTOM:
      DsGoto(False);
    SB_PAGEUP:
      DsMoveBy(-VisibleRowCount);
    SB_LINEUP:
      DsMoveBy(-1);
    SB_LINEDOWN:
      DsMoveBy(1);
    SB_PAGEDOWN:
      DsMoveBy(VisibleRowCount);
    SB_THUMBPOSITION:
      begin
        aPos := Message.Pos;
        if aPos>=MaxPos then
          dsGoto(False)
        else if aPos<=0 then
          dsGoto(True)
        else if IsSeq then
          FDatalink.DataSet.RecNo := aPos
        else begin
          DeltaRec := Message.Pos - FOldPosition;
          if DeltaRec=0 then
            exit
          else if DeltaRec<-1 then
            DsMoveBy(-VisibleRowCount)
          else if DeltaRec>1 then
            DsMoveBy(VisibleRowCount)
          else
            DsMoveBy(DeltaRec);
        end;
      end;
    else
      Exit;
  end;

  ScrollBarPosition(SB_VERT, aPos);
  FOldPosition:=aPos;
  {$ifdef dbgDBGrid}
  DebugLn('---- Diff=',dbgs(DeltaRec), ' FinalPos=',dbgs(aPos));
  {$endif}
end;

procedure TCustomDBGrid.WndProc(var TheMessage: TLMessage);
begin
  if (TheMessage.Msg=LM_SETFOCUS) and (gsUpdatingData in FGridStatus) then begin
    {$ifdef dbgGrid}DebugLn('DBGrid.LM_SETFOCUS while updating');{$endif}
    if EditorMode then begin
      LCLIntf.SetFocus(Editor.Handle);
      EditorSelectAll;
    end;
    exit;
  end;
  inherited WndProc(TheMessage);
end;


function TCustomDBGrid.DefaultFieldColWidth(F: TField): Integer;
begin
  if not HandleAllocated or (F=nil) then
    result:=DefaultColWidth
  else begin
    if F.DisplayWidth = 0 then
      if Canvas.HandleAllocated then
        result := Canvas.TextWidth( F.DisplayName ) + 3
      else
        Result := DefaultColWidth
    else
      result := F.DisplayWidth * CalcCanvasCharWidth(Canvas);
  end;
end;

function TCustomDBGrid.GetColumnCount: Integer;
var
  i: integer;
  F: TField;
begin
  result := 0;
  if Columns.Enabled then
    result := Columns.VisibleCount
  else
    if FDataLink.Active then
      for i:=0 to FDataLink.DataSet.FieldCount-1 do begin
        F:= FDataLink.DataSet.Fields[i];
        if (F<>nil) and F.Visible then
          Inc(Result);
      end;
end;

// Get the visible field (from dataset fields) that corresponds to given column
function TCustomDBGrid.GetDsFieldFromGridColumn(Column: Integer): TField;
var
  i: Integer;
begin
  i := FieldIndexFromGridColumn( Column );
  if i>=0 then
    Result := FDataLink.DataSet.Fields[i]
  else
    Result := nil;
end;

// obtain the field either from a Db column or directly from dataset fields
function TCustomDBGrid.GetFieldFromGridColumn(Column: Integer): TField;
var
  i: integer;
begin
  if Columns.Enabled then begin
    i := ColumnIndexFromGridColumn( Column );
    if i>=0 then
      result := TDBGridColumns(Columns)[i].FField
    else
      result := nil;
  end else
    result := GetDsFieldFromGridColumn(Column);
end;

// obtain the corresponding grid column for the given field
function TCustomDBGrid.GetGridColumnFromField(F: TField): Integer;
var
  i: Integer;
begin
  result := -1;
  for i:=FixedCols to ColCount-1 do begin
    if GetFieldFromGridColumn(i) = F then begin
      result := i;
      break;
    end;
  end;
end;

// obtain the visible field index corresponding to the grid column index
function TCustomDBGrid.FieldIndexFromGridColumn(Column: Integer): Integer;
var
  i: Integer;
begin
  column := column - FixedCols;
  i := 0;
  result := -1;
  if FDataLink.Active then
  while (i<FDataLink.DataSet.FieldCount)and(Column>=0) do begin
    if FDataLink.Fields[i].Visible then begin
        Dec(Column);
        if Column<0 then begin
          result := i;
          break;
        end;
    end;
    inc(i);
  end;
end;

procedure TCustomDBGrid.UpdateGridColumnSizes;
var
  i: Integer;
begin
  if FDefaultColWidths then begin
    if dgIndicator in Options then
      ColWidths[0]:=12;
    for i:=FixedCols to ColCount-1 do
      ColWidths[i] := GetColumnWidth(i);
  end;
end;

procedure TCustomDBGrid.UpdateScrollbarRange;
var
  aRange, aPage: Integer;
  aPos: Integer;
  isSeq: boolean;
  ScrollInfo: TScrollInfo;
begin
  if not HandleAllocated then exit;
  if FDatalink.Active then begin
    IsSeq := FDatalink.dataset.IsSequenced{$ifndef EnableIsSeq}and false{$endif};
    if IsSeq then begin
      aRange := GetRecordCount + VisibleRowCount - 1;
      aPage := VisibleRowCount;
      if aPage<1 then aPage := 1;
      if FDatalink.BOF then aPos := 0 else
      if FDatalink.EOF then aPos := aRange
      else
        aPos := FDataLink.DataSet.RecNo - 1; // RecNo is 1 based
      if aPos<0 then aPos:=0;
    end else begin
      aRange := 6;
      aPage := 2;
      if FDatalink.EOF then aPos := 4 else
      if FDatalink.BOF then aPos := 0
      else aPos := 2;
    end;
  end else begin
    aRange := 0;
    aPage := 0;
    aPos := 0;
  end;
  
  //ScrollBarRange(SB_VERT, aRange, aPage);
  //ScrollBarPosition(SB_VERT, aPos);
  FillChar(ScrollInfo, SizeOf(ScrollInfo), 0);
  ScrollInfo.cbSize := SizeOf(ScrollInfo);
  {$ifdef WINDOWS}
  ScrollInfo.fMask := SIF_ALL or SIF_DISABLENOSCROLL;
  ScrollInfo.ntrackPos := 0;
  {$else}
  ScrollInfo.fMask := SIF_ALL or SIF_UPDATEPOLICY;
  //ScrollInfo.ntrackPos := SB_POLICY_CONTINUOUS;
  ScrollInfo.ntrackPos := SB_POLICY_DISCONTINUOUS;
  {$endif}
  ScrollInfo.nMin := 0;
  ScrollInfo.nMax := aRange;
  ScrollInfo.nPos := aPos;
  ScrollInfo.nPage := aPage;
  // the redraw argument of SetScrollInfo means under gtk
  // if the scrollbar is visible or not, in windows it
  // seems to mean if the scrollbar is redrawn or not
  // to reflect the scrollbar changes made
  SetScrollInfo(Handle, SB_VERT, ScrollInfo,
    (ScrollBars in [ssBoth, ssVertical]) or
    ((Scrollbars in [ssAutoVertical, ssAutoBoth]) and (aRange>aPAge))
  );
  
  FOldPosition := aPos;
  {$ifdef dbgDBGrid}
  DebugLn('UpdateScrollBarRange: Handle=',IntToStr(Handle),
   ' aRange=', IntToStr(aRange),
   ' aPage=', IntToStr(aPage), ' aPos=', IntToStr(aPos));
  {$endif}
end;
procedure TCustomDBGrid.BeginVisualChange;
begin
  inc(FVisualChangeCount);
end;

procedure TCustomDBGrid.EndVisualChange;
begin
  dec(FVisualChangecount);
  if FVisualChangeCount = 0 then
    VisualChange;
end;

procedure TCustomDBGrid.doLayoutChanged;
begin
  if csDestroying in ComponentState then
    exit;
  {$ifdef dbgDBGrid} DebugLn('doLayoutChanged INIT'); {$endif}
  if UpdateGridCounts=0 then
    EmptyGrid;
  UpdateScrollBarRange;
  {$ifdef dbgDBGrid} DebugLn('doLayoutChanged FIN'); {$endif}
end;
{
procedure TCustomDBGrid.WriteColumns(Writer: TWriter);
begin
  if Columns.IsDefault then
    Writer.WriteCollection(nil)
  else
    Writer.WriteCollection(Columns);
end;
}
procedure TCustomDBGrid.RestoreEditor;
begin
  if EditorMode then begin
    EditorMode := False;
    EditorMode := True;
  end;
end;

function TCustomDBGrid.IsEOF: boolean;
begin
  with FDatalink do
    result :=
      Active and DataSet.EOF;
end;

function TCustomDBGrid.ValidDataSet: boolean;
begin
  result := FDatalink.Active And (FDatalink.DataSet<>nil)
end;

function TCustomDBGrid.InsertCancelable: boolean;
begin
  with FDatalink.DataSet do
  Result := (State=dsInsert) and not (Modified or FDataLink.FModified);
end;

procedure TCustomDBGrid.StartUpdating;
begin
  if not UpdatingData then begin
    {$ifdef dbgDBGrid} DebugLn('DBGrid.StartUpdating');{$endif}
    Include(FGridStatus, gsUpdatingData);
    FOldControlStyle := ControlStyle;
    ControlStyle := ControlStyle + [csActionClient];
    LockEditor;
  end
  else
    {$ifdef dbgDBGrid} DebugLn('WARNING: multiple call to StartUpdating');{$endif}
end;

procedure TCustomDBGrid.EndUpdating;
begin
  {$ifdef dbgDBGrid} DebugLn('DBGrid.EndUpdating');{$endif}
  Exclude(FGridStatus, gsUpdatingData);
  ControlStyle := FOldControlStyle;
  UnLockEditor;
  if csActionClient in ControlStyle then
    DebugLn('WARNING: still got csActionClient');
end;

function TCustomDBGrid.UpdatingData: boolean;
begin
  result := gsUpdatingData in FGridStatus;
end;

procedure TCustomDBGrid.AddAutomaticColumns;
var
  i: Integer;
  F: TField;
begin
  // add as many columns as there are fields in the dataset
  // do this only at runtime.
  if (csDesigning in ComponentState) or not FDatalink.Active or
    (gsRemovingAutoColumns in FGridStatus) then
    exit;

  Include(FGridStatus, gsAddingAutoColumns);
  try
    for i:=0 to FDataLink.DataSet.FieldCount-1 do begin

      F:= FDataLink.DataSet.Fields[i];

      if TDBGridColumns(Columns).ColumnFromField(F) <> nil then
        // this field is already in the collection. This could only happen
        // if AddAutomaticColumns was called out of LayoutChanged.
        // to avoid duplicate columns skip this field.
        continue;

      if (F<>nil) then begin
        with TDBGridColumns(Columns).Add do begin
          FIsAutomaticColumn := True;
          Field := F;
          Visible := F.Visible;
        end;
      end;

    end;
    // honor the field.index
    TDBGridColumns(Columns).ResetColumnsOrder(coFieldIndexOrder);
  finally
    Exclude(FGridStatus, gsAddingAutoColumns);
  end;
  
end;

procedure TCustomDBGrid.SwapCheckBox;
var
  SelField: TField;
  TempColumn: TColumn;
begin
  if not GridCanModify then
    exit;

  SelField := SelectedField;
  TempColumn := TColumn(ColumnFromGridColumn(Col));
  if (TempColumn<>nil) and not TempColumn.ReadOnly then
  begin
    if SelField.DataType=ftBoolean then
    begin
      SelField.DataSet.Edit;
    	SelField.AsBoolean := not SelField.AsBoolean
    end
    else
    begin
      SelField.DataSet.Edit;
      if ValueMatch(TempColumn.ValueChecked, SelField.AsString) then
        SelField.AsString := TempColumn.ValueUnchecked
      else
        SelField.AsString := TempColumn.ValueChecked;
    end;
  end;
end;

function TCustomDBGrid.ValueMatch(const BaseValue, TestValue: string): Boolean;
begin
  if BaseValue=TestValue then
    Result := True
  else
    Result := False;
end;

procedure TCustomDBGrid.ToggleSelectedRow;
begin
  SelectRecord(not FSelectedRows.CurrentRowSelected);
end;

procedure TCustomDBGrid.LinkActive(Value: Boolean);
begin
  if not Value then
    RemoveAutomaticColumns;
  LayoutChanged;
end;

procedure TCustomDBGrid.LayoutChanged;
begin
  if csDestroying in ComponentState then
    exit;
  if FLayoutChangedCount=0 then begin
    BeginLayout;
    if Columns.Count>0 then
      TDBGridColumns(Columns).LinkFields
    else if not FDataLink.Active then
      FDataLink.BufferCount := 0
    else
      AddAutomaticColumns;
    EndLayout;
  end;
end;

procedure TCustomDBGrid.Loaded;
begin
  LayoutChanged;
  inherited Loaded;
end;

type
  TProtFields=class(TFields)
  end;

procedure TCustomDBGrid.ColRowMoved(IsColumn: Boolean; FromIndex,
  ToIndex: Integer);
var
  F,CurField: TField;
  ColIndex: Integer;
begin
  if IsColumn then begin
    CurField := SelectedField;
    if Columns.Enabled then
      inherited ColRowMoved(IsColumn, FromIndex, ToIndex)
    else if FDatalink.Active and (FDataLink.DataSet<>nil) then begin
      F := GetDsFieldFromGridColumn(FromIndex);
      if F<>nil then begin
        TProtFields(FDatalink.DataSet.Fields).SetFieldIndex( F, ToIndex - FixedCols );
      end;
    end;
    ColIndex := GetGridColumnFromField(CurField);
    if (ColIndex>FixedCols) and (ColIndex<>Col) then begin
      // todo: buscar alguna otra forma de hacer esto
      FSelectionLock := true;
      try
        Col := ColIndex;
      finally
        FSelectionLock := False;
      end;
    end;

    if Assigned(OnColumnMoved) then
      OnColumnMoved(Self, FromIndex, ToIndex);
  end;
end;

function TCustomDBGrid.ColumnEditorStyle(aCol: Integer; F: TField): TColumnButtonStyle;
begin
  Result := cbsAuto;
  if Columns.Enabled then
    Result := ColumnFromGridColumn(aCol).ButtonStyle;

  if (Result=cbsAuto) and (F<>nil) then
    case F.DataType of
      ftBoolean: Result := cbsCheckboxColumn;
    end;

  if (result = cbsCheckBoxColumn) and not (dgeCheckboxColumn in FExtraOptions) then
    Result := cbsAuto;
end;

function TCustomDBGrid.CreateColumns: TGridColumns;
begin
  result := TDBGridColumns.Create(Self, TColumn);
end;

procedure TCustomDBGrid.CreateWnd;
begin
  inherited CreateWnd;
  LayoutChanged;
  if Scrollbars in [ssBoth, ssVertical, ssAutoBoth, ssAutoVertical] then
    ScrollBarShow(SB_VERT, True);
end;

procedure TCustomDBGrid.DefineProperties(Filer: TFiler);
  {
  function HasColumns: boolean;
  var
    C: TGridColumns;
  begin
    if Filer.Ancestor <> nil then
      C := TCustomGrid(Filer.Ancestor).Columns
    else
      C := Columns;
    if C<>nil then
      result := not C.IsDefault
    else
      result := false;
  end;
  }
begin
  // simply avoid to call TCustomGrid.DefineProperties method
  // which defines ColWidths,Rowheights,Cells
  //Filer.DefineProperty('Columns',  @ReadColumns,  @WriteColumns,  HasColumns);
end;

procedure TCustomDBGrid.DefaultDrawCell(aCol, aRow: Integer; aRect: TRect;
  aState: TGridDrawState);

  function GetDatasetState: TDataSetState;
  begin
    if FDatalink.Active then
      result := FDataLink.DataSet.State
    else
      result := dsInactive;
  end;

var
  S: string;
  F: TField;
begin
  if gdFixed in aState then begin
    if (ACol=0) and FDrawingActiveRecord then begin
      DrawIndicator(Canvas, aRect, GetDataSetState, FDrawingMultiSelRecord);
      {$ifdef dbgGridPaint}
      dbgOut('>');
      {$endif}
    end else
    if (ACol=0) and FDrawingMultiSelRecord then
      DrawIndicator(Canvas, aRect, dsCurValue{dummy}, True)
    else
    if (aRow=0)and(ACol>=FixedCols) then
      DrawCellText(aCol,aRow,aRect,aState,GetColumnTitle(aCol));
  end else
  if not FDrawingEmptyDataset then begin
    F := GetFieldFromGridColumn(aCol);
    case ColumnEditorStyle(aCol, F) of
      cbsCheckBoxColumn:
        DrawCheckBoxBitmaps(aCol, aRect, F);
      else begin
        if F<>nil then begin
          if F.dataType <> ftBlob then
            S := F.DisplayText
          else
            S := '(blob)';
        end else
          S := '';
        DrawCellText(aCol,aRow,aRect,aState,S);
      end;
    end;
  end;
end;


procedure TCustomDBGrid.DoOnChangeBounds;
begin
  BeginUpdate;
  inherited DoOnChangeBounds;
  if HandleAllocated then
    LayoutChanged;
  EndUpdate(False);
end;

procedure TCustomDBGrid.BeforeMoveSelection(const DCol,DRow: Integer);
begin
  if FSelectionLock then
    exit;
  {$ifdef dbgDBGrid}DebugLn('DBGrid.BefMovSel INIT');{$endif}
  inherited BeforeMoveSelection(DCol, DRow);
  if DCol<>Col then begin
    if assigned(OnColExit) then
      OnColExit(Self);
    FColEnterPending:=True;
  end;
{$ifdef dbgDBGrid}DebugLn('DBGrid.BefMovSel END');{$endif}
end;

procedure TCustomDBGrid.HeaderClick(IsColumn: Boolean; index: Integer);
begin
  if IsColumn and Assigned(OnTitleClick) then
    OnTitleClick(TColumn(ColumnFromGridColumn(Index)));
end;

procedure TCustomDBGrid.KeyDown(var Key: Word; Shift: TShiftState);
var
  DeltaCol,DeltaRow: Integer;
  WasCancelled: boolean;

  procedure DoOnKeyDown;
  begin
    if Assigned(OnKeyDown) then
      OnKeyDown(Self, Key, Shift);
  end;
  procedure DoMoveBy(amount: Integer);
  begin
    {$IfDef dbgGrid}DebugLn('KeyDown.DoMoveBy(',IntToStr(Amount),')');{$Endif}
    FDatalink.MoveBy(Amount);
    {$IfDef dbgGrid}DebugLn('KeyDown.DoMoveBy FIN');{$Endif}
  end;
  procedure DoMoveBySmall(amount: Integer);
  begin
    {$IfDef dbgGrid}DebugLn('KeyDown.DoMoveBySmall(',IntToStr(Amount),')');{$Endif}
    Include(FGridStatus, gsVisibleMove);
    FDatalink.CheckFirstRecord;
    FDatalink.MoveBy(Amount);
    Exclude(FGridStatus, gsVisibleMove);
    {$IfDef dbgGrid}DebugLn('KeyDown.doMoveBySmall FIN');{$Endif}
  end;
  procedure DoCancel;
  begin
    {$IfDef dbgGrid}DebugLn('KeyDown.doCancel INIT');{$Endif}
    if EditorMode then
      EditorCancelEditing;
    FDatalink.Dataset.cancel;
    {$IfDef dbgGrid}DebugLn('KeyDown.doCancel FIN');{$Endif}
  end;
  procedure DoDelete;
  begin
    {$IfDef dbgGrid}DebugLn('KeyDown.doDelete INIT');{$Endif}
    FDatalink.Dataset.Delete;
    {$IfDef dbgGrid}DebugLn('KeyDown.doDelete FIN');{$Endif}
  end;
  procedure DoAppend;
  begin
    {$IfDef dbgGrid}DebugLn('KeyDown.doAppend INIT');{$Endif}
    FDatalink.Dataset.Append;
    {$IfDef dbgGrid}DebugLn('KeyDown.doAppend FIN');{$Endif}
  end;
  procedure DoInsert;
  begin
    {$IfDef dbgGrid}DebugLn('KeyDown.doInsert INIT');{$Endif}
    FDatalink.Dataset.Insert;
    {$IfDef dbgGrid}DebugLn('KeyDown.doInsert FIN');{$Endif}
  end;
  function doVKDown: boolean;
  begin
    if InsertCancelable then
    begin
      if IsEOF then
        //exit
      else
        doCancel;
      result := true;
    end else begin
      doMoveBySmall(1);
      if GridCanModify and FDataLink.EOF then
        doAppend;
      result := false;
    end;
  end;
  function DoVKUP: boolean;
  begin
    Result := InsertCancelable and IsEOF;
    if Result then
      doCancel
    else
      doMoveBySmall(-1);
  end;
begin
  {$IfDef dbgGrid}DebugLn('DBGrid.KeyDown INIT Key= ',IntToStr(Key));{$Endif}
  case Key of

    VK_TAB:
      begin
        doOnKeyDown;
        if Key<>0 then begin
          if dgTabs in Options then begin

            GetDeltaMoveNext(ssShift in Shift, DeltaCol, DeltaRow);

            if DeltaRow > 0 then
              WasCancelled := doVkDown
            else
            if DeltaRow < 0 then
              WasCancelled := doVKUp
            else
              WasCancelled := false;

            if not WasCancelled and (DeltaCol<>0) then
              Col := Col + DeltaCol;

            Key := 0;
          end;
        end;
      end;

    VK_DELETE:
      begin
        doOnKeyDown;
        if (Key<>0) and (ssCtrl in Shift) and GridCanModify then
          if not (dgConfirmDelete in Options) or
            (MessageDlg('Delete record?',mtConfirmation,mbOKCancel,0)<>mrCancel)
          then begin
            doDelete;
            key := 0;
          end;
      end;

    VK_DOWN:
      if ValidDataSet then begin
        DoOnKeyDown;
        if Key<>0 then begin
          doVKDown;
          Key := 0;
        end;
      end;

    VK_UP:
      if ValidDataSet then begin
        doOnKeyDown;
        if Key<>0 then begin
          doVKUp;
          key := 0;
         end;
      end;

    VK_NEXT:
      begin
        doOnKeyDown;
        if Key<>0 then begin
          doMoveBy( VisibleRowCount );
          Key := 0;
        end;
      end;

    VK_PRIOR:
      begin
        doOnKeyDown;
        if Key<>0 then begin
          doMoveBy( -VisibleRowCount );
          key := 0;
        end;
      end;

    VK_ESCAPE:
      begin
        doOnKeyDown;
        if Key<>0 then begin
          if EditorMode then begin
            EditorCancelEditing;
            if FDatalink.Active and not FDatalink.Dataset.Modified then
              FDatalink.Modified := False;
            Key := 0;
          end else
            if FDataLink.Active then
              doCancel;
        end;
      end;

    VK_INSERT:
      begin
        doOnKeyDown;
        if Key<>0 then
          if GridCanModify then begin
            doInsert;
            Key:=0;
          end;
      end;

    VK_HOME:
      begin
        doOnKeyDown;
        if Key<>0 then begin
          if FDatalink.Active then begin
            if ssCTRL in Shift then
              FDataLink.DataSet.First
            else
              MoveNextSelectable(False, FixedCols, Row);
            Key:=0;
          end;
        end;
      end;

    VK_END:
      begin
        doOnKeyDown;
        if Key<>0 then begin
          if FDatalink.Active then begin
            if ssCTRL in shift then
              FDatalink.DataSet.Last
            else
              MoveNextSelectable(False, ColCount-1, Row);
            Key:=0;
          end;
        end;
      end;

    VK_SPACE:
      begin
        doOnKeyDown;
        if Key<>0 then begin
          if ColumnEditorStyle(Col, SelectedField) = cbsCheckboxColumn then begin
        		SwapCheckBox;
            Key:=0;
          end;
        end;
      end;
      
    VK_MULTIPLY:
      begin
        if ssCtrl in Shift then
          ToggleSelectedRow;
      end;

    else
      inherited KeyDown(Key, Shift);
  end;
  {$IfDef dbgGrid}DebugLn('DBGrid.KeyDown END Key= ',IntToStr(Key));{$Endif}
end;

procedure TCustomDBGrid.MouseDown(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
var
  Gz: TGridZone;
  P: TPoint;
  procedure doMouseDown;
  begin
    if assigned(OnMouseDown) then
      OnMouseDown(Self, Button, Shift, X, Y);
  end;
  procedure doInherited;
  begin
    inherited MouseDown(Button, Shift, X, Y);
  end;
  procedure doMoveBy;
  begin
    {$IfDef dbgGrid} DebugLn('DBGrid.MouseDown MoveBy INIT'); {$Endif}
    Include(FGridStatus, gsVisibleMove);
    FDatalink.MoveBy(P.Y - Row);
    Exclude(FGridStatus, gsVisibleMove);
    {$IfDef dbgGrid} DebugLn('DBGrid.MouseDown MoveBy END'); {$Endif}
  end;
  procedure doMoveToColumn;
  begin
    {$IfDef dbgGrid} DebugLn('DBGrid.MouseDown MoveToCol INIT Col=', IntToStr(P.X)); {$Endif}
    Col := P.X;
    {$IfDef dbgGrid} DebugLn('DBGrid.MouseDown MoveToCol END'); {$Endif}
  end;
  procedure DoCancel;
  begin
    {$IfDef dbgGrid}DebugLn('DBGrid.MouseDown Dataset.CANCEL INIT');{$Endif}
    if EditorMode then
      EditorCancelEditing;
    FDatalink.Dataset.cancel;
    {$IfDef dbgGrid}DebugLn('DBGrid.MouseDown Dataset.CANCEL FIN');{$Endif}
  end;
  procedure DoAcceptValue;
  begin
    if EditorMode and FDatalink.FModified then
      EditorMode := False;
  end;
begin
  {$ifdef dbgDBGrid}DebugLn('DBGrid.mousedown - INIT');{$endif}
  if (csDesigning in componentState) {or not GCache.ValidGrid }then
    exit;

  if UpdatingData then begin
    {$ifdef dbgDBGrid}DebugLn('DBGrid.MouseDown - UpdatingData');{$endif}
    exit;
  end;

  if button<>mbLeft then begin
    doInherited;
    exit;
  end;

  {$IfDef dbgGrid} DebugLn('DBGrid.MouseDown INIT'); {$Endif}
  Gz:=MouseToGridZone(X,Y);
  case Gz of
    gzFixedRows, gzFixedCols:
      doInherited;
    else
      begin
        P:=MouseToCell(Point(X,Y));
        if P.Y=Row then begin
          //doAcceptValue;
          if ssCtrl in Shift then
            ToggleSelectedRow
          else
            doInherited;
        end else begin
          doMouseDown;
          if ValidDataSet then begin
            if InsertCancelable and IsEOF then
              doCancel;
            doMoveBy;
          end;
          if ssCtrl in Shift then
            ToggleSelectedRow
          else
            doMoveToColumn;
        end;
      end;
  end;
  {$IfDef dbgGrid} DebugLn('DBGrid.MouseDown END'); {$Endif}
end;

procedure TCustomDBGrid.Paint;
begin
  CheckWidths;
  inherited Paint;
end;

procedure TCustomDBGrid.PrepareCanvas(aCol, aRow: Integer;
  aState: TGridDrawState);
begin
  inherited PrepareCanvas(aCol, aRow, aState);
  if (not FDatalink.Active) and ((gdSelected in aState) or
    (gdFocused in aState)) then
    Canvas.Brush.Color := Self.Color;
end;

procedure TCustomDBGrid.RemoveAutomaticColumns;
begin
  if not (csDesigning in ComponentState) then
    TDBGridColumns(Columns).RemoveAutoColumns;
end;

procedure TCustomDBGrid.SelectEditor;
begin
  if FDatalink.Active then
    inherited SelectEditor
  else
    Editor := nil;
end;

procedure TCustomDBGrid.SetEditText(ACol, ARow: Longint; const Value: string);
begin
  //SelectedField.AsString := AValue; // Delayed to avoid frequent updates
  FTempText := Value;
end;

function TCustomDBGrid.ScrollBarAutomatic(Which: TScrollStyle): boolean;
begin
  if Which=ssHorizontal then
    Result:= true
  else
    Result:=inherited ScrollBarAutomatic(Which);
  {$ifdef dbgScroll}
  DebugLn('TCustomDBGrid.ScrollbarAutomatic Which=',dbgs(Ord(Which)),
    ' Result=',dbgs(Result));
  {$endif}
end;

function TCustomDBGrid.SelectCell(aCol, aRow: Integer): boolean;
begin
  Result:= (ColWidths[aCol] > 0) and (RowHeights[aRow] > 0);
end;

procedure TCustomDBGrid.BeginLayout;
begin
  inc(FLayoutChangedCount);
end;

procedure TCustomDBGrid.EditingColumn(aCol: Integer; Ok: Boolean);
begin
  {$ifdef dbgDBGrid} DebugLn('DBGrid.EditingColumn INIT aCol=', InttoStr(aCol), ' Ok=', BoolToStr(ok)); {$endif}
  if Ok then begin
    FEditingColumn := aCol;
    FDatalink.Modified := True;
  end
  else
    FEditingColumn := -1;
  {$ifdef dbgDBGrid} DebugLn('DBGrid.EditingColumn END'); {$endif}
end;

procedure TCustomDBGrid.EditorCancelEditing;
begin
  EditingColumn(FEditingColumn, False); // prevents updating the value
  if EditorMode then begin
    EditorMode := False;
    if dgAlwaysShowEditor in Options then
      EditorMode := True;
  end;
end;

procedure TCustomDBGrid.EditorDoGetValue;
begin
  {$ifdef dbgDBGrid}DebugLn('DBGrid.EditorDoGetValue INIT');{$endif}
  inherited EditordoGetValue;
  UpdateData;
  {$ifdef dbgDBGrid}DebugLn('DBGrid.EditorDoGetValue FIN');{$endif}
end;

procedure TCustomDBGrid.CellClick(const aCol, aRow: Integer);
begin
  if (aCol>=FixedCols)and(aRow>=FixedRows) then begin
    if ColumnEditorStyle(ACol, SelectedField) = cbsCheckboxColumn then
      if FIsEditingCheckBox then
  			SwapCheckBox
      else
      	FIsEditingCheckBox := True;
  end;
  if Assigned(OnCellClick) then
    OnCellClick(TColumn(ColumnFromGridColumn(aCol)));
end;

procedure TCustomDBGrid.ChangeBounds(ALeft, ATop, AWidth, AHeight: integer);
begin
  inherited ChangeBounds(ALeft, ATop, AWidth, AHeight);
end;

procedure TCustomDBGrid.EndLayout;
begin
  dec(FLayoutChangedCount);
  if FLayoutChangedCount = 0 then
    DoLayoutChanged;
end;

function TCustomDBGrid.GetDefaultColumnAlignment(Column: Integer): TAlignment;
var
  F: TField;
begin
  F := GetDsFieldFromGridColumn(Column);
  if F<>nil then
    result := F.Alignment
  else
    result := taLeftJustify;
end;

function TCustomDBGrid.GetDefaultColumnWidth(Column: Integer): Integer;
begin
  Result := DefaultFieldColWidth(GetDsFieldFromGridColumn(Column));
end;

function TCustomDBGrid.GetDefaultColumnReadOnly(Column: Integer): boolean;
var
  F: Tfield;
begin
  result := true;
  if not Self.ReadOnly and (FDataLink.Active and not FDatalink.ReadOnly) then begin
    F := GetDsFieldFromGridColumn(Column);
    result := (F=nil) or F.ReadOnly;
  end;
end;

function TCustomDBGrid.GetDefaultColumnTitle(Column: Integer): string;
var
  F: Tfield;
begin
  F := GetDsFieldFromGridColumn(Column);
  if F<>nil then
    Result := F.DisplayName
  else
    Result := '';
end;

procedure TCustomDBGrid.DoExit;
begin
  {$ifdef dbgDBGrid}DebugLn('DBGrid.DoExit INIT');{$Endif}
  if not EditorShowing then begin
    if ValidDataSet and (dgCancelOnExit in Options) and
      InsertCancelable then
    begin
      FDataLink.DataSet.Cancel;
      EditorCancelEditing;
    end;
  end;
  inherited DoExit;
  {$ifdef dbgDBGrid}DebugLn('DBGrid.DoExit FIN');{$Endif}
end;

function TCustomDBGrid.DoMouseWheelDown(Shift: TShiftState; MousePos: TPoint
  ): Boolean;
begin
  Result := False;
  if Assigned(OnMouseWheelDown) then
    OnMouseWheelDown(Self, Shift, MousePos, Result);
  if not Result and FDatalink.Active then begin
    Include(FGridStatus, gsVisibleMove);
    FDatalink.MoveBy(1);
    Exclude(FGridStatus, gsVisibleMove);
    Result := True;
  end;
end;

function TCustomDBGrid.DoMouseWheelUp(Shift: TShiftState; MousePos: TPoint
  ): Boolean;
begin
  Result := False;
  if Assigned(OnMouseWheelUp) then
    OnMouseWheelUp(Self, Shift, MousePos, Result);
  if not Result and FDatalink.Active then begin
    Include(FGridStatus, gsVisibleMove);
    FDatalink.MoveBy(-1);
    Exclude(FGridStatus, gsVisibleMove);
    Result := True;
  end;
end;

function TCustomDBGrid.GetEditMask(aCol, aRow: Longint): string;
var
  aField: TField;
begin
  Result := '';
  if FDataLink.Active then begin
    aField := GetFieldFromGridColumn(aCol);
    if (aField<>nil) then begin
      {$ifdef EnableFieldEditMask}
      // enable following line if TField gets in the future a MaskEdit property
      //Result := aField.EditMask;
      if assigned(OnFieldEditMask) then
        OnFieldEditMask(Self, AField, Result);
      {$endif}
    end;
  end;
end;

function TCustomDBGrid.GetEditText(aCol, aRow: Longint): string;
var
  aField: TField;
begin
  if FDataLink.Active then begin
    aField := GetFieldFromGridColumn(aCol);
    if aField<>nil then begin
      Result := aField.AsString;
    end;
  end;
end;

function  TCustomDBGrid.GetImageForCheckBox(CheckBoxView: TDBGridCheckBoxState): TBitmap;
begin
  if CheckboxView=gcbpUnchecked then
    Result := FUncheckedBitmap
  else if CheckboxView=gcbpChecked then
    Result := FCheckedBitmap
  else
  	Result := FGrayedBitmap;

  if Assigned(OnUserCheckboxBitmap) then
    OnUserCheckboxBitmap(Self, CheckBoxView, Result);
end;

function TCustomDBGrid.GetIsCellSelected(aCol, aRow: Integer): boolean;
begin
  Result:=inherited GetIsCellSelected(aCol, aRow) or
    FDrawingMultiSelRecord;
end;

function TCustomDBGrid.GridCanModify: boolean;
begin
  result := not ReadOnly and (dgEditing in Options) and not FDataLink.ReadOnly
    and FDataLink.Active and FDatalink.DataSet.CanModify;
end;

procedure TCustomDBGrid.MoveSelection;
begin
  if FSelectionLock then
    exit;
  FIsEditingCheckBox := False;
  {$ifdef dbgDBGrid}DebugLn('DBGrid.MoveSelection INIT');{$Endif}
  inherited MoveSelection;
  if FColEnterPending and Assigned(OnColEnter) then begin
    OnColEnter(Self);
  end;
  FColEnterPending:=False;
  UpdateActive;
  {$ifdef dbgDBGrid}DebugLn('DBGrid.MoveSelection FIN');{$Endif}
end;

procedure TCustomDBGrid.DrawAllRows;
var
  CurActiveRecord: Integer;
begin
  if FDataLink.Active then begin
    CurActiveRecord:=FDataLink.ActiveRecord;
    FDrawingEmptyDataset:=FDatalink.DataSet.IsEmpty;
  end else
    FDrawingEmptyDataset:=True;
  try
    inherited DrawAllRows;
  finally
    if FDataLink.Active then
      FDataLink.ActiveRecord:=CurActiveRecord;
  end;
end;

procedure TCustomDBGrid.DrawFocusRect(aCol, aRow: Integer; ARect: TRect);
begin
  // Draw focused cell if we have the focus
  if Self.Focused and (dgAlwaysShowSelection in Options) and
    FDatalink.Active then
  begin
    CalcFocusRect(aRect);
    DrawRubberRect(Canvas, aRect, FocusColor);
  end;
end;

//
procedure TCustomDBGrid.DrawRow(ARow: Integer);
begin
  if (ARow>=FixedRows) and FDataLink.Active then begin
    //if (Arow>=FixedRows) and FCanBrowse then
    FDataLink.ActiveRecord:=ARow-FixedRows;
    FDrawingActiveRecord := ARow = Row;
    FDrawingMultiSelRecord := (dgMultiSelect in Options) and
      SelectedRows.CurrentRowSelected
  end else begin
    FDrawingActiveRecord := False;
    FDrawingMultiSelRecord := False;
  end;
  {$ifdef dbgGridPaint}
  DbgOut('DrawRow Row=', IntToStr(ARow), ' Act=', Copy(BoolToStr(FDrawingActiveRecord),1,1));
  {$endif}
  inherited DrawRow(ARow);
  {$ifdef dbgGridPaint}
  DebugLn('End Row')
  {$endif}
end;

procedure TCustomDBGrid.DrawCell(aCol, aRow: Integer; aRect: TRect;
  aState: TGridDrawState);
begin
  inherited DrawCell(aCol, aRow, aRect, aState);
  {$ifdef dbgGridPaint}
  DbgOut(' ',IntToStr(aCol));
  if gdSelected in aState then DbgOut('S');
  if gdFocused in aState then DbgOut('*');
  if gdFixed in aState then DbgOut('F');
  {$endif dbgGridPaint}
  if Assigned(OnDrawColumnCell) and not(CsDesigning in ComponentState) then
    OnDrawColumnCell(Self, aRect, aCol, TColumn(ColumnFromGridColumn(aCol)), aState)
  else
    DefaultDrawCell(aCol, aRow, aRect, aState);
end;

procedure TCustomDBGrid.DrawCheckboxBitmaps(aCol: Integer; aRect: TRect;
  F: TField);
var
  ChkBitmap: TBitmap;
  XPos,YPos: Integer;
begin
  // by SSY
	if (F<>nil) then
  	if F.DataType=ftBoolean then
      if F.IsNull then
    		ChkBitmap := GetImageForCheckBox(gcbpGrayed)
      else
        if F.AsBoolean then
          ChkBitmap := GetImageForCheckBox(gcbpChecked)
        else
        	ChkBitmap := GetImageForCheckBox(gcbpUnChecked)
    else
      if ValueMatch(F.AsString, TColumn(ColumnFromGridColumn(aCol)).ValueChecked) then
        ChkBitmap := GetImageForCheckBox(gcbpChecked)
      else
      	if ValueMatch(F.AsString, TColumn(ColumnFromGridColumn(aCol)).ValueUnChecked) then
      		ChkBitmap := GetImageForCheckBox(gcbpUnChecked)
        else
          ChkBitmap := GetImageForCheckBox(gcbpGrayed)
  else
    ChkBitmap := GetImageForCheckBox(gcbpGrayed);

  if ChkBitmap<>nil then begin
    XPos := Trunc((aRect.Left+aRect.Right-ChkBitmap.Width)/2);
    YPos := Trunc((aRect.Top+aRect.Bottom-ChkBitmap.Height)/2);
    Canvas.Draw(XPos, YPos, ChkBitmap);
  end;
end;

function TCustomDBGrid.EditorCanAcceptKey(const ch: Char): boolean;
var
  aField: TField;
begin
  result := False;
  if FDataLink.Active then begin
    aField := SelectedField;
    if aField<>nil then begin
      Result := aField.IsValidChar(Ch) and not aField.Calculated and
        (aField.DataType<>ftAutoInc) and not aField.IsBlob;
    end;
  end;
end;

function TCustomDBGrid.EditorIsReadOnly: boolean;
begin
  Result := inherited EditorIsReadOnly;
  if not Result then begin
    Result := not FDataLink.Edit;
    EditingColumn(Col, not Result);
  end;
end;

procedure TCustomDBGrid.HeaderSized(IsColumn: Boolean; Index: Integer);
var
  i: Integer;
begin
  if IsColumn then begin
    if Columns.Enabled then begin
      i := ColumnIndexFromGridColumn(Index);
      if i>=0 then
        Columns[i].Width := ColWidths[Index];
    end;
    FDefaultColWidths := False;
    if Assigned(OnColumnSized) then
      OnColumnSized(Self);
  end;
end;

procedure TCustomDBGrid.UpdateActive;
var
  PrevRow: Integer;
begin
  if (csDestroying in ComponentState) or not FDatalink.Active then
    exit;
    {$IfDef dbgDBGrid}
  DebugLn(Name,'.UpdateActive: ActiveRecord=', dbgs(FDataLink.ActiveRecord),
            ' FixedRows=',dbgs(FixedRows), ' Row=', dbgs(Row));
    {$endif}
  PrevRow := Row;
  Row:= FixedRows + FDataLink.ActiveRecord;
  if PrevRow<>Row then
    InvalidateCell(0, PrevRow);//(InvalidateRow(PrevRow);
  InvalidateRow(Row);
end;

function TCustomDBGrid.UpdateGridCounts: Integer;
var
  RecCount: Integer;
  FRCount, FCCount: Integer;
begin
  // find out the column count, if result=0 then
  // there are no visible columns defined or dataset is inactive
  // or there are no visible fields, ie the grid is blank
  BeginVisualChange;
  try
    Result := GetColumnCount;
    if Result > 0 then begin

      if dgTitles in Options then FRCount := 1 else FRCount := 0;
      if dgIndicator in Options then FCCount := 1 else FCCount := 0;
      InternalSetColCount(Result + FCCount);

      if FDataLink.Active then begin
        UpdateBufferCount;
        RecCount := FDataLink.RecordCount;
        if RecCount<1 then
          RecCount := 1;
      end else begin
        RecCount := 0;
        if FRCount=0 then
          // need to be as large enought to hold indicator
          // if there is one, and if there are no titles
          RecCount := FCCount;
      end;

      Inc(RecCount, FRCount);
      
      RowCount := RecCount;
      FixedRows := FRCount;
      FixedCols := FCCount;
      UpdateGridColumnSizes;
    end;
  finally
    EndVisualChange;
  end;
end;

procedure TCustomDBGrid.UpdateVertScrollbar(const aVisible: boolean;
  const aRange, aPage: Integer);
begin
  {$ifdef DbgScroll}
  DebugLn('TCustomDBGrid.UpdateVertScrollbar: Vis=',dbgs(aVisible),
    ' Range=',dbgs(aRange),' Page=',dbgs(aPage));
  {$endif}
  if (Scrollbars in [ssAutoVertical, ssAutoBoth]) then begin
    // ssAutovertical and ssAutoBoth would get the scrollbar hidden
    // but this case should be handled as if the scrollbar where
    // ssVertical or ssBoth
    ScrollBarShow(SB_VERT, True)
  end else
    ScrollBarShow(SB_VERT, AVisible);
end;

procedure TCustomDBGrid.VisualChange;
begin
  if FVisualChangeCount=0 then begin
    inherited VisualChange;
  end;
end;

constructor TCustomDBGrid.Create(AOwner: TComponent);
begin
  FEditingColumn:=-1;
  DragDx:=5;
  inherited Create(AOwner);

  FDataLink := TComponentDataLink.Create;//(Self);
  FDataLink.OnRecordChanged:=@OnRecordChanged;
  FDataLink.OnDatasetChanged:=@OnDataSetChanged;
  FDataLink.OnDataSetOpen:=@OnDataSetOpen;
  FDataLink.OnDataSetClose:=@OnDataSetClose;
  FDataLink.OnNewDataSet:=@OnNewDataSet;
  FDataLink.OnInvalidDataSet:=@OnInvalidDataset;
  FDataLink.OnInvalidDataSource:=@OnInvalidDataSource;
  FDataLink.OnDataSetScrolled:=@OnDataSetScrolled;
  FDataLink.OnLayoutChanged:=@OnLayoutChanged;
  FDataLink.OnEditingChanged:=@OnEditingChanged;
  FDataLink.OnUpdateData:=@OnUpdateData;
  FDataLink.VisualControl:= True;
  
  FSelectedRows := TBookmarkList.Create(Self);

  FDefaultColWidths := True;

  FOptions := [dgColumnResize, dgColumnMove, dgTitles, dgIndicator, dgRowLines,
    dgColLines, dgConfirmDelete, dgCancelOnExit, dgTabs, dgEditing,
    dgAlwaysShowSelection];

  inherited Options :=
    [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect,
     goSmoothScroll, goColMoving, goTabs, goEditing, goDrawFocusSelected,
     goColSizing ];

  FExtraOptions := [dgeAutoColumns, dgeCheckboxColumn];

  AutoAdvance := aaRightDown;

  // What a dilema!, we need ssAutoHorizontal and ssVertical!!!
  ScrolLBars:=ssBoth;

  DefaultRowHeight := 18;

  // Default bitmaps for cbsCheckedColumn
  FUnCheckedBitmap := TBitmap.Create;
  FUnCheckedBitmap.Handle := CreatePixmapIndirect(@IMGDBUnCheckedBox[0],
    GetSysColor(COLOR_BTNFACE));
  FCheckedBitmap := TBitmap.Create;
  FCheckedBitmap.Handle := CreatePixmapIndirect(@IMGDBCheckedBox[0],
    GetSysColor(COLOR_BTNFACE));
  FGrayedBitmap := TBitmap.Create;
  FGrayedBitmap.Handle := CreatePixmapIndirect(@IMGDBGrayedBox[0],
    GetSysColor(COLOR_BTNFACE));
end;

procedure TCustomDBGrid.InitiateAction;
begin
  {$ifdef dbgDBGrid}DebugLn('===> DBGrid.InitiateAction INIT');{$endif}
  inherited InitiateAction;
  if (gsUpdatingData in FGridStatus) then begin
    EndUpdating;
    {
    if EditorMode then begin
      Editor.SetFocus;
      EditorSelectAll;
    end;
    }
  end;
  {$ifdef dbgDBGrid}DebugLn('<=== DBGrid.InitiateAction FIN');{$endif}
end;

procedure TCustomDBGrid.DefaultDrawColumnCell(const Rect: TRect;
  DataCol: Integer; Column: TColumn; State: TGridDrawState);

  function GetDatasetState: TDataSetState;
  begin
    if FDatalink.Active then
      result := FDataLink.DataSet.State
    else
      result := dsInactive;
  end;
  
var
  S: string;
  F: TField;
begin
  if gdFixed in State then begin
    if (DataCol=0) and FDrawingActiveRecord then
      DrawIndicator(Canvas, Rect, GetDataSetState, FDrawingMultiSelRecord)
    else
    if (DataCol=0) and FDrawingMultiSelRecord then
      DrawIndicator(Canvas, Rect, dsCurValue{dummy}, True)
    else
    if (DataCol>=FixedCols) then
      DrawCellText(0{dummy}, DataCol{dummy}, Rect, State,GetColumnTitle(DataCol));
  end else begin
    F := GetFieldFromGridColumn(DataCol);
    case ColumnEditorStyle(DataCol, F) of
      cbsCheckBoxColumn:
        DrawCheckBoxBitmaps(DataCol, Rect, F);
      else begin
        if F<>nil then begin
          if F.dataType <> ftBlob then
            S := F.DisplayText
          else
            S := '(blob)';
        end else
          S := '';
        DrawCellText(0, DataCol, Rect, State, S);
      end;
    end;
  end;
end;

function TCustomDBGrid.EditorByStyle(Style: TColumnButtonStyle): TWinControl;
begin
  // we want override the editor style if it is cbsAuto because
  // field.datatype might be ftBoolean or some other cases
  if Style=cbsAuto then
    Style := ColumnEditorStyle(Col, SelectedField);

  Result:=inherited EditorByStyle(Style);
end;

procedure TCustomDBGrid.ResetColWidths;
begin
  if not FDefaultColWidths then begin
    FDefaultColWidths := True;
    LayoutChanged;
  end;
end;

procedure TCustomDBGrid.SelectRecord(AValue: boolean);
begin
  if dgMultiSelect in Options then
    FSelectedRows.CurrentRowSelected := AValue;
end;

destructor TCustomDBGrid.Destroy;
begin
  FUncheckedBitmap.Free;
  FCheckedBitmap.Free;
  FGrayedBitmap.Free;
  FSelectedRows.Free;
  FDataLink.OnDataSetChanged:=nil;
  FDataLink.OnRecordChanged:=nil;
  FDataLink.Free;
  inherited Destroy;
end;

{ TComponentDataLink }

function TComponentDataLink.GetFields(Index: Integer): TField;
begin
  if (index>=0)and(index<DataSet.FieldCount) then result:=DataSet.Fields[index];
end;

function TComponentDataLink.GetDataSetName: string;
begin
  Result:=FDataSetName;
  if DataSet<>nil then Result:=DataSet.Name;
end;

procedure TComponentDataLink.SetDataSetName(const AValue: string);
begin
  if FDataSetName<>AValue then FDataSetName:=AValue;
end;

procedure TComponentDataLink.RecordChanged(Field: TField);
begin
  {$ifdef dbgDBGrid}
  DebugLn('TComponentDataLink.RecordChanged');
  {$endif}
  if Assigned(OnRecordChanged) then
    OnRecordChanged(Field);
end;

procedure TComponentDataLink.DataSetChanged;
begin
  {$ifdef dbgDBGrid}
  DebugLn('TComponentDataLink.DataSetChanged, FirstRecord=', dbgs(FirstRecord));
  {$Endif}
  // todo: improve this routine, for example: OnDatasetInserted
  if Assigned(OnDataSetChanged) then
    OnDataSetChanged(DataSet);
end;

procedure TComponentDataLink.ActiveChanged;
begin
  {$ifdef dbgDBGrid}
  DebugLn('TComponentDataLink.ActiveChanged');
  {$endif}
  if Active then begin
    fDataSet := DataSet;
    if DataSetName <> fDataSetName then begin
      fDataSetName := DataSetName;
      if Assigned(fOnNewDataSet) then fOnNewDataSet(DataSet);
    end else
      if Assigned(fOnDataSetOpen) then fOnDataSetOpen(DataSet);
  end else begin
    BufferCount := 0;
    if (DataSource = nil)then begin
      if Assigned(fOnInvalidDataSource) then fOnInvalidDataSource(fDataSet);
      fDataSet := nil;
      fDataSetName := '[???]';
    end else begin
      if (DataSet=nil)or(csDestroying in DataSet.ComponentState) then begin
        if Assigned(fOnInvalidDataSet) then fOnInvalidDataSet(fDataSet);
        fDataSet := nil;
        fDataSetName := '[???]';
      end else begin
        if Assigned(fOnDataSetClose) then fOnDataSetClose(DataSet);
        if DataSet <> nil then FDataSetName := DataSetName;
      end;
    end;
  end;
end;

procedure TComponentDataLink.LayoutChanged;
begin
  {$ifdef dbgDBGrid}
  DebugLn('TComponentDataLink.LayoutChanged');
  {$Endif}
  if Assigned(OnLayoutChanged) then
    OnLayoutChanged(DataSet);
end;

procedure TComponentDataLink.DataSetScrolled(Distance: Integer);
begin
  {$ifdef dbgDBGrid}
  DebugLn('TComponentDataLink.DataSetScrolled(',IntToStr(Distance),')');
  {$endif}
  if Assigned(OnDataSetScrolled) then
    OnDataSetScrolled(DataSet, Distance);
end;

procedure TComponentDataLink.FocusControl(Field: TFieldRef);
begin
  {$ifdef dbgDBGrid}
  DebugLn('TComponentDataLink.FocusControl');
  {$endif}
end;

procedure TComponentDataLink.CheckBrowseMode;
begin
  {$ifdef dbgDBGrid}
  DebugLn(ClassName,'.CheckBrowseMode');
  {$endif}
  inherited CheckBrowseMode;
end;

function TComponentDataLink.CheckFirstRecord: boolean;
begin
  Result := FOldFirstRecord<>FirstRecord;
  FOldFirstRecord := FirstRecord;
end;

procedure TComponentDataLink.EditingChanged;
begin
  {$ifdef dbgDBGrid}
  DebugLn(ClassName,'.EditingChanged');
  {$endif}
  if Assigned(OnEditingChanged) then
    OnEditingChanged(DataSet);
end;

procedure TComponentDataLink.UpdateData;
begin
  {$ifdef dbgDBGrid}
  DebugLn(ClassName,'.UpdateData');
  {$endif}
  if Assigned(OnUpdatedata) then
    OnUpdateData(DataSet);
end;

function TComponentDataLink.MoveBy(Distance: Integer): Integer;
begin
  (*
  {$ifdef dbgDBGrid}
  DebugLn(ClassName,'.MoveBy  INIT: Distance=',Distance);
  {$endif}
  *)
  Result:=inherited MoveBy(Distance);
  (*
  {$ifdef dbgDBGrid}
  DebugLn(ClassName,'.MoveBy  END: Distance=',Distance);
  {$endif}
  *)
end;

{ TDBGridColumns }

function TDBGridColumns.GetColumn(Index: Integer): TColumn;
begin
  result := TColumn( inherited Items[Index] );
end;

procedure TDBGridColumns.SetColumn(Index: Integer; Value: TColumn);
begin
  Items[Index].Assign( Value );
end;

procedure TDBGridColumns.Update(Item: TCollectionItem);
begin
  if (Grid<>nil) and not (csLoading in Grid.ComponentState) then
    TCustomDBGrid(Grid).LayoutChanged;
end;

function TDBGridColumns.ColumnFromField(Field: TField): TColumn;
var
  i: Integer;
begin
  if Field<>nil then
  for i:=0 to Count-1 do begin
    result := Items[i];
    if (result<>nil)and(result.Field=Field) then
      exit;
  end;
  result:=nil;
end;

function TDBGridColumns.HasAutomaticColumns: boolean;
var
  i: Integer;
begin
  Result := False;
  for i:=0 to Count-1 do
    if Items[i].IsAutomaticColumn then begin
      Result := true;
      break;
    end;
end;

function TDBGridColumns.HasDesignColumns: boolean;
var
  i: Integer;
begin
  Result := False;
  for i:=0 to Count-1 do
    if Items[i].IsDesignColumn then begin
      Result := true;
      break;
    end;
end;

procedure TDBGridColumns.RemoveAutoColumns;
var
  i: Integer;
  G: TCustomDBGrid;
begin
  if HasAutomaticColumns then begin
    G := TCustomDBGrid(Grid);
    Include(G.GridStatus, gsRemovingAutoColumns);
    BeginUpdate;
    try
      for i:=Count-1 downto 0 do
        if Items[i].IsAutomaticColumn then
          Delete(i);
    finally
      EndUpdate;
      Exclude(G.GridStatus, gsRemovingAutoColumns);
    end;
  end;
end;

function CompareFieldIndex(P1,P2:Pointer): integer;
begin
  if P1=P2 then
    Result := 0
  else if (P1=nil) or (TColumn(P1).Field=nil) then
    Result := 1
  else if (P2=nil) or (TColumn(P2).Field=nil) then
    Result := -1
  else
    Result := TColumn(P1).Field.Index - TColumn(P2).Field.Index;
end;

function CompareDesignIndex(P1,P2:Pointer): integer;
begin
  result := TColumn(P1).DesignIndex - TColumn(P2).DesignIndex;
end;

procedure TDBGridColumns.ResetColumnsOrder(ColumnOrder: TColumnOrder);
var
  L: TList;
  i: Integer;
begin

  L := TList.Create;
  try

    for i:=0 to Count-1 do
      L.Add(Items[i]);

    case ColumnOrder of
      coDesignOrder:
        begin
          if not HasDesignColumns then
            exit;
          L.Sort(@CompareDesignIndex)
        end;
      coFieldIndexOrder:
        L.Sort(@CompareFieldIndex);
      else
        exit;
    end;

    for i:=0 to L.Count-1 do
      TColumn(L.Items[i]).Index := i;

  finally
    L.Free;
  end;
end;

function TDBGridColumns.Add: TColumn;
var
  G: TCustomDBGrid;
begin
  G := TCustomDBGrid(Grid);
  if G<>nil then begin
    // remove automatic columns before adding user columns
    if not (gsAddingAutoColumns in G.GridStatus) then
      RemoveAutoColumns;
  end;
  result := TColumn( inherited add );
end;

procedure TDBGridColumns.LinkFields;
var
  i: Integer;
  G: TCustomDBGrid;
begin
  G := TCustomDBGrid(Grid);
  if G<>nil then
    G.BeginLayout;
  for i:=0 to Count-1 do
    Items[i].LinkField;
  if G<>nil then
    G.EndLayout;
end;

{ TColumn }

function TColumn.GetField: TField;
begin
  if (FFieldName<>'') and (FField<>nil) then
    LinkField;
  result := FField;
end;

function TColumn.GetIsDesignColumn: boolean;
begin
  result := (DesignIndex>=0) and (DesignIndex<10000);
end;

function TColumn.GetValueChecked: string;
begin
  if FValueChecked = nil then
    Result := GetDefaultValueChecked
  else
    Result := FValueChecked;
end;

function TColumn.GetValueUnchecked: string;
begin
  if FValueUnChecked = nil then
    Result := GetDefaultValueUnChecked
  else
    Result := FValueUnChecked;
end;

procedure TColumn.ApplyDisplayFormat;
begin
  if (FField <> nil) and FDisplayFormatChanged then begin
    if (FField is TNumericField) then
      TNumericField(FField).DisplayFormat := DisplayFormat
    else if (FField is TDateTimeField) then
      TDateTimeField(FField).DisplayFormat := DisplayFormat;
  end;
end;

function TColumn.GetDisplayFormat: string;
begin
  if not FDisplayFormatChanged then
    Result := GetDefaultDisplayFormat
  else
    result := FDisplayFormat;
end;

function TColumn.IsDisplayFormatStored: boolean;
begin
  Result := FDisplayFormatChanged;
end;

function TColumn.IsValueCheckedStored: boolean;
begin
  result := FValueChecked <> nil;
end;

function TColumn.IsValueUncheckedStored: boolean;
begin
  Result := FValueUnchecked <> nil;
end;

procedure TColumn.SetDisplayFormat(const AValue: string);
begin
  if (not FDisplayFormatChanged)or(CompareText(AValue, FDisplayFormat)<>0) then begin
    FDisplayFormat := AValue;
    FDisplayFormatChanged:=True;
    ColumnChanged;
  end;
end;

procedure TColumn.SetField(const AValue: TField);
begin
  if FField <> AValue then begin
    FField := AValue;
    if FField<>nil then
      FFieldName := FField.FieldName;
    ColumnChanged;
  end;
end;

procedure TColumn.SetFieldName(const AValue: String);
begin
  if FFieldName=AValue then exit;
  FFieldName:=AValue;
  LinkField;
  ColumnChanged;
end;

function TColumn.GetDataSet: TDataSet;
var
  AGrid: TCustomDBGrid;
begin
  AGrid := TCustomDBGrid(Grid);
  if (AGrid<>nil) then
    result := AGrid.FDataLink.DataSet
  else
    result :=nil;
end;

procedure TColumn.SetValueChecked(const AValue: string);
begin
  if (FValueChecked=nil)or(CompareText(AValue, FValueChecked)<>0) then begin
    if FValueChecked<>nil then
      StrDispose(FValueChecked)
    else
      if CompareText(AValue, GetDefaultValueChecked)=0 then
        exit;
    FValueChecked := StrNew(PChar(AValue));
    Changed(False);
  end;
end;

procedure TColumn.SetValueUnchecked(const AValue: string);
begin
  if (FValueUnchecked=nil)or(CompareText(AValue, FValueUnchecked)<>0) then begin
    if FValueUnchecked<>nil then
      StrDispose(FValueUnchecked)
    else
      if CompareText(AValue, GetDefaultValueUnchecked)=0 then
        exit;
    FValueUnchecked := StrNew(PChar(AValue));
    Changed(False);
  end;
end;

procedure TColumn.Assign(Source: TPersistent);
begin
  if Source is TColumn then begin
    //DebugLn('Assigning TColumn[',dbgs(Index),'] a TColumn')
    Collection.BeginUpdate;
    try
      inherited Assign(Source);
      FieldName := TColumn(Source).FieldName;
      DisplayFormat := TColumn(Source).FieldName;
      ValueChecked := TColumn(Source).ValueChecked;
      ValueUnchecked := TColumn(Source).ValueUnchecked;
    finally
      Collection.EndUpdate;
    end;
  end else
    inherited Assign(Source);
end;

function TColumn.GetDefaultWidth: Integer;
var
  AGrid: TCustomDBGrid;
  WasAllocated: boolean;
  aDC: HDC;
begin
  AGrid := TCustomDBGrid(Grid);
  if AGrid<>nil then begin
    WasAllocated := aGrid.Canvas.HandleAllocated;
    if not WasAllocated then begin
      aDC := GetDC(0); // desktop canvas
      aGrid.Canvas.Handle := aDC;
      aGrid.Canvas.Font := aGrid.Font;
    end;

    if AGrid.Canvas.HandleAllocated then begin
      if FField<>nil then
        result := CalcColumnFieldWidth(
          aGrid.Canvas,
          dgTitles in aGrid.Options,
          Title.Caption,
          Title.Font,
          FField)
      else
        result := AGrid.DefaultColWidth
    end else begin
      aGrid.NeedUpdateWidths := True;
      result := DEFCOLWIDTH;
    end;
    
    if not WasAllocated then begin
      aGrid.Canvas.Handle := 0;
      ReleaseDC(0, aDC);
    end;
      
  end else
    result := DEFCOLWIDTH;
end;

function TColumn.CreateTitle: TGridColumnTitle;
begin
  Result := TColumnTitle.Create(Self);
end;

constructor TColumn.Create(ACollection: TCollection);
var
  AGrid: TCustomGrid;
begin
  inherited Create(ACollection);
  if ACollection is TDBGridColumns then begin
    AGrid := TDBGridColumns(ACollection).Grid;
    if (AGrid<>nil) and (csLoading in AGrid.ComponentState) then
      FDesignIndex := Index
    else
      FDesignIndex := 10000;
  end;
end;

destructor TColumn.Destroy;
begin
  if FValueChecked<>nil then StrDispose(FValueChecked);
  if FValueUnchecked<>nil then StrDispose(FValueUnchecked);
  inherited Destroy;
end;

function TColumn.IsDefault: boolean;
begin
  result := not FDisplayFormatChanged and (inherited IsDefault());
end;

procedure TColumn.LinkField;
var
  AGrid: TCustomDBGrid;
begin
  AGrid:= TCustomDBGrid(Grid);
  if (AGrid<>nil) and AGrid.FDatalink.Active then begin
    Field := AGrid.FDataLink.DataSet.FindField(FFieldName);
    ApplyDisplayFormat;
  end else
    Field := nil;
end;

function TColumn.GetDefaultDisplayFormat: string;
begin
  Result := '';
  if FField<>nil then begin
    if FField is TNumericField then
      Result := TNumericField(FField).DisplayFormat
    else if FField is TDateTimeField then
      Result := TDateTimeField(FField).DisplayFormat
  end;
end;

function TColumn.GetDefaultValueChecked: string;
begin
  if (FField<>nil) and (FField.Datatype=ftBoolean) then
    Result := BoolToStr(True)
  else
    Result := '1';
end;

function TColumn.GetDefaultValueUnchecked: string;
begin
  if (FField<>nil) and (FField.DataType=ftBoolean) then
    Result := BoolToStr(False)
  else
    Result := '0';
end;

function TColumn.GetDefaultReadOnly: boolean;
var
  AGrid: TCustomDBGrid;
begin
  AGrid := TCustomDBGrid(Grid);
  Result := ((AGrid<>nil)and(AGrid.ReadOnly)) or ((FField<>nil)and(FField.ReadOnly))
end;

function TColumn.GetDefaultVisible: boolean;
begin
  if FField<>nil then
    result := FField.Visible
  else
    result := True;
end;

function TColumn.GetDisplayName: string;
begin
  if FFieldName<>'' then
    Result:=FFieldName
  else
    Result:=inherited GetDisplayName;
end;

function TColumn.GetDefaultAlignment: TAlignment;
begin
  if FField<>nil then
    result := FField.Alignment
  else
    Result := taLeftJustify;
end;

{ TColumnTitle }

function TColumnTitle.GetDefaultCaption: string;
begin
  with (Column as TColumn) do begin
    if FieldName<>'' then begin
      if FField<>nil then
        Result := Field.DisplayName
      else
        Result := Fieldname;
    end else
      Result := inherited GetDefaultCaption;
  end;
end;

{ TBookmarkList }

function TBookmarkList.GetCount: integer;
begin
  result := FList.Count;
end;

function TBookmarkList.GetCurrentRowSelected: boolean;
begin
  CheckActive;
  Result := IndexOf(FGrid.Datasource.Dataset.Bookmark)>=0;
end;

function TBookmarkList.GetItem(AIndex: Integer): TBookmarkStr;
begin
  Result := FList[AIndex];
end;

procedure TBookmarkList.SetCurrentRowSelected(const AValue: boolean);
var
  aBookStr: TBookmarkstr;
  aIndex: Integer;
begin
  CheckActive;
  
  aBookStr := FGrid.Datasource.Dataset.Bookmark;
  if ABookStr='' then
    exit;
    
  if Find(ABookStr, aIndex) then begin
    if not AValue then begin
      FList.Delete(aIndex);
      FGrid.Invalidate;
    end;
  end else begin
    if AValue then begin
      FList.Add(ABookStr);
      FGrid.Invalidate;
    end;
  end;
end;

procedure TBookmarkList.CheckActive;
begin
  if not Fgrid.FDataLink.Active then
    raise EInvalidGridOperation.Create('Dataset Inactive');
end;

constructor TBookmarkList.Create(AGrid: TCustomDBGrid);
begin
  inherited Create;
  FGrid := AGrid;
  FList := TStringList.Create;
end;

destructor TBookmarkList.Destroy;
begin
  Clear;
  FList.Free;
  inherited Destroy;
end;

procedure TBookmarkList.Clear;
begin
  FList.Clear;
  FGrid.Invalidate;
end;

procedure TBookmarkList.Delete;
var
  i: Integer;
  ds: TDataSet;
begin
  ds := FGrid.Datasource.Dataset;
  for i:=0 to FList.Count-1 do begin
    ds.Bookmark := Items[i];
    ds.Delete;
    FList.delete(i);
  end;
end;

function TBookmarkList.Find(const Item: TBookmarkStr; var AIndex: Integer): boolean;
var
  Indx: integer;
begin
  Indx := FList.IndexOf(Item);
  if indx<0 then
    Result := False
  else begin
    Result := True;
    AIndex := indx;
  end;
end;

function TBookmarkList.IndexOf(const Item: TBookmarkStr): Integer;
begin
  result := FList.IndexOf(Item)
end;

function TBookmarkList.Refresh: boolean;
var
  ds: TDataset;
  i: LongInt;
begin
  Result := False;
  ds := FGrid.Datasource.Dataset;
  for i:=FList.Count-1 downto 0 do
    if not ds.BookmarkValid(TBookMark(Items[i])) then begin
      Result := True;
      Flist.Delete(i);
    end;
  if Result then
    FGrid.Invalidate;
end;

end.