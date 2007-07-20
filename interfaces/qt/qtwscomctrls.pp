{ $Id$}
{
 *****************************************************************************
 *                              QtWSComCtrls.pp                              * 
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
unit QtWSComCtrls;

{$mode delphi}{$H+}

interface

uses
  // Bindings
{$ifdef USE_QT_4_3}
  qt43,
{$else}
  qt4,
{$endif}
  qtwidgets, qtprivate, qtobjects,
  // LCL
  Classes, ComCtrls, Controls, LCLType, Graphics, LCLProc, LCLIntf, Forms,
  // Widgetset
  WSProc, WSComCtrls, WSLCLClasses;

type

  { TQtWSStatusBar }

  TQtWSStatusBar = class(TWSStatusBar)
  private
  protected
  public
    class function  CreateHandle(const AWinControl: TWinControl; const AParams: TCreateParams): HWND; override;
    class procedure DestroyHandle(const AWinControl: TWinControl); override;
    class procedure PanelUpdate(const AStatusBar: TStatusBar; PanelIndex: integer); override;
    class procedure SetPanelText(const AStatusBar: TStatusBar; PanelIndex: integer); override;
    class procedure Update(const AStatusBar: TStatusBar); override;
    class procedure GetPreferredSize(const AWinControl: TWinControl;
     var PreferredWidth, PreferredHeight: integer; WithThemeSpace: Boolean); override;
  end;

  { TQtWSTabSheet }

  TQtWSTabSheet = class(TWSTabSheet)
  private
  protected
  public
  end;

  { TQtWSPageControl }

  TQtWSPageControl = class(TWSPageControl)
  private
  protected
  public
  end;

  { TQtWSCustomListView }

  TQtWSCustomListView = class(TWSCustomListView)
  private
  protected
  public
    class function  CreateHandle(const AWinControl: TWinControl;
     const AParams: TCreateParams): TLCLIntfHandle; override;
  public
    class procedure ColumnDelete(const ALV: TCustomListView; const AIndex: Integer); override;
    class procedure ColumnInsert(const ALV: TCustomListView; const AIndex: Integer; const AColumn: TListColumn); override;
    class function  ColumnGetWidth(const ALV: TCustomListView; const AIndex: Integer; const AColumn: TListColumn): Integer; override;
    class procedure ColumnSetWidth(const ALV: TCustomListView; const AIndex: Integer; const AColumn: TListColumn; const AWidth: Integer); override;
    class procedure ColumnSetVisible(const ALV: TCustomListView; const AIndex: Integer; const AColumn: TListColumn; const AVisible: Boolean); override;
    class procedure ColumnSetAlignment(const ALV: TCustomListView; const AIndex: Integer; const AColumn: TListColumn; const AAlignment: TAlignment); override;
    class procedure ColumnSetAutoSize(const ALV: TCustomListView; const AIndex: Integer; const AColumn: TListColumn; const AAutoSize: Boolean); override;
    class procedure ColumnSetCaption(const ALV: TCustomListView; const AIndex: Integer; const AColumn: TListColumn; const ACaption: String); override;
    class procedure ColumnSetImage(const ALV: TCustomListView; const AIndex: Integer; const AColumn: TListColumn; const AImageIndex: Integer); override;
    
    class procedure ColumnSetMinWidth(const ALV: TCustomListView; const AIndex: Integer; const AColumn: TListColumn; const AMinWidth: integer); override;
    class procedure ColumnMove(const ALV: TCustomListView; const AOldIndex, ANewIndex: Integer; const AColumn: TListColumn); override;
    
    
    {items}
    class procedure ItemInsert(const ALV: TCustomListView; const AIndex: Integer; const AItem: TListItem); override;
    class procedure ItemDelete(const ALV: TCustomListView; const AIndex: Integer); override;
    class function  ItemGetChecked(const ALV: TCustomListView; const AIndex: Integer; const AItem: TListItem): Boolean; override;
    class procedure ItemSetChecked(const ALV: TCustomListView; const AIndex: Integer; const AItem: TListItem; const AChecked: Boolean); override;
    class function  ItemGetPosition(const ALV: TCustomListView; const AIndex: Integer): TPoint; override;
    class function  ItemGetState(const ALV: TCustomListView; const AIndex: Integer; const AItem: TListItem; const AState: TListItemState; out AIsSet: Boolean): Boolean; override; // returns True if supported
    class procedure ItemSetState(const ALV: TCustomListView; const AIndex: Integer; const AItem: TListItem; const AState: TListItemState; const AIsSet: Boolean); override;
    class procedure ItemSetText(const ALV: TCustomListView; const AIndex: Integer; const AItem: TListItem; const ASubIndex: Integer; const AText: String); override;
    class procedure ItemShow(const ALV: TCustomListView; const AIndex: Integer; const AItem: TListItem; const PartialOK: Boolean); override;
    class function  ItemDisplayRect(const ALV: TCustomListView; const AIndex, ASubItem: Integer; ACode: TDisplayCode): TRect; override;
    
    {parent}
    class function GetFocused(const ALV: TCustomListView): Integer; override;
    class function GetItemAt(const ALV: TCustomListView; x,y: integer): Integer; override;
    class function GetSelCount(const ALV: TCustomListView): Integer; override;
    class function GetSelection(const ALV: TCustomListView): Integer; override;
    class procedure SetSort(const ALV: TCustomListView; const AType: TSortType; const AColumn: Integer); override;
    
    class function GetBoundingRect(const ALV: TCustomListView): TRect; override;

    (*
    // Column

    class procedure ColumnSetMaxWidth(const ALV: TCustomListView; const AIndex: Integer; const AColumn: TListColumn; const AMaxWidth: Integer); override;


    // Item

    class procedure ItemSetImage(const ALV: TCustomListView; const AIndex: Integer; const AItem: TListItem; const ASubIndex, AImageIndex: Integer); virtual;
    class function ItemSetPosition(const ALV: TCustomListView; const AIndex: Integer; const ANewPosition: TPoint): Boolean; virtual;

    // LV
    class procedure BeginUpdate(const ALV: TCustomListView); virtual;
    class procedure EndUpdate(const ALV: TCustomListView); virtual;


    class function GetDropTarget(const ALV: TCustomListView): Integer; virtual;

    class function GetHoverTime(const ALV: TCustomListView): Integer; virtual;

    class function GetTopItem(const ALV: TCustomListView): Integer; virtual;
    class function GetViewOrigin(const ALV: TCustomListView): TPoint; virtual;
    class function GetVisibleRowCount(const ALV: TCustomListView): Integer; override;

    class procedure SetAllocBy(const ALV: TCustomListView; const AValue: Integer); virtual;
    class procedure SetDefaultItemHeight(const ALV: TCustomListView; const AValue: Integer); virtual;
    class procedure SetHotTrackStyles(const ALV: TCustomListView; const AValue: TListHotTrackStyles); virtual;
    class procedure SetHoverTime(const ALV: TCustomListView; const AValue: Integer); virtual;
//    class procedure SetIconOptions(const ALV: TCustomListView; const AValue: TIconOptions); virtual;
    class procedure SetImageList(const ALV: TCustomListView; const AList: TListViewImageList; const AValue: TCustomImageList); virtual;
    class procedure SetProperty(const ALV: TCustomListView; const AProp: TListViewProperty; const AIsSet: Boolean); virtual;
    class procedure SetProperties(const ALV: TCustomListView; const AProps: TListViewProperties); virtual;
    class procedure SetScrollBars(const ALV: TCustomListView; const AValue: TScrollStyle); virtual;

    class procedure SetViewOrigin(const ALV: TCustomListView; const AValue: TPoint); virtual;
    class procedure SetViewStyle(const ALV: TCustomListView; const Avalue: TViewStyle); virtual;
    *)
  end;

  { TQtWSListView }

  TQtWSListView = class(TWSListView)
  private
  protected
  public
  end;

  { TQtWSProgressBar }

  TQtWSProgressBar = class(TWSProgressBar)
  private
  protected
  public
    class function  CreateHandle(const AWinControl: TWinControl; const AParams: TCreateParams): HWND; override;
    class procedure ApplyChanges(const AProgressBar: TCustomProgressBar); override;
    class procedure SetPosition(const AProgressBar: TCustomProgressBar; const NewPosition: integer); override;
  end;

  { TQtWSCustomUpDown }

  TQtWSCustomUpDown = class(TWSCustomUpDown)
  private
  protected
  public
  end;

  { TQtWSUpDown }

  TQtWSUpDown = class(TWSUpDown)
  private
  protected
  public
  end;

  { TQtWSToolButton }

  TQtWSToolButton = class(TWSToolButton)
  private
  protected
  public
    class function  CreateHandle(const AWinControl: TWinControl; const AParams: TCreateParams): HWND; override;
    class function  GetText(const AWinControl: TWinControl; var AText: String): Boolean; override;
    class procedure SetText(const AWinControl: TWinControl; const AText: String); override;
    class procedure SetColor(const AWinControl: TWinControl); override;
  end;

  { TQtWSToolBar }

  TQtWSToolBar = class(TWSToolBar)
  private
  protected
  public
    class function  CreateHandle(const AWinControl: TWinControl; const AParams: TCreateParams): HWND; override;
    class procedure SetColor(const AWinControl: TWinControl); override;
  end;

  { TQtWSTrackBar }

  TQtWSTrackBar = class(TWSTrackBar)
  private
  protected
  public
    class function  CreateHandle(const AWinControl: TWinControl; const AParams: TCreateParams): HWND; override;
    class procedure ApplyChanges(const ATrackBar: TCustomTrackBar); override;
    class function  GetPosition(const ATrackBar: TCustomTrackBar): integer; override;
    class procedure SetPosition(const ATrackBar: TCustomTrackBar; const NewPosition: integer); override;
  end;

  { TQtWSCustomTreeView }

  TQtWSCustomTreeView = class(TWSCustomTreeView)
  private
  protected
  public
  end;

  { TQtWSTreeView }

  TQtWSTreeView = class(TWSTreeView)
  private
  protected
  public
  end;


implementation


{ TQtWSToolButton }

class function TQtWSToolButton.CreateHandle(const AWinControl: TWinControl; const AParams: TCreateParams): HWND;
var
  QtToolButton: TQtToolButton;
begin
  QtToolButton := TQtToolButton.Create(AWinControl, AParams);
  QtToolButton.AttachEvents;

  Result := THandle(QtToolButton);
end;


{------------------------------------------------------------------------------
  Method: TQtWSToolButton.GetText
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
class function TQtWSToolButton.GetText(const AWinControl: TWinControl; var AText: String): Boolean;
var
  Str: WideString;
begin
  TQtToolButton(AWinControl.Handle).Text(@Str);

  AText := UTF8Encode(Str);

  Result := True;
end;

{------------------------------------------------------------------------------
  Method: TQtWSToolButton.SetText
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
class procedure TQtWSToolButton.SetText(const AWinControl: TWinControl; const AText: String);
var
  Str: WideString;
begin
  Str := UTF8Decode(AText);

  TQtToolButton(AWinControl.Handle).SetText(@Str);
end;

{------------------------------------------------------------------------------
  Method: TQtWSToolButton.SetColor
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
class procedure TQtWSToolButton.SetColor(const AWinControl: TWinControl);
var
  QColor: TQColor;
  Color: TColor;
begin
  if not WSCheckHandleAllocated(AWincontrol, 'SetColor')
  then Exit;

  if AWinControl.Color = CLR_INVALID then exit;

  // Get the color numeric value (system colors are mapped to numeric colors depending on the widget style)
  Color:=ColorToRGB(AWinControl.Color);

  // Fill QColor
  QColor_setRgb(@QColor,Red(Color),Green(Color),Blue(Color));

  // Set color of the widget to QColor
  TQtAbstractButton(AWinControl.Handle).SetColor(@QColor);
end;

{ TQtWSToolBar }

class function TQtWSToolBar.CreateHandle(const AWinControl: TWinControl; const AParams: TCreateParams): HWND;
var
  QtToolBar: TQtToolBar;
begin
  QtToolBar := TQtToolBar.Create(AWinControl, AParams);
  QtToolBar.AttachEvents;

  Result := THandle(QtToolBar);
end;

{------------------------------------------------------------------------------
  Method: TQtWSToolBar.SetColor
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
class procedure TQtWSToolBar.SetColor(const AWinControl: TWinControl);
var
  QColor: TQColor;
  Color: TColor;
begin
  if not WSCheckHandleAllocated(AWincontrol, 'SetColor')
  then Exit;

  if AWinControl.Color = CLR_INVALID then exit;

  // Get the color numeric value (system colors are mapped to numeric colors depending on the widget style)
  Color:=ColorToRGB(AWinControl.Color);

  // Fill QColor
  QColor_setRgb(@QColor,Red(Color),Green(Color),Blue(Color));

  // Set color of the widget to QColor
  TQtToolBar(AWinControl.Handle).SetColor(@QColor);
end;

{ TQtWSTrackBar }

class function TQtWSTrackBar.CreateHandle(const AWinControl: TWinControl; const AParams: TCreateParams): HWND;
var
  QtTrackBar: TQtTrackBar;
begin
  QtTrackBar := TQtTrackBar.Create(AWinControl, AParams);
  QtTrackBar.AttachEvents;

  Result := THandle(QtTrackBar);
end;

class procedure TQtWSTrackBar.ApplyChanges(const ATrackBar: TCustomTrackBar);
var
  QtTrackBar: TQtTrackBar;
begin

  QtTrackBar := TQtTrackBar(ATrackBar.Handle);

  QtTrackBar.setRange(ATrackBar.Min, ATrackBar.Max);

  case ATrackBar.TickMarks of
    tmBoth:QtTrackBar.SetTickPosition(QSliderTicksBothSides);
    tmTopLeft:QtTrackBar.SetTickPosition(QSliderTicksAbove);
    tmBottomRight:QtTrackBar.SetTickPosition(QSliderTicksBelow);
  end;

  if QAbstractSlider_pageStep(QAbstractSliderH(QtTrackBar.Widget)) <> ATrackBar.PageSize then
    QtTrackBar.setPageStep(ATrackBar.PageSize);
  if QSlider_tickInterval(QSliderH(QtTrackBar.Widget)) <> ATrackBar.Frequency then
    QtTrackBar.setTickInterval(ATrackBar.Frequency);
  if QAbstractSlider_value(QAbstractSliderH(QtTrackBar.Widget)) <> ATrackBar.Position then
    QtTrackBar.setSliderPosition(ATrackBar.Position);

  case ATrackBar.Orientation of
    trVertical:
    begin
      QtTrackBar.Hide;
      QtTrackBar.setOrientation(QtVertical);
      QtTrackBar.setInvertedAppereance(False);
      QtTrackBar.setInvertedControls(False);
      QtTrackBar.Show;
    end;
    else {trHorizontal}
    begin
      QtTrackBar.Hide;
      QtTrackBar.setOrientation(QtHorizontal);
      QtTrackBar.setInvertedAppereance(False);
      QtTrackBar.setInvertedControls(False);
      QtTrackBar.Show;
    end;
  end;
end;

class function  TQtWSTrackBar.GetPosition(const ATrackBar: TCustomTrackBar): integer;
var
  QtTrackBar: TQtTrackBar;
begin
  QtTrackBar := TQtTrackBar(ATrackBar.Handle);
  Result := QAbstractSlider_value(QAbstractSliderH(QtTrackBar.Widget));
end;

class procedure TQtWSTrackBar.SetPosition(const ATrackBar: TCustomTrackBar; const NewPosition: integer);
var
  QtTrackBar: TQtTrackBar;
begin
  QtTrackBar := TQtTrackBar(ATrackBar.Handle);
  QtTrackBar.setValue(NewPosition);
end;

{ TQtWSProgressBar }

class function TQtWSProgressBar.CreateHandle(const AWinControl: TWinControl; const AParams: TCreateParams): HWND;
var
  QtProgressBar: TQtProgressBar;
begin
  QtProgressBar := TQtProgressBar.Create(AWinControl, AParams);
  QtProgressBar.AttachEvents;
  Result := THandle(QtProgressBar);
end;

class procedure TQtWSProgressBar.ApplyChanges(const AProgressBar: TCustomProgressBar);
var
  QtProgressBar: TQtProgressBar;
begin
  QtProgressBar := TQtProgressBar(AProgressBar.Handle);

//  if AProgressBar.Smooth then
//    gtk_progress_bar_set_bar_style (GTK_PROGRESS_BAR(Pointer(Pointer(wHandle))),
//                                         GTK_PROGRESS_CONTINUOUS)
//   else gtk_progress_bar_set_bar_style (GTK_PROGRESS_BAR(Pointer(Pointer(wHandle))),
//                                         GTK_PROGRESS_DISCRETE);

  case AProgressBar.Orientation of
    pbVertical:
    begin
      QtProgressBar.setOrientation(QtVertical);
      QtProgressBar.setInvertedAppearance(False);
    end;
    pbRightToLeft:
    begin
      QtProgressBar.setOrientation(QtHorizontal);
      QtProgressBar.setInvertedAppearance(True);
    end;
    pbTopDown:
    begin
      QtProgressBar.setOrientation(QtVertical);
      QtProgressBar.setInvertedAppearance(True);
    end;
  else { pbHorizontal is default }
    QtProgressBar.setOrientation(QtHorizontal);
    QtProgressBar.setInvertedAppearance(False);
  end;

  if AProgressBar.BarShowText then
  begin
//       gtk_progress_set_format_string (GTK_PROGRESS(Pointer(Pointer(wHandle))),
//                                       '%v from [%l-%u] (=%p%%)');

    QtProgressBar.setTextVisible(True);
  end
  else QtProgressBar.setTextVisible(False);

  // The position, minumum and maximum values
  QtProgressBar.setValue(AProgressBar.Position);

  QtProgressBar.setRange(AProgressBar.Min, AProgressBar.Max);
end;

class procedure TQtWSProgressBar.SetPosition(const AProgressBar: TCustomProgressBar; const NewPosition: integer);
begin
  TQtProgressBar(AProgressBar.Handle).setValue(NewPosition);
end;

{ TQtWSStatusBar }

class function TQtWSStatusBar.CreateHandle(const AWinControl: TWinControl; const AParams: TCreateParams): HWND;
var
  QtStatusBar: TQtStatusBar;
  Str: WideString;
  i: Integer;
  R: TRect;
begin
  QtStatusBar := TQtStatusBar.Create(AWinControl, AParams);
  QtStatusBar.AttachEvents;

  if TStatusBar(AWinControl).SimplePanel then
  begin
    Str := UTF8Decode(TStatusBar(AWinControl).SimpleText);
    QtStatusBar.showMessage(@Str);
  end else
  if TStatusBar(AWinControl).Panels.Count > 0 then
  begin
    SetLength(QtStatusBar.APanels, TStatusBar(AWinControl).Panels.Count);
    for i := 0 to TStatusBar(AWinControl).Panels.Count - 1 do
    begin
      Str := UTF8Decode(TStatusBar(AWinControl).Panels[i].Text);
      QtStatusBar.APanels[i] := QLabel_create(@Str, QtStatusBar.Widget);

      QFrame_setLineWidth(QFrameH(QtStatusBar.APanels[i]), 1);
      QFrame_setMidLineWidth(QFrameH(QtStatusBar.APanels[i]), 0);
      
      if TStatusBar(AWinControl).Panels[i].Bevel = pbNone then
      QFrame_setFrameStyle(QFrameH(QtStatusBar.APanels[i]), Ord(QFrameNoFrame))
      else
      if TStatusBar(AWinControl).Panels[i].Bevel = pbLowered then
      QFrame_setFrameStyle(QFrameH(QtStatusBar.APanels[i]),Ord(QFramePanel) or Ord(QFrameSunken))
      else
      if TStatusBar(AWinControl).Panels[i].Bevel = pbRaised then
      QFrame_setFrameStyle(QFrameH(QtStatusBar.APanels[i]), Ord(QFramePanel) or Ord(QFrameRaised));
      
    //  QWidget_setContentsMargins(QtStatusBar.APanels[i], 0, 0, 2, 0);
      
      QWidget_frameGeometry(QtStatusBar.Widget, @R);
      QWidget_setGeometry(QtStatusBar.APanels[i], 0, 0, TStatusBar(AWinControl).Panels[i].Width, R.Bottom);
      QStatusBar_addWidget(QStatusBarH(QtStatusBar.Widget),QtStatusBar. APanels[i], 100);
    end;
  end;
  
  {some systems doesn't show statusbar inside mainwindow
   (linux tested on FC3,FC4,FC7 ).}
  {$ifdef linux}
  if Assigned(AWinControl.Parent)
  and (AWinControl.Parent.Handle = Application.MainForm.Handle)
  then
    QMainWindow_setStatusBar(QMainWindowH(TQtMainWindow(AWinControl.Parent.Handle).Widget), QStatusBarH(QtStatusBar.Widget));
  {$endif}
    
  // Return handle

  Result := THandle(QtStatusBar);
end;

class procedure TQtWSStatusBar.DestroyHandle(const AWinControl: TWinControl);
var
  QtStatusBar: TQtStatusBar;
  i: Integer;
begin

  QtStatusBar := TQtStatusBar(AWinControl.Handle);
  
  if length(QtStatusBar.APanels) > 0 then
  begin
    for i := High(QtStatusBar.APanels) downto 0 do
    begin
      QStatusBar_removeWidget(QStatusBarH(QtStatusBar.Widget), QtStatusBar.APanels[i]);
      QLabel_destroy(QtStatusBar.APanels[i]);
    end;
    SetLength(QtStatusBar.APanels, 0);
  end;
  
  TQtStatusBar(AWinControl.Handle).Free;

  AWinControl.Handle := 0;
end;

class procedure TQtWSStatusBar.PanelUpdate(const AStatusBar: TStatusBar; PanelIndex: integer);
var
  QtStatusBar: TQtStatusBar;
  Str: Widestring;
  i: Integer;
begin
  QtStatusBar := TQtStatusBar(AStatusBar.Handle);
  if AStatusBar.SimplePanel then
  begin
  
    if Length(QtStatusBar.APanels) > 0 then
    begin
      for i := High(QtStatusBar.APanels) downto 0 do
      begin
        QStatusBar_removeWidget(QStatusBarH(QtStatusBar.Widget), QtStatusBar.APanels[i]);
        QLabel_destroy(QtStatusBar.APanels[i]);
      end;
      SetLength(QtStatusBar.APanels, 0);
    end;
      
    Str := UTF8Decode(AStatusBar.SimpleText);
    QtStatusBar.showMessage(@Str);
    
  end else
  if AStatusBar.Panels.Count > 0 then
  begin
  
    QStatusBar_clearMessage(QStatusBarH(QtStatusBar.Widget));
    
    if (PanelIndex >= Low(QtStatusBar.APanels)) and (PanelIndex <= High(QtStatusBar.APanels)) then
    begin
    
      Str := UTF8Decode(AStatusBar.Panels[PanelIndex].Text);
      
      QLabel_setText(QtStatusBar.APanels[PanelIndex], @Str);
      
      if AStatusBar.Panels[PanelIndex].Bevel = pbNone then
      QFrame_setFrameStyle(QFrameH(QtStatusBar.APanels[PanelIndex]), Ord(QFrameNoFrame))
      else
      if AStatusBar.Panels[PanelIndex].Bevel = pbLowered then
      QFrame_setFrameStyle(QFrameH(QtStatusBar.APanels[PanelIndex]),Ord(QFrameWinPanel) or Ord(QFrameSunken))
      else
      if AStatusBar.Panels[PanelIndex].Bevel = pbRaised then
      QFrame_setFrameStyle(QFrameH(QtStatusBar.APanels[PanelIndex]), Ord(QFrameWinPanel) or Ord(QFrameRaised));
      
    end;
  end;
end;

class procedure TQtWSStatusBar.SetPanelText(const AStatusBar: TStatusBar; PanelIndex: integer);
var
  QtStatusBar: TQtStatusBar;
  Str: Widestring;
begin
  QtStatusBar := TQtStatusBar(AStatusBar.Handle);
  if AStatusBar.SimplePanel then
  begin
    Str := UTF8Decode(AStatusBar.SimpleText);
    QtStatusBar.showMessage(@Str);
  end else
  begin
    if (PanelIndex >= Low(QtStatusBar.APanels)) and (PanelIndex <= High(QtStatusBar.APanels)) then
    begin
      Str := UTF8Decode(AStatusBar.Panels[PanelIndex].Text);
      QLabel_setText(QtStatusBar.APanels[PanelIndex], @Str);
    end;
  end;
end;

class procedure TQtWSStatusBar.Update(const AStatusBar: TStatusBar);
var
  QtStatusBar: TQtStatusBar;
  i: Integer;
  Str: WideString;
  R: TRect;
begin
  QtStatusBar := TQtStatusBar(AStatusBar.Handle);
  if AStatusBar.SimplePanel then
  begin
    if Length(QtStatusBar.APanels) > 0 then
    begin
    
      for i := High(QtStatusBar.APanels) downto 0 do
      begin
        QStatusBar_removeWidget(QStatusBarH(QtStatusBar.Widget), QtStatusBar.APanels[i]);
        QLabel_destroy(QtStatusBar.APanels[i]);
      end;
        
      SetLength(QtStatusBar.APanels, 0);
    end;
  end else
  begin
    if Length(QtStatusBar.APanels) <> AStatusBar.Panels.Count then
    begin
    
      QStatusBar_clearMessage(QStatusBarH(QtStatusBar.Widget));
      
      for i := High(QtStatusBar.APanels) downto 0 do
      begin
        QStatusBar_removeWidget(QStatusBarH(QtStatusBar.Widget), QtStatusBar.APanels[i]);
        QLabel_destroy(QtStatusBar.APanels[i]);
      end;
      
      SetLength(QtStatusBar.APanels, 0);
      SetLength(QtStatusBar.APanels, AStatusBar.Panels.Count);
      
      
      for i := 0 to AStatusBar.Panels.Count - 1 do
      begin
        Str := UTF8Decode(AStatusBar.Panels[i].Text);
        
        QtStatusBar.APanels[i] := QLabel_create(@Str, QtStatusBar.Widget);

        QFrame_setLineWidth(QFrameH(QtStatusBar.APanels[i]), 1);
        QFrame_setMidLineWidth(QFrameH(QtStatusBar.APanels[i]), 0);

        if AStatusBar.Panels[i].Bevel = pbNone then
        QFrame_setFrameStyle(QFrameH(QtStatusBar.APanels[i]), Ord(QFrameNoFrame))
        else
        if AStatusBar.Panels[i].Bevel = pbLowered then
        QFrame_setFrameStyle(QFrameH(QtStatusBar.APanels[i]),Ord(QFramePanel) or Ord(QFrameSunken))
        else
        if AStatusBar.Panels[i].Bevel = pbRaised then
        QFrame_setFrameStyle(QFrameH(QtStatusBar.APanels[i]), Ord(QFramePanel) or Ord(QFrameRaised));

        QWidget_frameGeometry(QtStatusBar.Widget, @R);
        QWidget_setGeometry(QtStatusBar.APanels[i], 0, 0, AStatusBar.Panels[i].Width, R.Bottom);
        
        QStatusBar_addWidget(QStatusBarH(QtStatusBar.Widget),QtStatusBar.APanels[i], 100);
        QWidget_show(QtStatusBar. APanels[i]);
      end;
      
    end
  end;
end;

class procedure TQtWSStatusBar.GetPreferredSize(const AWinControl: TWinControl;
  var PreferredWidth, PreferredHeight: integer; WithThemeSpace: Boolean);
begin

end;

{ TQtWSCustomListView }

{------------------------------------------------------------------------------
  Method: TQtWSCustomListView.CreateHandle
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
class function TQtWSCustomListView.CreateHandle(const AWinControl: TWinControl; const AParams: TCreateParams): HWND;
var
  QtTreeWidget: TQtTreeWidget;
begin
  QtTreeWidget := TQtTreeWidget.Create(AWinControl, AParams);
  QtTreeWidget.AttachEvents;
  Result := THandle(QtTreeWidget);
end;

{------------------------------------------------------------------------------
  Method: TQtWSCustomListView.ColumnDelete
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
class procedure TQtWSCustomListView.ColumnDelete(const ALV: TCustomListView; const AIndex: Integer);
var
  TW: QTreeWidgetH;
  TWI: QTreeWidgetItemH;
begin
  TW := QTreeWidgetH(TQtTreeWidget(ALV.Handle).Widget);
  TWI := QTreeWidget_headerItem(TW);
  QTreeWidgetItem_takeChild(TWI, AIndex);
end;

{------------------------------------------------------------------------------
  Method: TQtWSCustomListView.ColumnInsert
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
class procedure TQtWSCustomListView.ColumnInsert(const ALV: TCustomListView; const AIndex: Integer; const AColumn: TListColumn);
var
  TW: QTreeWidgetH;
  TWI: QTreeWidgetItemH;
  TWIChild: QTreeWidgetItemH;
  HV: QHeaderViewH;
  Str: WideString;
begin

  TW := QTreeWidgetH(TQtTreeWidget(ALV.Handle).Widget);


  if QTreeWidget_columnCount(TW) <> TListView(ALV).Columns.Count then
  QTreeWidget_setColumnCount(TW, TListView(ALV).Columns.Count);
  
  TWI := QTreeWidget_headerItem(TW);

  if QTreeWidgetItem_childCount(TWI) < (AIndex + 1) then
  begin
    TWIChild := QTreeWidgetItem_create(0);
    QTreeWidgetItem_setFlags(TWIChild, QtItemIsEnabled);
    QTreeWidgetItem_addChild(TWI, TWIChild);
    Str := UTF8Encode(ALV.Column[AIndex].Caption);
    QTreeWidgetItem_setText(TWI, AIndex, @Str);
  end;

  HV := QTreeView_header(TW);
  
  if not QHeaderView_isClickable(HV) then
  QHeaderView_setClickable(HV, True);

end;

{------------------------------------------------------------------------------
  Method: TQtWSCustomListView.ColumnGetWidth
  Params:  None
  Returns: Integer
 ------------------------------------------------------------------------------}
class function  TQtWSCustomListView.ColumnGetWidth(const ALV: TCustomListView; const AIndex: Integer; const AColumn: TListColumn): Integer;
var
  TW: QTreeWidgetH;
begin
  TW := QTreeWidgetH(TQtTreeWidget(ALV.Handle).Widget);
  Result := QTreeView_columnWidth(QTreeViewH(TW), AIndex);
end;

{------------------------------------------------------------------------------
  Method: TQtWSCustomListView.ColumnMove
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
class procedure TQtWSCustomListView.ColumnMove(const ALV: TCustomListView; const AOldIndex, ANewIndex: Integer; const AColumn: TListColumn);
var
  TW: QTreeWidgetH;
  HV: QHeaderViewH;
begin
  TW := QTreeWidgetH(TQtTreeWidget(ALV.Handle).Widget);
  HV := QTreeView_header(TW);
  QHeaderView_moveSection(HV, AOldIndex, ANewIndex);
end;

{------------------------------------------------------------------------------
  Method: TQtWSCustomListView.ColumnSetAlignment
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
class procedure TQtWSCustomListView.ColumnSetAlignment(const ALV: TCustomListView; const AIndex: Integer; const AColumn: TListColumn; const AAlignment: TAlignment);
var
  TW: QTreeWidgetH;
  TWI: QTreeWidgetItemH;
  FAlign: QtAlignment;
begin

  TW := QTreeWidgetH(TQtTreeWidget(ALV.Handle).Widget);
  TWI := QTreeWidget_headerItem(TW);
  
  case AAlignment of
    taLeftJustify: FAlign := QtAlignLeft;
    taRightJustify: FAlign := QtAlignRight;
    taCenter: FAlign := QtAlignCenter;
    else
      FAlign := QtAlignLeft;
  end;
  
  QTreeWidgetItem_setTextAlignment(TWI, AIndex, FAlign);
  
end;

{------------------------------------------------------------------------------
  Method: TQtWSCustomListView.ColumnSetAutoSize
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
class procedure TQtWSCustomListView.ColumnSetAutoSize(const ALV: TCustomListView; const AIndex: Integer; const AColumn: TListColumn; const AAutoSize: Boolean);
var
  TW: QTreeWidgetH;
  HV: QHeaderViewH;
begin
  TW := QTreeWidgetH(TQtTreeWidget(ALV.Handle).Widget);
  HV := QTreeView_header(TW);
  if AAutoSize then
  QHeaderView_setResizeMode(HV, AIndex, QHeaderViewResizeToContents)
  else
  QHeaderView_setResizeMode(HV, AIndex, QHeaderViewInteractive);
  
end;

{------------------------------------------------------------------------------
  Method: TQtWSCustomListView.ColumnSetCaption
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
class procedure TQtWSCustomListView.ColumnSetCaption(const ALV: TCustomListView; const AIndex: Integer; const AColumn: TListColumn; const ACaption: String);
var
  Str: WideString;
  TW: QTreeWidgetH;
  TWI: QTreeWidgetItemH;
begin
  TW := QTreeWidgetH(TQtTreeWidget(ALV.Handle).Widget);
  TWI := QTreeWidget_headerItem(TW);
  if TWI <> NiL then
  begin
    Str := UTF8Encode(ACaption);
    QTreeWidgetItem_setText(TWI, AIndex, @Str);
  end;
end;

{------------------------------------------------------------------------------
  Method: TQtWSCustomListView.ColumnSetImage
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
class procedure TQtWSCustomListView.ColumnSetImage(const ALV: TCustomListView; const AIndex: Integer; const AColumn: TListColumn; const AImageIndex: Integer);
var
  TW: QTreeWidgetH;
  TWI: QTreeWidgetItemH;
begin
  TW := QTreeWidgetH(TQtTreeWidget(ALV.Handle).Widget);
  TWI := QTreeWidget_headerItem(TW);
  if Assigned(TListView(ALV).SmallImages) then
  begin
  {what to implement here ?!? SmallImages, LargeImages, StateImages ?!?}
  // QTreeWidgetItem_setIcon(TWI, AIndex, QIconH ?!? -> wait for TImageList implementation ?!? );
  end;
end;

{------------------------------------------------------------------------------
  Method: TQtWSCustomListView.ColumnSetMinWidth
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
class procedure TQtWSCustomListView.ColumnSetMinWidth(const ALV: TCustomListView; const AIndex: Integer; const AColumn: TListColumn; const AMinWidth: integer);
var
  TW: QTreeWidgetH;
  HV: QHeaderViewH;
begin
  TW := QTreeWidgetH(TQtTreeWidget(ALV.Handle).Widget);
  HV := QTreeView_header(TW);
  QHeaderView_setMinimumSectionSize(HV, AMinWidth);
end;

{------------------------------------------------------------------------------
  Method: TQtWSCustomListView.ColumnSetWidth
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
class procedure TQtWSCustomListView.ColumnSetWidth(const ALV: TCustomListView; const AIndex: Integer; const AColumn: TListColumn; const AWidth: Integer);
var
  TW: QTreeWidgetH;
begin
  TW := QTreeWidgetH(TQtTreeWidget(ALV.Handle).Widget);
  QTreeView_setColumnWidth(QTreeViewH(TW), AIndex, AWidth);
end;

{------------------------------------------------------------------------------
  Method: TQtWSCustomListView.ColumnSetVisible
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
class procedure TQtWSCustomListView.ColumnSetVisible(const ALV: TCustomListView; const AIndex: Integer; const AColumn: TListColumn; const AVisible: Boolean);
var
  TW: QTreeWidgetH;
begin
  TW := QTreeWidgetH(TQtTreeWidget(ALV.Handle).Widget);
  QTreeView_setColumnHidden(QTreeViewH(TW), AIndex, not AVisible);
end;

{------------------------------------------------------------------------------
  Method: TQtWSCustomListView.ItemDelete
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
class procedure TQtWSCustomListView.ItemDelete(const ALV: TCustomListView; const AIndex: Integer);
var
  TW: QTreeWidgetH;
  TWI: QTreeWidgetItemH;
begin
  TW := QTreeWidgetH(TQtTreeWidget(ALV.Handle).Widget);
  TWI := QTreeWidget_takeTopLevelItem(TW, AIndex);
  {$note implement}
end;

{------------------------------------------------------------------------------
  Method: TQtWSCustomListView.ItemGetChecked
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
class function  TQtWSCustomListView.ItemGetChecked(const ALV: TCustomListView; const AIndex: Integer; const AItem: TListItem): Boolean;
var
  TW: QTreeWidgetH;
  TWI: QTreeWidgetItemH;
  AState: QtCheckState;
begin
  TW := QTreeWidgetH(TQtTreeWidget(ALV.Handle).Widget);
  TWI := QTreeWidget_topLevelItem(TW, AIndex);
  AState := QTreeWidgetItem_checkState(TWI, 0);
  if AState = QtChecked then
  Result := True
  else
  Result := False;
end;

{------------------------------------------------------------------------------
  Method: TQtWSCustomListView.ItemGetPosition
  Params:  None
  Returns: TPoint
 ------------------------------------------------------------------------------}
class function  TQtWSCustomListView.ItemGetPosition(const ALV: TCustomListView; const AIndex: Integer): TPoint;
var
  TW: QTreeWidgetH;
  TWI: QTreeWidgetItemH;
  R: TRect;
begin
  TW := QTreeWidgetH(TQtTreeWidget(ALV.Handle).Widget);
  TWI := QTreeWidget_topLevelItem(TW, AIndex);
  QTreeWidget_visualItemRect(TW, @R, TWI);

  Result.X := R.Left;
  Result.Y := R.Top;
  
end;

{------------------------------------------------------------------------------
  Method: TQtWSCustomListView.ItemGetState
  Params:  None
  Returns: TPoint
 ------------------------------------------------------------------------------}
class function  TQtWSCustomListView.ItemGetState(const ALV: TCustomListView; const AIndex: Integer; const AItem: TListItem; const AState: TListItemState; out AIsSet: Boolean): Boolean;
var
  TW: QTreeWidgetH;
  TWI: QTreeWidgetItemH;
begin

  TW := QTreeWidgetH(TQtTreeWidget(ALV.Handle).Widget);

  TWI := QTreeWidget_topLevelItem(TW, AIndex);

  case AState of
    lisFocused: AIsSet := TWI = QTreeWidget_currentItem(TW);
    lisSelected: AIsSet := QTreeWidgetItem_isSelected(TWI);
    else
    AIsSet := False;
  end;
  
  Result := True;
  
end;
    
{------------------------------------------------------------------------------
  Method: TQtWSCustomListView.ItemSetChecked
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
class procedure TQtWSCustomListView.ItemSetChecked(const ALV: TCustomListView; const AIndex: Integer; const AItem: TListItem; const AChecked: Boolean);
var
  TW: QTreeWidgetH;
  TWI: QTreeWidgetItemH;
begin
  TW := QTreeWidgetH(TQtTreeWidget(ALV.Handle).Widget);
  TWI := QTreeWidget_topLevelItem(TW, AIndex);
  if AChecked then
    QTreeWidgetItem_setCheckState(TWI, 0, QtChecked)
  else
    QTreeWidgetItem_setCheckState(TWI, 0, QtUnChecked);
end;

{------------------------------------------------------------------------------
  Method: TQtWSCustomListView.ItemSetState
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
class procedure TQtWSCustomListView.ItemSetState(const ALV: TCustomListView; const AIndex: Integer; const AItem: TListItem; const AState: TListItemState; const AIsSet: Boolean);
var
  TW: QTreeWidgetH;
  TWI: QTreeWidgetItemH;
begin
  TW := QTreeWidgetH(TQtTreeWidget(ALV.Handle).Widget);

  TWI := QTreeWidget_topLevelItem(TW, AIndex);

  case AState of
    lisFocused: QTreeWidget_setCurrentItem(TW, TWI);
    lisSelected: QTreeWidgetItem_setSelected(TWI, AIsSet);
  end;
  
end;

{------------------------------------------------------------------------------
  Method: TQtWSCustomListView.ItemInsert
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
class procedure TQtWSCustomListView.ItemInsert(const ALV: TCustomListView; const AIndex: Integer; const AItem: TListItem);
var
  TW: QTreeWidgetH;
  TWI: QTreeWidgetItemH;
  Str: WideString;
  i: Integer;
begin
  TW := QTreeWidgetH(TQtTreeWidget(ALV.Handle).Widget);

  TWI := QTreeWidgetItem_create(TW, 0);
  Str := UTF8Decode(AItem.Caption);
  
  if ALV.CheckBoxes then
  begin
    if AItem.Checked then
    QTreeWidgetItem_setCheckState(TWI, 0, QtChecked)
    else
    QTreeWidgetItem_setCheckState(TWI, 0, QtUnchecked);
  end;
  
  QTreeWidgetItem_setText(TWI, 0, @Str);
  for i := 0 to AItem.SubItems.Count - 1 do
  begin
    Str := UTF8Decode(AItem.Subitems.Strings[i]);
    QTreeWidgetItem_setText(TWI, i+1, @Str);
  end;
  
  QTreeWidget_insertTopLevelItem(TW, AIndex, TWI);
end;


{------------------------------------------------------------------------------
  Method: TQtWSCustomListView.ItemSetText
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
class procedure TQtWSCustomListView.ItemSetText(const ALV: TCustomListView; const AIndex: Integer; const AItem: TListItem; const ASubIndex: Integer; const AText: String);
var
  TW: QTreeWidgetH;
  TWI: QTreeWidgetItemH;
  Str: WideString;
begin
  TW := QTreeWidgetH(TQtTreeWidget(ALV.Handle).Widget);

  Str := UTF8Decode(AText);
  TWI := QTreeWidget_topLevelItem(TW, AIndex);
  if TWI <> NiL then
    QTreeWidgetItem_setText(TWI, ASubIndex, @Str);
end;

{------------------------------------------------------------------------------
  Method: TQtWSCustomListView.ItemShow
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
class procedure TQtWSCustomListView.ItemShow(const ALV: TCustomListView; const AIndex: Integer; const AItem: TListItem; const PartialOK: Boolean);
var
  TW: QTreeWidgetH;
  TWI: QTreeWidgetItemH;
begin
  TW := QTreeWidgetH(TQtTreeWidget(ALV.Handle).Widget);
  TWI := QTreeWidget_topLevelItem(TW, AIndex);
  QTreeWidget_setItemHidden(TW, TWI, False);
end;


{------------------------------------------------------------------------------
  Method: TQtWSCustomListView.ItemDisplayRect
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
class function  TQtWSCustomListView.ItemDisplayRect(const ALV: TCustomListView; const AIndex, ASubItem: Integer; ACode: TDisplayCode): TRect;
var
  TW: QTreeWidgetH;
  TWI: QTreeWidgetItemH;
begin
  TW := QTreeWidgetH(TQtTreeWidget(ALV.Handle).Widget);
  TWI := QTreeWidget_topLevelItem(TW, AIndex);
  if QTreeWidgetItem_childCount(TWI) > 0 then
  QTreeWidget_visualItemRect(TW, @Result, QTreeWidgetItem_child(TWI, ASubItem))
  else
  QTreeWidget_visualItemRect(TW, @Result, TWI);
end;

{------------------------------------------------------------------------------
  Method: TQtWSCustomListView.GetFocused
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
class function TQtWSCustomListView.GetFocused(const ALV: TCustomListView): Integer;
var
  TW: QTreeWidgetH;
  TWI: QTreeWidgetItemH;
  i: Integer;
begin
  TW := QTreeWidgetH(TQtTreeWidget(ALV.Handle).Widget);
  TWI := QTreeWidget_currentItem(TW);
  i := QTreeWidget_indexOfTopLevelItem(TW, TWI);
  if QTreeWidgetItem_isSelected(TWI) then
  Result := i
  else
  Result := -1;
end;

{------------------------------------------------------------------------------
  Method: TQtWSCustomListView.GetItemAt
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
class function TQtWSCustomListView.GetItemAt(const ALV: TCustomListView; x,y: integer): Integer;
var
  TW: QTreeWidgetH;
  TWI: QTreeWidgetItemH;
begin
  TW := QTreeWidgetH(TQtTreeWidget(ALV.Handle).Widget);
  TWI := QTreeWidget_itemAt(TW, x, y);
  Result := QTreeWidget_indexOfTopLevelItem(TW, TWI);
end;

{------------------------------------------------------------------------------
  Method: TQtWSCustomListView.GetSelCount
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
class function TQtWSCustomListView.GetSelCount(const ALV: TCustomListView): Integer;
var
  TW: QTreeWidgetH;
  FPInts: TIntArray;
begin
  TW := QTreeWidgetH(TQtTreeWidget(ALV.Handle).Widget);
  QTreeWidget_selectedItems(TW, @FPInts);
  Result := length(FPInts);
end;

{------------------------------------------------------------------------------
  Method: TQtWSCustomListView.GetSelection
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
class function TQtWSCustomListView.GetSelection(const ALV: TCustomListView): Integer;
var
  TW: QTreeWidgetH;
  FPInts: TIntArray;
begin
{implement selection event so we can return Alv.Selected.Index}
  TW := QTreeWidgetH(TQtTreeWidget(ALV.Handle).Widget);
  QTreeWidget_selectedItems(TW, @FPInts);
  if Length(FPInts)>0 then
  Result := FPInts[0]
  else
  Result := -1;
end;
    
{------------------------------------------------------------------------------
  Method: TQtWSCustomListView.SetSort
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
class procedure TQtWSCustomListView.SetSort(const ALV: TCustomListView; const AType: TSortType; const AColumn: Integer);
var
  TW: QTreeWidgetH;
begin
  TW := QTreeWidgetH(TQtTreeWidget(ALV.Handle).Widget);
  if AType <> stNone then
  begin
    {$note implement}
//    QTreeWidget_setSortingEnabled(TW, True);
//    QTreeView_sortByColumn(QTreeViewH(TW), AColumn);
  end;
end;

{------------------------------------------------------------------------------
  Method: TQtWSCustomListView.GetBoundingRect
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
class function TQtWSCustomListView.GetBoundingRect(const ALV: TCustomListView): TRect;
begin
  QWidget_frameGeometry(TQtWidget(ALV.Handle).Widget, @Result);
end;

initialization

////////////////////////////////////////////////////
// I M P O R T A N T
////////////////////////////////////////////////////
// To improve speed, register only classes
// which actually implement something
////////////////////////////////////////////////////
  RegisterWSComponent(TStatusBar, TQtWSStatusBar);
//  RegisterWSComponent(TCustomTabSheet, TQtWSTabSheet);
//  RegisterWSComponent(TCustomPageControl, TQtWSPageControl);
  RegisterWSComponent(TCustomListView, TQtWSCustomListView);
//  RegisterWSComponent(TCustomListView, TQtWSListView);
  RegisterWSComponent(TCustomProgressBar, TQtWSProgressBar);
//  RegisterWSComponent(TCustomUpDown, TQtWSCustomUpDown);
//  RegisterWSComponent(TCustomUpDown, TQtWSUpDown);
  RegisterWSComponent(TToolButton, TQtWSToolButton);
  RegisterWSComponent(TToolBar, TQtWSToolBar);
//  RegisterWSComponent(TCustomToolButton, TQtWSToolButton);
//  RegisterWSComponent(TCustomToolBar, TQtWSToolBar);
  RegisterWSComponent(TCustomTrackBar, TQtWSTrackBar);
//  RegisterWSComponent(TCustomTreeView, TQtWSCustomTreeView);
//  RegisterWSComponent(TCustomTreeView, TQtWSTreeView);
////////////////////////////////////////////////////
end.
