{ $Id$}
{
 *****************************************************************************
 *                              QtWSControls.pp                              * 
 *                              ---------------                              * 
 *                                                                           *
 *                                                                           *
 *****************************************************************************

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
unit QtWSControls;

{$mode objfpc}{$H+}

interface

uses
  // Bindings
{$ifdef USE_QT_4_3}
  qt43,
{$else}
  qt4,
{$endif}
  qtwidgets, qtobjects,
  // LCL
  SysUtils, Classes, Types, Controls, LCLType, LCLProc, Forms, Graphics,
  StdCtrls,
  // Widgetset
  InterfaceBase, WSControls, WSLCLClasses;

type

  { TQtWSDragImageList }

  TQtWSDragImageList = class(TWSDragImageList)
  private
  protected
  public
  end;

  { TQtWSControl }

  TQtWSControl = class(TWSControl)
  private
  protected
  public
  end;

  { TQtWSWinControl }

  TQtWSWinControl = class(TWSWinControl)
  private
  protected
  public
    class function  CanFocus(const AWinControl: TWinControl): Boolean; override;
    class function  CreateHandle(const AWinControl: TWinControl;
          const AParams: TCreateParams): HWND; override;
    class procedure DestroyHandle(const AWinControl: TWinControl); override;
    class procedure Invalidate(const AWinControl: TWinControl); override;
  public
    class procedure AddControl(const AControl: TControl); override;
    class function  GetClientBounds(const AWincontrol: TWinControl; var ARect: TRect): Boolean; override;
    class function  GetClientRect(const AWincontrol: TWinControl; var ARect: TRect): Boolean; override;
    class procedure SetBounds(const AWinControl: TWinControl; const ALeft, ATop, AWidth, AHeight: Integer); override;
    class procedure SetBorderStyle(const AWinControl: TWinControl; const ABorderStyle: TBorderStyle); override;
    class procedure SetPos(const AWinControl: TWinControl; const ALeft, ATop: Integer); override;
    class procedure SetSize(const AWinControl: TWinControl; const AWidth, AHeight: Integer); override;
    class procedure ShowHide(const AWinControl: TWinControl); override; //TODO: rename to SetVisible(control, visible)
    class procedure SetColor(const AWinControl: TWinControl); override;
    class procedure SetCursor(const AWinControl: TWinControl; const ACursor: HCursor); override;
    class procedure SetFont(const AWinControl: TWinControl; const AFont: TFont); override;

    class procedure GetPreferredSize(const AWinControl: TWinControl;
      var PreferredWidth, PreferredHeight: integer; WithThemeSpace: Boolean); override;

//    class function  GetText(const AWinControl: TWinControl; var AText: String): Boolean; override;
//    class procedure SetText(const AWinControl: TWinControl; const AText: string); override;

    class procedure SetChildZPosition(const AWinControl, AChild: TWinControl;
                                      const AOldPos, ANewPos: Integer;
                                      const AChildren: TFPList); override;

    class procedure ConstraintsChange(const AWinControl: TWinControl); override;
  end;

  { TQtWSGraphicControl }

  TQtWSGraphicControl = class(TWSGraphicControl)
  private
  protected
  public
  end;

  { TQtWSCustomControl }

  TQtWSCustomControl = class(TWSCustomControl)
  private
  protected
  public
    class function  CreateHandle(const AWinControl: TWinControl;
          const AParams: TCreateParams): HWND; override;
    class procedure ShowHide(const AWinControl: TWinControl); override; //TODO: rename to SetVisible(control, visible)
  end;

  { TQtWSImageList }

  TQtWSImageList = class(TWSImageList)
  private
  protected
  public
  end;


implementation
const
  TBorderStyleToQtFrameShapeMap: array[TBorderStyle] of QFrameShape =
  (
 {bsNone}   QFrameNoFrame,
 {bsSingle} QFrameStyledPanel
  );

{------------------------------------------------------------------------------
  Method: TQtWSCustomControl.CreateHandle
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
class function  TQtWSCustomControl.CreateHandle(const AWinControl: TWinControl;
          const AParams: TCreateParams): HWND;
var
  QtAbstractScrollArea: TQtAbstractScrollArea;
begin
  {$ifdef VerboseQt}
    WriteLn('> TQtWSCustomControl.CreateHandle for ',dbgsname(AWinControl));
  {$endif}

  QtAbstractScrollArea := TQtAbstractScrollArea.Create(AWinControl, AParams);
  QtAbstractScrollArea.setFrameShape(TBorderStyleToQtFrameShapeMap[TCustomControl(AWinControl).BorderStyle]);
  QtAbstractScrollArea.AttachEvents;
  QtAbstractScrollArea.viewportNeeded;
  Result := THandle(QtAbstractScrollArea);

  {$ifdef VerboseQt}
    WriteLn('< TQtWSCustomControl.CreateHandle for ',dbgsname(AWinControl),' Result: ', dbgHex(Result));
  {$endif}
end;

{------------------------------------------------------------------------------
  Method: TQtWSCustomControl.ShowHide
  Params:  AWinControl     - the calling object

  Returns: Nothing

  Shows or hides a widget.
 ------------------------------------------------------------------------------}
class procedure TQtWSCustomControl.ShowHide(const AWinControl: TWinControl);
var
  Widget: TQtWidget;
  R: TRect;
begin
  {$ifdef VerboseQt}
    WriteLn('Trace:> [TQtWSCustomControl.ShowHide]');
  {$endif}

  if (AWinControl = nil) or not AWinControl.HandleAllocated then
    exit;

  Widget := TQtWidget(AWinControl.Handle);
  { if the widget is a form, this is a place to set the Tab order }
  if AWinControl.HandleObjectShouldBeVisible and (Widget is TQtMainWindow) then
  begin
    if fsModal in TForm(AWinControl).FormState then
    begin
      {$ifdef linux}
      QWidget_setWindowFlags(Widget.Widget, QtDialog);
      {$endif}
      Widget.setWindowModality(QtApplicationModal);
    end;
    TQtMainWindow(Widget).SetTabOrders;
    
    if TForm(AWinControl).FormStyle = fsMDIChild then
    begin
      {MDI windows have to be resized , since titlebar is included into widget geometry !}
      if not (csDesigning in AWinControl.ComponentState) then
      begin
        QWidget_contentsRect(Widget.Widget, @R);
        TForm(AWinControl).Left := 0;
        TForm(AWinControl).Top := 0;
        TForm(AWinControl).Width := TForm(AWinControl).Width + R.Left;
        TForm(AWinControl).Height := TForm(AWinControl).Height + R.Top;
        TForm(AWinControl).ReAlign;
      end;
    end;
  end;

  Widget.setVisible(AWinControl.HandleObjectShouldBeVisible);
  

  {$ifdef VerboseQt}
    Write('Trace:< [TQtWSCustomControl.ShowHide] ');

    if AWinControl is TForm then
      Write('Is TForm, ');

    if AWinControl.HandleObjectShouldBeVisible then
      WriteLn('Visible: True')
    else
      WriteLn('Visible: False');
  {$endif}
end;

{------------------------------------------------------------------------------
  Function: TQtWSWinControl.CanFocus
  Params:  TWinControl
  Returns: Boolean
 ------------------------------------------------------------------------------}
class function TQtWSWinControl.CanFocus(const AWinControl: TWinControl): Boolean;
var
  Widget: TQtWidget;
  FocusWidget: QWidgetH;
begin
  if AWinControl.HandleAllocated then
  begin
    Widget := TQtWidget(AWinControl.Handle);
    if Assigned(Widget.LCLObject.Parent) then
      FocusWidget := QWidget_focusWidget(TQtWidget(Widget.LCLObject.Parent.Handle).Widget)
    else
      FocusWidget := QWidget_focusWidget(Widget.Widget);
    
    Result := (FocusWidget <> nil) and
              QWidget_isEnabled(FocusWidget) and
              QWidget_isVisible(FocusWidget) and
              (QWidget_focusPolicy(FocusWidget) <> QtNoFocus);
  end else
    Result := False;
end;

{------------------------------------------------------------------------------
  Method: TQtWSWinControl.CreateHandle
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
class function TQtWSWinControl.CreateHandle(const AWinControl: TWinControl;
  const AParams: TCreateParams): HWND;
var
  QtWidget: TQtWidget;
begin
  {$ifdef VerboseQt}
    WriteLn('> TQtWSWinControl.CreateHandle for ',dbgsname(AWinControl));
  {$endif}
  QtWidget := TQtWidget.Create(AWinControl, AParams);

  QtWidget.AttachEvents;

  // Finalization

  Result := THandle(QtWidget);

  {$ifdef VerboseQt}
    WriteLn('< TQtWSWinControl.CreateHandle for ',dbgsname(AWinControl),' Result: ', dbgHex(Result));
  {$endif}
end;

{------------------------------------------------------------------------------
  Method: TQtWSWinControl.DestroyHandle
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
class procedure TQtWSWinControl.DestroyHandle(const AWinControl: TWinControl);
begin
  TQtWidget(AWinControl.Handle).Release;

  AWinControl.Handle := 0;
end;

{------------------------------------------------------------------------------
  Method: TQtWSWinControl.Invalidate
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
class procedure TQtWSWinControl.Invalidate(const AWinControl: TWinControl);
begin
  TQtWidget(AWinControl.Handle).Update;
end;

class procedure TQtWSWinControl.AddControl(const AControl: TControl);
begin
  if (AControl is TWinControl) and (TWinControl(AControl).HandleAllocated) then
    TQtWidget(TWinControl(AControl).Handle).setParent(TQtWidget(AControl.Parent.Handle).GetContainerWidget);
end;

class function TQtWSWinControl.GetClientBounds(const AWincontrol: TWinControl;
  var ARect: TRect): Boolean;
begin
  ARect := TQtWidget(AWinControl.Handle).getClientBounds;
  Result := True;
end;

class function TQtWSWinControl.GetClientRect(const AWincontrol: TWinControl;
  var ARect: TRect): Boolean;
begin
  ARect := TQtWidget(AWinControl.Handle).getClientBounds;
  OffsetRect(ARect, -ARect.Left, -ARect.Top);
  Result := True;
end;

class procedure TQtWSWinControl.GetPreferredSize(const AWinControl: TWinControl;
  var PreferredWidth, PreferredHeight: integer; WithThemeSpace: Boolean);
var
  PrefSize: TSize;
begin
  {$ifdef VerboseQt}
    WriteLn('> TQtWSWinControl.GetPreferredSSize for ',dbgsname(AWinControl));
  {$endif}
  QWidget_sizeHint(TQtWidget(AWinControl.Handle).Widget, @PrefSize);
  if (PrefSize.cx >= 0)
  and (PrefSize.cy >=0) then
  begin
    PreferredWidth := PrefSize.cx;
    PreferredHeight := PrefSize.cy;
  end;
end;

class procedure TQtWSWinControl.SetChildZPosition(const AWinControl,
                AChild: TWinControl; const AOldPos, ANewPos: Integer; const AChildren: TFPList);
begin
  {$note TODO: QWidget::stackUnder, QWidget::raise, QWidget::lower}
  inherited SetChildZPosition(AWinControl, AChild, AOldPos, ANewPos, AChildren);
end;

class procedure TQtWSWinControl.ConstraintsChange(const AWinControl: TWinControl);
const
  QtMaxContraint = $FFFFFF;
var
  Widget: TQtWidget;
  MaxW, MaxH: Integer;
begin
  Widget := TQtWidget(AWinControl.Handle);
  with AWinControl do
  begin
    Widget.setMinimumSize(Constraints.MinWidth, Constraints.MinHeight);
    if Constraints.MaxWidth = 0 then
      MaxW := QtMaxContraint
    else
      MaxW := Constraints.MaxWidth;
    if Constraints.MaxHeight = 0 then
      MaxH := QtMaxContraint
    else
      MaxH := Constraints.MaxHeight;
    Widget.setMaximumSize(MaxW, MaxH);
  end;
end;

{------------------------------------------------------------------------------
  Method: TQtWSWinControl.SetBounds
  Params:  AWinControl - the calling object
           ALeft, ATop - Position
           AWidth, AHeight - Size
  Returns: Nothing

  Sets the position and size of a widget
 ------------------------------------------------------------------------------}
class procedure TQtWSWinControl.SetBounds(const AWinControl: TWinControl;
  const ALeft, ATop, AWidth, AHeight: Integer);
begin
  TQtWidget(AWinControl.Handle).move(ALeft, ATop);
  TQtWidget(AWinControl.Handle).resize(AWidth, AHeight);
end;

{------------------------------------------------------------------------------
  Method: TQtWSWinControl.SetPos
  Params:  AWinControl - the calling object
           ALeft, ATop - Position
  Returns: Nothing

  Sets the position of a widget
 ------------------------------------------------------------------------------}
class procedure TQtWSWinControl.SetPos(const AWinControl: TWinControl;
  const ALeft, ATop: Integer);
begin
  TQtWidget(AWinControl.Handle).move(ALeft, ATop);
end;

{------------------------------------------------------------------------------
  Method: TQtWSWinControl.SetSize
  Params:  AWinControl     - the calling object
           AWidth, AHeight - Size
  Returns: Nothing

  Sets the size of a widget
 ------------------------------------------------------------------------------}
class procedure TQtWSWinControl.SetSize(const AWinControl: TWinControl;
  const AWidth, AHeight: Integer);
begin
  TQtWidget(AWinControl.Handle).resize(AWidth, AHeight);
end;

{------------------------------------------------------------------------------
  Method: TQtWSWinControl.ShowHide
  Params:  AWinControl     - the calling object

  Returns: Nothing

  Shows or hides a widget.
 ------------------------------------------------------------------------------}
class procedure TQtWSWinControl.ShowHide(const AWinControl: TWinControl);
var
  Widget: TQtWidget;
begin
  {$ifdef VerboseQt}
    WriteLn('Trace:> [TQtWSWinControl.ShowHide]');
  {$endif}

  if (AWinControl = nil) or not AWinControl.HandleAllocated then
    exit;

  Widget := TQtWidget(AWinControl.Handle);
  { if the widget is a form, this is a place to set the Tab order }
  if AWinControl.HandleObjectShouldBeVisible and (Widget is TQtMainWindow) then
    TQtMainWindow(Widget).SetTabOrders;

  Widget.setVisible(AWinControl.HandleObjectShouldBeVisible);

  {$ifdef VerboseQt}
    Write('Trace:< [TQtWSWinControl.ShowHide] ');

    if AWinControl is TForm then
      Write('Is TForm, ');

    if AWinControl.HandleObjectShouldBeVisible then
      WriteLn('Visible: True')
    else
      WriteLn('Visible: False');
  {$endif}
end;

{------------------------------------------------------------------------------
  Method: TQtWSWinControl.SetColor
  Params:  AWinControl     - the calling object
  Returns: Nothing

  Sets the color of the widget.
 ------------------------------------------------------------------------------}
class procedure TQtWSWinControl.SetColor(const AWinControl: TWinControl);
var
  QColor: TQColor;
  Color: TColor;
begin
  if AWinControl = nil then exit;

  if not AWinControl.HandleAllocated then exit;

  if AWinControl.Color = CLR_INVALID then exit;

  // Get the color numeric value (system colors are mapped to numeric colors depending on the widget style)
  Color := ColorToRGB(AWinControl.Color);
  
  // Fill QColor
  QColor_setRgb(QColorH(@QColor),Red(Color),Green(Color),Blue(Color));

  // Set color of the widget to QColor
  TQtWidget(AWinControl.Handle).SetColor(@QColor);
end;

{------------------------------------------------------------------------------
  Method: TQtWSWinControl.SetCursor
  Params:  AWinControl     - the calling object
  Returns: Nothing

  Sets the cursor of the widget.
 ------------------------------------------------------------------------------}
class procedure TQtWSWinControl.SetCursor(const AWinControl: TWinControl; const ACursor: HCursor);
begin
  if AWinControl = nil then exit;
  if not AWinControl.HandleAllocated then exit;
  
  TQtWidget(AWinControl.Handle).SetCursor(QCursorH(ACursor));
end;

{------------------------------------------------------------------------------
  Method: TQtWSWinControl.SetFont
  Params:  AWinControl - the calling object, AFont - object font
  Returns: Nothing

  Sets the font of the widget.
 ------------------------------------------------------------------------------}
class procedure TQtWSWinControl.SetFont(const AWinControl: TWinControl; const AFont: TFont);
var
  QColor: TQColor;
  Color: TColor;
begin
  QWidget_setFont(TQtWidget(AWinControl.Handle).Widget, TQtFont(AFont.Handle).Widget);
  
  if AFont.Color = CLR_INVALID then exit;

  Color := ColorToRGB(AFont.Color);
  QColor_setRgb(QColorH(@QColor),Red(Color),Green(Color),Blue(Color));
  TQtWidget(AWinControl.Handle).SetTextColor(@QColor);
end;

class procedure TQtWSWinControl.SetBorderStyle(const AWinControl: TWinControl;
  const ABorderStyle: TBorderStyle);
var
  Widget: TQtWidget;
begin
  Widget := TQtWidget(AWinControl.Handle);
  if Widget is TQtFrame then
    TQtFrame(Widget).setFrameShape(TBorderStyleToQtFrameShapeMap[ABorderStyle]);
end;

initialization

////////////////////////////////////////////////////
// I M P O R T A N T
////////////////////////////////////////////////////
// To improve speed, register only classes
// which actually implement something
////////////////////////////////////////////////////
//  RegisterWSComponent(TDragImageList, TQtWSDragImageList);
//  RegisterWSComponent(TControl, TQtWSControl);
  RegisterWSComponent(TWinControl, TQtWSWinControl);
//  RegisterWSComponent(TGraphicControl, TQtWSGraphicControl);
  RegisterWSComponent(TCustomControl, TQtWSCustomControl);
//  RegisterWSComponent(TImageList, TQtWSImageList);
////////////////////////////////////////////////////
end.
