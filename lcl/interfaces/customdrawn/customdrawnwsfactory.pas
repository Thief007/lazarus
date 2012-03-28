unit CustomDrawnWSFactory;

{$mode objfpc}{$H+}

interface

uses
  Classes, Controls, ComCtrls, ImgList, Calendar, StdCtrls, Arrow, Spin,
  Dialogs, ExtCtrls, Buttons, Forms, Menus,
  WSLCLClasses;

// imglist
function RegisterCustomImageList: Boolean;
// controls
function RegisterDragImageList: Boolean;
function RegisterLazAccessibleObject: Boolean;
function RegisterControl: Boolean;
function RegisterWinControl: Boolean;
function RegisterGraphicControl: Boolean;
function RegisterCustomControl: Boolean;
// comctrls
function RegisterStatusBar: Boolean;
function RegisterTabSheet: Boolean;
function RegisterPageControl: Boolean;
function RegisterCustomListView: Boolean;
function RegisterCustomProgressBar: Boolean;
function RegisterCustomUpDown: Boolean;
function RegisterCustomToolButton: Boolean;
function RegisterToolBar: Boolean;
function RegisterCustomTrackBar: Boolean;
function RegisterCustomTreeView: Boolean;
// calendar
function RegisterCustomCalendar: Boolean;
// dialogs
function RegisterCommonDialog: Boolean;
function RegisterFileDialog: Boolean;
function RegisterOpenDialog: Boolean;
function RegisterSaveDialog: Boolean;
function RegisterSelectDirectoryDialog: Boolean;
function RegisterColorDialog: Boolean;
function RegisterColorButton: Boolean;
function RegisterFontDialog: Boolean;
// StdCtrls
function RegisterCustomScrollBar: Boolean;
function RegisterCustomGroupBox: Boolean;
function RegisterCustomComboBox: Boolean;
function RegisterCustomListBox: Boolean;
function RegisterCustomEdit: Boolean;
function RegisterCustomMemo: Boolean;
function RegisterButtonControl: Boolean;
function RegisterCustomButton: Boolean;
function RegisterCustomCheckBox: Boolean;
function RegisterToggleBox: Boolean;
function RegisterRadioButton: Boolean;
function RegisterCustomStaticText: Boolean;
function RegisterCustomLabel: Boolean;
// extctrls
function RegisterCustomPage: Boolean;
function RegisterCustomNotebook: Boolean;
function RegisterShape: Boolean;
function RegisterCustomSplitter: Boolean;
function RegisterPaintBox: Boolean;
function RegisterCustomImage: Boolean;
function RegisterBevel: Boolean;
function RegisterCustomRadioGroup: Boolean;
function RegisterCustomCheckGroup: Boolean;
function RegisterCustomLabeledEdit: Boolean;
function RegisterCustomPanel: Boolean;
function RegisterCustomTrayIcon: Boolean;
//ExtDlgs
function RegisterPreviewFileControl: Boolean;
function RegisterPreviewFileDialog: Boolean;
function RegisterOpenPictureDialog: Boolean;
function RegisterSavePictureDialog: Boolean;
function RegisterCalculatorDialog: Boolean;
function RegisterCalculatorForm: Boolean;
function RegisterCalendarDialog: Boolean;
// Buttons
function RegisterCustomBitBtn: Boolean;
function RegisterCustomSpeedButton: Boolean;
// Arrow
function RegisterArrow: Boolean;
// CheckLst
function RegisterCustomCheckListBox: Boolean;
// Forms
function RegisterScrollingWinControl: Boolean;
function RegisterScrollBox: Boolean;
function RegisterCustomFrame: Boolean;
function RegisterCustomForm: Boolean;
function RegisterHintWindow: Boolean;
function RegisterCustomGrid: Boolean;
function RegisterMenuItem: Boolean;
function RegisterMenu: Boolean;
function RegisterMainMenu: Boolean;
function RegisterPopupMenu: Boolean;
function RegisterPairSplitterSide: Boolean;
function RegisterCustomPairSplitter: Boolean;
function RegisterCustomFloatSpinEdit: Boolean;
function RegisterCustomRubberBand: Boolean;
// LazDeviceAPIs
function RegisterLazDeviceAPIs: Boolean;

implementation
uses
 CustomDrawnWSArrow,
 CustomDrawnWSButtons,
{ WinCEWSCalendar,
 WinCEWSCheckLst,}
 CustomDrawnWSComCtrls,
 CustomDrawnWSControls,
{ WinCEWSDialogs,}
 CustomDrawnWSExtCtrls,
 CustomDrawnWSForms,
// WinCEWSImgList,
 CustomDrawnWSMenus,
 CustomDrawnWSSpin,
 CustomDrawnWSStdCtrls,
 CustomDrawnWSLazDeviceAPIs{,
 WinCEWSGrids};

// imglist
function RegisterCustomImageList: Boolean; alias : 'WSRegisterCustomImageList';
begin
//  RegisterWSComponent(TCustomImageList, TWinCEWSCustomImageList);
  Result := False;
end;

// controls
function RegisterDragImageList: Boolean; alias : 'WSRegisterDragImageList';
begin
//  RegisterWSComponent(TDragImageList, TWinCEWSDragImageList);
  Result := False;
end;

function RegisterLazAccessibleObject: Boolean; alias : 'WSRegisterLazAccessibleObject';
begin
  RegisterWSLazAccessibleObject(TCDWSLazAccessibleObject);
  Result := True;
end;

function RegisterControl: Boolean; alias : 'WSRegisterControl';
begin
  Result := False;
end;

function RegisterWinControl: Boolean; alias : 'WSRegisterWinControl';
begin
  RegisterWSComponent(TWinControl, TCDWSWinControl);
  Result := True;
end;

function RegisterGraphicControl: Boolean; alias : 'WSRegisterGraphicControl';
begin
  Result := False;
end;

function RegisterCustomControl: Boolean; alias : 'WSRegisterCustomControl';
begin
  Result := False;
end;

// comctrls
function RegisterStatusBar: Boolean; alias : 'WSRegisterStatusBar';
begin
//  RegisterWSComponent(TStatusBar, TWinCEWSStatusBar);
  Result := False;
end;

function RegisterTabSheet: Boolean; alias : 'WSRegisterTabSheet';
begin
  Result := False;
end;

function RegisterPageControl: Boolean; alias : 'WSRegisterPageControl';
begin
  RegisterWSComponent(TCustomTabControl, TCDWSCustomTabControl);
  Result := True;
end;

function RegisterCustomListView: Boolean; alias : 'WSRegisterCustomListView';
begin
//  RegisterWSComponent(TCustomListView, TWinCEWSCustomListView);
  Result := False;
end;

function RegisterCustomProgressBar: Boolean; alias : 'WSRegisterCustomProgressBar';
begin
  RegisterWSComponent(TCustomProgressBar, TCDWSProgressBar);
  Result := True;
end;

function RegisterCustomUpDown: Boolean; alias : 'WSRegisterCustomUpDown';
begin
  Result := False;
end;

function RegisterCustomToolButton: Boolean; alias : 'WSRegisterCustomToolButton';
begin
  Result := False;
end;

function RegisterToolBar: Boolean; alias : 'WSRegisterToolBar';
begin
  Result := False;
end;

function RegisterCustomTrackBar: Boolean; alias : 'WSRegisterCustomTrackBar';
begin
  RegisterWSComponent(TCustomTrackBar, TCDWSTrackBar);
  Result := True;
end;

function RegisterCustomTreeView: Boolean; alias : 'WSRegisterCustomTreeView';
begin
  Result := False;
end;

// calendar
function RegisterCustomCalendar: Boolean; alias : 'WSRegisterCustomCalendar';
begin
//  RegisterWSComponent(TCustomCalendar, TWinCEWSCustomCalendar);
  Result := False;
end;

// dialogs
function RegisterCommonDialog: Boolean; alias : 'WSRegisterCommonDialog';
begin
  Result := False;
end;

function RegisterFileDialog: Boolean; alias : 'WSRegisterFileDialog';
begin
//  RegisterWSComponent(TFileDialog, TWinCEWSFileDialog);
  Result := False;
end;

function RegisterOpenDialog: Boolean; alias : 'WSRegisterOpenDialog';
begin
  Result := False;
end;

function RegisterSaveDialog: Boolean; alias : 'WSRegisterSaveDialog';
begin
  Result := False;
end;

function RegisterSelectDirectoryDialog: Boolean; alias : 'WSRegisterSelectDirectoryDialog';
begin
  Result := False;
end;

function RegisterColorDialog: Boolean; alias : 'WSRegisterColorDialog';
begin
  Result := False;
end;

function RegisterColorButton: Boolean; alias : 'WSRegisterColorButton';
begin
  Result := False;
end;

function RegisterFontDialog: Boolean; alias : 'WSRegisterFontDialog';
begin
  Result := False;
end;

// StdCtrls
function RegisterCustomScrollBar: Boolean; alias : 'WSRegisterCustomScrollBar';
begin
  RegisterWSComponent(TCustomScrollBar, TCDWSScrollBar);
  Result := True;
end;

function RegisterCustomGroupBox: Boolean; alias : 'WSRegisterCustomGroupBox';
begin
  RegisterWSComponent(TCustomGroupBox, TCDWSCustomGroupBox);
  Result := True;
end;

function RegisterCustomComboBox: Boolean; alias : 'WSRegisterCustomComboBox';
begin
  RegisterWSComponent(TCustomComboBox, TCDWSCustomComboBox);
  Result := True;
end;

function RegisterCustomListBox: Boolean; alias : 'WSRegisterCustomListBox';
begin
//  RegisterWSComponent(TCustomListBox, TWinCEWSCustomListBox);
  Result := False;
end;

function RegisterCustomEdit: Boolean; alias : 'WSRegisterCustomEdit';
begin
  RegisterWSComponent(TCustomEdit, TCDWSCustomEdit);
  Result := True;
end;

function RegisterCustomMemo: Boolean; alias : 'WSRegisterCustomMemo';
begin
//  RegisterWSComponent(TCustomMemo, TWinCEWSCustomMemo);
  Result := False;
end;

function RegisterButtonControl: Boolean; alias : 'WSRegisterButtonControl';
begin
  Result := False;
end;

function RegisterCustomButton: Boolean; alias : 'WSRegisterCustomButton';
begin
  RegisterWSComponent(TCustomButton, TCDWSButton);
  Result := True;
end;

function RegisterCustomCheckBox: Boolean; alias : 'WSRegisterCustomCheckBox';
begin
  RegisterWSComponent(TCustomCheckBox, TCDWSCustomCheckBox);
  Result := True;
end;

function RegisterToggleBox: Boolean; alias : 'WSRegisterToggleBox';
begin
//  RegisterWSComponent(TToggleBox, TWinCEWSToggleBox);
  Result := False;
end;

function RegisterRadioButton: Boolean; alias : 'WSRegisterRadioButton';
begin
  RegisterWSComponent(TRadioButton, TCDWSRadioButton);
  Result := True;
end;

function RegisterCustomStaticText: Boolean; alias : 'WSRegisterCustomStaticText';
begin
  RegisterWSComponent(TCustomStaticText, TCDWSCustomStaticText);
  Result := True;
end;

function RegisterCustomLabel: Boolean; alias : 'WSRegisterCustomLabel';
begin
  Result := False;
end;

// extctrls
function RegisterCustomPage: Boolean; alias : 'WSRegisterCustomPage';
begin
//  RegisterWSComponent(TCustomPage, TWinCEWSCustomPage);
  Result := False;
end;

function RegisterCustomNotebook: Boolean; alias : 'WSRegisterCustomNotebook';
begin
//  RegisterWSComponent(TCustomTabControl, TWinCEWSCustomNotebook);
  Result := False;
end;

function RegisterShape: Boolean; alias : 'WSRegisterShape';
begin
  Result := False;
end;

function RegisterCustomSplitter: Boolean; alias : 'WSRegisterCustomSplitter';
begin
  Result := False;
end;

function RegisterPaintBox: Boolean; alias : 'WSRegisterPaintBox';
begin
  Result := False;
end;

function RegisterCustomImage: Boolean; alias : 'WSRegisterCustomImage';
begin
  Result := False;
end;

function RegisterBevel: Boolean; alias : 'WSRegisterBevel';
begin
  Result := False;
end;

function RegisterCustomRadioGroup: Boolean; alias : 'WSRegisterCustomRadioGroup';
begin
  Result := False;
end;

function RegisterCustomCheckGroup: Boolean; alias : 'WSRegisterCustomCheckGroup';
begin
  Result := False;
end;

function RegisterCustomLabeledEdit: Boolean; alias : 'WSRegisterCustomLabeledEdit';
begin
  Result := False;
end;

function RegisterCustomPanel: Boolean; alias : 'WSRegisterCustomPanel';
begin
  RegisterWSComponent(TCustomPanel, TCDWSCustomPanel);
  Result := True;
end;

function RegisterCustomTrayIcon: Boolean; alias : 'WSRegisterCustomTrayIcon';
begin
  RegisterWSComponent(TCustomTrayIcon, TCDWSCustomTrayIcon);
  Result := True;
end;

//ExtDlgs
function RegisterPreviewFileControl: Boolean; alias : 'WSRegisterPreviewFileControl';
begin
  Result := False;
end;

function RegisterPreviewFileDialog: Boolean; alias : 'WSRegisterPreviewFileDialog';
begin
  Result := False;
end;

function RegisterOpenPictureDialog: Boolean; alias : 'WSRegisterOpenPictureDialog';
begin
  Result := False;
end;

function RegisterSavePictureDialog: Boolean; alias : 'WSRegisterSavePictureDialog';
begin
  Result := False;
end;

function RegisterCalculatorDialog: Boolean; alias : 'WSRegisterCalculatorDialog';
begin
  Result := False;
end;

function RegisterCalculatorForm: Boolean; alias : 'WSRegisterCalculatorForm';
begin
  Result := False;
end;

(*function RegisterCalendarDialogForm: Boolean; alias : 'WSRegisterCalendarDialogForm';
begin
//  RegisterWSComponent(TCalendarDialogForm, TWinCEWSCalendarDialogForm);
  Result := False;
end;*)

function RegisterCalendarDialog: Boolean; alias : 'WSRegisterCalendarDialog';
begin
  Result := False;
end;

// Buttons
function RegisterCustomBitBtn: Boolean; alias : 'WSRegisterCustomBitBtn';
begin
  RegisterWSComponent(TCustomBitBtn, TCDWSBitBtn);
  Result := True;
end;

function RegisterCustomSpeedButton: Boolean; alias : 'WSRegisterCustomSpeedButton';
begin
  Result := False;
end;

// Arrow
function RegisterArrow: Boolean; alias : 'WSRegisterArrow';
begin
  RegisterWSComponent(TArrow, TCDWSArrow);
  Result := True;
end;

// CheckLst
function RegisterCustomCheckListBox: Boolean; alias : 'WSRegisterCustomCheckListBox';
begin
//  RegisterWSComponent(TCustomCheckListBox, TWinCEWSCustomCheckListBox);
  Result := False;
end;

// Forms
function RegisterScrollingWinControl: Boolean; alias : 'WSRegisterScrollingWinControl';
begin
//  RegisterWSComponent(TScrollingWinControl, TWinCEWSScrollingWinControl);
  Result := False;
end;

function RegisterScrollBox: Boolean; alias : 'WSRegisterScrollBox';
begin
//  RegisterWSComponent(TScrollBox, TWinCEWSScrollBox);
  Result := False;
end;

function RegisterCustomFrame: Boolean; alias : 'WSRegisterCustomFrame';
begin
  Result := False;
end;

function RegisterCustomForm: Boolean; alias : 'WSRegisterCustomForm';
begin
  RegisterWSComponent(TCustomForm, TCDWSCustomForm);
  Result := True;
end;

function RegisterHintWindow: Boolean; alias : 'WSRegisterHintWindow';
begin
  Result := False;
end;

// Grids
function RegisterCustomGrid: Boolean; alias : 'WSRegisterCustomGrid';
begin
//  RegisterWSComponent(TCustomGrid, TWinCEWSCustomGrid);
  Result := False;
end;

// Menus
function RegisterMenuItem: Boolean; alias : 'WSRegisterMenuItem';
begin
  RegisterWSComponent(TMenuItem, TCDWSMenuItem);
  Result := True;
end;

function RegisterMenu: Boolean; alias : 'WSRegisterMenu';
begin
  RegisterWSComponent(TMenu, TCDWSMenu);
  Result := True;
end;

function RegisterMainMenu: Boolean; alias : 'WSRegisterMainMenu';
begin
  Result := False;
end;

function RegisterPopupMenu: Boolean; alias : 'WSRegisterPopupMenu';
begin
//  RegisterWSComponent(TPopupMenu, TCDWSPopupMenu);
  Result := False;
end;

function RegisterPairSplitterSide: Boolean; alias : 'WSRegisterPairSplitterSide';
begin
  Result := False;
end;

function RegisterCustomPairSplitter: Boolean; alias : 'WSRegisterCustomPairSplitter';
begin
  Result := False;
end;

function RegisterCustomFloatSpinEdit: Boolean; alias : 'WSRegisterCustomFloatSpinEdit';
begin
  RegisterWSComponent(TCustomFloatSpinEdit, TCDWSCustomFloatSpinEdit);
  Result := True;
end;

function RegisterCustomRubberBand: Boolean; alias : 'WSRegisterCustomRubberBand';
begin
  Result := False;
end;

function RegisterLazDeviceAPIs: Boolean; alias : 'WSRegisterLazDeviceAPIs';
begin
  RegisterWSLazDeviceAPIs(TCDWSLazDeviceAPIs);
  Result := True;
end;

end.
