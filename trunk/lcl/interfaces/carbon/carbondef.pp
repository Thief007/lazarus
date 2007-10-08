{ $Id$
                    -----------------------------------------
                    carbondef.pp  -  Type & Const definitions
                    -----------------------------------------

 @created(Wed Aug 26st WET 2005)
 @lastmod($Date$)
 @author(Marc Weustink <marc@@lazarus.dommelstein.net>)

 This unit contains type & const definitions needed in the Carbon <-> LCL interface

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


unit CarbonDef;

{$mode objfpc}{$H+}

interface

// debugging defines
{$I carbondebug.inc}

uses
  // libs
  FPCMacOSAll,
  // wdgetset
  WSLCLClasses, LCLClasses,
  // LCL + RTL
  Types, Classes, SysUtils, Controls, LCLType, LCLProc, Graphics, Math, AVL_Tree,
  LMessages, LCLMessageGlue;

var
  LAZARUS_FOURCC: FourCharCode;    // = 'Laz ';
  WIDGETINFO_FOURCC: FourCharCode; // = 'WInf';
  MENU_FOURCC: FourCharCode;       // = 'Menu';

type

  { TCarbonContext }

  TCarbonContext = class
  public
    CGContext: CGContextRef;
    constructor Create;
    procedure Reset; virtual; abstract;
  end;

  { TCarbonWidget }
  
  TCarbonWidget = class
  private
    FProperties: TStringList;
    FCursor: HCURSOR;
    function GetProperty(AIndex: String): Pointer;
    procedure SetProperty(AIndex: String; const AValue: Pointer);
  protected
    procedure RegisterEvents; virtual; abstract;
    procedure CreateWidget(const AParams: TCreateParams); virtual; abstract;
    procedure DestroyWidget; virtual; abstract;
    function GetContent: ControlRef; virtual; abstract;
  public
    LCLObject: TWinControl;  // LCL control which created this widget
    Context: TCarbonContext; // Carbon content area context
    Widget: Pointer;         // Reference to the Carbon window or control
  public
    constructor Create(const AObject: TWinControl; const AParams: TCreateParams);
    destructor Destroy; override;
    procedure AddToWidget(AParent: TCarbonWidget); virtual; abstract;
    procedure BoundsChanged; virtual;
    function GetClientRect(var ARect: TRect): Boolean; virtual; abstract;
    function GetPreferredSize: TPoint; virtual;
    function GetMousePos: TPoint; virtual; abstract;
    function GetTopParentWindow: WindowRef; virtual; abstract;
    procedure Invalidate(Rect: PRect = nil); virtual; abstract;
    procedure InvalidateRgn(AShape: HISHapeRef);
    function IsEnabled: Boolean; virtual; abstract;
    function IsVisible: Boolean; virtual; abstract;
    function Enable(AEnable: Boolean): Boolean; virtual; abstract;
    
    procedure GetScrollInfo(SBStyle: Integer; var ScrollInfo: TScrollInfo); virtual;
    function GetBounds(var ARect: TRect): Boolean; virtual; abstract;
    function GetScreenBounds(var ARect: TRect): Boolean; virtual; abstract;
    function SetBounds(const ARect: TRect): Boolean; virtual; abstract;
    procedure SetChildZPosition(AChild: TCarbonWidget; const AOldPos, ANewPos: Integer; const AChildren: TFPList); virtual; abstract;
    procedure SetCursor(ACursor: HCURSOR); virtual;
    
    procedure ScrollBy(DX, DY: Integer); virtual;
    procedure SetFocus; virtual; abstract;
    procedure SetColor(const AColor: TColor); virtual; abstract;
    function SetScrollInfo(SBStyle: Integer; const ScrollInfo: TScrollInfo): Integer; virtual;
    procedure SetFont(const AFont: TFont); virtual; abstract;
    procedure ShowHide(AVisible: Boolean); virtual; abstract;
    
    function GetText(var S: String): Boolean; virtual; abstract;
    function SetText(const S: String): Boolean; virtual; abstract;
    function Update: Boolean; virtual; abstract;
  public
  { Content:
     = widget in controls without special client control
     - client area control of control or window
     - origin of local coordinates
     - area for embedding child controls
     - processes track and draw event                  }
    property Content: ControlRef read GetContent;
    property Cursor: HCURSOR read FCursor;
    property Properties[AIndex: String]: Pointer read GetProperty write SetProperty;
  end;
  
type
  TCarbonEventHandlerProc = function (ANextHandler: EventHandlerCallRef;
    AEvent: EventRef;
    AWidget: TCarbonWidget): OSStatus; {$IFDEF darwin}mwpascal;{$ENDIF}

  TEventInt = packed record
    case Integer of
    1: (Chars: array[0..4] of Char);
    2: (Int: FPCMacOSAll.UInt32);
  end;
  
const
  LCLCarbonEventClass    = 'Laz ';
  LCLCarbonEventKindWake = 'Wake';
  LCLCarbonEventKindMain = 'Main';

function CheckHandle(const AWinControl: TWinControl; const AClass: TClass; const DbgText: String): Boolean;
function CheckWidget(const Handle: HWND; const AMethodName: String; AParamName: String = ''): Boolean;
function CheckWidget(const Handle: HWND; const AMethodName: String; AClass: TClass): Boolean;

function RegisterEventHandler(AHandler: TCarbonEventHandlerProc): EventHandlerUPP;

implementation

uses
  CarbonProc, CarbonDbgConsts, CarbonUtils;

{------------------------------------------------------------------------------
  Name:    CheckHandle
  Params:  AWinControl  - Handle of window
           AClass       - Class
           DbgText      - Text to output on invalid DC
  Returns: If the wincontrol handle is allocated and valid
 ------------------------------------------------------------------------------}
function CheckHandle(const AWinControl: TWinControl; const AClass: TClass;
  const DbgText: String): Boolean;
begin
   if AWinControl <> nil then
  begin
    if TObject(AWinControl.Handle) is TCarbonWidget then
    begin
      {$IFDEF VerboseWSClass}
        DebugLn(AClass.ClassName + '.' + DbgText + ' for ' + AWinControl.Name);
      {$ENDIF}

      Result := True;
    end
    else
    begin
      Result := False;
      DebugLn(AClass.ClassName + '.' + DbgText + ' for ' + AWinControl.Name +
        ' failed: Handle ' + DbgS(Integer(AWinControl.Handle)) + ' is invalid!');
    end;
  end
  else
  begin
    Result := False;
    DebugLn(AClass.ClassName + '.' + DbgText + ' for ' + AWinControl.Name +
      ' failed: WinControl is nil!');
  end;
end;

{------------------------------------------------------------------------------
  Name:    CheckWidget
  Params:  Handle      - Handle of window
           AMethodName - Method name
           AParamName  - Param name
  Returns: If the window is valid widget
 ------------------------------------------------------------------------------}
function CheckWidget(const Handle: HWND; const AMethodName: String;
  AParamName: String): Boolean;
begin
  if TObject(Handle) is TCarbonWidget then Result := True
  else
  begin
    Result := False;

    if Pos('.', AMethodName) = 0 then
      DebugLn(SCarbonWSPrefix + AMethodName + ' Error - invalid widget ' +
        AParamName + ' = ' + DbgS(Handle) + '!')
    else
      DebugLn(AMethodName + ' Error - invalid widget ' + AParamName + ' = ' +
        DbgS(Handle) + '!');
  end;
end;

{------------------------------------------------------------------------------
  Name:    CheckWidget
  Params:  Handle      - Handle of window
           AMethodName - Method name
           AClass      - Class
  Returns: If the window is valid widget and class
 ------------------------------------------------------------------------------}
function CheckWidget(const Handle: HWND; const AMethodName: String;
  AClass: TClass): Boolean;
var
  S: String;
begin
  if TObject(Handle) is TCarbonWidget then
  begin
    if TObject(Handle) is AClass then
    begin
      Result := True;
      Exit;
    end;
    
    S := ' Error - Widget ' + TObject(Handle).ClassName + ' is not ' +
      AClass.ClassName + '!';
  end
  else S := ' Error - Handle ' + DbgS(Handle) + ' is not valid widget!';
  
  Result := False;
  
  if Pos('.', AMethodName) = 0 then
    DebugLn(SCarbonWSPrefix + AMethodName + S)
  else
    DebugLn(AMethodName + S);
end;

//=====================================================
// UPP mamanger
//=====================================================
type
  TUPPAVLTreeNode = class(TAVLTreeNode)
  public
    UPP: EventHandlerUPP;
    procedure Clear; reintroduce; // not overridable, so reintroduce since we only will call this clear
    destructor Destroy; override;
  end;

var
  UPPTree: TAVLTree = nil;

procedure TUPPAVLTreeNode.Clear;
begin
  if UPP <> nil then
  begin
    DisposeEventHandlerUPP(UPP);
    UPP := nil;
  end;

  inherited Clear;
end;

destructor TUPPAVLTreeNode.Destroy;
begin
  if UPP <> nil then
  begin
    DisposeEventHandlerUPP(UPP);
    UPP := nil;
  end;

  inherited Destroy;
end;

{------------------------------------------------------------------------------
  Name:    RegisterEventHandler
  Params:  AHandler - Carbon event handler procedure
  Returns: Event handler UPP

  Registers new carbon event handler procedure
 ------------------------------------------------------------------------------}
function RegisterEventHandler(AHandler: TCarbonEventHandlerProc): EventHandlerUPP;
var
  Node: TUPPAVLTreeNode;
begin
  if UPPTree = nil then UPPTree := TAVLTree.Create;

  Node := TUPPAVLTreeNode(UPPTree.Find(AHandler));
  if Node = nil then
  begin
    Node := TUPPAVLTreeNode.Create;
    Node.Data := AHandler;
    Node.UPP := NewEventHandlerUPP(EventHandlerProcPtr(AHandler));
    UPPTree.Add(Node);
  end;

  Result := Node.UPP;
end;
  
{ TCarbonContext }

constructor TCarbonContext.Create;
begin
  inherited;

  CGContext := nil;
end;
  
{ TCarbonWidget }

{------------------------------------------------------------------------------
  Method:  TCarbonWidget.GetProperty
  Params:  AIndex - Property name
  Returns: Property data, nil if the property is not listed

  Returns the specified property data or nil if the property is not listed
 ------------------------------------------------------------------------------}
function TCarbonWidget.GetProperty(AIndex: String): Pointer;
var
  I: Integer;
begin
  if FProperties <> nil then
  begin
    I := FProperties.IndexOf(AIndex);
    
    if I >= 0 then // the property is listed
    begin
      Result := FProperties.Objects[I];
      Exit;
    end;
  end;
  Result := nil;
end;

{------------------------------------------------------------------------------
  Method:  TCarbonWidget.SetProperty
  Params:  AIndex - Property name
           AValue - Property data, nil means remove the property

  Sets the specified property data or removes the property
 ------------------------------------------------------------------------------}
procedure TCarbonWidget.SetProperty(AIndex: String; const AValue: Pointer);
var
  I: Integer;
begin
  if FProperties = nil then
  begin
    if AValue = nil then Exit;
    // create string list for storing properties
    FProperties := TStringList.Create;
    FProperties.Sorted := True; // to enable binary searching
  end;
  
  I := FProperties.IndexOf(AIndex);
  if I >= 0 then // the property is listed -> update or remove if AValue = nil
  begin
    if AValue = nil then
    begin
      FProperties.Delete(I);
      if FProperties.Count = 0 then
      begin
        FProperties.Free; // free if the list is clear
        FProperties := nil;
      end;
    end
    else FProperties.Objects[I] := TObject(AValue);
  end
  else // the property is not listed -> add
  begin
    FProperties.AddObject(AIndex, TObject(AValue));
  end;
end;

{------------------------------------------------------------------------------
  Method:  TCarbonWidget.BoundsChanged

  Handles bounds change
 ------------------------------------------------------------------------------}
procedure TCarbonWidget.BoundsChanged;
var
{$IFDEF VerboseBounds}
  WidgetClient,
{$ENDIF}
  WidgetBounds, OldBounds: TRect;
  Resized, ClientResized: Boolean;
begin
  {$IFDEF VerboseBounds}
    DebugLn('TCarbonWidget.BoundsChanged ' + LCLObject.Name);
  {$ENDIF}

  GetBounds(WidgetBounds);
  OldBounds := LCLObject.BoundsRect;
  
  {$IFDEF VerboseBounds}
    GetClientRect(WidgetClient);
    DebugLn('TCarbonWidget.BoundsChanged Interface new bounds: ' + DbgS(WidgetBounds));
    DebugLn('TCarbonWidget.BoundsChanged LCL old bounds: ' + DbgS(OldBounds));
    DebugLn('TCarbonWidget.BoundsChanged Interface new client: ' + DbgS(WidgetClient));
    DebugLn('TCarbonWidget.BoundsChanged LCL old client: ' + DbgS(LCLObject.ClientRect));
  {$ENDIF}
  
  Resized := False;
  ClientResized := False;
  
  // then send a LM_SIZE message
  if (OldBounds.Right - OldBounds.Left <> WidgetBounds.Right - WidgetBounds.Left) or
     (OldBounds.Bottom - OldBounds.Top <> WidgetBounds.Bottom - WidgetBounds.Top) then
  begin
    LCLSendSizeMsg(LCLObject, WidgetBounds.Right - WidgetBounds.Left,
      WidgetBounds.Bottom - WidgetBounds.Top, Size_SourceIsInterface);
    
    Resized := True;
  end;
  
  if Resized or LCLObject.ClientRectNeedsInterfaceUpdate then
  begin
    {$IFDEF VerboseBounds}
      DebugLn('TCarbonWidget.BoundsChanged Update client rects cache');
    {$ENDIF}
    LCLObject.InvalidateClientRectCache(True);
    LCLObject.DoAdjustClientRectChange;
    ClientResized := True;
  end;

  // then send a LM_MOVE message
  if (OldBounds.Left <> WidgetBounds.Left) or
     (OldBounds.Top <> WidgetBounds.Top) then
  begin
    LCLSendMoveMsg(LCLObject, WidgetBounds.Left,
      WidgetBounds.Top, Move_SourceIsInterface);
  end;

  // invalidate client area
  if ClientResized then Invalidate;

  // invalidate parent client area, previously covered by control
  if Resized and (LCLObject.Parent <> nil) and LCLObject.Parent.HandleAllocated then
  begin
    TCarbonWidget(LCLObject.Parent.Handle).Invalidate(@OldBounds);
  end;
  
  {$IFDEF VerboseBounds}
    DebugLn('TCarbonWidget.BoundsChanged LCL new bounds: ' + DbgS(LCLObject.BoundsRect));
    DebugLn('TCarbonWidget.BoundsChanged LCL new client: ' + DbgS(LCLObject.ClientRect));
  {$ENDIF}
end;

{------------------------------------------------------------------------------
  Method:  TCarbonWidget.Create
  Params:  AObject - LCL conrol
           AParams - Creation parameters
  Returns: The Carbon widget

  Creates basic widget for the specified LCL control
 ------------------------------------------------------------------------------}
constructor TCarbonWidget.Create(const AObject: TWinControl;
  const AParams: TCreateParams);
begin
  LCLObject := AObject;
  FProperties := nil;
  Widget := nil;
  Context := nil;
  
  CreateWidget(AParams);
  
  {$IFDEF VerboseWidget}
    DebugLn('TCarbonWidget.Create ', ClassName, ' ', LCLObject.Name, ': ',
      LCLObject.ClassName);
  {$ENDIF}
  
  RegisterEvents;
    
  LCLObject.InvalidateClientRectCache(True);
  BoundsChanged;
  
  {$IFDEF VerboseBounds}
    DebugLn('TCarbonWidget.Create LCL bounds: ' + DbgS(LCLObject.BoundsRect));
    DebugLn('TCarbonWidget.Create LCL client: ' + DbgS(LCLObject.ClientRect));
  {$ENDIF}
end;

{------------------------------------------------------------------------------
  Method:  TCarbonWidget.Destroy

  Frees the widget
 ------------------------------------------------------------------------------}
destructor TCarbonWidget.Destroy;
begin
  DestroyWidget;
  
  FProperties.Free;

  {$IFDEF VerboseWidget}
    DebugLn('TCarbonWidget.Destroy ', ClassName, ' ', LCLObject.Name, ': ',
      LCLObject.ClassName);
  {$ENDIF}

  inherited Destroy;
end;

{------------------------------------------------------------------------------
  Method:  TCarbonWidget.GetPreferredSize
  Returns: The preffered size of widget for autosizing or (0, 0)
 ------------------------------------------------------------------------------}
function TCarbonWidget.GetPreferredSize: TPoint;
begin
  Result.X := 0;
  Result.Y := 0;
end;

{------------------------------------------------------------------------------
  Method:  TCarbonWidget.InvalidateRgn
  Params:  AShape - HIShapeRef

  Invalidates the specified client region or entire area
 ------------------------------------------------------------------------------}
procedure TCarbonWidget.InvalidateRgn(AShape: HISHapeRef);
begin
  if AShape = nil then Invalidate
  else
    OSError(HIViewSetNeedsDisplayInShape(Content, AShape, True),
      Self, 'InvalidateRgn', 'HIViewSetNeedsDisplayInShape');
end;

{------------------------------------------------------------------------------
  Method:  TCarbonWidget.GetScrollInfo
  Params:  SBStyle    - Scrollbar type (SB_VERT, SB_HORZ)
           ScrollInfo - Record fo scrolling info
  Returns: If the function suceeds

  Gets the scrolling info of the specified scroll bar
 ------------------------------------------------------------------------------}
procedure TCarbonWidget.GetScrollInfo(SBStyle: Integer;
  var ScrollInfo: TScrollInfo);
begin
  DebugLn(ClassName + '.GetScrollInfo unsupported or not implemented!');
end;

{------------------------------------------------------------------------------
  Method:  TCarbonWidget.SetCursor
  Params:  ACursor - Handle of cursor to set

  Sets the cursor
 ------------------------------------------------------------------------------}
procedure TCarbonWidget.SetCursor(ACursor: HCURSOR);
begin
  FCursor := ACursor;
end;

{------------------------------------------------------------------------------
  Method:  TCarbonWidget.ScrollBy
  Params:  DX, DY

  Scrolls the content
 ------------------------------------------------------------------------------}
procedure TCarbonWidget.ScrollBy(DX, DY: Integer);
var
  R: CGRect;
const
  SName = 'ScrollBy';
begin
  OSError(HIViewGetBounds(Content, R),
    Self, SName, 'HIViewGetBounds');
  OSError(HIViewSetBoundsOrigin(Content, R.origin.x + DX, R.origin.y + DY),
    Self, SName, 'HIViewSetBoundsOrigin');
end;

{------------------------------------------------------------------------------
  Method:  TCarbonWidget.SetScrollInfo
  Params:  SBStyle    - Scrollbar type (SB_VERT, SB_HORZ)
           ScrollInfo - Scrolling info
  Returns: The old scroll bar position

  Sets the scrolling info of the specified scroll bar
 ------------------------------------------------------------------------------}
function TCarbonWidget.SetScrollInfo(SBStyle: Integer;
  const ScrollInfo: TScrollInfo): Integer;
begin
  Result := 0;
  DebugLn(ClassName + '.SetScrollInfo unsupported or not implemented!');
end;

initialization

  LAZARUS_FOURCC := MakeFourCC('Laz ');
  WIDGETINFO_FOURCC := MakeFourCC('WInf');
  MENU_FOURCC := MakeFourCC('Menu');
  
finalization

  if UPPTree <> nil then FreeAndNil(UPPTree);

end.
