{
 *****************************************************************************
 *                              QtWidgets.pas                                *
 *                              --------------                               *
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
unit qtwidgets;

{$mode delphi}{$H+}

interface

uses
  // Bindings
{$ifdef USE_QT_4_3}
  qt43,
{$else}
  qt4,
{$endif}
  qtobjects,
  // Free Pascal
  Classes, SysUtils, Types,
  // LCL
  LCLType, LCLProc, LCLIntf, LMessages, Buttons, Forms, Controls, ComCtrls, CommCtrl,
  ExtCtrls, StdCtrls, Menus;

type
  // forward declarations
  TQtListWidget = class;

  //
  TPaintData = record
    ClipRect: Prect;
    ClipRegion: QRegionH;
  end;
  
  { TQtWidget }

  TQtWidget = class(TQtObject)
  private
    FOwnWidget: Boolean;
    FProps: TStringList;
    FPaintData: TPaintData;
    FCentralWidget: QWidgetH;
    FContext: HDC;
    FParams: TCreateParams;
    FDefaultCursor: QCursorH;

    function GetProps(const AnIndex: String): pointer;
    function GetWidget: QWidgetH;
    function LCLKeyToQtKey(AKey: Word): Integer;
    function QtButtonsToLCLButtons(AButtons: QTMouseButton): PtrInt;
    function QtKeyModifiersToKeyState(AModifiers: QtKeyboardModifiers): PtrInt;
    function QtKeyToLCLKey(AKey: Integer): Word;
    function DeliverMessage(var Msg): LRESULT;
    procedure SetProps(const AnIndex: String; const AValue: pointer);
    procedure SetWidget(const AValue: QWidgetH);
    function ShiftStateToQtModifiers(Shift: TShiftState): QtModifier;
  protected
    function CreateWidget(const Params: TCreateParams):QWidgetH; virtual;
    procedure SetGeometry; virtual; overload;
  public
    AVariant: QVariantH;
    LCLObject: TWinControl;
    HasCaret: Boolean;
  public
    constructor Create(const AWinControl: TWinControl; const AParams: TCreateParams); virtual;
    constructor CreateFrom(const AWinControl: TWinControl; AWidget: QWidgetH);
    procedure InitializeWidget;
    procedure DeInitializeWidget;
    procedure RecreateWidget;
    
    destructor Destroy; override;
    function  GetContainerWidget: QWidgetH; virtual;
  public
    function EventFilter(Sender: QObjectH; Event: QEventH): Boolean; cdecl; override;
    procedure SlotShow(vShow: Boolean); cdecl;
    procedure SlotClose; cdecl;
    procedure SlotDestroy; cdecl;
    procedure SlotFocus(FocusIn: Boolean); cdecl;
    procedure SlotHover(Sender: QObjectH; Event: QEventH); cdecl;
    procedure SlotKey(Event: QEventH); cdecl;
    procedure SlotMouse(Sender: QObjectH; Event: QEventH); cdecl;
    procedure SlotMouseEnter(Event: QEventH); cdecl;
    procedure SlotMouseMove(Event: QEventH); cdecl;
    procedure SlotMouseWheel(Sender: QObjectH; Event: QEventH); cdecl;
    procedure SlotMove(Event: QEventH); cdecl;
    procedure SlotPaint(Event: QEventH); cdecl;
    procedure SlotResize; cdecl;
    procedure SlotContextMenu; cdecl;
  public
    procedure Activate;
    procedure BringToFront;
    procedure OffsetMousePos(APoint: PQtPoint); virtual;
    procedure Update(ARect: PRect = nil);
    procedure Repaint(ARect: PRect = nil);
    procedure setWindowTitle(Str: PWideString);
    procedure WindowTitle(Str: PWideString);
    procedure Hide;
    procedure Show;
    procedure ShowNormal;
    procedure ShowMinimized;
    procedure ShowMaximized;
    function getEnabled: Boolean;
    function getFrameGeometry: TRect;
    function getGeometry: TRect; virtual;
    function getVisible: Boolean; virtual;
    function getClientBounds: TRect; virtual;
    procedure grabMouse;
    function hasFocus: Boolean;
    procedure move(ANewLeft, ANewTop: Integer);
    procedure resize(ANewWidth, ANewHeight: Integer);
    procedure releaseMouse;
    procedure setColor(const Value: PQColor); virtual;
    procedure setCursor(const ACursor: QCursorH);
    procedure setEnabled(p1: Boolean);
    procedure setGeometry(ARect: TRect); overload;
    procedure setMaximumSize(AWidth, AHeight: Integer);
    procedure setMinimumSize(AWidth, AHeight: Integer);
    procedure setParent(parent: QWidgetH); virtual;
    procedure setTextColor(const Value: PQColor); virtual;
    procedure setVisible(visible: Boolean); virtual;
    procedure setWindowFlags(_type: QtWindowFlags);
    procedure setWindowIcon(AIcon: QIconH);
    procedure setWindowModality(windowModality: QtWindowModality);
    procedure setWidth(p1: Integer);
    procedure setHeight(p1: Integer);
    procedure setTabOrder(p1, p2: TQtWidget);
    procedure setWindowState(AState: QtWindowStates);
    function windowFlags: QtWindowFlags;
    function windowModality: QtWindowModality;

    property Context: HDC read FContext;
    property Props[AnIndex:String]:pointer read GetProps write SetProps;
    property PaintData: TPaintData read FPaintData write FPaintData;
    property Widget: QWidgetH read GetWidget write SetWidget;
  end;

  { TQtAbstractSlider , inherited by TQtScrollBar, TQtTrackBar }

  TQtAbstractSlider = class(TQtWidget)
  private
    FSliderPressed: Boolean;
    FSliderReleased: Boolean;
    FRangeChangedHook: QAbstractSlider_hookH;
    FSliderMovedHook:  QAbstractSlider_hookH;
    FSliderPressedHook: QAbstractSlider_hookH;
    FSliderReleasedHook: QAbstractSlider_hookH;
    FValueChangedHook: QAbstractSlider_hookH;
  protected
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
  public
    procedure AttachEvents; override;
    procedure DetachEvents; override;

    procedure SlotSliderMoved(p1: Integer); cdecl; virtual;
    procedure SlotValueChanged(p1: Integer); cdecl; virtual;
    procedure SlotRangeChanged(minimum: Integer; maximum: Integer); cdecl; virtual;
    procedure SlotSliderPressed; cdecl;
    procedure SlotSliderReleased; cdecl;
 public
    function getValue: Integer;
    function getPageStep: Integer;
    function getMin: Integer;
    function getMax: Integer;
    function getSingleStep: Integer;

    procedure setInvertedAppereance(p1: Boolean); virtual;
    procedure setInvertedControls(p1: Boolean); virtual;

    procedure setMaximum(p1: Integer); virtual;
    procedure setMinimum(p1: Integer); virtual;

    procedure setOrientation(p1: QtOrientation); virtual;
    procedure setPageStep(p1: Integer); virtual;
    procedure setRange(minimum: Integer; maximum: Integer); virtual;
    procedure setSingleStep(p1: Integer); virtual;
    procedure setSliderDown(p1: Boolean); virtual;
    procedure setSliderPosition(p1: Integer); virtual;
    procedure setTracking(p1: Boolean); virtual;
    procedure setValue(p1: Integer); virtual;
    property SliderPressed: Boolean read FSliderPressed;
    property SliderReleased: Boolean read FSliderReleased;
  end;

  { TQtScrollBar }

  TQtScrollBar = class(TQtAbstractSlider)
  protected
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
  public
    procedure AttachEvents; override;
  end;

  { TQtFrame }

  TQtFrame = class(TQtWidget)
  private
  protected
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
  public
    procedure setFrameStyle(p1: Integer);
    procedure setFrameShape(p1: QFrameShape);
    procedure setFrameShadow(p1: QFrameShadow);
    procedure setTextColor(const Value: PQColor); override;
  end;
  
  { TQtAbstractScrollArea }

  TQtAbstractScrollArea = class(TQtFrame)
  private
    FCornerWidget: TQtWidget;
    FViewPortWidget: TQtWidget;
    FHScrollbar: TQtScrollBar;
    FVScrollbar: TQtScrollbar;
  protected
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
  public
    destructor Destroy; override;
  public
    function cornerWidget: TQtWidget;
    function horizontalScrollBar: TQtScrollBar;
    function verticalScrollBar: TQtScrollBar;
    function viewport: TQtWidget;
    function getClientBounds: TRect; override;
    procedure SetColor(const Value: PQColor); override;
    procedure setCornerWidget(AWidget: TQtWidget);
    procedure setHorizontalScrollBar(AScrollBar: TQtScrollBar);
    procedure setScrollStyle(AScrollStyle: TScrollStyle);
    procedure setTextColor(const Value: PQColor); override;
    procedure setVerticalScrollBar(AScrollBar: TQtScrollBar);
    procedure setVisible(visible: Boolean); override;
    procedure viewportNeeded;
  end;

  { TQtArrow }

  TQtArrow = class(TQtFrame)
  protected
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
  public
    ArrowType: Integer;
  end;

  { TQtAbstractButton }

  TQtAbstractButton = class(TQtWidget)
  private
  public
    procedure setColor(const Value: PQColor); override;
    procedure setIcon(AIcon: QIconH);
    procedure setShortcut(AShortcut: TShortcut);
    procedure setText(text: PWideString);
    procedure Text(retval: PWideString);
    procedure Toggle;
    function isChecked: Boolean;
    function isDown: Boolean;
    procedure setChecked(p1: Boolean);
    procedure setDown(p1: Boolean);
    procedure SignalPressed; cdecl;
    procedure SignalReleased; cdecl;
    procedure SignalClicked(Checked: Boolean = False); cdecl;
    procedure SignalClicked2; cdecl;
    procedure SignalToggled(Checked: Boolean); cdecl;
  end;

  { TQtPushButton }

  TQtPushButton = class(TQtAbstractButton)
  private
    FClickedHook: QAbstractButton_hookH;
  protected
    function CreateWidget(const AParams: TCreateParams): QWidgetH; override;
  public
    destructor Destroy; override;
  public
    procedure AttachEvents; override;
    procedure DetachEvents; override;
    
    procedure SlotClicked; cdecl;
  end;

  { TQtMainWindow }

  TQtMenuBar = class;
  TQtToolBar = class;

  TQtMainWindow = class(TQtWidget)
  private
    LayoutWidget: QBoxLayoutH;
  protected
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
  public
    IsMainForm: Boolean;
{$ifdef USE_QT_4_3}
    MDIAreaHandle: QMDIAreaH;
{$endif}
    MenuBar: TQtMenuBar;
    ToolBar: TQtToolBar;
    destructor Destroy; override;
    function getClientBounds: TRect; override;
    procedure setTabOrders;
    procedure setMenuBar(AMenuBar: QMenuBarH);
    function EventFilter(Sender: QObjectH; Event: QEventH): Boolean; cdecl; override;
    procedure OffsetMousePos(APoint: PQtPoint); override;
    procedure SlotWindowStateChange; cdecl;
    procedure setShowInTaskBar(AValue: Boolean);
  end;
  
  { TQtHintWindow }

  TQtHintWindow = class(TQtMainWindow)
  protected
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
  end;

  { TQtStaticText }

  TQtStaticText = class(TQtFrame)
  private
  protected
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
  public
    destructor Destroy; override;
    procedure getText(retval: PWideString);
    procedure setText(text: PWideString);
    procedure setAlignment(const AAlignment: QtAlignment);
  end;

  { TQtCheckBox }

  TQtCheckBox = class(TQtAbstractButton)
  private
    FStateChangedHook : QCheckBox_hookH;
  protected
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
  public
    destructor Destroy; override;
    function CheckState: QtCheckState;
    procedure setCheckState(state: QtCheckState);
  public
    procedure AttachEvents; override;
    procedure DetachEvents; override;
    
    procedure signalStateChanged(p1: Integer); cdecl;
  end;

  { TQtRadioButton }

  TQtRadioButton = class(TQtAbstractButton)
  private
    FClickedHook: QAbstractButton_hookH;
  protected
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
  public
    destructor Destroy; override;
  public
    procedure AttachEvents; override;
    procedure DetachEvents; override;
  end;

  { TQtGroupBox }

  TQtGroupBox = class(TQtWidget)
  protected
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
  public
    destructor Destroy; override;
  end;
  
  { TQtToolBar }
  
  TQtToolBar = class(TQtWidget)
  private
  protected
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
  end;
  
  { TQtToolButton }

  TQtToolButton = class(TQtAbstractButton)
  private
  protected
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
  end;
  
  { TQtTrackBar }
  
  TQtTrackBar = class(TQtAbstractSlider)
  private
  protected
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
  public
    procedure SetTickPosition(Value: QSliderTickPosition);
    procedure SetTickInterval(Value: Integer);
  public
    procedure AttachEvents; override;
    
    procedure SlotSliderMoved(p1: Integer); cdecl; override;
    procedure SlotValueChanged(p1: Integer); cdecl; override;
    procedure SlotRangeChanged(minimum: Integer; maximum: Integer); cdecl; override;
  end;

  { TQtLineEdit }

  TQtLineEdit = class(TQtWidget)
  private
    FTextChanged: QLineEdit_hookH;
  protected
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
  public
    function getMaxLength: Integer;
    function getSelectedText: WideString;
    function getSelectionStart: Integer;
    function getText: WideString;
    procedure setColor(const Value: PQColor); override;
    procedure setEchoMode(const AMode: QLineEditEchoMode);
    procedure setInputMask(const AMask: WideString);
    procedure setMaxLength(const ALength: Integer);
    procedure setReadOnly(const AReadOnly: Boolean);
    procedure setSelection(const AStart, ALength: Integer);
    procedure setText(const AText: WideString);
  public
    procedure AttachEvents; override;
    procedure DetachEvents; override;
    
    function EventFilter(Sender: QObjectH; Event: QEventH): Boolean; cdecl; override;
    procedure SignalTextChanged(p1: PWideString); cdecl;
  end;

  { TQtTextEdit }

  TQtTextEdit = class(TQtAbstractScrollArea)
  private
    FTextChangedHook: QTextEdit_hookH;
  protected
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
  public
    FList: TStrings;
    procedure append(AStr: WideString);
    function getPlainText: WideString;
    function getSelectionStart: Integer;
    function getSelectionEnd: Integer;
    procedure setAlignment(const AAlignment: QtAlignment);
    procedure setColor(const Value: PQColor); override;
    procedure setLineWrapMode(const AMode: QTextEditLineWrapMode);
    procedure setPlainText(const AText: WideString);
    procedure setReadOnly(const AReadOnly: Boolean);
    procedure setSelection(const AStart, ALength: Integer);
    procedure setTabChangesFocus(const AValue: Boolean);
  public
    procedure AttachEvents; override;
    procedure DetachEvents; override;
    procedure SignalTextChanged; cdecl;
  end;

  { TQtTabWidget }

  TQtTabWidget = class(TQtWidget)
  private
    FCurrentChangedHook: QTabWidget_hookH;
  protected
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
  public
    procedure AttachEvents; override;
    procedure DetachEvents; override;
    
    procedure SignalCurrentChanged(Index: Integer); cdecl;
  public
    function insertTab(index: Integer; page: QWidgetH; p2: PWideString): Integer; overload;
    function insertTab(index: Integer; page: QWidgetH; icon: QIconH; p2: PWideString): Integer; overload;
    function getCurrentIndex: Integer;
    procedure removeTab(AIndex: Integer);
    procedure setCurrentIndex(AIndex: Integer);
    procedure SetTabPosition(ATabPosition: QTabWidgetTabPosition);
    procedure setTabText(index: Integer; p2: PWideString);
  end;

  { TQtComboBox }

  TQtComboBox = class(TQtWidget)
  private
    // hooks
    FChangeHook: QComboBox_hookH;
    FOwnerDrawn: Boolean;
    FSelectHook: QComboBox_hookH;
    FDropListEventHook: QObject_hookH;
    // parts
    FLineEdit: QLineEditH;
    FDropList: TQtListWidget;
    function GetDropList: TQtListWidget;
    function GetLineEdit: QLineEditH;
    procedure SetOwnerDrawn(const AValue: Boolean);
  protected
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
  public
    FList: TStrings;
    destructor Destroy; override;
    procedure SetColor(const Value: PQColor); override;
    function currentIndex: Integer;
    function getEditable: Boolean;
    function getMaxVisibleItems: Integer;
    procedure insertItem(AIndex: Integer; AText: String); overload;
    procedure insertItem(AIndex: Integer; AText: PWideString); overload;
    procedure setCurrentIndex(index: Integer);
    procedure setMaxVisibleItems(ACount: Integer);
    procedure setEditable(AValue: Boolean);
    procedure removeItem(AIndex: Integer);
    
    property DropList: TQtListWidget read GetDropList;
    property LineEdit: QLineEditH read GetLineEdit;
    property OwnerDrawn: Boolean read FOwnerDrawn write SetOwnerDrawn;
  public
    procedure AttachEvents; override;
    procedure DetachEvents; override;
    function EventFilter(Sender: QObjectH; Event: QEventH): Boolean; cdecl; override;

    procedure SlotChange(p1: PWideString); cdecl;
    procedure SlotSelect(index: Integer); cdecl;
    procedure SlotDropListVisibility(AVisible: Boolean); cdecl;
  end;

  { TQtAbstractSpinBox}
  
  TQtAbstractSpinBox = class(TQtWidget)
  private
    FEditingFinishedHook: QAbstractSpinBox_hookH;
  protected
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
  public
    function IsReadOnly: Boolean;
    procedure SetReadOnly(r: Boolean);
  public
    procedure AttachEvents; override;
    procedure DetachEvents; override;
    
    procedure SignalEditingFinished; cdecl;
  end;

  { TQtFloatSpinBox }

  TQtFloatSpinBox = class(TQtAbstractSpinBox)
  private
    FValueChangedHook: QDoubleSpinBox_hookH;
  protected
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
  public
    procedure AttachEvents; override;
    procedure DetachEvents; override;

    procedure SignalValueChanged(p1: Double); cdecl;
  end;
  
  { TQtSpinBox }

  TQtSpinBox = class(TQtAbstractSpinBox)
  private
    FValueChangedHook: QSpinBox_hookH;
  protected
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
  public
    procedure AttachEvents; override;
    procedure DetachEvents; override;

    procedure SignalValueChanged(p1: Integer); cdecl;
  end;

  { TQtAbstractItemView }

  TQtAbstractItemView = class(TQtAbstractScrollArea)
  private
    FOldDelegate: QAbstractItemDelegateH;
    FNewDelegate: QLCLItemDelegateH;
    function GetOwnerDrawn: Boolean;
    procedure SetOwnerDrawn(const AValue: Boolean);
  public
    constructor Create(const AWinControl: TWinControl; const AParams: TCreateParams); override;
    procedure modelIndex(retval: QModelIndexH; row, column: Integer; parent: QModelIndexH = nil);
    function visualRect(Index: QModelIndexH): TRect;
    property OwnerDrawn: Boolean read GetOwnerDrawn write SetOwnerDrawn;
  public
    procedure ItemDelegateSizeHint(option: QStyleOptionViewItemH; index: QModelIndexH; Size: PSize); cdecl;
    procedure ItemDelegatePaint(painter: QPainterH; option: QStyleOptionViewItemH; index: QModelIndexH); cdecl; virtual;
  end;

  { TQtListView }

  TQtListView = class(TQtAbstractItemView)
  public
  end;

  { TQtListWidget }

  TQtListWidget = class(TQtListView)
  private
    FSelectionChangeHook: QListWidget_hookH;
    FItemDoubleClickedHook: QListWidget_hookH;
    FItemClickedHook: QListWidget_hookH;
  protected
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
  public
    FList: TStrings;
  public
    procedure AttachEvents; override;
    procedure DetachEvents; override;
    
    procedure SlotSelectionChange(current: QListWidgetItemH; previous: QListWidgetItemH); cdecl;
    procedure SignalItemDoubleClicked(item: QListWidgetItemH); cdecl;
    procedure SignalItemClicked(item: QListWidgetItemH); cdecl;
    procedure ItemDelegatePaint(painter: QPainterH; option: QStyleOptionViewItemH; index: QModelIndexH); cdecl; override;
  public
    function currentRow: Integer;
    function IndexAt(APoint: PQtPoint): Integer;
    procedure setCurrentRow(row: Integer);
  end;
  
  { TQtHeaderView }

  TQtHeaderView = class (TQtAbstractItemView)
  private
    FSelectionClicked: QHeaderView_hookH;
  protected
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
  public
    procedure AttachEvents; override;
    procedure DetachEvents; override;
    procedure SignalSectionClicked(logicalIndex: Integer) cdecl;
  end;

  { TQtTreeView }
  
  TQtTreeView = class (TQtAbstractItemView)
  private
  protected
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
  end;
  
  { TQtTreeWidget }

  TQtTreeWidget = class(TQtTreeView)
  private
    Header: TQtHeaderView;
    FCurrentItemChangedHook: QTreeWidget_hookH;
    FItemDoubleClickedHook: QTreeWidget_hookH;
    FItemClickedHook: QTreeWidget_hookH;
    FItemActivatedHook: QTreeWidget_hookH;
    FItemChangedHook: QTreeWidget_hookH;
    FItemSelectionChangedHook: QTreeWidget_hookH;
    FItemPressedHook: QTreeWidget_hookH;
    FItemEnteredHook: QTreeWidget_hookH;
  protected
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
  public
    destructor Destroy; override;
    
    function currentRow: Integer;
    procedure setCurrentRow(row: Integer);
  public
    procedure AttachEvents; override;
    procedure DetachEvents; override;
    
    procedure SignalItemPressed(item: QTreeWidgetItemH; column: Integer) cdecl;
    procedure SignalItemClicked(item: QTreeWidgetItemH; column: Integer) cdecl;
    procedure SignalItemDoubleClicked(item: QTreeWidgetItemH; column: Integer) cdecl;
    procedure SignalItemActivated(item: QTreeWidgetItemH; column: Integer) cdecl;
    procedure SignalItemEntered(item: QTreeWidgetItemH; column: Integer) cdecl;
    procedure SignalItemChanged(item: QTreeWidgetItemH; column: Integer) cdecl;
    procedure SignalitemExpanded(item: QTreeWidgetItemH) cdecl;
    procedure SignalItemCollapsed(item: QTreeWidgetItemH) cdecl;
    procedure SignalCurrentItemChanged(current: QTreeWidgetItemH; previous: QTreeWidgetItemH) cdecl;
    procedure SignalItemSelectionChanged; cdecl;
  end;

  { TQtMenu }

  TQtMenu = class(TQtWidget)
  private
    FIcon: QIconH;
    FActionHook: QAction_hookH;
  public
    MenuItem: TMenuItem;
  public
    constructor Create(const AParent: QWidgetH); overload;
    constructor Create(const AHandle: QMenuH); overload;
    destructor Destroy; override;
  public
    procedure AttachEvents; override;
    procedure DetachEvents; override;
    
    procedure SlotDestroy; cdecl;
    procedure SlotTriggered(checked: Boolean = False); cdecl;
    function EventFilter(Sender: QObjectH; Event: QEventH): Boolean; cdecl; override;
  public
    procedure PopUp(pos: PQtPoint; at: QActionH = nil);
    function actionHandle: QActionH;
    function addMenu(title: PWideString): TQtMenu;
    function addSeparator: TQtMenu;
    function getVisible: Boolean; override;
    procedure setChecked(p1: Boolean);
    procedure setCheckable(p1: Boolean);
    procedure setHasSubmenu(AValue: Boolean);
    procedure setIcon(AIcon: QIconH);
    procedure setImage(AImage: TQtImage);
    procedure setSeparator(AValue: Boolean);
    procedure setShortcut(AShortcut: TShortcut);
    procedure setText(AText: PWideString);
    procedure setVisible(visible: Boolean); override;
  end;

  { TQtMenuBar }

  TQtMenuBar = class(TQtWidget)
  private
    FVisible: Boolean;
    FHeight: Integer;
  public
    constructor Create(const AParent: QWidgetH); overload;
  public
    function addMenu(title: PWideString): TQtMenu;
    function addSeparator: TQtMenu;
    function getGeometry: TRect; override;
  end;

  { TQtProgressBar }

  TQtProgressBar = class(TQtWidget)
  private
    FValueChangedHook: QProgressBar_hookH;
  protected
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
  public
    procedure AttachEvents; override;
    procedure DetachEvents; override;
    procedure SignalValueChanged(Value: Integer); cdecl;
  public
    procedure setRange(minimum: Integer; maximum: Integer);
    procedure setTextVisible(visible: Boolean);
    procedure setAlignment(const AAlignment: QtAlignment);
    procedure setTextDirection(textDirection: QProgressBarDirection);
    procedure setValue(value: Integer);
    procedure setOrientation(p1: QtOrientation);
    procedure setInvertedAppearance(invert: Boolean);
  end;

  { TQtStatusBar }

  TQtStatusBar = class(TQtWidget)
  private
  protected
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
  public
    APanels: Array of QLabelH;
    procedure showMessage(text: PWideString; timeout: Integer = 0);
  end;
  
  { TQtDialog }
  
  TQtDialog = class(TQtWidget)
  private
  public
    constructor Create(parent: QWidgetH = nil; f: QtWindowFlags = 0); overload;
    function exec: Integer;
  end;
  
  { TQtCalendar }

  TQtCalendar = class(TQtWidget)
  private
    FClickedHook: QCalendarWidget_hookH;
    FActivatedHook: QCalendarWidget_hookH;
    FSelectionChangedHook: QCalendarWidget_hookH;
    FCurrentPageChangedHook: QCalendarWidget_hookH;
  protected
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
  public
    AYear, AMonth, ADay: Word;
    procedure AttachEvents; override;
    procedure DetachEvents; override;
    
    procedure SignalActivated(ADate: QDateH); cdecl;
    procedure SignalClicked(ADate: QDateH); cdecl;
    procedure SignalSelectionChanged; cdecl;
    procedure SignalCurrentPageChanged(p1, p2: Integer); cdecl;
  end;
  
  // for page control / notebook

  { TQtPage }

  TQtPage = class(TQtWidget)
  protected
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
  end;
  
  { TQtRubberBand }
  
  TQtRubberBand = class(TQtWidget)
  private
    FShape: QRubberBandShape;
  protected
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
  public
    constructor Create(const AWinControl: TWinControl; const AParams: TCreateParams); override;
    function getShape: QRubberBandShape;
    procedure setShape(AShape: QRubberBandShape);
  end;

const
  AlignmentMap: array[TAlignment] of QtAlignment =
  (
{taLeftJustify } QtAlignLeft,
{taRightJustify} QtAlignRight,
{taCenter      } QtAlignHCenter
  );

implementation

uses
  LCLMessageGlue,
  qtCaret;

const
  DblClickThreshold = 3;// max Movement between two clicks of a DblClick

type
  TLastMouseInfo = record
    Widget: QObjectH;
    MousePos: TQtPoint;
    TheTime: TDateTime;
    ClickCount: Integer;
  end;

var
{$IFDEF DARWIN}
  LastMouse: TLastMouseInfo = (Widget: nil; MousePos: (y:0; x:0); TheTime:0; ClickCount: 0);
{$ELSE}
  LastMouse: TLastMouseInfo = (Widget: nil; MousePos: (x:0; y:0); TheTime:0; ClickCount: 0);
{$ENDIF}

{ TQtWidget }

{------------------------------------------------------------------------------
  Function: TQtWidget.Create
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
constructor TQtWidget.Create(const AWinControl: TWinControl; const AParams: TCreateParams);
begin
  inherited Create;

  FOwnWidget := True;
  // Initializes the properties
  FProps := nil;
  LCLObject := AWinControl;

  FParams := AParams;
  InitializeWidget;
end;

constructor TQtWidget.CreateFrom(const AWinControl: TWinControl;
  AWidget: QWidgetH);
begin
  inherited Create;

  FOwnWidget := False;
  // Initializes the properties
  FProps := niL;
  LCLObject := AWinControl;

  // Creates the widget
  Widget := AWidget;

  // set Handle->QWidget map
  AVariant := QVariant_Create(Int64(ptruint(Self)));
  QObject_setProperty(QObjectH(Widget), 'lclwidget', AVariant);

  fillchar(FPaintData, sizeOf(FPaintData), 0);
end;

procedure TQtWidget.InitializeWidget;
begin
  // Creates the widget
  Widget := CreateWidget(FParams);

  // retrieve default cursor on create
  FDefaultCursor := QCursor_create();
  QWidget_cursor(Widget, FDefaultCursor);
  
  {$ifdef VerboseQt}
  DebugLn('TQtWidget.InitializeWidget: Self:%x Widget:%x was created for control %s',
    [ptrint(Self), ptrint(Widget), LCLObject.Name]);
  {$endif}

  // set Handle->QWidget map
  AVariant := QVariant_Create(Int64(ptruint(Self)));
  QObject_setProperty(QObjectH(Widget), 'lclwidget', AVariant);

  fillchar(FPaintData, sizeOf(FPaintData), 0);

  // Sets it's initial properties
  SetGeometry;

  // set focus policy
  if LCLObject.TabStop then
    QWidget_setFocusPolicy(Widget, QtStrongFocus);

  // Set mouse move messages policy
  QWidget_setMouseTracking(Widget, True);
end;

procedure TQtWidget.DeInitializeWidget;
begin
  if Widget <> nil then
    DetachEvents;

  QVariant_destroy(AVariant);

  {$ifdef VerboseQt}
    WriteLn('Calling QWidget_destroy');
  {$endif}
  
  QCursor_destroy(FDefaultCursor);
  
  if (Widget <> nil) and FOwnWidget then
    QWidget_destroy(QWidgetH(Widget));
  Widget := nil;
end;

procedure TQtWidget.RecreateWidget;
var
  Parent: QWidgetH;
begin
  if Widget <> nil then
    Parent := QWidget_parentWidget(Widget)
  else
    Parent := nil;
  DeinitializeWidget;
  InitializeWidget;
  if Parent <> nil then
    setParent(Parent);
end;

{------------------------------------------------------------------------------
  Function: TQtWidget.Destroy
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
destructor TQtWidget.Destroy;
begin
  DeinitializeWidget;

  if FProps<>nil then
  begin
    FProps.Free;
    FProps:=nil;
  end;

  if FPaintData.ClipRegion<>nil then
  begin
    QRegion_Destroy(FPaintData.ClipRegion);
    FPaintData.ClipRegion:=nil;
  end;

  inherited Destroy;
end;

{------------------------------------------------------------------------------
  Function: TQtWidget.GetContainerWidget
  Params:  None
  Returns: The widget of the control on top of which other controls
           should be placed
 ------------------------------------------------------------------------------}
function TQtWidget.GetContainerWidget: QWidgetH;
begin
  if FCentralWidget <> nil then
    Result := FCentralWidget
  else
    Result := Widget;
end;

{$IFDEF VerboseQt}
function EventTypeToStr(Event:QEventH):string;
// Qt 3 events
const
  QEventChildInsertedRequest = 67;
  QEventChildInserted = 70;
  QEventLayoutHint = 72;
begin
  case QEvent_type(Event) of
    QEventNone: result:='QEventNone';
    QEventTimer: result:='QEventTimer';
    QEventMouseButtonPress: result:='QEventMouseButtonPress';
    QEventMouseButtonRelease: result:='QEventMouseButtonRelease';
    QEventMouseButtonDblClick: result:='QEventMouseButtonDblClick';
    QEventMouseMove: result:='QEventMouseMove';
    QEventKeyPress: result:='QEventKeyPress';
    QEventKeyRelease: result:='QEventKeyRelease';
    QEventFocusIn: result:='QEventFocusIn';
    QEventFocusOut: result:='QEventFocusOut';
    QEventEnter: result:='QEventEnter';
    QEventLeave: result:='QEventLeave';
    QEventPaint: result:='QEventPaint';
    QEventMove: result:='QEventMove';
    QEventResize: result:='QEventResize';
    QEventCreate: result:='QEventCreate';
    QEventDestroy: result:='QEventDestroy';
    QEventShow: result:='QEventShow';
    QEventHide: result:='QEventHide';
    QEventClose: result:='QEventClose';
    QEventQuit: result:='QEventQuit';
    QEventParentChange: result:='QEventParentChange';
    QEventThreadChange: result:='QEventThreadChange';
    QEventWindowActivate: result:='QEventWindowActivate';
    QEventWindowDeactivate: result:='QEventWindowDeactivate';
    QEventShowToParent: result:='QEventShowToParent';
    QEventHideToParent: result:='QEventHideToParent';
    QEventWheel: result:='QEventWheel';
    QEventWindowTitleChange: result:='QEventWindowTitleChange';
    QEventWindowIconChange: result:='QEventWindowIconChange';
    QEventApplicationWindowIconChange: result:='QEventApplicationWindowIconChange';
    QEventApplicationFontChange: result:='QEventApplicationFontChange';
    QEventApplicationLayoutDirectionChange: result:='QEventApplicationLayoutDirectionChange';
    QEventApplicationPaletteChange: result:='QEventApplicationPaletteChange';
    QEventPaletteChange: result:='QEventPaletteChange';
    QEventClipboard: result:='QEventClipboard';
    QEventSpeech: result:='QEventSpeech';
    QEventMetaCall: result:='QEventMetaCall';
    QEventSockAct: result:='QEventSockAct';
    QEventShortcutOverride: result:='QEventShortcutOverride';
    QEventDeferredDelete: result:='QEventDeferredDelete';
    QEventDragEnter: result:='QEventDragEnter';
    QEventDragMove: result:='QEventDragMove';
    QEventDragLeave: result:='QEventDragLeave';
    QEventDrop: result:='QEventDrop';
    QEventDragResponse: result:='QEventDragResponse';
//    QEventChildInsertedRequest: result:='(Qt3) QEventChildAdded'; //qt3
    QEventChildAdded: result:='QEventChildAdded';
    QEventChildPolished: result:='QEventChildPolished';
//    QEventChildInserted: result:='(Qt3) QEventChildAdded'; // qt3
//    QEventLayoutHint: result:='(Qt3) QEventChildAdded'; // qt3
    QEventChildRemoved: result:='QEventChildRemoved';
    QEventShowWindowRequest: result:='QEventShowWindowRequest';
    QEventPolishRequest: result:='QEventPolishRequest';
    QEventPolish: result:='QEventPolish';
    QEventLayoutRequest: result:='QEventLayoutRequest';
    QEventUpdateRequest: result:='QEventUpdateRequest';
    QEventUpdateLater: result:='QEventUpdateLater';
    QEventEmbeddingControl: result:='QEventEmbeddingControl';
    QEventActivateControl: result:='QEventActivateControl';
    QEventDeactivateControl: result:='QEventDeactivateControl';
    QEventContextMenu: result:='QEventContextMenu';
    QEventInputMethod: result:='QEventInputMethod';
    QEventAccessibilityPrepare: result:='QEventAccessibilityPrepare';
    QEventTabletMove: result:='QEventTabletMove';
    QEventLocaleChange: result:='QEventLocaleChange';
    QEventLanguageChange: result:='QEventLanguageChange';
    QEventLayoutDirectionChange: result:='QEventLayoutDirectionChange';
    QEventStyle: result:='QEventStyle';
    QEventTabletPress: result:='QEventTabletPress';
    QEventTabletRelease: result:='QEventTabletRelease';
    QEventOkRequest: result:='QEventOkRequest';
    QEventHelpRequest: result:='QEventHelpRequest';
    QEventIconDrag: result:='QEventIconDrag';
    QEventFontChange: result:='QEventFontChange';
    QEventEnabledChange: result:='QEventEnabledChange';
    QEventActivationChange: result:='QEventActivationChange';
    QEventStyleChange: result:='QEventStyleChange';
    QEventIconTextChange: result:='QEventIconTextChange';
    QEventModifiedChange: result:='QEventModifiedChange';
    QEventWindowBlocked: result:='QEventWindowBlocked';
    QEventWindowUnblocked: result:='QEventWindowUnblocked';
    QEventWindowStateChange: result:='QEventWindowStateChange';
    QEventMouseTrackingChange: result:='QEventMouseTrackingChange';
    QEventToolTip: result:='QEventToolTip';
    QEventWhatsThis: result:='QEventWhatsThis';
    QEventStatusTip: result:='QEventStatusTip';
    QEventActionChanged: result:='QEventActionChanged';
    QEventActionAdded: result:='QEventActionAdded';
    QEventActionRemoved: result:='QEventActionRemoved';
    QEventFileOpen: result:='QEventFileOpen';
    QEventShortcut: result:='QEventShortcut';
    QEventWhatsThisClicked: result:='QEventWhatsThisClicked';
    QEventAccessibilityHelp: result:='QEventAccessibilityHelp';
    QEventToolBarChange: result:='QEventToolBarChange';
    QEventApplicationActivated: result:='QEventApplicationActivated';
    QEventApplicationDeactivated: result:='QEventApplicationDeactivated';
    QEventQueryWhatsThis: result:='QEventQueryWhatsThis';
    QEventEnterWhatsThisMode: result:='QEventEnterWhatsThisMode';
    QEventLeaveWhatsThisMode: result:='QEventLeaveWhatsThisMode';
    QEventZOrderChange: result:='QEventZOrderChange';
    QEventHoverEnter: result:='QEventHoverEnter';
    QEventHoverLeave: result:='QEventHoverLeave';
    QEventHoverMove: result:='QEventHoverMove';
    QEventAccessibilityDescription: result:='QEventAccessibilityDescription';
    QEventParentAboutToChange: result:='QEventParentAboutToChange';
    QEventWinEventAct: result:='QEventWinEventAct';
    QEventAcceptDropsChange: result:='QEventAcceptDropsChange';
    QEventMenubarUpdated: result:='QEventMenubarUpdated';
    QEventZeroTimerEvent: result:='QEventZeroTimerEvent';
    QEventNonClientAreaMouseMove: result:='QEventNonClientAreaMouseMove';
    QEventNonClientAreaMouseButtonPress: result:='QEventNonClientAreaMouseButtonPress';
    QEventNonClientAreaMouseButtonRelease: result:='QEventNonClientAreaMouseButtonRelease';
    QEventNonClientAreaMouseButtonDblClick: result:='QEventNonClientAreaMouseButtonDblClick';
    QEventUser: result:='QEventUser';
    QEventMaxUser: result:='QEventMaxUser';
  else
    Result := Format('Unknown event: %d', [QEvent_type(Event)]);
  end;
end;
{$ENDIF}

{------------------------------------------------------------------------------
  Function: TQtWidget.EventFilter
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
function TQtWidget.EventFilter(Sender: QObjectH; Event: QEventH): Boolean; cdecl;
begin
  BeginEventProcessing;
  Result := False;

  QEvent_accept(Event);

  {$ifdef VerboseQt}
  WriteLn('TQtWidget.EventFilter: Sender=', IntToHex(ptrint(Sender),8),
    ' LCLObject=', dbgsName(LCLObject),
    ' Event=', EventTypeToStr(Event));
  {$endif}

  case QEvent_type(Event) of
    QEventShow: SlotShow(True);
    QEventHide: SlotShow(False);
    QEventClose:
      begin
        Result := True;
        QEvent_ignore(Event);
        SlotClose;
     end;
    QEventDestroy: SlotDestroy;
    QEventEnter: SlotMouseEnter(Event);
    QEventFocusIn: SlotFocus(True);
    QEventFocusOut:
    begin
      SlotFocus(False);
      if QFocusEvent_reason(QFocusEventH(Event)) <> QtMouseFocusReason then
        releaseMouse;
    end;

    QEventHoverEnter,
    QEventHoverLeave,
    QEventHoverMove:
      begin
        SlotHover(Sender, Event);
      end;

    QEventKeyPress,
    QEventKeyRelease:
      begin
        SlotKey(Event);
        Result := LCLObject is TCustomControl;
      end;
    QEventLeave: SlotMouseEnter(Event);

    QEventMouseButtonPress,
    QEventMouseButtonRelease,
    QEventMouseButtonDblClick:
      begin
        SlotMouse(Sender, Event);
      end;
    QEventMouseMove:
      begin
        SlotMouseMove(Event);
      end;
    QEventWheel:
      begin
        SlotMouseWheel(Sender, Event);
      end;
    QEventMove: SlotMove(Event);
    QEventResize: SlotResize;
    QEventPaint: SlotPaint(Event);
    QEventContextMenu: SlotContextMenu;
  else
    QEvent_ignore(Event);
  end;
  EndEventProcessing;
end;

{------------------------------------------------------------------------------
  Function: TQtWidget.SlotShow
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtWidget.SlotShow(vShow: Boolean); cdecl;
var
  Msg: TLMShowWindow;
begin
  {$ifdef VerboseQt}
    WriteLn('TQtWidget.SlotShow Name', LCLObject.Name, ' vShow: ', dbgs(vShow));
  {$endif}

  FillChar(Msg, SizeOf(Msg), #0);

  Msg.Msg := LM_SHOWWINDOW;
  Msg.Show := vShow;

  DeliverMessage(Msg);
end;

{------------------------------------------------------------------------------
  Function: TQtWidget.Close
  Params:  None
  Returns: Nothing

  Note: LCL uses LM_CLOSEQUERY to set the form visibility and if we don�t send this
 message, you won�t be able to show a form twice.
 ------------------------------------------------------------------------------}
procedure TQtWidget.SlotClose; cdecl;
begin
  {$ifdef VerboseQt}
    WriteLn('TQtWidget.SlotClose');
  {$endif}

  LCLSendCloseQueryMsg(LCLObject);
end;

{------------------------------------------------------------------------------
  Function: TQtWidget.SlotDestroy
  Params:  None
  Returns: Nothing

  Currently commented because it was raising exception on software exit
 ------------------------------------------------------------------------------}
procedure TQtWidget.SlotDestroy; cdecl;
var
  Msg: TLMessage;
begin
  {$ifdef VerboseQt}
    WriteLn('TQtWidget.SlotDestroy');
  {$endif}
  Widget := nil;
  
  FillChar(Msg, SizeOf(Msg), #0);

  Msg.Msg := LM_DESTROY;

  DeliverMessage(Msg);
end;

{------------------------------------------------------------------------------
  Function: TQtWidget.SlotFocus
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtWidget.SlotFocus(FocusIn: Boolean); cdecl;
var
  Msg: TLMessage;
begin
  {$ifdef VerboseFocus}
    WriteLn('TQtWidget.SlotFocus In=',FocusIn,' For ', dbgsname(LCLObject));
  {$endif}

  FillChar(Msg, SizeOf(Msg), #0);

  if FocusIn then
    Msg.Msg := LM_SETFOCUS
  else
    Msg.Msg := LM_KILLFOCUS;

  DeliverMessage(Msg);

  {$ifdef VerboseFocus}
    WriteLn('TQtWidget.SlotFocus END');
  {$endif}
end;

procedure TQtWidget.SlotHover(Sender: QObjectH; Event: QEventH); cdecl;
var
  Msg: TLMessage;
  MouseMsg: TLMMouseMove absolute Msg;
  MousePos: PQtPoint;
begin
  if QApplication_mouseButtons() = 0 then // in other case MouseMove will be hooked
  begin
    FillChar(Msg, SizeOf(Msg), #0);

    MousePos := QHoverEvent_pos(QHoverEventH(Event));
    OffsetMousePos(MousePos);

    case QEvent_type(Event) of
      QEventHoverEnter : Msg.Msg := CM_MOUSEENTER;
      QEventHoverLeave : Msg.Msg := CM_MOUSELEAVE;
      QEventHoverMove  :
        begin
          MouseMsg.Msg := LM_MOUSEMOVE;
          MouseMsg.XPos := SmallInt(MousePos^.X);
          MouseMsg.YPos := SmallInt(MousePos^.Y);
        end;
    end;
    NotifyApplicationUserInput(Msg.Msg);
    DeliverMessage(Msg);
  end;
end;

{------------------------------------------------------------------------------
  Function: TQtWidget.SlotKey
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtWidget.SlotKey(Event: QEventH); cdecl;
const
  CN_KeyDownMsgs: array[Boolean] of UINT = (CN_KEYDOWN, CN_SYSKEYDOWN);
  CN_KeyUpMsgs: array[Boolean] of UINT = (CN_KEYUP, CN_SYSKEYUP);
  LM_KeyDownMsgs: array[Boolean] of UINT = (LM_KEYDOWN, LM_SYSKEYDOWN);
  LM_KeyUpMsgs: array[Boolean] of UINT = (LM_KEYUP, LM_SYSKEYUP);
  CN_CharMsg: array[Boolean] of UINT = (CN_CHAR, CN_SYSCHAR);
  LM_CharMsg: array[Boolean] of UINT = (LM_CHAR, LM_SYSCHAR);
var
  KeyMsg: TLMKey;
  CharMsg: TLMChar;
  Modifiers: QtKeyboardModifiers;
  IsSysKey: Boolean;
  Text: WideString;
  UTF8Char: TUTF8Char;
begin
  {$ifdef VerboseQt}
    Write('TQtWidget.SlotKey');
  {$endif}

  FillChar(KeyMsg, SizeOf(KeyMsg), #0);

  // Detects special keys (shift, alt, control, etc)
  Modifiers := QKeyEvent_modifiers(QKeyEventH(Event));
  IsSysKey := (QtAltModifier and Modifiers) <> $0;
  KeyMsg.KeyData := QtKeyModifiersToKeyState(Modifiers);

  // Translates a Qt4 Key to a LCL VK_* key
  KeyMsg.CharCode := QtKeyToLCLKey(QKeyEvent_key(QKeyEventH(Event)));
  
  // Loads the UTF-8 character associated with the keypress, if any
  QKeyEvent_text(QKeyEventH(Event), @Text);

  {------------------------------------------------------------------------------
   Sends the adequate key messages
   ------------------------------------------------------------------------------}
  case QEvent_type(Event) of
    QEventKeyPress: KeyMsg.Msg := CN_KeyDownMsgs[IsSysKey];
    QEventKeyRelease: KeyMsg.Msg := CN_KeyUpMsgs[IsSysKey];
  end;

  {$ifdef VerboseQt}
    WriteLn(' message: ', Msg.Msg);
  {$endif}
  if KeyMsg.CharCode <> VK_UNKNOWN then
  begin
    NotifyApplicationUserInput(KeyMsg.Msg);
    if (DeliverMessage(KeyMsg) <> 0) or (KeyMsg.CharCode=VK_UNKNOWN) then
      Exit;

    // here we should let widgetset to handle key
    //...

    case QEvent_type(Event) of
      QEventKeyPress: KeyMsg.Msg := LM_KeyDownMsgs[IsSysKey];
      QEventKeyRelease: KeyMsg.Msg := LM_KeyUpMsgs[IsSysKey];
    end;
    NotifyApplicationUserInput(KeyMsg.Msg);
    if (DeliverMessage(KeyMsg) <> 0) or (KeyMsg.CharCode=VK_UNKNOWN) then
      // the LCL handled the key
      Exit;
  end;
  { Also sends a utf-8 key event for key down }

  if (QEvent_type(Event) = QEventKeyPress) and (Length(Text) <> 0) then
  begin
    UTF8Char := TUTF8Char(Text);
    if LCLObject.IntfUTF8KeyPress(UTF8Char, 1, IsSysKey) then
    begin
      // the LCL has handled the key
      Exit;
    end;

    // create the CN_CHAR / CN_SYSCHAR message
    FillChar(CharMsg, SizeOf(CharMsg), 0);
    CharMsg.Msg := CN_CharMsg[IsSysKey];
    CharMsg.KeyData := KeyMsg.KeyData;
    CharMsg.CharCode := ord(Text[1]);

    //Send message to LCL
    NotifyApplicationUserInput(CharMsg.Msg);
    if (DeliverMessage(CharMsg) <> 0) or (CharMsg.CharCode = VK_UNKNOWN) then
      // the LCL handled the key
      Exit;

    //Here is where we (interface) can do something with the key
    //...

    //Send a LM_(SYS)CHAR
    CharMsg.Msg := LM_CharMsg[IsSysKey];

    NotifyApplicationUserInput(CharMsg.Msg);
    if DeliverMessage(CharMsg) <> 0 then
      Exit;
  end;
end;

{------------------------------------------------------------------------------
  Function: TQtWidget.SlotMouse
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtWidget.SlotMouse(Sender: QObjectH; Event: QEventH); cdecl;
const
  // array of clickcount x buttontype
  MSGKIND: array[0..2, 1..4] of Integer =
  (
    (LM_LBUTTONDOWN, LM_LBUTTONDBLCLK, LM_LBUTTONTRIPLECLK, LM_LBUTTONQUADCLK),
    (LM_RBUTTONDOWN, LM_RBUTTONDBLCLK, LM_RBUTTONTRIPLECLK, LM_RBUTTONQUADCLK),
    (LM_MBUTTONDOWN, LM_MBUTTONDBLCLK, LM_MBUTTONTRIPLECLK, LM_MBUTTONQUADCLK)
  );
var
  Msg: TLMMouse;
  MousePos: PQtPoint;
  MButton: QTMouseButton;
  Modifiers: QtKeyboardModifiers;

  function CheckMouseButtonDown(AButton: Integer): Cardinal;

    function LastClickInSameWidget: boolean;
    begin
      Result := (LastMouse.Widget <> nil) and
                (LastMouse.Widget = Sender);
    end;

    function LastClickAtSamePosition: boolean;
    begin
      Result:= (Abs(MousePos.X-LastMouse.MousePos.X) <= DblClickThreshold) and
               (Abs(MousePos.Y-LastMouse.MousePos.Y) <= DblClickThreshold);
    end;

    function LastClickInTime: boolean;
    begin
      Result:=((now - LastMouse.TheTime) <= ((1/86400)*(QApplication_doubleClickInterval/1000)));
    end;

    function TestIfMultiClick: boolean;
    begin
      Result:= LastClickInSameWidget and
               LastClickAtSamePosition and
               LastClickInTime;
    end;

  var
    IsMultiClick: boolean;
  begin
    Result := LM_NULL;

    IsMultiClick := TestIfMultiClick;

    if QEvent_type(Event) = QEventMouseButtonDblClick then
    begin
      // the qt itself has detected a double click
      if (LastMouse.ClickCount >= 2) and IsMultiClick then
        // the double click was already detected and sent to the LCL
        // -> skip this message
        exit
      else
        LastMouse.ClickCount := 2;
    end
    else
    begin
      inc(LastMouse.ClickCount);

      if (LastMouse.ClickCount <= 4) and IsMultiClick then
      begin
        // multi click
      end else
      begin
        // normal click
        LastMouse.ClickCount:=1;
      end;
    end;

    LastMouse.TheTime := Now;
    LastMouse.MousePos := MousePos^;
    LastMouse.Widget := Sender;

    Result := MSGKIND[AButton][LastMouse.ClickCount];
  end;
begin
  {$ifdef VerboseQt}
    WriteLn('TQtWidget.SlotMouse');
  {$endif}

  // idea of multi click implementation is taken from gtk

  FillChar(Msg, SizeOf(Msg), #0);
  
  MousePos := QMouseEvent_pos(QMouseEventH(Event));
  OffsetMousePos(MousePos);

  Modifiers := QInputEvent_modifiers(QInputEventH(Event));
  Msg.Keys := QtKeyModifiersToKeyState(Modifiers);

  Msg.XPos := SmallInt(MousePos^.X);
  Msg.YPos := SmallInt(MousePos^.Y);
  
  MButton := QmouseEvent_Button(QMouseEventH(Event));

  case QEvent_type(Event) of
   QEventMouseButtonPress, QEventMouseButtonDblClick:
    begin
      Msg.Keys := Msg.Keys or QtButtonsToLCLButtons(MButton);
      case MButton of
        QtLeftButton: Msg.Msg := CheckMouseButtonDown(0);
        QtRightButton: Msg.Msg := CheckMouseButtonDown(1);
        QtMidButton: Msg.Msg := CheckMouseButtonDown(2);
      end;
      NotifyApplicationUserInput(Msg.Msg);
      DeliverMessage(Msg);
      Msg.Msg := LM_PRESSED;
      DeliverMessage(Msg);
    end;
   QEventMouseButtonRelease:
   begin
     LastMouse.Widget := Sender;
     LastMouse.MousePos := MousePos^;
     Msg.Keys := Msg.Keys or QtButtonsToLCLButtons(MButton);
     case MButton of
       QtLeftButton: Msg.Msg := LM_LBUTTONUP;
       QtRightButton: Msg.Msg := LM_RBUTTONUP;
       QtMidButton: Msg.Msg := LM_MBUTTONUP;
     end;
     NotifyApplicationUserInput(Msg.Msg);
     DeliverMessage(Msg);
     { Clicking on buttons operates differently, because QEventMouseButtonRelease
       is sent if you click a control, drag the mouse out of it and release, but
       buttons should not be clicked on this case. }
     if not (LCLObject is TCustomButton) then
     begin
       Msg.Msg := LM_CLICKED;
       DeliverMessage(Msg);
     end;

     Msg.Msg := LM_RELEASED;
   end;
  end;
  DeliverMessage(Msg);
end;

procedure TQtWidget.SlotMouseEnter(Event: QEventH); cdecl;
var
  Msg: TLMessage;
begin
  FillChar(Msg, SizeOf(Msg), #0);
  case QEvent_type(Event) of
    QEventEnter: Msg.Msg := CM_MOUSEENTER;
    QEventLeave: Msg.Msg := CM_MOUSELEAVE;
  end;
  DeliverMessage(Msg);
end;

function TQtWidget.QtButtonsToLCLButtons(AButtons: QTMouseButton): PtrInt;
begin
  Result := 0;
  if (QtLeftButton and AButtons) <> 0 then
    Result := Result or MK_LBUTTON;

  if (QtRightButton and AButtons) <> 0 then
    Result := Result or MK_RBUTTON;

  if (QtMidButton and AButtons) <> 0 then
    Result := Result or MK_MBUTTON;

  if (QtXButton1 and AButtons) <> 0 then
    Result := Result or MK_XBUTTON1;
    
  if (QtXButton2 and AButtons) <> 0 then
    Result := Result or MK_XBUTTON2;
end;

function TQtWidget.QtKeyModifiersToKeyState(AModifiers: QtKeyboardModifiers): PtrInt;
begin
  Result := 0;
  if AModifiers and qtShiftModifier <> 0 then
    Result := Result or MK_SHIFT;
  if AModifiers and qtControlModifier <> 0 then
    Result := Result or MK_CONTROL;
  { TODO: add support for ALT, META and NUMKEYPAD }
end;

{------------------------------------------------------------------------------
  Function: TQtWidget.SlotMouseMove
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtWidget.SlotMouseMove(Event: QEventH); cdecl;
var
  Msg: TLMMouseMove;
  MousePos: PQtPoint;
begin
  FillChar(Msg, SizeOf(Msg), #0);
  
  MousePos := QMouseEvent_pos(QMouseEventH(Event));
  OffsetMousePos(MousePos);

  Msg.XPos := SmallInt(MousePos^.X);
  Msg.YPos := SmallInt(MousePos^.Y);
  
  Msg.Keys := QtButtonsToLCLButtons(QmouseEvent_Buttons(QMouseEventH(Event)));

  Msg.Msg := LM_MOUSEMOVE;

  NotifyApplicationUserInput(Msg.Msg);
  DeliverMessage(Msg);
end;

{------------------------------------------------------------------------------
  Function: TQtWidget.SlotMouseWheel
  Params:  None
  Returns: Nothing

  Qt stores the delta in 1/8 of a degree
  Most mouses scroll 15 degrees each time
 
  Msg.WheelData: -1 for up, 1 for down
 ------------------------------------------------------------------------------}
procedure TQtWidget.SlotMouseWheel(Sender: QObjectH; Event: QEventH); cdecl;
var
  Msg: TLMMouseEvent;
  MousePos: PQtPoint;
begin
  FillChar(Msg, SizeOf(Msg), #0);

  MousePos := QWheelEvent_pos(QWheelEventH(Event));
  OffsetMousePos(MousePos);

  LastMouse.Widget := Sender;
  LastMouse.MousePos := MousePos^;
  
  Msg.Msg := LM_MOUSEWHEEL;

  Msg.X := SmallInt(MousePos^.X);
  Msg.Y := SmallInt(MousePos^.Y);

  Msg.WheelDelta := QWheelEvent_delta(QWheelEventH(Event)) div 120;
  
  NotifyApplicationUserInput(Msg.Msg);
  DeliverMessage(Msg);
end;

procedure TQtWidget.SlotMove(Event: QEventH); cdecl;
var
  Msg: TLMMove;
  Pos: PQtPoint;
  FrameRect, WindowRect: TRect;
begin
  {$ifdef VerboseQt}
    WriteLn('TQtWidget.SlotMove');
  {$endif}

  if not QEvent_spontaneous(Event) then
    Exit;

  FillChar(Msg, SizeOf(Msg), #0);

  Msg.Msg := LM_MOVE;

  Msg.MoveType := Msg.MoveType or Move_SourceIsInterface;

  Pos := QMoveEvent_pos(QMoveEventH(Event));
  FrameRect := getFrameGeometry;
  WindowRect := getGeometry;

  Msg.XPos := Pos^.x - (WindowRect.Left - FrameRect.Left);
  Msg.YPos := Pos^.y - (WindowRect.Top - FrameRect.Top);

  DeliverMessage(Msg);
end;

{------------------------------------------------------------------------------
  Function: TQtWidget.SlotPaint
  Params:  None
  Returns: Nothing

  Sends a LM_PAINT message to the LCL. This is for windowed controls only
 ------------------------------------------------------------------------------}
procedure TQtWidget.SlotPaint(Event: QEventH); cdecl;
var
  Msg: TLMPaint;
  AStruct: PPaintStruct;
begin
  {$ifdef VerboseQt}
    WriteLn('TQtWidget.SlotPaint');
  {$endif}
  if (LCLObject is TWinControl) then
  begin
    FillChar(Msg, SizeOf(Msg), #0);

    Msg.Msg := LM_PAINT;
    New(AStruct);
    FillChar(AStruct^, SizeOf(TPaintStruct), 0);
    Msg.PaintStruct := AStruct;

    with PaintData do
    begin
      ClipRegion := QPaintEvent_Region(QPaintEventH(Event));
      if ClipRect=nil then
        New(ClipRect);
      QPaintEvent_Rect(QPaintEventH(Event), ClipRect);
    end;


    Msg.DC := BeginPaint(THandle(Self), AStruct^);
    FContext := Msg.DC;
    
    Msg.PaintStruct^.rcPaint := PaintData.ClipRect^;
	  Msg.PaintStruct^.hdc := FContext;


    with getClientBounds do
      SetWindowOrgEx(Msg.DC, -Left, -Top, nil);

    // send paint message
    try
      // Saving clip rect and clip region
      try
        LCLObject.WindowProc(TLMessage(Msg));
        if HasCaret then
          QtCaret.DrawCaret;
      finally
        Dispose(PaintData.ClipRect);
        Fillchar(FPaintData, SizeOf(FPaintData), 0);
        FContext := 0;
        EndPaint(THandle(Self), AStruct^);
        Dispose(AStruct);
      end;
    except
      Application.HandleException(nil);
    end;
  end;
end;

{------------------------------------------------------------------------------
  Function: TQtWidget.SlotResize
  Params:  None
  Returns: Nothing

  Sends a LM_SIZE message to the LCL.
 ------------------------------------------------------------------------------}
procedure TQtWidget.SlotResize; cdecl;
var
  Msg: TLMSize;
begin
  {$ifdef VerboseQt}
    WriteLn('TQtWidget.SlotResize');
  {$endif}

  FillChar(Msg, SizeOf(Msg), #0);

  Msg.Msg := LM_SIZE;

  case QWidget_windowState(Widget) of
    QtWindowMinimized: Msg.SizeType := SIZEICONIC;
    QtWindowMaximized: Msg.SizeType := SIZEFULLSCREEN;
    QtWindowFullScreen: Msg.SizeType := SIZEFULLSCREEN;
  else
    Msg.SizeType := SIZENORMAL;
  end;

  Msg.SizeType := Msg.SizeType or Size_SourceIsInterface;

  Msg.Width := QWidget_width(Widget);
  Msg.Height := QWidget_height(Widget);

  DeliverMessage(Msg);
end;

procedure TQtWidget.SlotContextMenu; cdecl;
begin
  if Assigned(LCLObject.PopupMenu) then
   LCLObject.PopupMenu.PopUp(Mouse.CursorPos.X, Mouse.CursorPos.Y);
end;

procedure TQtWidget.Activate;
begin
  QWidget_activateWindow(Widget);
end;

procedure TQtWidget.BringToFront;
begin
  Activate;
  QWidget_raise(Widget);
end;

procedure TQtWidget.OffsetMousePos(APoint: PQtPoint);
begin
  with getClientBounds do
  begin
    dec(APoint.x, Left);
    dec(APoint.y, Top);
  end;
end;

{------------------------------------------------------------------------------
  Function: TQtWidget.SetColor
  Params:  QColorH
  Returns: Nothing

  Changes the color of a widget
 ------------------------------------------------------------------------------}
procedure TQtWidget.SetColor(const Value: PQColor);
var
  Palette: QPaletteH;
begin
  Palette := QPalette_create(QWidget_palette(Widget));
  try
    QPalette_setColor(Palette, QPaletteWindow, Value);
    QWidget_setPalette(Widget, Palette);
  finally
    QPalette_destroy(Palette);
  end;
end;

{------------------------------------------------------------------------------
  Function: TQtWidget.SetTextColor
  Params:  QColorH
  Returns: Nothing

  Changes the text color of a widget
 ------------------------------------------------------------------------------}
procedure TQtWidget.SetTextColor(const Value: PQColor);
var
  Palette: QPaletteH;
begin
  Palette := QPalette_create(QWidget_palette(Widget));
  try
    QPalette_setColor(Palette, QPaletteText, Value);
    QWidget_setPalette(Widget, Palette);
  finally
    QPalette_destroy(Palette);
  end;
end;

procedure TQtWidget.SetCursor(const ACursor: QCursorH);
begin
  if ACursor <> nil then
    QWidget_setCursor(Widget, ACursor)
  else
    QWidget_setCursor(Widget, FDefaultCursor);
end;

{------------------------------------------------------------------------------
  Function: TQtWidget.Update
  Params:  None
  Returns: Nothing

  Schedules a paint event for processing when Qt returns to the main event loop
 ------------------------------------------------------------------------------}
procedure TQtWidget.Update(ARect: PRect = nil);
begin
  if ARect <> nil then
    QWidget_update(Widget, ARect)
  else
    QWidget_update(Widget);
end;

{------------------------------------------------------------------------------
  Function: TQtWidget.Repaint
  Params:  None
  Returns: Nothing

  Repaints the control imediately
 ------------------------------------------------------------------------------}
procedure TQtWidget.Repaint(ARect: PRect = nil);
begin
  if ARect <> nil then
    QWidget_repaint(Widget, ARect)
  else
    QWidget_repaint(Widget);
end;

procedure TQtWidget.setWindowTitle(Str: PWideString);
begin
  QWidget_setWindowTitle(Widget, Str);
end;

procedure TQtWidget.WindowTitle(Str: PWideString);
begin
  QWidget_WindowTitle(Widget, Str);
end;

procedure TQtWidget.Hide;
begin
  QWidget_hide(Widget);
end;

procedure TQtWidget.Show;
begin
  QWidget_show(Widget);
end;

procedure TQtWidget.ShowNormal;
begin
  QWidget_showNormal(Widget);
end;

procedure TQtWidget.ShowMinimized;
begin
  QWidget_showMinimized(Widget);
end;

procedure TQtWidget.ShowMaximized;
begin
  QWidget_showMaximized(Widget);
end;

function TQtWidget.getEnabled: Boolean;
begin
  Result := QWidget_isEnabled(Widget);
end;

function TQtWidget.getFrameGeometry: TRect;
begin
  QWidget_frameGeometry(Widget, @Result);
end;

function TQtWidget.getGeometry: TRect;
begin
  QWidget_geometry(Widget, @Result);
end;

function TQtWidget.getVisible: boolean;
begin
  Result := QWidget_isVisible(Widget);
end;

function TQtWidget.getClientBounds: TRect;
begin
  QWidget_contentsRect(Widget, @Result);
end;

procedure TQtWidget.grabMouse;
begin
  QWidget_grabMouse(Widget);
end;

function TQtWidget.hasFocus: Boolean;
begin
  Result := QWidget_hasFocus(Widget);
end;

procedure TQtWidget.move(ANewLeft, ANewTop: Integer);
begin
  QWidget_move(Widget, ANewLeft, ANewTop);
end;

procedure TQtWidget.resize(ANewWidth, ANewHeight: Integer);
begin
  QWidget_resize(Widget, ANewWidth, ANewHeight);
end;

procedure TQtWidget.releaseMouse;
var
  AGrabWidget: QWidgetH;
begin
  // capture widget can be one of childs of Widget if Widget is complex control
  // so better to look for current Capture widget to release it instead of pass Widget as argument
  AGrabWidget := QWidget_mouseGrabber();
  QWidget_releaseMouse(AGrabWidget);
end;

procedure TQtWidget.setEnabled(p1: Boolean);
begin
  QWidget_setEnabled(Widget, p1);
end;

procedure TQtWidget.setGeometry(ARect: TRect);
begin
  QWidget_setGeometry(Widget, @ARect);
end;

procedure TQtWidget.setMaximumSize(AWidth, AHeight: Integer);
begin
  QWidget_setMaximumSize(Widget, AWidth, AHeight);
end;

procedure TQtWidget.setMinimumSize(AWidth, AHeight: Integer);
begin
  QWidget_setMinimumSize(Widget, AWidth, AHeight);
end;

procedure TQtWidget.setVisible(visible: Boolean);
begin
  QWidget_setVisible(Widget, visible);
end;

function TQtWidget.windowModality: QtWindowModality;
begin
  Result := QWidget_windowModality(Widget);
end;

procedure TQtWidget.setWindowModality(windowModality: QtWindowModality);
begin
  QWidget_setWindowModality(Widget, windowModality);
end;

procedure TQtWidget.setParent(parent: QWidgetH);
begin
  QWidget_setParent(Widget, parent);
end;

procedure TQtWidget.setWindowFlags(_type: QtWindowFlags);
begin
  QWidget_setWindowFlags(Widget, _type);
end;

procedure TQtWidget.setWindowIcon(AIcon: QIconH);
begin
  QWidget_setWindowIcon(Widget, AIcon);
end;

function TQtWidget.windowFlags: QtWindowFlags;
begin
  Result := QWidget_windowFlags(Widget);
end;

procedure TQtWidget.setWidth(p1: Integer);
var
  R: TRect;
begin
  R := getGeometry;
  R.Right := R.Left + p1;
  setGeometry(R);
end;

procedure TQtWidget.setHeight(p1: Integer);
var
  R: TRect;
begin
  R := getGeometry;
  R.Bottom := R.Top + p1;
  setGeometry(R);
end;

procedure TQtWidget.setTabOrder(p1, p2: TQtWidget);
begin
  QWidget_setTabOrder(p1.Widget, p2.Widget);
end;

procedure TQtWidget.setWindowState(AState: QtWindowStates);
begin
  QWidget_setWindowState(Widget, AState);
end;

{------------------------------------------------------------------------------
  Function: TQtWidget.QtKeyToLCLKey
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
function TQtWidget.QtKeyToLCLKey(AKey: Integer): Word;
begin
  case AKey of
    QtKey_0..QtKey_9: Result := VK_0 + (AKey - QtKey_0);
    QtKey_At: Result := VK_2; // some bug, but Ctrl + Shit + 2 produce QtKey_At
    QtKey_Escape: Result := VK_ESCAPE;
    QtKey_Tab: Result := VK_TAB;
    QtKey_Backtab: Result := VK_UNKNOWN; // ???
    QtKey_Backspace: Result := VK_BACK;
    QtKey_Return: Result := VK_RETURN;
    QtKey_Enter: Result := VK_RETURN;
    QtKey_Insert: Result := VK_INSERT;
    QtKey_Delete: Result := VK_DELETE;
    QtKey_Pause: Result := VK_PAUSE;
    QtKey_Print: Result := VK_PRINT;
    QtKey_SysReq: Result := VK_UNKNOWN; // ???
    QtKey_Clear: Result := VK_CLEAR;
    QtKey_Home: Result := VK_HOME;
    QtKey_End: Result := VK_END;
    QtKey_Left: Result := VK_LEFT;
    QtKey_Up: Result := VK_UP;
    QtKey_Right: Result := VK_RIGHT;
    QtKey_Down: Result := VK_DOWN;
    QtKey_PageUp: Result := VK_PRIOR;
    QtKey_PageDown: Result := VK_NEXT;
    QtKey_Shift: Result := VK_SHIFT;     // There is also RSHIFT
    QtKey_Control: Result := VK_CONTROL; // There is also RCONTROL
    QtKey_Meta: Result := VK_UNKNOWN; // ???
    QtKey_Alt: Result := VK_MENU;
    QtKey_CapsLock: Result := VK_CAPITAL;
    QtKey_NumLock: Result := VK_NUMLOCK;
    QtKey_ScrollLock: Result := VK_SCROLL;
    QtKey_F1..QtKey_F24: Result := VK_F1 + (AKey - QtKey_F1);
    QtKey_F25..
    QtKey_F35,
    QtKey_Super_L,
    QtKey_Super_R: Result := VK_UNKNOWN;
    QtKey_Menu: Result := VK_MENU;
    QtKey_Hyper_L,
    QtKey_Hyper_R: Result := VK_UNKNOWN;
    QtKey_Help: Result := VK_HELP;
    QtKey_Direction_L,
    QtKey_Direction_R,
    QtKey_Exclam..
    QtKey_ParenRight: Result := VK_UNKNOWN;
    QtKey_Asterisk: Result := VK_MULTIPLY;
    QtKey_Plus: Result := VK_ADD;
    QtKey_Comma: Result := VK_SEPARATOR;
    QtKey_Minus: Result := VK_SUBTRACT;
    QtKey_Period: Result := VK_DECIMAL;
    QtKey_Slash: Result := VK_DIVIDE;
    QtKey_BracketLeft..
    QtKey_ydiaeresis,
    QtKey_Multi_key..
    QtKey_No: Result := VK_UNKNOWN;
    QtKey_Cancel: Result := VK_CANCEL;
    QtKey_Printer: Result := VK_PRINT;
    QtKey_Execute: Result := VK_EXECUTE;
    QtKey_Sleep: Result := VK_SLEEP;
    QtKey_Play: Result := VK_PLAY;
    QtKey_Zoom: Result := VK_ZOOM;
    QtKey_Context1..
    QtKey_Flip,
    QtKey_unknown: Result := VK_UNKNOWN;
  else
    Result := AKey; // Qt:AKey = VK_KEY in many cases
  end;
end;

function TQtWidget.LCLKeyToQtKey(AKey: Word): Integer;
const
  VKKeyToQtKeyMap: array[0..255] of Integer = // Keyboard mapping table
   (
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_Cancel,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_Backspace,
    QtKey_Tab,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_Clear,
    QtKey_Return,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_Shift,
    QtKey_Control,
    QtKey_Alt,
    QtKey_Pause,
    QtKey_CapsLock,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_Escape,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_Mode_switch,
    QtKey_Space,
    QtKey_PageUp,
    QtKey_PageDown,
    QtKey_End,
    QtKey_Home,
    QtKey_Left,
    QtKey_Up,
    QtKey_Right,
    QtKey_Down,
    QtKey_Select,
    QtKey_Printer,
    QtKey_Execute,
    QtKey_Print,
    QtKey_Insert,
    QtKey_Delete,
    QtKey_Help,
    QtKey_0,
    QtKey_1,
    QtKey_2,
    QtKey_3,
    QtKey_4,
    QtKey_5,
    QtKey_6,
    QtKey_7,
    QtKey_8,
    QtKey_9,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_A,
    QtKey_B,
    QtKey_C,
    QtKey_D,
    QtKey_E,
    QtKey_F,
    QtKey_G,
    QtKey_H,
    QtKey_I,
    QtKey_J,
    QtKey_K,
    QtKey_L,
    QtKey_M,
    QtKey_N,
    QtKey_O,
    QtKey_P,
    QtKey_Q,
    QtKey_R,
    QtKey_S,
    QtKey_T,
    QtKey_U,
    QtKey_V,
    QtKey_W,
    QtKey_X,
    QtKey_Y,
    QtKey_Z,
    QtKey_Meta,
    QtKey_Meta,
    QtKey_Menu,
    QtKey_unknown,
    QtKey_Sleep,
    QtKey_0,
    QtKey_1,
    QtKey_2,
    QtKey_3,
    QtKey_4,
    QtKey_5,
    QtKey_6,
    QtKey_7,
    QtKey_8,
    QtKey_9,
    QtKey_Asterisk,
    QtKey_Plus,
    QtKey_Comma,
    QtKey_Minus,
    QtKey_Period,
    QtKey_Slash,
    QtKey_F1,
    QtKey_F2,
    QtKey_F3,
    QtKey_F4,
    QtKey_F5,
    QtKey_F6,
    QtKey_F7,
    QtKey_F8,
    QtKey_F9,
    QtKey_F10,
    QtKey_F11,
    QtKey_F12,
    QtKey_F13,
    QtKey_F14,
    QtKey_F15,
    QtKey_F16,
    QtKey_F17,
    QtKey_F18,
    QtKey_F19,
    QtKey_F20,
    QtKey_F21,
    QtKey_F22,
    QtKey_F23,
    QtKey_F24,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_NumLock,
    QtKey_ScrollLock,
    QtKey_unknown,
    QtKey_Massyo,
    QtKey_Touroku,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_Shift,
    QtKey_Shift,
    QtKey_Control,
    QtKey_Control,
    QtKey_Alt,
    QtKey_Alt,
    QtKey_Back,
    QtKey_Forward,
    QtKey_Refresh,
    QtKey_Stop,
    QtKey_Search,
    QtKey_Favorites,
    QtKey_HomePage,
    QtKey_VolumeMute,
    QtKey_VolumeDown,
    QtKey_VolumeUp,
    QtKey_MediaNext,
    QtKey_MediaPrevious,
    QtKey_MediaStop,
    QtKey_MediaPlay,
    QtKey_LaunchMail,
    QtKey_LaunchMedia,
    QtKey_Launch0,
    QtKey_Launch1,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_Plus,
    QtKey_Comma,
    QtKey_Minus,
    QtKey_Period,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_Play,
    QtKey_Zoom,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_Clear,
    QtKey_unknown
   );
begin
  if AKey > 255 then
    Result := QtKey_unknown
  else
    Result := VKKeyToQtKeyMap[AKey];
end;

function TQtWidget.ShiftStateToQtModifiers(Shift: TShiftState): QtModifier;
begin
  Result := 0;
  if ssCtrl  in Shift then inc(Result, QtCTRL);
  if ssShift in Shift then Inc(Result, QtSHIFT);
  if ssMeta  in Shift then Inc(Result, QtMETA);
  if ssAlt   in Shift then Inc(Result, QtALT);
end;

function TQtWidget.GetProps(const AnIndex: String): pointer;
var
  i: Integer;
begin
  if (Fprops<>nil) then
  begin
    i:=Fprops.IndexOf(AnIndex);
    if i>=0 then
    begin
      result:=Fprops.Objects[i];
      exit;
    end;
  end;
  result := nil;
end;

function TQtWidget.GetWidget: QWidgetH;
begin
  Result := QWidgetH(TheObject);
end;

function TQtWidget.DeliverMessage(var Msg): LRESULT;
begin
  try
    if LCLObject.HandleAllocated then
    begin
      LCLObject.WindowProc(TLMessage(Msg));
      Result := TLMessage(Msg).Result;
    end else
      Result := 0;
  except
    Application.HandleException(nil);
  end;
end;

procedure TQtWidget.SetProps(const AnIndex: String; const AValue: pointer);
var
  i: Integer;
begin
  if FProps=nil then
  begin
    FProps:=TStringList.Create;
    //FProps.CaseSensitive:=false;
    FProps.Sorted:=true;
  end;
  i := Fprops.IndexOf(AnIndex);
  if i < 0 then
    i := FProps.Add(AnIndex);
  Fprops.Objects[i] := TObject(AValue);
end;

procedure TQtWidget.SetWidget(const AValue: QWidgetH);
begin
  TheObject := AValue;
end;

function TQtWidget.CreateWidget(const Params: TCreateParams): QWidgetH;
var
  Parent: QWidgetH;
begin
  Parent := TQtWidget(LCLObject.Parent.Handle).Widget;
  Widget := QWidget_create(Parent);
  Result := Widget;
end;

procedure TQtWidget.SetGeometry;
begin
  setGeometry(LCLObject.BoundsRect);
end;

{ TQtAbstractButton }

{------------------------------------------------------------------------------
  Function: TQtAbstractButton.SetColor
  Params:  QColorH
  Returns: Nothing

  Changes the color of a widget
 ------------------------------------------------------------------------------}
procedure TQtAbstractButton.SetColor(const Value: PQColor);
var
  Palette: QPaletteH;
begin
  Palette := QPalette_create(QWidget_palette(Widget));
  try
    QPalette_setColor(Palette, QPaletteButton, Value);
    QWidget_setPalette(Widget, Palette);
  finally
    QPalette_destroy(Palette);
  end;
end;

procedure TQtAbstractButton.setIcon(AIcon: QIconH);
begin
  QAbstractButton_setIcon(QAbstractButtonH(Widget), AIcon);
end;

procedure TQtAbstractButton.setShortcut(AShortcut: TShortcut);
var
  Key: Word;
  Shift: TShiftState;
  Modifiers: QtModifier;
  KeySequence: QKeySequenceH;
begin
  if AShortCut <> 0 then
  begin
    ShortCutToKey(AShortCut, Key, Shift);
    Modifiers := ShiftStateToQtModifiers(Shift);
    KeySequence := QKeySequence_create(LCLKeyToQtKey(Key) or Modifiers);
  end
  else
    KeySequence := QKeySequence_create();
  QAbstractButton_setShortcut(QAbstractButtonH(Widget), KeySequence);
  QKeySequence_destroy(KeySequence);
end;

{------------------------------------------------------------------------------
  Function: TQtAbstractButton.SetText
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtAbstractButton.SetText(text: PWideString);
begin
  QAbstractButton_setText(QAbstractButtonH(Widget), text);
end;

{------------------------------------------------------------------------------
  Function: TQtAbstractButton.Text
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtAbstractButton.Text(retval: PWideString);
begin
  QAbstractButton_text(QAbstractButtonH(Widget), retval);
end;

procedure TQtAbstractButton.Toggle;
begin
  QAbstractButton_toggle(QAbstractButtonH(Widget));
end;

{------------------------------------------------------------------------------
  Function: TQtAbstractButton.isChecked
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
function TQtAbstractButton.isChecked: Boolean;
begin
  Result := QAbstractButton_isChecked(QAbstractButtonH(Widget));
end;

function TQtAbstractButton.isDown: Boolean;
begin
  Result := QAbstractButton_isDown(QAbstractButtonH(Widget));
end;

{------------------------------------------------------------------------------
  Function: TQtAbstractButton.setChecked
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtAbstractButton.setChecked(p1: Boolean);
begin
  QAbstractButton_setChecked(QAbstractButtonH(Widget), p1);
end;

procedure TQtAbstractButton.setDown(p1: Boolean);
begin
  QAbstractButton_setDown(QAbstractButtonH(Widget), p1);
end;

{------------------------------------------------------------------------------
  Function: TQtAbstractButton.SignalPressed
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtAbstractButton.SignalPressed; cdecl;
var
  Msg: TLMessage;
begin
  FillChar(Msg, SizeOf(Msg), #0);
  Msg.Msg := LM_KEYDOWN;
  DeliverMessage(Msg);
end;

{------------------------------------------------------------------------------
  Function: TQtAbstractButton.SignalReleased
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtAbstractButton.SignalReleased; cdecl;
var
  Msg: TLMessage;
begin
  FillChar(Msg, SizeOf(Msg), #0);
  Msg.Msg := LM_KEYUP;
  DeliverMessage(Msg);
end;

{------------------------------------------------------------------------------
  Function: TQtAbstractButton.SignalClicked
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtAbstractButton.SignalClicked(Checked: Boolean = False); cdecl;
var
  Msg: TLMessage;
begin
  FillChar(Msg, SizeOf(Msg), #0);
  Msg.Msg := LM_CHANGED;
  DeliverMessage(Msg);
end;

{------------------------------------------------------------------------------
  Function: TQtAbstractButton.SignalClicked2
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtAbstractButton.SignalClicked2; cdecl;
var
  Msg: TLMessage;
begin
  FillChar(Msg, SizeOf(Msg), #0);
  Msg.Msg := LM_CLICKED;
  DeliverMessage(Msg);
end;

{------------------------------------------------------------------------------
  Function: TQtAbstractButton.SignalToggled
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtAbstractButton.SignalToggled(Checked: Boolean); cdecl;
begin
 {use this for TToggleButton }
end;


{ TQtPushButton }

function TQtPushButton.CreateWidget(const AParams: TCreateParams): QWidgetH;
var
  Str: WideString;
  Parent: QWidgetH;
begin
  // Creates the widget
  {$ifdef VerboseQt}
    WriteLn('TQtPushButton.Create Left:', dbgs(LCLObject.Left), ' Top:', dbgs(LCLObject.Top));
  {$endif}

  Str := UTF8Decode(LCLObject.Caption);
  Parent := TQtWidget(LCLObject.Parent.Handle).GetContainerWidget;
  Result := QPushButton_create(@Str, Parent);
end;

{------------------------------------------------------------------------------
  Function: TQtPushButton.Destroy
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
destructor TQtPushButton.Destroy;
begin
  {$ifdef VerboseQt}
    WriteLn('TQtPushButton.Destroy');
  {$endif}

  if Widget <> nil then
  begin
    DetachEvents;
    QPushButton_destroy(QPushButtonH(Widget));
    Widget := nil;
  end;

  inherited Destroy;
end;

procedure TQtPushButton.AttachEvents;
var
  Method: TMethod;
begin
  inherited AttachEvents;
  
  FClickedHook := QAbstractButton_hook_create(Widget);
  QAbstractButton_clicked2_Event(Method) := SlotClicked;
  QAbstractButton_hook_hook_clicked2(FClickedHook, Method);
end;

procedure TQtPushButton.DetachEvents;
begin
  QAbstractButton_hook_destroy(FClickedHook);
  inherited DetachEvents;
end;

{------------------------------------------------------------------------------
  Function: TQtPushButton.SlotClicked
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtPushButton.SlotClicked; cdecl;
var
  Msg: TLMessage;
begin
  Msg.Msg := LM_CLICKED;

  try
    LCLObject.WindowProc(TLMessage(Msg));
  except
    Application.HandleException(nil);
  end;
end;

{ TQtMainWindow }

function TQtMainWindow.CreateWidget(const AParams: TCreateParams): QWidgetH;
var
  w: QWidgetH;
begin
  // Creates the widget
  {$ifdef VerboseQt}
    WriteLn('TQtMainWindow.CreateWidget Name: ', LCLObject.Name);
  {$endif}
  

  IsMainForm := False;

  
  w := QApplication_activeWindow;

  if not Assigned(w) and not ((Application.MainForm <> nil) and (Application.MainForm.Visible)) then
  begin
  
    IsMainForm := True;

    Result := QMainWindow_create(nil, QtWindow);
    
    MenuBar := TQtMenuBar.Create(Result);
    
    {$ifdef USE_QT_4_3}
      if (Application.MainForm <> nil) and (Application.MainForm.FormStyle = fsMDIForm)
      and not (csDesigning in LCLObject.ComponentState) then
      begin
        MDIAreaHandle := QMdiArea_create(Result);
        FCentralWidget := MDIAreaHandle;
        QMainWindow_setCentralWidget(QMainWindowH(Result), MDIAreaHandle);
      end
      else
      begin
        FCentralWidget := QWidget_create(Result);
        MDIAreaHandle := nil;
      end;
      
      if FCentralWidget <> nil then
        QMainWindow_setCentralWidget(QMainWindowH(Result), FCentralWidget);
      
      if not (csDesigning in LCLObject.ComponentState) then
        QMainWindow_setDockOptions(QMainWindowH(Result), QMainWindowAnimatedDocks);
    {$else}
      FCentralWidget := QWidget_create(Result);

      QMainWindow_setCentralWidget(QMainWindowH(Result), FCentralWidget);
    {$endif}
  end
  else
  begin
    {$ifdef USE_QT_4_3}
      if (LCLObject is TCustomForm) and (TCustomForm(LCLObject).FormStyle = fsMDIChild) and
          not (csDesigning in LCLObject.ComponentState) then
      begin

        if TQtMainWindow(Application.MainForm.Handle).MDIAreaHandle = nil then
          raise Exception.Create('MDIChild can be added to MDIForm only !');

        Result := QMdiSubWindow_create(nil, QtWindow);

        // QMdiSubWindow already have an layout

        LayoutWidget := QBoxLayoutH(QWidget_layout(Result));
        if LayoutWidget <> nil then
          QBoxLayout_destroy(LayoutWidget);
      end
      else
      begin
        Result := QWidget_create(nil, QtWindow);
        QWidget_setAttribute(Result, QtWA_Hover);
      end;
    {$else}
      Result := QWidget_create(nil, QtWindow);
    {$endif}
    
    // Main menu bar
    MenuBar := TQtMenuBar.Create(Result);

    FCentralWidget := QWidget_create(Result);
    LayoutWidget := QBoxLayout_create(QBoxLayoutTopToBottom, Result);

    {$ifdef USE_QT_4_3}
      QBoxLayout_setSpacing(LayoutWidget, 0);
      QLayout_setContentsMargins(LayoutWidget, 0, 0, 0, 0);
    {$else}
      QLayout_setSpacing(LayoutWidget, 0);
      QLayout_setMargin(LayoutWidget, 0);
    {$endif}
    
    QLayout_addWidget(LayoutWidget, FCentralWidget);
    QWidget_setLayout(Result, QLayoutH(LayoutWidget));
  end;
  QWidget_setAttribute(Result, QtWA_NoMousePropagation);
end;

{------------------------------------------------------------------------------
  Function: TQtMainWindow.Destroy
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
destructor TQtMainWindow.Destroy;
begin
  {$ifdef VerboseQt}
    WriteLn('TQtMainWindow.Destroy');
  {$endif}

  if Widget <> nil then
  begin
    DetachEvents;
    QWidget_destroy(Widget);
    Widget := nil;
  end;

  { The main window takes care of the menubar handle}
  
  if MenuBar <> nil then
  begin
    MenuBar.Widget := nil;
    MenuBar.Free;
  end;

  inherited Destroy;
end;

function TQtMainWindow.getClientBounds: TRect;
var
  R: TRect;
begin
  Result := inherited getClientBounds;
  if (MenuBar <> nil) and (MenuBar.getVisible) then
  begin
    R := MenuBar.getGeometry;
    if TCustomForm(LCLObject).FormStyle <> fsMDIChild then
      inc(Result.Top, R.Bottom - R.Top);
  end;
end;

{------------------------------------------------------------------------------
  Function: TQtMainWindow.setTabOrders
  Params:  None
  Returns: Nothing
  
  Sets the tab order of all controls on a form.
 ------------------------------------------------------------------------------}
procedure TQtMainWindow.setTabOrders;
var
 i: Integer;
 Form: TForm;
 List: TFPList;
begin
  Form := TForm(LCLObject);

  List := TFPList.Create;
  Form.GetTabOrderList(List);

  for i := 0 to List.Count - 2 do
  begin
    setTabOrder(TQtWidget(TWinControl(List.Items[i]).Handle),
     TQtWidget(TWinControl(List.Items[i + 1]).Handle));

   {$ifdef VerboseQt}
     WriteLn('Setting Tab Order first: ', TWinControl(List.Items[i]).Name, ' second: ',
      TWinControl(List.Items[i + 1]).Name);
   {$endif}
  end;

 { The last element points to the first }
  if List.Count > 1 then
  begin
    setTabOrder(TQtWidget(TWinControl(List.Items[List.Count - 1]).Handle),
     TQtWidget(TWinControl(List.Items[0]).Handle));

   {$ifdef VerboseQt}
     WriteLn('Setting Tab Order first: ', TWinControl(List.Items[List.Count - 1]).Name, ' second: ',
      TWinControl(List.Items[0]).Name);
   {$endif}
  end;

  List.Free;
end;

procedure TQtMainWindow.setMenuBar(AMenuBar: QMenuBarH);
begin
  if IsMainForm then
    QMainWindow_setMenuBar(QMainWindowH(Widget), AMenuBar)
  else
    QLayout_setMenuBar(LayoutWidget, AMenuBar);
end;

{------------------------------------------------------------------------------
  Function: TQtMainWindow.EventFilter
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
function TQtMainWindow.EventFilter(Sender: QObjectH; Event: QEventH): Boolean;
  cdecl;
begin
  BeginEventProcessing;
  Result := False;

  case QEvent_type(Event) of
    QEventWindowStateChange: SlotWindowStateChange;
  else
    inherited EventFilter(Sender, Event);
  end;
  EndEventProcessing;
end;

procedure TQtMainWindow.OffsetMousePos(APoint: PQtPoint);
begin
  if TCustomForm(LCLObject).FormStyle <> fsMdiChild then
    inherited OffsetMousePos(APoint);
end;

{------------------------------------------------------------------------------
  Function: TQtMainWindow.SlotWindowStateChange
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtMainWindow.SlotWindowStateChange; cdecl;
var
  Msg: TLMSize;
begin
  {$ifdef VerboseQt}
    WriteLn('TQtMainWindow.SlotWindowStateChange');
  {$endif}

  FillChar(Msg, SizeOf(Msg), #0);

  Msg.Msg := LM_SIZE;

  case QWidget_windowState(Widget) of
    QtWindowMinimized: Msg.SizeType := SIZEICONIC;
    QtWindowMaximized: Msg.SizeType := SIZEFULLSCREEN;
    QtWindowFullScreen: Msg.SizeType := SIZEFULLSCREEN;
  else
    Msg.SizeType := SIZENORMAL;
  end;

  Msg.SizeType := Msg.SizeType or Size_SourceIsInterface;

  Msg.Width := QWidget_width(Widget);
  Msg.Height := QWidget_height(Widget);

  try
    LCLObject.WindowProc(TLMessage(Msg));
  except
    Application.HandleException(nil);
  end;
end;

procedure TQtMainWindow.setShowInTaskBar(AValue: Boolean);
var
  w: QWidgetH;
  Flags: QtWindowFlags;
  Visible: Boolean;
begin
  if not AValue then
  begin
    w := TQtMainWindow(Application.MainForm.Handle).Widget;
    if w <> Widget then
    begin
      Visible := getVisible;
      Flags := windowFlags;
      setParent(w);
      setWindowFlags(Flags);
      setVisible(Visible);
    end;
  end
  else
  begin
    Visible := getVisible;
    Flags := windowFlags;
    setParent(nil);
    setWindowFlags(Flags);
    setVisible(Visible);
  end;
end;

{ TQtStaticText }

function TQtStaticText.CreateWidget(const AParams: TCreateParams): QWidgetH;
var
  Parent: QWidgetH;
begin
  // Creates the widget
  {$ifdef VerboseQt}
    WriteLn('TQtStaticText.Create');
  {$endif}

  Result := QLabel_create();
  QWidget_setAutoFillBackground(Result, True);
end;

{------------------------------------------------------------------------------
  Function: TQtStaticText.Destroy
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
destructor TQtStaticText.Destroy;
begin
  {$ifdef VerboseQt}
    WriteLn('TQtStaticText.Destroy');
  {$endif}

  if Widget <> nil then
  begin
    DetachEvents;
    QLabel_destroy(QLabelH(Widget));
    Widget := nil;
  end;

  inherited Destroy;
end;

{------------------------------------------------------------------------------
  Function: TQtStaticText.SetText
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtStaticText.SetText(text: PWideString);
begin
  QLabel_setText(QLabelH(Widget), text);
end;

procedure TQtStaticText.setAlignment(const AAlignment: QtAlignment);
begin
  QLabel_setAlignment(QLabelH(Widget), AAlignment);
end;

{------------------------------------------------------------------------------
  Function: TQtStaticText.Text
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtStaticText.getText(retval: PWideString);
begin
  QLabel_text(QLabelH(Widget), retval);
end;

{ TQtCheckBox }

function TQtCheckBox.CreateWidget(const AParams: TCreateParams): QWidgetH;
begin
  // Creates the widget
  {$ifdef VerboseQt}
    WriteLn('TQtCheckBox.Create');
  {$endif}
  
  Result := QCheckBox_create;
end;

{------------------------------------------------------------------------------
  Function: TQtCheckBox.Destroy
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
destructor TQtCheckBox.Destroy;
begin
  {$ifdef VerboseQt}
    WriteLn('TQtCheckBox.Destroy');
  {$endif}

  if Widget <> nil then
  begin
    DetachEvents;
    QCheckBox_destroy(QCheckBoxH(Widget));
    Widget := nil;
  end;

  inherited Destroy;
end;

{------------------------------------------------------------------------------
  Function: TQtCheckBox.CheckState
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
function TQtCheckBox.CheckState: QtCheckState;
begin
  Result := QCheckBox_checkState(QCheckBoxH(Widget));
end;

{------------------------------------------------------------------------------
  Function: TQtCheckBox.setCheckState
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtCheckBox.setCheckState(state: QtCheckState);
begin
  QCheckBox_setCheckState(QCheckBoxH(Widget), state);
end;

procedure TQtCheckBox.AttachEvents;
var
  Method: TMethod;
begin
  inherited AttachEvents;
  FStateChangedHook := QCheckBox_hook_create(Widget);
  QCheckBox_stateChanged_Event(Method) := SignalStateChanged;
  QCheckBox_hook_hook_stateChanged(FStateChangedHook, Method);
end;

procedure TQtCheckBox.DetachEvents;
begin
  QCheckBox_hook_destroy(FStateChangedHook);
  inherited DetachEvents;
end;

{------------------------------------------------------------------------------
  Function: TQtCheckBox.signalStateChanged
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtCheckBox.signalStateChanged(p1: Integer); cdecl;
var
  Msg: TLMessage;
begin
  FillChar(Msg, SizeOf(Msg), #0);
  Msg.Msg := LM_CHANGED;
  DeliverMessage(Msg);
end;

{ TQtRadioButton }

function TQtRadioButton.CreateWidget(const AParams: TCreateParams): QWidgetH;
begin
  // Creates the widget
  {$ifdef VerboseQt}
    WriteLn('TQtRadioButton.Create');
  {$endif}

  Result := QRadioButton_create();
  // hide widget by default
  QWidget_hide(Result);
end;

{------------------------------------------------------------------------------
  Function: TQtRadioButton.Destroy
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
destructor TQtRadioButton.Destroy;
begin
  {$ifdef VerboseQt}
    WriteLn('TQtRadioButton.Destroy');
  {$endif}

  if Widget <> nil then
  begin
    DetachEvents;
    QRadioButton_destroy(QRadioButtonH(Widget));
    Widget := nil;
  end;

  inherited Destroy;
end;

procedure TQtRadioButton.AttachEvents;
var
  Method: TMethod;
begin
  inherited AttachEvents;
  FClickedHook := QAbstractButton_hook_create(Widget);
  
  QAbstractButton_clicked_Event(Method) := SignalClicked;
  QAbstractButton_hook_hook_clicked(FClickedHook, Method);
end;

procedure TQtRadioButton.DetachEvents;
begin
  QAbstractButton_hook_destroy(FClickedHook);
  inherited DetachEvents;
end;

{ TQtGroupBox }

function TQtGroupBox.CreateWidget(const AParams: TCreateParams): QWidgetH;
var
  Parent: QWidgetH;
  Layout: QBoxLayoutH;
begin
  // Creates the widget
  {$ifdef VerboseQt}
    WriteLn('TQtGroupBox.Create ');
  {$endif}
  Parent := TQtWidget(LCLObject.Parent.Handle).GetContainerWidget;
  Result := QGroupBox_create(Parent);
  FCentralWidget := QWidget_create(Result, 0);
  Layout := QVBoxLayout_create(Result);
  QLayout_addWidget(Layout, FCentralWidget);
  QLayout_setSpacing(Layout, 0);
  QLayout_setMargin(Layout, 0);
  QWidget_setLayout(Result, QLayoutH(Layout));
end;

{------------------------------------------------------------------------------
  Function: TQtGroupBox.Destroy
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
destructor TQtGroupBox.Destroy;
begin
  {$ifdef VerboseQt}
    WriteLn('TQtGroupBox.Destroy');
  {$endif}

  if Widget <> nil then
  begin
    DetachEvents;
    QGroupBox_destroy(QGroupBoxH(Widget));
    Widget := nil;
  end;

  inherited Destroy;
end;

{ TQtFrame }

function TQtFrame.CreateWidget(const AParams: TCreateParams): QWidgetH;
var
  Parent: QWidgetH;
begin
  // Creates the widget
  {$ifdef VerboseQt}
    WriteLn('TQtFrame.Create');
  {$endif}
  Parent := TQtWidget(LCLObject.Parent.Handle).GetContainerWidget;
  Result := QFrame_create(Parent);
  QWidget_setAutoFillBackground(Result, True);
  QWidget_setAttribute(Result, QtWA_NoMousePropagation);
end;

{------------------------------------------------------------------------------
  Function: TQtFrame.setFrameStyle
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtFrame.setFrameStyle(p1: Integer);
begin
  QFrame_setFrameStyle(QFrameH(Widget), p1);
end;

{------------------------------------------------------------------------------
  Function: TQtFrame.setFrameShape
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtFrame.setFrameShape(p1: QFrameShape);
begin
  QFrame_setFrameShape(QFrameH(Widget), p1);
end;

{------------------------------------------------------------------------------
  Function: TQtFrame.setFrameShadow
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtFrame.setFrameShadow(p1: QFrameShadow);
begin
  QFrame_setFrameShadow(QFrameH(Widget), p1);
end;

{------------------------------------------------------------------------------
  Function: TQtFrame.setTextColor
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtFrame.setTextColor(const Value: PQColor);
var
  Palette: QPaletteH;
begin
  Palette := QPalette_create(QWidget_palette(Widget));
  try
    QPalette_setColor(Palette, QPaletteForeground, Value);
    QWidget_setPalette(Widget, Palette);
  finally
    QPalette_destroy(Palette);
  end;
end;

{------------------------------------------------------------------------------
  Function: TQtArrow.CreateWidget
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
function TQtArrow.CreateWidget(const AParams: TCreateParams):QWidgetH;
var
  Parent: QWidgetH;
begin
  // Creates the widget
  {$ifdef VerboseQt}
    WriteLn('TQtArrow.Create');
  {$endif}
  Parent := TQtWidget(LCLObject.Parent.Handle).GetContainerWidget;
  Result := QFrame_create(Parent);
  QWidget_setAttribute(Result, QtWA_NoMousePropagation);
end;

function TQtAbstractSlider.CreateWidget(const AParams: TCreateParams
  ): QWidgetH;
var
  Parent: QWidgetH;
begin
  // Creates the widget
  {$ifdef VerboseQt}
    WriteLn('TQtAbstractSlider.Create');
  {$endif}
  
  FSliderPressed := False;
  FSliderReleased:= False;

  Parent := TQtWidget(LCLObject.Parent.Handle).GetContainerWidget;
  Result := QAbstractSlider_create(Parent);
end;

procedure TQtAbstractSlider.AttachEvents;
begin
  inherited AttachEvents;
  FRangeChangedHook := QAbstractSlider_hook_create(Widget);
  FSliderMovedHook :=  QAbstractSlider_hook_create(Widget);
  FSliderPressedHook := QAbstractSlider_hook_create(Widget);
  FSliderReleasedHook := QAbstractSlider_hook_create(Widget);
  FValueChangedHook := QAbstractSlider_hook_create(Widget);
end;

procedure TQtAbstractSlider.DetachEvents;
begin
  QAbstractSlider_hook_destroy(FRangeChangedHook);
  QAbstractSlider_hook_destroy(FSliderMovedHook);
  QAbstractSlider_hook_destroy(FSliderPressedHook);
  QAbstractSlider_hook_destroy(FSliderReleasedHook);
  QAbstractSlider_hook_destroy(FValueChangedHook);
  inherited DetachEvents;
end;

function TQtAbstractSlider.getValue: Integer;
begin
  Result := QAbstractSlider_value(QAbstractSliderH(Widget));
end;

function TQtAbstractSlider.getPageStep: Integer;
begin
  Result := QAbstractSlider_pageStep(QAbstractSliderH(Widget));
end;

function TQtAbstractSlider.getMin: Integer;
begin
  Result := QAbstractSlider_minimum(QAbstractSliderH(Widget));
end;

function TQtAbstractSlider.getMax: Integer;
begin
  Result := QAbstractSlider_maximum(QAbstractSliderH(Widget));
end;

function TQtAbstractSlider.getSingleStep: Integer;
begin
  Result := QAbstractSlider_singleStep(QAbstractSliderH(Widget));
end;

{------------------------------------------------------------------------------
  Function: TQtAbstractSlider.rangeChanged
  Params:  minimum,maximum: Integer
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtAbstractSlider.SlotRangeChanged(minimum: Integer; maximum: Integer); cdecl;
begin
  { TODO: find out what needs to be done on rangeChanged event
    Possibilities: repaint or recount pageSize() }
 {$ifdef VerboseQt}
  writeln('TQtAbstractSlider.rangeChanged() to min=',minimum,' max=',maximum);
 {$endif}
end;

{------------------------------------------------------------------------------
  Function: TQtAbstractSlider.setInvertedAppereance
  Params:  p1: Boolean
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtAbstractSlider.setInvertedAppereance(p1: Boolean);
begin
  QAbstractSlider_setInvertedAppearance(QAbstractSliderH(Widget), p1);
end;

{------------------------------------------------------------------------------
  Function: TQtAbstractSlider.setInvertedControls
  Params:  p1: Boolean
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtAbstractSlider.setInvertedControls(p1: Boolean);
begin
  QAbstractSlider_setInvertedControls(QAbstractSliderH(Widget), p1);
end;

{------------------------------------------------------------------------------
  Function: TQtAbstractSlider.setMaximum
  Params:  p1: Integer
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtAbstractSlider.setMaximum(p1: Integer);
begin
  QAbstractSlider_setMaximum(QAbstractSliderH(Widget), p1);
end;

{------------------------------------------------------------------------------
  Function: TQtAbstractSlider.setMinimum
  Params:  p1: Integer
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtAbstractSlider.setMinimum(p1: Integer);
begin
  QAbstractSlider_setMinimum(QAbstractSliderH(Widget), p1);
end;

{------------------------------------------------------------------------------
  Function: TQtAbstractSlider.setOrientation
  Params:  p1: QtOrientation (QtHorizontal or QtVertical)
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtAbstractSlider.setOrientation(p1: QtOrientation);
begin
  QAbstractSlider_setOrientation(QAbstractSliderH(Widget), p1);
end;

{------------------------------------------------------------------------------
  Function: TQtAbstractSlider.setPageStep
  Params:  p1: Integer
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtAbstractSlider.setPageStep(p1: Integer);
begin
  QAbstractSlider_setPageStep(QAbstractSliderH(Widget), p1);
end;

{------------------------------------------------------------------------------
  Function: TQtAbstractSlider.setRange
  Params:  minimum,maximum: Integer
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtAbstractSlider.setRange(minimum: Integer; maximum: Integer);
begin
  QAbstractSlider_setRange(QAbstractSliderH(Widget), minimum, maximum);
end;

{------------------------------------------------------------------------------
  Function: TQtAbstractSlider.setSingleStep
  Params:  p1: Integer
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtAbstractSlider.setSingleStep(p1: Integer);
begin
  QAbstractSlider_setSingleStep(QAbstractSliderH(Widget), p1);
end;

{------------------------------------------------------------------------------
  Function: TQtAbstractSlider.setSliderDown
  Params:  p1: Boolean
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtAbstractSlider.setSliderDown(p1: Boolean);
begin
  QAbstractSlider_setSliderDown(QAbstractSliderH(Widget), p1);
end;


{------------------------------------------------------------------------------
  Function: TQtAbstractSlider.setSliderPosition
  Params:  p1: Integer
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtAbstractSlider.setSliderPosition(p1: Integer);
begin
  QAbstractSlider_setSliderPosition(QAbstractSliderH(Widget), p1);
end;

{------------------------------------------------------------------------------
  Function: TQtAbstractSlider.setTracking
  Params:  p1: Boolean
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtAbstractSlider.setTracking(p1: Boolean);
begin
  QAbstractSlider_setTracking(QAbstractSliderH(Widget), p1);
end;

{-----------------------------------------------------------------------------
  Function: TQtAbstractSlider.setValue
  Params:  p1: Integer
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtAbstractSlider.setValue(p1: Integer);
begin
  QAbstractSlider_setValue(QAbstractSliderH(Widget), p1);
end;

procedure TQtAbstractSlider.SlotSliderMoved(p1: Integer); cdecl;
var
   Msg: PLMessage;
   LMScroll: TLMScroll;
begin
 {$ifdef VerboseQt}
  writeln('TQtAbstractSlider.sliderMoved() to pos=',p1);
 {$endif}
 
  FillChar(Msg, SizeOf(Msg), #0);
  FillChar(LMScroll, SizeOf(LMScroll), #0);

  LMScroll.ScrollBar := LCLObject.Handle;
   
  if QAbstractSlider_orientation(QAbstractSliderH(Widget)) = QtHorizontal then
  LMScroll.Msg := LM_HSCROLL
  else
  LMScroll.Msg := LM_VSCROLL;

  LMScroll.Pos := p1;
  LMScroll.ScrollCode := SIF_POS; { SIF_TRACKPOS }

  Msg := @LMScroll;
  
  try
    if (TScrollBar(LCLObject).Position <> p1)
    and (Assigned(LCLObject.Parent)) then
    LCLObject.Parent.WindowProc(Msg^);
  except
    Application.HandleException(nil);
  end;
end;

procedure TQtAbstractSlider.SlotSliderPressed; cdecl;
begin
 {$ifdef VerboseQt}
  writeln('TQtAbstractSlider.sliderPressed()');
 {$endif}
 FSliderPressed := True;
 FSliderReleased := False;
end;

procedure TQtAbstractSlider.SlotSliderReleased; cdecl;
begin
 {$ifdef VerboseQt}
  writeln('TQtAbstractSlider.sliderReleased()');
 {$endif}
 FSliderPressed := False;
 FSliderReleased := True;
end;

procedure TQtAbstractSlider.SlotValueChanged(p1: Integer); cdecl;
var
  Msg: PLMessage;
  LMScroll: TLMScroll;
begin
 {$ifdef VerboseQt}
  writeln('TQtAbstractSlider.SlotValueChanged()');
 {$endif}
 
  FillChar(Msg, SizeOf(Msg), #0);
  FillChar(LMScroll, SizeOf(LMScroll), #0);

  LMScroll.ScrollBar := LCLObject.Handle;

  if QAbstractSlider_orientation(QAbstractSliderH(Widget)) = QtHorizontal then
  LMScroll.Msg := LM_HSCROLL
  else
  LMScroll.Msg := LM_VSCROLL;
  
  LMScroll.Pos := p1;
  LMScroll.ScrollCode := SIF_POS;

  Msg := @LMScroll;
  try
    if not SliderPressed and Assigned(LCLObject.Parent)
    and (p1 <> TScrollBar(LCLObject).Position) then
    begin
      LCLObject.Parent.WindowProc(Msg^);
    end;
  except
    Application.HandleException(nil);
  end;
end;


{ TQtScrollBar }

function TQtScrollBar.CreateWidget(const AParams: TCreateParams): QWidgetH;
var
  Parent: QWidgetH;
begin
  // Creates the widget
  {$ifdef VerboseQt}
    WriteLn('TQtScrollBar.Create');
  {$endif}
  Parent := TQtWidget(LCLObject.Parent.Handle).GetContainerWidget;
  Result := QScrollBar_create(Parent);
end;

procedure TQtScrollBar.AttachEvents;
var
  Method: TMethod;
begin
  inherited AttachEvents;
  QAbstractSlider_rangeChanged_Event(Method) := SlotRangeChanged;
  QAbstractSlider_hook_hook_rangeChanged(FRangeChangedHook, Method);

  QAbstractSlider_sliderMoved_Event(Method) := SlotSliderMoved;
  QAbstractSlider_hook_hook_sliderMoved(FSliderMovedHook, Method);

  QAbstractSlider_sliderPressed_Event(Method) := SlotSliderPressed;
  QAbstractSlider_hook_hook_sliderPressed(FSliderPressedHook, Method);

  QAbstractSlider_sliderReleased_Event(Method) := SlotSliderReleased;
  QAbstractSlider_hook_hook_sliderReleased(FSliderReleasedHook, Method);

  QAbstractSlider_valueChanged_Event(Method) := SlotValueChanged;
  QAbstractSlider_hook_hook_valueChanged(FValueChangedHook, Method);
end;

{ TQtToolBar }

function TQtToolBar.CreateWidget(const AParams: TCreateParams):QWidgetH;
var
  Parent: QWidgetH;
begin
  // Creates the widget
  {$ifdef VerboseQt}
    WriteLn('TQtToolBar.Create');
  {$endif}
  Parent := TQtWidget(LCLObject.Parent.Handle).GetContainerWidget;
  Result := QToolBar_create(Parent);
end;

{ TQtToolButton }

function TQtToolButton.CreateWidget(const AParams: TCreateParams):QWidgetH;
var
  Parent: QWidgetH;
begin
  // Creates the widget
  {$ifdef VerboseQt}
    WriteLn('TQtToolButton.Create');
  {$endif}
  Parent := TQtWidget(LCLObject.Parent.Handle).GetContainerWidget;
  Result := QToolButton_create(Parent);
end;

{ TQtTrackBar }

function TQtTrackBar.CreateWidget(const AParams: TCreateParams): QWidgetH;
var
  Parent: QWidgetH;
begin
  // Creates the widget
  {$ifdef VerboseQt}
    WriteLn('TQtTrackBar.Create');
  {$endif}
  Parent := TQtWidget(LCLObject.Parent.Handle).GetContainerWidget;
  Result := QSlider_create(Parent);
end;

{------------------------------------------------------------------------------
  Function: TQtTrackBar.setTickPosition
  Params:  Value: QSliderTickPosition
  Returns: Nothing
 ------------------------------------------------------------------------------ }
procedure TQtTrackBar.setTickPosition(Value: QSliderTickPosition);
begin
  QSlider_setTickPosition(QSliderH(Widget), Value);
end;

{------------------------------------------------------------------------------
  Function: TQtTrackBar.setTickInterval
  Params:  Value: Integer
  Returns: Nothing
 ------------------------------------------------------------------------------ }
procedure TQtTrackBar.SetTickInterval(Value: Integer);
begin
  QSlider_setTickInterval(QSliderH(Widget), Value);
end;

procedure TQtTrackBar.AttachEvents;
var
  Method: TMethod;
begin
  inherited AttachEvents;
  
  QAbstractSlider_rangeChanged_Event(Method) := SlotRangeChanged;
  QAbstractSlider_hook_hook_rangeChanged(FRangeChangedHook, Method);

  QAbstractSlider_sliderMoved_Event(Method) := SlotSliderMoved;
  QAbstractSlider_hook_hook_sliderMoved(FSliderMovedHook, Method);

  QAbstractSlider_sliderPressed_Event(Method) := SlotSliderPressed;
  QAbstractSlider_hook_hook_sliderPressed(FSliderPressedHook, Method);

  QAbstractSlider_sliderReleased_Event(Method) := SlotSliderReleased;
  QAbstractSlider_hook_hook_sliderReleased(FSliderReleasedHook, Method);

  QAbstractSlider_valueChanged_Event(Method) := SlotValueChanged;
  QAbstractSlider_hook_hook_valueChanged(FValueChangedHook, Method);
end;

procedure TQtTrackBar.SlotSliderMoved(p1: Integer); cdecl;
var
  Msg: TLMessage;
begin
 {$ifdef VerboseQt}
  writeln('TQtTrackBar.SlotSliderMoved()');
 {$endif}
  FillChar(Msg, SizeOf(Msg), #0);

  Msg.Msg := LM_CHANGED;
  try
    if (TTrackBar(LCLObject).Position<>p1) then
      LCLObject.WindowProc(Msg);
  except
    Application.HandleException(nil);
  end;
end;

procedure TQtTrackBar.SlotValueChanged(p1: Integer); cdecl;
var
  Msg: TLMessage;
begin
 {$ifdef VerboseQt}
  writeln('TQtTrackBar.SlotValueChanged()');
 {$endif}

  FillChar(Msg, SizeOf(Msg), #0);

  Msg.Msg := LM_CHANGED;
  try
    if not SliderPressed and (TTrackBar(LCLObject).Position<>p1) then
      LCLObject.WindowProc(Msg);
  except
    Application.HandleException(nil);
  end;
end;

procedure TQtTrackBar.SlotRangeChanged(minimum: Integer; maximum: Integer); cdecl;
var
  Msg: TLMessage;
begin
 {$ifdef VerboseQt}
  writeln('TQtTrackBar.SlotRangeChanged()');
 {$endif}
  FillChar(Msg, SizeOf(Msg), #0);

  Msg.Msg := LM_CHANGED;
  try
    DeliverMessage(Msg);
  except
    Application.HandleException(nil);
  end;
end;


{ TQtLineEdit }

function TQtLineEdit.CreateWidget(const AParams: TCreateParams): QWidgetH;
var
  Parent: QWidgetH;
  Str: WideString;
begin
  // Creates the widget
  {$ifdef VerboseQt}
    WriteLn('TQtLineEdit.Create');
  {$endif}
  Parent := TQtWidget(LCLObject.Parent.Handle).GetContainerWidget;
  Str := UTF8Decode((LCLObject as TCustomEdit).Text);
  Result := QLineEdit_create(@Str, Parent);
end;

function TQtLineEdit.getMaxLength: Integer;
begin
  Result := QLineEdit_maxLength(QLineEditH(Widget));
end;

function TQtLineEdit.getSelectedText: WideString;
begin
  QLineEdit_selectedText(QLineEditH(Widget), @Result);
end;

function TQtLineEdit.getSelectionStart: Integer;
begin
  Result := QLineEdit_selectionStart(QLineEditH(Widget));
end;

function TQtLineEdit.getText: WideString;
begin
  QLineEdit_text(QLineEditH(Widget), @Result);
end;

procedure TQtLineEdit.AttachEvents;
var
  Method: TMethod;
begin
  inherited AttachEvents;

  FTextChanged := QLineEdit_hook_create(Widget);
  {TODO: BUG CopyUnicodeToPWideString() segfaults while calling SetLength()
   workaround: add try..except around SetLength() }
  QLineEdit_textChanged_Event(Method) := SignalTextChanged;
  QLineEdit_hook_hook_textChanged(FTextChanged, Method);
end;

procedure TQtLineEdit.DetachEvents;
begin
  QLineEdit_hook_destroy(FTextChanged);
  inherited DetachEvents;
end;

{------------------------------------------------------------------------------
  Function: TQtLineEdit.EventFilter
  Params:  QObjectH, QEventH
  Returns: boolean

  Overrides TQtWidget EventFilter()
 ------------------------------------------------------------------------------}
function TQtLineEdit.EventFilter(Sender: QObjectH; Event: QEventH): Boolean; cdecl;
begin
  BeginEventProcessing;
  case QEvent_type(Event) of
    QEventFocusIn:
    begin
      if QFocusEvent_reason(QFocusEventH(Event)) in
        [QtTabFocusReason,QtBacktabFocusReason,QtActiveWindowFocusReason,
         QtShortcutFocusReason, QtOtherFocusReason] then
      begin
        // it would be better if we have AutoSelect published from TCustomEdit
        // then TMaskEdit also belongs here.
        if ((LCLObject is TEdit) and (TEdit(LCLObject).AutoSelect)) then
          QLineEdit_selectAll(QLineEditH(Widget));
      end;
    end;
  end;
  Result := inherited EventFilter(Sender, Event);
  EndEventProcessing;
end;

{------------------------------------------------------------------------------
  Function: TQtLineEdit.SetColor
  Params:  QColorH
  Returns: Nothing

  Changes the color of a widget
 ------------------------------------------------------------------------------}
procedure TQtLineEdit.SetColor(const Value: PQColor);
var
  Palette: QPaletteH;
begin
  Palette := QPalette_create(QWidget_palette(Widget));
  try
    QPalette_setColor(Palette, QPaletteBase, Value);
    QWidget_setPalette(Widget, Palette);
  finally
    QPalette_destroy(Palette);
  end;
end;

procedure TQtLineEdit.setEchoMode(const AMode: QLineEditEchoMode);
begin
  QLineEdit_setEchoMode(QLineEditH(Widget), AMode);
end;

procedure TQtLineEdit.setInputMask(const AMask: WideString);
begin
  QLineEdit_setInputMask(QLineEditH(Widget), @AMask);
end;

procedure TQtLineEdit.setMaxLength(const ALength: Integer);
begin
  QLineEdit_setMaxLength(QLineEditH(Widget), ALength);
end;

procedure TQtLineEdit.setReadOnly(const AReadOnly: Boolean);
begin
  QLineEdit_setReadOnly(QLineEditH(Widget), AReadOnly);
end;

procedure TQtLineEdit.setSelection(const AStart, ALength: Integer);
begin
  if AStart >= 0 then
    QLineEdit_setSelection(QLineEditH(Widget), AStart, ALength);
end;

procedure TQtLineEdit.setText(const AText: WideString);
begin
  QLineEdit_setText(QLineEditH(Widget), @AText);
end;

{------------------------------------------------------------------------------
  Function: TQtLineEdit.SignalTextChanged
  Params:  PWideString
  Returns: Nothing

  Fires OnChange() event of TCustomEdit
 ------------------------------------------------------------------------------}
procedure TQtLineEdit.SignalTextChanged(p1: PWideString); cdecl;
var
   Msg: TLMessage;
begin
   FillChar(Msg, SizeOf(Msg), #0);
   Msg.Msg := CM_TEXTCHANGED;
   DeliverMessage(Msg);
end;

{ TQtTextEdit }

function TQtTextEdit.CreateWidget(const AParams: TCreateParams): QWidgetH;
var
  Parent: QWidgetH;
begin
  // Creates the widget
  {$ifdef VerboseQt}
    WriteLn('TQtTextEdit.Create');
  {$endif}

  Result := QTextEdit_create();
end;

procedure TQtTextEdit.append(AStr: WideString);
begin
  QTextEdit_append(QTextEditH(Widget), @AStr);
end;

function TQtTextEdit.getPlainText: WideString;
begin
  QTextEdit_toPlainText(QTextEditH(Widget), @Result);
end;

function TQtTextEdit.getSelectionStart: Integer;
var
  TextCursor: QTextCursorH;
begin
  TextCursor := QTextCursor_create();
  QTextEdit_textCursor(QTextEditH(Widget), TextCursor);
  Result := QTextCursor_selectionStart(TextCursor);
  QTextCursor_destroy(TextCursor);
end;

function TQtTextEdit.getSelectionEnd: Integer;
var
  TextCursor: QTextCursorH;
begin
  TextCursor := QTextCursor_create();
  QTextEdit_textCursor(QTextEditH(Widget), TextCursor);
  Result := QTextCursor_selectionEnd(TextCursor);
  QTextCursor_destroy(TextCursor);
end;

{------------------------------------------------------------------------------
  Function: TQtTextEdit.SetColor
  Params:  QColorH
  Returns: Nothing

  Changes the color of a widget
 ------------------------------------------------------------------------------}
procedure TQtTextEdit.SetColor(const Value: PQColor);
var
  Palette: QPaletteH;
begin
  Palette := QPalette_create(QWidget_palette(Widget));
  try
    QPalette_setColor(Palette, QPaletteBase, Value);
    QWidget_setPalette(Widget, Palette);
  finally
    QPalette_destroy(Palette);
  end;
end;

procedure TQtTextEdit.setLineWrapMode(const AMode: QTextEditLineWrapMode);
begin
  QTextEdit_setLineWrapMode(QTextEditH(Widget), AMode);
end;

procedure TQtTextEdit.setPlainText(const AText: WideString);
begin
  QTextEdit_setPlainText(QTextEditH(Widget), @AText);
end;

procedure TQtTextEdit.setReadOnly(const AReadOnly: Boolean);
begin
  QTextEdit_setReadOnly(QTextEditH(Widget), AReadOnly);
end;

procedure TQtTextEdit.setSelection(const AStart, ALength: Integer);
var
  TextCursor: QTextCursorH;
begin
  if AStart >= 0 then
  begin
    TextCursor := QTextCursor_create();
    QTextEdit_textCursor(QTextEditH(Widget), TextCursor);
    QTextCursor_clearSelection(TextCursor);
    QTextCursor_setPosition(TextCursor, AStart);
    QTextCursor_setPosition(TextCursor, AStart + ALength, QTextCursorKeepAnchor);
    QTextEdit_setTextCursor(QTextEditH(Widget), TextCursor);
    QTextCursor_destroy(TextCursor);
  end;
end;

procedure TQtTextEdit.setTabChangesFocus(const AValue: Boolean);
begin
  QTextEdit_setTabChangesFocus(QTextEditH(Widget), AValue);
end;

procedure TQtTextEdit.SetAlignment(const AAlignment: QtAlignment);
var
  TextCursor: QTextCursorH;
begin
  // QTextEdit supports alignment for every paragraph. We need to align all text.
  // So, we should select all text, set format, and clear selection
  
  // 1. Select all text
  QTextEdit_selectAll(QTextEditH(Widget));
  
  // 2. Set format
  QTextEdit_setAlignment(QTextEditH(Widget), AAlignment);
  
  // 3. Clear selection. To unselect all document we must create new text cursor,
  // get format from Text Edit, clear selection in cursor and set it back to Text Edit
  TextCursor := QTextCursor_create();
  QTextEdit_textCursor(QTextEditH(Widget), TextCursor);
  QTextCursor_clearSelection(TextCursor);
  QTextEdit_setTextCursor(QTextEditH(Widget), TextCursor);
  QTextCursor_destroy(TextCursor);
end;

procedure TQtTextEdit.AttachEvents;
var
  Method: TMethod;
begin
  inherited AttachEvents;

  FTextChangedHook := QTextEdit_hook_create(Widget);
  {TODO: BUG CopyUnicodeToPWideString() segfaults while calling SetLength()
   workaround: add try..except around SetLength() }
  QTextEdit_textChanged_Event(Method) := SignalTextChanged;
  QTextEdit_hook_hook_textChanged(FTextChangedHook, Method);
end;

procedure TQtTextEdit.DetachEvents;
begin
  inherited DetachEvents;
  QTextEdit_hook_destroy(FTextChangedHook);
end;

{------------------------------------------------------------------------------
  Function: TQtTextEdit.SignalTextChanged
  Params:  none
  Returns: Nothing

  Fires OnChange() event of TCustomMemo
 ------------------------------------------------------------------------------}
procedure TQtTextEdit.SignalTextChanged; cdecl;
var
   Msg: TLMessage;
begin
   FillChar(Msg, SizeOf(Msg), #0);
   Msg.Msg := CM_TEXTCHANGED;
   DeliverMessage(Msg);
end;

{ TQtTabWidget }

function TQtTabWidget.CreateWidget(const AParams: TCreateParams): QWidgetH;
var
  Parent: QWidgetH;
begin
  // Creates the widget
  {$ifdef VerboseQt}
    WriteLn('TQtTabWidget.Create');
  {$endif}
  Parent := TQtWidget(LCLObject.Parent.Handle).GetContainerWidget;
  Result := QTabWidget_create(Parent);
end;

procedure TQtTabWidget.AttachEvents;
var
  Method: TMethod;
begin
  inherited AttachEvents;
  FCurrentChangedHook := QTabWidget_hook_create(Widget);
  
  QTabWidget_currentChanged_Event(Method) := SignalCurrentChanged;
  QTabWidget_hook_hook_currentChanged(FCurrentChangedHook, Method);
end;

procedure TQtTabWidget.DetachEvents;
begin
  QTabWidget_hook_destroy(FCurrentChangedHook);
  inherited DetachEvents;
end;

{------------------------------------------------------------------------------
  Function: TQtTabWidget.insertTab
  Params:  index: Integer; page: QWidgetH; p2: PWideString
  Returns: Nothing
 ------------------------------------------------------------------------------}
function TQtTabWidget.insertTab(index: Integer; page: QWidgetH; p2: PWideString): Integer; overload;
begin
  Result := QTabWidget_insertTab(QTabWidgetH(Widget), index, page, p2);
end;

{------------------------------------------------------------------------------
  Function: TQtTabWidget.insertTab
  Params:  index: Integer; page: QWidgetH; icon: QIconH; p2: PWideString
  Returns: Nothing
 ------------------------------------------------------------------------------}
function TQtTabWidget.insertTab(index: Integer; page: QWidgetH; icon: QIconH; p2: PWideString): Integer; overload;
begin
  Result := QTabWidget_insertTab(QTabWidgetH(Widget), index, page, icon, p2);
end;

function TQtTabWidget.getCurrentIndex: Integer;
begin
  Result := QTabWidget_currentIndex(QTabWidgetH(Widget));
end;

procedure TQtTabWidget.removeTab(AIndex: Integer);
begin
  QTabWidget_removeTab(QTabWidgetH(Widget), AIndex);
end;

procedure TQtTabWidget.setCurrentIndex(AIndex: Integer);
begin
  QTabWidget_setCurrentIndex(QTabWidgetH(Widget), AIndex);
end;

{------------------------------------------------------------------------------
  Function: TQtTabWidget.setTabPosition
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtTabWidget.SetTabPosition(ATabPosition: QTabWidgetTabPosition);
begin
  QTabWidget_setTabPosition(QTabWidgetH(Widget), ATabPosition);
end;

{------------------------------------------------------------------------------
  Function: TQtTabWidget.SignalCurrentChanged
  Params:  None
  Returns: Nothing
           Changes ActivePage of TPageControl
 ------------------------------------------------------------------------------}
procedure TQtTabWidget.SignalCurrentChanged(Index: Integer); cdecl;
var
  Msg: TLMNotify;
  Hdr: TNmHdr;
begin

  FillChar(Msg, SizeOf(Msg), #0);

  Msg.Msg := CN_NOTIFY;
  
  Hdr.hwndFrom := LCLObject.Handle;
  Hdr.Code := TCN_SELCHANGE;
  Hdr.idFrom := Index;
  
  Msg.NMHdr := @Hdr;
  try
    DeliverMessage(Msg);
  except
    Application.HandleException(nil);
  end;
end;

procedure TQtTabWidget.setTabText(index: Integer; p2: PWideString);
begin
  QTabWidget_setTabText(QTabWidgetH(Widget), index, p2);
end;


{ TQtComboBox }

function TQtComboBox.GetLineEdit: QLineEditH;
begin
  if not getEditable then
  begin
    FLineEdit := nil
  end
  else
  begin
    if FLineEdit = nil then
      FLineEdit := QComboBox_lineEdit(QComboBoxH(Widget));
  end;
  Result := FLineEdit;
end;

procedure TQtComboBox.SetOwnerDrawn(const AValue: Boolean);
begin
  FOwnerDrawn := AValue;
  if FDropList <> nil then
    FDropList.OwnerDrawn := FOwnerDrawn;
end;

function TQtComboBox.GetDropList: TQtListWidget;
begin
  if FDropList = nil then
  begin
    FDropList := TQtListWidget.CreateFrom(LCLObject, QComboBox_view(QComboBoxH(Widget)));
    FDropList.OwnerDrawn := OwnerDrawn;
  end;
  Result := FDropList;
end;

function TQtComboBox.CreateWidget(const AParams: TCreateParams): QWidgetH;
var
  Parent: QWidgetH;
begin
  // Creates the widget
  {$ifdef VerboseQt}
    WriteLn('TQtComboBox.Create');
  {$endif}
  Parent := TQtWidget(LCLObject.Parent.Handle).GetContainerWidget;
  Result := QComboBox_create(Parent);
  FLineEdit := nil;
  FOwnerDrawn := False;
end;

{------------------------------------------------------------------------------
  Function: TQtComboBox.Destroy
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
destructor TQtComboBox.Destroy;
begin
  FDropList.Free;
  inherited Destroy;
end;

procedure TQtComboBox.SetColor(const Value: PQColor);
begin
  inherited SetColor(Value);
end;

{------------------------------------------------------------------------------
  Function: TQtComboBox.currentIndex
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
function TQtComboBox.currentIndex: Integer;
begin
  Result := QComboBox_currentIndex(QComboBoxH(Widget));
end;

function TQtComboBox.getEditable: Boolean;
begin
  Result := QComboBox_isEditable(QComboBoxH(Widget));
end;

function TQtComboBox.getMaxVisibleItems: Integer;
begin
  Result := QComboBox_maxVisibleItems(QComboboxH(Widget));
end;

procedure TQtComboBox.insertItem(AIndex: Integer; AText: String);
var
  Str: WideString;
begin
  Str := UTF8Decode(AText);
  insertItem(AIndex, @Str);
end;

procedure TQtComboBox.insertItem(AIndex: Integer; AText: PWideString);
begin
  QComboBox_insertItem(QComboBoxH(WIdget), AIndex, AText, QVariant_create());
  if DropList.getVisible then
  begin
    BeginUpdate;
    QComboBox_hidePopup(QComboboxH(Widget));
    QComboBox_showPopup(QComboboxH(Widget));
    EndUpdate;
  end;
end;

{------------------------------------------------------------------------------
  Function: TQtComboBox.Destroy
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtComboBox.setCurrentIndex(index: Integer);
begin
  QComboBox_setCurrentIndex(QComboBoxH(Widget), index);
end;

procedure TQtComboBox.setMaxVisibleItems(ACount: Integer);
begin
  QComboBox_setMaxVisibleItems(QComboboxH(Widget), ACount);
end;

procedure TQtComboBox.setEditable(AValue: Boolean);
begin
  QComboBox_setEditable(QComboBoxH(Widget), AValue);
  if not AValue then
    FLineEdit := nil;
end;

procedure TQtComboBox.removeItem(AIndex: Integer);
begin
  QComboBox_removeItem(QComboBoxH(Widget), AIndex);
end;

procedure TQtComboBox.AttachEvents;
var
  Method: TMethod;
begin
  inherited AttachEvents;

  FChangeHook := QComboBox_hook_create(Widget);
  FSelectHook := QComboBox_hook_create(Widget);
  // OnChange event
  QComboBox_editTextChanged_Event(Method) := SlotChange;
  QComboBox_hook_hook_editTextChanged(FChangeHook, Method);
  // OnSelect event
  QComboBox_currentIndexChanged_Event(Method) := SlotSelect;
  QComboBox_hook_hook_currentIndexChanged(FSelectHook, Method);
  
  // DropList events
  FDropListEventHook := QObject_hook_create(DropList.Widget);
  TEventFilterMethod(Method) := EventFilter;
  QObject_hook_hook_events(FDropListEventHook, Method);
end;

procedure TQtComboBox.DetachEvents;
begin
  QComboBox_hook_destroy(FChangeHook);
  QComboBox_hook_destroy(FSelectHook);

  inherited DetachEvents;
end;

function TQtComboBox.EventFilter(Sender: QObjectH; Event: QEventH): Boolean; cdecl;
begin
  BeginEventProcessing;
  if (FDropList <> nil) and (Sender = FDropList.Widget) then
  begin
    Result := False;

    QEvent_accept(Event);
    
    case QEvent_type(Event) of
      QEventShow: SlotDropListVisibility(True);
      QEventHide: SlotDropListVisibility(False);
    else
      QEvent_ignore(Event);
    end;
  end else
    Result := inherited EventFilter(Sender, Event);
  EndEventProcessing;
end;

procedure TQtComboBox.SlotChange(p1: PWideString); cdecl;
var
  Msg: TLMessage;
begin
  if InUpdate then
    Exit;
    
  FillChar(Msg, SizeOf(Msg), #0);

  Msg.Msg := LM_CHANGED;

  try
    LCLObject.WindowProc(TLMessage(Msg));
  except
    Application.HandleException(nil);
  end;
end;

procedure TQtComboBox.SlotSelect(index: Integer); cdecl;
var
  Msg: TLMessage;
begin
  if InUpdate then
    exit;

  FillChar(Msg, SizeOf(Msg), #0);

  Msg.Msg := LM_SELCHANGE;

  try
    LCLObject.WindowProc(TLMessage(Msg));
  except
    Application.HandleException(nil);
  end;
end;

procedure TQtComboBox.SlotDropListVisibility(AVisible: Boolean); cdecl;
const
  VisibilityToCodeMap: array[Boolean] of Word =
  (
    CBN_CLOSEUP,
    CBN_DROPDOWN
  );
var
  Message : TLMCommand;
begin
  if InUpdate then
    Exit;
    
  FillChar(Message, SizeOf(Message), 0);
  Message.Msg := CN_COMMAND;
  Message.NotifyCode := VisibilityToCodeMap[AVisible];

  DeliverMessage(Message);
end;

{ TQtAbstractSpinBox }

function TQtAbstractSpinBox.CreateWidget(const AParams: TCreateParams): QWidgetH;
var
  Parent: QWidgetH;
begin
  // Creates the widget
  {$ifdef VerboseQt}
    WriteLn('TQtAbstractSpinBox.Create');
  {$endif}
  Parent := TQtWidget(LCLObject.Parent.Handle).GetContainerWidget;
  Result := QAbstractSpinBox_create(Parent);
end;

function TQtAbstractSpinBox.IsReadOnly: Boolean;
begin
  {$ifdef VerboseQt}
    WriteLn('TQtAbstractSpinBox.IsReadOnly');
  {$endif}
  Result := QAbstractSpinBox_isReadOnly(QAbstractSpinBoxH(Widget));
end;

procedure TQtAbstractSpinBox.SetReadOnly(r: Boolean);
begin
  {$ifdef VerboseQt}
    WriteLn('TQtAbstractSpinBox.SetReadOnly');
  {$endif}
  QAbstractSpinBox_setReadOnly(QAbstractSpinBoxH(Widget), r);
end;

procedure TQtAbstractSpinBox.AttachEvents;
var
  Method: TMethod;
begin
  inherited AttachEvents;

  FEditingFinishedHook := QAbstractSpinBox_hook_create(Widget);
  {TODO: find out which TLMessage should be sended }
  QAbstractSpinBox_editingFinished_Event(Method) := SignalEditingFinished;
  QAbstractSpinBox_hook_hook_editingFinished(FEditingFinishedHook, Method);
end;

procedure TQtAbstractSpinBox.DetachEvents;
begin
  QAbstractSpinBox_hook_destroy(FEditingFinishedHook);
  
  inherited DetachEvents;
end;

procedure TQtAbstractSpinBox.SignalEditingFinished; cdecl;
var
  Msg: TLMessage;
begin
  {$ifdef VerboseQt}
    WriteLn('TQtAbstractSpinBox.SignalEditingFinished');
  {$endif}
  FillChar(Msg, SizeOf(Msg), #0);
  { TODO: Find out which message should be sended here
    problem:
     everything is fine when we work with mouse, or
     press TabKey to select next control, but if we
     connect OnKeyDown and say eg. VK_RETURN: SelectNext(ActiveControl, true, true)
     then spinedit text is always selected, nothing important but looks ugly.}
//  Msg.Msg := LM_EXIT;
//  DeliverMessage(Msg);
end;

{ TQtFloatSpinBox }

function TQtFloatSpinBox.CreateWidget(const AParams: TCreateParams): QWidgetH;
var
  Parent: QWidgetH;
begin
  // Creates the widget
  {$ifdef VerboseQt}
    WriteLn('TQtFloatSpinBox.Create');
  {$endif}
  Parent := TQtWidget(LCLObject.Parent.Handle).GetContainerWidget;
  Result := QDoubleSpinBox_create(Parent);
end;

procedure TQtFloatSpinBox.AttachEvents;
var
  Method: TMethod;
begin
  inherited AttachEvents;
  FValueChangedHook := QDoubleSpinBox_hook_create(Widget);
  QDoubleSpinBox_valueChanged_Event(Method) := SignalValueChanged;
  QDoubleSpinBox_hook_hook_valueChanged(FValueChangedHook, Method);
end;

procedure TQtFloatSpinBox.DetachEvents;
begin
  QDoubleSpinBox_hook_destroy(FValueChangedHook);
  inherited DetachEvents;
end;

procedure TQtFloatSpinBox.SignalValueChanged(p1: Double); cdecl;
var
   Msg: TLMessage;
begin
  FillChar(Msg, SizeOf(Msg), #0);
  Msg.Msg := CM_TEXTCHANGED;
  DeliverMessage(Msg);
end;

{ TQtSpinBox }

function TQtSpinBox.CreateWidget(const AParams: TCreateParams): QWidgetH;
var
  Parent: QWidgetH;
begin
  // Creates the widget
  {$ifdef VerboseQt}
    WriteLn('TQtSpinBox.Create');
  {$endif}
  Parent := TQtWidget(LCLObject.Parent.Handle).GetContainerWidget;
  Result := QSpinBox_create(Parent);
end;

procedure TQtSpinBox.AttachEvents;
var
  Method: TMethod;
begin
  inherited AttachEvents;
  FValueChangedHook := QSpinBox_hook_create(Widget);
  QSpinBox_valueChanged_Event(Method) := SignalValueChanged;
  QSpinBox_hook_hook_valueChanged(FValueChangedHook, Method);
end;

procedure TQtSpinBox.DetachEvents;
begin
  QSpinBox_hook_destroy(FValueChangedHook);
  inherited DetachEvents;
end;

procedure TQtSpinBox.SignalValueChanged(p1: Integer); cdecl;
var
   Msg: TLMessage;
begin
  FillChar(Msg, SizeOf(Msg), #0);
  Msg.Msg := CM_TEXTCHANGED;
  DeliverMessage(Msg);
end;

function TQtListWidget.CreateWidget(const AParams: TCreateParams): QWidgetH;
var
  Parent: QWidgetH;
  Text: WideString;
  i: Integer;
begin
  // Creates the widget
  {$ifdef VerboseQt}
    WriteLn('TQListWidget.Create');
  {$endif}
  Parent := TQtWidget(LCLObject.Parent.Handle).GetContainerWidget;
  Result := QListWidget_create(Parent);

  // Sets the initial items
  for I := 0 to TCustomListBox(LCLObject).Items.Count - 1 do
  begin
    Text := UTF8Decode(TCustomListBox(LCLObject).Items.Strings[i]);
    QListWidget_addItem(QListWidgetH(Result), @Text);
  end;
  // Initialize current row or we get double fired LM_CLICKED on first mouse click.
  if TCustomListBox(LCLObject).Items.Count > 0 then
    QListWidget_setCurrentRow(QListWidgetH(Result), 0);
end;

procedure TQtListWidget.AttachEvents;
var
  Method: TMethod;
begin
  inherited AttachEvents;
  
  FSelectionChangeHook := QListWidget_hook_create(Widget);
  FItemDoubleClickedHook := QListWidget_hook_create(Widget);
  FItemClickedHook := QListWidget_hook_create(Widget);

  // OnSelectionChange event
  QListWidget_currentItemChanged_Event(Method) := SlotSelectionChange;
  QListWidget_hook_hook_currentItemChanged(FSelectionChangeHook, Method);

  QListWidget_itemDoubleClicked_Event(Method) := SignalItemDoubleClicked;
  QListWidget_hook_hook_ItemDoubleClicked(FItemDoubleClickedHook, Method);

  QListWidget_itemClicked_Event(Method) := SignalItemClicked;
  QListWidget_hook_hook_ItemClicked(FItemClickedHook, Method);
end;

procedure TQtListWidget.DetachEvents;
begin
  QListWidget_hook_destroy(FSelectionChangeHook);
  QListWidget_hook_destroy(FItemDoubleClickedHook);
  QListWidget_hook_destroy(FItemClickedHook);

  inherited DetachEvents;
end;

{------------------------------------------------------------------------------
  Function: TQtListWidget.SlotSelectionChange
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtListWidget.SlotSelectionChange(current: QListWidgetItemH;
  previous: QListWidgetItemH); cdecl;
var
  Msg: TLMessage;
begin
  FillChar(Msg, SizeOf(Msg), #0);

  Msg.Msg := LM_SELCHANGE;

  try
    LCLObject.WindowProc(TLMessage(Msg));
  except
    Application.HandleException(nil);
  end;
end;

{------------------------------------------------------------------------------
  Function: TQtListWidget.SignalItemDoubleClicked
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtListWidget.SignalItemDoubleClicked(item: QListWidgetItemH); cdecl;
var
  Msg: TLMMouse;
  MousePos: TQtPoint;
  Modifiers: QtKeyboardModifiers;
begin
  QCursor_pos(@MousePos);
  QWidget_mapFromGlobal(Widget, @MousePos, @MousePos);
  OffsetMousePos(@MousePos);
  Msg.Keys := 0;

  Modifiers := QApplication_keyboardModifiers();
  Msg.Keys := QtKeyModifiersToKeyState(Modifiers) or MK_LBUTTON;

  Msg.XPos := SmallInt(MousePos.X);
  Msg.YPos := SmallInt(MousePos.Y);

  Msg.Msg := LM_LBUTTONDBLCLK;
  NotifyApplicationUserInput(Msg.Msg);
  DeliverMessage(Msg);
  Msg.Msg := LM_PRESSED;
  DeliverMessage(Msg);
  Msg.Msg := LM_LBUTTONUP;
  NotifyApplicationUserInput(Msg.Msg);
  DeliverMessage(Msg);
  Msg.Msg := LM_RELEASED;
  DeliverMessage(Msg);
end;

{------------------------------------------------------------------------------
  Function: TQtListWidget.SignalItemClicked
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtListWidget.SignalItemClicked(item: QListWidgetItemH); cdecl;
var
  Msg: TLMMouse;
  MousePos: TQtPoint;
  Modifiers: QtKeyboardModifiers;
begin
  QCursor_pos(@MousePos);
  QWidget_mapFromGlobal(Widget, @MousePos, @MousePos);
  OffsetMousePos(@MousePos);
  Msg.Keys := 0;

  Modifiers := QApplication_keyboardModifiers();
  Msg.Keys := QtKeyModifiersToKeyState(Modifiers) or MK_LBUTTON;

  Msg.XPos := SmallInt(MousePos.X);
  Msg.YPos := SmallInt(MousePos.Y);

  Msg.Msg := LM_LBUTTONDOWN;
  NotifyApplicationUserInput(Msg.Msg);
  DeliverMessage(Msg);
  Msg.Msg := LM_PRESSED;
  DeliverMessage(Msg);
  Msg.Msg := LM_LBUTTONUP;
  NotifyApplicationUserInput(Msg.Msg);
  DeliverMessage(Msg);
  Msg.Msg := LM_RELEASED;
  DeliverMessage(Msg);
end;

procedure TQtListWidget.ItemDelegatePaint(painter: QPainterH;
  option: QStyleOptionViewItemH; index: QModelIndexH); cdecl;
var
  Msg: TLMDrawListItem;
  DrawStruct: TDrawListItemStruct;
  State: QStyleState;
begin
  QPainter_save(painter);
  State := QStyleOption_state(option);
  DrawStruct.ItemID := QModelIndex_row(index);

  DrawStruct.Area := visualRect(index);
  DrawStruct.DC := HDC(TQtDeviceContext.CreateFromPainter(painter));

  DrawStruct.ItemState := [];
  // selected
  if (State and QStyleState_Selected) <> 0 then
    Include(DrawStruct.ItemState, odSelected);
  // disabled
  if (State and QStyleState_Enabled) = 0 then
    Include(DrawStruct.ItemState, odDisabled);
  // focused (QStyleState_FocusAtBorder?)
  if (State and QStyleState_HasFocus) <> 0 then
    Include(DrawStruct.ItemState, odFocused);
  // hotlight
  if (State and QStyleState_MouseOver) <> 0 then
    Include(DrawStruct.ItemState, odHotLight);

  { todo: over states:
  
    odGrayed, odChecked,
    odDefault, odInactive, odNoAccel,
    odNoFocusRect, odReserved1, odReserved2, odComboBoxEdit,
    odPainted
  }
  Msg.Msg := LM_DRAWLISTITEM;
  Msg.DrawListItemStruct := @DrawStruct;
  DeliverMessage(Msg);

  QPainter_restore(painter);
  
  TQtDeviceContext(DrawStruct.DC).Free;
end;

{------------------------------------------------------------------------------
  Function: TQtListWidget.currentRow
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
function TQtListWidget.currentRow: Integer;
begin
  Result := QListWidget_currentRow(QListWidgetH(Widget));
end;

function TQtListWidget.IndexAt(APoint: PQtPoint): Integer;
var
  AModelIndex: QModelIndexH;
begin
  AModelIndex := QModelIndex_create();
  QListView_indexAt(QListWidgetH(Widget), AModelIndex, APoint);
  Result := QModelIndex_row(AModelIndex);
  QModelIndex_destroy(AModelIndex);
end;

{------------------------------------------------------------------------------
  Function: TQtListWidget.setCurrentRow
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtListWidget.setCurrentRow(row: Integer);
begin
  QListWidget_setCurrentRow(QListWidgetH(Widget), row);
end;


  { TQtHeaderView }
  
{------------------------------------------------------------------------------
  Function: TQtHeaderView.CreateWidget
  Params:  None
  Returns: Widget (QHeaderViewH)
 ------------------------------------------------------------------------------}
function TQtHeaderView.CreateWidget(const AParams: TCreateParams):QWidgetH;
var
  Parent: QWidgetH;
begin
  // Creates the widget
  {$ifdef VerboseQt}
    WriteLn('TQtHeaderView.Create');
  {$endif}
  Parent := TQtWidget(LCLObject.Parent.Handle).GetContainerWidget;
  Result := QHeaderView_create(QtHorizontal, Parent);
end;

procedure TQtHeaderView.AttachEvents;
var
  Method: TMethod;
begin
  inherited AttachEvents;
  FSelectionClicked := QHeaderView_hook_create(Widget);
  
  QHeaderView_sectionClicked_Event(Method) := SignalSectionClicked;
  QHeaderView_hook_hook_sectionClicked(FSelectionClicked, Method);
end;

procedure TQtHeaderView.DetachEvents;
begin
  QHeaderView_hook_destroy(FSelectionClicked);
  inherited DetachEvents;
end;

{------------------------------------------------------------------------------
  Function: TQtHeaderView.SignalSectionClicked
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtHeaderView.SignalSectionClicked(logicalIndex: Integer) cdecl;
var
  Msg: TLMNotify;
  NMLV: TNMListView;
begin

  FillChar(Msg, SizeOf(Msg), #0);
  FillChar(NMLV, SizeOf(NMLV), #0);
  
  Msg.Msg := CN_NOTIFY;
  NMLV.hdr.hwndfrom := LCLObject.Handle;
  NMLV.hdr.code := LVN_COLUMNCLICK;
  NMLV.iItem := -1;
  NMLV.iSubItem := logicalIndex;
  
  Msg.NMHdr := @NMLV.hdr;
  
  DeliverMessage(Msg);
  
end;

  { TQtTreeView }

{------------------------------------------------------------------------------
  Function: TQtTreeView.CreateWidget
  Params:  None
  Returns: Widget (QTreeViewH)
 ------------------------------------------------------------------------------}
function TQtTreeView.CreateWidget(const AParams: TCreateParams):QWidgetH;
var
  Parent: QWidgetH;
begin
  // Creates the widget
  {$ifdef VerboseQt}
    WriteLn('TQtTreeView.Create');
  {$endif}
  Parent := TQtWidget(LCLObject.Parent.Handle).GetContainerWidget;
  Result := QTreeView_create(Parent);
end;

  { TQtTreeWidget }

{------------------------------------------------------------------------------
  Function: TQtTreeWidget.CreateWidget
  Params:  None
  Returns: Widget (QTreeWidgetH)
 ------------------------------------------------------------------------------}
function TQtTreeWidget.CreateWidget(const AParams: TCreateParams):QWidgetH;
var
  Parent: QWidgetH;
begin
  // Creates the widget
  {$ifdef VerboseQt}
    WriteLn('TQtTreeWidget.Create');
  {$endif}
  Parent := TQtWidget(LCLObject.Parent.Handle).GetContainerWidget;
  Result := QTreeWidget_create(Parent);
  
  Header := TQtHeaderView.Create(LCLObject, AParams);
  Header.AttachEvents;
  
  QTreeView_setHeader(QTreeViewH(Result), QHeaderViewH(Header.Widget));
end;

{------------------------------------------------------------------------------
  Function: TQtTreeWidget.Destroy
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
destructor TQtTreeWidget.Destroy;
begin
  {$ifdef VerboseQt}
    WriteLn('TQtTreeWidget.Destroy');
  {$endif}

  if Assigned(Header) then
    Header.Free;

  inherited Destroy;
end;

{------------------------------------------------------------------------------
  Function: TQtTreeWidget.CurrentRow
  Params:  None
  Returns: Integer
 ------------------------------------------------------------------------------}
function TQtTreeWidget.currentRow: Integer;
var
  TWI: QTreeWidgetItemH;
begin
  TWI := QTreeWidget_currentItem(QTreeWidgetH(Widget));
  Result := QTreeWidget_indexOfTopLevelItem(QTreeWidgetH(Widget), TWI);
end;

{------------------------------------------------------------------------------
  Function: TQtTreeWidget.setCurrentRow
  Params:  Integer
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtTreeWidget.setCurrentRow(row: Integer);
var
  TWI: QTreeWidgetItemH;
begin
  TWI := QTreeWidget_topLevelItem(QTreeWidgetH(Widget), Row);
  QTreeWidget_setCurrentItem(QTreeWidgetH(Widget), TWI);
end;

procedure TQtTreeWidget.AttachEvents;
var
  Method: TMethod;
begin
  inherited AttachEvents;

  FCurrentItemChangedHook := QTreeWidget_hook_create(Widget);
  FItemDoubleClickedHook := QTreeWidget_hook_create(Widget);
  FItemClickedHook := QTreeWidget_hook_create(Widget);
  FItemActivatedHook := QTreeWidget_hook_create(Widget);
  FItemChangedHook := QTreeWidget_hook_create(Widget);
  FItemSelectionChangedHook := QTreeWidget_hook_create(Widget);
  FItemPressedHook := QTreeWidget_hook_create(Widget);
  FItemEnteredHook := QTreeWidget_hook_create(Widget);
  
  QTreeWidget_currentItemChanged_Event(Method) := SignalCurrentItemChanged;
  QTreeWidget_hook_hook_currentItemChanged(FCurrentItemChangedHook, Method);

  QTreeWidget_itemDoubleClicked_Event(Method) := SignalItemDoubleClicked;
  QTreeWidget_hook_hook_ItemDoubleClicked(FItemDoubleClickedHook, Method);

  QTreeWidget_itemClicked_Event(Method) := SignalItemClicked;
  QTreeWidget_hook_hook_ItemClicked(FItemClickedHook, Method);

  QTreeWidget_itemActivated_Event(Method) := SignalItemActivated;
  QTreeWidget_hook_hook_ItemActivated(FItemActivatedHook, Method);

  QTreeWidget_itemChanged_Event(Method) := SignalItemChanged;
  QTreeWidget_hook_hook_ItemChanged(FItemChangedHook, Method);

  QTreeWidget_itemSelectionChanged_Event(Method) := SignalItemSelectionChanged;
  QTreeWidget_hook_hook_ItemSelectionChanged(FItemSelectionChangedHook, Method);

  QTreeWidget_itemPressed_Event(Method) := SignalItemPressed;
  QTreeWidget_hook_hook_ItemPressed(FItemPressedHook, Method);

  QTreeWidget_itemEntered_Event(Method) := SignalItemEntered;
  QTreeWidget_hook_hook_ItemEntered(FItemEnteredHook, Method);
end;

procedure TQtTreeWidget.DetachEvents;
begin
  QTreeWidget_hook_destroy(FCurrentItemChangedHook);
  QTreeWidget_hook_destroy(FItemDoubleClickedHook);
  QTreeWidget_hook_destroy(FItemClickedHook);
  QTreeWidget_hook_destroy(FItemActivatedHook);
  QTreeWidget_hook_destroy(FItemChangedHook);
  QTreeWidget_hook_destroy(FItemSelectionChangedHook);
  QTreeWidget_hook_destroy(FItemPressedHook);
  QTreeWidget_hook_destroy(FItemEnteredHook);
  
  inherited DetachEvents;
end;

{------------------------------------------------------------------------------
  Function: TQtTreeWidget.SignalItemPressed
  Params:  Integer
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtTreeWidget.SignalItemPressed(item: QTreeWidgetItemH; column: Integer) cdecl;
var
  Msg: TLMNotify;
  NMLV: TNMListView;
begin
  FillChar(Msg, SizeOf(Msg), #0);
  FillChar(NMLV, SizeOf(NMLV), #0);

  Msg.Msg := LM_PRESSED;
  
  NMLV.hdr.hwndfrom := LCLObject.Handle;
  NMLV.hdr.code := LVN_ITEMCHANGED;

  NMLV.iItem := QTreeWidget_indexOfTopLevelItem(QTreeWidgetH(Widget), Item);

  NMLV.iSubItem := Column;
  NMLV.uNewState := UINT(NM_KEYDOWN);
  NMLV.uChanged := LVIS_SELECTED;

  Msg.NMHdr := @NMLV.hdr;

  DeliverMessage(Msg);
end;

{------------------------------------------------------------------------------
  Function: TQtTreeWidget.SignalItemClicked
  Params:  Integer
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtTreeWidget.SignalItemClicked(item: QTreeWidgetItemH; column: Integer) cdecl;
var
  Msg: TLMNotify;
  NMLV: TNMListView;
  R: TRect;
  Pt: TPoint;
begin

  FillChar(Msg, SizeOf(Msg), #0);
  FillChar(NMLV, SizeOf(NMLV), #0);

  Msg.Msg := LM_CLICKED;

  NMLV.hdr.hwndfrom := LCLObject.Handle;
  NMLV.hdr.code := NM_CLICK;

  NMLV.iItem := QTreeWidget_indexOfTopLevelItem(QTreeWidgetH(Widget), Item);

  NMLV.iSubItem := Column;
  NMLV.uNewState := UINT(NM_CLICK);
  NMLV.uChanged := LVIS_SELECTED;
  QTreeWidget_visualItemRect(QTreeWidgetH(Widget), @R, Item);
  
  pt.X := R.Left;
  pt.Y := R.Top;

  NMLV.ptAction := pt;

  Msg.NMHdr := @NMLV.hdr;
  
  DeliverMessage(Msg);
  
end;

{------------------------------------------------------------------------------
  Function: TQtTreeWidget.SignalItemDoubleClicked
  Params:  Integer
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtTreeWidget.SignalItemDoubleClicked(item: QTreeWidgetItemH; column: Integer) cdecl;
var
  Msg: TLMNotify;
  NMLV: TNMListView;
begin
  FillChar(Msg, SizeOf(Msg), #0);
  FillChar(NMLV, SizeOf(NMLV), #0);
  
  Msg.Msg := LM_LBUTTONDBLCLK;

  NMLV.hdr.hwndfrom := LCLObject.Handle;
  NMLV.hdr.code := NM_DBLCLK;

  NMLV.iItem := QTreeWidget_indexOfTopLevelItem(QTreeWidgetH(Widget), Item);

  NMLV.iSubItem := Column;
  NMLV.uNewState := UINT(NM_DBLCLK);
  NMLV.uChanged := LVIS_SELECTED;
  // LVIF_STATE;
  
  Msg.NMHdr := @NMLV.hdr;
  
  DeliverMessage( Msg);
end;

{------------------------------------------------------------------------------
  Function: TQtTreeWidget.SignalItemActivated
  Params:  Integer
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtTreeWidget.SignalItemActivated(item: QTreeWidgetItemH; column: Integer) cdecl;
var
  Msg: TLMNotify;
  NMLV: TNMListView;
begin
  FillChar(Msg, SizeOf(Msg), #0);
  FillChar(NMLV, SizeOf(NMLV), #0);

  Msg.Msg := CN_NOTIFY;

  NMLV.hdr.hwndfrom := LCLObject.Handle;
  NMLV.hdr.code := LVN_ITEMCHANGED;

  NMLV.iItem := QTreeWidget_indexOfTopLevelItem(QTreeWidgetH(Widget), Item);

  NMLV.iSubItem := Column;
  NMLV.uNewState := LVIS_FOCUSED;
  NMLV.uChanged := LVIF_STATE;

  Msg.NMHdr := @NMLV.hdr;

  DeliverMessage( Msg);
end;

{------------------------------------------------------------------------------
  Function: TQtTreeWidget.SignalItemEntered
  Params:  Integer
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtTreeWidget.SignalItemEntered(item: QTreeWidgetItemH; column: Integer) cdecl;
var
  Msg: TLMessage;
begin
  FillChar(Msg, SizeOf(Msg), #0);
  Msg.Msg := LM_ENTER;
  try
    LCLObject.WindowProc(TLMessage(Msg));
  except
    Application.HandleException(nil);
  end;
end;

{------------------------------------------------------------------------------
  Function: TQtTreeWidget.SignalItemChanged
  Params:  Integer
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtTreeWidget.SignalItemChanged(item: QTreeWidgetItemH; column: Integer) cdecl;
var
  Msg: TLMessage;
begin
  FillChar(Msg, SizeOf(Msg), #0);
  Msg.Msg := LM_CHANGED;
  try
    LCLObject.WindowProc(TLMessage(Msg));
  except
    Application.HandleException(nil);
  end;
end;

{------------------------------------------------------------------------------
  Function: TQtTreeWidget.SignalItemExpanded
  Params:  Integer
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtTreeWidget.SignalitemExpanded(item: QTreeWidgetItemH) cdecl;
begin
{fixme}
end;

{------------------------------------------------------------------------------
  Function: TQtTreeWidget.SignalItemCollapsed
  Params:  Integer
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtTreeWidget.SignalItemCollapsed(item: QTreeWidgetItemH) cdecl;
begin
{fixme}
end;

{------------------------------------------------------------------------------
  Function: TQtTreeWidget.SignalCurrentItemChanged
  Params:  Integer
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtTreeWidget.SignalCurrentItemChanged(current: QTreeWidgetItemH; previous: QTreeWidgetItemH) cdecl;
var
  Msg: TLMNotify;
  NMLV: TNMListView;
  AParent: QTreeWidgetItemH;
  ASubIndex: Integer;
begin

  FillChar(Msg, SizeOf(Msg), #0);
  FillChar(NMLV, SizeOf(NMLV), #0);

  Msg.Msg := CN_NOTIFY;

  NMLV.hdr.hwndfrom := LCLObject.Handle;
  NMLV.hdr.code := LVN_ITEMCHANGING;
  
  NMLV.iItem := QTreeWidget_indexOfTopLevelItem(QTreeWidgetH(Widget), Current);
  
  AParent := QTreeWidgetItem_parent(Current);
  
  if AParent <> NiL then
    ASubIndex := QTreeWidgetItem_indexOfChild(AParent, Current)
  else
    ASubIndex := 0;
    
  NMLV.iSubItem := ASubIndex;
  NMLV.uNewState := LVIS_SELECTED;
  NMLV.uChanged := LVIF_STATE;

  Msg.NMHdr := @NMLV.hdr;
  
  if Current <> Previous then
  DeliverMessage(Msg);
  
end;

{------------------------------------------------------------------------------
  Function: TQtTreeWidget.SignalItemSelectionChanged
  Params:  Integer
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtTreeWidget.SignalItemSelectionChanged; cdecl;
var
  Msg: TLMNotify;
  NMLV: TNMListView;
  Item: QTreeWidgetItemH;
  AParent: QTreeWidgetItemH;
  AIndex: Integer;
  ASubIndex: Integer;
begin
  FillChar(Msg, SizeOf(Msg), #0);
  FillChar(NMLV, SizeOf(NMLV), #0);

  Msg.Msg := CN_NOTIFY;


  NMLV.hdr.hwndfrom := LCLObject.Handle;
  NMLV.hdr.code := LVN_ITEMCHANGED;


  Item := QTreeWidget_currentItem(QTreeWidgetH(Widget));
  AIndex := QTreeWidget_indexOfTopLevelItem(QTreeWidgetH(Widget), Item);
  AParent := QTreeWidgetItem_parent(Item);
  if AParent <> NiL then
    ASubIndex := QTreeWidgetItem_indexOfChild(AParent, Item)
  else
    ASubIndex := 0;

  NMLV.iItem := AIndex;
  NMLV.iSubItem := ASubIndex;
  NMLV.uNewState := LVIS_SELECTED;
  NMLV.uChanged := LVIF_STATE;


  Msg.NMHdr := @NMLV.hdr;

  DeliverMessage(Msg);
  
end;


{ TQtMenu }

constructor TQtMenu.Create(const AParent: QWidgetH);
begin
  Create;
  Widget := QMenu_Create(AParent);
  FIcon := nil;
end;

constructor TQtMenu.Create(const AHandle: QMenuH);
begin
  Create;
  Widget := AHandle;
  FIcon := nil;
end;

destructor TQtMenu.Destroy;
begin
  if FIcon <> nil then
    QIcon_destroy(FIcon);
  inherited Destroy;
end;

procedure TQtMenu.AttachEvents;
var
  Method: TMethod;
begin
  FActionHook := QAction_hook_create(ActionHandle);
  FEventHook := QObject_hook_create(Widget);

  QAction_triggered_Event(Method) := SlotTriggered;
  QAction_hook_hook_triggered(FActionHook, Method);
  TEventFilterMethod(Method) := EventFilter;
  QObject_hook_hook_events(FEventHook, Method);
end;

procedure TQtMenu.DetachEvents;
begin
  if FActionHook <> nil then
  begin
    QAction_hook_destroy(FActionHook);
    FActionHook := nil;
  end;

  inherited DetachEvents;
end;

procedure TQtMenu.SlotDestroy; cdecl;
begin
  Widget := nil;
end;

procedure TQtMenu.PopUp(pos: PQtPoint; at: QActionH);
begin
  QMenu_Popup(QMenuH(Widget), pos, at);
end;

function TQtMenu.actionHandle: QActionH;
begin
  Result := QMenu_menuAction(QMenuH(Widget));
end;

function TQtMenu.addMenu(title: PWideString): TQtMenu;
begin
  Result := TQtMenu.Create(QMenu_addMenu(QMenuH(Widget), title));
end;

function TQtMenu.addSeparator: TQtMenu;
begin
  Result := TQtMenu.Create(QMenu_addMenu(QMenuH(Widget), nil));
  Result.setSeparator(True);
end;

function TQtMenu.getVisible: Boolean;
begin
  Result := QAction_isVisible(ActionHandle);
end;

procedure TQtMenu.setText(AText: PWideString);
begin
  QAction_setText(ActionHandle, AText);
end;

procedure TQtMenu.setVisible(visible: Boolean);
begin
  QAction_setVisible(ActionHandle, visible);
end;

procedure TQtMenu.setChecked(p1: Boolean);
begin
  if p1 then setCheckable(True)
  else setCheckable(False);

  QAction_setChecked(ActionHandle, p1);
end;

procedure TQtMenu.setCheckable(p1: Boolean);
begin
  QAction_setCheckable(ActionHandle, p1);
end;

procedure TQtMenu.setHasSubmenu(AValue: Boolean);
begin
  if AValue then
    QAction_setMenu(ActionHandle, QMenuH(Widget))
  else
    QAction_setMenu(ActionHandle, nil);
end;

procedure TQtMenu.setIcon(AIcon: QIconH);
begin
  QMenu_setIcon(QMenuH(Widget), AIcon)
end;

procedure TQtMenu.setImage(AImage: TQtImage);
begin
  if FIcon <> nil then
  begin
    QIcon_destroy(FIcon);
    FIcon := nil;
  end;

  if AImage <> nil then
    FIcon := AImage.AsIcon()
  else
    FIcon := QIcon_create();
    
  setIcon(FIcon);
end;

procedure TQtMenu.setSeparator(AValue: Boolean);
begin
  QAction_setSeparator(ActionHandle, AValue);
end;

procedure TQtMenu.setShortcut(AShortcut: TShortcut);
var
  Key: Word;
  KeySequence: QKeySequenceH;
  Shift: TShiftState;
  Modifiers: QtModifier;
begin
  if AShortCut <> 0 then
  begin
    ShortCutToKey(AShortCut, Key, Shift);
    Modifiers := ShiftStateToQtModifiers(Shift);
    // there is no need in destroying QKeySequnce
    KeySequence := QKeySequence_create(LCLKeyToQtKey(Key) or Modifiers);
  end
  else
    KeySequence := QKeySequence_create();
  QAction_setShortcut(ActionHandle, KeySequence);
  QKeySequence_destroy(KeySequence);
end;

{------------------------------------------------------------------------------
  Method: TQtMenu.SlotTriggered

  Callback for menu item click
 ------------------------------------------------------------------------------}
procedure TQtMenu.SlotTriggered(checked: Boolean); cdecl;
begin
  if Assigned(MenuItem) and Assigned(MenuItem.OnClick) then
   MenuItem.OnClick(Self.MenuItem);
end;

function TQtMenu.EventFilter(Sender: QObjectH; Event: QEventH): Boolean; cdecl;
begin
  BeginEventProcessing;
  Result := False;

  case QEvent_type(Event) of
    QEventDestroy: SlotDestroy;
  end;
  EndEventProcessing;
end;

{ TQtMenuBar }

constructor TQtMenuBar.Create(const AParent: QWidgetH);
begin
  Create;
  Widget := QMenuBar_create(AParent);
  FHeight := QWidget_height(Widget);
  FVisible := False;
  setVisible(FVisible);
end;

function TQtMenuBar.addMenu(title: PWideString): TQtMenu;
begin
  if not FVisible then
  begin
    FVisible := True;
    setVisible(FVisible);
  end;
  
  Result := TQtMenu.Create(QMenuBar_addMenu(QMenuBarH(Widget), title));
end;

function TQtMenuBar.addSeparator: TQtMenu;
begin
  if not FVisible then
  begin
    FVisible := True;
    setVisible(FVisible);
  end;
  Result := TQtMenu.Create(QMenuBar_addMenu(QMenuBarH(Widget), nil));
  Result.setSeparator(True);
end;

function TQtMenuBar.getGeometry: TRect;
begin
  Result := inherited getGeometry;
  if Result.Bottom = 0 then
  begin
    Result.Bottom := FHeight; // workaround since after attaching menu it takes 0 height
  end;
end;

{ TQtProgressBar }

function TQtProgressBar.CreateWidget(const AParams: TCreateParams): QWidgetH;
var
  Parent: QWidgetH;
begin
  // Creates the widget
  {$ifdef VerboseQt}
    WriteLn('TQProgressBar.Create');
  {$endif}
  Parent := TQtWidget(LCLObject.Parent.Handle).GetContainerWidget;
  Result := QProgressBar_create(Parent);
end;

procedure TQtProgressBar.AttachEvents;
var
  Method: TMethod;
begin
  inherited AttachEvents;

  FValueChangedHook := QProgressBar_hook_create(Widget);
  QProgressBar_valueChanged_Event(Method) := SignalValueChanged;
  QProgressBar_hook_hook_valueChanged(FValueChangedHook, Method);
end;

procedure TQtProgressBar.DetachEvents;
begin
  QProgressBar_hook_destroy(FValueChangedHook);
  inherited DetachEvents;
end;

procedure TQtProgressBar.setRange(minimum: Integer; maximum: Integer);
begin
  QProgressBar_setRange(QProgressBarH(Widget), minimum, maximum);
end;

procedure TQtProgressBar.setTextVisible(visible: Boolean);
begin
  QProgressBar_setTextVisible(QProgressBarH(Widget), visible);
end;

procedure TQtProgressBar.setAlignment(const AAlignment: QtAlignment);
begin
  QProgressBar_setAlignment(QProgressBarH(Widget), AAlignment);
end;

procedure TQtProgressBar.setTextDirection(textDirection: QProgressBarDirection);
begin
  QProgressBar_setTextDirection(QProgressBarH(Widget), textDirection);
end;

procedure TQtProgressBar.setValue(value: Integer);
begin
  QProgressBar_setValue(QProgressBarH(Widget), value);
end;

procedure TQtProgressBar.setOrientation(p1: QtOrientation);
begin
  QProgressBar_setOrientation(QProgressBarH(Widget), p1);
end;

procedure TQtProgressBar.setInvertedAppearance(invert: Boolean);
begin
  QProgressBar_setInvertedAppearance(QProgressBarH(Widget), invert);
end;

procedure TQtProgressBar.SignalValueChanged(Value: Integer);
var
  Msg: TLMessage;
begin
  FillChar(Msg, SizeOf(Msg), #0);
  Msg.Msg := LM_CHANGED;
  DeliverMessage(Msg);
end;

{ TQtStatusBar }

function TQtStatusBar.CreateWidget(const AParams: TCreateParams): QWidgetH;
var
  Parent: QWidgetH;
begin
  // Creates the widget
  {$ifdef VerboseQt}
    WriteLn('TQtStatusBar.Create');
  {$endif}
  
  SetLength(APanels, 0);
  Parent := TQtWidget(LCLObject.Parent.Handle).GetContainerWidget;
  Result := QStatusBar_create(Parent);
  
  {TODO: this should be made in initializeWND?
  if (LCLObject as TStatusBar).SimplePanel then
  begin;
    Text := UTF8Decode((LCLObject as TStatusBar).SimpleText);
    showMessage(@Text);
  end;
  }
end;

procedure TQtStatusBar.showMessage(text: PWideString; timeout: Integer);
begin
  QStatusBar_showMessage(QStatusBarH(Widget), text, timeout);
end;

{ TQtDialog }

constructor TQtDialog.Create(parent: QWidgetH; f: QtWindowFlags);
begin
  Widget := QDialog_create(parent, f);
end;

function TQtDialog.exec: Integer;
begin
  Result := QDialog_exec(QDialogH(Widget));
end;

{ TQtAbstractScrollArea }

{------------------------------------------------------------------------------
  Function: TQtAbstractScrollArea.CreateWidget
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
function TQtAbstractScrollArea.CreateWidget(const AParams: TCreateParams):QWidgetH;
var
  Parent: QWidgetH;
begin
  // Creates the widget
  {$ifdef VerboseQt}
    WriteLn('TQtAbstractScrollArea.Create');
  {$endif}
  FViewPortWidget := NiL;
  Parent := TQtWidget(LCLObject.Parent.Handle).GetContainerWidget;
  Result := QScrollArea_create(Parent);
  QWidget_setAttribute(Result, QtWA_NoMousePropagation);
end;

{------------------------------------------------------------------------------
  Function: TQtAbstractScrollArea.Destroy
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
destructor TQtAbstractScrollArea.Destroy;
begin
  {$ifdef VerboseQt}
    WriteLn('TQAbstractScrollArea.Destroy');
  {$endif}
  if Assigned(FViewPortWidget) then
    FViewPortWidget.Free;

  inherited Destroy;
end;

{------------------------------------------------------------------------------
  Function: TQtAbstractScrollArea.cornerWidget
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
function TQtAbstractScrollArea.cornerWidget: TQtWidget;
begin
  {$ifdef VerboseQt}
    WriteLn('TQAbstractScrollArea.cornerWidget');
  {$endif}
  Result := FCornerWidget;
end;

{------------------------------------------------------------------------------
  Function: TQtAbstractScrollArea.setColor
  Params:  TQtWidget
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtAbstractScrollArea.setColor(const Value: PQColor);
var
  Palette: QPaletteH;
begin
  Palette := QPalette_create(QWidget_palette(Widget));
  try
    QPalette_setColor(Palette, QPaletteBase, Value);
    QWidget_setPalette(Widget, Palette);
  finally
    QPalette_destroy(Palette);
  end;
end;

{------------------------------------------------------------------------------
  Function: TQtAbstractScrollArea.setCornerWidget
  Params:  TQtWidget
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtAbstractScrollArea.setCornerWidget(AWidget: TQtWidget);
begin
  {$ifdef VerboseQt}
    WriteLn('TQAbstractScrollArea.setCornerWidget');
  {$endif}
  FCornerWidget := AWidget;
  if Assigned(FCornerWidget) then
  QAbstractScrollArea_setCornerWidget(QAbstractScrollAreaH(Widget), FCornerWidget.Widget)
  else
  QAbstractScrollArea_setCornerWidget(QAbstractScrollAreaH(Widget), NiL);
end;

{------------------------------------------------------------------------------
  Function: TQtAbstractScrollArea.setTextColor
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtAbstractScrollArea.setTextColor(const Value: PQColor);
var
  Palette: QPaletteH;
begin
  Palette := QPalette_create(QWidget_palette(Widget));
  try
    QPalette_setColor(Palette, QPaletteText, Value);
    QWidget_setPalette(Widget, Palette);
  finally
    QPalette_destroy(Palette);
  end;
end;

{------------------------------------------------------------------------------
  Function: TQtAbstractScrollArea.setHorizontalScrollbar
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtAbstractScrollArea.setHorizontalScrollBar(AScrollBar: TQtScrollBar);
begin
  {$ifdef VerboseQt}
    WriteLn('TQAbstractScrollArea.setHorizontalScrollBar');
  {$endif}
  FHScrollbar := AScrollBar;
  if Assigned(FHScrollBar) then
  QAbstractScrollArea_setHorizontalScrollBar(QAbstractScrollAreaH(Widget), QScrollBarH(FHScrollBar.Widget));
end;

{------------------------------------------------------------------------------
  Function: TQtAbstractScrollArea.setVerticalScrollbar
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtAbstractScrollArea.setVerticalScrollBar(AScrollBar: TQtScrollBar);
begin
  {$ifdef VerboseQt}
    WriteLn('TQAbstractScrollArea.setVerticalScrollBar');
  {$endif}
  FVScrollBar := AScrollBar;
  if Assigned(FVScrollBar) then
  QAbstractScrollArea_setVerticalScrollBar(QAbstractScrollAreaH(Widget), QScrollBarH(FVScrollBar.Widget));
end;

procedure TQtAbstractScrollArea.setVisible(visible: Boolean);
begin
  inherited setVisible(visible);
  if FViewPortWidget <> nil then
    FViewPortWidget.setVisible(visible);
end;

{------------------------------------------------------------------------------
  Function: TQtAbstractScrollArea.horizontalScrollbar
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
function TQtAbstractScrollArea.horizontalScrollBar: TQtScrollBar;
begin
  {$ifdef VerboseQt}
    WriteLn('TQAbstractScrollArea.horizontalScrollBar');
  {$endif}
  Result := FHScrollBar;
end;

{------------------------------------------------------------------------------
  Function: TQtAbstractScrollArea.verticalScrollbar
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
function TQtAbstractScrollArea.verticalScrollBar: TQtScrollBar;
begin
  {$ifdef VerboseQt}
    WriteLn('TQAbstractScrollArea.verticalScrollBar');
  {$endif}
  Result := FVScrollBar;
end;

{------------------------------------------------------------------------------
  Function: TQtAbstractScrollArea.viewport
  Params:  None
  Returns: viewport widget of QAbstractScrollArea
 ------------------------------------------------------------------------------}
function TQtAbstractScrollArea.viewport: TQtWidget;
begin
  viewportNeeded;
  Result := FViewPortWidget;
end;

function TQtAbstractScrollArea.getClientBounds: TRect;
var
  R: TRect;
begin
  Result := inherited getClientBounds;
  if (FVScrollbar <> nil) and (FVScrollbar.getVisible) then
  begin
    R := FVScrollbar.getGeometry;
    dec(Result.Right, R.Right - R.Left);
  end;
  if (FHScrollbar <> nil) and (FHScrollbar.getVisible) then
  begin
    R := FHScrollbar.getGeometry;
    dec(Result.Bottom, R.Bottom - R.Top);
  end;
end;

{------------------------------------------------------------------------------
  Function: TQtAbstractScrollArea.viewportNeeded
  Params:  None
  Returns: Nothing
           Creates viewport widget for QAbstractScrollArea
 ------------------------------------------------------------------------------}
procedure TQtAbstractScrollArea.viewportNeeded;
var
  AParams: TCreateParams;
begin
  if FViewPortWidget <> niL then
    exit;

  FillChar(AParams, SizeOf(AParams), #0);
  FViewPortWidget := TQtWidget.Create(LCLObject, AParams);
  FViewPortWidget.AttachEvents;
  
  QAbstractScrollArea_setViewport(QAbstractScrollAreaH(Widget), FViewPortWidget.Widget);
end;

{------------------------------------------------------------------------------
  Function: TQtAbstractScrollArea.setScrollStyle
  Params:  None
  Returns: Nothing
           Setting scrollbar''s policy (LCL TScrollStyle)
 -----------------------------------------------------------------------------}
procedure TQtAbstractScrollArea.setScrollStyle(AScrollStyle: TScrollStyle);
begin
  {$ifdef VerboseQt}
    WriteLn('TQAbstractScrollArea.setScrollStyle');
  {$endif}
  case AScrollStyle of
    ssNone:
    begin
      QAbstractScrollArea_setVerticalScrollBarPolicy(QAbstractScrollAreaH(Widget), QtScrollBarAlwaysOff);
      QAbstractScrollArea_setHorizontalScrollBarPolicy(QAbstractScrollAreaH(Widget), QtScrollBarAlwaysOff);
    end;
    ssHorizontal:
    begin
      QAbstractScrollArea_setHorizontalScrollBarPolicy(QAbstractScrollAreaH(Widget), QtScrollBarAlwaysOn);
    end;
    ssVertical:
    begin
     QAbstractScrollArea_setVerticalScrollBarPolicy(QAbstractScrollAreaH(Widget), QtScrollBarAlwaysOn);
    end;
    ssBoth:
    begin
      QAbstractScrollArea_setVerticalScrollBarPolicy(QAbstractScrollAreaH(Widget), QtScrollBarAlwaysOn);
      QAbstractScrollArea_setHorizontalScrollBarPolicy(QAbstractScrollAreaH(Widget), QtScrollBarAlwaysOn);
    end;
    ssAutoHorizontal:
    begin
      QAbstractScrollArea_setHorizontalScrollBarPolicy(QAbstractScrollAreaH(Widget), QtScrollBarAsNeeded);
    end;
    ssAutoVertical:
    begin
      QAbstractScrollArea_setVerticalScrollBarPolicy(QAbstractScrollAreaH(Widget), QtScrollBarAsNeeded);
    end;
    ssAutoBoth:
    begin
      QAbstractScrollArea_setHorizontalScrollBarPolicy(QAbstractScrollAreaH(Widget), QtScrollBarAsNeeded);
      QAbstractScrollArea_setVerticalScrollBarPolicy(QAbstractScrollAreaH(Widget), QtScrollBarAsNeeded);
    end;
  end;
end;

  { TQtCalendar }

{------------------------------------------------------------------------------
  Function: TQtCalendar.CreateWidget
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
function TQtCalendar.CreateWidget(const AParams: TCreateParams):QWidgetH;
var
  Parent: QWidgetH;
begin
  // Creates the widget
  {$ifdef VerboseQt}
    WriteLn('TQtCalendar.Create');
  {$endif}
  Parent := TQtWidget(LCLObject.Parent.Handle).GetContainerWidget;
  Result := QCalendarWidget_create(Parent);
end;

procedure TQtCalendar.AttachEvents;
var
  Method: TMethod;
begin
  inherited AttachEvents;

  FClickedHook := QCalendarWidget_hook_create(Widget);
  FActivatedHook := QCalendarWidget_hook_create(Widget);
  FSelectionChangedHook := QCalendarWidget_hook_create(Widget);
  FCurrentPageChangedHook := QCalendarWidget_hook_create(Widget);
  
  QCalendarWidget_clicked_Event(Method) := SignalClicked;
  QCalendarWidget_hook_hook_clicked(FClickedHook, Method);

  QCalendarWidget_activated_Event(Method) := SignalActivated;
  QCalendarWidget_hook_hook_activated(FActivatedHook, Method);

  QCalendarWidget_selectionChanged_Event(Method) := SignalSelectionChanged;
  QCalendarWidget_hook_hook_selectionChanged(FSelectionChangedHook, Method);

  QCalendarWidget_currentPageChanged_Event(Method) := SignalCurrentPageChanged;
  QCalendarWidget_hook_hook_currentPageChanged(FCurrentPageChangedHook, Method);
end;

procedure TQtCalendar.DetachEvents;
begin
  QCalendarWidget_hook_destroy(FClickedHook);
  QCalendarWidget_hook_destroy(FActivatedHook);
  QCalendarWidget_hook_destroy(FSelectionChangedHook);
  QCalendarWidget_hook_destroy(FCurrentPageChangedHook);
  inherited DetachEvents;
end;

{------------------------------------------------------------------------------
  Function: TQtCalendar.SignalActivated
  Params:  None
  Returns: Nothing
           Sends signal when RETURN pressed on selected date.
 ------------------------------------------------------------------------------}
procedure TQtCalendar.SignalActivated(ADate: QDateH); cdecl;
var
  Msg: TLMessage;
  y,m,d: Integer;
begin
  {this one triggers if we press RETURN on selected date
   shell we send KeyDown here ?!?}
  FillChar(Msg, SizeOf(Msg), #0);
  Msg.Msg := LM_DAYCHANGED;
  y := QDate_year(ADate);
  m := QDate_month(ADate);
  d := QDate_day(ADate);
  if (y <> aYear) or (m <> aMonth)
  or (d <> aDay) then
  DeliverMessage(Msg);
end;

{------------------------------------------------------------------------------
  Function: TQtCalendar.SignalClicked
  Params:  None
  Returns: Nothing
           Sends msg LM_DAYCHANGED when OldDate<>NewDate
 ------------------------------------------------------------------------------}
procedure TQtCalendar.SignalClicked(ADate: QDateH); cdecl;
var
  Msg: TLMessage;
  y,m,d: Integer;
begin
//  writeln('TQtCalendar.signalClicked');
  FillChar(Msg, SizeOf(Msg), #0);
  Msg.Msg := LM_DAYCHANGED;
  y := QDate_year(ADate);
  m := QDate_month(ADate);
  d := QDate_day(ADate);
  if (y <> aYear) or (m <> aMonth)
  or (d <> aDay) then
  DeliverMessage(Msg);
end;

{------------------------------------------------------------------------------
  Function: TQtCalendar.SignalSelectionChanged
  Params:  None
  Returns: Nothing

  Notes: no event for date changed by keyboard ?!?
   always triggers even if selection isn't changed ...
   this is not Qt4 bug ... tested with pure Qt C++ app
 ------------------------------------------------------------------------------}
procedure TQtCalendar.SignalSelectionChanged; cdecl;
var
  Msg: TLMessage;
begin
//  writeln('TQtCalendar.SignalSelectionChanged');

  FillChar(Msg, SizeOf(Msg), #0);
  Msg.Msg := LM_DAYCHANGED;
  DeliverMessage(Msg);
end;

{------------------------------------------------------------------------------
  Function: TQtCalendar.SignalCurrentPageChanged
  Params:  None
  Returns: Nothing

  Notes: fixme what's wrong with those values ?!?
   with pure Qt C++ app this works ok, but via bindings get
   impossible year & month values ...
 ------------------------------------------------------------------------------}
procedure TQtCalendar.SignalCurrentPageChanged(p1, p2: Integer); cdecl;
var
  Msg: TLMessage;
begin
  // writeln('TQtCalendar.SignalCurrentPageChanged p1=',p1,' p2=',p2);

  FillChar(Msg, SizeOf(Msg), #0);
  if AYear<>p1 then
  begin
    Msg.Msg := LM_YEARCHANGED;
    DeliverMessage(Msg);
  end;

  if AMonth<>p2 then
  begin
    Msg.Msg := LM_MONTHCHANGED;
    DeliverMessage(Msg);
  end;
end;

{ TQtHintWindow }

function TQtHintWindow.CreateWidget(const AParams: TCreateParams): QWidgetH;
begin
  Result := QWidget_create(nil, QtToolTip);
  MenuBar := nil;
end;

{ TQtPage }

function TQtPage.CreateWidget(const AParams: TCreateParams): QWidgetH;
begin
  Result := QWidget_create;
  QWidget_setAttribute(Result, QtWA_NoMousePropagation);
end;

{ TQtAbstractItemView }

function TQtAbstractItemView.GetOwnerDrawn: Boolean;
begin
  Result := FNewDelegate <> nil;
end;

procedure TQtAbstractItemView.SetOwnerDrawn(const AValue: Boolean);
var
  Method: TMethod;
begin
  if AValue and (FNewDelegate = nil) then
  begin
    FNewDelegate := QLCLItemDelegate_create(Widget);

    QLCLItemDelegate_sizeHint_Override(Method) := ItemDelegateSizeHint;
    QLCLItemDelegate_override_sizeHint(FNewDelegate, Method);

    QLCLItemDelegate_paint_Override(Method) := ItemDelegatePaint;
    QLCLItemDelegate_override_Paint(FNewDelegate, Method);

    FOldDelegate := QAbstractItemView_itemDelegate(QAbstractItemViewH(Widget));
    QAbstractItemView_setItemDelegate(QAbstractItemViewH(Widget), FNewDelegate);
  end
  else
  if ((not AValue) and (FNewDelegate <> nil)) then
  begin
    QAbstractItemView_setItemDelegate(QAbstractItemViewH(Widget), FOldDelegate);
    QLCLItemDelegate_destroy(FNewDelegate);
    FNewDelegate := nil;
  end;
end;

constructor TQtAbstractItemView.Create(const AWinControl: TWinControl;
  const AParams: TCreateParams);
begin
  inherited Create(AWinControl, AParams);
  FOldDelegate := nil;
  FNewDelegate := nil;
end;

procedure TQtAbstractItemView.modelIndex(retval: QModelIndexH; row, column: Integer; parent: QModelIndexH = nil);
var
  AModel: QAbstractItemModelH;
begin
  AModel := QAbstractItemView_model(QAbstractItemViewH(Widget));
  QAbstractItemModel_index(AModel, retval, row, column, parent);
end;

function TQtAbstractItemView.visualRect(Index: QModelIndexH): TRect;
begin
  QAbstractItemView_visualRect(QAbstractItemViewH(Widget), @Result, Index);
end;

procedure TQtAbstractItemView.ItemDelegateSizeHint(
  option: QStyleOptionViewItemH; index: QModelIndexH; Size: PSize); cdecl;
var
  Msg: TLMMeasureItem;
  MeasureItemStruct: TMeasureItemStruct;
begin
  MeasureItemStruct.itemID := QModelIndex_row(index);
  MeasureItemStruct.itemWidth := Size^.cx;
  MeasureItemStruct.itemHeight := Size^.cy;
  Msg.Msg := LM_MEASUREITEM;
  Msg.MeasureItemStruct := @MeasureItemStruct;
  DeliverMessage(Msg);
  Size^.cx := MeasureItemStruct.itemWidth;
  Size^.cy := MeasureItemStruct.itemHeight;
end;

procedure TQtAbstractItemView.ItemDelegatePaint(painter: QPainterH;
  option: QStyleOptionViewItemH; index: QModelIndexH); cdecl;
begin
  // should be overrided
end;

{ TQtRubberBand }

function TQtRubberBand.CreateWidget(const AParams: TCreateParams): QWidgetH;
begin
  Result := QRubberBand_create(FShape);
end;

constructor TQtRubberBand.Create(const AWinControl: TWinControl;
  const AParams: TCreateParams);
begin
  FShape := QRubberBandLine;
  inherited Create(AWinControl, AParams);
end;

function TQtRubberBand.getShape: QRubberBandShape;
begin
  Result := QRubberBand_shape(QRubberBandH(Widget));
end;

procedure TQtRubberBand.setShape(AShape: QRubberBandShape);
begin
  if getShape <> AShape then
  begin
    // recreate widget
    FShape := AShape;
    RecreateWidget;
    AttachEvents;
  end;
end;

end.
