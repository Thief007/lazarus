{  $Id$  }
{
 /***************************************************************************
                               ExtCtrls.pp
                             -------------------
                             Component Library Extended Controls
                   Initial Revision  : Sat Jul 26 12:04:35 PDT 1999

 ***************************************************************************/

/***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/
}

{
@abstract(Just a try to provide the same objects as the Delphi extctrls unit)
@author(TCustomNotebook, TNotebook - Curtis White <cwhite@aracnet.com>)
@author(TTimer - Stefan Hille (stoppok@osibisa.ms.sub.org))
@created(26 Jul 1999)
@lastmod(28 Jul 1999)

Extctrls contains only few class defintions at the moment and is very
incomplete.
}

unit ExtCtrls;

{$mode objfpc}
{$H+}

interface

{$ifdef Trace}
{$ASSERTIONS ON}
{$endif}

uses
  SysUtils, Classes, Controls, stdCtrls, vclGlobals, lMessages;

type
  { workaround problem with fcl }
  TAbstractReader = TReader;
  
  { TTabPosition - Move to TTabbedNotebook when it is created }
  TTabPosition = (tpTop, tpBottom, tpLeft, tpRight);

  { TPage }
  {
    @abstract(Pages for Notebooks and TabbedNotebooks.)
    Introduced and (currently) maintained by Curtis White
  }


  TPage = class(TCustomControl)
  private
  protected
    procedure AttachSignals; override;
    procedure ReadState(Reader: TAbstractReader); override;
    procedure Paint; override;
  public
    procedure AddControl; override;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Caption;
    //property Height;
    // property TabOrder;     This property needs to be created in TWinControl
    property Visible;
    //property Width;
  end;

  TCustomNotebook = class;

  { TNBPages }
  {
    @abstract(Notebook page access class to provide access to notebook pages.)
    Introduced and (currently) maintained by Curtis White
  }
  TNBPages = class(TStrings)
  private
    fPageList: TList;
    fNotebook: TCustomNotebook;
  protected
    function Get(Index: Integer): String; override;
    function GetCount: Integer; override;
    function GetObject(Index: Integer): TObject; override;
    procedure Put(Index: Integer; const S: String); override;
  public
    constructor Create(thePageList: TList; theNotebook: TCustomNotebook);
    procedure Clear; override;
    procedure Delete(Index: Integer); override;
    procedure Insert(Index: Integer; const S: String); override;
    procedure InsertPage(Index:integer; APage: TPage);

    procedure Move(CurIndex, NewIndex: Integer); override;
  end;

  { TCustomNotebook }
  {
    @abstract(Base class for TNotebook and TTabbedNotebook.)
    Introduced and (currently) maintained by Curtis White
  }
  TCustomNotebook = class(TCustomControl)
  private
    fPageList: TList;  // TList of TPage
    fAccess: TStrings; // TNBPages
    fPageIndex: Integer;
    fOnPageChanged: TNotifyEvent;

    { Extra variables not in Delphi }
    fShowTabs: Boolean;
    fTabPosition: TTabPosition;

    function GetActivePage: String;
    function GetPageIndex: Integer;
    procedure SetActivePage(const Value: String);
    procedure SetPageIndex(Value: Integer);
    procedure SetPages(Value: TStrings);
    Procedure CNNotify(var Message : TLMNotify); message CN_NOTIFY;
    { Extra private methods not in Delphi }
    function GetPage(aIndex: Integer): TPage;
    procedure SetShowTabs(Value: Boolean);
    procedure SetTabPosition(tabPos: TTabPosition);
  protected
    procedure CreateParams(var Params: TCreateParams);override;
    procedure CreateWnd; override;
    procedure Change; virtual;
    function GetChildOwner: TComponent; override;
    procedure GetChildren(Proc: TGetChildProc; Root: TComponent); override;
    procedure ReadState(Reader: TAbstractReader); override;
    procedure ShowControl(AControl: TControl); override;

    property ActivePage: String read GetActivePage write SetActivePage;
    property PageIndex: Integer read GetPageIndex write SetPageIndex default 0;
    property Pages: TStrings read fAccess write SetPages;
    property OnPageChanged: TNotifyEvent read fOnPageChanged write fOnPageChanged;

    { Extra properties not in Delphi - Move to TabbedNotebook when it is created }
    property Page[Index: Integer]: TPage read GetPage;
    property PageList: TList read fPageList;
    property ShowTabs: Boolean read fShowTabs write SetShowTabs;
    property TabPosition: TTabPosition read fTabPosition write SetTabPosition;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property Name;
  end;

  { TNotebook }
  {
    @abstract(A Delphi style TNotebook.)
    Introduced and (currently) maintained by Curtis White
  }
  TNotebook = class(TCustomNotebook)
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property Page;
    property Pages;
  published
    property ActivePage;
    property PageIndex;
    property PageList;
    property OnPageChanged;
  end;


 {
   @abstract(A free running timer.)
   Introduced and (currently) maintained by Stefan Hille (stoppok@osibisa.ms.sub.org)
 }
 TTimer = class (TComponent)
 private
   FInterval     : Cardinal;
   FTimerID      : integer;
   FOnTimer      : TNotifyEvent;
   FEnabled      : Boolean;
   procedure UpdateTimer;
   procedure SetEnabled(Value: Boolean);
   procedure SetInterval(Value: Cardinal);
   procedure SetOnTimer(Value: TNotifyEvent);
   procedure KillTimer;
 protected
   procedure Timer (var msg); message LM_Timer;
 public
   constructor Create(AOwner: TComponent); override;
   destructor Destroy; override;
 published
   property Enabled: Boolean read FEnabled write SetEnabled default True;
   property Interval: Cardinal read FInterval write SetInterval default 1000;
   property OnTimer: TNotifyEvent read FOnTimer write SetOnTimer;
 end;

  TPaintBox = class(TGraphicControl)
  private
    FOnPaint: TNotifyEvent;
  protected
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;
    property Canvas;
  published
    property Align;
//    property Anchors;
    property Color;
//    property Constraints;
//    property DragCursor;
//    property DragKind;
//    property DragMode;
//    property Enabled;
    property Font;
    property ParentColor;
    property ParentFont;
//    property ParentShowHint;
//    property PopupMenu;
//    property ShowHint;
    property Visible;
    property OnClick;
//    property OnDblClick;
//    property OnDragDrop;
//    property OnDragOver;
//    property OnEndDock;
//    property OnEndDrag;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnPaint: TNotifyEvent read FOnPaint write FOnPaint;
//    property OnStartDock;
//    property OnStartDrag;
  end;

  TBevelStyle=(bsLowered, bsRaised);
  TBevelShape=(bsBox, bsFrame, bsTopLine, bsBottomLine, bsLeftLine, bsRightLine);
  TBevel=Class(TGraphicControl)
  private
     FStyle:TBevelStyle;
     FShape:TBevelShape;
     Function GetStyle:TBevelStyle;
     Procedure SetStyle(aStyle:TBevelStyle);
     Function GetShape:TBevelShape;
     Procedure SetShape(aShape:TBevelShape);
  Protected
     Procedure Paint; Override;
  Public
     Constructor Create(AOwner:TComponent); override;
     Destructor Destroy; override;
     Procedure Invalidate; override;
  Published
     Property Height;
     Property Left;
     Property Name;
     Property Shape:TBevelShape Read GetShape Write SetShape Default bsBox;
     Property Top;
     Property Style:TBevelStyle Read GetStyle Write SetStyle Default bsLowered;
     Property Visible;
     Property Width;
  End;

  {
    @abstract(Base class for TRadioGroup.)
    (currently) maintained by Stefan Hille (stoppok@osibisa.ms.sub.org)
  }
  TCustomRadioGroup = class(TCustomGroupBox)
  public
    constructor Create (AOwner : TComponent); override;
    destructor Destroy; override;
    function CanModify : boolean; virtual;
    procedure CreateWnd; override;
  private
    FButtonList : TList;
    FItems      : TStrings;
    FItemIndex  : integer;
    FColumns    : integer;
    FReading    : boolean;
    FOnClick    : TNotifyEvent;
    procedure ItemsChanged (Sender : TObject);
    procedure Clicked(Sender : TObject); virtual;
  protected
    procedure ReadState(Reader: TReader); override;
    procedure SetItem (value : TStrings);
    procedure SetColumns (value : integer);
    procedure SetItemIndex (value : integer);
    function GetItemIndex : integer;
    property ItemIndex : integer read GetItemIndex write SetItemIndex default -1;
    property Items : TStrings read FItems write SetItem;
    property Columns : integer read FColumns write SetColumns default 1;
    property OnClick : TNotifyEvent read FOnClick write FOnClick;
  end;

  {
    @abstract(Group of radiobuttons.)
    (currently) maintained by Stefan Hille (stoppok@osibisa.ms.sub.org)
  }
  TRadioGroup = class(TCustomRadioGroup)
  public
     constructor Create (AOwner : TComponent); override;
  published
     property Align;
     property Caption;
     property Enabled;
     property ItemIndex;
     property Items;
     property Columns;
     property Visible;
     property OnClick;
  end;

const
TCN_First = 0-550;
TCN_SELCHANGE = TCN_FIRST - 1;

implementation

 uses Graphics, interfaces;

{$I page.inc}
{$I customnotebook.inc}
{$I notebook.inc}
{$I timer.inc}
{$I paintbox.inc}
{$I customradiogroup.inc}
{$I radiogroup.inc}
{$I bevel.inc}

end.

 {
  $Log$
  Revision 1.11  2001/06/12 18:31:01  lazarus
  MG: small bugfixes

  Revision 1.10  2001/04/17 21:39:17  lazarus
  + added working OnClick support for TCustomRadiogroup, stoppok

  Revision 1.9  2001/04/06 22:28:09  lazarus
  * TTimer uses winapi interface now instead of sendmessage interface, stoppok

  Revision 1.8  2001/03/15 14:42:20  lazarus
  MG: customradiogroup is now streamable

  Revision 1.7  2001/01/12 18:27:31  lazarus
  Streaming additions by MAttias
  Shane

  Revision 1.6  2001/01/09 21:06:06  lazarus
  Started taking KeyDown messages in TDesigner
  Shane

  Revision 1.5  2001/01/09 18:23:20  lazarus
  Worked on moving controls.  It's just not working with the X and Y coord's I'm getting.
  Shane

  Revision 1.4  2001/01/05 18:56:23  lazarus
  Minor changes

  Revision 1.3  2001/01/04 20:33:53  lazarus
  Moved lresources.
  Moved CreateLFM to Main.pp
  Changed Form1 and TFOrm1 to MainIDE and TMainIDE
  Shane

  Revision 1.2  2000/12/29 15:04:07  lazarus
  Added more images to the resource.
  Shane

  Revision 1.1  2000/07/13 10:28:23  michael
  + Initial import

  Revision 1.25  2000/06/29 21:06:14  lazarus
  reintroduced TAbstractReader=Treader hack, stoppok

  Revision 1.24  2000/06/28 13:11:37  lazarus
  Fixed TNotebook so it gets page change events.  Shane

  Revision 1.23  2000/05/08 23:59:52  lazarus
  Updated my email address in the documentation to the current one. Also
  removed email references in comments that were not @author comments to
  fix problems with the documentation produced by pasdoc.           CAW

  Revision 1.22  2000/02/26 23:31:50  lazarus
  MWE:
    Fixed notebook crash on insert
    Fixed loadfont problem for win32 (tleast now a fontname is required)

  Revision 1.21  2000/01/10 19:09:18  lazarus
  MWE:
    Removed temp hack TAbstractReader=TReader. It is now defined

  Revision 1.20  2000/01/10 00:07:12  lazarus
  MWE:
    Added more scrollbar support for TWinControl
    Most signals for TWinContorl are jet connected to the wrong widget
      (now scrolling window, should be fixed)
    Added some cvs entries

  Revision 1.19  2000/01/07 21:14:13  lazarus
  Added code for getwindowlong and setwindowlong.
  Shane

  Revision 1.18  2000/01/06 01:10:36  lazarus
  Stoppok:
     - changed ReadState to match current definition in fcl
       (affects TPage & TCustomNotebook)
     - added callback FItems.OnChanging to TCustomRadiogroup

  Revision 1.17  2000/01/02 00:22:54  lazarus
  stoppok:
    - introduced TBevel
    - enhanced TCustomRadioGroup

  Revision 1.16  1999/12/31 02:20:57  lazarus
    Initial implementation of TCustomRadioGroup / TRadioGroup
      stoppok

  Revision 1.15  1999/11/01 01:28:29  lazarus
  MWE: Implemented HandleNeeded/CreateHandle/CreateWND
       Now controls are created on demand. A call to CreateComponent shouldn't
       be needed. It is now part of CreateWnd

  Revision 1.14  1999/10/22 21:01:50  lazarus

        Removed calls to InterfaceObjects except for controls.pp. Commented
        out any gtk depend lines of code.     MAH

  Revision 1.13  1999/10/19 19:16:51  lazarus
  renamed stdcontrols.pp stdctrls.pp
  Shane

  Revision 1.12  1999/10/04 23:36:25  lazarus
  Moved PageList and Page property to public to allow access to them.   CAW

  Revision 1.11  1999/09/30 21:59:01  lazarus
  MWE: Fixed TNoteBook problems
       Modifications: A few
       - Removed some debug messages
       + Added some others
       * changed fixed widged of TPage. Code is still broken.
       + TWinControls are also added to the Controls collection
       + Added TControl.Controls[] property

  Revision 1.10  1999/09/22 19:09:17  lazarus
  Added some trace info for the TNotebook problem.

  Revision 1.9  1999/09/21 23:46:54  lazarus
  *** empty log message ***

  Revision 1.8  1999/09/16 21:14:27  lazarus
    Some cleanups to the timer class. (moved some comments to timer.inc,
    added more comments and changed TTimer.Timer from function to procedure)
      Stoppok

  Revision 1.7  1999/09/13 03:27:10  lazarus
  Fixed a bug in the PageIndex property of TCustomNotebook where
  it was not tracking notebook pages if the user selected them
  with the mouse in a TTabbedNotebook.                               caw

  Revision 1.6  1999/08/26 23:36:02  peter
    + paintbox
    + generic keydefinitions and gtk conversion
    * gtk state -> shiftstate conversion

  Revision 1.5  1999/08/04 05:21:11  lazarus
  Created TCustomNotebook to allow both TNotebook and TTabbedNotebook to
  inherit from a common object. Made TNotebook work like Delphi TNotebook.

  Revision 1.3  1999/07/31 06:39:22  lazarus

       Modified the IntSendMessage3 to include a data variable. It isn't used
       yet but will help in merging the Message2 and Message3 features.

       Adjusted TColor routines to match Delphi color format

       Added a TGdkColorToTColor routine in gtkproc.inc

       Finished the TColorDialog added to comDialog example.        MAH

 }
