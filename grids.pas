{ $Id$}
{
 /***************************************************************************
                               Grids.pas
                               ---------
                     An interface to DB aware Controls
                     Initial Revision : Sun Sep 14 2003


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
{

TCustomGrid, TDrawGrid and TStringGrid for Lazarus
Copyright (C) 2002  Jesus Reyes Aguilar.
email: jesusrmx@yahoo.com.mx

Cur version: 0.8.5
The log was moved to end of file, search for: The_Log

}
unit Grids;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LCLStrConsts, LCLProc, LCLType, LCLIntf, Controls,
  GraphType, Graphics, Forms, VCLGlobals, DynamicArray, LMessages,
  XMLCfg, StdCtrls, LResources, MaskEdit;

const
  //GRIDFILEVERSION = 1; // Original
  //GRIDFILEVERSION = 2; // Introduced goSmoothScroll
  GRIDFILEVERSION = 3; // Introduced Col/Row FixedAttr and NormalAttr


const
  GM_SETVALUE   = LM_USER + 100;
  GM_GETVALUE   = LM_USER + 101;
  GM_SETGRID    = LM_USER + 102;
  GM_SETPOS     = LM_USER + 103;
  GM_SELECTALL  = LM_USER + 104;
  GM_SETMASK    = LM_USER + 105;

const
  CA_LEFT     =   $1;
  CA_CENTER   =   $2;
  CA_RIGHT    =   $4;
  CL_TOP      =   $8;
  CL_CENTER   =   $10;
  CL_BOTTOM   =   $20;

const
  EO_AUTOSIZE   =   $1;
  EO_HOOKKEYS   =   $2;
  EO_HOOKEXIT   =   $4;
  EO_SELECTALL  =   $8;
  EO_WANTCHAR   =   $10;

type
  EGridException = class(Exception);

type
  TGridOption = (
    goFixedVertLine,      // Ya
    goFixedHorzLine,      // Ya
    goVertLine,           // Ya
    goHorzLine,           // Ya
    goRangeSelect,        // Ya
    goDrawFocusSelected,  // Ya
    goRowSizing,          // Ya
    goColSizing,          // Ya
    goRowMoving,          // Ya
    goColMoving,          // Ya
    goEditing,            // Ya
    goTabs,               // Ya
    goRowSelect,          // Ya
    goAlwaysShowEditor,   // Ya
    goThumbTracking,      // ya
    // Additional Options
    goColSpanning,        // Enable cellextent calcs
    goRelaxedRowSelect,   // User can see focused cell on goRowSelect
    goDblClickAutoSize,   // dblclicking columns borders (on hdrs) resize col.
    goSmoothScroll        // Switch scrolling mode (pixel scroll is by default)
  );
  TGridOptions = set of TGridOption;

  TGridSaveOptions = (
    soDesign,             // Save grid structure (col/row count and Options)
    soAttributes,         // Save grid attributes (Font,Brush,TextStyle)
    soContent,            // Save Grid Content (Text in stringgrid)
    soPosition            // Save Grid cursor and selection position
  );
  TSaveOptions = Set of TGridSaveOptions;

  TGridDrawState = set of (gdSelected, gdFocused, gdFixed);
  TGridState =
    (gsNormal, gsSelecting, gsRowSizing, gsColSizing,gsRowMoving,gsColMoving);
  TGridZone = (gzNormal, gzFixedCols, gzFixedRows, gzFixedCells);

  TUpdateOption = (uoNone, uoQuick, uoFull);
  TAutoAdvance = (aaDown,aaRight);

  TGridStatus = (stNormal, stEditorHiding, stEditorShowing, stFocusing);
  TItemType = (itNormal,itCell,itColumn,itRow,itFixed,itFixedColumn,itFixedRow,itSelected);

const
  soAll: TSaveOptions = [soDesign, soAttributes, soContent, soPosition];

type

  TCustomGrid = class;


  PCellProps= ^TCellProps;
  TCellProps=record
    Attr: pointer;
    Data: TObject;
    Text: pchar;
  end;

  PColRowProps= ^TColRowProps;
  TColRowProps=record
    Size: Integer;
    FixedAttr: pointer;
    NormalAttr: pointer;
  end;

  PGridMessage=^TGridMessage;
  TGridMessage=record
    MsgID: Cardinal;
    Grid: TCustomGrid;
    Col,Row: Integer;
    Value: string;
    CellRect: TRect;
    Options: Integer;
  end;

 type

  { Default cell editor for TStringGrid }
  TStringCellEditor=class(TCustomMaskEdit)
  private
    FGrid: TCustomGrid;
  protected
    //procedure WndProc(var TheMessage : TLMessage); override;
    procedure Change; override;
    procedure KeyDown(var Key : Word; Shift : TShiftState); override;
    procedure msg_SetMask(var Msg: TGridMessage); message GM_SETMASK;
    procedure msg_SetValue(var Msg: TGridMessage); message GM_SETVALUE;
    procedure msg_GetValue(var Msg: TGridMessage); message GM_GETVALUE;
    procedure msg_SetGrid(var Msg: TGridMessage); message GM_SETGRID;
    procedure msg_SelectAll(var Msg: TGridMessage); message GM_SELECTALL;
  end;



  TOnDrawCell =
    procedure(Sender: TObject; Col, Row: Integer; aRect: TRect;
              aState:TGridDrawState) of object;

  TOnSelectCellEvent =
    procedure(Sender: TObject; Col, Row: Integer;
              var CanSelect: Boolean) of object;

  TOnSelectEvent =
    procedure(Sender: TObject; Col,Row: Integer) of object;

  TGridOperationEvent =
    procedure (Sender: TObject; IsColumn:Boolean;
               sIndex,tIndex: Integer) of object;
  THdrEvent =
    procedure(Sender: TObject; IsColumn: Boolean; index: Integer) of object;

  TOnCompareCells =
    function (Sender: TObject; Acol,ARow,Bcol,BRow: Integer): Integer of object;

  TSelectEditorEvent =
    procedure(Sender: TObject; Col,Row: Integer;
              var Editor: TWinControl) of object;

  TVirtualGrid=class
    private
      FColCount: Integer;
      FRowCount: Integer;
      FCells, FCols, FRows: TArray;
      function  GetCells(Col, Row: Integer): PCellProps;
      function  Getrows(Row: Integer): PColRowprops;
      function  Getcols(Col: Integer): PColRowprops;
      procedure SetCells(Col, Row: Integer; const AValue: PCellProps);
      procedure Setrows(Row: Integer; const Avalue: PColRowprops);
      procedure Setcolcount(const Avalue: Integer);
      procedure Setrowcount(const Avalue: Integer);
      procedure Setcols(Col: Integer; const Avalue: PColRowprops);
    protected
      procedure doDestroyItem(Sender: TObject; Col,Row:Integer; var Item: Pointer);
      procedure doNewItem(Sender: TObject; Col,Row:Integer; var Item: Pointer);
      procedure DeleteColRow(IsColumn: Boolean; index: Integer);
      procedure MoveColRow(IsColumn: Boolean; FromIndex, ToIndex: Integer);
      procedure ExchangeColRow(IsColumn:Boolean; index,WithIndex: Integer);
      procedure DisposeCell(var P: PCellProps); virtual;
      procedure DisposeColRow(var p: PColRowProps); virtual;
    public
      constructor Create;
      destructor Destroy; override;
      procedure Clear;
      function GetDefaultCell: PcellProps;
      function GetDefaultColRow: PColRowProps;

      property ColCount: Integer read FColCount write SetColCount;
      property RowCount: Integer read FRowCount write SetRowCount;

      property Celda[Col,Row: Integer]: PCellProps read GetCells write SetCells;
      property Cols[Col: Integer]: PColRowProps read GetCols write SetCols;
      property Rows[Row: Integer]: PColRowProps read GetRows write SetRows;
  end;

  type
    TGridCoord = TPoint;
    TGridRect  = TRect;

    TGridDataCache=record
      FixedWidth: Integer;    // Sum( Fixed ColsWidths[i] )
      FixedHeight: Integer;   // Sum( Fixed RowsHeights[i] )
      GridWidth: Integer;     // Sum( ColWidths[i] )
      GridHeight: Integer;    // Sum( RowHeights[i] )
      ClientWidth: Integer;   // Width-VertScrollbar.Size
      ClientHeight: Integer;  // Height-HorzScrollbar.Size
      ScrollWidth: Integer;   // ClientWidth-FixedWidth
      ScrollHeight: Integer;  // ClientHeight-FixedHeight
      VisibleGrid: TRect;     // Visible non fixed rectagle of cells
      MaxClientXY: Tpoint;    // VisibleGrid.BottomRight (pixel) coordinates
      ValidGrid: Boolean;     // true if there is something to show
      AccumWidth: TList;       // Accumulated width per column
      AccumHeight: TList;     // Accumulated Height per row
      HScrDiv,VScrDiv: Double;      // Transform const for ThumbTracking
      TLColOff,TLRowOff: Integer;   // TopLeft Offset in pixels
      MaxTopLeft: TPoint;     // Max Top left ( cell coorditates)
    end;

type
  TCustomGrid=class(TCustomControl)
  private
    FAutoAdvance: TAutoAdvance;
    FBorderStyle: TBorderStyle;
    FDefaultDrawing: Boolean;
    FEditor: TWinControl;
    FEditorHiding: Boolean;
    FEditorMode: Boolean;
    FEditorShowing: Boolean;
    FEditorKey: Boolean;
    FEditorOptions: Integer;
    FFlat: Boolean;
    FOnCompareCells: TOnCompareCells;
    FGridLineStyle: TPenStyle;
    FGridLineWidth: Integer;
    FDefColWidth, FDefRowHeight: Integer;
    FCol,FRow, FFixedCols, FFixedRows: Integer;
    FOnSelectEditor: TSelectEditorEvent;
    FGridLineColor: TColor;
    FFixedcolor, FFocusColor, FSelectedColor: TColor;
    FCols,FRows: TList;
    FsaveOptions: TSaveOptions;
    FScrollBars: TScrollStyle;
    FSelectActive: Boolean;
    FTopLeft: TPoint;
    FSplitter, FPivot: TPoint;
    FRange: TRect;
    FDragDx: Integer;
    FMoveLast: TPoint;
    FUpdateCount: Integer;
    FUpdateScrollBarsCount: Integer;
    FGCache: TGridDataCache;
    FOptions: TGridOptions;
    FOnDrawCell: TOnDrawcell;
    FOnBeforeSelection: TOnSelectEvent;
    FOnSelection: TOnSelectEvent;
    FOnTopLeftChanged: TNotifyEvent;
    FSkipUnselectable: Boolean;
    FGSMHBar, FGSMVBar: Integer; // Scrollbar's metrics
    FVSbVisible, FHSbVisible: boolean;

    procedure AdjustCount(IsColumn:Boolean; OldValue, NewValue:Integer);
    procedure CacheVisibleGrid;
    procedure CheckFixedCount(aCol,aRow,aFCol,aFRow: Integer);
    procedure CheckCount(aNewColCount, aNewRowCount: Integer);
    function  CheckTopLeft(aCol,aRow: Integer; CheckCols,CheckRows: boolean): boolean;
    procedure SetFlat(const AValue: Boolean);
    function  doColSizing(X,Y: Integer): Boolean;
    function  doRowSizing(X,Y: Integer): Boolean;
    procedure doColMoving(X,Y: Integer);
    procedure doRowMoving(X,Y: Integer);
    procedure doTopleftChange(DimChg: Boolean);
    procedure EditorGetValue;
    procedure EditorHide;
    procedure EditorPos;
    procedure EditorSelectAll;
    procedure EditorShowChar(Ch: Char);
    procedure EditorSetMode(const AValue: Boolean);
    procedure EditorSetValue;
    function  EditorShouldEdit: Boolean;
    procedure EditorShow;
    function  GetLeftCol: Integer;
    function  GetColCount: Integer;
    function  GetColWidths(Acol: Integer): Integer;
    function  GetRowCount: Integer;
    function  GetRowHeights(Arow: Integer): Integer;
    function  GetSelection: TGridRect;
    function  GetTopRow: Longint;
    function  GetVisibleColCount: Integer;
    function  GetVisibleGrid: TRect;
    function  GetVisibleRowCount: Integer;
    procedure MyTextRect(R: TRect; Offx,Offy:Integer; S:string; Clipping: boolean);
    procedure ReadColWidths(Reader: TReader);
    procedure ReadRowHeights(Reader: TReader);
    function  ScrollToCell(const aCol,aRow: Integer): Boolean;
    function  ScrollGrid(Relative:Boolean; DCol,DRow: Integer): TPoint;
    procedure SetBorderStyle(const AValue: TBorderStyle);
    procedure SetCol(Valor: Integer);
    procedure SetColwidths(Acol: Integer; Avalue: Integer);
    procedure SetColCount(Valor: Integer);
    procedure SetDefColWidth(Valor: Integer);
    procedure SetDefRowHeight(Valor: Integer);
    procedure SetDefaultDrawing(const AValue: Boolean);
    procedure SetEditor(AValue: TWinControl);
    procedure SetFixedCols(const AValue: Integer);
    procedure SetFixedRows(const AValue: Integer);
    procedure SetFocusColor(const AValue: TColor);
    procedure SetGridLineColor(const AValue: TColor);
    procedure SetGridLineStyle(const AValue: TPenStyle);
    procedure SetGridLineWidth(const AValue: Integer);
    procedure SetLeftCol(const AValue: Integer);
    procedure SetOptions(const AValue: TGridOptions);
    procedure SetRow(Valor: Integer);
    procedure SetRowCount(Valor: Integer);
    procedure SetRowheights(Arow: Integer; Avalue: Integer);
    procedure SetScrollBars(const AValue: TScrollStyle);
    procedure SetSelectActive(const AValue: Boolean);
    procedure SetSelection(const AValue: TGridRect);
    procedure SetTopRow(const AValue: Integer);
    procedure TryScrollTo(aCol,aRow: integer);
    procedure UpdateScrollBarPos(Which: TScrollStyle);
    procedure UpdateSelectionRange;
    procedure WriteColWidths(Writer: TWriter);
    procedure WriteRowHeights(Writer: TWriter);
    procedure WMEraseBkgnd(var message: TLMEraseBkgnd); message LM_ERASEBKGND;
    procedure WMGetDlgCode(var Msg: TLMNoParams); message LM_GETDLGCODE;
    procedure WMSize(var Msg: TLMSize); message LM_SIZE;
    procedure WMChar(var message: TLMChar); message LM_CHAR;
  protected
    fGridState: TGridState;
    procedure AutoAdjustColumn(aCol: Integer); virtual;
    procedure BeforeMoveSelection(const DCol,DRow: Integer); virtual;
    procedure ColRowDeleted(IsColumn: Boolean; index: Integer); dynamic;
    procedure ColRowExchanged(IsColumn: Boolean; index,WithIndex: Integer); dynamic;
    procedure ColRowMoved(IsColumn: Boolean; FromIndex,ToIndex: Integer); dynamic;
    function  ColRowToOffset(IsCol,Fisical:Boolean; index: Integer; var Ini,Fin:Integer): Boolean;
    procedure ColWidthsChanged; dynamic;
    procedure CreateWnd; override;
    procedure CreateParams(var Params: TCreateParams); override;
    procedure DblClick; override;
    procedure DefineProperties(Filer: TFiler); override;
    procedure DestroyHandle; override;
    procedure doExit; override;
    procedure doEnter; override;
    procedure DrawBackGround; virtual;
    procedure DrawBorder;
    procedure DrawByRows; virtual;
    procedure DrawCell(aCol,aRow:Integer; aRect:TRect; aState:TGridDrawState); virtual;
    procedure DrawCellGrid(aCol,aRow: Integer; aRect: TRect; astate: TGridDrawState);
    procedure DrawColRowMoving;
    procedure DrawEdges;
    //procedure DrawFixedCells; virtual;
    procedure DrawFocused; virtual;
    procedure DrawFocusRect(aCol,aRow:Integer; ARect:TRect; aState:TGridDrawstate); virtual;
    //procedure DrawInteriorCells; virtual;
    procedure DrawRow(aRow: Integer); virtual;
    procedure EditordoGetValue; virtual;
    procedure EditordoSetValue; virtual;
    function  GetFixedcolor: TColor; virtual;
    function  GetSelectedColor: TColor; virtual;
    function  GetEditMask(ACol, ARow: Longint): string; dynamic;
    function  GetEditText(ACol, ARow: Longint): string; dynamic;
    procedure SetEditText(ACol, ARow: Longint; const Value: string); dynamic;
    procedure HeaderClick(IsColumn: Boolean; index: Integer); dynamic;
    procedure InvalidateCell(aCol, aRow: Integer); overload;
    procedure InvalidateCell(aCol, aRow: Integer; Redraw: Boolean); overload;
    procedure InvalidateCol(ACol: Integer);
    procedure InvalidateGrid;
    procedure InvalidateRow(ARow: Integer);
    procedure KeyDown(var Key : Word; Shift : TShiftState); override;
    procedure KeyUp(var Key : Word; Shift : TShiftState); override;
    procedure LoadContent(cfg: TXMLConfig; Version: Integer); virtual;
    procedure Loaded; override;
    procedure MouseDown(Button: TMouseButton; Shift:TShiftState; X,Y:Integer); override;
    procedure MouseMove(Shift: TShiftState; X,Y: Integer);override;
    procedure MouseUp(Button: TMouseButton; Shift:TShiftState; X,Y:Integer); override;
    function  MoveExtend(Relative: Boolean; DCol, DRow: Integer): Boolean;
    function  MoveNextSelectable(Relative:Boolean; DCol, DRow: Integer): Boolean;
    procedure MoveSelection; virtual;
    function  OffsetToColRow(IsCol,Fisical:Boolean; Offset:Integer; var Rest:Integer): Integer;
    procedure Paint; override;
    procedure PrepareCanvas(aCol,aRow: Integer; aState:TGridDrawState); virtual;
    procedure ProcessEditor(LastEditor:TWinControl; DCol,DRow: Integer; WasVis: Boolean);
    procedure ResetOffset(chkCol, ChkRow: Boolean);
    procedure RowHeightsChanged; dynamic;
    procedure SaveContent(cfg: TXMLConfig); virtual;
    procedure ScrollBarRange(Which:Integer; {IsVisible:boolean; }aRange: Integer);
    procedure ScrollBarPosition(Which, Value: integer);
    //function  ScrollBarIsVisible(Which:Integer): Boolean;
    procedure ScrollBarPage(Which: Integer; aPage: Integer);
    procedure ScrollBarShow(Which: Integer; aValue: boolean);
    function  ScrollBarAutomatic(Which: TScrollStyle): boolean; virtual;
    procedure SelectEditor; virtual;
    function  SelectCell(ACol, ARow: Integer): Boolean; virtual;
    procedure SetFixedcolor(const AValue: TColor); virtual;
    procedure SetSelectedColor(const AValue: TColor); virtual;
    procedure SizeChanged(OldColCount, OldRowCount: Integer); dynamic;
    procedure Sort(ColSorting: Boolean; index,IndxFrom,IndxTo:Integer); virtual;
    procedure TopLeftChanged; dynamic;
    function  TryMoveSelection(Relative: Boolean; var DCol, DRow: Integer): Boolean;
    procedure VisualChange; virtual;
    procedure WMHScroll(var message : TLMHScroll); message LM_HScroll;
    procedure WMVScroll(var message : TLMVScroll); message LM_VScroll;
    procedure WndProc(var TheMessage : TLMessage); override;

    property AutoAdvance: TAutoAdvance read FAutoAdvance write FAutoAdvance default aaRight;
    property BorderStyle: TBorderStyle read FBorderStyle write SetBorderStyle default bsSingle;
    property Col: Integer read FCol write SetCol;
    property ColCount: Integer read GetColCount write SetColCount;
    property ColWidths[aCol: Integer]: Integer read GetColWidths write SetColWidths;
    property DefaultColWidth: Integer read FDefColWidth write SetDefColWidth;
    property DefaultRowHeight: Integer read FDefRowHeight write SetDefRowHeight;
    property DefaultDrawing: Boolean read FDefaultDrawing write SetDefaultDrawing default True;
    property DragDx: Integer read FDragDx write FDragDx;
    property Editor: TWinControl read FEditor write SetEditor;
    property EditorMode: Boolean read FEditorMode write EditorSetMode;
    property FixedCols: Integer read FFixedCols write SetFixedCols default 1;
    property FixedRows: Integer read FFixedRows write SetFixedRows default 1;
    property FixedColor: TColor read GetFixedColor write SetFixedcolor;
    property Flat: Boolean read FFlat write SetFlat default false;
    property FocusColor: TColor read FFocusColor write SetFocusColor;
    property GCache: TGridDataCache read FGCAChe;
    property GridHeight: Integer read FGCache.GridHeight;
    property GridLineColor: TColor read FGridLineColor write SetGridLineColor;
    property GridLineStyle: TPenStyle read FGridLineStyle write SetGridLineStyle;
    property GridLineWidth: Integer read FGridLineWidth write SetGridLineWidth default 1;
    property GridWidth: Integer read FGCache.GridWidth;
    property LeftCol:Integer read GetLeftCol write SetLeftCol;
    property Options: TGridOptions read FOptions write SetOptions;
    property Row: Integer read FRow write SetRow;
    property RowCount: Integer read GetRowCount write SetRowCount;
    property RowHeights[aRow: Integer]: Integer read GetRowHeights write SetRowHeights;
    property SaveOptions: TSaveOptions read FsaveOptions write FSaveOptions;
    property SelectActive: Boolean read FSelectActive write SetSelectActive;
    property SelectedColor: TColor read GetSelectedColor write SetSelectedColor;
    property Selection: TGridRect read GetSelection write SetSelection;
    property ScrollBars: TScrollStyle read FScrollBars write SetScrollBars;
    property SkipUnselectable: Boolean read FSkipUnselectable write FSkipUnselectable;
    property TopRow: Integer read GetTopRow write SetTopRow;
    property VisibleColCount: Integer read GetVisibleColCount;
    property VisibleRowCount: Integer read GetVisibleRowCount;

    property OnBeforeSelection: TOnSelectEvent read FOnBeforeSelection write FOnBeforeSelection;
    property OnCompareCells: TOnCompareCells read FOnCompareCells write FOnCompareCells;
    property OnDrawCell: TOnDrawCell read FOnDrawCell write FOnDrawCell;
    property OnSelection: TOnSelectEvent read fOnSelection write fOnSelection;
    property OnSelectEditor: TSelectEditorEvent read FOnSelectEditor write FOnSelectEditor;
    property OnTopLeftChanged: TNotifyEvent read FOnTopLeftChanged write FOnTopLeftChanged;

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Invalidate; override;

    { Exposed procs }
    procedure AutoAdjustColumns;
    procedure BeginUpdate;
    function  CellRect(ACol, ARow: Integer): TRect;
    procedure Clear;
    procedure DeleteColRow(IsColumn: Boolean; index: Integer);
    procedure EditorExit(Sender: TObject);
    procedure EditorKeyDown(Sender: TObject; var Key:Word; Shift:TShiftState);
    procedure EndUpdate(UO: TUpdateOption); overload;
    procedure EndUpdate(FullUpdate: Boolean); overload;
    procedure ExchangeColRow(IsColumn: Boolean; index, WithIndex: Integer);
    function  IscellSelected(aCol,aRow: Integer): Boolean;
    function  IscellVisible(aCol, aRow: Integer): Boolean;
    procedure LoadFromFile(FileName: string);
    function  MouseToCell(Mouse: TPoint): TPoint;
    function  MouseToLogcell(Mouse: TPoint): TPoint;
    function  MouseToGridZone(X,Y: Integer; CellCoords: Boolean): TGridZone;
    procedure MoveColRow(IsColumn: Boolean; FromIndex, ToIndex: Integer);
    procedure SaveToFile(FileName: string);
    procedure SortColRow(IsColumn: Boolean; index:Integer); overload;
    procedure SortColRow(IsColumn: Boolean; index,FromIndex,ToIndex: Integer); overload;
  end;

  TGetEditEvent = procedure (Sender: TObject; ACol, ARow: Integer; var Value: string) of object;
  TSetEditEvent = procedure (Sender: TObject; ACol, ARow: Integer; const Value: string) of object;

  TDrawGrid=class(TCustomGrid)
  private
    FOnColRowDeleted: TgridOperationEvent;
    FOnColRowExchanged: TgridOperationEvent;
    FOnColRowMoved: TgridOperationEvent;
    FOnGetEditMask: TGetEditEvent;
    FOnGetEditText: TGetEditEvent;
    FOnHeaderClick: THdrEvent;
    FOnSelectCell: TOnSelectcellEvent;
    FOnSetEditText: TSetEditEvent;
  protected
    FGrid: TVirtualGrid;
    procedure CalcCellExtent(acol, aRow: Integer; var aRect: TRect); virtual;
    procedure ColRowDeleted(IsColumn: Boolean; index: Integer); override;
    procedure ColRowExchanged(IsColumn: Boolean; index,WithIndex: Integer); override;
    procedure ColRowMoved(IsColumn: Boolean; FromIndex,ToIndex: Integer); override;
    function  CreateVirtualGrid: TVirtualGrid; virtual;
    procedure DrawCell(aCol,aRow: Integer; aRect: TRect; aState:TGridDrawState); override;
    procedure DrawFocusRect(aCol,aRow: Integer; ARect: TRect; aState: TGridDrawstate); override;
    procedure HeaderClick(IsColumn: Boolean; index: Integer); override;
    function  GetEditMask(aCol, aRow: Longint): string; override;
    function  GetEditText(aCol, aRow: Longint): string; override;
    function  SelectCell(aCol,aRow: Integer): boolean; override;
    procedure SetColor(Value: TColor); override;
    procedure SetEditText(ACol, ARow: Longint; const Value: string); override;
    procedure SizeChanged(OldColCount, OldRowCount: Integer); override;
  public

    // to easy user call
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure DefaultDrawCell(aCol,aRow: Integer; var aRect: TRect; aState:TGridDrawState); virtual;
    // properties
    property Canvas;
    property Col;
    property ColWidths;
    property Editor;
    property EditorMode;
    property FocusColor;
    property GridHeight;
    property GridLineColor;
    property GridLineStyle;
    property GridWidth;
    property LeftCol;
    property Row;
    property RowHeights;
    property SaveOptions;
    property Selection;
    property SkipUnselectable;
    //property TabStops;
    property TopRow;
  published
    property Align;
    property Anchors;
    property AutoAdvance;
    //property BiDiMode;
    property BorderStyle;
    property Color default clWindow;
    property ColCount;
    //property Constraints;
    //property Ctl3D; // Deprecated
    property DefaultColWidth;
    property DefaultDrawing;
    property DefaultRowHeight;
    //property DragCursor;
    //property DragKind;
    //property DragMode;
    property Enabled;
    property FixedColor;
    property FixedCols;
    property FixedRows;
    property Flat;
    property Font;
    property GridLineWidth;
    property Options;
    //property ParentBiDiMode;
    //property ParentColor;
    //property ParentCtl3D; // Deprecated
    //property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property RowCount;
    property ScrollBars;
    property ShowHint;
    property TabOrder;
    property TabStop;
    property Visible;
    property VisibleColCount;
    property VisibleRowCount;


    property OnBeforeSelection;
    property OnClick;
    property OnColRowDeleted: TgridOperationEvent read FOnColRowDeleted write FOnColRowDeleted;
    property OnColRowExchanged: TgridOperationEvent read FOnColRowExchanged write FOnColRowExchanged;
    property OnColRowMoved: TgridOperationEvent read FOnColRowMoved write FOnColRowMoved;
    property OnCompareCells;
    property OnDblClick;
    property OnDrawCell;
    property OnEnter;
    property OnExit;
    property OnGetEditMask: TGetEditEvent read FOnGetEditMask write FOnGetEditMask;
    property OnGetEditText: TGetEditEvent read FOnGetEditText write FOnGetEditText;
    property OnHeaderClick: THdrEvent read FOnHeaderClick write FOnHeaderClick;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnSelectEditor;
    property OnSelection;
    property OnSelectCell: TOnSelectCellEvent read FOnSelectCell write FOnSelectCell;
    property OnSetEditText: TSetEditEvent read FOnSetEditText write FOnSetEditText;
    property OnTopleftChanged;

{
    property OnContextPopup;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDock;
    property OnEndDrag;
    property OnStartDock;
    property OnStartDrag;
    property OnMouseWheelDown;
    property OnMouseWheelUp;
}
  end;

  TStringGrid = class(TDrawGrid)
    private
      FDefEditor: TStringCellEditor;
      function  GetCells(ACol, ARow: Integer): string;
      function  GetCols(index: Integer): TStrings;
      function  GetObjects(ACol, ARow: Integer): TObject;
      function  GetRows(index: Integer): TStrings;
      procedure ReadCells(Reader: TReader);
      procedure SetCells(ACol, ARow: Integer; const AValue: string);
      procedure SetCols(index: Integer; const AValue: TStrings);
      procedure SetObjects(ACol, ARow: Integer; AValue: TObject);
      procedure SetRows(index: Integer; const AValue: TStrings);
      procedure WriteCells(Writer: TWriter);
    protected
      procedure AutoAdjustColumn(aCol: Integer); override;
      procedure CalcCellExtent(acol, aRow: Integer; var aRect: TRect); override;
      procedure DefineProperties(Filer: TFiler); override;
      procedure DrawCell(aCol,aRow: Integer; aRect: TRect; aState:TGridDrawState); override;
      procedure EditordoGetValue; override;
      procedure EditordoSetValue; override;
      function  GetEditText(aCol, aRow: Integer): string; override;
      procedure LoadContent(cfg: TXMLConfig; Version: Integer); override;
      procedure SaveContent(cfg: TXMLConfig); override;
      //procedure DrawInteriorCells; override;
      procedure SelectEditor; override;
      procedure SetEditText(aCol, aRow: Longint; const aValue: string); override;

    public
      constructor Create(AOWner: TComponent); override;
      destructor Destroy; override;
      property Cells[ACol, ARow: Integer]: string read GetCells write SetCells;
      property Cols[index: Integer]: TStrings read GetCols write SetCols;
      property Objects[ACol, ARow: Integer]: TObject read GetObjects write SetObjects;
      property Rows[index: Integer]: TStrings read GetRows write SetRows;
  end;


  procedure DebugRect(S:string; R:TRect);
  procedure DebugPoint(S:string; P:TPoint);


procedure register;

implementation

{
// Dibujar una linea en el borde izquierdo de esta celda
Dc:=GetDC(handle);
Pen:=CreatePen(PS_SOLID, 3, clRed);
OldPen:=SelectObject(Dc, Pen);
MoveToEx(Dc, R.left, 0, nil);
LineTo(Dc, R.Left, FGCache.MaxClientXY.Y);
SelectObject(Dc, OldPen);
DeleteObject(Pen);
ReleaseDC(Handle, Dc);
FMoveLast:=P;
}

{function RndStr:string;
var
  i: Integer;
begin
  Result:='';
  For i:=1 to 10 do begin
    Result:=Result+ Char(Ord('A')+Random(20));
  end;
end;}
function PointIgual(const P1,P2: TPoint): Boolean;
begin
  result:=(P1.X=P2.X)and(P1.Y=P2.Y);
end;
{function RectIgual(const R1,R2: TRect): Boolean;
begin
  Result:=CompareMem(@R1,@R2, SizeOf(R1));
end;}
function Min(const I,J: Integer): Integer;
begin
  if I<J then Result:=I

  else        Result:=J;
end;
function Max(const I,J: Integer): Integer;
begin
  if I>J then Result:=I

  else        Result:=J;
end;
function NormalizarRect(const R:TRect): TRect;
begin
  Result.Left:=Min(R.Left, R.Right);

  Result.Top:=Min(R.Top, R.Bottom);
  Result.Right:=Max(R.Left, R.Right);
  Result.Bottom:=Max(R.Top, R.Bottom);
end;

procedure SwapInt(var I1,I2: Integer);
var
  Tmp: Integer;
begin
  Tmp:=I1;
  I1:=I2;
  I2:=Tmp;
end;

{$ifdef GridTraceMsg}
function TransMsg(const S: String; const TheMsg: TLMessage): String;
var
	hex: string;
begin
  with TheMsg do begin
    hex:= S + '['+IntToHex(msg, 8)+'] W='+IntToHex(WParam,8)+' L='+IntToHex(LParam,8)+' ';
    case Msg of
      CM_BASE..CM_MOUSEWHEEL:
        case Msg of
          CM_MOUSEENTER:          WriteLn(hex, 'CM_MOUSEENTER');
          CM_MOUSELEAVE:          WriteLn(hex, 'CM_MOUSELEAVE');
          CM_TEXTCHANGED:           WriteLn(hex, 'CM_TEXTCHANGED');
          CM_PARENTCTL3DCHANGED:    WriteLn(hex, 'CM_PARENTCTL3DCHANGED');
          CM_UIACTIVATE:            WriteLn(hex, 'CM_UIACTIVATE');
          CM_CONTROLLISTCHANGE:     WriteLn(hex, 'CM_CONTROLLISTCHANGE');
          
          CM_PARENTCOLORCHANGED:  WriteLn(hex, 'CM_PARENTCOLORCHANGED');
          CM_PARENTFONTCHANGED:   WriteLn(hex, 'CM_PARENTFONTCHANGED');
          CM_PARENTSHOWHINTCHANGED: WriteLn(hex, 'CM_PARENTSHOWHINTCHANGED');
          CM_PARENTBIDIMODECHANGED: WriteLn(hex, 'CM_PARENTBIDIMODECHANGED');
          CM_CONTROLCHANGE:         WriteLn(Hex, 'CM_CONTROLCHANGE');
          CM_SHOWINGCHANGED:        WriteLn(Hex, 'CM_SHOWINGCHANGED');
          CM_VISIBLECHANGED:        WriteLn(Hex, 'CM_VISIBLECHANGED');
          else                    WriteLn(Hex, 'CM_BASE + ', Msg - CM_BASE);
        end;
      else
        case Msg of
          //CN_BASE MESSAGES
          CN_COMMAND:             WriteLn(hex, 'LM_CNCOMMAND');
          // NORMAL MESSAGES
          LM_SETFOCUS:            WriteLn(hex, 'LM_SetFocus');
          LM_LBUTTONDOWN:         WriteLn(hex, 'LM_MOUSEDOWN');
          LM_LBUTTONUP:           WriteLn(hex, 'LM_LBUTTONUP');
          LM_RBUTTONDOWN:         WriteLn(hex, 'LM_RBUTTONDOWN');
          LM_RBUTTONUP:           WriteLn(hex, 'LM_RBUTTONUP');
          LM_GETDLGCODE:          WriteLn(hex, 'LM_GETDLGCODE');
          LM_KEYDOWN:             WriteLn(hex, 'LM_KEYDOWN');
          LM_KEYUP:               WriteLn(hex, 'LM_KEYUP');
          LM_CAPTURECHANGED:      WriteLn(hex, 'LM_CAPTURECHANGED');
          LM_ERASEBKGND:          WriteLn(hex, 'LM_ERASEBKGND');
          LM_KILLFOCUS:           WriteLn(hex, 'LM_KILLFOCUS');
          LM_CHAR:                WriteLn(hex, 'LM_CHAR');
          LM_SHOWWINDOW:          WriteLn(hex, 'LM_SHOWWINDOW');
          LM_SIZE:                WriteLn(hex, 'LM_SIZE');
          LM_WINDOWPOSCHANGED:    WriteLn(hex, 'LM_WINDOWPOSCHANGED');
          LM_HSCROLL:             WriteLn(hex, 'LM_HSCROLL');
          LM_VSCROLL:             WriteLn(hex, 'LM_VSCROLL');
          
          LM_MOUSEMOVE:           ;//WriteLn(hex, 'LM_MOUSEMOVE');
          LM_MOUSEWHEEL:          WriteLn(Hex, 'LM_MOUSEWHEEL');
          else                    WriteLn(hex, GetMessageName(Msg));
        end;
    end;
  end;
end;
{$Endif GridTraceMsg}

{ TCustomGrid }

function TCustomGrid.Getrowheights(Arow: Integer): Integer;
begin
  if aRow<RowCount then Result:=Integer(FRows[aRow])
  else                  Result:=-1;
  if Result<0 then Result:=fDefRowHeight;
end;

function TCustomGrid.GetTopRow: Longint;
begin
  Result:=fTopLeft.y;
end;

function TCustomGrid.GetVisibleColCount: Integer;
var
  R: TRect;
begin
  R:=FGCache.VisibleGrid;
  Result:=r.Right-r.left+1;//+FFixedCols;
end;

function TCustomGrid.GetVisibleRowCount: Integer;
var
  R: TRect;
begin
  R:=FGCache.VisibleGrid;
  Result:=r.bottom-r.top+1;//+FFixedRows;
end;

function TCustomGrid.GetLeftCol: Integer;
begin
  result:=fTopLeft.x;
end;

function TCustomGrid.Getcolcount: Integer;
begin
  Result:=FCols.Count;
end;

function TCustomGrid.Getrowcount: Integer;
begin
  Result:=FRows.Count;
end;

function TCustomGrid.Getcolwidths(Acol: Integer): Integer;
begin
  if aCol<ColCount then Result := Integer(FCols[aCol])
  else                  Result := -1;
  if result<0 then Result:=fDefColWidth;
end;

procedure TCustomGrid.SetEditor(AValue: TWinControl);
var
  Msg: TGridMessage;
begin
  if FEditor=AValue then exit;
  FEditor:=AValue;
  if FEditor<>nil then begin

    if FEditor.Parent=nil then FEditor.Visible:=False;
    if FEditor.Parent<>Self then FEditor.Parent:=Self;
    FEditor.TabStop:=False;

    Msg.MsgID:=GM_SETGRID;
    Msg.Grid:=Self;
    Msg.Options:=0;
    FEditor.Dispatch(Msg);
    FEditorOptions:=Msg.Options;

    if Msg.Options and EO_HOOKKEYS = EO_HOOKKEYS then begin
      FEditor.OnKeyDown:=@EditorKeyDown;
    end;

    if Msg.Options and EO_HOOKEXIT = EO_HOOKEXIT then begin
      FEditor.OnExit:=@EditorExit;
    end;

    {$IfDef EditorDbg}
    write('SetEditor-> Editor=',FEditor.Name,' ');
    if FEditorOptions and EO_AUTOSIZE = EO_AUTOSIZE then write('EO_AUTOSIZE ');
    if FEditorOptions and EO_HOOKKEYS = EO_HOOKKEYS then write('EO_HOOKKEYS ');
    if FEditorOptions and EO_HOOKEXIT = EO_HOOKEXIT then write('EO_HOOKEXIT ');
    if FEditorOptions and EO_SELECTALL= EO_SELECTALL then write('EO_SELECTALL ');
    if FEditorOptions and EO_WANTCHAR = EO_WANTCHAR then write('EO_WANTCHAR ');
    WriteLn;
    {$Endif}
  end;
end;

procedure TCustomGrid.SetFixedCols(const AValue: Integer);
begin
  if FFixedCols=AValue then exit;
  CheckFixedCount(ColCount, RowCount, AValue, FFixedRows);
  FFixedCols:=AValue;
  fTopLeft.x:=AValue;
  fCol:=Avalue;
  if not (csLoading in componentState) then doTopleftChange(true);
end;

procedure TCustomGrid.SetFixedRows(const AValue: Integer);
begin
  if FFixedRows=AValue then exit;
  CheckFixedCount(ColCount, RowCount, FFixedCols, AValue);
  FFixedRows:=AValue;
  fTopLeft.y:=AValue;
  FRow:=AValue;
  UpdateSelectionRange;
  if not (csLoading in ComponentState) Then doTopleftChange(true);
end;

procedure TCustomGrid.SetGridLineColor(const AValue: TColor);
begin
  if FGridLineColor=AValue then exit;
  FGridLineColor:=AValue;
  Invalidate;
end;

procedure TCustomGrid.SetLeftCol(const AValue: Integer);
begin
  TryScrollTo(AValue, FTopLeft.Y);
end;

procedure TCustomGrid.SetOptions(const AValue: TGridOptions);
begin
  if FOptions=AValue then exit;
  FOptions:=AValue;
  if goRangeSelect in Options then
    FOptions:=FOptions - [goAlwaysShowEditor];
  UpdateSelectionRange;
  if goAlwaysShowEditor in Options then begin
    EditorShow;
  end else begin
    EditorHide;
  end;
  VisualChange;
end;

procedure TCustomGrid.SetScrollBars(const AValue: TScrollStyle);
begin
  if FScrollBars=AValue then exit;
  FScrollBars:=AValue;
  VisualChange;
end;

procedure TCustomGrid.SetTopRow(const AValue: Integer);
begin
  TryScrollTo(FTopLeft.X, Avalue);
end;

procedure TCustomGrid.Setrowheights(Arow: Integer; Avalue: Integer);
begin
  if AValue<0 then AValue:=-1;
  if AValue<>Integer(FRows[ARow]) then begin
    FRows[ARow]:=Pointer(AValue);
    VisualChange;
    if (FEditor<>nil)and(Feditor.Visible)and(ARow<=FRow) then EditorPos;
    RowHeightsChanged;
  end;
end;

procedure TCustomGrid.Setcolwidths(Acol: Integer; Avalue: Integer);
begin
  if AValue<0 then Avalue:=-1;
  if Avalue<>Integer(FCols[ACol]) then begin
    FCols[ACol]:=Pointer(AValue);
    VisualChange;
    if (FEditor<>nil)and(Feditor.Visible)and(ACol<=FCol) then EditorPos;
    ColWidthsChanged;
  end;
end;

procedure TCustomGrid.AdjustCount(IsColumn: Boolean; OldValue, newValue: Integer);
  procedure AddDel(Lst: TList; aCount: Integer);
  begin
    while lst.Count<aCount do Lst.Add(Pointer(-1)); // default width/height
    Lst.Count:=aCount;
  end;
  procedure FixSelection;
  begin
    if FRow > FRows.Count - 1 then FRow := FRows.Count - 1;
    if FCol > FCols.Count - 1 then FCol := FCols.Count - 1;
    UpdateSelectionRange;
  end;
var
  OldCount: integer;
begin
  if IsColumn then begin
    AddDel(FCols, NewValue);
    FGCache.AccumWidth.Count:=NewValue;
    OldCount:=RowCount;
    if (OldValue=0)and(NewValue>=0) then begin
      FTopLeft.X:=FFixedCols;
      if RowCount=0 then begin
        FFixedRows:=0;
        FTopLeft.Y:=0;
        AddDel(FRows, 1); FGCache.AccumHeight.Count:=1;
      end;
    end;
    SizeChanged(OldValue, OldCount);
  end else begin
    AddDel(FRows, NewValue);
    FGCache.AccumHeight.Count:=NewValue;
    OldCount:=ColCount;
    if (OldValue=0)and(NewValue>=0) then begin
      FTopleft.Y:=FFixedRows;
      if FCols.Count=0 then begin
        FFixedCols:=0;
        FTopLeft.X:=0;
        AddDel(FCols, 1); FGCache.AccumWidth.Count:=1;
      end;
    end;
    SizeChanged(OldCount, OldValue);
  end;
  FixSelection;
  VisualChange;
end;

procedure TCustomGrid.SetColCount(Valor: Integer);
var
  OldC: Integer;
begin
  if Valor=FCols.Count then Exit;
  if Valor<1 then
    Clear
  else begin
    OldC:=FCols.Count;
    CheckFixedCount(Valor, RowCount, FFixedCols, FFixedRows);
    CheckCount(Valor, RowCount);
    AdjustCount(True, OldC, Valor);
  end;
end;

procedure TCustomGrid.SetRowCount(Valor: Integer);
var
  OldR: Integer;
begin
  if Valor=FRows.Count then Exit;
  if Valor<1 then
    clear
  else begin
    OldR:=FRows.Count;
    CheckFixedCount(ColCount, Valor, FFixedCols, FFixedRows);
    CheckCount(ColCount, Valor);
    AdjustCount(False, OldR, Valor);
  end;
end;

procedure TCustomGrid.SetDefColWidth(Valor: Integer);
var
  i: Integer;
begin
  if Valor=fDefColwidth then Exit;
  FDefColWidth:=Valor;
  for i:=0 to ColCount-1 do FCols[i] := Pointer(-1);
  VisualChange;
end;

procedure TCustomGrid.SetDefRowHeight(Valor: Integer);
var
  i: Integer;
begin
  if Valor=fDefRowHeight then Exit;
  FDefRowheight:=Valor;
  for i:=0 to RowCount-1 do FRows[i] := Pointer(-1);
  VisualChange;
end;

procedure TCustomGrid.SetCol(Valor: Integer);
begin
  if Valor=FCol then Exit;
  MoveExtend(False, Valor, FRow);
end;

procedure TCustomGrid.SetRow(Valor: Integer);
begin
  if Valor=FRow then Exit;
  MoveExtend(False, FCol, Valor);
end;

procedure TCustomGrid.Sort(ColSorting: Boolean; index, IndxFrom, IndxTo: Integer);
  procedure QuickSort(L,R: Integer);
  var
    i,j: Integer;
    P{,Q}: Integer;
  begin
    repeat
      I:=L;
      J:=R;
      P:=(L+R)Div 2;
      repeat
        if ColSorting then begin
          while OnCompareCells(Self, index, P, index, i)>0 do I:=I+1;
          while OnCompareCells(Self, index, P, index, j)<0 do J:=J-1;
        end else begin
          while OnCompareCells(Self, P, index, i, index)>0 do I:=I+1;
          while OnCompareCells(Self, P, index, j, index)<0 do J:=J-1;
        end;
        if I<=J then begin
          ExchangeColRow(not ColSorting, i,j);
          I:=I+1;
          J:=j-1;
        end;
      until I>J;
      if L<J then QuickSort(L,J);
      L:=I;
    until I>=R;
  end;
begin
  BeginUpdate;
  QuickSort(IndxFrom, IndxTo);
  EndUpdate(True);
end;

procedure TCustomGrid.doTopleftChange(dimChg: Boolean);
begin
  TopLeftChanged;
  if dimchg then begin
    VisualChange;
  end else begin
    CacheVisibleGrid;
    Invalidate;
  end;
  //UpdateScrollBarPos(nil);
  updateScrollBarPos(ssBoth);
end;

procedure TCustomGrid.VisualChange;
var
  Tw,Th: Integer;
  Dh,DV: Integer;

  function CalcMaxTopLeft: TPoint;
  var
    i: Integer;
    W,H: Integer;
  begin
    Result:=Point(ColCount-1, RowCount-1);
    W:=0;
    for i:=ColCount-1 downto FFixedCols do begin
      W:=W+GetColWidths(i);
      if W<FGCache.ScrollWidth then Result.x:=i
      else         Break;
    end;
    H:=0;
    for i:=RowCount-1 downto FFixedRows do begin
      H:=H+GetRowHeights(i);
      if H<FGCache.ScrollHeight then Result.y:=i
      else         Break;
    end;
  end;
var
  //Mtl: TPoint;
  {$Ifdef TestSbars} vs,hs: Boolean; {$Endif}
  HsbVisible, VsbVisible: boolean;
  HsbRange, VsbRange: Integer;
begin
  // Calculate New Cached Values
  FGCache.GridWidth:=0;
  FGCache.FixedWidth:=0;
  For Tw:=0 To ColCount-1 do begin
    FGCache.AccumWidth[Tw]:=Pointer(FGCache.GridWidth);
    FGCache.GridWidth:=FGCache.GridWidth + GetColWidths(Tw);
    if Tw<FixedCols then FGCache.FixedWidth:=FGCache.GridWidth;
    {$IfDef dbgScroll}
    WriteLn('FGCache.AccumWidth[',Tw,']=',Integer(FGCache.AccumWidth[Tw]));
    {$Endif}
  end;
  FGCache.Gridheight:=0;
  FGCache.FixedHeight:=0;
  For Tw:=0 To RowCount-1 do begin
    FGCache.AccumHeight[Tw]:=Pointer(FGCache.Gridheight);
    FGCache.Gridheight:=FGCache.Gridheight+GetRowHeights(Tw);
    if Tw<FixedRows then FGCache.FixedHeight:=FGCache.GridHeight;
    {$IfDef dbgScroll}
    WriteLn('FGCache.AccumHeight[',Tw,']=',Integer(FGCache.AccumHeight[Tw]));
    {$Endif}
  end;

  if not(goSmoothScroll in Options) then begin
    FGCache.TLColOff:=0;
    FGCache.TLRowOff:=0;
  end;

  Dh:=FGSMHBar;
  DV:=FGSMVBar;
  TW:=FGCache.GridWidth;
  TH:=FGCache.GridHeight;
  FGCache.ClientWidth:= Width - Integer(BorderStyle);
  FGCache.ClientHeight := Height - Integer(BorderStyle);
  HsbRange:=Width - Dv;
  VsbRange:=Height - Dh;

  HsbVisible := (FScrollBars in [ssHorizontal, ssBoth]) or (FGCache.GridWidth > FGCache.ClientWidth);
  VsbVisible := (FScrollBars in [ssVertical, ssBoth]) or (FGCache.GridHeight > FGCache.ClientHeight);

  if ScrollBarAutomatic(ssHorizontal) then
    HsbVisible := HsbVisible or (VsbVisible and (TW>HsbRange));
  if ScrollBarAutomatic(ssVertical) then
    VsbVisible := VsbVisible or (HsbVisible and (TH>VsbRange));
  {

  HSbVisible:=
     ((FScrollbars in [ssHorizontal, ssBoth]) or
     (ScrollBarAutomatic(ssHorizontal)) and (VsbVisible And (TW>HsbRange)));

  VSbVisible:=
     ((FScrollbars in [ssVertical, ssBoth]) or
     (ScrollBarAutomatic(ssVertical)) and (Hsbvisible And (TH>VsbRange)));
  }
  if not HSBVisible then DH:=0;
  if not VSbVisible then DV:=0;
  Dec(FGCache.ClientWidth, DV);
  Dec(FGCache.ClientHeight, DH);
  
  {$Ifdef DbgScroll}
  WriteLn('Width=',Width,' Height=',height, ' GWidth=',TW,' GHeight=',TH,' HsbRange=',HsbRange, ' VsbRange=',VSbRange, ' Vbar=',VSbVisible, ' HSb=',HsbVisible);
  WriteLn('ClientWidth=', FGCAche.ClientWidth, ' ClientHeight=', FGCache.ClientHeight);
  {$endif}

  //FGCache.ClientWidth:= Width - DV;
  //FGCache.ClientHeight:=Height - DH;
  FGCache.ScrollWidth:=FGCache.ClientWidth-FGCache.FixedWidth;
  FGCache.ScrollHeight:=FGCache.ClientHeight-FGCache.FixedHeight;

  FGCache.MaxTopLeft:=CalcMaxTopLeft;
  {$Ifdef DbgScroll}
  DebugPoint('MaxTopLeft',FGCache.MaxTopLeft);
  {$Endif}
  FGCache.HScrDiv:=0;
  FGCache.VScrDiv:=0;

  with FGCache do
  if ScrollBarAutomatic(ssHorizontal) then begin

    if HSbVisible then begin
      HsbRange:=GridWidth + 2 - Integer(BorderStyle){+ dv};

      if not (goSmoothScroll in Options) then begin
        TW:= Integer(AccumWidth[MaxTopLeft.X])-(HsbRange-ClientWidth);
        HsbRange:=HsbRange + TW - FixedWidth + 1;
      end;

      if HsbRange>ClientWidth then
        HscrDiv := Double(ColCount-FixedCols-1)/(HsbRange-ClientWidth);
    end;
  end else
  if FScrollBars in [ssHorizontal, ssBoth] then HsbRange:=0;
  If HsbVisible then ScrollBarRange(SB_HORZ, {HsbVisible, }HsbRange );
  ScrollBarShow(SB_HORZ, HsbVisible);

  with FGCache do
  if ScrollBarAutomatic(ssVertical)  then begin
    if VSbVisible then begin
      VSbRange:= GridHeight + 2 - Integer(BorderStyle){ + dh};

      if not (goSmoothScroll in Options) then begin
        TH:= Integer(accumHeight[MaxTopLeft.Y])-(VsbRange-ClientHeight);
        VsbRange:=VsbRange + TH -FixedHeight + 1;
      end;

      if VSbRange>ClientHeight then
        VScrDiv:= Double(RowCount-FixedRows-1)/(VsbRange-ClientHeight);
    end;
  end else
  if FScrollBars in [ssVertical, ssBoth] then VsbRange:= 0;
  if VsbVisible then ScrollbarRange(SB_VERT, {VsbVisible, }VsbRange );
  ScrollBarShow(SB_VERT, VsbVisible);

  CacheVisibleGrid;
  Invalidate;
end;

procedure TCustomGrid.CreateParams(var Params: TCreateParams);
const
  ClassStylesOff = CS_VREDRAW or CS_HREDRAW;
begin
  inherited CreateParams(Params);
  with Params do begin
    WindowClass.Style := WindowClass.Style and DWORD(not ClassStylesOff);
    Style := Style or WS_VSCROLL or WS_HSCROLL or WS_CLIPCHILDREN;
  end;
end;

procedure TCustomGrid.ScrollBarRange(Which: Integer; aRange: Integer);
var
  ScrollInfo: TScrollInfo;
begin
  if HandleAllocated then begin
    {$Ifdef DbgScroll}
    WriteLn('ScrollbarRange: Which=',Which,' Range=',aRange);
    {$endif}
    ScrollInfo.cbSize := SizeOf(ScrollInfo);
    ScrollInfo.fMask := SIF_RANGE or SIF_PAGE or SIF_DISABLENOSCROLL;
    ScrollInfo.nMin := 0;
    ScrollInfo.nMax := ARange;

    if Which = SB_VERT then
      ScrollInfo.nPage := ClientHeight
    else
      ScrollInfo.nPage := ClientWidth;
    if ScrollInfo.nPage<1 then ScrollInfo.nPage:=1;

    SetScrollInfo(Handle, Which, ScrollInfo, True);
  end;
end;

procedure TCustomGrid.ScrollBarPosition(Which, Value: integer);
var
  ScrollInfo: TScrollInfo;
  Vis: Boolean;
begin
  if HandleAllocated then begin
    {$Ifdef DbgScroll}
    WriteLn('ScrollbarPosition: Which=',Which, ' Value= ',Value);
    {$endif}
    if Which = SB_VERT then Vis := FVSbVisible else
    if Which = SB_HORZ then Vis := FHSbVisible
    else vis := false;
    ScrollInfo.cbSize := SizeOf(ScrollInfo);
    ScrollInfo.fMask := SIF_POS;
    ScrollInfo.nPos:= Value;
    SetScrollInfo(Handle, Which, ScrollInfo, Vis);
  end;
end;
{
function TCustomGrid.ScrollBarIsVisible(Which: Integer): Boolean;
begin
  Result:=false;
  if HandleAllocated then begin
    Result:= getScrollbarVisible(handle, Which);
  end;
end;
}
procedure TCustomGrid.ScrollBarPage(Which: Integer; aPage: Integer);
var
  ScrollInfo: TScrollInfo;
begin
  if HandleAllocated then begin
    ScrollInfo.cbSize := SizeOf(ScrollInfo);
    ScrollInfo.fMask := SIF_PAGE;
    ScrollInfo.nPage:= aPage;
    SetScrollInfo(Handle, Which, ScrollInfo, True);
  end;
end;

procedure TCustomGrid.ScrollBarShow(Which: Integer; aValue: boolean);
begin
  if HandleAllocated then begin
    {$Ifdef DbgScroll}
    WriteLn('ScrollbarShow: Which=',Which, ' Avalue=',AValue);
    {$endif}
    ShowScrollBar(Handle,Which,aValue);
    if Which in [SB_BOTH, SB_VERT] then FVSbVisible := AValue else
    if Which in [SB_BOTH, SB_HORZ] then FHSbVisible := AValue;
  end;
end;

function TCustomGrid.ScrollBarAutomatic(Which: TScrollStyle): boolean;
begin
  result:=false;
  if (Which=ssVertical)or(Which=ssHorizontal) then begin
    if Which=ssVertical then Which:=ssAutoVertical
    else Which:=ssAutoHorizontal;
    Result:= FScrollBars in [Which, ssAutoBoth];
  end;
end;

{ Returns a reactagle corresponding to a fisical cell[aCol,aRow] }
function TCustomGrid.CellRect(ACol, ARow: Integer): TRect;
begin
  //Result:=ColRowToClientCellRect(aCol,aRow);
  ColRowToOffset(True, True, ACol, Result.Left, Result.Right);
  ColRowToOffSet(False,True, ARow, Result.Top, Result.Bottom);
end;

// The visible grid Depends on  TopLeft and ClientWidht,ClientHeight,
// Col/Row Count, So it Should be called inmediately after any change
// like that
function TCustomGrid.GetVisibleGrid: TRect;
var
  w: Integer;
  MaxRight: Integer;
  MaxBottom: Integer;
begin
  if (FTopLeft.X<0)or(FTopLeft.y<0) then begin
    Result:=Rect(-1,-1,-1,-1);
    Exit;
  end;
  // visible TopLeft Cell
  Result.TopLeft:=fTopLeft;
  Result.BottomRight:=Result.TopLeft;

  // Max visible coordinates
  MaxRight:= FGCache.ClientWidth;
  MaxBottom:=FGCache.ClientHeight;

  // Left Margin of next visible Column and Rightmost visible cell
  w:=GetColWidths(Result.Left) + FGCache.FixedWidth- FGCache.TLColOff;
  while (Result.Right<ColCount-1)and(W<MaxRight) do begin
    Inc(Result.Right);
    W:=W+GetColWidths(Result.Right);
  end;

  // Top Margin of next visible Row and Bottom most visible cell
  w:=GetRowheights(Result.Top) + FGCache.FixedHeight - FGCache.TLRowOff;
  while (Result.Bottom<RowCount-1)and(W<MaxBottom) do begin
    Inc(Result.Bottom);
    W:=W+GetRowHeights(Result.Bottom);
  end;
end;

{Calculate the TopLeft needed to show cell[aCol,aRow]}
function TCustomGrid.ScrollToCell(const aCol,aRow: Integer): Boolean;
var
  RNew: TRect;
  OldTopLeft:TPoint;
  Xinc,YInc: Integer;
begin

  OldTopLeft:=fTopLeft;
  
  while (fTopLeft.x>=0) and
        (fTopLeft.x<ColCount)and
        (fTopLeft.y>=0) and
        (fTopLeft.y<RowCount) do begin

    RNew:=CellRect(aCol,aRow);

    Xinc:=0;
    if Rnew.Left + FGCache.TLColOff < FGCache.FixedWidth then Xinc:=-1
    else if RNew.Right  + FGCache.TLColOff > FGCache.ClientWidth then XInc:=1;
    Yinc:=0;
    if RNew.Top  + FGCAche.TLRowOff < FGcache.FixedHeight then Yinc:=-1
    else if RNew.Bottom + FGCache.TLRowOff > FGCache.ClientHeight then YInc:=1;

    with FTopLeft do
    if ((XInc=0)and(YInc=0)) or
       ((X=aCol)and(y=aRow)) Or // Only Perfect fit !
       ((X+XInc>=ColCount)or(Y+Yinc>=RowCount)) Or // Last Posible
       ((X+XInc<0)Or(Y+Yinc<0)) // Least Posible
    then Break;
    Inc(FTopLeft.x, XInc);
    Inc(FTopLeft.y, YInc);
  end;
  
  Result:=not PointIgual(OldTopleft,FTopLeft);
  if result then doTopleftChange(False)
  else ResetOffset(True, True);
end;

{Returns a valid TopLeft from a proposed TopLeft[DCol,DRow] which are
 relative or absolute coordinates }
function TCustomGrid.ScrollGrid(Relative: Boolean; DCol, DRow: Integer): TPoint;
begin
  Result:=FTopLeft;
  if not Relative then begin
    DCol:=DCol-Result.x;
    DRow:=DRow-Result.y;
  end;

  if DCol+Result.x<FFixedCols then DCol:=Result.x-FFixedCols else
  if DCol+Result.x>ColCount-1 then DCol:=ColCount-1-Result.x;
  if DRow+Result.y<FFixedRows then DRow:=Result.y-FFixedRows else
  if DRow+Result.y>RowCount-1 then DRow:=RowCount-1-Result.y;

  Inc(Result.x, DCol);
  Inc(Result.y, DRow);
end;

procedure TCustomGrid.TopLeftChanged;
begin
  if Assigned(OnTopLeftChanged) and not (csDesigning in ComponentState) then
    OnTopLeftChanged(Self);
end;

procedure TCustomGrid.HeaderClick(IsColumn: Boolean; index: Integer);
begin
end;
procedure TCustomGrid.ColRowMoved(IsColumn: Boolean; FromIndex,ToIndex: Integer);
begin
end;
procedure TCustomGrid.ColRowExchanged(isColumn: Boolean; index, WithIndex: Integer);
begin
end;
procedure TCustomGrid.DrawFocusRect(aCol, aRow: Integer; ARect: TRect;
  aState: TGridDrawstate);
begin
end;
procedure TCustomGrid.AutoAdjustColumn(aCol: Integer);
begin
end;
procedure TCustomGrid.SizeChanged(OldColCount, OldRowCount: Integer);
begin
end;
procedure TCustomGrid.ColRowDeleted(IsColumn: Boolean; index: Integer);
begin
end;

procedure TCustomGrid.Paint;
begin
  Inherited Paint;
  if FUpdateCount=0 then begin
    //WriteLn('Paint: FGCache.ValidGrid=',FGCache.ValidGrid );
    //DebugRect('Paint.ClipRect=',Canvas.ClipRect);
    DrawEdges;
    DrawBackGround;
    if FGCache.ValidGrid then begin
      {
      DrawFixedCells;
      DrawInteriorCells;
      DrawFocused;
      }
      DrawByRows;
      DrawColRowMoving;
    end;
    DrawBorder;
  end;
end;

procedure TCustomGrid.PrepareCanvas(aCol, aRow: Integer; aState: TGridDrawState
  );
begin
  if DefaultDrawing then begin
    if gdSelected in aState then  Canvas.Brush.color:= SelectedColor else
    if gdFixed in aState then     Canvas.Brush.color:= FixedColor
    else                          Canvas.Brush.color:= Color;
    if gdSelected in aState then  Canvas.Font.Color := clWindow
    else                          Canvas.Font.Color := Self.Font.Color; //clWindowText;
  end else begin
    Canvas.Brush.Color := clWindow;
    Canvas.Font.Color := clWindowText;
  end;
end;

procedure TCustomGrid.ResetOffset(chkCol, ChkRow: Boolean);
begin
  with FGCache do begin
    if ChkCol then ChkCol:=TLColOff<>0;
    if ChkCol then TlColOff:=0;
    if ChkRow then ChkRow:=TLRowOff<>0;
    if ChkRow then TlRowOff:=0;
    if ChkRow or ChkCol then begin
      CacheVisibleGrid;
      Invalidate;
      if ChkCol then updateScrollBarPos(ssHorizontal);//UpdateScrollBarPos(HorzScrollBar);
      if ChkRow then updateScrollBarPos(ssVertical);//UpdateScrolLBarPos(VertScrollBar);
    end;
  end;
end;


function TCustomGrid.SelectCell(ACol, ARow: Integer): Boolean;
begin
  Result:=true;
  //Result:=MoveExtend(False, aCol, aRow);
end;

procedure TCustomGrid.DrawBackGround;
begin
  {
    The user can draw a something here :)

  Canvas.Brush.Color:=Color;
  Canvas.FillRect(Parent.ClientRect);
  }
end;

procedure TCustomGrid.DrawBorder;
var
  R: TRect;
begin
  if BorderStyle = bsSingle then begin
    R := Rect(0,0,Width,Height);
    with R, Canvas do begin
      Pen.Color := cl3DDKShadow;
      MoveTo(Right-1, 0);
      LineTo(0,0);
      LineTo(0,Bottom-1);
      LineTo(Right-1, Bottom-1);
      LineTo(Right-1, Top-1);
    end;
  end;
end;

(*
procedure TCustomGrid.DrawFixedCells;
var
  Gds: TGridDrawState;
  i,j: Integer;
begin
  Gds:=[gdFixed];
  // Draw fixed fixed Cells
  For i:=0 to FFixedCols-1 do
    For j:=0 to fFixedRows-1 do
      DrawCell(i,j, CellRect(i,j), gds);

  with FGCache.VisibleGrid do begin
    // Draw fixed column headers
    For i:=left to Right do
      For j:=0 to fFixedRows-1 do
        DrawCell(i,j, CellRect(i,j), gds);
    // Draw fixed row headers
    For i:=0 to FFixedCols-1 do
      For j:=Top to Bottom do
        DrawCell(i,j, CellRect(i,j), gds);
  end;
end;

procedure TCustomGrid.DrawInteriorCells;
var
  Gds: TGridDrawState;
  i,j: Integer;
begin
  with FGCache.VisibleGrid do begin
    For i:=Left to Right do
      For j:=Top to Bottom do begin
        Gds:=[];
        if (i=FCol)and(J=FRow) then Continue;
        if IsCellSelected(i,j) then Include(gds, gdSelected);
        DrawCell(i,j, CellRect(i,j), gds);
      end;
  end;
end;
*)
procedure TCustomGrid.DrawColRowMoving;
begin
  if (FGridState=gsColMoving)and(fMoveLast.x>=0) then begin
    Canvas.Pen.Width:=3;
    Canvas.Pen.Color:=clRed;
    Canvas.MoveTo(fMoveLast.y, 0);
    Canvas.Lineto(fMovelast.y, FGCache.MaxClientXY.Y);
    Canvas.Pen.Width:=1;
  end else
  if (FGridState=gsRowMoving)and(FMoveLast.y>=0) then begin
    Canvas.Pen.Width:=3;
    Canvas.Pen.Color:=clRed;
    Canvas.MoveTo(0, FMoveLast.X);
    Canvas.LineTo(FGCache.MaxClientXY.X, FMoveLast.X);
    Canvas.Pen.Width:=1;
  end;
end;

procedure TCustomGrid.DrawCell(aCol, aRow: Integer; aRect: TRect;
  aState: TGridDrawState);
begin
  PrepareCanvas(aCol, aRow, aState);
  Canvas.FillRect(aRect);
  DrawCellGrid(aCol,aRow,aRect,aState);
end;

procedure TCustomGrid.DrawByRows;
var
  i: Integer;
begin
  // Draw Rows
  with FGCache.VisibleGrid do
    For i:=Top To Bottom do DrawRow(i);
  // Draw Fixed Rows
  For i:=0 to FFixedRows-1 Do DrawRow(i);
end;

procedure TCustomGrid.DrawRow(aRow: Integer);
var
  Gds: TGridDrawState;
  i: Integer;
  Rs: Boolean;
  R: TRect;
begin

  // Upper and Lower bounds for this row
  ColRowToOffSet(False, True, aRow, R.Top, R.Bottom);

  // Draw columns in this row
  with FGCache.VisibleGrid do
    if ARow<FFixedRows then begin
      gds:=[gdFixed];
      For i:=Left to Right do begin
        ColRowToOffset(true, True, i, R.Left, R.Right);
        DrawCell(i,aRow, R,gds)
      end;
    end else begin
      Rs:=(goRowSelect in Options);
      For i:=Left To Right do begin
        Gds:=[];
        if (i=Fcol)and(FRow=ARow) then begin
          // Focused Cell
          Include(gds, gdFocused);
          // Check if need to be selected
          if (goDrawFocusSelected in Options) or
             (Rs and not(goRelaxedRowSelect in Options)) then Include(gds, gdSelected);
        end else
        if IsCellSelected(i, ARow) then Include(gds, gdSelected);
        ColRowToOffset(True, True, i, R.Left, R.Right);
        DrawCell(i,aRow, R, gds);
      end;
      // Draw the focus Rect
      if (ARow=FRow) and
         (IsCellVisible(FCol,ARow) or (Rs and (ARow>=Top) and (ARow<=Bottom)))
      then begin
        if EditorShouldEdit and (FEditor<>nil)and(FEditor.Visible) then begin
          //WriteLn('No Draw Focus Rect');
        end else begin
          ColRowToOffset(True, True, FCol, R.Left, R.Right);
          DrawFocusRect(FCol,FRow, R, [gdFocused]);
        end;
      end;
    end; // else begin

  // Draw Fixed Columns
  gds:=[gdFixed];
  For i:=0 to FFixedCols-1 do begin
    ColRowToOffset(True, True, i, R.Left, R.Right);
    DrawCell(i,aRow, R,gds);
  end;
end;

procedure TCustomGrid.DrawEdges;
var
  P:  TPoint;
  Cr: TRect;
begin
  P:=FGCache.MaxClientXY;
  Cr:=Bounds(0,0, FGCache.ClientWidth, FGCache.ClientHeight);
  if P.x<Cr.Right then begin
    Cr.Left:=P.x;
    Canvas.Brush.Color:=Color;
    Canvas.FillRect(cr);
    Cr.Left:=0;
    Cr.Right:=p.x;
  end;
  if P.y<Cr.Bottom then begin
    Cr.Top:=p.y;
    Canvas.Brush.Color:=Color;
    Canvas.FillRect(cr);
  end;
end;

procedure TCustomGrid.DrawFocused;
var
  R: TRect;
  gds: TGridDrawState;
begin
  gds:=[gdFocused];
  if IsCellVisible(FCol,FRow) then begin
    if goDrawFocusSelected in Options then Include(gds,gdSelected);
    if (goRowSelect in Options) and not (goRelaxedRowSelect in Options) then
      Include(gds, gdSelected);
    R:=CellRect(fCol,fRow);
    DrawCell(fCol,fRow,R, gds);
    DrawFocusRect(fCol,fRow, R, gds);
  end else
    if  ((goRowSelect in Options) and
        (Frow>=FGCache.VisibleGrid.Top) and
        (Frow<=FGCache.VisibleGrid.Bottom))
    then begin
      R:=CellRect(fCol,fRow);
      DrawFocusRect(fcol,fRow, R, gds);
    end;
end;

procedure DebugRect(S:string; R:TRect);
begin
  WriteLn(S, 'L=',R.Left, ' T=',R.Top, ' R=',R.Right,' B=',R.Bottom);
end;
procedure DebugPoint(S:string; P:TPoint);
begin
  WriteLn(S, 'X=',P.X,' Y=',P.Y);
end;

procedure TCustomGrid.DrawCellGrid(aCol,aRow: Integer; aRect: TRect; aState: TGridDrawState);
var
  dv,dh: Boolean;
begin
  // Draw Cell Grid or Maybe in the future Borders..
  with Canvas, aRect do begin
    if (gdFixed in aState) then begin
      Dv := goFixedVertLine in Options;
      Dh := goFixedHorzLine in Options;
      Pen.Style := psSolid;
      if Not FFlat Then begin
        Pen.Color := cl3DHilight;
        MoveTo(Right - 1, Top);
        LineTo(Left, Top);
        LineTo(Left, Bottom);
      end;
      Pen.Color := cl3DDKShadow;
    end else begin
      Dv := goVertLine in Options;
      Dh := goHorzLine in Options;
      Pen.Style := fGridLineStyle;
      Pen.Color := fGridLineColor;
    end;
    if Dh then begin
      MoveTo(Left, Bottom - 1);
      LineTo(Right, Bottom - 1);
    end;
    if Dv then begin
       MoveTo(Right - 1, Top);
       LineTo(Right - 1, Bottom);
    end;
  end;
end;

procedure TCustomGrid.MyTextRect(R: TRect; Offx, Offy: Integer; S: string;
  Clipping: boolean);
var
  Rorg: TRect;
  tmpRgn: HRGN;
begin
  if Clipping then begin
    //IntersectClipRect(Canvas.handle, R.Left,R.Top,R.Right,R.Bottom);

    GetClipBox(Canvas.Handle, @ROrg);
    //DebugRect('Ini Rect = ', ROrg);
    tmpRGN:=CreateRectRgn(R.Left, R.Top, R.Right, R.Bottom);
    SelectClipRgn(Canvas.Handle, tmpRGN);
    //GetClipBox(Canvas.Handle, @Rtmp);
    //DebugRect('Set Rect = ', Rtmp);
    DeleteObject(tmpRGN);
  end;

  //if Ts.Opaque then Canvas.FillRect(R);
  Canvas.TextOut(R.Left+Offx, R.Top+Offy,  S);

  if Clipping then begin
    tmpRGN:=CreateRectRgn(Rorg.Left, Rorg.Top, Rorg.Right, Rorg.Bottom);
    SelectClipRgn(Canvas.Handle, tmpRGN);
    //GetClipBox(Canvas.Handle, @Rtmp);
    //DebugRect('end Rect = ', Rtmp);
    DeleteObject(tmpRGN);
  end;
end;

procedure TCustomGrid.ReadColWidths(Reader: TReader);
var
  i: integer;
begin
  with Reader do begin
    ReadListBegin;
    for i:=0 to ColCount-1 do
      ColWidths[I] := ReadInteger;
    ReadListEnd;
  end;
end;

procedure TCustomGrid.ReadRowHeights(Reader: TReader);
var
  i: integer;
begin
  with Reader do begin
    ReadListBegin;
    for i:=0 to RowCount-1 do
      RowHeights[I] := ReadInteger;
    ReadListEnd;
  end;
end;

procedure TCustomGrid.WMEraseBkgnd(var message: TLMEraseBkgnd);
begin
  message.Result:=1;
  //WriteLn('TCustomGrid.WMEraseBkgnd');
end;

procedure TCustomGrid.WMGetDlgCode(var Msg: TLMNoParams);
begin
	Msg.Result := DLGC_WANTARROWS or DLGC_WANTCHARS or DLGC_WANTALLKEYS;
	if goTabs in Options then Msg.Result:= Msg.Result or DLGC_WANTTAB;
end;

//
// NOTE: WMHScroll and VMHScroll
// This methods are used to pre-calculate the scroll position
//
procedure TCustomGrid.WMHScroll(var message: TLMHScroll);
var
  C,TL,CTL: Integer;
begin

  // Avoid invalidating right know, just let the scrollbar
  // calculate its position
  {
  BeginUpdate;
  Inherited;
  message.Result:=1;
  EndUpdate(uoNone);
  }

  {$IfDef dbgScroll}
  WriteLn('HSCROLL: Code=',message.ScrollCode,' Position=', message.Pos);
  {$Endif}


  if FGCache.HScrDiv<=0 then Exit;
  if FEditor<>nil then
    EditorGetValue;

  if goThumbTracking in Options then begin
    C:=FFixedCols + Round( message.Pos * FGCache.HScrDiv );
    if (FCol<>C) then begin
      Inc(FUpdateScrollBarsCount);
      MoveExtend(False, C, FRow);
      Dec(FUpdateScrollBarsCount);
    end;
  end else begin

    TL:=  Integer(FGCache.AccumWidth[ FGCache.MaxTopLeft.X ]);
    CTL:= Integer(FGCache.AccumWidth[ FtopLeft.X ]);

    case message.ScrollCode of
        // Scrolls to start / end of the text
      SB_TOP:        C := 0;
      SB_BOTTOM:     C := TL;
        // Scrolls one line up / down
      SB_LINEDOWN:   C := CTL + FDefColWidth;
      SB_LINEUP:     C := CTL - FDefColWidth;
        // Scrolls one page of lines up / down
      SB_PAGEDOWN:   C := CTL + FGCache.ClientWidth;
      SB_PAGEUP:     C := CTL - FGCache.ClientWidth;
        // Scrolls to the current scroll bar position
      SB_THUMBPOSITION,
      SB_THUMBTRACK: C := message.Pos;
        // Ends scrolling
      SB_ENDSCROLL: Exit;
    end;

    {$Ifdef dbgScroll}
    WriteLn('---- Position=',C, ' FixedWidth=',FGCache.FixedWidth);
    {$Endif}
    ScrollBarPosition(SB_HORZ, C);
    C:= C + FGCache.FixedWidth + Integer(BorderStyle);
    {$Ifdef dbgScroll}
    WriteLn('---- Position=',C, ' FixedWidth=',FGCache.FixedWidth);
    {$Endif}
    TL:=OffsetToColRow(True, False, C, FGCache.TLColOff);
    {$Ifdef dbgScroll}
    WriteLn('---- Offset=',C, ' TL=',TL,' TLColOFf=', FGCache.TLColOff);
    {$Endif}
    if not (goSmoothScroll in Options) then FGCache.TLColOff:=0;

    if TL<>FTopLeft.X then begin
      Inc(FUpdateScrollBarsCount);
      TryScrollTo(Tl, FTopLeft.Y);
      Dec(FUpdateScrollBarsCount);
    end else
    if goSmoothScroll in Options then begin
      CacheVisibleGrid;
      {
      R.Topleft:=Point(FGCache.FixedWidth, 0);
      R.BottomRight:= FGCache.MaxClientXY;
      InvalidateRect(Handle, @R, false);
      }
      Invalidate;
    end;
  end;
end;

procedure TCustomGrid.WMVScroll(var message: TLMVScroll);
var
  C, TL, CTL: Integer;
begin
  // Avoid invalidating right know, just let the scrollbar
  // calculate its position
  {
  BeginUpdate;
  Inherited;
  message.Result:=1;
  EndUpdate(uoNone);
  }
  {$IfDef dbgScroll}
  WriteLn('VSCROLL: Code=',message.ScrollCode,' Position=', message.Pos);
  {$Endif}

  if FGCache.VScrDiv<=0 then Exit;
  if FEditor<>nil then EditorGetValue;
  if goThumbTracking in Options then begin
    C:=FFixedRows + Round( message.Pos * FGCache.VScrDiv );
    if (C<>FRow) then begin
      Inc(FUpdateScrollBarsCount);
      MoveExtend(False, FCol, C);
      Dec(FUpdateScrollBarsCount);
    end;
  end else begin

    TL:=  Integer(FGCache.AccumHeight[ FGCache.MaxTopLeft.Y ]);
    CTL:= Integer(FGCache.AccumHeight[ FtopLeft.Y ]);

    case message.ScrollCode of
        // Scrolls to start / end of the text
      SB_TOP:        C := 0;
      SB_BOTTOM:     C := TL;
        // Scrolls one line up / down
      SB_LINEDOWN:   C := CTL + FDefRowHeight;
      SB_LINEUP:     C := CTL - FDefRowHeight;
        // Scrolls one page of lines up / down
      SB_PAGEDOWN:   C := CTL + FGCache.ClientHeight;
      SB_PAGEUP:     C := CTL - FGCache.ClientHeight;
        // Scrolls to the current scroll bar position
      SB_THUMBPOSITION,
      SB_THUMBTRACK: C := message.Pos;
        // Ends scrolling
      SB_ENDSCROLL: Exit;
    end;

    {$Ifdef dbgScroll}
    WriteLn('---- Position=',C, ' FixedHeight=',FGCache.FixedHeight);
    {$Endif}
    ScrollBarPosition(SB_VERT, C);
    C:= C + FGCache.FixedHeight + Integer(BorderStyle);
    {$Ifdef dbgScroll}
    WriteLn('---- NewPosition=',C);
    {$Endif}
    TL:=OffsetToColRow(False, False, C, FGCache.TLRowOff);
    {$Ifdef dbgScroll}
    WriteLn('---- Offset=',C, ' TL=',TL, ' TLRowOFf=', FGCache.TLRowOff);
    {$Endif}
    if not (goSmoothScroll in Options) then FGCache.TLRowOff:=0;

    if TL<>FTopLeft.Y then begin
      Inc(FUpdateScrollBarsCount);
      TryScrollTo(FTopLeft.X, Tl);
      Dec(FUpdateScrollBarsCount);
    end else
    if goSmoothScroll in Options then begin
      CacheVisibleGrid;
      {
      R.TopLeft:=Point(0, FGCache.FixedHeight);
      R.BottomRight:=FGCache.MaxClientXY;
      InvalidateRect(Handle, @R, false);
      }
      Invalidate;
    end;
  end;
end;

procedure TCustomGrid.WMSize(var Msg: TLMSize);
begin
  Inherited;
  visualChange;
end;

procedure TCustomGrid.WMChar(var message: TLMChar);
var
  Ch: Char;
begin
  Ch:=Char(message.CharCode);
  //WriteLn(ClassName,'.WMchar CharCode= ',message.CharCode);
  if (goEditing in Options) and (Ch in [^H, #32..#255]) then
    EditorShowChar(Ch)
  else
    inherited;
end;


procedure TCustomGrid.WndProc(var TheMessage: TLMessage);
begin
	{$IfDef GridTraceMsg}
	TransMsg('GRID: ', TheMessage);
	{$Endif}
 
  with TheMessage do
  if (csDesigning in ComponentState) and
     ((Msg = LM_HSCROLL)or(Msg = LM_VSCROLL))
  then
          Exit;

  inherited WndProc(TheMessage);
end;

procedure TCustomGrid.CreateWnd;
begin
  inherited CreateWnd;
  VisualChange;
end;

{ Scroll grid to the given Topleft[aCol,aRow] as needed }
procedure TCustomGrid.TryScrollTo(aCol, aRow: Integer);
var
  TryTL: TPoint;
begin
  TryTL:=ScrollGrid(False,aCol, aRow);
  if not PointIgual(TryTL, FTopLeft) then begin
    FTopLeft:=TryTL;
    doTopleftChange(False);
  end;
end;

procedure TCustomGrid.SetGridLineWidth(const AValue: Integer);
begin
  // Todo
  if FGridLineWidth=AValue then exit;
  FGridLineWidth:=AValue;
  Invalidate;
end;

{ Reposition the scrollbars according to the current TopLeft }
procedure TCustomGrid.UpdateScrollbarPos(Which: TScrollStyle);
begin
  // Adjust ScrollBar Positions
  // Special condition only When scrolling by draging
  // the scrollbars see: WMHScroll and WVHScroll
  if FUpdateScrollBarsCount=0 then begin
    if Which in [ssHorizontal, ssBoth] then begin
      if ScrollBarAutomatic(ssHorizontal) Then begin
          with FGCache do
            ScrollBarPosition(SB_HORZ,
              Integer(AccumWidth[FTopLeft.x])-TLColOff-FixedWidth );
      end;
    end;

    if Which in [ssVertical, ssBoth] then begin
      if ScrollBarAutomatic(ssVertical) then begin
          with FGCache do
            ScrollBarPosition(SB_VERT,
              Integer(AccumHeight[FTopLeft.y])-TLRowOff-FixedHeight);
      end;
    end;
  end; {if FUpd...}
end;

procedure TCustomGrid.UpdateSelectionRange;
begin
  if goRowSelect in Options then begin
    FRange:=Rect(FFixedCols, FRow, ColCount-1, FRow);
  end
  else
    FRange:=Rect(FCol,FRow,FCol,FRow);
end;

procedure TCustomGrid.WriteColWidths(Writer: TWriter);
var
  i: Integer;
begin
  with writer do begin
    WriteListBegin;
    for i:=0 to ColCount-1 do
      WriteInteger(ColWidths[i]);
    WriteListEnd;
  end;
end;

procedure TCustomGrid.WriteRowHeights(Writer: TWriter);
var
  i: integer;
begin
  with writer do begin
    WriteListBegin;
    for i:=0 to RowCount-1 do
      WriteInteger(RowHeights[i]);
    WriteListEnd;
  end;
end;

procedure TCustomGrid.CheckFixedCount(aCol,aRow,aFCol,aFRow: Integer);
begin
  if AFRow<0 then
    Raise EGridException.Create('FixedRows<0');
  if AFCol<0 then
    Raise EGridException.Create('FixedCols<0');

  if (aCol=0)And(aFCol=0) then // invalid grid, ok
  else if (aFCol>=aCol) and not (csLoading in componentState) then
    raise EGridException.Create(rsFixedColsTooBig);
  if (aRow=0)and(aFRow=0) then // Invalid grid, ok
  else if (aFRow>=aRow) and not (csLoading in ComponentState) then
    raise EGridException.Create(rsFixedRowsTooBig);
end;

procedure TCustomGrid.CheckCount(aNewColCount, aNewRowCount: Integer);
var
  NewCol,NewRow: Integer;
begin
  if HandleAllocated then begin
    if Col >= aNewColCount then NewCol := aNewColCount-1
    else                        NewCol := Col;
    if Row >= aNewRowCount then NewRow := aNewRowCount-1
    else                        NewRow := Row;
    if (NewCol>=0) and (NewRow>=0) and ((NewCol <> Col) or (NewRow <> Row)) then
    begin
      CheckTopleft(NewCol, NewRow , NewCol<>Col, NewRow<>Row);
      MoveNextSelectable(false, NewCol, NewRow);
    end;
  end;
end;

function TCustomGrid.CheckTopLeft(aCol,aRow: Integer; CheckCols, CheckRows: boolean): boolean;
var
  OldTopLeft: TPoint;
  W: Integer;
begin
  OldTopLeft := FTopLeft;
  Result:= False;
  
  with FTopleft do
  if CheckCols and (X>FixedCols) then begin
    W := FGCache.ScrollWidth-ColWidths[aCol]-Integer(FGCache.AccumWidth[aCol]);
    while (x>FixedCols)and(W+Integer(FGCache.AccumWidth[x])>=ColWidths[x-1]) do
    begin
      Dec(x);
    end;
  end;

  with FTopleft do
  if CheckRows and (Y > FixedRows) then begin
    W := FGCache.ScrollHeight-RowHeights[aRow]-Integer(FGCache.AccumHeight[aRow]);
    while (y>FixedRows)and(W+Integer(FGCache.AccumHeight[y])>=RowHeights[y-1]) do
    begin
      Dec(y);
    end;
  end;

  Result := Not PointIgual(OldTopleft,FTopLeft);
  if Result then
    doTopleftChange(False)
end;

procedure TCustomGrid.SetFlat(const AValue: Boolean);
begin
  if FFlat=AValue then exit;
  FFlat:=AValue;
  Invalidate;
end;

procedure TCustomGrid.SetBorderStyle(const AValue: TBorderStyle);
begin
  if FBorderStyle<>AValue Then begin
    FBorderStyle := AValue;
    VisualChange;
    if CheckTopLeft(Col, Row, True, True) then
      VisualChange;
  end;
end;

{ Save to the cache the current visible grid (excluding fixed cells) }
procedure TCustomGrid.CacheVisibleGrid;
var
  R: TRect;
begin
  with FGCache do begin
    VisibleGrid:=GetVisibleGrid;
    with VisibleGrid do
      ValidGrid:=(Left>=0)and(Top>=0)and(Right>=Left)and(Bottom>=Top);
    if not ValidGrid then MaxClientXY:=Point(0,0)
    else begin
      R:=CellRect(VisibleGrid.Right, VisibleGrid.Bottom);
      MaxClientXY:=R.BottomRight;
    end;
  end;
end;

function TCustomGrid.GetSelection: TGridRect;
begin
  Result:=FRange;
end;

procedure TCustomGrid.SetDefaultDrawing(const AValue: Boolean);
begin
  if FDefaultDrawing=AValue then exit;
  FDefaultDrawing:=AValue;
  Invalidate;
end;

procedure TCustomGrid.SetFocusColor(const AValue: TColor);
begin
  if FFocusColor=AValue then exit;
  FFocusColor:=AValue;
  InvalidateCell(FCol,FRow);
end;

procedure TCustomGrid.SetGridLineStyle(const AValue: TPenStyle);
begin
  if FGridLineStyle=AValue then exit;
  FGridLineStyle:=AValue;
  Invalidate;
end;

procedure TCustomGrid.SetSelectActive(const AValue: Boolean);
begin
  if FSelectActive=AValue then exit;
  FSelectActive:=AValue and not(goEditing in Options);
  if FSelectActive then FPivot:=Point(FCol,FRow);
end;

procedure TCustomGrid.SetSelection(const AValue: TGridRect);
begin
  if goRangeSelect in Options then begin
    fRange:=NormalizarRect(aValue);
    Invalidate;
  end;
end;

function TCustomGrid.doColSizing(X, Y: Integer): Boolean;
var
  R: TRect;
  Loc: Integer;
begin
  Result:=False;
  if gsColSizing = fGridState then begin
    if x>FSplitter.y then
      ColWidths[FSplitter.x]:=x-FSplitter.y
    else
      if ColWidths[FSplitter.x]>0 then ColWidths[FSplitter.X]:=0;
    Result:=True;
  end else
  if (fGridState=gsNormal)and(Y<FGCache.FixedHeight)and(X>FGCache.FixedWidth) then
  begin
    FSplitter.X:= OffsetToColRow(True, True, X, Loc);
    FSplitter.Y:=0;
    if FSplitter.X>=0 then begin
      R:=CellRect(FSplitter.x, FSplitter.y);
      FSplitter.y:=X;                       // Resizing X reference
      if (R.Right-X)<(X-R.Left) then Loc:=R.Right
      else begin
        Loc:=R.Left;
        Dec(FSplitter.x);                   // Resizing col is the previous
      end;
      IF (Abs(Loc-x)<=2)and(FSplitter.X>=FFixedCols) then Cursor:=crHSplit
      else                                                Cursor:=crDefault;
      Result:=True;
    end;
  end
    else
      if (cursor=crHSplit) then Cursor:=crDefault;
end;

function TCustomGrid.doRowSizing(X, Y: Integer): Boolean;
var
  OffTop,OffBottom: Integer;
begin
  Result:=False;
  if gsRowSizing = fGridState then begin
    if y>FSplitter.x then
      RowHeights[FSplitter.y]:=y-FSplitter.x
    else
      if RowHeights[FSplitter.y]>0 then RowHeights[FSplitter.Y]:=0;
    Result:=True;
  end else
  if (fGridState=gsNormal)and(X<FGCache.FixedWidth)and(Y>FGCache.FixedHeight) then
  begin
    fSplitter.Y:=OffsetToColRow(False, True, Y, OffTop{dummy});
    if Fsplitter.Y>=0 then begin
      ColRowToOffset(False, True, FSplitter.Y, OffTop, OffBottom);
      FSplitter.X:=Y;
      if (OffBottom-Y)<(Y-OffTop) then SwapInt(OffTop, OffBottom)
      else Dec(FSplitter.y);
      IF (Abs(OffTop-y)<=2)and(FSplitter.Y>=FFixedRows) then Cursor:=crVSplit
      else                                                   Cursor:=crDefault;
      Result:=True;
    end;
  end
    else
      if Cursor=crVSplit then Cursor:=crDefault;
end;

procedure TCustomGrid.doColMoving(X, Y: Integer);
var
  P: TPoint;
  R: TRect;
begin
  P:=MouseToCell(Point(X,Y));
  if (Abs(FSplitter.Y-X)>fDragDx)and(Cursor<>crMultiDrag) then begin
    Cursor:=crMultiDrag;
    FMoveLast:=Point(-1,-1);
    ResetOffset(True, False);
  end;
  if (Cursor=crMultiDrag)and
     (P.x>=FFixedCols) and
     ((P.X<=FSplitter.X)or(P.X>FSplitter.X))and
     (P.X<>FMoveLast.X) then begin
      R:=CellRect(P.x, P.y);
      if P.x<=FSplitter.X then fMoveLast.Y:=R.left
      else                     FMoveLast.Y:=R.Right;
      fMoveLast.X:=P.X;
      Invalidate;
  end;
end;

procedure TCustomGrid.doRowMoving(X, Y: Integer);
var
  P: TPoint;
  R: TRect;
begin
  P:=MouseToCell(Point(X,Y));
  if (Cursor<>crMultiDrag)and(Abs(FSplitter.X-Y)>fDragDx) then begin
    Cursor:=crMultiDrag;
    FMoveLast:=Point(-1,-1);
    ResetOffset(False, True);
  end;
  if (Cursor=crMultiDrag)and
     (P.y>=FFixedRows) and
     ((P.y<=FSplitter.Y)or(P.Y>FSplitter.Y))and
     (P.y<>FMoveLast.Y) then begin
      R:=CellRect(P.x, P.y);
      if P.y<=FSplitter.y then fMoveLast.X:=R.Top
      else                     FMoveLast.X:=R.Bottom;
      fMoveLast.Y:=P.Y;
      Invalidate;
  end;
end;


function TCustomGrid.OffsetToColRow(IsCol, Fisical: Boolean; Offset: Integer;
  var Rest: Integer): Integer;
begin
  Result:=0; //Result:=-1;
  Rest:=0;
  Offset := Offset - Integer(BorderStyle);
  if Offset<0 then Exit; // Out of Range;

  with FGCache do
  if IsCol then begin

    // begin to count Cols from 0 but ...
    if Fisical and (Offset>FixedWidth-1) then begin
      Result:=FTopLeft.X;  // In scrolled view, then begin from FtopLeft col
      Offset:=Offset-FixedWidth+Integer(AccumWidth[Result])+TLColOff;
      if Offset>GridWidth-1 then begin
        Result:=ColCount-1;
        Exit;
      end;
    end;
    while Offset>(Integer(AccumWidth[Result])+GetColWidths(Result)-1) do Inc(Result);

    Rest:=Offset;
    if Result<>0 then Rest:=Offset-Integer(AccumWidth[Result]);

  end else begin

    if Fisical and (Offset>FixedHeight-1) then begin
      Result:=FTopLeft.Y;
      Offset:=Offset-FixedHeight+Integer(AccumHeight[Result])+TLRowOff;
      if Offset>GridHeight-1 then begin
        Result:=RowCount-1;
        Exit; // Out of Range
      end;
    end;
    while Offset>(Integer(AccumHeight[Result])+GetRowHeights(Result)-1) do Inc(Result);
    Rest:=Offset;
    if Result<>0 then Rest:=Offset-Integer(AccumHeight[Result]);

  end;
end;

// ex: IsCol=true, Index:=100, TopLeft.x:=98, FixedCols:=1, all ColWidths:=20
// Fisical = Relative => Ini := WidthfixedCols+WidthCol98+WidthCol99
// Not Fisical = Absolute => Ini := WidthCols(0..99)
function TCustomGrid.ColRowToOffset(IsCol,Fisical:Boolean; index:Integer; var Ini,Fin:Integer): Boolean;
var
  Dim: Integer;
begin
  with FGCache do begin
    if IsCol then begin
      Ini:=Integer(AccumWidth[index]);
      Dim:=GetColWidths(index);
    end else begin
      Ini:=Integer(AccumHeight[index]);
      Dim:= GetRowHeights(index);
    end;
    Ini := Ini + Integer(BorderStyle);
    if not Fisical then begin
      Fin:=Ini + Dim;
      Exit;
    end;
    if IsCol then begin
      if index>=FFixedCols then
        Ini:=Ini-Integer(AccumWidth[FTopLeft.X]) + FixedWidth -  TLColOff;
    end else begin
      if index>=FFixedRows then
        Ini:=Ini-Integer(AccumHeight[FTopLeft.Y]) + FixedHeight - TLRowOff;
    end;
    Fin:=Ini + Dim;
  end;
  Result:=true;
end;

function TCustomGrid.MouseToGridZone(X, Y: Integer; CellCoords: Boolean): TGridZone;
begin
  Result:=gzNormal;
  if CellCoords then begin
    if (X<fFixedCols) then
      if Y<FFixedRows then  Result:= gzFixedCells
      else                  Result:= gzFixedRows
    else
    if (Y<fFixedRows) then
      if X<FFixedCols then  Result:= gzFixedCells
      else                  Result:= gzFixedCols;
  end else begin
    if X<=FGCache.FixedWidth then
      if Y<=FGcache.FixedHeight then  Result:=gzFixedCells
      else                            Result:=gzFixedRows
    else
    if Y<=FGCache.FixedHeight then
      if X<=FGCache.FixedWidth then   Result:=gzFixedCells
      else                            Result:=gzFixedCols;
  end;
end;

procedure TCustomGrid.ExchangeColRow(IsColumn: Boolean; index, WithIndex: Integer
  );
begin
  if IsColumn then FCols.Exchange(index, WithIndex)
  else             FRows.Exchange(index, WithIndex);
  ColRowExchanged(IsColumn, index, WithIndex);
  VisualChange;
end;

procedure TCustomGrid.MoveColRow(IsColumn: Boolean; FromIndex, ToIndex: Integer);
begin
  if IsColumn then FCols.Move(FromIndex, ToIndex)
  else             FRows.Move(FromIndex, ToIndex);
  ColRowMoved(IsColumn, FromIndex, ToIndex);
  VisualChange;
end;

procedure TCustomGrid.SortColRow(IsColumn: Boolean; index: Integer);
begin
  if IsColumn then SortColRow(IsColumn, index, FFixedRows, RowCount-1)
  else             SortColRow(IsColumn, index, FFixedCols, ColCount-1);
end;

procedure TCustomGrid.SortColRow(IsColumn: Boolean; index, FromIndex,
  ToIndex: Integer);
begin
  if Assigned(OnCompareCells) then begin
    BeginUpdate;
    Sort(IsColumn, index, FromIndex, ToIndex);
    EndUpdate(true);
  end;
end;

procedure TCustomGrid.DeleteColRow(IsColumn: Boolean; index: Integer);
begin
  if IsColumn then FCols.Delete(index)
  else             FRows.Delete(index);
  ColRowDeleted(IsColumn, index);
  VisualChange;
end;



procedure TCustomGrid.MouseDown(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
var
  Gz: TGridZone;
  R: TRect;
begin
  inherited MouseDown(Button, Shift, X, Y);

  if not FGCache.ValidGrid then Exit;
  if not (ssLeft in Shift) then Exit;
  if csDesigning in componentState then Exit;

  {$IfDef dbgFocus} WriteLn('MouseDown INIT'); {$Endif}

  Gz:=MouseToGridZone(X,Y, False);
  case Gz of
    gzFixedCols:
      begin
        if (goColSizing in Options)and(Cursor=crHSplit) then begin
          R:=CellRect(FSplitter.x, FTopLeft.y);
          FSplitter.y:=R.Left;
          fGridState:= gsColSizing;
        end else begin
          // ColMoving or Clicking
          fGridState:=gsColMoving;
          FSplitter:=MouseToCell(Point(X,Y));
          FMoveLast:=Point(-1,-1);
          FSplitter.Y:=X;
        end;
      end;
    gzFixedRows:
      if (goRowSizing in Options)and(Cursor=crVSplit) then begin
        R:=CellRect(FTopLeft.X, FSplitter.y);
        FSplitter.x:=R.top;
        fGridState:= gsRowSizing;
      end else begin
        // RowMoving or Clicking
        fGridState:=gsRowMoving;
        fSplitter:=MouseToCell(Point(X,Y));
        FMoveLast:=Point(-1,-1);
        FSplitter.X:=Y;
      end;
    gzNormal:
      if Not (csDesigning in componentState) then begin
        fGridState:=gsSelecting;
        FSplitter:=MouseToCell(Point(X,Y));
        if Not Focused then setFocus;

        if not (goEditing in Options) then begin
          if ssShift in Shift then begin
            SelectActive:=(goRangeSelect in Options);
          end else begin
            if not SelectACtive then begin
              FPivot:=FSplitter;
              FSelectActive:=true;
            end;
          end;
        end;

        if not MoveExtend(False, FSplitter.X, FSplitter.Y) then begin
          if EditorShouldEdit then begin
            SelectEditor;
            EditorShow;
          end;
          // user clicked on selected cell
          // -> fire an OnSelection event
          MoveSelection;
          // Click();
        end;
        (*
        if (GoEditing in Options)and(FEditor=nil) and not Focused then begin
          {$IfDef dbgFocus} WriteLn('  AUTO-FOCUSING '); {$Endif}
          LCLIntf.SetFocus(Self.Handle);
        end;
        *)
      end;
  end;
  {$ifDef dbgFocus} WriteLn('MouseDown END'); {$Endif}
end;

procedure TCustomGrid.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  p: TPoint;
begin
  inherited MouseMove(Shift, X, Y);
  if not FGCache.ValidGrid then Exit;

  case fGridState of
    gsSelecting:
      begin
        if not (goEditing in Options) then begin
          P:=MouseToLogcell(Point(X,Y));
          MoveExtend(False, P.x, P.y);
        end;
      end;
    gsColMoving: if goColMoving in Options then doColMoving(X,Y);
    gsRowMoving: if goRowMoving in Options then doRowMoving(X,Y);
    else
      begin
        if goColSizing in Options then doColSizing(X,Y);
        if goRowSizing in Options then doRowSizing(X,Y);
      end;
  end;
end;

procedure TCustomGrid.MouseUp(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
var
   Cur: TPoint;
begin
  inherited MouseUp(Button, Shift, X, Y);
  if not FGCache.ValidGrid then Exit;
  {$IfDef dbgFocus}WriteLn('MouseUP INIT');{$Endif}
  Cur:=MouseToCell(Point(x,y));
  case fGridState of
    gsSelecting:
      begin
        if SelectActive then begin
          MoveExtend(False, Cur.x, Cur.y);
          SelectActive:=False;
        end;
      end;
    gsColMoving:
      begin
        //WriteLn('Move Col From ',Fsplitter.x,' to ', FMoveLast.x);
        if FMoveLast.X>=0 then begin
          MoveColRow(True, Fsplitter.X, FMoveLast.X);
          Cursor:=crDefault;
        end else
          if Cur.X=FSplitter.X then HeaderClick(True, FSplitter.X);
      end;
    gsRowMoving:
      begin
        //WriteLn('Move Row From ',Fsplitter.Y,' to ', FMoveLast.Y);
        if FMoveLast.Y>=0 then begin
          MoveColRow(False, Fsplitter.Y, FMoveLast.Y);
          Cursor:=crDefault;
        end else
          if Cur.Y=FSplitter.Y then HeaderClick(False, FSplitter.Y);
      end;
  end;
  fGridState:=gsNormal;
  {$IfDef dbgFocus}WriteLn('MouseUP  END  RND=',Random);{$Endif}
end;

procedure TCustomGrid.DblClick;
begin
  if (goColSizing in Options) and (Cursor=crHSplit) then begin
    if (goDblClickAutoSize in Options) then begin
      AutoAdjustColumn( FSplitter.X );
    end {else
      WriteLn('Got Doubleclick on Col Resizing: AutoAdjust?');}
  end else
  if  (goDblClickAutoSize in Options) and
      (goRowSizing in Options) and
      (Cursor=crVSplit) then begin
      {
        WriteLn('Got DoubleClick on Row Resizing: AutoAdjust?');
      }
  end
  else
    Inherited DblClick;
end;

procedure TCustomGrid.DefineProperties(Filer: TFiler);
  function SonIguales(L1,L2: TList): boolean;
  var
    i: Integer;
  begin
    Result:=False; // store by default
    for i:=0 to L1.Count-1 do begin
      Result:=L1[i]=L2[i];
      if Not Result then break;
    end;
  end;
  function NeedWidths: boolean;
  begin
    if Filer.Ancestor <> nil then
      Result := not SonIguales(TCustomGrid(Filer.Ancestor).FCols, FCols)
    else
      Result := True;
  end;
  function NeedHeights: boolean;
  begin
    if Filer.Ancestor <> nil then
      Result := not SonIguales(TCustomGrid(Filer.Ancestor).FRows, FRows)
    else
      Result := True;
  end;
begin
  inherited DefineProperties(Filer);
  with Filer do begin
    DefineProperty('ColWidths',  @ReadColWidths,  @WriteColWidths,  NeedWidths);
    DefineProperty('RowHeights', @ReadRowHeights, @WriteRowHeights, NeedHeights);
  end;
end;

procedure TCustomGrid.DestroyHandle;
begin
  editorGetValue;
  inherited DestroyHandle;
end;

procedure TCustomGrid.doExit;
begin
  if FEditorShowing then begin
    {$IfDef dbgFocus}WriteLn('DoExit - EditorShowing');{$Endif}
  end else begin
    {$IfDef dbgFocus}WriteLn('DoExit - Ext');{$Endif}
    Invalidate;
  end;
  inherited doExit;
end;

procedure TCustomGrid.doEnter;
begin
  inherited doEnter;
  if FEditorHiding then begin
    {$IfDef dbgFocus}WriteLn('DoEnter - EditorHiding');{$Endif}
  end else begin
    {$IfDef dbgFocus}WriteLn('DoEnter - Ext');{$Endif}
    if EditorShouldEdit then begin
      SelectEditor;
      if Feditor=nil then Invalidate
      else                EditorShow;
    end else Invalidate;
  end;
end;

procedure TCustomGrid.KeyDown(var Key: Word; Shift: TShiftState);
var
  Sh: Boolean;

  procedure MoveSel(Rel: Boolean; aCol,aRow: Integer);
  begin
    // Always reset Offset in kerboard Events
    FGCache.TLColOff:=0;
    FGCache.TLRowOff:=0;
    SelectActive:=Sh;
    MoveNextSelectable(Rel, aCol, aRow);
    Key:=0;
  end;
var
  R: TRect;
  Relaxed: Boolean;
  //PF: TCustomForm;
begin
  inherited KeyDown(Key, Shift);
  if not FGCache.ValidGrid then Exit;
  Sh:=(ssShift in Shift);
  Relaxed:=not (goRowSelect in Options) or (goRelaxedRowSelect in Options);

  if (Key=Vk_TAB) then begin
    if (goTabs in Options) then begin
      case FAutoAdvance of
        aaRight:
          if Sh then Key:=VK_LEFT
          else       Key:=VK_RIGHT;
        aaDown:
          if Sh then Key:=VK_UP
          else       Key:=VK_DOWN;
      end;
    end else begin
      // TODO
      (*
      Pf:=GetParentForm(Self);
      if (Pf<>nil) then Pf.FocusControl(Self);
      PerformTab;
      *)
    end;
  end;

  case Key of
    VK_LEFT:
      begin
        if Relaxed then MoveSel(True,-1, 0)
        else            MoveSel(true, 0,-1);
      end;
    VK_RIGHT:
      begin
        if Relaxed then MoveSel(True, 1, 0)
        else            MoveSel(True, 0, 1);
      end;
    VK_UP:
      begin
        MoveSel(True, 0, -1);
      end;
    VK_DOWN:
      begin
        MoveSel(True, 0, 1);
      end;
    VK_PRIOR:
      begin
        R:=FGCache.Visiblegrid;
        MoveSel(True, 0, R.Top-R.Bottom);
      end;
    VK_NEXT:
      begin
        R:=FGCache.VisibleGrid;
        MoveSel(True, 0, R.Bottom-R.Top);
      end;
    VK_HOME:
      begin
        if ssCtrl in Shift then MoveSel(False, FCol, FFixedRows)
        else
          if Relaxed then MoveSel(False, FFixedCols, FRow)
          else            MoveSel(False, FCol, FFixedRows);
      end;
    VK_END:
      begin
        if ssCtrl in Shift then MoveSel(False, FCol, RowCount-1)
        else
          if Relaxed then MoveSel(False, ColCount-1, FRow)
          else            MoveSel(False, FCol, RowCount-1);
      end;
    VK_F2, VK_RETURN:
      begin
        EditorShow;
        if Key=VK_RETURN then EditorSelectAll;
        Key:=0;
      end;
    VK_BACK:
      begin
        // Workaround: LM_CHAR doesnt trigger with BACKSPACE
        EditorShowChar(^H);
        key:=0;
      end;

    {$IfDef Dbg}
    else WriteLn(ClassName,'.KeyDown: ', Key);
    {$Endif}
  end;
end;


procedure TCustomGrid.KeyUp(var Key: Word; Shift: TShiftState);
begin
  inherited KeyUp(Key, Shift);
end;

{ Convert a fisical Mouse coordinate into fisical a cell coordinate }
function TCustomGrid.MouseToCell(Mouse: TPoint): TPoint;
var
   d: Integer;
begin
  Result.X:= OffsetToColRow(True, True, Mouse.x, d);
  Result.Y:= OffsetToColRow(False,True, Mouse.y, d);
end;

{ Convert a fisical Mouse coordinate into logical a cell coordinate }
function TCustomGrid.MouseToLogcell(Mouse: TPoint): TPoint;
var
  gz: TGridZone;
begin
  Gz:=MouseToGridZone(Mouse.x, Mouse.y, False);
  Result:=MouseToCell(Mouse);
  //if gz=gzNormal then Result:=MouseToCell(Mouse)
  //else begin
  if gz<>gzNormal then begin
    //Result:=MouseToCell(Mouse);
    if (gz=gzFixedRows)or(gz=gzFixedCells) then begin
      Result.x:= fTopLeft.x-1;
      if Result.x<FFixedCols then Result.x:=FFixedCols;
    end;
    if (gz=gzFixedCols)or(gz=gzFixedCells) then begin
      Result.y:=fTopleft.y-1;
      if Result.y<fFixedRows then Result.y:=FFixedRows;
    end;
  end;
end;

function TCustomGrid.ISCellVisible(aCol, aRow: Integer): Boolean;
begin
  with FGCache.VisibleGrid do
    Result:= (Left<=ACol)and(aCol<=Right)and(Top<=aRow)and(aRow<=Bottom);
end;

procedure TCustomGrid.InvalidateCol(ACol: Integer);
var
  R: TRect;
begin
  {$ifdef dbg} WriteLn('InvalidateCol  Col=',aCol); {$Endif}
  R:=CellRect(aCol, FTopLeft.y);
  R.Top:=0; // Full Column
  R.Bottom:=FGCache.MaxClientXY.Y;
  InvalidateRect(Handle, @R, True);
end;

procedure TCustomGrid.InvalidateRow(ARow: Integer);
var
  R: TRect;
begin
  {$ifdef dbg} WriteLn('InvalidateRow  Row=',aRow); {$Endif}
  R:=CellRect(fTopLeft.x, aRow);
  R.Left:=0; // Full row
  R.Right:=FGCache.MaxClientXY.X;
  InvalidateRect(Handle, @R, True);
end;

function TCustomGrid.MoveExtend(Relative: Boolean; DCol, DRow: Integer): Boolean;
var
  InvalidateAll: Boolean;
  LastEditor: TWinControl;
  WasVis: Boolean;
begin
  Result:=TryMoveSelection(Relative,DCol,DRow);
  if (not Result) then Exit;

  BeforeMoveSelection(DCol,DRow);
  {$IfDef dbgFocus}WriteLn(' MoveExtend INIT FCol= ',FCol, ' FRow= ',FRow);{$Endif}

  LastEditor:=Editor;
  WasVis:=(LastEditor<>nil)and(LastEditor.Visible);
  // default range
  if goRowSelect in Options then FRange:=Rect(FFixedCols, DRow, Colcount-1, DRow)
  else                           FRange:=Rect(DCol,DRow,DCol,DRow);

  InvalidateAll:=False;
  if SelectActive then
    if goRangeSelect in Options then begin
      if goRowSelect in Options then begin
        FRange.Top:=Min(fPivot.y, DRow);
        FRange.Bottom:=Max(fPivot.y, DRow);
      end else begin
        FRange:=NormalizarRect(Rect(Fpivot.x,FPivot.y, DCol, DRow));
      end;
      InvalidateAll:=True;
    end;

  if not ScrollToCell(DCol, DRow) then
    if InvalidateAll then begin
      //InvalidateSelection;
      Invalidate
    end else begin
      if goRowSelect in Options then begin
        InvalidateRow(FRow);
        InvalidateRow(DRow);
      end else begin
        InvalidateCell(FCol, FRow);
        InvalidateCell(DCol, DRow);
      end;
    end;


  SwapInt(DCol,FCol);
  SwapInt(DRow,FRow);

  MoveSelection;
  SelectEditor;

  ProcessEditor(LastEditor,DCol,DRow,WasVis);

  {$IfDef dbgFocus}WriteLn(' MoveExtend FIN FCol= ',FCol, ' FRow= ',FRow);{$Endif}
end;

function TCustomGrid.MoveNextSelectable(Relative: Boolean; DCol, DRow: Integer
  ): Boolean;
var
  CInc,RInc: Integer;
  NCol,NRow: Integer;
  SelOk: Boolean;
begin
  // Reference
  if not Relative then begin
    NCol:=DCol;
    NRow:=DRow;
    DCol:=NCol-FCol;
    DRow:=NRow-FRow;
  end else begin
    NCol:=FCol + DCol;
    NRow:=FRow + DRow;
  end;
  // Increment
  if DCol<0 then CInc:=-1 else
  if DCol>0 then CInc:= 1
  else           CInc:= 0;
  if DRow<0 then RInc:=-1 else
  if DRow>0 then RInc:= 1
  else           RInc:= 0;
  // Calculation
  SelOk:=SelectCell(NCol,NRow);
  Result:=False;
  while not SelOk do begin
    if  (NRow>RowCount-1)or(NRow<FFixedRows) or
        (NCol>ColCount-1)or(NCol<FFixedCols) then Exit;
    Inc(NCol, CInc);
    Inc(NRow, RInc);
    SelOk:=SelectCell(NCol, NRow);
  end;
  Result:=MoveExtend(False, NCol, NRow);
end;

function TCustomGrid.TryMoveSelection(Relative: Boolean; var DCol, DRow: Integer
  ): Boolean;
begin

  Result:=False;

  dCol:=FCol*(1-Byte(not Relative))+DCol;
  dRow:=FRow*(1-Byte(not Relative))+DRow;
  if dCol<FFixedCols then dCol:=FFixedCols else
  if dCol>ColCount-1 then dcol:=ColCount-1;
  if dRow<FFixedRows then dRow:=FFixedRows else
  if dRow>RowCount-1 then dRow:=RowCount-1;

  // Change on Focused cell?
  if (Dcol=FCol)and(DRow=FRow) then begin
  end else begin
    Result:=SelectCell(DCol,DRow);
  end;
end;

procedure TCustomGrid.ProcessEditor(LastEditor: TWinControl; DCol, DRow: Integer; WasVis: Boolean);
  procedure RestoreEditor;
  begin
    SwapInt(Integer(FEditor),Integer(LastEditor));
    SwapInt(FCol,DCol);
    SwapInt(FRow,DRow);
  end;
  procedure HideLastEditor;
  begin
    RestoreEditor;
    EditorGetValue;
    RestoreEditor;
  end;
var
  WillVis: Boolean;
begin
  WillVis:=(FEditor<>nil)and EditorShouldEdit;
  if WillVis or WasVis then begin
    if not WillVis then HideLastEditor else
    if not WasVis then  EditorShow
    else begin
      {
      LastEditor.Visible:=False;
      lastEditor.Parent:=nil;
      FEditorMode:=False;
      EditorShow;
      }
      HideLastEditor;
      EditorShow;
      {
      if LastEditor=FEditor then begin
        // only to swap DCol<->FCol and DRow<->FRow
        // Hide editor in old position
        RestoreEditor;
        EditordoGetValue;
        RestoreEditor;
        // Move Editor to new position and set its value
        EditorPos;
        EditordoSetValue;
      end else begin
        // Hide old editor type a
        LastEditor.Visible:=False;
        lastEditor.Parent:=nil;
        // Show new editor type b
        EditorShow;
      end;
      }
    end;
  end;
end;

procedure TCustomGrid.BeforeMoveSelection(const DCol,DRow: Integer);
begin
  if Assigned(OnBeforeSelection) then OnBeforeSelection(Self, DCol, DRow);
end;

procedure TCustomGrid.MoveSelection;
begin
  if Assigned(OnSelection) then OnSelection(Self, FCol, FRow);
end;

procedure TCustomGrid.BeginUpdate;
begin
  Inc(FUpdateCount);
end;

procedure TCustomGrid.EndUpdate(UO: TUpdateOption);
begin
  Dec(FUpdateCount);
  if FUpdateCount=0 then
    case UO of
      uoQuick: Invalidate;
      uoFull: VisualChange;
    end;
end;

procedure TCustomGrid.EndUpdate(FullUpdate: Boolean);
begin
  EndUpdate(uoFull);
end;

function TCustomGrid.IsCellSelected(aCol, aRow: Integer): Boolean;
begin
  Result:=  (FRange.Left<=aCol)   and
            (aCol<=FRange.Right)  and
            (FRange.Top<=aRow)    and
            (aRow<=FRange.Bottom);
end;

procedure TCustomGrid.InvalidateCell(aCol, aRow: Integer);
begin
  InvalidateCell(ACol,ARow, False);
end;

procedure TCustomGrid.InvalidateCell(aCol, aRow: Integer; Redraw: Boolean);
var
  R: TRect;
begin
  {$IfDef dbgPaint}
    WriteLn('InvalidateCell  Col=',aCol, ' Row=',aRow,' Redraw=',Redraw);
  {$Endif}
  R:=CellRect(aCol, aRow);
  InvalidateRect(Handle, @R, Redraw);
end;

procedure TCustomGrid.InvalidateGrid;
begin
  if FUpdateCount=0 then Invalidate;
end;

procedure TCustomGrid.Invalidate;
begin
  if FUpdateCount=0 then
    inherited Invalidate;
end;

procedure TCustomGrid.EditorGetValue;
begin
  if not (csDesigning in ComponentState) then begin
    EditordoGetValue;
    EditorHide;
  end;
end;

procedure TCustomGrid.EditorSetValue;
begin
  if not (csDesigning in ComponentState) then begin
    EditordoSetValue;
    EditorPos;
  end;
end;

procedure TCustomGrid.EditorHide;
begin
  if not FEditorHiding and (Editor<>nil) and Editor.HandleAllocated and Editor.Visible then
  begin
    FEditorMode:=False;
    {$IfDef dbgFocus} WriteLn('EditorHide INIT FCol=',FCol,' FRow=',FRow);{$Endif}
    FEditorHiding:=True;
    Editor.Visible:=False;
    Editor.Parent:=nil;
    LCLIntf.SetFocus(Self.Handle);
    FEDitorHiding:=False;
    {$IfDef dbgFocus} WriteLn('EditorHide FIN'); {$Endif}
  end;
end;

procedure TCustomGrid.EditorShow;
begin
  if csDesigning in ComponentState then exit;
  if not HandleAllocated then
    Exit;

  if (goEditing in Options) and
     not FEditorShowing and (Editor<>nil) and not Editor.Visible then
  begin
    {$IfDef dbgFocus} WriteLn('EditorShow INIT FCol=',FCol,' FRow=',FRow);{$Endif}
    FEditorMode:=True;
    FEditorShowing:=True;

    ScrollToCell(FCol,FRow);
    EditorSetValue;
    Editor.Parent:=Self;
    Editor.Visible:=True;
    LCLIntf.SetFocus(Editor.Handle);
    InvalidateCell(FCol,FRow,True);
    FEditorShowing:=False;
    {$IfDef dbgFocus} WriteLn('EditorShow FIN');{$Endif}
  end;
end;

procedure TCustomGrid.EditorPos;
var
  msg: TGridMessage;
begin
  if FEditor<>nil then begin
    Msg.CellRect:=CellRect(FCol,FRow);
    if FEditorOptions and EO_AUTOSIZE = EO_AUTOSIZE then begin
      with Msg.CellRect do begin
        Right:=Right-Left;
        Bottom:=Bottom-Top;
        FEditor.SetBounds(Left, Top, Right, Bottom);
      end;
    end else begin
      Msg.MsgID:=GM_SETPOS;
      Msg.Grid:=Self;
      Msg.Col:=FCol;
      Msg.Row:=FRow;
      FEditor.Dispatch(Msg);
    end;
  end;
end;

procedure TCustomGrid.EditorSelectAll;
var
  Msg: TGridMessage;
begin
  if FEditor<>nil then
    if FEditorOptions and EO_SELECTALL = EO_SELECTALL then begin
      Msg.MsgID:=GM_SELECTALL;
      FEditor.Dispatch(Msg);
    end;
end;

procedure TCustomGrid.EditordoGetValue;
begin
  //
end;

procedure TCustomGrid.EditordoSetValue;
begin
  //
end;

procedure TCustomGrid.EditorExit(Sender: TObject);
begin
  if not FEditorHiding then begin
    {$IfDef dbgFocus} WriteLn('EditorExit INIT');{$Endif}
    FEditorHiding:=True;
    EditorGetValue;
    if Editor<>nil then begin
      Editor.Visible:=False;
      Editor.Parent:=nil;
      //InvalidateCell(FCol,FRow, True);
    end;
    FEditorHiding:=False;
    {$IfDef dbgFocus} WriteLn('EditorExit FIN'); {$Endif}
  end;
end;

procedure TCustomGrid.EditorKeyDown(Sender: TObject; var Key:Word; Shift:TShiftState);
begin
  FEditorKey:=True; // Just a flag to see from where the event comes
  case Key of
    VK_LEFT, VK_RIGHT, VK_UP, VK_DOWN,
    VK_PRIOR, VK_NEXT:
    begin
      if not(ssShift in Shift) then KeyDown(Key, Shift);
    end;
    VK_RETURN, VK_TAB:
    begin
      if (Key=VK_TAB) and not (goTabs in Options) then begin
          // let the focus go
          KeyDown(Key, Shift);
          //WriteLn('Editor KeyTab Pressed, Focus Should leave the grid');
          Exit;
      end;
      Key:=0;
      case FAutoAdvance of
        aaRight: Key:=VK_RIGHT * Integer( FCol<ColCount-1 );
        aaDown : Key:=VK_DOWN * Integer( FRow<RowCount-1 );
      end;
      if Key=0 then begin
        EditorGetValue;
        EditorShow;
        // Select All !
      end else KeyDown(Key, Shift);
    end;
  end;
  FEditorKey:=False;
end;

procedure TCustomGrid.SelectEditor;
var
  aEditor: TWinControl;
begin
  aEditor:= Editor;
  if (goEditing in Options) and Assigned(OnSelectEditor) then
    OnSelectEditor(Self, fCol,FRow, aEditor);
  if aEditor<>Editor then Editor:=aEditor;
end;

function TCustomGrid.EditorShouldEdit: Boolean;
begin
  Result:=(goEditing in Options)and(goAlwaysShowEditor in Options);
end;

procedure TCustomGrid.EditorShowChar(Ch: Char);
{
var
  msg: TGridMessage;
}
begin
  SelectEditor;
  if FEditor<>nil then begin
    EditorShow;
    EditorSelectAll;
    PostMessage(FEditor.Handle, LM_CHAR, Word(Ch), 0);
    //
    // Note. this is a workaround because the call above doesn't work
    ///
    {
    Msg.MsgID:=GM_SETVALUE;
    Msg.Grid:=Self;
    Msg.Col:=FCol;
    Msg.Row:=FRow;
    if Ch=^H then Msg.Value:=''
    else          Msg.Value:=ch;
    FEditor.Dispatch(Msg);
    }
  end;
end;

procedure TCustomGrid.EditorSetMode(const AValue: Boolean);
begin
  if not AValue then begin
    EditorHide;
    //SetFocus;
  end else
  begin
    EditorShow;
  end;
end;

function TCustomGrid.GetSelectedColor: TColor;
begin
  Result:=FSelectedColor;
end;

function TCustomGrid.GetEditMask(ACol, ARow: Longint): string;
begin
  result:='';
end;

function TCustomGrid.GetEditText(ACol, ARow: Longint): string;
begin
  result:='';
end;

procedure TCustomGrid.SetEditText(ACol, ARow: Longint; const Value: string);
begin
end;

procedure TCustomGrid.SetSelectedColor(const AValue: TColor);
begin
  if FSelectedColor<>AValue then begin
    FSelectedColor:=AValue;
    Invalidate;
  end;
end;

procedure TCustomGrid.SetFixedcolor(const AValue: TColor);
begin
  if FFixedColor<>AValue then begin
    FFixedColor:=Avalue;
    Invalidate;
  end;
end;

function TCustomGrid.GetFixedcolor: TColor;
begin
  result:=FFixedColor;
end;

procedure TCustomGrid.ColWidthsChanged;
begin
  //
end;
procedure TCustomGrid.RowHeightsChanged;
begin
  //
end;

procedure TCustomGrid.SaveContent(cfg: TXMLConfig);
var
  i,j,k: Integer;
  Path: string;
begin
  cfg.SetValue('grid/version', GRIDFILEVERSION);

  Cfg.SetValue('grid/saveoptions/create', soDesign in SaveOptions);
  if soDesign in SaveOptions then begin
    Cfg.SetValue('grid/design/columncount',  ColCount);
    Cfg.SetValue('grid/design/rowcount',  RowCount);
    Cfg.SetValue('grid/design/fixedcols', FixedCols);
    Cfg.SetValue('grid/design/fixedrows', Fixedrows);
    Cfg.SetValue('grid/design/defaultcolwidth', DefaultColWidth);
    Cfg.SetValue('grid/design/defaultRowHeight',DefaultRowHeight);

    j:=0;
    For i:=0 to ColCount-1 do begin
      k:=Integer(FCols[i]);
      if (k>=0)and(k<>DefaultColWidth) then begin
        inc(j);
        cfg.SetValue('grid/design/columns/columncount',j);
        cfg.SetValue('grid/design/columns/column'+IntToStr(j)+'/index', i);
        cfg.SetValue('grid/design/columns/column'+IntToStr(j)+'/width', k);
      end;
    end;
    j:=0;
    For i:=0 to RowCount-1 do begin
      k:=Integer(FRows[i]);
      if (k>=0)and(k<>DefaultRowHeight) then begin
        inc(j);
        cfg.SetValue('grid/design/rows/rowcount',j);
        cfg.SetValue('grid/design/rows/row'+IntToStr(j)+'/index', i);
        cfg.SetValue('grid/design/rows/row'+IntToStr(j)+'/height',k);
      end;
    end;


    Path:='grid/design/options/';
    Cfg.SetValue(Path+'goFixedVertLine/value', goFixedVertLine in options);
    Cfg.SetValue(Path+'goFixedHorzLine/value', goFixedHorzLine in options);
    Cfg.SetValue(Path+'goVertLine/value',  goVertLine in options);
    Cfg.SetValue(Path+'goHorzLine/value',  goHorzLine in options);
    Cfg.SetValue(Path+'goRangeSelect/value', goRangeSelect in options);
    Cfg.SetValue(Path+'goDrawFocusSelected/value', goDrawFocusSelected in options);
    Cfg.SetValue(Path+'goRowSizing/value', goRowSizing in options);
    Cfg.SetValue(Path+'goColSizing/value', goColSizing in options);
    Cfg.SetValue(Path+'goRowMoving/value', goRowMoving in options);
    Cfg.SetValue(Path+'goColMoving/value', goColMoving in options);
    Cfg.SetValue(Path+'goEditing/value', goEditing in options);
    Cfg.SetValue(Path+'goTabs/value', goTabs in options);
    Cfg.SetValue(Path+'goRowSelect/value', goRowSelect in options);
    Cfg.SetValue(Path+'goAlwaysShowEditor/value', goAlwaysShowEditor in options);
    Cfg.SetValue(Path+'goThumbTracking/value', goThumbTracking in options);
    Cfg.SetValue(Path+'goColSpanning/value', goColSpanning in options);
    cfg.SetValue(Path+'goRelaxedRowSelect/value', goRelaxedRowSelect in options);
    cfg.SetValue(Path+'goDblClickAutoSize/value', goDblClickAutoSize in options);
    Cfg.SetValue(Path+'goSmoothScroll/value', goSmoothScroll in Options);
  end;

  Cfg.SetValue('grid/saveoptions/position', soPosition in SaveOptions);
  if soPosition in SaveOptions then begin
    Cfg.SetValue('grid/position/topleftcol',ftopleft.x);
    Cfg.SetValue('grid/position/topleftrow',ftopleft.y);
    Cfg.SetValue('grid/position/col',fCol);
    Cfg.SetValue('grid/position/row',fRow);
    if goRangeSelect in Options then begin
      Cfg.SetValue('grid/position/selection/left',Selection.left);
      Cfg.SetValue('grid/position/selection/top',Selection.top);
      Cfg.SetValue('grid/position/selection/right',Selection.right);
      Cfg.SetValue('grid/position/selection/bottom',Selection.bottom);
    end;
  end;
end;


procedure TCustomGrid.LoadContent(cfg: TXMLConfig; Version: Integer);
var
  CreateSaved: Boolean;
  Opt: TGridOptions;
  i,j,k: Integer;
  path: string;

    procedure GetValue(optStr:string; aOpt:TGridOption);
    begin
      if Cfg.GetValue(Path+OptStr+'/value', False) then Opt:=Opt+[aOpt];
    end;

begin
  if soDesign in FSaveOptions then begin
    CreateSaved:=Cfg.GetValue('grid/saveoptions/create', false);
    if CreateSaved then begin
      Clear;
      FixedCols:=0;
      FixedRows:=0;
      ColCount:=Cfg.GetValue('grid/design/columncount', 5);
      RowCount:=Cfg.GetValue('grid/design/rowcount', 5);
      FixedCols:=Cfg.GetValue('grid/design/fixedcols', 1);
      FixedRows:=Cfg.GetValue('grid/design/fixedrows', 1);
      DefaultRowheight:=Cfg.GetValue('grid/design/defaultrowheight', 24);
      DefaultColWidth:=Cfg.getValue('grid/design/defaultcolwidth', 64);

      Path:='grid/design/columns/';
      k:=cfg.getValue(Path+'columncount',0);
      For i:=1 to k do begin
        j:=cfg.getValue(Path+'column'+IntToStr(i)+'/index',-1);
        if (j>=0)and(j<=ColCount-1) then begin
          ColWidths[j]:=cfg.getValue(Path+'column'+IntToStr(i)+'/width',-1);
        end;
      end;
      Path:='grid/design/rows/';
      k:=cfg.getValue(Path+'rowcount',0);
      For i:=1 to k do begin
        j:=cfg.getValue(Path+'row'+IntToStr(i)+'/index',-1);
        if (j>=0)and(j<=ColCount-1) then begin
          RowHeights[j]:=cfg.getValue(Path+'row'+IntToStr(i)+'/height',-1);
        end;
      end;

      Opt:=[];
      Path:='grid/design/options/';
      GetValue('goFixedVertLine', goFixedVertLine);
      GetValue('goFixedHorzLine', goFixedHorzLine);
      GetValue('goVertLine',goVertLine);
      GetValue('goHorzLine',goHorzLine);
      GetValue('goRangeSelect',goRangeSelect);
      GetValue('goDrawFocusSelected',goDrawFocusSelected);
      GetValue('goRowSizing',goRowSizing);
      GetValue('goColSizing',goColSizing);
      GetValue('goRowMoving',goRowMoving);
      GetValue('goColMoving',goColMoving);
      GetValue('goEditing',goEditing);
      GetValue('goRowSelect',goRowSelect);
      GetValue('goTabs',goTabs);
      GetValue('goAlwaysShowEditor',goAlwaysShowEditor);
      GetValue('goThumbTracking',goThumbTracking);
      GetValue('goColSpanning', goColSpanning);
      GetValue('goRelaxedRowSelect',goRelaxedRowSelect);
      GetValue('goDblClickAutoSize',goDblClickAutoSize);
      if Version>=2 then begin
        GetValue('goSmoothScroll',goSmoothScroll);
      end;

      Options:=Opt;
    end;

    CreateSaved:=Cfg.GetValue('grid/saveoptions/position', false);
    if CreateSaved then begin
      i:=Cfg.GetValue('grid/position/topleftcol',-1);
      j:=Cfg.GetValue('grid/position/topleftrow',-1);
      if MouseToGridZone(i,j,true)=gzNormal then begin
        tryScrollto(i,j);
      end;
      i:=Cfg.GetValue('grid/position/col',-1);
      j:=Cfg.GetValue('grid/position/row',-1);
      if (i>=FFixedCols)and(i<=ColCount-1) and
         (j>=FFixedRows)and(j<=RowCount-1) then begin
        MoveExtend(false, i,j);
      end;
      if goRangeSelect in Options then begin
        FRange.left:=Cfg.getValue('grid/position/selection/left',FCol);
        FRange.Top:=Cfg.getValue('grid/position/selection/top',FRow);
        FRange.Right:=Cfg.getValue('grid/position/selection/right',FCol);
        FRange.Bottom:=Cfg.getValue('grid/position/selection/bottom',FRow);
      end;
    end;
  end;
end;

procedure TCustomGrid.Loaded;
begin
  inherited Loaded;
  VisualChange;
end;

constructor TCustomGrid.Create(AOwner: TComponent);
begin
  // Inherited create Calls SetBounds->WM_SIZE->VisualChange so
  // fGrid needs to be created before that
  FCols:=TList.Create;
  FRows:=TList.Create;
  FGCache.AccumWidth:=TList.Create;
  FGCache.AccumHeight:=TList.Create;
  FGSMHBar := GetSystemMetrics(SM_CYHSCROLL) + 3;
  FGSMVBar := GetSystemMetrics(SM_CXVSCROLL) + 3;
  //WriteLn('FGSMHBar= ', FGSMHBar, ' FGSMVBar= ', FGSMVBar);
  inherited Create(AOwner);
  //AutoScroll:=False;
  FBorderStyle := bsSingle; //bsNone;
  FDefaultDrawing := True;
  FOptions:=
    [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect,
     goSmoothScroll ];
  FScrollbars:=ssAutoBoth;
  fGridState:=gsNormal;
  fDefColWidth:=64;//40;
  fDefRowHeight:=24;//18;
  fGridLineColor:=clGray;
  FGridLineStyle:=psSolid;
  fFocusColor:=clRed;
  FFixedColor:=clBtnFace;
  FSelectedColor:= clBlack;
  FSkipUnSelectable:=True;
  FRange:=Rect(-1,-1,-1,-1);
  FDragDx:=3;

  SetBounds(0,0,200,100);
  ColCount:=5;
  RowCount:=5;
  FixedCols:=1;
  FixedRows:=1;
  Editor:=nil;

  //writeLn('Setting color');
  Color:=clWindow;
  //writeLn('Color', IntToHex(color, 4), ColorToString(Color));
  Color:=clWhite;
  //writeLn('Color', IntToHex(Color, 4), ColorToString(Color));
end;

destructor TCustomGrid.Destroy;
begin
  {$Ifdef dbg}WriteLn('TCustomGrid.Destroy');{$Endif}
  FreeThenNil(FGCache.AccumWidth);
  FreeThenNil(FGCache.AccumHeight);
  FreeThenNil(FCols);
  FreeThenNil(FRows);
  inherited Destroy;
end;

procedure TCustomGrid.SaveToFile(FileName: string);
var
  Cfg: TXMLConfig;
begin
  if FileExists(FileName) then DeleteFile(FileName);

  Cfg:=TXMLConfig.Create(FileName);
  Try
    SaveContent(Cfg);
  Finally
    Cfg.Flush;
    FreeThenNil(Cfg);
  end;
end;

procedure TCustomGrid.LoadFromFile(FileName: string);
var
  Cfg: TXMLConfig;
  Version: Integer;
begin
  if not FileExists(FileName) then
    raise Exception.Create(rsGridFileDoesNotExists);

  Cfg:=TXMLConfig.Create(FileName);
  Try
    Version:=cfg.GetValue('grid/version',-1);
    if Version=-1 then raise Exception.Create(rsNotAValidGridFile);
    BeginUpdate;
    LoadContent(Cfg, Version);
    EndUpdate(True);
  Finally
    FreeThenNil(Cfg);
  end;
end;

procedure TCustomGrid.Clear;
var
  OldR,OldC: Integer;
begin
  OldR:=RowCount;
  OldC:=ColCount;
  FFixedCols:=0;
  FFixedRows:=0;
  FRows.Count:=0;
  FCols.Count:=0;
  FTopLeft:=Point(-1,-1);
  FRange:=Rect(-1,-1,-1,-1);
  FGCache.TLColOff := 0;
  FGCache.TlRowOff := 0;
  VisualChange;
  SizeChanged(OldR,OldC);
end;

procedure TCustomGrid.AutoAdjustColumns;
var
  i: Integer;
begin
  For i:=0 to ColCount do
    AutoAdjustColumn(i);
end;

{ TVirtualGrid }

function TVirtualGrid.GetCells(Col, Row: Integer): PCellProps;
begin
  // todo: Check range
  Result:=nil;
  if (Col<0) or (Row<0) or (Col>=ColCount) or (Row>=RowCount) then
    raise EGridException.CreateFmt(rsIndexOutOfRange, [Col, Row]);
  Result:=FCells[Col,Row];
end;

function Tvirtualgrid.Getrows(Row: Integer): PColRowprops;
begin
  Result:= FRows[Row, 0];
end;

function Tvirtualgrid.Getcols(Col: Integer): PColRowProps;
begin
  result:=FCols[Col, 0];
end;

procedure TVirtualGrid.SetCells(Col, Row: Integer; const AValue: PCellProps);
var
   Cell: PCellProps;
begin
  // todo: Check range
  Cell:=FCells[Col,Row];
  if Cell<>nil then DisposeCell(Cell);
  Cell:=AValue;
  FCells[Col,Row]:=Cell;
end;

procedure Tvirtualgrid.Setrows(Row: Integer; const Avalue: PColRowProps);
var
   C: PColRowProps;
begin
  // todo: Check range
  C:=FRows[Row,0];
  if C<>nil then DisposeColRow(C);
  FRows[Row,0]:=AValue;
end;

procedure Tvirtualgrid.Setcolcount(const Avalue: Integer);
begin
  if FColCount=Avalue then Exit;
  {$Ifdef dbgMem}
    WriteLn('TVirtualGrid.SetColCount Value=',AValue);
  {$Endif}
  FColCount:=AValue;
  {$Ifdef dbgMem}
    write('TVirtualGrid.SetColCount->FCOLS: ');
  {$Endif}
  FCols.SetLength(FColCount, 1);
  {$Ifdef dbgMem}
    write('TVirtualGrid.SetColCount->FCELLS(',FColCount,',',FRowCount,'): ');
  {$Endif}
  FCells.SetLength(FColCount, FRowCount);
end;


procedure Tvirtualgrid.Setrowcount(const Avalue: Integer);
begin
  if FRowCount=AValue then Exit;
  {$Ifdef dbgMem}
    WriteLn('TVirtualGrid.SetRowCount Value=',AValue);
  {$Endif}
  FRowCount:=AValue;
  {$Ifdef dbgMem}
    write('TVirtualGrid.SetRowCount->FROWS: ');
  {$Endif}
  FRows.SetLength(FRowCount,1);
  {$Ifdef dbgMem}
    write('TVirtualGrid.SetRowCount->FCELLS(',FColCount,',',FRowCount,'): ');
  {$Endif}
  FCells.SetLength(FColCount, FRowCount);
end;

procedure Tvirtualgrid.Setcols(Col: Integer; const Avalue: PColRowProps);
var
   C: PColRowProps;
begin
  // todo: Check range
  C:=FCols[Col,0];
  if C<>nil then DisposeColRow(C);
  FCols[Col,0]:=AValue;
end;

procedure Tvirtualgrid.Clear;
begin
  {$Ifdef dbgMem}write('FROWS: ');{$Endif}FRows.Clear;
  {$Ifdef dbgMem}write('FCOLS: ');{$Endif}FCols.Clear;
  {$Ifdef dbgMem}write('FCELLS: ');{$Endif}FCells.Clear;
  FColCount:=0;
  FRowCount:=0;
end;

procedure Tvirtualgrid.Disposecell(var P: Pcellprops);
begin
  if P<>nil then begin
    if P^.Text<>nil then StrDispose(P^.Text);
    Dispose(P);
    P:=nil;
  end;
end;

procedure TVirtualGrid.DisposeColRow(var p: PColRowProps);
begin
  if P<>nil then begin
    Dispose(P);
    P:=nil;
  end;
end;

function TVirtualGrid.GetDefaultCell: PcellProps;
begin
  New(Result);
  Result^.Text:=nil;
  Result^.Attr:=nil;
end;

function TVirtualGrid.GetDefaultColRow: PColRowProps;
begin
  New(Result);
  Result^.FixedAttr:=nil;
  Result^.NormalAttr:=nil;
  Result^.Size:=-1;
end;

procedure Tvirtualgrid.Dodestroyitem (Sender: Tobject; Col,Row: Integer;
  var Item: Pointer);
begin
  {$Ifdef dbgMem}
    WriteLn('TVirtualGrid.doDestroyItem Col=',Col,' Row= ',
            Row,' Item=',Integer(Item));
  {$endif}
  if Item<>nil then begin
    if (Sender=FCols)or(Sender=FRows) then begin
      DisposeColRow(PColRowProps(Item));
    end else begin
      DisposeCell(PCellProps(Item));
    end;
    Item:=nil;
  end;
end;

procedure Tvirtualgrid.doNewitem(Sender: Tobject; Col,Row:Integer;
  var Item: Pointer);
begin
  {$Ifdef dbgMem}
    WriteLn('TVirtualGrid.doNewItem Col=',Col,' Row= ',
            Row,' Item=',Integer(Item));
  {$endif}
  if Sender=FCols then begin
    // Procesar Nueva Columna
    Item:=GetDefaultColRow;
  end else
  if Sender=FRows then begin
    // Procesar Nuevo Renglon
    Item:=GetDefaultColRow;
  end else begin
    // Procesar Nueva Celda
    Item:=nil;
  end;
end;

constructor TVirtualGrid.Create;
begin
  Inherited Create;
  {$Ifdef dbg}WriteLn('TVirtualGrid.Create');{$Endif}
  FCells:=TArray.Create;
  FCells.OnDestroyItem:=@doDestroyItem;
  FCells.OnNewItem:=@doNewItem;
  FCols:= TArray.Create;
  FCols.OnDestroyItem:=@doDestroyItem;
  FCols.OnNewItem:=@doNewItem;
  FRows:=TArray.Create;
  FRows.OnDestroyItem:=@doDestroyItem;
  FRows.OnNewItem:=@doNewItem;
  RowCount:=4;
  ColCount:=4;
end;

destructor TVirtualGrid.Destroy;
begin
  {$Ifdef dbg}WriteLn('TVirtualGrid.Destroy');{$Endif}
  Clear;
  FreeThenNil(FRows);
  FreeThenNil(FCols);
  FreeThenNil(FCells);
  inherited Destroy;
end;

procedure TVirtualGrid.DeleteColRow(IsColumn: Boolean; index: Integer);
begin
  FCells.DeleteColRow(IsColumn, index);
  if IsColumn then begin
    FCols.DeleteColRow(True, index);
    Dec(FColCount);
  end else begin
    FRows.DeleteColRow(True, index);
    Dec(fRowCount);
  end;
end;

procedure TVirtualGrid.MoveColRow(IsColumn: Boolean; FromIndex, ToIndex: Integer
  );
begin
  FCells.MoveColRow(IsColumn, FromIndex, ToIndex);
  if IsColumn then FCols.MoveColRow(True, FromIndex, ToIndex)
  else             FRows.MoveColRow(True, FromIndex, ToIndex);
end;

procedure TVirtualGrid.ExchangeColRow(IsColumn: Boolean; index,
  WithIndex: Integer);
begin
  FCells.ExchangeColRow(IsColumn, index, WithIndex);
  if IsColumn then FCols.ExchangeColRow(true, index, WithIndex)
  else             FRows.ExchangeColRow(True, index, WithIndex);
end;


{
procedure TStringCellEditor.WndProc(var TheMessage: TLMessage);
begin
  write(Name,'.WndProc msg= ');
  case TheMessage.Msg of
    LM_SHOWWINDOW: WriteLn('LM_SHOWWINDOW');
    LM_SETFOCUS: WriteLn('LM_SETFOCUS');
    LM_PAINT: WriteLn('LM_PAINT');
    LM_KEYUP: WriteLn('LM_KEYUP');
    LM_WINDOWPOSCHANGED: WriteLn('LM_WINDOWPOSCHANGED');
    LM_MOVE: WriteLn('LM_MOVE');
    LM_KILLFOCUS: WriteLn('LM_KILLFOCUS');
    CM_BASE..CM_MOUSEWHEEL:
      begin
        case TheMessage.Msg of
          CM_MOUSEENTER: WriteLn('CM_MOUSEENTER');
          CM_MOUSELEAVE: WriteLn('CM_MOUSELEAVE');
          CM_VISIBLECHANGED: WriteLn('CM_VISIBLECHANGED');
          CM_TEXTCHANGED: WriteLn('CM_TEXTCHANGED');
          CM_SHOWINGCHANGED: WriteLn('CM_SHOWINGCHANGED');
          else WriteLn('CM_BASE + ',TheMessage.Msg-CM_BASE);
        end

      end;
    CN_BASE..CN_NOTIFY:
      begin
        WriteLn('CN_BASE + ',TheMessage.Msg-CN_BASE);
      end;
    else
      WriteLn(TheMessage.Msg,' (',IntToHex(TheMessage.Msg, 4),')');
  end;
  inherited WndProc(TheMessage);
end;
}
{ TStringCellEditor }

procedure TStringCellEditor.Change;
begin
  inherited Change;
  if FGrid<>nil then FGrid.SetEditText(FGrid.Col, FGrid.Row, Text);
end;

procedure TStringCellEditor.KeyDown(var Key: Word; Shift: TShiftState);
  procedure doInherited;
  begin
    inherited keyDown(key, shift);
    key:=0;
  end;
  function AtStart: Boolean;
  begin
    Result:= (SelStart=0);
  end;
  function AtEnd: Boolean;
  begin
    Result:= (SelStart+1)>Length(Text);
  end;
begin
  {$IfDef dbg}
  WriteLn('INI: Key=',Key,' SelStart=',SelStart,' SelLenght=',SelLength);
  {$Endif}
  {
  case Key of
    VK_LEFT:  if AtStart then doInherited;
    VK_RIGHT: if AtEnd then doInherited;
  end;
  }
  if FGrid<>nil then begin
    Fgrid.EditorKeyDown(Self, Key, Shift);
  end;
  inherited keyDown(key, shift);
  {$IfDef dbg}
  WriteLn('FIN: Key=',Key,' SelStart=',SelStart,' SelLenght=',SelLength);
  {$Endif}
end;

procedure TStringCellEditor.msg_SetMask(var Msg: TGridMessage);
begin
  EditMask:=msg.Value;
end;


procedure TStringCellEditor.msg_SetValue(var Msg: TGridMessage);
begin
  Text:=Msg.Value;
end;

procedure TStringCellEditor.msg_GetValue(var Msg: TGridMessage);
begin
  Msg.Value:=Text;
end;

procedure TStringCellEditor.msg_SetGrid(var Msg: TGridMessage);
begin
  FGrid:=Msg.Grid;
  Msg.Options:=EO_AUTOSIZE or EO_HOOKEXIT or EO_SELECTALL;
end;

procedure TStringCellEditor.msg_SelectAll(var Msg: TGridMessage);
begin
  SelectAll;
end;

{ TDrawGrid }


procedure TDrawGrid.CalcCellExtent(acol, aRow: Integer; var aRect: TRect);
begin
  //
end;

procedure TDrawGrid.DrawCell(aCol,aRow: Integer; aRect: TRect;
  aState:TGridDrawState);
begin
  if Assigned(OnDrawCell) and not(CsDesigning in ComponentState) then begin
    PrepareCanvas(aCol, aRow, aState);
    Canvas.FillRect(aRect);
    OnDrawCell(Self,aCol,aRow,aRect,aState)
  end else
    DefaultDrawCell(aCol,aRow,aRect,aState);
  inherited DrawCellGrid(aCol,aRow,aRect,aState);
end;

procedure TDrawGrid.DrawFocusRect(aCol, aRow: Integer; ARect: TRect;
  aState: TGridDrawstate);
begin
  // Draw focused cell if we have the focus
  if Self.Focused Or (EditorShouldEdit and ((Feditor=nil)or not Feditor.Focused)) then begin
    if (gdFocused in aState)then begin
      Canvas.Pen.Color:=FFocusColor;
      Canvas.Pen.Style:=psDot;
      if goRowSelect in Options then begin
        Canvas.MoveTo(FGCache.FixedWidth+1, aRect.Top);
        Canvas.LineTo(FGCache.MaxClientXY.x-2, aRect.Top);
        Canvas.LineTo(FGCache.MaxClientXY.x-2, aRect.Bottom-2);
        Canvas.LineTo(FGCache.FixedWidth+1, aRect.Bottom-2);
        Canvas.LineTo(FGCache.FixedWidth+1, aRect.Top+1);
      end else begin
        Canvas.MoveTo(aRect.Left, aRect.Top);
        Canvas.LineTo(ARect.Right-2,aRect.Top);
        Canvas.LineTo(aRect.Right-2,aRect.bottom-2);
        Canvas.LineTo(aRect.Left, aRect.Bottom-2);
        Canvas.Lineto(aRect.left, aRect.top+1);
      end;
      Canvas.Pen.Style:=psSolid;
    end;
  end;
end;

procedure TDrawGrid.ColRowExchanged(IsColumn:Boolean; index, WithIndex: Integer);
begin
  Fgrid.ExchangeColRow(IsColumn, index, WithIndex);
  if Assigned(OnColRowExchanged) then
    OnColRowExchanged(Self, IsColumn, index, WithIndex);
end;

procedure TDrawGrid.ColRowDeleted(IsColumn: Boolean; index: Integer);
begin
  FGrid.DeleteColRow(IsColumn, index);
  if Assigned(OnColRowDeleted) then
    OnColRowDeleted(Self, IsColumn, index, index);
end;

procedure TDrawGrid.ColRowMoved(IsColumn: Boolean; FromIndex, ToIndex: Integer);
begin
  FGrid.MoveColRow(IsColumn, FromIndex, ToIndex);
  if Assigned(OnColRowMoved) then
    OnColRowMoved(Self, IsColumn, FromIndex, toIndex);
end;

procedure TDrawGrid.HeaderClick(IsColumn: Boolean; index: Integer);
begin
  inherited HeaderClick(IsColumn, index);
  if Assigned(OnHeaderClick) then OnHeaderClick(Self, IsColumn, index);
end;

function TDrawGrid.GetEditMask(aCol, aRow: Longint): string;
begin
  result:='';
  if assigned(OnGetEditMask) then OnGetEditMask(self, aCol, aRow, Result);
end;

function TDrawGrid.GetEditText(aCol, aRow: Longint): string;
begin
  result:='';
  if assigned(OnGetEditText) then OnGetEditText(self, aCol, aRow, Result);
end;

procedure TDrawGrid.SetEditText(ACol, ARow: Longint; const Value: string);
begin
  if Assigned(OnSetEditText) then OnSetEditText(Self, aCol, aRow, Value);
end;

procedure TDrawGrid.SizeChanged(OldColCount, OldRowCount: Integer);
begin
  if OldColCount<>ColCount then fGrid.ColCount:=ColCOunt;
  if OldRowCount<>RowCount then fGrid.RowCount:=RowCount;
end;

function TDrawGrid.SelectCell(aCol, aRow: Integer): boolean;
begin
  Result:=true;
  if Assigned(OnSelectCell) then OnSelectCell(Self, aCol, aRow, Result);
end;

procedure TDrawGrid.SetColor(Value: TColor);
begin
  inherited SetColor(Value);
  Invalidate;
end;

function TDrawGrid.CreateVirtualGrid: TVirtualGrid;
begin
  Result:=TVirtualGrid.Create;
end;

constructor TDrawGrid.Create(AOwner: TComponent);
begin
  fGrid:=CreateVirtualGrid; //TVirtualGrid.Create;
  inherited Create(AOwner);
end;

destructor TDrawGrid.Destroy;
begin
  {$Ifdef dbg}WriteLn('TDrawGrid.Destroy');{$Endif}
  //WriteLn('Font.Name',Font.Name);
  FreeThenNil(FGrid);
  inherited Destroy;
end;

procedure TDrawGrid.DefaultDrawCell(aCol, aRow: Integer; var aRect: TRect;
  aState: TGridDrawState);
var
  OldDefaultDrawing: boolean;
begin
  OldDefaultDrawing:=FDefaultDrawing;
  FDefaultDrawing:=True;
  try
    PrepareCanvas(aCol, aRow, aState);
  finally
    FDefaultDrawing:=OldDefaultDrawing;
  end;
  if goColSpanning in Options then CalcCellExtent(acol, arow, aRect);
  Canvas.FillRect(aRect);
end;

{ TStringGrid }

function TStringGrid.Getcells(aCol, aRow: Integer): string;
var
   C: PCellProps;
begin
  Result:='';
  C:=FGrid.Celda[aCol,aRow];
  if C<>nil then Result:=C^ .Text;
end;

function TStringGrid.GetCols(index: Integer): TStrings;
var
  i,j: Integer;
begin
  Result:=nil;
  if (ColCount>0)and(index>=0)and(index<ColCount) then begin
    Result:=TStringList.Create;
    For i:=0 to RowCount-1 do begin
      j:=Result.Add( Cells[index, i] );
      Result.Objects[j]:=Objects[index, i];
    end;
  end;
end;

function TStringGrid.GetObjects(ACol, ARow: Integer): TObject;
var
  C: PCellProps;
begin
  Result:=nil;
  C:=Fgrid.Celda[aCol,aRow];
  if C<>nil then Result:=C^.Data;
end;

function TStringGrid.GetRows(index: Integer): TStrings;
var
  i,j: Integer;
begin
  Result:=nil;
  if (RowCount>0)and(index>=0)and(index<RowCount) then begin
    Result:=TStringList.Create;
    For i:=0 to ColCount-1 do begin
      j:=Result.Add( Cells[i, index] );
      Result.Objects[j]:=Objects[i, index];
    end;
  end;
end;

procedure TStringGrid.ReadCells(Reader: TReader);
var
  aCol,aRow: Integer;
  i, c: Integer;
begin
  with Reader do begin
    ReadListBegin;
    c := ReadInteger;
    for i:=1 to c do begin
      aCol := ReadInteger;
      aRow := ReadInteger;
      Cells[aCol,aRow]:= ReadString;
    end;
    {
    repeat
      aCol := ReadInteger;
      aRow := ReadInteger;
      Cells[aCol,aRow] := ReadString;
    until NextValue = vaNull;
    }
    ReadListEnd;
  end;
end;

procedure TStringGrid.Setcells(aCol, aRow: Integer; const Avalue: string);
var
  C: PCellProps;
begin
  C:= FGrid.Celda[aCol,aRow];
  if C<>nil then begin
    if C^.Text<>nil then StrDispose(C^.Text);
    C^.Text:=StrNew(pchar(aValue));
    InvalidateCell(aCol, aRow);
  end else begin
    if AValue<>'' then begin
      New(C);
      C^.Text:=StrNew(pchar(Avalue));
      C^.Attr:=nil;
      FGrid.Celda[aCol,aRow]:=C;
      InvalidateCell(aCol, aRow);
    end;
  end;
end;

procedure TStringGrid.SetCols(index: Integer; const AValue: TStrings);
var
  i: Integer;
begin
  if Avalue=nil then exit;
  for i:=0 to AValue.Count-1 do begin
    Cells[index, i]:= AValue[i];
    Objects[Index, i]:= AValue.Objects[i];
  end;
end;

procedure TStringGrid.SetObjects(ACol, ARow: Integer; AValue: TObject);
var
  c: PCellProps;
begin
  C:=FGrid.Celda[aCol,aRow];
  if c<>nil then C^.Data:=AValue
  else begin
    c:=fGrid.GetDefaultCell;
    c^.Data:=Avalue;
    FGrid.Celda[aCol,aRow]:=c;
  end;
end;

procedure TStringGrid.SetRows(index: Integer; const AValue: TStrings);
var
  i: Integer;
begin
  if Avalue=nil then exit;
  for i:=0 to AValue.Count-1 do begin
    Cells[i, index]:= AValue[i];
    Objects[i, Index]:= AValue.Objects[i];
  end;
end;

procedure TStringGrid.WriteCells(Writer: TWriter);
var
  i,j: Integer;
  c: Integer;
begin
  with writer do begin
    WriteListBegin;
    //cell count
    c:=0;
    for i:=0 to ColCount-1 do
      for j:=0 to RowCount-1 do
        if Cells[i,j]<>'' then Inc(c);
    WriteInteger(c);
    
    for i:=0 to ColCount-1 do
      for j:=0 to RowCount-1 do
        if Cells[i,j]<>'' then begin
          WriteInteger(i);
          WriteInteger(j);
          WriteString(Cells[i,j]);
        end;
    WriteListEnd;
  end;
end;

procedure TStringGrid.AutoAdjustColumn(aCol: Integer);
var
  i,W: Integer;
  Ts: TSize;
begin
  if (aCol<0)or(aCol>ColCount-1) then Exit;
  W:=0;
  For i:=0 to RowCount-1 do begin
    Ts:=Canvas.TextExtent(Cells[aCol, i]);
    if Ts.Cx>W then W:=Ts.Cx;
  end;
  if W=0 then W:=DefaultColWidth
  else        W:=W + 8;
  ColWidths[aCol]:=W;
end;

procedure TStringGrid.CalcCellExtent(acol, aRow: Integer; var aRect: TRect);
var
  S: string;
  Ts: Tsize;
  nc: PcellProps;
  i: integer;
begin
  inherited CalcCellExtent(acol,arow, aRect);
  S:=Cells[aCol,aRow];
  if not Canvas.TextStyle.Clipping then begin
  //if not FCellAttr.TextStyle.Clipping then begin
    // Calcular el numero de celdas necesarias para contener todo
    // El Texto
    Ts:=Canvas.TextExtent(S);
    i:=aCol;
    while (Ts.Cx>(aRect.Right-aRect.Left))and(i<ColCount) do begin
      inc(i);
      Nc:=FGrid.Celda[i, aRow];
      if (nc<>nil)and(Nc^.Text<>'')then Break;
      aRect.Right:=aRect.Right + getColWidths(i);
    end;
    //fcellAttr.TextStyle.Clipping:=i<>aCol;
    Canvas.TextStyle.clipping:=i<>aCol;
  end;
end;

procedure TStringGrid.DefineProperties(Filer: TFiler);
  function NeedCells: boolean;
  var
    i,j: integer;
    AntGrid: TStringGrid;
  begin
    AntGrid := TStringGrid(Filer.Ancestor);
    //WriteLn('TStringGrid.DefineProperties: Ancestor=',Integer(AntGrid));
    if AntGrid<>nil then begin
      result:=false;
      for i:=0 to AntGrid.ColCount-1 do
        for j:=0 to AntGrid.RowCount-1 do
          if Cells[i,j]<>AntGrid.Cells[i,j] then begin
          result:=true;
          break;
        end;
   end else
      result:=true;
  end;
begin
  inherited DefineProperties(Filer);
  with Filer do begin
    DefineProperty('Cells',  @ReadCells,  @WriteCells,  NeedCells);
  end;
end;

procedure TStringGrid.DrawCell(aCol, aRow: Integer; aRect: TRect;
  aState: TGridDrawState);
//var
//  ts: TTextStyle;
begin
  inherited DrawCell(aCol, aRow, aRect, aState);
  if DefaultDrawing then begin
    Canvas.TextRect(aRect, 3, 0, Cells[aCol,aRow]);
    //MyTExtRect(aRect, 3, 0, Cells[aCol,aRow], Canvas.Textstyle.Clipping);
  end;
end;

procedure TStringGrid.EditordoGetValue;
var
  msg: TGridMessage;
begin
  if (FEditor<>nil) and FEditor.Visible then begin
    Msg.MsgID:=GM_GETVALUE;
    Msg.grid:=Self;
    Msg.Col:=FCol;
    Msg.Row:=FRow;
    Msg.Value:=Cells[FCol,FRow]; // default value
    FEditor.Dispatch(Msg);
    SetEditText(FCol, FRow, msg.Value);
    //Cells[FCol,FRow]:=msg.Value;
  end;
end;

procedure TStringGrid.EditordoSetValue;
var
  msg: TGridMessage;
begin
  if FEditor<>nil then begin
    // Set the editor mask
    Msg.MsgID:=GM_SETMASK;
    Msg.Grid:=Self;
    Msg.Col:=FCol;
    Msg.Row:=FRow;
    Msg.Value:=GetEditMask(FCol, FRow);
    FEditor.Dispatch(Msg);
    // Set the editor value
    Msg.MsgID:=GM_SETVALUE;
    Msg.Grid:=Self;
    Msg.Col:=FCol;
    Msg.Row:=FRow;
    Msg.Value:=GetEditText(Fcol, FRow); //Cells[FCol,FRow];
    FEditor.Dispatch(Msg);
  end;
end;

function TStringGrid.GetEditText(aCol, aRow: Integer): string;
begin
  Result:=Cells[aCol, aRow];
  if Assigned(OnGetEditText) then OnGetEditText(Self, aCol, aRow, result);
end;

procedure TStringGrid.SaveContent(cfg: TXMLConfig);
var
  i,j,k: Integer;
  c: PCellProps;
begin
  inherited SaveContent(cfg);
  cfg.SetValue('grid/saveoptions/content', soContent in SaveOptions);
  if soContent in SaveOptions then begin
    // Save Cell Contents
    k:=0;
    For i:=0 to ColCount-1 do
      For j:=0 to RowCount-1 do begin
        C:=fGrid.Celda[i,j];
        if (c<>nil) and (C^.Text<>'') then begin
          Inc(k);
          Cfg.SetValue('grid/content/cells/cellcount',k);
          cfg.SetValue('grid/content/cells/cell'+IntToStr(k)+'/column',i);
          cfg.SetValue('grid/content/cells/cell'+IntToStr(k)+'/row',j);
          cfg.SetValue('grid/content/cells/cell'+IntToStr(k)+'/text', c^.Text);
        end;
      end;
   end;
end;

procedure TStringGrid.LoadContent(Cfg: TXMLConfig; Version:Integer);
var
  ContentSaved: Boolean;
  i,j,k: Integer;
begin
  inherited LoadContent(Cfg, Version);
  if soContent in FSaveOptions then begin
    ContentSaved:=Cfg.GetValue('grid/saveoptions/content', false);
    if ContentSaved then begin
      k:=cfg.getValue('grid/content/cells/cellcount', 0);
      while k>0 do begin
        i:=cfg.GetValue('grid/content/cells/cell'+IntToStr(k)+'/column', -1);
        j:=cfg.GetValue('grid/content/cells/cell'+IntTostr(k)+'/row',-1);
        if (j>=0)and(j<=rowcount-1)and(i>=0)and(i<=Colcount-1) then
          Cells[i,j]:=cfg.GetValue('grid/content/cells/cell'+IntToStr(k)+'/text','');
        Dec(k);
      end;
    end;
  end;
end;

(*
procedure TStringGrid.DrawInteriorCells;
var
  i,j: Integer;
  gds: TGridDrawState;
  c: PCellProps;
begin
  with FGCache.VisibleGrid do
  if goColSpanning in Options then begin
    //
    // Ordered draw should be done in order to this work
    //
    Gds:=[];
    // Draw Empty (nil) cells First
    For i:=Left to Right do
      For j:=Top to Bottom do begin
        if IsCellSelected(i,j) then Continue;
        C:=Fgrid.Celda[i,j];
        if (c=nil) then DrawCell(i,j, CellRect(i,j), gds);
      end;
     // Draw Cells Empty Cells (Text='') with Attribute
    For i:=Left to Right do
      For j:=Top to Bottom do begin
        if IsCellSelected(i,j) then Continue;
        if (i=FCol)or(j=FRow) then Continue;
        C:=Fgrid.Celda[i,j];
        if (c<>nil)and(C^.Text='') then
          DrawCell(i,j, CellRect(i,j), gds);
      end;
    // Draw Cells not Empty (Text<>'')
    For i:=Left to Right do
      For j:=Top to Bottom do begin
        if IsCellSelected(i,j) then Continue;
        C:=Fgrid.Celda[i,j];
        if (C<>nil)and(C^.Text<>'') then
          DrawCell(i,j, CellRect(i,j), gds);
      end;

    gds:=[gdSelected];
    For i:=Left To Right do
      For j:=Top to Bottom do
        if IsCellSelected(i,j) then begin
          DrawCell(i,j, CellRect(i,j), gds);
        end;

  end else inherited DrawInteriorCells;
end;
*)

procedure TStringGrid.SelectEditor;
begin
  if goEditing in Options then Editor:=fDefEditor;
  inherited SelectEditor;
end;

procedure TStringGrid.SetEditText(aCol, aRow: Longint; const aValue: string);
begin
  if Cells[aCol, aRow]<>aValue Then Cells[aCol, aRow]:= aValue;
  inherited SetEditText(aCol, aRow, aValue);
end;

constructor TStringGrid.Create(AOWner: TComponent);
begin
  inherited Create(AOWner);
  if not (csDesigning in componentState) then begin
    FDefEditor:=TStringCellEditor.Create(nil);
    FDefEditor.Name:='Default_StringCellEditor';
    FDefEditor.Text:='';
    FDefEditor.Visible:=False;
    FDefEditor.Align:=alNone;
  end else begin
    FDefEditor:=nil;
  end;
  Canvas.TextStyle.Alignment:=taLeftJustify;
  Canvas.TextStyle.Layout:=tlCenter;
  //Canvas.TextStyle.Wordbreak:=false;
  Canvas.TextStyle.Clipping:=True;
end;

destructor TStringGrid.Destroy;
begin
  {$Ifdef dbg}WriteLn('TStringGrid.Destroy');{$Endif}
  if FdefEditor<>nil then begin
    FDefEDitor.Parent:=nil;
    FreeThenNil(FDefEditor);
  end;
  inherited Destroy;
end;


procedure Register;
begin
  RegisterComponents('Additional',[TStringGrid,TDrawGrid]);
end;

end.

{  The_Log
VERSION: 0.8.6:
----------------
Date: 20-Dic-2003
- Added GetEditText, GetEditMask, SetEditText and events OnGetEditText, OnGetEditMask, OnSetEditText
- Added ColWidths and RowHeights lfm storing
- Changed Default CellEditor from TCustomEdit to TCustomMaskEdit
- Added Test StringGridEditor (enabled with -dWithGridEditor)

VERSION: 0.8.5:
----------------
Date: 15-Sept-2003
- TCustomGrid is derived from TCustomControl instead of TScrollingWinControl
  means that:
  * No more transparent grid at design time
  * No more HorzScrolLBar and VertScrollbar in Object inspector
  * HorzScrollbar and VertScrollbar doesn't exists anymore
  * Scrollbar is handled with setscrollinfo or through the new ScrollbarXXXX
     protected methods.
- TDrawGrid attribute support was removed and added to a new TStringGrid derivated
  component.
- Removed CanSelect, OnCanSelect, TOnCanSelectEvent now it uses SelectCell
  OnSelectCell and TOnSelectCell.
- Implemented Auto edit mode (Typing something will show editor)
- Implemented EditorMode


VERSION: 0.8.4:
---------------
Date: 21-JAN-2003
- Moved log to the end of file
- Editor should be set in OnSelectEditor or SelectEditor in descendants.
- Added SkipUnselectable, this allow the seleccion [using UP,DOWN,LEFT,TOP,
  TABS (if goTabs)] select the next selectable cell.
- Fixed goAlwaysShowEditor
- Fixed bug (gtk-CRITICAL) when destroying the grid and the editor is visible
- Fixed bug selecting a partial visible cell while the grid is scrolled
- missing: tabb from the grid, and Shift-Tab in goTabs mode.



VERSION: 0.8.3
---------------
CHANGES   - Better Editor Support
            Renamed Editor functions
            Editors uses .Dispatch instead of .Perform
            Introduced EditorOptions:
            EO_AUTOSIZE  = Let the grid automatically resize the editor
            EO_HOOKKEYS  = Let the grid process known keydows first
            EO_HOOKEXIT  = Let the grid handle the focus
            EO_SELECTALL = Editor wants to receive SelectAll msg on Key RETURN
            EO_WANTCHAR  = Editor wants to Preview Keys on the grid (soon)
            EO_GETSETVAL = Editor wants to receive GetValue,SetValue msgs (soon)
            This Options should be set in GM_SETGRID message (msg.Options:= ..)

          - Deleted Scr1 Conditional

FIXES     Painting and Crashes at desing time

TODOS     Better editor Support
          TCustomgrid Inherited from TCustomControl to get rid of
            - published VertScrollBar
            - published HorzScrollBar
            - published AutoScroll
            - translucid look at design time?
          Detect ReadOnly grid in editors
          Detect changes in the grid.
          Column Resizing at design time
          ...


VERSION: 0.8.2
---------------
CHANGES		Demo Program

			Too many internal changes to be listed, scrollbars are now
			proportional to client/grid sizes (with goSmoothScroll option
			and almost proptional without it), removed OnEditor, etc.

ADDED		goSmoothScroll. (default) allows scroll the grid by pixel basis
            goThumbTracking. The grid acts always as if this is set, the
			  value is ignored due to current implementation, however if
			  the user set it explicitly then, when the user is scrolling,
			  the focused cell will be following the scroll position.
			goTabs.
			goAlwaysShowEditor. Still need some working

NEW			AutoAdvance. Choose where the next cell position should go
              if a RETURN or TABS(if enabled) is pressed

			  aaRight. Selected cell will go to the right
			  aaDown.  Selected cell will go to down

BUGS		goEditing:
			  - pressing RETURN doesn't edit the current cell
			  - pressing other keys doesn't start editing (need F2)
			goTabs:
			  - Shift-TAB doesn't work
			goAlwaysShowEditor:
			  - Still working :)
			...


VERSION: 0.8.1
---------------
DATE: 28-DEC-2002

CHANGES -- Continued migrating properties from TCustomGrid to TDrawGrid
	   (onCellAttr, DefaultCellAttr, FixedColor, etc.)

FIXES   -- FGrid in TDrawGrid was not destroyed
        -- goEditing now works. I mean, you can now stop showing the
	   editor at F2 (although editor needs more work)
           Default cell editor
	-- DefaultEditor parent is now TStringGrid
	-- Some fpc 1.1 issues (Mattias)


VERSION: 0.8.0
---------------
DATE: 20-DEC-2002

CHANGES Many internal changes (width,height removed from pcellsprop,
        fgrid removed from tcustomgrid, colRowToClientCellRect now
        uses col,row instead of point(col,row), cleaned DynamicArray,
        drawcells splitted in DrawFixedCells, DrawInteriorCells, DrawFocused
        so TStringGrid can implement ordered cell drawin and TCustomGrid
        draw cells is simpler, etc).

ADDED   ExchangeColRow(IsColumn: Boolean; index, WithIndex: Integer);
        DeleteColRow(IsColumn:Boolea; index:Integer);
        MoveColRow(IsColumn: Boolean; FromIndex, ToIndex: Integer);
        SortColRow(IsColumn: Boolean; index: Integer);
        SortColRow(IsColumn: Boolean; index,FromIndex,ToIndex: Integer);
        property OnColRowMoved: TgridOperationEvent
        property OnColRowDeleted: TgridOperationEvents
        property OnColRowExchanged: TgridOperationEvents

ADDED   TcustomGrid derivatives can now replace sort algorithm overriding
        Sort method and using exchangeColRow as needed.


VERSION:  0.7.3
-----------------
DATE: 10-DIC-2002

ADDED goDblClickAutoSize to grid Options, Doubleclicking col's right edge
      automatically adjust column width (in TStringGrid).
      Implemented AutoAdjustColumn() and AutoAdjustColumns.

FIXED col, row increment after grid.clear don't show the grid ( if
      fixed rows-cols = 0 )

ADDED version info to saved grid files.

ADDED NEW DEMO: mysql_query. A program that connects to MySQL and shows query
      results in a grid which you can save and load.


VERSION:  0.7.2
-----------------
DATE: 5-DIC-2002
FIXED a bug that prevents col, and row sizing. MouseDown uses only Left clicks

VERSION:  0.7.1
-----------------
DATE: 3-DIC-2002
ADDED LoadFromFile and SaveToFile to XML file.
  SaveOptions   (soDesign,soPosition,soAttributes,soContent);
  soDesign:     Save & Load ColCount,RowCount,FixedCols,FixedRows,
                ColWidths, RowHeights and Options (TCustomGrid)
  soPosition:   Save & Load Scroll Position, Row, Col and Selection (TCustomGrid)
  soAttributes: Save & Load Colors, Text Alignment & Layout, etc. (TDrawGrid)
  soContent:    Save & Load Text (TStringGrid)

ADDED TCustomgrid.Clear.
                Wipe completly the grid.
ADDED goRelaxedRowSelect option
                You can see focused cell and navigate freely if goRowSelect is
                set.
FIXED Crash on reducing Rowcount


VERSION:  0.7.0
-----------------
RELEASE DATE: 30-NOV-2002

This unit version provides TCustomGrid, TDrawGrid and TStringGrid for lazarus
from the component user perpective there should be to much differences.
This release has only basic editing support.

Old Features:
  Almost all that T*Grid can do.

New Features :

  OnHeaderClick:
              Detect clicks on Row(Column) Headers, it uses a property: DragDx
              as a threshold in order to detect Col(Row) moving or clicking.

  OnCellAttr: In this Event You can easily customize the grid.
  OnDrawCell: Draw your specific cells here and then call .DefaultDrawCell
              to let the grid draw other cells.
  SortColumn,
  SortRow:    Sorting capabilities are built! you need only write one
              OnCompareCells handler to do your custom sorting needs.

  Exposed: DeleteColumn, DeleteRow, MoveColumn, MoveRow.

  RowAttr[],RowColor[],RowFontColor[],RowAlign[]
  ColAttr[],ColColor[],ColFontColor[],ColAlign[]
  CellAttr[],CellColor[],CellFontColor[],CellAlign[]

  GridLineStyle, FocusColor, etc.

Bugs:

  + Editor: it has a unneeded feature "auto cell filling" :)

  others.
}


