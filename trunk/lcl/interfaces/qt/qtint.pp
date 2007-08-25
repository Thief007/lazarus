{ $Id$ }
{ 
 /*************************************************************************** 
                         QTINT.pp  -  QTInterface Object
                             ------------------- 
 
                   Initial Revision  : Thu July 1st CST 1999 
 
 
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
 
unit qtint;
 
{$mode objfpc}{$H+}

interface

{$ifdef Trace}
{$ASSERTIONS ON}
{$endif}
 
uses 
  // Bindings - qt4 must come first to avoid type redefinition problems
{$ifdef USE_QT_4_3}
  qt43,
{$else}
  qt4,
{$endif}
  // FPC
  Classes, SysUtils, Math, Types,
  // LCL
  InterfaceBase, LCLProc, LCLType, LMessages, LCLMessageGlue, Controls, ExtCtrls, Forms,
  Dialogs, StdCtrls, Comctrls, LCLIntf, GraphType, Themes,
  Arrow, CheckLst,
  // WS
  qtproc;

type

  { TQtWidgetSet }

  TQtWidgetSet = Class(TWidgetSet)
  private
    App: QApplicationH;
    SavedDCList: TList;
  protected
    FStockNullBrush: HBRUSH;
    FStockBlackBrush: HBRUSH;
    FStockLtGrayBrush: HBRUSH;
    FStockGrayBrush: HBRUSH;
    FStockDkGrayBrush: HBRUSH;
    FStockWhiteBrush: HBRUSH;

    FStockNullPen: HPEN;
    FStockBlackPen: HPEN;
    FStockWhitePen: HPEN;
    FStockSystemFont: HFONT;
    FStockDefaultDC: HDC;
    
    function CreateThemeServices: TThemeServices; override;
  public
    function LCLPlatform: TLCLPlatform; override;
    // Application
    procedure AppInit(var ScreenInfo: TScreenInfo); override;
    procedure AppRun(const ALoop: TApplicationMainLoop); override;
    procedure AppWaitMessage; override;
    procedure AppProcessMessages; override;
    procedure AppTerminate; override;
    procedure AppMinimize; override;
    procedure AppRestore; override;
    procedure AppBringToFront; override;
    procedure AppSetTitle(const ATitle: string); override;
  public
    constructor Create;
    destructor Destroy; override;

    function  DCGetPixel(CanvasHandle: HDC; X, Y: integer): TGraphicsColor; override;
    procedure DCSetPixel(CanvasHandle: HDC; X, Y: integer; AColor: TGraphicsColor); override;
    procedure DCRedraw(CanvasHandle: HDC); override;
    procedure SetDesigning(AComponent: TComponent); override;

    function  InitHintFont(HintFont: TObject): Boolean; override;

    // create and destroy
    function CreateComponent(Sender : TObject): THandle; override; // deprecated
    function CreateTimer(Interval: integer; TimerFunc: TFNTimerProc): THandle; override;
    function DestroyTimer(TimerHandle: THandle): boolean; override;

    // device contexts
    function IsValidDC(const DC: HDC): Boolean; virtual;
    function IsValidGDIObject(const GDIObject: HGDIOBJ): Boolean; virtual;
  public
    function CreateDefaultFont: HFONT; virtual;
    function GetQtDefaultDC: HDC; virtual;
    procedure DeleteDefaultDC; virtual;
		procedure SetQtDefaultDC(Handle: HDC); virtual;
    procedure InitStockItems; virtual;
    procedure FreeStockItems; virtual;

    {$I qtwinapih.inc}
    {$I qtlclintfh.inc}
  end;


type
  TEventProc = record
    Name : String[25];
    CallBack : Procedure(Data : TObject);
    Data : Pointer;
  End;

  CallbackProcedure = Procedure (Data : Pointer);

  pTRect = ^TRect;

  procedure EventTrace(message : string; data : pointer);


const
   TargetEntrys = 3;

var
  QtWidgetSet: TQtWidgetSet;

implementation

uses 
////////////////////////////////////////////////////
// I M P O R T A N T
////////////////////////////////////////////////////
// To get as little as possible circles,
// uncomment only those units with implementation
////////////////////////////////////////////////////
// QtWSActnList,
 QtWSArrow,
 QtWSButtons,
 QtWSCalendar,
 QtWSCheckLst,
// QtWSCListBox,
 QtWSComCtrls,
 QtWSControls,
// QtWSDbCtrls,
// QtWSDBGrids,
 QtWSDialogs,
// QtWSDirSel,
// QtWSEditBtn,
 QtWSExtCtrls,
// QtWSExtDlgs,
// QtWSFileCtrl,
 QtWSForms,
// QtWSGrids,
// QtWSImgList,
// QtWSMaskEdit,
 QtWSMenus,
// QtWSPairSplitter,
 QtWSSpin,
 QtWSStdCtrls,
// QtWSToolwin,
 QtCaret,
 QtThemes,
////////////////////////////////////////////////////
  Graphics, buttons, Menus,
  // Bindings
  qtprivate, qtwidgets, qtobjects;


const
  KEYMAP_VKUNKNOWN = $10000;
  KEYMAP_TOGGLE    = $20000;
  KEYMAP_EXTENDED  = $40000;
  
function QtObjectFromWidgetH(const WidgetH: QWidgetH): TQtWidget;
var
  V: QVariantH;
  Ok: Boolean;
  QtWg: TQtWidget;
begin
  Result := nil;
  V := QVariant_Create();
  try
    QObject_property(QObjectH(WidgetH), V, 'lclwidget');
    if not QVariant_IsNull(v) and QVariant_isValid(V) then
    begin
      //Write('Got a valid variant .. ');
{$IFDEF CPU32}
      QtWg := TQtWidget(QVariant_toUint(V, @Ok));
{$ENDIF}
{$IFDEF CPU64}
      QtWg := TQtWidget(QVariant_toULongLong(V, @Ok));
{$ENDIF}
      if OK then
      begin
        //Write('Converted successfully, Control=');
        if QtWg<>nil then
        begin
          Result := QtWg;
          //WriteLn(Result.LCLObject.Name);
        end else
          ;//WriteLn('nil');
      end else
        ;//WriteLn('Can''t convert to UINT');
    end else
      ;//Writeln('GetFocus: Variant is NULL or INVALID');
  finally
    QVariant_Destroy(V);
  end;
end;

procedure EventTrace(message: string; data: pointer);
begin

end;

{$I qtobject.inc}
{$I qtwinapi.inc}
{$I qtlclintf.inc}
{.$I qtcallback.inc}


initialization

finalization

end.
