unit CocoaWSCommon;

{$mode objfpc}{$H+}
{$modeswitch objectivec1}

interface

uses
  MacOSAll, CocoaAll,
  Classes,
  Controls,
  WSControls, LCLType,
  CocoaPrivate, CocoaUtils, LCLMessageGlue;

type

  { TLCLCommonCallback }

  TLCLCommonCallback = class(TCommonCallback)
  public
    Target  : TControl;
    constructor Create(AOwner: NSObject; ATarget: TControl);
    procedure MouseDown(x,y: Integer); override;
    procedure MouseUp(x,y: Integer); override;
    procedure MouseClick(clickCount: Integer); override;
    procedure MouseMove(x,y: Integer); override;
  end;

  { TCocoaWSWinControl }

  TCocoaWSWinControl=class(TWSWinControl)
  published
    class function CreateHandle(const AWinControl: TWinControl;
      const AParams: TCreateParams): TLCLIntfHandle; override;
    class procedure SetText(const AWinControl: TWinControl; const AText: String); override;
    class function GetText(const AWinControl: TWinControl; var AText: String): Boolean; override;
    class function GetTextLen(const AWinControl: TWinControl; var ALength: Integer): Boolean; override;

    class function  GetClientBounds(const AWincontrol: TWinControl; var ARect: TRect): Boolean; override;
    class function  GetClientRect(const AWincontrol: TWinControl; var ARect: TRect): Boolean; override;
    class procedure SetBounds(const AWinControl: TWinControl; const ALeft, ATop, AWidth, AHeight: Integer); override;
  end;


  { TCocoaWSCustomControl }

  TCocoaWSCustomControl=class(TWSCustomControl)
  published
    class function CreateHandle(const AWinControl: TWinControl;
      const AParams: TCreateParams): TLCLIntfHandle; override;
  end;

// Utility WS functions

function AllocCustomControl(const AWinControl: TWinControl): TCocoaCustomControl;
procedure SetCreateParamsToControl(AControl: NSControl; const AParams: TCreateParams);

implementation

function AllocCustomControl(const AWinControl: TWinControl): TCocoaCustomControl;
begin
  if not Assigned(AWinControl) then begin
    Result:=nil;
    Exit;
  end;
  Result:=TCocoaCustomControl(TCocoaCustomControl.alloc).init;
  Result.callback:=TLCLCommonCallback.Create(Result, AWinControl);
end;

procedure SetCreateParamsToControl(AControl: NSControl; const AParams: TCreateParams);
begin
  if not Assigned(AControl) then Exit;
  AddViewToNSObject(AControl, NSObject(AParams.WndParent), AParams.X, AParams.Y);
end;

{ TLCLCommonCallback }

constructor TLCLCommonCallback.Create(AOwner: NSObject; ATarget: TControl);
begin
  inherited Create(AOwner);
  Target:=ATarget;
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
  GetViewFrame(NSView(AWinControl.Handle), ARect);
end;

class function TCocoaWSWinControl.GetClientRect(const AWincontrol: TWinControl; var ARect: TRect): Boolean;
begin
  Result:=(AWinControl.Handle<>0);
  if not Result then Exit;
  NSRectToRect(NSView(AWinControl.Handle).bounds, ARect);
end;

class procedure TCocoaWSWinControl.SetBounds(const AWinControl: TWinControl;
  const ALeft, ATop, AWidth, AHeight: Integer);
begin
  if (AWinControl.Handle=0) then Exit;
  SetViewFrame(NSView(AWinControl.Handle), ALeft, ATop, AWidth, AHeight);
end;

{ TCocoaWSCustomControl }

class function TCocoaWSCustomControl.CreateHandle(const AWinControl: TWinControl;
  const AParams: TCreateParams): TLCLIntfHandle;
var
  ctrl  : TCocoaCustomControl;
begin
  ctrl:=AllocCustomControl(AWinControl);
  SetCreateParamsToControl(ctrl, AParams);
  Result:=TLCLIntfHandle(ctrl);
end;

end.

