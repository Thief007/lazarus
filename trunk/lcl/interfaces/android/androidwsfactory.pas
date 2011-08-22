unit androidwsfactory;

{$mode objfpc}{$H+}

interface
uses
  Classes, Controls, ComCtrls, ImgList, Calendar, StdCtrls, Arrow, Spin,
  Dialogs, ExtCtrls, ExtDlgs, Buttons, CheckLst, Forms, Grids, Menus,
  PairSplitter, WSLCLClasses;


// imglist
function RegisterCustomImageList: Boolean;
// controls
function RegisterDragImageList: Boolean;
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

implementation

uses
{  Gtk2WSArrow,
  Gtk2WSButtons,
  Gtk2WSCalendar,
  Gtk2WSCheckLst,
  Gtk2WSComCtrls,}
  AndroidWSControls,
{  Gtk2WSDialogs,
  Gtk2WSExtCtrls,
  Gtk2WSExtDlgs,}
  AndroidWSForms,
{  Gtk2WSGrids,
  Gtk2WSImgList,
  Gtk2WSMenus,
  Gtk2WSSpin,}
  AndroidWSStdCtrls;
{  Gtk2WSPairSplitter,
  Gtk2WSPrivate;   }

// imglist
function RegisterCustomImageList: Boolean; alias : 'WSRegisterCustomImageList';
begin
//  RegisterWSComponent(TImageList, TGtk2WSImageList);
//  RegisterWSComponent(TCustomImageList, TGtk2WSCustomImageList);
  Result := False;
end;

// controls
function RegisterDragImageList: Boolean; alias : 'WSRegisterDragImageList';
begin
  Result := False;
//  RegisterWSComponent(TDragImageList, TGtk2WSDragImageList); { GTK2 }
//  Result := True;
end;

function RegisterControl: Boolean; alias : 'WSRegisterControl';
begin
//  RegisterWSComponent(TControl, TGtk2WSControl);
  Result := False;
end;

function RegisterWinControl: Boolean; alias : 'WSRegisterWinControl';
begin
  RegisterWSComponent(TWinControl, TAndroidWSWinControl);
  Result := True;
end;

function RegisterGraphicControl: Boolean; alias : 'WSRegisterGraphicControl';
begin
//  RegisterWSComponent(TGraphicControl, TGtk2WSGraphicControl);
  Result := False;
end;

function RegisterCustomControl: Boolean; alias : 'WSRegisterCustomControl';
begin
//  RegisterWSComponent(TCustomControl, TGtk2WSCustomControl);
  Result := False;
end;

// comctrls
function RegisterStatusBar: Boolean; alias : 'WSRegisterStatusBar';
begin
  Result := False;
//  RegisterWSComponent(TStatusBar, TGtk2WSStatusBar);
//  Result := True;
end;

function RegisterTabSheet: Boolean; alias : 'WSRegisterTabSheet';
begin
//  RegisterWSComponent(TCustomTabSheet, TGtk2WSTabSheet);
  Result := False;
end;

function RegisterPageControl: Boolean; alias : 'WSRegisterPageControl';
begin
//  RegisterWSComponent(TCustomPageControl, TGtk2WSPageControl);
  Result := False;
end;

function RegisterCustomListView: Boolean; alias : 'WSRegisterCustomListView';
begin
  Result := False;
//  RegisterWSComponent(TCustomListView, TGtk2WSCustomListView);
//  RegisterWSComponent(TCustomListView, TGtk2WSListView);
//  Result := True;
end;

function RegisterCustomProgressBar: Boolean; alias : 'WSRegisterCustomProgressBar';
begin
  Result := False;
//  RegisterWSComponent(TCustomProgressBar, TGtk2WSProgressBar);
//  Result := True;
end;

function RegisterCustomUpDown: Boolean; alias : 'WSRegisterCustomUpDown';
begin
//  RegisterWSComponent(TCustomUpDown, TGtk2WSCustomUpDown);
//  RegisterWSComponent(TCustomUpDown, TGtk2WSUpDown);
  Result := False;
end;

function RegisterCustomToolButton: Boolean; alias : 'WSRegisterCustomToolButton';
begin
//  RegisterWSComponent(TCustomToolButton, TGtk2WSToolButton);
  Result := False;
end;

function RegisterToolBar: Boolean; alias : 'WSRegisterToolBar';
begin
  Result := False;
//  RegisterWSComponent(TToolBar, TGtk2WSToolBar);
//  Result := True;
end;

function RegisterCustomTrackBar: Boolean; alias : 'WSRegisterCustomTrackBar';
begin
  Result := False;
//  RegisterWSComponent(TCustomTrackBar, TGtk2WSTrackBar);
//  Result := True;
end;

function RegisterCustomTreeView: Boolean; alias : 'WSRegisterCustomTreeView';
begin
//  RegisterWSComponent(TCustomTreeView, TGtk2WSCustomTreeView);
//  RegisterWSComponent(TCustomTreeView, TGtk2WSTreeView);
  Result := False;
end;

// calendar
function RegisterCustomCalendar: Boolean; alias : 'WSRegisterCustomCalendar';
begin
  Result := False;
//  RegisterWSComponent(TCustomCalendar, TGtk2WSCustomCalendar);
//  Result := True;
end;

// dialogs
function RegisterCommonDialog: Boolean; alias : 'WSRegisterCommonDialog';
begin
  Result := False;
//  RegisterWSComponent(TCommonDialog, TGtk2WSCommonDialog);
//  Result := True;
end;

function RegisterFileDialog: Boolean; alias : 'WSRegisterFileDialog';
begin
  Result := False;
//  RegisterWSComponent(TFileDialog, TGtk2WSFileDialog);
//  Result := True;
end;

function RegisterOpenDialog: Boolean; alias : 'WSRegisterOpenDialog';
begin
  Result := False;
//  RegisterWSComponent(TOpenDialog, TGtk2WSOpenDialog);
//  Result := True;
end;

function RegisterSaveDialog: Boolean; alias : 'WSRegisterSaveDialog';
begin
//  RegisterWSComponent(TSaveDialog, TGtk2WSSaveDialog);
  Result := False;
end;

function RegisterSelectDirectoryDialog: Boolean; alias : 'WSRegisterSelectDirectoryDialog';
begin
//  RegisterWSComponent(TSelectDirectoryDialog, TGtk2WSSelectDirectoryDialog);
  Result := False;
end;

function RegisterColorDialog: Boolean; alias : 'WSRegisterColorDialog';
begin
  Result := False;
//  RegisterWSComponent(TColorDialog, TGtk2WSColorDialog);
//  Result := True;
end;

function RegisterColorButton: Boolean; alias : 'WSRegisterColorButton';
begin
//  RegisterWSComponent(TColorButton, TGtk2WSColorButton);
  Result := False;
end;

function RegisterFontDialog: Boolean; alias : 'WSRegisterFontDialog';
begin
  Result := False;
//  RegisterWSComponent(TFontDialog, TGtk2WSFontDialog);
//  Result := True;
end;

// StdCtrls
function RegisterCustomScrollBar: Boolean; alias : 'WSRegisterCustomScrollBar';
begin
  Result := False;
//  RegisterWSComponent(TScrollBar, TGtk2WSScrollBar);
//  Result := True;
end;

function RegisterCustomGroupBox: Boolean; alias : 'WSRegisterCustomGroupBox';
begin
  Result := False;
//  RegisterWSComponent(TCustomGroupBox, TGtk2WSCustomGroupBox);
//  RegisterWSComponent(TGroupBox, TGtk2WSGroupBox);
//  Result := True;
end;

function RegisterCustomComboBox: Boolean; alias : 'WSRegisterCustomComboBox';
begin
  RegisterWSComponent(TCustomComboBox, TAndroidWSCustomComboBox);
  Result := True;
end;

function RegisterCustomListBox: Boolean; alias : 'WSRegisterCustomListBox';
begin
  Result := False;
//  RegisterWSComponent(TCustomListBox, TGtk2WSCustomListBox, TGtk2PrivateList);
//  RegisterWSComponent(TListBox, TGtk2WSListBox);
//  Result := True;
end;

function RegisterCustomEdit: Boolean; alias : 'WSRegisterCustomEdit';
begin
  RegisterWSComponent(TCustomEdit, TAndroidWSCustomEdit);
  Result := True;
end;

function RegisterCustomMemo: Boolean; alias : 'WSRegisterCustomMemo';
begin
  RegisterWSComponent(TCustomMemo, TAndroidWSCustomMemo);
  Result := True;
end;

function RegisterButtonControl: Boolean; alias : 'WSRegisterButtonControl';
begin
//  RegisterWSComponent(TButtonControl, TGtk2WSButtonControl);
  Result := False;
end;

function RegisterCustomButton: Boolean; alias : 'WSRegisterCustomButton';
begin
  RegisterWSComponent(TCustomButton, TAndroidWSButton);
  Result := True;
end;

function RegisterCustomCheckBox: Boolean; alias : 'WSRegisterCustomCheckBox';
begin
  RegisterWSComponent(TCustomCheckBox, TAndroidWSCustomCheckBox);
  Result := True;
end;

function RegisterToggleBox: Boolean; alias : 'WSRegisterToggleBox';
begin
  Result := False;
//  RegisterWSComponent(TToggleBox, TGtk2WSToggleBox); { GTK1 }
//  Result := True;
end;

function RegisterRadioButton: Boolean; alias : 'WSRegisterRadioButton';
begin
  Result := False;
//  RegisterWSComponent(TRadioButton, TGtk2WSRadioButton); { GTK1 }
//  Result := True;
end;

function RegisterCustomStaticText: Boolean; alias : 'WSRegisterCustomStaticText';
begin
  RegisterWSComponent(TCustomStaticText, TAndroidWSCustomStaticText); { GTK1 }
  Result := True;
end;

function RegisterCustomLabel: Boolean; alias : 'WSRegisterCustomLabel';
begin
//  RegisterWSComponent(TCustomLabel, TGtk2WSCustomLabel);
//  RegisterWSComponent(TLabel, TGtk2WSLabel);
  Result := False;
end;

// extctrls
function RegisterCustomPage: Boolean; alias : 'WSRegisterCustomPage';
begin
  Result := False;
//  RegisterWSComponent(TCustomPage, TGtk2WSCustomPage);
//  Result := True;
end;

function RegisterCustomNotebook: Boolean; alias : 'WSRegisterCustomNotebook';
begin
  Result := False;
//  RegisterWSComponent(TCustomTabControl, TGtk2WSCustomNotebook, TGtk2PrivateNotebook);
//  Result := True;
end;

function RegisterShape: Boolean; alias : 'WSRegisterShape';
begin
//  RegisterWSComponent(TShape, TGtk2WSShape);
  Result := False;
end;

function RegisterCustomSplitter: Boolean; alias : 'WSRegisterCustomSplitter';
begin
//  RegisterWSComponent(TCustomSplitter, TGtk2WSCustomSplitter);
//  RegisterWSComponent(TSplitter, TGtk2WSSplitter);
  Result := False;
end;

function RegisterPaintBox: Boolean; alias : 'WSRegisterPaintBox';
begin
//  RegisterWSComponent(TPaintBox, TGtk2WSPaintBox);
  Result := False;
end;

function RegisterCustomImage: Boolean; alias : 'WSRegisterCustomImage';
begin
//  RegisterWSComponent(TCustomImage, TGtk2WSCustomImage);
//  RegisterWSComponent(TImage, TGtk2WSImage);
  Result := False;
end;

function RegisterBevel: Boolean; alias : 'WSRegisterBevel';
begin
//  RegisterWSComponent(TBevel, TGtk2WSBevel);
  Result := False;
end;

function RegisterCustomRadioGroup: Boolean; alias : 'WSRegisterCustomRadioGroup';
begin
//  RegisterWSComponent(TCustomRadioGroup, TGtk2WSCustomRadioGroup);
//  RegisterWSComponent(TRadioGroup, TGtk2WSRadioGroup);
  Result := False;
end;

function RegisterCustomCheckGroup: Boolean; alias : 'WSRegisterCustomCheckGroup';
begin
//  RegisterWSComponent(TCustomCheckGroup, TGtk2WSCustomCheckGroup);
//  RegisterWSComponent(TCheckGroup, TGtk2WSCheckGroup);
  Result := False;
end;

function RegisterCustomLabeledEdit: Boolean; alias : 'WSRegisterCustomLabeledEdit';
begin
//  RegisterWSComponent(TBoundLabel, TGtk2WSBoundLabel);
//  RegisterWSComponent(TCustomLabeledEdit, TGtk2WSCustomLabeledEdit);
//  RegisterWSComponent(TLabeledEdit, TGtk2WSLabeledEdit);
  Result := False;
end;

function RegisterCustomPanel: Boolean; alias : 'WSRegisterCustomPanel';
begin
  Result := False;
//  RegisterWSComponent(TCustomPanel, TGtk2WSCustomPanel);
//  Result := False;
end;

function RegisterCustomTrayIcon: Boolean; alias : 'WSRegisterCustomTrayIcon';
begin
  Result := False;
//  RegisterWSComponent(TCustomTrayIcon, TGtk2WSCustomTrayIcon);
//  Result := True;
end;

//ExtDlgs
function RegisterPreviewFileControl: Boolean; alias : 'WSRegisterPreviewFileControl';
begin
  Result := False;
//  RegisterWSComponent(TPreviewFileControl, TGtk2WSPreviewFileControl); { GTK1 }
//  Result := True;
end;

function RegisterPreviewFileDialog: Boolean; alias : 'WSRegisterPreviewFileDialog';
begin
//  RegisterWSComponent(TPreviewFileDialog, TGtk2WSPreviewFileDialog);
  Result := False;
end;

function RegisterOpenPictureDialog: Boolean; alias : 'WSRegisterOpenPictureDialog';
begin
//  RegisterWSComponent(TOpenPictureDialog, TGtk2WSOpenPictureDialog);
  Result := False;
end;

function RegisterSavePictureDialog: Boolean; alias : 'WSRegisterSavePictureDialog';
begin
//  RegisterWSComponent(TSavePictureDialog, TGtk2WSSavePictureDialog);
  Result := False;
end;

function RegisterCalculatorDialog: Boolean; alias : 'WSRegisterCalculatorDialog';
begin
//  RegisterWSComponent(TCalculatorDialog, TGtk2WSCalculatorDialog);
  Result := False;
end;

function RegisterCalculatorForm: Boolean; alias : 'WSRegisterCalculatorForm';
begin
//  RegisterWSComponent(TCalculatorForm, TGtk2WSCalculatorForm);
  Result := False;
end;

(*function RegisterCalendarDialogForm: Boolean; alias : 'WSRegisterCalendarDialogForm';
begin
//  RegisterWSComponent(TCalendarDialogForm, TGtk2WSCalendarDialogForm);
  Result := False;
end;*)

function RegisterCalendarDialog: Boolean; alias : 'WSRegisterCalendarDialog';
begin
//  RegisterWSComponent(TCalendarDialog, TGtk2WSCalendarDialog);
  Result := False;
end;

// Buttons
function RegisterCustomBitBtn: Boolean; alias : 'WSRegisterCustomBitBtn';
begin
//  RegisterWSComponent(TCustomBitBtn, TGtk2WSBitBtn, TGtk2PrivateButton);
  Result := False;
//  Result := True;
end;

function RegisterCustomSpeedButton: Boolean; alias : 'WSRegisterCustomSpeedButton';
begin
//  RegisterWSComponent(TCustomSpeedButton, TGtk2WSSpeedButton);
  Result := False;
end;

// Arrow
function RegisterArrow: Boolean; alias : 'WSRegisterArrow';
begin
  Result := False;
//  RegisterWSComponent(TArrow, TGtk2WSArrow); { GTK2 }
//  Result := True;
end;

// CheckLst
function RegisterCustomCheckListBox: Boolean; alias : 'WSRegisterCustomCheckListBox';
begin
  Result := False;
//  RegisterWSComponent(TCustomCheckListBox, TGtk2WSCustomCheckListBox);
//  Result := True;
end;

// Forms
function RegisterScrollingWinControl: Boolean; alias : 'WSRegisterScrollingWinControl';
begin
  Result := False;
//  RegisterWSComponent(TScrollingWinControl, TGtk2WSScrollingWinControl, TGtkPrivateScrollingWinControl);
//  Result := True;
end;

function RegisterScrollBox: Boolean; alias : 'WSRegisterScrollBox';
begin
//  RegisterWSComponent(TScrollBox, TGtk2WSScrollBox);
  Result := False;
end;

function RegisterCustomFrame: Boolean; alias : 'WSRegisterCustomFrame';
begin
//  RegisterWSComponent(TCustomFrame, TGtk2WSCustomFrame);
//  RegisterWSComponent(TFrame, TGtk2WSFrame);
  Result := False;
end;

function RegisterCustomForm: Boolean; alias : 'WSRegisterCustomForm';
begin
  RegisterWSComponent(TCustomForm, TAndroidWSCustomForm);
  Result := True;
end;

function RegisterHintWindow: Boolean; alias : 'WSRegisterHintWindow';
begin
  Result := False;
//  RegisterWSComponent(THintWindow, TGtk2WSHintWindow); { GTK1 }
//  Result := True;
end;

function RegisterCustomGrid: Boolean; alias : 'WSRegisterCustomGrid';
begin
  Result := False;
//  RegisterWSComponent(TCustomGrid, TGtk2WSCustomGrid); { GTK1 }
//  Result := True;
end;

function RegisterMenuItem: Boolean; alias : 'WSRegisterMenuItem';
begin
  Result := False;
//  RegisterWSComponent(TMenuItem, TGtk2WSMenuItem);
//  Result := True;
end;

function RegisterMenu: Boolean; alias : 'WSRegisterMenu';
begin
  Result := False;
//  RegisterWSComponent(TMenu, TGtk2WSMenu);
//  Result := True;
end;

function RegisterMainMenu: Boolean; alias : 'WSRegisterMainMenu';
begin
//  RegisterWSComponent(TMainMenu, TGtk2WSMainMenu);
  Result := False;
end;

function RegisterPopupMenu: Boolean; alias : 'WSRegisterPopupMenu';
begin
  Result := False;
//  RegisterWSComponent(TPopupMenu, TGtk2WSPopupMenu); { GTK1 }
//  Result := True;
end;

function RegisterPairSplitterSide: Boolean; alias : 'WSRegisterPairSplitterSide';
begin
  Result := False;
//  RegisterWSComponent(TPairSplitterSide, TGtk2WSPairSplitterSide); { GTK1 }
//  Result := True;
end;

function RegisterCustomPairSplitter: Boolean; alias : 'WSRegisterCustomPairSplitter';
begin
  Result := False;
//  RegisterWSComponent(TCustomPairSplitter, TGtk2WSCustomPairSplitter);
//  Result := True;
end;

function RegisterCustomFloatSpinEdit: Boolean; alias : 'WSRegisterCustomFloatSpinEdit';
begin
  Result := False;
//  RegisterWSComponent(TCustomFloatSpinEdit, TGtk2WSCustomFloatSpinEdit);
//  Result := True;
end;

function RegisterCustomRubberBand: Boolean; alias : 'WSRegisterCustomRubberBand';
begin
//  RegisterWSComponent(TFloatSpinEdit, TGtk2WSFloatSpinEdit);
  Result := False;
end;

end.
