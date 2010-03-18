{ $Id$}
{
 *****************************************************************************
 *                               QtWSForms.pp                                * 
 *                               ------------                                * 
 *                                                                           *
 *                                                                           *
 *****************************************************************************

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
unit QtWSForms;

{$mode objfpc}{$H+}

interface

{$I qtdefines.inc}

uses
  // Bindings
  qt4,
  qtobjects, qtwidgets, qtproc,
  // LCL
  SysUtils, Classes, Controls, LCLType, Forms,
  // Widgetset
  InterfaceBase, WSForms, WSProc, WSLCLClasses;

type

  { TQtWSScrollingWinControl }

  TQtWSScrollingWinControl = class(TWSScrollingWinControl)
  published
  end;

  { TQtWSScrollBox }

  TQtWSScrollBox = class(TWSScrollBox)
  published
    class procedure ScrollBy(const AWinControl: TScrollingWinControl;
      const DeltaX, DeltaY: integer); override;
  end;

  { TQtWSCustomFrame }

  TQtWSCustomFrame = class(TWSCustomFrame)
  published
    class procedure ScrollBy(const AWinControl: TScrollingWinControl;
      const DeltaX, DeltaY: integer); override;
  end;

  { TQtWSFrame }

  TQtWSFrame = class(TWSFrame)
  published
  end;

  { TQtWSCustomForm }

  TQtWSCustomForm = class(TWSCustomForm)
  private
    class function GetQtBorderStyle(const AFormBorderStyle: TFormBorderStyle): QtWindowFlags;
    class function GetQtBorderIcons(const AFormBorderStyle: TFormBorderStyle; ABorderIcons: TBorderIcons): QtWindowFlags;
    class function GetQtFormStyle(const AFormStyle: TFormStyle): QtWindowFlags;
    class procedure UpdateWindowFlags(const AWidget: TQtMainWindow;
      ABorderStyle: TFormBorderStyle; ABorderIcons: TBorderIcons; AFormStyle: TFormStyle);
  published
    class function CreateHandle(const AWinControl: TWinControl; const AParams: TCreateParams): TLCLIntfHandle; override;

    class procedure CloseModal(const ACustomForm: TCustomForm); override;
    class procedure DestroyHandle(const AWinControl: TWinControl); override;
    class procedure SetAllowDropFiles(const AForm: TCustomForm; AValue: Boolean); override;
    class procedure SetFormBorderStyle(const AForm: TCustomForm; const AFormBorderStyle: TFormBorderStyle); override;
    class procedure SetFormStyle(const AForm: TCustomform; const AFormStyle: TFormStyle); override;
    class procedure SetIcon(const AForm: TCustomForm; const Small, Big: HICON); override;
    class procedure SetPopupParent(const ACustomForm: TCustomForm;
       const APopupMode: TPopupMode; const APopupParent: TCustomForm); override;
    class procedure SetShowInTaskbar(const AForm: TCustomForm; const AValue: TShowInTaskbar); override;
    class procedure ShowModal(const ACustomForm: TCustomForm); override;
    class procedure SetBorderIcons(const AForm: TCustomForm; const ABorderIcons: TBorderIcons); override;
    class procedure SetAlphaBlend(const ACustomForm: TCustomForm;
       const AlphaBlend: Boolean; const Alpha: Byte); override;
  end;

  { TQtWSForm }

  TQtWSForm = class(TWSForm)
  published
  end;

  { TQtWSHintWindow }

  TQtWSHintWindow = class(TWSHintWindow)
  published
    class function CreateHandle(const AWinControl: TWinControl; const AParams: TCreateParams): TLCLIntfHandle; override;
  end;

  { TQtWSScreen }

  TQtWSScreen = class(TWSScreen)
  published
  end;

  { TQtWSApplicationProperties }

  TQtWSApplicationProperties = class(TWSApplicationProperties)
  published
  end;


implementation

uses QtWSControls;

{------------------------------------------------------------------------------
  Method: TQtWSCustomForm.CreateHandle
  Params:  None
  Returns: Nothing

  Creates a Qt Form and initializes it according to it's properties
 ------------------------------------------------------------------------------}
class function TQtWSCustomForm.CreateHandle(const AWinControl: TWinControl;
  const AParams: TCreateParams): TLCLIntfHandle;
var
  QtMainWindow: TQtMainWindow;
  Str: WideString;
  PopupParent: QWidgetH;
begin
  {$ifdef VerboseQt}
    WriteLn('[TQtWSCustomForm.CreateHandle] Height: ', IntToStr(AWinControl.Height),
     ' Width: ', IntToStr(AWinControl.Width));
  {$endif}

  // Creates the window

  if csDesigning in AWinControl.ComponentState then
    QtMainWindow := TQtDesignWidget.Create(AWinControl, AParams)
  else
    QtMainWindow := TQtMainWindow.Create(AWinControl, AParams);
  
  // Set�s initial properties

  Str := GetUtf8String(AWinControl.Caption);

  QtMainWindow.SetWindowTitle(@Str);

  if not (csDesigning in TCustomForm(AWinControl).ComponentState) then
  begin
    UpdateWindowFlags(QtMainWindow, TCustomForm(AWinControl).BorderStyle,
      TCustomForm(AWinControl).BorderIcons, TCustomForm(AWinControl).FormStyle);
  end;

  if not (TCustomForm(AWinControl).FormStyle in [fsMDIChild]) and
     (Application <> nil) and
     (Application.MainForm <> nil) and
     (Application.MainForm.HandleAllocated) and
     (Application.MainForm <> AWinControl) then
  begin
    if (TCustomForm(AWinControl).ShowInTaskBar in [stDefault, stNever])
       {$ifdef linux}
       {QtTool have not minimize button !}
       and not (TCustomForm(AWinControl).BorderStyle in [bsSizeToolWin, bsToolWindow])
       {$endif} then
      QtMainWindow.setShowInTaskBar(False);

    if Assigned(TCustomForm(AWinControl).PopupParent) then
      PopupParent := TQtWidget(TCustomForm(AWinControl).PopupParent.Handle).Widget
    else
      PopupParent := nil;
    QtMainWindow.setPopupParent(TCustomForm(AWinControl).PopupMode, PopupParent);
  end;

  // Sets Various Events
  QtMainWindow.AttachEvents;
  
  if (TCustomForm(AWinControl).FormStyle in [fsMDIChild]) and
     (Application.MainForm.FormStyle = fsMdiForm) and
     not (csDesigning in AWinControl.ComponentState) then
  begin
    QMdiArea_addSubWindow(TQtMainWindow(Application.MainForm.Handle).MDIAreaHandle, QtMainWindow.Widget, QtWindow);
    QWidget_setFocusProxy(QtMainWindow.Widget, QtMainWindow.getContainerWidget);
  end;
    

  // Return the handle
  Result := TLCLIntfHandle(QtMainWindow);
end;

{------------------------------------------------------------------------------
  Method: TQtWSCustomForm.CloseModal
  Params:
  Returns: Nothing
 ------------------------------------------------------------------------------}
class procedure TQtWSCustomForm.CloseModal(const ACustomForm: TCustomForm);
begin
  inherited CloseModal(ACustomForm);
end;

class procedure TQtWSCustomForm.DestroyHandle(const AWinControl: TWinControl);
var
  w: TQtWidget;
begin
  w := TQtWidget(AWinControl.Handle);
  {forms which have another widget as parent
   eg.form inside tabpage or mdichilds
   can segfault without hiding before release.
   So we save our day here.}
  if w.getVisible and (w.getParent <> nil) then
    w.Hide;
  w.Release;
end;

{------------------------------------------------------------------------------
  Method: TQtWSCustomForm.SetAllowDropFiles
  Params:
  Returns: Nothing
 ------------------------------------------------------------------------------}
class procedure TQtWSCustomForm.SetAllowDropFiles(const AForm: TCustomForm;
  AValue: Boolean);
begin
  if AForm.HandleAllocated then
    TQtMainWindow(AForm.Handle).setAcceptDropFiles(AValue);
end;

{------------------------------------------------------------------------------
  Method: TQtWSCustomForm.SetFormBorderStyle
  Params:
  Returns: Nothing
 ------------------------------------------------------------------------------}
class procedure TQtWSCustomForm.SetFormBorderStyle(const AForm: TCustomForm;
  const AFormBorderStyle: TFormBorderStyle);
begin
  UpdateWindowFlags(TQtMainWindow(AForm.Handle), AFormBorderStyle, AForm.BorderIcons, AForm.FormStyle);
end;

class procedure TQtWSCustomForm.SetFormStyle(const AForm: TCustomform;
  const AFormStyle: TFormStyle);
begin
  UpdateWindowFlags(TQtMainWindow(AForm.Handle), AForm.BorderStyle, AForm.BorderIcons, AFormStyle);
end;

{------------------------------------------------------------------------------
  Method: TQtWSCustomForm.SetIcon
  Params:
  Returns: Nothing
 ------------------------------------------------------------------------------}
class procedure TQtWSCustomForm.SetIcon(const AForm: TCustomForm; const Small, Big: HICON);
var
  Icon: TQtIcon;
begin
  Icon := TQtIcon(Big);
  if Icon <> nil then
    TQtWidget(AForm.Handle).setWindowIcon(Icon.Handle)
  else
    TQtWidget(AForm.Handle).setWindowIcon(nil);
end;

class procedure TQtWSCustomForm.SetPopupParent(const ACustomForm: TCustomForm;
  const APopupMode: TPopupMode; const APopupParent: TCustomForm);
var
  PopupParent: QWidgetH;
begin
  if Assigned(APopupParent) then
    PopupParent := TQtWidget(APopupParent.Handle).Widget
  else
    PopupParent := nil;
  TQtMainWindow(ACustomForm.Handle).setPopupParent(APopupMode, PopupParent);
end;

{------------------------------------------------------------------------------
  Method: TQtWSCustomForm.SetShowInTaskbar
  Params:
  Returns: Nothing
 ------------------------------------------------------------------------------}
class procedure TQtWSCustomForm.SetShowInTaskbar(const AForm: TCustomForm; const AValue: TShowInTaskbar);
var
  Enable: Boolean;
begin
  if (AForm.Parent<>nil) or not (AForm.HandleAllocated) then exit;

  Enable := AValue <> stNever;
  if (AValue = stDefault) and
     (Application<>nil) and
     (Application.MainForm <> nil) and
     (Application.MainForm <> AForm) then
    Enable := false;
  TQtMainWindow(AForm.Handle).setShowInTaskBar(Enable);
end;

{------------------------------------------------------------------------------
  Method: TQtWSCustomForm.ShowModal
  Params:
  Returns: Nothing
 ------------------------------------------------------------------------------}
class procedure TQtWSCustomForm.ShowModal(const ACustomForm: TCustomForm);
begin
  {
    Setting modal flags is done in TQtWSCustomControl.ShowHide
    Since that flags has effect only when Widget is not visible
    
    We can of course hide widget, set flags here and then show it, but we dont
    want window flickering :)
  }
end;

{------------------------------------------------------------------------------
  Method: TQtWSCustomForm.SetBorderIcons
  Params:
  Returns: Nothing
 ------------------------------------------------------------------------------}
class procedure TQtWSCustomForm.SetBorderIcons(const AForm: TCustomForm;
  const ABorderIcons: TBorderIcons);
begin
  UpdateWindowFlags(TQtMainWindow(AForm.Handle), AForm.BorderStyle, ABorderIcons, AForm.FormStyle);
end;

class procedure TQtWSCustomForm.SetAlphaBlend(const ACustomForm: TCustomForm;
  const AlphaBlend: Boolean; const Alpha: Byte);
begin
  if AlphaBlend then
    TQtMainWindow(ACustomForm.Handle).setWindowOpacity(Alpha / 255)
  else
    TQtMainWindow(ACustomForm.Handle).setWindowOpacity(1);
end;

{------------------------------------------------------------------------------
  Method: TQtWSCustomForm.GetQtWindowBorderStyle
  Params:  None
  Returns: Nothing

 ------------------------------------------------------------------------------}
class function TQtWSCustomForm.GetQtBorderStyle(const AFormBorderStyle: TFormBorderStyle): QtWindowFlags;
begin
  case AFormBorderStyle of
    bsNone:
      Result := QtWindow or QtFramelessWindowHint;
    bsSingle:
      Result := QtWindow or QtMSWindowsFixedSizeDialogHint;
    bsSizeable:
      Result := QtWindow;
    bsDialog:
      Result := QtDialog or QtMSWindowsFixedSizeDialogHint;
    bsToolWindow:
      Result := QtTool or QtMSWindowsFixedSizeDialogHint;
    bsSizeToolWin:
      // qt on most platforms (except windows) doesn't have sizeToolWin, it's regular qtWindow
      Result := {$ifdef windows}QtTool{$else}QtWindow{$endif}; 
    else
      Result := QtWidget;
  end;
end;

{------------------------------------------------------------------------------
  Method: TQtWSCustomForm.SetQtBorderIcons
  Params:  None
  Returns: Nothing

  Same comment as SetQtWindowBorderStyle above
 ------------------------------------------------------------------------------}
class function TQtWSCustomForm.GetQtBorderIcons(const AFormBorderStyle: TFormBorderStyle; ABorderIcons: TBorderIcons): QtWindowFlags;
begin
  Result := 0;

  case AFormBorderStyle of
    bsNone: Exit;
    bsDialog: ABorderIcons := ABorderIcons - [biMaximize, biMinimize];
    bsToolWindow, bsSizeToolWin: ABorderIcons := ABorderIcons - [biMaximize, biMinimize, biHelp];
  end;

  if (biSystemMenu in ABorderIcons) then
    Result := Result or QtWindowSystemMenuHint;

  if (biMinimize in ABorderIcons) then
    Result := Result or QtWindowMinimizeButtonHint;

  if (biMaximize in ABorderIcons) then
    Result := Result or QtWindowMaximizeButtonHint;

  if (biHelp in ABorderIcons) then
    Result := Result or QtWindowContextHelpButtonHint;
end;

class function TQtWSCustomForm.GetQtFormStyle(const AFormStyle: TFormStyle): QtWindowFlags;
begin
  if AFormStyle in [fsStayOnTop, fsSplash] then
    Result := QtWindowStaysOnTopHint
  else
    Result := 0;
end;

class procedure TQtWSCustomForm.UpdateWindowFlags(const AWidget: TQtMainWindow;
  ABorderStyle: TFormBorderStyle; ABorderIcons: TBorderIcons; AFormStyle: TFormStyle);
var
  Flags: QtWindowFlags;
  AVisible: Boolean;
begin
  AVisible := AWidget.getVisible;
  Flags := GetQtBorderStyle(ABorderStyle) or GetQtFormStyle(AFormStyle) or GetQtBorderIcons(ABorderStyle, ABorderIcons);
  if (Flags and QtFramelessWindowHint) = 0 then
    Flags := Flags or QtWindowTitleHint or QtCustomizeWindowHint
      or QtWindowCloseButtonHint;

  if not (csDesigning in AWidget.LCLObject.ComponentState) then
    AWidget.setWindowFlags(Flags);
  AWidget.setVisible(AVisible);
end;

{ TQtWSHintWindow }

class function TQtWSHintWindow.CreateHandle(const AWinControl: TWinControl; const AParams: TCreateParams): TLCLIntfHandle;
var
  QtMainWindow: TQtMainWindow;
begin
  QtMainWindow := TQtHintWindow.Create(AWinControl, AParams);
  // Sets Various Events
  QtMainWindow.AttachEvents;
  Result := TLCLIntfHandle(QtMainWindow);
end;

{ TQtWSScrollBox }

class procedure TQtWSScrollBox.ScrollBy(
  const AWinControl: TScrollingWinControl; const DeltaX, DeltaY: integer);
var
  Widget: TQtCustomControl;
begin
  if not WSCheckHandleAllocated(AWinControl, 'ScrollBy') then
    Exit;
  Widget := TQtCustomControl(AWinControl.Handle);
  Widget.viewport.scroll(-DeltaX, -DeltaY);
end;

{ TQtWSCustomFrame }

class procedure TQtWSCustomFrame.ScrollBy(
  const AWinControl: TScrollingWinControl; const DeltaX, DeltaY: integer);
var
  Widget: TQtCustomControl;
begin
  if not WSCheckHandleAllocated(AWinControl, 'ScrollBy') then
    Exit;
  Widget := TQtCustomControl(AWinControl.Handle);
  Widget.viewport.scroll(-DeltaX, -DeltaY);
end;

end.
