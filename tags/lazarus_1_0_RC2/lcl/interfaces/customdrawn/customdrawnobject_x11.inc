{%MainUnit customdrawnint.pas}

{******************************************************************************
                                   customdrawnobject_win.inc
 ******************************************************************************

 *****************************************************************************
 *                                                                           *
 *  This file is part of the Lazarus Component Library (LCL)                 *
 *                                                                           *
 *  See the file COPYING.modifiedLGPL.txt, included in this distribution,    *
 *  for details about the copyright.                                         *
 *                                                                           *
 *  This program is distributed in the hope that it will be useful,          *
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of           *
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                     *
 *                                                                           *
 *****************************************************************************
}


// The version from FreePascal crash except in FPC 2.7.1+ from 10 Dec 2011 +
function XOpenIM(para1: PDisplay; para2: PXrmHashBucketRec; para3: Pchar; para4: Pchar): PXIM; cdecl; external;
function XCreateIC(para1: PXIM; para2: array of const): PXIC; cdecl; external;

procedure MyXConnectionWatchProc(display: PDisplay; client_data: TXPointer;
  fd: cint; opening: XLib.TBool; watch_data: PXPointer); cdecl;
begin
  if opening <> 0 then CDWidgetset.XConnections.Add(Pointer(fd))
  else CDWidgetset.XConnections.Remove(Pointer(fd));
end;

function TCDWidgetSet.CheckInvalidateWindowForX(XWIndowID: X.TWindow): Boolean;
var
  I: integer;
  AWindowInfo: TX11WindowInfo;
begin
  Result:= False;
  for I:= 0 to XWindowList.Count -1 do begin
    AWindowInfo:= TX11WindowInfo(XWindowList.Objects[I]);
    if AWindowInfo.Window = XWIndowID then begin
      if XWindowList.Strings[I] <> 'Paint' then begin
        XWindowList.Strings[I] := 'Paint';
        Result:= True;
        Exit;
      end;
    end;
  end;
end;

procedure TCDWidgetSet.WindowUpdated(XWIndowID: X.TWindow);
var
  I: integer;
  AWindowInfo: TX11WindowInfo;
begin
  for I:= 0 to XWindowList.Count -1 do begin
    AWindowInfo:= TX11WindowInfo(XWindowList.Objects[I]);
    if AWindowInfo.Window = XWIndowID then begin
      XWindowList.Strings[I] := 'Done';
      Exit;
      end;
    end;
end;

function TCDWidgetSet.FindWindowByXID(XWindowID: X.TWindow; out AWindowInfo: TX11WindowInfo): TWinControl;
var
  i: Integer;
  EndSubSearch: Boolean; { Necessary to quit the recursion }
  lWindowInfo: TX11WindowInfo;
begin
  {$ifdef VerboseFindX11Window}
  DbgOut(Format('[TCDWidgetSet.FindWindowByXID] XWindowID=%x', [PtrInt(XWindowID)]));
  {$endif}
  AWindowInfo := nil;
  Result := nil;

  { Loops througth all windows on the application }
  for i := 0 to Screen.FormCount - 1 do
  begin
    lWindowInfo := TX11WindowInfo(Screen.Forms[i].Handle);
    Result := lWindowInfo.LCLForm;
    AWindowInfo := lWindowInfo;

    {$ifdef VerboseFindX11Window}
    DbgOut(Format(' Item %d Window=%x', [i, PtrInt(lWindowInfo.Window)]));
    {$endif}
    if lWindowInfo.Window = XWindowID then Break;
  end;
  if (Result <> nil) and (lWindowInfo.Window <> XWindowID) then Result := nil;
  {$ifdef VerboseFindX11Window}
  DebugLn('');
  {$endif}
end;

{------------------------------------------------------------------------------
  Method: TCDWidgetSet.Create
  Params:  None
  Returns: Nothing

  Constructor for the class.
 ------------------------------------------------------------------------------}
procedure TCDWidgetSet.BackendCreate;
begin
  // Create the dummy screen DC
  ScreenBitmapRawImage.Init;
  ScreenBitmapHeight := 100;
  ScreenBitmapWidth := 100;
  ScreenBitmapRawImage.Description.Init_BPP32_A8R8G8B8_BIO_TTB(ScreenBitmapWidth, ScreenBitmapHeight);
  ScreenBitmapRawImage.CreateData(True);
  ScreenImage := TLazIntfImage.Create(0, 0);
  ScreenImage.SetRawImage(ScreenBitmapRawImage);
  ScreenDC := TLazCanvas.Create(ScreenImage);

  XConnections := TFPList.Create;
  XWindowList := TStringList.Create;
end;

{------------------------------------------------------------------------------
  Method: TWinCEWidgetSet.Destroy
  Params:  None
  Returns: Nothing

  destructor for the class.
 ------------------------------------------------------------------------------}
procedure TCDWidgetSet.BackendDestroy;
var
  I: Integer;
begin
  XConnections.Free;
  for I:= 0 to XWindowList.Count -1 do
    XWindowList.Objects[I].Free;
  XWindowList.Free;

  { Release the screen DC and Image }
  ScreenDC.Free;
  ScreenImage.Free;
end;

{------------------------------------------------------------------------------
  Method: TCDWidgetSet.AppInit
  Params:  None
  Returns: Nothing

  initialize Windows
 ------------------------------------------------------------------------------}
procedure TCDWidgetSet.AppInit(var ScreenInfo: TScreenInfo);
var
  ClassHint: PXClassHint;
begin
  {$ifdef Verbose_CDWS}
//  DebugLn('TCDWidgetSet.AppInit');
  {$endif}

  if Application.ApplicationType = atDefault then
    Application.ApplicationType := atDesktop;

  if Application.LayoutAdjustmentPolicy = lapDefault then
    Application.LayoutAdjustmentPolicy := lapFixedLayout;

  // Maybe it was passed as a -display parameter. Lets check first!
  if FDisplayName = '' then
    FDisplayName := XDisplayName(nil);

  FDisplay := XOpenDisplay(PChar(FDisplayName));

  if not Assigned(FDisplay) then
    raise Exception.Create('[TCDWidgetSet.AppInit] XOpenDisplay failed');

  // Keyboard initialization

  InputMethod := XOpenIM(FDisplay, nil, nil, nil);
  if InputMethod <> nil then
    InputContext := XCreateIC(InputMethod, [XNInputStyle, XIMPreeditNothing or XIMStatusNothing, nil]);

  if InputContext = nil then DebugLn('[TCDWidgetSet.BackendInit] Failed to initialize the Keyboard handling!');

  // Initialize ScreenInfo
  ScreenInfo.PixelsPerInchX:= 96;
  ScreenInfo.PixelsPerInchY:= 96;
  ScreenInfo.Initialized:= True;

  //if (not (woX11SkipWMHints in WindowOptions)) and (woWindow in WindowOptions) then
  //begin
    LeaderWindow := XCreateSimpleWindow(FDisplay, XDefaultRootWindow(FDisplay), 0, 0, 1, 1, 0, 0, 0);

    ClassHint := XAllocClassHint;
    ClassHint^.res_name := 'fpGFX'; // !!! use app name
    ClassHint^.res_class := 'FpGFX';
    XSetWMProperties(FDisplay, LeaderWindow, nil, nil, nil, 0, nil, nil, ClassHint);
    XFree(ClassHint);
    ClientLeaderAtom := XInternAtom(FDisplay, 'WM_CLIENT_LEADER', False);
  //end;

  // Add watches to the XConnection
  XAddConnectionWatch(FDisplay, @MyXConnectionWatchProc, nil);

  // Generic code
  GenericAppInit();
end;

procedure TCDWidgetSet.AppRun(const ALoop: TApplicationMainLoop);
var
  DoBreakRun: Boolean = False;
begin
  while (DoBreakRun = False) do
  begin
    if XPending(FDisplay) <= 0 then AppProcessInvalidates();
    AppWaitMessage();
    AppProcessMessage();

    DoBreakRun := Application.Terminated;
  end;
  DoBreakRun := False;
end;

(*
function TWinCEWidgetSet.GetAppHandle: THandle;
begin
  Result:= FAppHandle;
end;

procedure TWinCEWidgetSet.SetAppHandle(const AValue: THandle);
begin
  // Do it only if handle is not yet created (for example for DLL initialization)
  // if handle is already created we can't reassign it
  if AppHandle = 0 then
    FAppHandle := AValue;
end;*)

{------------------------------------------------------------------------------
  Method: TWinCEWidgetSet.AppMinimize
  Params:  None
  Returns: Nothing

  Minimizes the whole application to the taskbar
 ------------------------------------------------------------------------------}
procedure TCDWidgetSet.AppMinimize;
begin
//  Windows.SendMessage(FAppHandle, WM_SYSCOMMAND, SC_MINIMIZE, 0);
end;

{------------------------------------------------------------------------------
  Method: TWinCEWidgetSet.AppRestore
  Params:  None
  Returns: Nothing

  Restore minimized whole application from taskbar
 ------------------------------------------------------------------------------}

procedure TCDWidgetSet.AppRestore;
begin
//  Windows.SendMessage(FAppHandle, WM_SYSCOMMAND, SC_RESTORE, 0);
end;


{------------------------------------------------------------------------------
  Method: TWinCEWidgetSet.AppBringToFront
  Params:  None
  Returns: Nothing

  Brings the entire application on top of all other non-topmost programs
 ------------------------------------------------------------------------------}
procedure TCDWidgetSet.AppBringToFront;
begin
end;

(*
procedure TWinCEWidgetSet.SetDesigning(AComponent: TComponent);
begin
  //if Data<>nil then EnableWindow((AComponent As TWinControl).Handle, boolean(Data^));
end;

{------------------------------------------------------------------------------
  Method: TWinCEWidgetSet.SetCallback
  Params: Msg    - message for which to set a callback
          Sender - object to which callback will be sent
  Returns:  nothing

  Applies a Message to the sender
 ------------------------------------------------------------------------------}
procedure TWinCEWidgetSet.SetCallback(Msg: LongInt; Sender: TObject);
var
  Window: HWnd;
begin
  //DebugLn('Trace:TWinCEWidgetSet.SetCallback - Start');
  //DebugLn(Format('Trace:TWinCEWidgetSet.SetCallback - Class Name --> %S', [Sender.ClassName]));
  //DebugLn(Format('Trace:TWinCEWidgetSet.SetCallback - Message Name --> %S', [GetMessageName(Msg)]));
  if Sender Is TControlCanvas then
    Window := TControlCanvas(Sender).Handle
  else if Sender Is TCustomForm then
    Window := TCustomForm(Sender).Handle
  else
    Window := TWinControl(Sender).Handle;
  if Window=0 then exit;

  //DebugLn('Trace:TWinCEWidgetSet.SetCallback - Exit');
end;

{------------------------------------------------------------------------------
  Method: TWinCEWidgetSet.RemoveCallbacks
  Params:   Sender - object from which to remove callbacks
  Returns:  nothing

  Removes Call Back Signals from the sender
 ------------------------------------------------------------------------------}
procedure TWinCEWidgetSet.RemoveCallbacks(Sender: TObject);
var
  Window: HWnd;
begin
  if Sender Is TControlCanvas then
    Window := TControlCanvas(Sender).Handle
  else if Sender Is TCustomForm then
    Window := TCustomForm(Sender).Handle
  else
    Window := (Sender as TWinControl).Handle;
  if Window=0 then exit;
end;*)

{------------------------------------------------------------------------------
  Method: TWinCEWidgetSet.AppProcessMessages
  Params:  None
  Returns: Nothing

  Handle all pending messages
 ------------------------------------------------------------------------------}
procedure TCDWidgetSet.AppProcessMessages;
begin
  while True do
  begin
    // There are no more X messages to process
    if XPending(FDisplay) <= 0 then
    begin
      AppProcessInvalidates();
      Exit;
    end;
    AppProcessMessage();
  end;
end;

// Processes 1 X message
procedure TCDWidgetSet.AppProcessMessage;
var
  XEvent: TXEvent;
  XClientEvent: TXClientMessageEvent absolute XEvent ;
  WindowEntry: TWinControl;
  Sum: Integer;
  NewEvent: TXEvent;
  CurWindowInfo: TX11WindowInfo;
begin
  XNextEvent(FDisplay, @XEvent);

  // According to a comment in X.h, the valid event types start with 2!
  if XEvent._type >= 2 then
  begin
    WindowEntry := FindWindowByXID(XEvent.XAny.Window, CurWindowInfo);

    if not Assigned(WindowEntry) then
    begin
      DebugLn('LCL-CustomDrawn-X11: Received X event "%s" for unknown window %x',
        [GetXEventName(XEvent._type), PtrInt(XEvent.XAny.Window)]);
      Exit;
    end;

    CurWindowInfo.XEvent := @XEvent;

    case XEvent._type of
     X.DestroyNotify:
     begin
       //WindowList.Delete(lWindowListIndex);
     end;
     X.KeyPress:
     begin
       TCDWSCustomForm.EvKeyPressed(WindowEntry, CurWindowInfo, XEvent.xkey);
     end;
     X.KeyRelease:
     begin
       TCDWSCustomForm.EvKeyReleased(WindowEntry, CurWindowInfo, XEvent.xkey);
     end;
     X.ButtonPress:
     begin
       TCDWSCustomForm.EvMousePressed(WindowEntry, CurWindowInfo, XEvent.xbutton);
     end;
     X.ButtonRelease:
     begin
       TCDWSCustomForm.EvMouseReleased(WindowEntry, CurWindowInfo, XEvent.xbutton);
     end;
     X.EnterNotify:
     begin
       TCDWSCustomForm.EvMouseEnter(WindowEntry, CurWindowInfo);
     end;
     X.LeaveNotify:
     begin
       TCDWSCustomForm.EvMouseLeave(WindowEntry, CurWindowInfo);
     end;
     X.MotionNotify:
     begin
       TCDWSCustomForm.EvMouseMove(WindowEntry, CurWindowInfo, XEvent.xmotion);
     end;
     X.FocusIn:
     begin
       TCDWSCustomForm.EvFocusIn(WindowEntry, CurWindowInfo);
     end;
     X.FocusOut:
     begin
       TCDWSCustomForm.EvFocusOut(WindowEntry, CurWindowInfo);
     end;
     X.MapNotify:
     begin
//           WindowEntry.EvShow();
     end;
     X.UnmapNotify:
     begin
//           WindowEntry.EvHide();
     end;
     X.ReparentNotify:
     begin
//           WindowEntry.EvCreate();
     end;
     X.Expose:
     begin
       // This repeat really helps speeding up when maximized for example
       repeat
       until not XCheckTypedWindowEvent(FDisplay, XEvent.xexpose.window, X.Expose, @XEvent);
       // This check for count=0 is a performance tunning documented in
       // http://tronche.com/gui/x/xlib/events/exposure/expose.html
       if XEvent.xexpose.count = 0 then
       begin
         TCDWSCustomForm.EvPaint(WindowEntry, CurWindowInfo);
       end;
     end;
     X.ConfigureNotify:
     begin
       TCDWSCustomForm.EvConfigureNotify(WindowEntry, CurWindowInfo, XEvent.xconfigure);
     end;
     X.ClientMessage:
     begin
       if XClientEvent.message_type = CDWidgetSet.FWMPaint then begin
         {$ifdef VerboseCDEvents}
         DebugLn(Format('X11 event WM_PAINT - Window %d',[CurWindowInfo.Window]));
         {$endif}
         TCDWSCustomForm.EvPaintEx(WindowEntry, CurWindowInfo);
         WindowUpdated(CurWindowInfo.Window);
       end
       else
         TCDWSCustomForm.EvClientMessage(WindowEntry, CurWindowInfo, XEvent.xclient);
     end;
    else
      DebugLn('LCL-CustomDrawn-X11: Unhandled X11 event received: ', GetXEventName(XEvent._type));
    end;
  end;
end;

procedure TCDWidgetSet.AppProcessInvalidates;
var
  i: Integer;
  CurWindowInfo: TX11WindowInfo;
  lForm: TForm;
begin
  for i := 0 to Screen.FormCount-1 do
  begin
    lForm := Screen.Forms[i];
    if (not lForm.HandleObjectShouldBeVisible) or
      (not lForm.HandleAllocated) then Continue;
    CurWindowInfo := TX11WindowInfo(Screen.Forms[i].Handle);
    if CurWindowInfo.InvalidateRequestedInAnyControl then
    begin
      TCDWSCustomForm.EvPaint(lForm, CurWindowInfo);
      CurWindowInfo.InvalidateRequestedInAnyControl := False;
    end;
  end;
end;

function TCDWidgetSet.XStateToLCLState(XKeyState: cuint): TShiftState;
begin
  Result:= [];
  if (XKeyState and X.ShiftMask) <> 0 then Include(Result,ssShift);
  if (XKeyState and X.ControlMask) <> 0 then Include(Result,ssCtrl);
  if (XKeyState and X.Mod1Mask) <> 0 then Include(Result,ssAlt);
  if (XKeyState and X.Mod5Mask) <> 0 then Include(Result,ssAltGr);
end;

function TCDWidgetSet.GetAppHandle: THandle;
begin
  Result := THandle(FDisplay);
end;

(*
procedure TWinCEWidgetSet.CheckPipeEvents;
var
  lHandler: PPipeEventInfo;
//  lBytesAvail: dword;
//  SomethingChanged: Boolean;
  ChangedCount:integer;
begin
  lHandler := FWaitPipeHandlers;
  ChangedCount := 0;
  while (lHandler <> nil) and (ChangedCount < 10) do
  begin
    {
    roozbeh : ooops not supported
    SomethingChanged:=true;
    if Windows.PeekNamedPipe(lHandler^.Handle, nil, 0, nil, @lBytesAvail, nil) then
    begin
      if lBytesAvail <> 0 then
        lHandler^.OnEvent(lHandler^.UserData, [prDataAvailable])
      else
        SomethingChanged := false;
    end else
      lHandler^.OnEvent(lHandler^.UserData, [prBroken]);
    if SomethingChanged then
      lHandler := FWaitPipeHandlers
    else begin
      lHandler := lHandler^.Next;
      ChangedCount := 0;
    end;
    inc(ChangedCount);}
  end;
end;*)

{------------------------------------------------------------------------------
  Method: TWinCEWidgetSet.AppWaitMessage
  Params:  None
  Returns: Nothing

  Passes execution control to X11, but processes timer messages while waiting
 ------------------------------------------------------------------------------}
procedure TCDWidgetSet.AppWaitMessage;
var
  // timer variables
  rfds: baseunix.TFDSet;
  xconnnum, selectresult: integer;
  IsFirstTimeout: Boolean;
  AnyTimerProcessed: Boolean = False;
  lTimer: TCDTimer;
  lTimeoutInterval: Integer; // miliseconds
  i: Integer;
begin
  IsFirstTimeout := True;

  lTimeoutInterval := GetSmallestTimerInterval();
  // Limit the maximum interval, even if only to process Application.OnIdle or
  // for general safety
  if (lTimeoutInterval < 0) or (lTimeoutInterval >= 1000) then lTimeoutInterval := 1000;
  // To avoid consuming too much CPU, if the interval is zero, act as if it was 1
  if lTimeoutInterval = 0 then lTimeoutInterval := 1;

  while not Application.Terminated do
  begin
    xconnnum := XConnectionNumber(FDisplay);
    XFlush(FDisplay);

    if XPending(FDisplay) > 0 then Exit; // We have a X message to process

    // No X messages to process (we are idle). So do a timeout wait

    //if Assigned(FOnIdle) then
    //  OnIdle(self);
    fpFD_ZERO(rfds);
    fpFD_SET(xconnnum, rfds);

    // Add all other X connections
    for i := 0 to XConnections.Count-1 do
      fpFD_SET(cint(PtrInt(XConnections.Items[i])), rfds);

    selectresult := fpSelect(xconnnum + 1, @rfds, nil, nil, lTimeoutInterval);

    // Process all timers
    for i := 0 to GetTimerCount()-1 do
    begin
      lTimer := GetTimer(i);

      // if selectresult = 0 then a timeout occured, in other cases guess how
      // much time passed
      if selectresult = 0 then Inc(lTimer.NativeHandle, lTimeoutInterval)
      else Inc(lTimer.NativeHandle, 10);

      if lTimer.NativeHandle >= lTimer.Interval then
      begin
        lTimer.TimerFunc();
        AnyTimerProcessed := True;
        lTimer.NativeHandle := 0;
      end;
    end;
    if AnyTimerProcessed then AppProcessInvalidates();

    if selectresult <> 0 then  // We got a X event or the timeout happened
      Exit
    else
    begin
      // Process standard application Idle
      if (not Application.Terminated) and IsFirstTimeout then Application.Idle(False);

      //IsFirstTimeout := False; <- This affects ProcessAsyncCallQueue handling too, so we need LCL support for partial Idles before activating this

      Continue; // Go back and keep waiting for a message
    end;
  end;
end;

{------------------------------------------------------------------------------
  Method: TWinCEWidgetSet.AppTerminate
  Params:  None
  Returns: Nothing

  Tells Windows to halt and destroy
 ------------------------------------------------------------------------------}
procedure TCDWidgetSet.AppTerminate;
begin
  //DebugLn('Trace:TWinCEWidgetSet.AppTerminate - Start');
end;


procedure TCDWidgetSet.AppSetIcon(const Small, Big: HICON);
begin
end;

procedure TCDWidgetSet.AppSetTitle(const ATitle: string);
begin
end;

procedure TCDWidgetSet.AppSetVisible(const AVisible: Boolean);
begin
end;

function TCDWidgetSet.AppRemoveStayOnTopFlags(const ASystemTopAlso: Boolean = False): Boolean;
begin
end;

function TCDWidgetSet.AppRestoreStayOnTopFlags(const ASystemTopAlso: Boolean = False): Boolean;
begin
end;

procedure TCDWidgetSet.AppSetMainFormOnTaskBar(const DoSet: Boolean);
begin
end;


{------------------------------------------------------------------------------
  function: CreateTimer
  Params: Interval:
          TimerFunc: Callback
  Returns: a Timer id (use this ID to destroy timer)

  Design: A timer which calls TimerCallBackProc, is created.
    The TimerCallBackProc calls the TimerFunc.
 ------------------------------------------------------------------------------}
function TCDWidgetSet.CreateTimer(Interval: integer; TimerFunc: TWSTimerProc) : THandle;
var
  lTimer: TCDTimer;
begin
  lTimer := TCDTimer.Create;
  lTimer.Interval := Interval;
  lTimer.TimerFunc := TimerFunc;
  AddTimer(lTimer);
  Result := THandle(lTimer);
end;

{------------------------------------------------------------------------------
  function: DestroyTimer
  Params: TimerHandle
  Returns:
 ------------------------------------------------------------------------------}
function TCDWidgetSet.DestroyTimer(TimerHandle: THandle) : boolean;
var
  lTimer: TCDTimer absolute TimerHandle;
begin
  if TimerHandle <> 0 then
  begin
    RemoveTimer(lTimer);
    lTimer.Free;
  end;
end;
(*
procedure TWinCEWidgetSet.HandleWakeMainThread(Sender: TObject);
begin
  // wake up GUI thread by sending a message to it
  Windows.PostMessage(AppHandle, WM_NULL, 0, 0);
end;
*)
