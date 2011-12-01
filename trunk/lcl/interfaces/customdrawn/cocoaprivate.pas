unit cocoaprivate;

{$mode objfpc}{$H+}
{$modeswitch objectivec1}

interface

uses
  // rtl+ftl
  Types, Classes, SysUtils,
  CGGeometry,
  fpimage, fpcanvas,
  // Custom Drawn Canvas
  IntfGraphics, lazcanvas, customdrawnproc,
  // Libs
  MacOSAll, CocoaAll, CocoaUtils, CocoaGDIObjects,
  //
  Forms, Controls, LCLMessageGlue, WSControls, LCLType, LCLProc, GraphType;

type
  { TCocoaWindow }

  TCocoaWindow = objcclass(NSWindow, NSWindowDelegateProtocol)
  protected
    function windowShouldClose(sender : id): LongBool; message 'windowShouldClose:';
    procedure windowWillClose(notification: NSNotification); message 'windowWillClose:';
    procedure windowDidBecomeKey(notification: NSNotification); message 'windowDidBecomeKey:';
    procedure windowDidResignKey(notification: NSNotification); message 'windowDidResignKey:';
    procedure windowDidResize(notification: NSNotification); message 'windowDidResize:';
  public
    LCLForm: TCustomForm;
    Children: TFPList; // TCDWinControl
    function acceptsFirstResponder: Boolean; override;
    procedure mouseUp(event: NSEvent); override;
    procedure mouseDown(event: NSEvent); override;
    procedure mouseDragged(event: NSEvent); override;
    procedure mouseEntered(event: NSEvent); override;
    procedure mouseExited(event: NSEvent); override;
    procedure mouseMoved(event: NSEvent); override;
    function lclIsVisible: Boolean; message 'lclIsVisible';
    procedure lclInvalidateRect(const r: TRect); message 'lclInvalidateRect:';
    procedure lclInvalidate; message 'lclInvalidate';
    procedure lclLocalToScreen(var X,Y: Integer); message 'lclLocalToScreen::';
    function lclFrame: TRect; message 'lclFrame';
    procedure lclSetFrame(const r: TRect); message 'lclSetFrame:';
    function lclClientFrame: TRect; message 'lclClientFrame';
    // callback routines
    procedure CallbackActivate; message 'CallbackActivate';
    procedure CallbackDeactivate; message 'CallbackDeactivate';
    procedure CallbackCloseQuery(var CanClose: Boolean); message 'CallbackCloseQuery:';
    procedure CallbackResize; message 'CallbackResize';
    //
    procedure CallbackMouseDown(x, y: Integer); message 'CallbackMouseDown:y:';
    procedure CallbackMouseUp(x, y: Integer); message 'CallbackMouseUp:y:';
    procedure CallbackMouseClick(clickCount: Integer); message 'CallbackMouseClick:';
    procedure CallbackMouseMove(x, y: Integer); message 'CallbackMouseMove:y:';
  end;

  { TCocoaCustomControl }

  TCocoaCustomControl = objcclass(NSControl)
    //callback  : TCommonCallback;
    Image: TLazIntfImage;
    Canvas: TLazCanvas;
    Context : TCocoaContext;
    LCLForm: TCustomForm;
    procedure drawRect(dirtyRect: NSRect); override;
    procedure Draw(ControlContext: NSGraphicsContext; const Abounds, dirty:NSRect); message 'draw:Context:bounds:';
  public
    function lclInitWithCreateParams(const AParams: TCreateParams): id; message 'lclInitWithCreateParams:';
    //
    function lclIsVisible: Boolean; message 'lclIsVisible';
    procedure lclInvalidateRect(const r: TRect); message 'lclInvalidateRect:';
    procedure lclInvalidate; message 'lclInvalidate';
    procedure lclLocalToScreen(var X,Y: Integer); message 'lclLocalToScreen::';
    function lclParent: id; message 'lclParent';
    function lclFrame: TRect; message 'lclFrame';
    procedure lclSetFrame(const r: TRect); message 'lclSetFrame:';
    function lclClientFrame: TRect; message 'lclClientFrame';
  end;

procedure SetViewDefaults(AView: NSView);

function Cocoa_RawImage_CreateBitmaps(const ARawImage: TRawImage; out ABitmap, AMask: HBitmap; ASkipMask: Boolean): Boolean;
function RawImage_DescriptionToBitmapType(ADesc: TRawImageDescription; out bmpType: TCocoaBitmapType): Boolean;

implementation

uses customdrawnwsforms;

function Cocoa_RawImage_CreateBitmaps(const ARawImage: TRawImage; out ABitmap, AMask: HBitmap; ASkipMask: Boolean): Boolean;
const
  ALIGNMAP: array[TRawImageLineEnd] of TCocoaBitmapAlignment = (cbaByte, cbaByte, cbaWord, cbaDWord, cbaQWord, cbaDQWord);
var
  ADesc: TRawImageDescription absolute ARawImage.Description;
  bmpType: TCocoaBitmapType;
begin
  Result := RawImage_DescriptionToBitmapType(ADesc, bmpType);
  if not Result then begin
    debugln(['TCarbonWidgetSet.RawImage_CreateBitmaps TODO Depth=',ADesc.Depth,' alphaprec=',ADesc.AlphaPrec,' byteorder=',ord(ADesc.ByteOrder),' alpha=',ADesc.AlphaShift,' red=',ADesc.RedShift,' green=',adesc.GreenShift,' blue=',adesc.BlueShift]);
    exit;
  end;
  ABitmap := HBITMAP(TCocoaBitmap.Create(ADesc.Width, ADesc.Height, ADesc.Depth, ADesc.BitsPerPixel, ALIGNMAP[ADesc.LineEnd], bmpType, ARawImage.Data));

  if ASkipMask or (ADesc.MaskBitsPerPixel = 0)
  then AMask := 0
  else AMask := HBITMAP(TCocoaBitmap.Create(ADesc.Width, ADesc.Height, 1, ADesc.MaskBitsPerPixel, ALIGNMAP[ADesc.MaskLineEnd], cbtMask, ARawImage.Mask));

  Result := True;
end;

function RawImage_DescriptionToBitmapType(
  ADesc: TRawImageDescription;
  out bmpType: TCocoaBitmapType): Boolean;
begin
  Result := False;

  if ADesc.Format = ricfGray
  then
  begin
    if ADesc.Depth = 1 then bmpType := cbtMono
    else bmpType := cbtGray;
  end
  else if ADesc.Depth = 1
  then bmpType := cbtMono
  else if ADesc.AlphaPrec <> 0
  then begin
    if ADesc.ByteOrder = riboMSBFirst
    then begin
      if  (ADesc.AlphaShift = 24)
      and (ADesc.RedShift   = 16)
      and (ADesc.GreenShift = 8 )
      and (ADesc.BlueShift  = 0 )
      then bmpType := cbtARGB
      else
      if  (ADesc.AlphaShift = 0)
      and (ADesc.RedShift   = 24)
      and (ADesc.GreenShift = 16 )
      and (ADesc.BlueShift  = 8 )
      then bmpType := cbtRGBA
      else
      if  (ADesc.AlphaShift = 0 )
      and (ADesc.RedShift   = 8 )
      and (ADesc.GreenShift = 16)
      and (ADesc.BlueShift  = 24)
      then bmpType := cbtBGRA
      else Exit;
    end
    else begin
      if  (ADesc.AlphaShift = 24)
      and (ADesc.RedShift   = 16)
      and (ADesc.GreenShift = 8 )
      and (ADesc.BlueShift  = 0 )
      then bmpType := cbtBGRA
      else
      if  (ADesc.AlphaShift = 0 )
      and (ADesc.RedShift   = 8 )
      and (ADesc.GreenShift = 16)
      and (ADesc.BlueShift  = 24)
      then bmpType := cbtARGB
      else
      if  (ADesc.AlphaShift = 24 )
      and (ADesc.RedShift   = 0 )
      and (ADesc.GreenShift = 8)
      and (ADesc.BlueShift  = 16)
      then bmpType := cbtRGBA
      else Exit;
    end;
  end
  else begin
    bmpType := cbtRGB;
  end;

  Result := True;
end;

{ TCocoaWindow }

function TCocoaWindow.windowShouldClose(sender: id): LongBool;
var
  canClose : Boolean;
begin
  canClose:=true;
  CallbackCloseQuery(canClose);
  Result:=canClose;
end;

procedure TCocoaWindow.windowWillClose(notification: NSNotification);
begin
  LCLSendCloseUpMsg(LCLForm);
end;

procedure TCocoaWindow.windowDidBecomeKey(notification: NSNotification);
begin
  CallbackActivate;
end;

procedure TCocoaWindow.windowDidResignKey(notification: NSNotification);
begin
  CallbackDeactivate;
end;

procedure TCocoaWindow.windowDidResize(notification: NSNotification);
begin
  CallbackResize;
end;

function TCocoaWindow.acceptsFirstResponder: Boolean;
begin
  Result:=true;
end;

procedure TCocoaWindow.mouseUp(event: NSEvent);
var
  mp : NSPoint;
begin
  mp:=event.locationInWindow;
  mp.y:=NSView(event.window.contentView).bounds.size.height-mp.y;
  callbackMouseUp(round(mp.x), round(mp.y));
  inherited mouseUp(event);
end;

procedure TCocoaWindow.mouseDown(event: NSEvent);
var
  mp : NSPoint;
begin
  mp:=event.locationInWindow;
  mp.y:=NSView(event.window.contentView).bounds.size.height-mp.y;
  callbackMouseDown(round(mp.x), round(mp.y));
  inherited mouseDown(event);
end;

procedure TCocoaWindow.mouseDragged(event: NSEvent);
var
  mp : NSPoint;
begin
  mp:=event.locationInWindow;
  mp.y:=NSView(event.window.contentView).bounds.size.height-mp.y;
  callbackMouseMove(round(mp.x), round(mp.y));
  inherited mouseMoved(event);
end;

procedure TCocoaWindow.mouseMoved(event: NSEvent);
var
  mp : NSPoint;
begin
  mp:=event.locationInWindow;
  mp.y:=NSView(event.window.contentView).bounds.size.height-mp.y;
  callbackMouseMove(round(mp.x), round(mp.y));
  inherited mouseMoved(event);
end;

procedure TCocoaWindow.mouseEntered(event: NSEvent);
begin
  inherited mouseEntered(event);
end;

procedure TCocoaWindow.mouseExited(event: NSEvent);
begin
  inherited mouseExited(event);
end;

function TCocoaWindow.lclIsVisible:Boolean;
begin
  Result:=isVisible;
end;

procedure TCocoaWindow.lclInvalidateRect(const r:TRect);
begin
  contentView.lclInvalidateRect(r);
end;

procedure TCocoaWindow.lclInvalidate;
begin
  contentView.lclInvalidate;
end;

procedure TCocoaWindow.lclLocalToScreen(var X,Y:Integer);
var
  f   : NSRect;
begin
  if Assigned(screen) then begin
    f:=frame;
    x:=Round(f.origin.x+x);
    y:=Round(screen.frame.size.height-f.size.height-f.origin.y);
  end;
end;

function TCocoaWindow.lclFrame:TRect;
begin
  if Assigned(screen)
    then NSToLCLRect(frame, screen.frame.size.height, Result)
    else NSToLCLRect(frame, Result);
end;

procedure TCocoaWindow.lclSetFrame(const r:TRect);
var
  ns : NSREct;
begin
  if Assigned(screen)
    then LCLToNSRect(r, screen.frame.size.height, ns)
    else LCLToNSRect(r, ns);
  setFrame_display(ns, isVisible);
end;

function TCocoaWindow.lclClientFrame:TRect;
var
  wr  : NSRect;
  b   : CGGeometry.CGRect;
begin
  wr:=frame;
  b:=contentView.frame;
  Result.Left:=Round(b.origin.x);
  Result.Top:=Round(wr.size.height-b.origin.y);
  Result.Right:=Round(b.origin.x+b.size.width);
  Result.Bottom:=Round(Result.Top+b.size.height);
end;

procedure TCocoaWindow.CallbackActivate;
begin
  LCLSendActivateMsg(LCLForm, True, false);
end;

procedure TCocoaWindow.CallbackDeactivate;
begin
  LCLSendDeactivateStartMsg(LCLForm);
end;

procedure TCocoaWindow.CallbackCloseQuery(var CanClose: Boolean);
begin
  // Message results : 0 - do nothing, 1 - destroy window
  CanClose:=LCLSendCloseQueryMsg(LCLForm)>0;
end;

procedure TCocoaWindow.CallbackResize;
var
  sz  : NSSize;
  r   : TRect;
begin
  sz := frame.size;
  TCDWSCustomForm.GetClientBounds(TWinControl(LCLForm), r);
  if Assigned(LCLForm) then
    LCLSendSizeMsg(LCLForm, Round(sz.width), Round(sz.height), SIZENORMAL);
end;

procedure TCocoaWindow.CallbackMouseDown(x, y: Integer);
begin
  LCLSendMouseDownMsg(LCLForm,x,y,mbLeft, []);
end;

procedure TCocoaWindow.CallbackMouseUp(x, y: Integer);
begin
  LCLSendMouseUpMsg(LCLForm,x,y,mbLeft, []);
end;

procedure TCocoaWindow.CallbackMouseClick(clickCount: Integer);
begin
  LCLSendClickedMsg(LCLForm);
end;

procedure TCocoaWindow.CallbackMouseMove(x, y: Integer);
begin
  LCLSendMouseMoveMsg(LCLForm, x,y, []);
end;

{ TCocoaCustomControl }

procedure TCocoaCustomControl.drawRect(dirtyRect:NSRect);
begin
  inherited drawRect(dirtyRect);
  Draw(NSGraphicsContext.currentContext, bounds, dirtyRect);
end;

procedure TCocoaCustomControl.Draw(ControlContext: NSGraphicsContext;
  const Abounds, dirty:NSRect);
var
  struct : TPaintStruct;
  lWidth, lHeight: Integer;
  lBitmap, lMask: HBITMAP;
  lRawImage: TRawImage;
  AImage: TLazIntfImage;
  ACanvas: TLazCanvas;
begin
  if not Assigned(Context) then Context:=TCocoaContext.Create;

  Context.ctx:=ControlContext;
  lWidth := Round(bounds.size.width);
  lHeight := Round(bounds.size.height);
  if Context.InitDraw(lWidth, lHeight) then
  begin
    // Prepare the non-native image and canvas
    FillChar(struct, SizeOf(TPaintStruct), 0);

    UpdateControlLazImageAndCanvas(Image,
      Canvas, lWidth, lHeight, clfRGB24UpsideDown);

    struct.hdc := HDC(Canvas);

    // Send the paint message to the LCL
    {$IFDEF VerboseCDWinAPI}
      DebugLn(Format('[TLCLCommonCallback.Draw] OnPaint event started context: %x', [struct.hdc]));
    {$ENDIF}
    LCLSendPaintMsg(LCLForm, struct.hdc, @struct);
    {$IFDEF VerboseCDWinAPI}
      DebugLn('[TLCLCommonCallback.Draw] OnPaint event ended');
    {$ENDIF}

    // Now render all child wincontrols
    RenderChildWinControls(Image, Canvas,
      TCDWSCustomForm.BackendGetCDWinControlList(LCLForm));

    // Now render it into the control
    Image.GetRawImage(lRawImage);
    Cocoa_RawImage_CreateBitmaps(lRawImage, lBitmap, lMask, True);
    Context.DrawBitmap(0, 0, TCocoaBitmap(lBitmap));
  end;
end;

function RectToViewCoord(view: NSView; const r: TRect): NSRect;
var
  b: NSRect;
begin
  if not Assigned(view) then Exit;
  b:=view.bounds;
  Result.origin.x:=r.Left;
  Result.origin.y:=b.size.height-r.Top;
  Result.size.width:=r.Right-r.Left;
  Result.size.height:=r.Bottom-r.Top;
end;

function TCocoaCustomControl.lclInitWithCreateParams(const AParams:TCreateParams): id;
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

function TCocoaCustomControl.lclIsVisible:Boolean;
begin
  Result:=not isHidden;
end;

procedure TCocoaCustomControl.lclInvalidateRect(const r:TRect);
begin
  setNeedsDisplayInRect(RectToViewCoord(Self, r));
end;

procedure TCocoaCustomControl.lclInvalidate;
begin
  setNeedsDisplay_(True);
end;

procedure TCocoaCustomControl.lclLocalToScreen(var X,Y:Integer);
begin

end;

function TCocoaCustomControl.lclParent:id;
begin
  Result:=superView;
end;

function TCocoaCustomControl.lclFrame: TRect;
var
  v : NSView;
begin
  v:=superview;
  if Assigned(v)
    then NSToLCLRect(frame, v.frame.size.height, Result)
    else NSToLCLRect(frame, Result);
end;

procedure TCocoaCustomControl.lclSetFrame(const r:TRect);
var
  ns : NSRect;
begin
  if Assigned(superview)
    then LCLToNSRect(r, superview.frame.size.height, ns)
    else LCLToNSRect(r, ns);
  setFrame(ns);
end;

function TCocoaCustomControl.lclClientFrame:TRect;
var
  r: NSRect;
begin
  r:=bounds;
  Result.Left:=0;
  Result.Top:=0;
  Result.Right:=Round(r.size.width);
  Result.Bottom:=Round(r.size.height);
end;

procedure SetViewDefaults(AView:NSView);
begin
  if not Assigned(AView) then Exit;
  AView.setAutoresizingMask(NSViewMinYMargin or NSViewMaxXMargin);
end;

end.

