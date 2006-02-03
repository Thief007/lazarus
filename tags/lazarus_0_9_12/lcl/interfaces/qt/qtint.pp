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
 *  See the file COPYING.LCL, included in this distribution,                 *
 *  for details about the copyright.                                         *
 *                                                                           *
 *  This program is distributed in the hope that it will be useful,          *
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of           *
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                     *
 *                                                                           *
 *****************************************************************************
}
 
unit qtint;
 
{$mode objfpc} 

interface

{$ifdef Trace}
{$ASSERTIONS ON}
{$endif}
 
uses 
  InterfaceBase, SysUtils, LCLProc, LCLType, LMessages, Classes, Controls,
  ExtCtrls, Forms, Dialogs, StdCtrls, Comctrls, LCLIntf, GraphType,
  qt;

type

  { TQtWidgetSet }

  TQtWidgetSet = Class(TWidgetSet)
  private
  public
    {$I qtwinapih.inc}
    {$I qtlclintfh.inc}
  public
    procedure AppInit(var ScreenInfo: TScreenInfo); override;
    procedure AppRun(const ALoop: TApplicationMainLoop); override;
    procedure AppWaitMessage; override;
    procedure AppProcessMessages; override;
    procedure AppTerminate; override;
    procedure AppMinimize; override;
    procedure AppBringToFront; override;

    function  DCGetPixel(CanvasHandle: HDC; X, Y: integer): TGraphicsColor; override;
    procedure DCSetPixel(CanvasHandle: HDC; X, Y: integer; AColor: TGraphicsColor); override;
    procedure DCRedraw(CanvasHandle: HDC); override;
    procedure SetDesigning(AComponent: TComponent); override;

    function  InitHintFont(HintFont: TObject): Boolean; override;

    // create and destroy
    function CreateComponent(Sender : TObject): THandle; override;
    function CreateTimer(Interval: integer; TimerFunc: TFNTimerProc): integer; override;
    function DestroyTimer(TimerHandle: integer): boolean; override;
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

implementation

uses 
////////////////////////////////////////////////////
// I M P O R T A N T
////////////////////////////////////////////////////
// To get as little as possible circles,
// uncomment only those units with implementation
////////////////////////////////////////////////////
// QtWSActnList,
// QtWSArrow,
// QtWSButtons,
// QtWSCalendar,
// QtWSCheckLst,
// QtWSCListBox,
// QtWSComCtrls,
// QtWSControls,
// QtWSDbCtrls,
// QtWSDBGrids,
// QtWSDialogs,
// QtWSDirSel,
// QtWSEditBtn,
// QtWSExtCtrls,
// QtWSExtDlgs,
// QtWSFileCtrl,
// QtWSForms,
// QtWSGrids,
// QtWSImgList,
// QtWSMaskEdit,
// QtWSMenus,
// QtWSPairSplitter,
// QtWSSpin,
// QtWSStdCtrls,
// QtWSToolwin,
////////////////////////////////////////////////////
  Graphics, buttons, Menus, CListBox;


const

  KEYMAP_VKUNKNOWN = $10000;
  KEYMAP_TOGGLE    = $20000;
  KEYMAP_EXTENDED  = $40000;

procedure EventTrace(message: string; data: pointer);
begin

end;

{$I qtobject.inc}
{$I qtwinapi.inc}
{$I qtcallback.inc}


initialization

finalization

end.
