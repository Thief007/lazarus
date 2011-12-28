unit CocoaWSCommon;

{$mode objfpc}{$H+}
{$modeswitch objectivec1}

interface

uses
  Types,
  MacOSAll, CocoaAll,
  Classes, Controls, SysUtils,
  //
  WSControls, LCLType, LMessages, LCLProc, Forms,
  CocoaPrivate, CocoaGDIObjects, CocoaCaret, CocoaUtils, LCLMessageGlue;

type

  { LCLWSViewExtension }

  LCLWSViewExtension = objccategory(NSView)
    function lclInitWithCreateParams(const AParams: TCreateParams): id; message 'lclInitWithCreateParams:';
  end;

  { TLCLCommonCallback }

  TLCLCommonCallback = class(TObject, ICommonCallBack)
  private
    FPropStorage: TStringList;
    FContext: TCocoaContext;
    FHasCaret: Boolean;
    function GetHasCaret: Boolean;
    procedure SetHasCaret(AValue: Boolean);
  public
    Owner: NSObject;
    Target: TWinControl;
    constructor Create(AOwner: NSObject; ATarget: TWinControl); virtual;
    destructor Destroy; override;
    function GetPropStorage: TStringList;
    function GetContext: TCocoaContext;
    function GetTarget: TObject;
    procedure MouseDown(x,y: Integer); virtual;
    procedure MouseUp(x,y: Integer); virtual;
    procedure MouseClick(clickCount: Integer); virtual;
    procedure MouseMove(x,y: Integer); virtual;
    procedure frameDidChange; virtual;
    procedure boundsDidChange; virtual;
    procedure BecomeFirstResponder; virtual;
    procedure ResignFirstResponder; virtual;
    function DeliverMessage(Msg: Cardinal; WParam: WParam; LParam: LParam): LResult; virtual;
    procedure Draw(ControlContext: NSGraphicsContext; const bounds, dirty: NSRect); virtual;
    function ResetCursorRects: Boolean; virtual;

    property HasCaret: Boolean read GetHasCaret write SetHasCaret;
  end;

  TLCLCommonCallBackClass = class of TLCLCommonCallBack;

  { TCocoaWSWinControl }

  TCocoaWSWinControl = class(TWSWinControl)
  published
    class function CreateHandle(const AWinControl: TWinControl;
      const AParams: TCreateParams): TLCLIntfHandle; override;
    class procedure SetText(const AWinControl: TWinControl; const AText: String); override;
    class function GetText(const AWinControl: TWinControl; var AText: String): Boolean; override;
    class function GetTextLen(const AWinControl: TWinControl; var ALength: Integer): Boolean; override;

    class function  GetClientBounds(const AWincontrol: TWinControl; var ARect: TRect): Boolean; override;
    class function  GetClientRect(const AWincontrol: TWinControl; var ARect: TRect): Boolean; override;
    class procedure GetPreferredSize(const AWinControl: TWinControl; var PreferredWidth, PreferredHeight: integer; WithThemeSpace: Boolean); override;
    class procedure SetBounds(const AWinControl: TWinControl; const ALeft, ATop, AWidth, AHeight: Integer); override;
    class procedure SetCursor(const AWinControl: TWinControl; const ACursor: HCursor); override;
  end;


  { TCocoaWSCustomControl }

  TCocoaWSCustomControl = class(TWSCustomControl)
  published
    class function CreateHandle(const AWinControl: TWinControl;
      const AParams: TCreateParams): TLCLIntfHandle; override;
  end;


// Utility WS functions

function AllocCustomControl(const AWinControl: TWinControl): TCocoaCustomControl;
function EmbedInScrollView(AView: NSView): TCocoaScrollView;
procedure SetViewDefaults(AView: NSView);

implementation

uses
  CocoaInt;

function AllocCustomControl(const AWinControl: TWinControl): TCocoaCustomControl;
begin
  if not Assigned(AWinControl) then
    Exit(nil);
  Result := TCocoaCustomControl(TCocoaCustomControl.alloc).init;
  Result.callback := TLCLCommonCallback.Create(Result, AWinControl);
end;

function EmbedInScrollView(AView:NSView):TCocoaScrollView;
var
  r: TRect;
  p: NSView;
begin
  if not Assigned(AView) then
    Exit(nil);
  r := AView.lclFrame;
  p := AView.superview;
  Result := TCocoaScrollView.alloc.initWithFrame(NSNullRect);
  if Assigned(p) then p.addSubView(Result);
  Result.lclSetFrame(r);
  Result.setDocumentView(AView);
  SetViewDefaults(Result);
end;

procedure SetViewDefaults(AView:NSView);
begin
  if not Assigned(AView) then Exit;
  AView.setAutoresizingMask(NSViewMinYMargin or NSViewMaxXMargin);
end;


{ TLCLCommonCallback }

function TLCLCommonCallback.GetHasCaret: Boolean;
begin
  Result := FHasCaret;
end;

procedure TLCLCommonCallback.SetHasCaret(AValue: Boolean);
begin
  FHasCaret := AValue;
end;

constructor TLCLCommonCallback.Create(AOwner: NSObject; ATarget: TWinControl);
begin
  inherited Create;
  Owner := AOwner;
  Target := ATarget;
  FContext := nil;
  FHasCaret := False;
  FPropStorage := TStringList.Create;
  FPropStorage.Sorted := True;
  FPropStorage.Duplicates := dupAccept;
end;

destructor TLCLCommonCallback.Destroy;
begin
  FContext.Free;
  FPropStorage.Free;
  inherited Destroy;
end;

function TLCLCommonCallback.GetPropStorage: TStringList;
begin
  Result := FPropStorage;
end;

function TLCLCommonCallback.GetContext: TCocoaContext;
begin
  Result := FContext;
end;

function TLCLCommonCallback.GetTarget: TObject;
begin
  Result := Target;
end;

procedure TLCLCommonCallback.MouseDown(x, y: Integer);
begin
  LCLSendMouseDownMsg(Target,x,y,mbLeft, []);
end;

procedure TLCLCommonCallback.MouseUp(x, y: Integer);
begin
  LCLSendMouseUpMsg(Target,x,y,mbLeft, []);
end;

procedure TLCLCommonCallback.MouseClick(clickCount: Integer);
begin
  LCLSendClickedMsg(Target);
end;

procedure TLCLCommonCallback.MouseMove(x, y: Integer);
begin
  LCLSendMouseMoveMsg(Target, x,y, []);
end;

procedure TLCLCommonCallback.frameDidChange;
begin
  boundsDidChange;
end;

procedure TLCLCommonCallback.boundsDidChange;
var
  NewBounds, OldBounds: TRect;
  PosMsg: TLMWindowPosChanged;
  Resized, Moved, ClientResized: Boolean;
  SizeType: Integer;
begin
  NewBounds := Owner.lclFrame;

  // send window pos changed
  PosMsg.Msg := LM_WINDOWPOSCHANGED;
  PosMsg.Result := 0;
  New(PosMsg.WindowPos);
  try
    with PosMsg.WindowPos^ do
    begin
      hWndInsertAfter := 0;
      x := NewBounds.Left;
      y := NewBounds.Right;
      cx := NewBounds.Right - NewBounds.Left;
      cy := NewBounds.Bottom - NewBounds.Top;
      flags := 0;
    end;
    LCLMessageGlue.DeliverMessage(Target, PosMsg);
  finally
    Dispose(PosMsg.WindowPos);
  end;

  OldBounds := Target.BoundsRect;

  Resized :=
    (OldBounds.Right - OldBounds.Left <> NewBounds.Right - NewBounds.Left) or
    (OldBounds.Bottom - OldBounds.Top <> NewBounds.Bottom - NewBounds.Top);
  Moved :=
    (OldBounds.Left <> NewBounds.Left) or
    (OldBounds.Top <> NewBounds.Top);

  ClientResized := False;

  // update client rect
  if Resized or Target.ClientRectNeedsInterfaceUpdate then
  begin
    Target.InvalidateClientRectCache(False);
    ClientResized := True;
  end;

  // then send a LM_SIZE message
  if Resized or ClientResized then
  begin
    LCLSendSizeMsg(Target, NewBounds.Right - NewBounds.Left,
      NewBounds.Bottom - NewBounds.Top, Owner.lclWindowState, True);
  end;

  // then send a LM_MOVE message
  if Moved then
  begin
    LCLSendMoveMsg(Target, NewBounds.Left,
      NewBounds.Top, Move_SourceIsInterface);
  end;
end;

procedure TLCLCommonCallback.BecomeFirstResponder;
begin
  LCLSendSetFocusMsg(Target);
end;

procedure TLCLCommonCallback.ResignFirstResponder;
begin
  LCLSendKillFocusMsg(Target);
end;

function TLCLCommonCallback.DeliverMessage(Msg: Cardinal; WParam: WParam; LParam: LParam): LResult;
var
  Message: TLMessage;
begin
  Message.Msg := Msg;
  Message.WParam := WParam;
  Message.LParam := LParam;
  Message.Result := 0;
  Result := LCLMessageGlue.DeliverMessage(Target, Message);
end;

procedure TLCLCommonCallback.Draw(ControlContext: NSGraphicsContext;
  const bounds, dirty: NSRect);
var
  struct: TPaintStruct;
begin
  // todo: think more about draw call while previous draw still active
  if Assigned(FContext) then
    Exit;
  FContext := TCocoaContext.Create;
  try
    FContext.ctx := ControlContext;
    if FContext.InitDraw(Round(bounds.size.width), Round(bounds.size.height)) then
    begin
      FillChar(struct, SizeOf(TPaintStruct), 0);
      struct.hdc := HDC(FContext);
      LCLSendPaintMsg(Target, HDC(FContext), @struct);
      if FHasCaret then
        DrawCaret;
    end;
  finally
    FreeAndNil(FContext);
  end;
end;

function TLCLCommonCallback.ResetCursorRects: Boolean;
var
  ACursor: TCursor;
  View: NSView;
begin
  Result := False;
  if Owner.isKindOfClass_(NSWindow) then
    View := NSwindow(Owner).contentView
  else
  if Owner.isKindOfClass_(NSView) then
    View := NSView(Owner)
  else
    Exit;
  if not (csDesigning in Target.ComponentState) then
  begin
    ACursor := Screen.Cursor;
    if ACursor = crDefault then
    begin
      // traverse visible child controls
      ACursor := Target.Cursor;
    end;
    Result := ACursor <> crDefault;
    if Result then
      View.addCursorRect_cursor(View.visibleRect, TCocoaCursor(Screen.Cursors[ACursor]).Cursor);
  end;
end;

{ TCocoaWSWinControl }

class function TCocoaWSWinControl.CreateHandle(const AWinControl: TWinControl;
  const AParams: TCreateParams): TLCLIntfHandle;
begin
  Result:=TCocoaWSCustomControl.CreateHandle(AWinControl, AParams);
end;

class procedure TCocoaWSWinControl.SetText(const AWinControl: TWinControl; const AText: String);
var
  obj : NSObject;
begin
  // sanity check
  obj:=NSObject(AWinControl.Handle);
  if not Assigned(obj) or not obj.isKindOfClass_(NSControl) then Exit;

  SetNSControlValue(NSControl(obj), AText);
end;

class function TCocoaWSWinControl.GetText(const AWinControl: TWinControl; var AText: String): Boolean;
var
  obj   : NSObject;
begin
  Result:=false;

  // sanity check
  obj:=NSObject(AWinControl.Handle);
  Result:=Assigned(obj) and obj.isKindOfClass_(NSControl);
  if not Result then Exit;

  AText:=GetNSControlValue(NSControl(obj));
  Result:=true;
end;

class function TCocoaWSWinControl.GetTextLen(const AWinControl: TWinControl; var ALength: Integer): Boolean;
var
  obj : NSObject;
  s   : NSString;
begin
  Result:=false;

  // sanity check
  obj:=NSObject(AWinControl.Handle);
  Result:= Assigned(obj) and obj.isKindOfClass_(NSControl);
  if not Result then Exit;

  s:=NSControl(obj).stringValue;
  if Assigned(s) then ALength:=s.length
  else ALength:=0
end;

class function TCocoaWSWinControl.GetClientBounds(const AWincontrol: TWinControl; var ARect: TRect): Boolean;
begin
  Result:=(AWinControl.Handle<>0);
  if not Result then Exit;
  ARect:=NSObject(AWinControl.Handle).lclClientFrame;
end;

class function TCocoaWSWinControl.GetClientRect(const AWincontrol: TWinControl; var ARect: TRect): Boolean;
begin
  Result:=(AWinControl.Handle<>0);
  if not Result then Exit;
  ARect:=NSObject(AWinControl.Handle).lclClientFrame;
end;

class procedure TCocoaWSWinControl.GetPreferredSize(
  const AWinControl: TWinControl; var PreferredWidth, PreferredHeight: integer;
  WithThemeSpace: Boolean);
var
  Obj: NSObject;
  Size: NSSize;
begin
  if (AWinControl.Handle <> 0) then
  begin
    Obj := NSObject(AWinControl.Handle);
{
    if Obj.isKindOfClass_(NSView) and obj.respondsToSelector(objcselector('fittingSize')) then
    begin
      Size := NSView(Obj).fittingSize;
      PreferredWidth := Round(Size.width);
      PreferredHeight := Round(Size.height);
    end;
}
  end;
end;

class procedure TCocoaWSWinControl.SetBounds(const AWinControl: TWinControl;
  const ALeft, ATop, AWidth, AHeight: Integer);
begin
  if (AWinControl.Handle<>0) then
    NSObject(AWinControl.Handle).lclSetFrame(Bounds(ALeft, ATop, AWidth, AHeight));
end;

class procedure TCocoaWSWinControl.SetCursor(const AWinControl: TWinControl;
  const ACursor: HCursor);
var
  Obj: NSObject;
begin
  if (AWinControl.Handle <> 0) then
  begin
    Obj := NSObject(AWinControl.Handle);
    if Obj.isKindOfClass_(NSWindow) then
      NSWindow(Obj).resetCursorRects
    else
    if Obj.isKindOfClass_(NSView) then
      NSView(Obj).resetCursorRects;
  end;
end;

{ TCocoaWSCustomControl }

class function TCocoaWSCustomControl.CreateHandle(const AWinControl: TWinControl;
  const AParams: TCreateParams): TLCLIntfHandle;
var
  ctrl  : TCocoaCustomControl;
begin
  ctrl:=TCocoaCustomControl( NSView(TCocoaCustomControl.alloc).lclInitWithCreateParams(AParams));
  ctrl.callback:=TLCLCommonCallback.Create(ctrl, AWinControl);
  Result:=TLCLIntfHandle(ctrl);
end;

{ LCLWSViewExtension }

function LCLWSViewExtension.lclInitWithCreateParams(const AParams:TCreateParams): id;
var
  p: NSView;
  ns: NSRect;
begin
  p:=nil;
  if (AParams.WndParent<>0) then begin
    if (NSObject(AParams.WndParent).isKindOfClass_(NSView)) then
      p:=NSView(AParams.WndParent)
    else if (NSObject(AParams.WndParent).isKindOfClass_(NSWindow)) then
      p:=NSWindow(AParams.WndParent).contentView;
  end;
  with AParams do
    if Assigned(p)
      then LCLToNSRect(Types.Bounds(X,Y,Width, Height), p.frame.size.height, ns)
      else LCLToNSRect(Types.Bounds(X,Y,Width, Height), ns);

  Result:=initWithFrame(ns);
  if not Assigned(Result) then Exit;

  if Assigned(p) then p.addSubview(Self);
  SetViewDefaults(Self);
end;

end.

