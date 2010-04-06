unit QtThemes;

{$mode objfpc}{$H+}

interface

{$I qtdefines.inc}

uses
  // rtl
  Types, Classes, SysUtils,
  // qt bindings
  qt4,
  // lcl
  LCLType, LCLProc, LCLIntf, Graphics, Themes, TmSchema,
  // widgetset
  InterfaceBase, QtObjects
  ;
  
type
  TQtDrawVariant =
  (
    qdvNone,
    qdvPrimitive,
    qdvControl,
    qdvComplexControl,
    qdvStandardPixmap
  );
  TQtDrawElement = record
    case DrawVariant: TQtDrawVariant of
      qdvPrimitive:
        (PrimitiveElement: QStylePrimitiveElement);
      qdvControl:
        (ControlElement: QStyleControlElement);
      qdvComplexControl:
        (ComplexControl: QStyleComplexControl;
         SubControls: QStyleSubControls;
         Features: Cardinal);
      qdvStandardPixmap:
        (StandardPixmap: QStyleStandardPixmap);
  end;

  { TQtThemeServices }
  
  TQtThemeServices = class(TThemeServices)
  private
    FStyle: QStyleH;
    function GetStyle: QStyleH;
  protected
    function InitThemes: Boolean; override;
    function UseThemes: Boolean; override;
    function ThemedControlsEnabled: Boolean; override;
    procedure InternalDrawParentBackground(Window: HWND; Target: HDC; Bounds: PRect); override;
    
    function GetControlState(Details: TThemedElementDetails): QStyleState;
    function GetDrawElement(Details: TThemedElementDetails): TQtDrawElement;
    property Style: QStyleH read GetStyle;
  public
    procedure DrawElement(DC: HDC; Details: TThemedElementDetails; const R: TRect; ClipRect: PRect); override;
    procedure DrawEdge(DC: HDC; Details: TThemedElementDetails; const R: TRect; Edge, Flags: Cardinal; AContentRect: PRect); override;
    procedure DrawIcon(DC: HDC; Details: TThemedElementDetails; const R: TRect; himl: HIMAGELIST; Index: Integer); override;
    function GetDetailSize(Details: TThemedElementDetails): TSize; override;
    function GetStockImage(StockID: LongInt; out Image, Mask: HBitmap): Boolean; override;

    function ContentRect(DC: HDC; Details: TThemedElementDetails; BoundingRect: TRect): TRect; override;
    function HasTransparentParts(Details: TThemedElementDetails): Boolean; override;
  end;

implementation

{ TQtThemeServices }

function TQtThemeServices.GetStyle: QStyleH;
begin
  FStyle := QApplication_style();
  Result := FStyle;
end;

function TQtThemeServices.InitThemes: Boolean;
begin
  FStyle := nil;
  Result := True;
end;

function TQtThemeServices.UseThemes: Boolean;
begin
  Result := True;
end;

function TQtThemeServices.ThemedControlsEnabled: Boolean;
begin
  Result := True;
end;

function TQtThemeServices.ContentRect(DC: HDC;
  Details: TThemedElementDetails; BoundingRect: TRect): TRect;
begin
  Result := BoundingRect;
  InflateRect(Result, -1, -1);
end;

procedure TQtThemeServices.DrawEdge(DC: HDC;
  Details: TThemedElementDetails; const R: TRect; Edge, Flags: Cardinal;
  AContentRect: PRect);
begin

end;

procedure TQtThemeServices.DrawElement(DC: HDC;
  Details: TThemedElementDetails; const R: TRect; ClipRect: PRect);
var
  Context: TQtDeviceContext absolute DC;
  opt: QStyleOptionH;
  ARect: TRect;
  AIcon: QIconH;
  Element: TQtDrawElement;
  Features: QStyleOptionButtonButtonFeatures;
  Position: QStyleOptionHeaderSectionPosition;
  Palette: QPaletteH;
  AColor: TQColor;
  ABrush: QBrushH;
  W: QWidgetH;
  AViewportPaint: Boolean = false;
begin
  if (Context <> nil) then
  begin
    Context.save;
    try
      if Context.Parent <> nil then
      begin
        W := QWidget_parentWidget(Context.Parent);
        if (W <> nil) and QObject_inherits(W,'QAbstractScrollArea') then
        begin
          {do not set any palette on QAbstractScrollArea viewport ! }
          AViewportPaint := True;
        end else
        begin
          Palette := QWidget_palette(Context.Parent);
          QPainter_setBackground(Context.Widget, QPalette_background(Palette));
        end;
      end else
      begin
        Palette := QPalette_create();
        QApplication_palette(Palette);
        QPainter_setBackground(Context.Widget, QPalette_background(Palette));
        QPalette_destroy(Palette);
      end;

      if HasTransparentParts(Details) then
        QPainter_setBackgroundMode(Context.Widget, QtTransparentMode);

      ARect := R;
      Element := GetDrawElement(Details);
      case Element.DrawVariant of
        qdvNone:
          inherited DrawElement(DC, Details, R, ClipRect);
        qdvControl:
        begin
          if (Element.ControlElement in [QStyleCE_PushButton, QStyleCE_RadioButton, QStyleCE_CheckBox]) then
          begin
            opt := QStyleOptionButton_create();
            Features := QStyleOptionButtonNone;
            if Details.Element = teToolBar then
              Features := Features or QStyleOptionButtonFlat;
            QStyleOptionButton_setFeatures(QStyleOptionButtonH(opt), Features);
          end
          else
          if (Element.ControlElement = QStyleCE_HeaderSection) then
          begin
            opt := QStyleOptionHeader_create();
            case Details.Part of
              HP_HEADERITEM: Position := QStyleOptionHeaderMiddle;
              HP_HEADERITEMLEFT: Position := QStyleOptionHeaderBeginning;
              HP_HEADERITEMRIGHT: Position := QStyleOptionHeaderEnd;
            end;
            QStyleOptionHeader_setPosition(QStyleOptionHeaderH(opt), Position);
            QStyleOptionHeader_setOrientation(QStyleOptionHeaderH(opt), QtHorizontal);
          end
          else
            opt := QStyleOptionComplex_create(LongInt(QStyleOptionVersion), LongInt(QStyleOptionSO_Default));

          QStyleOption_setState(opt, GetControlState(Details));
          QStyleOption_setRect(opt, @ARect);

          QStyle_drawControl(Style, Element.ControlElement, opt, Context.Widget);
          QStyleOption_Destroy(opt);
        end;
        qdvComplexControl:
        begin
          case Element.ComplexControl of
            QStyleCC_ToolButton:
            begin
              opt := QStyleOptionToolButton_create();
              QStyleOptionToolButton_setFeatures(QStyleOptionToolButtonH(opt),
                Element.Features);
            end;
            QStyleCC_ComboBox:
            begin
              opt := QStyleOptionComboBox_create();
            end;
            QStyleCC_TitleBar, QStyleCC_MdiControls:
            begin
              opt := QStyleOptionTitleBar_create();
              QStyleOptionTitleBar_setTitleBarFlags(QStyleOptionTitleBarH(opt),
                QtWindow or QtWindowSystemMenuHint);
              // workaround: qt has own minds about position of requested part -
              // but we need a way to draw it at our position
              Context.translate(ARect.Left, ARect.Top);
              OffsetRect(ARect, -ARect.Left, -ARect.Top);
            end;
            QStyleCC_Slider, QStyleCC_ScrollBar:
            begin
              opt := QStyleOptionSlider_create();
              QStyleOptionSlider_setMinimum(QStyleOptionSliderH(opt), 0);
              QStyleOptionSlider_setMaximum(QStyleOptionSliderH(opt), 100);
            end;
          else
            opt := QStyleOptionComplex_create(LongInt(QStyleOptionVersion),
              LongInt(QStyleOptionSO_Default));
          end;

          if Element.SubControls > QStyleSC_None then
            QStyleOptionComplex_setSubControls(QStyleOptionComplexH(opt),
              Element.SubControls);

          QStyleOption_setState(opt, GetControlState(Details));
          QStyleOption_setRect(opt, @ARect);
          QStyle_drawComplexControl(Style, Element.ComplexControl,
            QStyleOptionComplexH(opt), Context.Widget);
          QStyleOption_Destroy(opt);
        end;
        qdvPrimitive:
        begin
          case Element.PrimitiveElement of
            QStylePE_FrameTabWidget:
              begin
                opt := QStyleOptionTabWidgetFrame_create();
                // need widget to draw gradient
              end;
            QStylePE_PanelTipLabel:
              begin
                opt := QStyleOptionFrame_create();
              end;
              QStylePE_IndicatorBranch:
              begin
                opt := QStyleOption_create(Integer(QStyleOptionVersion),
                  Integer(QStyleOptionSO_Default));
                if AViewPortPaint then
                begin
                  {we must reinitialize QPainter brush from opt since
                  it isn't property initialised, also we must fillrect
                  because dots are visible inside branch}
                  QStyleOption_initFrom(opt, Context.Parent);
                  Palette := QPalette_create();
                  QStyleOption_palette(opt, Palette);
                  Context.FillRect(ARect.Left, ARect.Top,
                    ARect.Right - ARect.Left,
                    ARect.Bottom - ARect.Top);
                  AColor := QPalette_color(Palette, QPaletteBackground)^;
                  ABrush := QBrush_create(QPainter_brush(Context.Widget));
                  QBrush_setColor(ABrush, @AColor);
                  QBrush_setStyle(ABrush, QtNoBrush);
                  QPainter_setBrush(Context.Widget, ABrush);
                  QPalette_destroy(Palette);
                  QBrush_destroy(ABrush);
                end;
              end;
            else
              opt := QStyleOption_create(Integer(QStyleOptionVersion), Integer(QStyleOptionSO_Default));
          end;
          QStyleOption_setState(opt, GetControlState(Details));
          QStyleOption_setRect(opt, @ARect);
          QStyle_drawPrimitive(Style, Element.PrimitiveElement, opt, Context.Widget);
          QStyleOption_Destroy(opt);
        end;
        qdvStandardPixmap:
        begin
          opt := QStyleOption_create(Integer(QStyleOptionVersion), Integer(QStyleOptionSO_Default));
          AIcon := QIcon_create();
          QStyle_standardIcon(Style, AIcon, Element.StandardPixmap, opt);
          QIcon_paint(AIcon, Context.Widget, ARect.Left, ARect.Top,
            ARect.Right - ARect.Left, ARect.Bottom - ARect.Top);
          QIcon_destroy(AIcon);
          QStyleOption_Destroy(opt);
        end;
      end;
    finally
      Context.restore;
    end;
  end;
end;

procedure TQtThemeServices.DrawIcon(DC: HDC;
  Details: TThemedElementDetails; const R: TRect; himl: HIMAGELIST;
  Index: Integer);
begin

end;

function TQtThemeServices.HasTransparentParts(Details: TThemedElementDetails): Boolean;
begin
  Result := True;
end;

procedure TQtThemeServices.InternalDrawParentBackground(Window: HWND;
  Target: HDC; Bounds: PRect);
begin
  // ?
end;

function TQtThemeServices.GetControlState(Details: TThemedElementDetails): QStyleState;
begin
{
  QStyleState_None
  QStyleState_Enabled
  QStyleState_Raised
  QStyleState_Sunken
  QStyleState_Off
  QStyleState_NoChange
  QStyleState_On
  QStyleState_DownArrow
  QStyleState_Horizontal
  QStyleState_HasFocus
  QStyleState_Top
  QStyleState_Bottom
  QStyleState_FocusAtBorder
  QStyleState_AutoRaise
  QStyleState_MouseOver
  QStyleState_UpArrow
  QStyleState_Selected
  QStyleState_Active
  QStyleState_Open
  QStyleState_Children
  QStyleState_Item
  QStyleState_Sibling
  QStyleState_Editing
  QStyleState_KeyboardFocusChange
  QStyleState_ReadOnly
}
  Result := QStyleState_None;
  
  if not IsDisabled(Details) then
    Result := Result or QStyleState_Enabled;

  if IsHot(Details) then
    Result := Result or QStyleState_MouseOver;

  if IsPushed(Details) then
    Result := Result or QStyleState_Sunken;

  if IsMixed(Details) then
    Result := Result or QStyleState_NoChange
  else
  if IsChecked(Details) then
    Result := Result or QStyleState_On
  else
    Result := Result or QStyleState_Off;

  // specific states
  {when toolbar = flat, toolbar buttons should be flat too.}
  if (Details.Element = teToolBar) and
     (Details.State in [TS_NORMAL, TS_DISABLED]) then
    Result := QStyleState_AutoRaise;

  // define orientations
  if ((Details.Element = teRebar) and (Details.Part = RP_GRIPPER)) or
     ((Details.Element = teToolBar) and (Details.Part = TP_SEPARATOR)) or
     ((Details.Element = teScrollBar) and (Details.Part in [SBP_UPPERTRACKHORZ, SBP_LOWERTRACKHORZ, SBP_THUMBBTNHORZ, SBP_GRIPPERHORZ])) then
    Result := Result or QStyleState_Horizontal;

  if (Details.Element = teTreeview) and (Details.Part = TVP_GLYPH) then
  begin
    Result := Result or QStyleState_Children;
    if Details.State = GLPS_OPENED then
      Result := Result or QStyleState_Open;
  end;
end;

function TQtThemeServices.GetDetailSize(Details: TThemedElementDetails): TSize;
begin
  case Details.Element of
    teRebar :
      if Details.Part in [RP_GRIPPER, RP_GRIPPERVERT] then
        Result := Size(-1, -1);
    else
      Result := inherited;
  end;
end;

function TQtThemeServices.GetStockImage(StockID: LongInt; out Image,
  Mask: HBitmap): Boolean;
var
  APixmap: QPixmapH;
  AImage: QImageH;
  AStdPixmap: QStyleStandardPixmap;
  opt: QStyleOptionH;
begin
  case StockID of
    idButtonOk: AStdPixmap := QStyleSP_DialogOkButton;
    idButtonCancel: AStdPixmap := QStyleSP_DialogCancelButton;
    idButtonYes: AStdPixmap := QStyleSP_DialogYesButton;
    idButtonYesToAll: AStdPixmap := QStyleSP_DialogYesButton;
    idButtonNo: AStdPixmap := QStyleSP_DialogNoButton;
    idButtonNoToAll: AStdPixmap := QStyleSP_DialogNoButton;
    idButtonHelp: AStdPixmap := QStyleSP_DialogHelpButton;
    idButtonClose: AStdPixmap := QStyleSP_DialogCloseButton;
    idButtonAbort: AStdPixmap := QStyleSP_DialogResetButton;
    idButtonAll: AStdPixmap := QStyleSP_DialogApplyButton;
    idButtonIgnore: AStdPixmap := QStyleSP_DialogDiscardButton;
    idButtonRetry: AStdPixmap := QStyleSP_BrowserReload; // ?
    idButtonOpen: AStdPixmap := QStyleSP_DialogOpenButton;
    idButtonSave: AStdPixmap := QStyleSP_DialogSaveButton;
    idButtonShield: AStdPixmap := QStyleSP_VistaShield;

    idDialogWarning : AStdPixmap := QStyleSP_MessageBoxWarning;
    idDialogError: AStdPixmap := QStyleSP_MessageBoxCritical;
    idDialogInfo: AStdPixmap := QStyleSP_MessageBoxInformation;
    idDialogConfirm: AStdPixmap := QStyleSP_MessageBoxQuestion;
  else
    begin
       Result := inherited GetStockImage(StockID, Image, Mask);
       Exit;
    end;
  end;

  opt := QStyleOption_create(Integer(QStyleOptionVersion), Integer(QStyleOptionSO_Default));
  APixmap := QPixmap_create();
  QStyle_standardPixmap(QApplication_style(), APixmap, AStdPixmap, opt);
  QStyleOption_Destroy(opt);

  if QPixmap_isNull(APixmap) then
  begin
    QPixmap_destroy(APixmap);
    Result := inherited GetStockImage(StockID, Image, Mask);
    Exit;
  end;

  // convert from what we have to QImageH
  AImage := QImage_create();
  QPixmap_toImage(APixmap, AImage);
  QPixmap_destroy(APixmap);
  Image := HBitmap(TQtImage.Create(AImage));
  Mask := 0;
  Result := True;
end;

function TQtThemeServices.GetDrawElement(Details: TThemedElementDetails): TQtDrawElement;
const
  ButtonMap: array[BP_PUSHBUTTON..BP_USERBUTTON] of QStyleControlElement =
  (
{BP_PUSHBUTTON } QStyleCE_PushButton,
{BP_RADIOBUTTON} QStyleCE_RadioButton,
{BP_CHECKBOX   } QStyleCE_CheckBox,
{BP_GROUPBOX   } QStyleCE_PushButton,
{BP_USERBUTTON } QStyleCE_PushButton
  );
begin
  Result.DrawVariant := qdvNone;
  case Details.Element of
    teButton:
      begin
        if Details.Part <> BP_GROUPBOX then
        begin
          Result.DrawVariant := qdvControl;
          Result.ControlElement := ButtonMap[Details.Part]
        end
        else
        begin
          Result.DrawVariant := qdvComplexControl;
          Result.ComplexControl := QStyleCC_GroupBox;
          Result.SubControls := QStyleSC_GroupBoxFrame;
        end;
      end;
    teComboBox:
      begin
        if Details.Part = CP_DROPDOWNBUTTON then
        begin
          Result.DrawVariant := qdvComplexControl;
          Result.ComplexControl := QStyleCC_ComboBox;
          Result.SubControls := QStyleSC_ComboBoxArrow;
        end;
      end;
    teHeader:
      begin
        case Details.Part of
          HP_HEADERITEM,
          HP_HEADERITEMLEFT,
          HP_HEADERITEMRIGHT:
            begin
              Result.DrawVariant := qdvControl;
              Result.ControlElement := QStyleCE_HeaderSection;
            end;
          HP_HEADERSORTARROW:
            begin
              Result.DrawVariant := qdvPrimitive;
              Result.PrimitiveElement := QStylePE_IndicatorHeaderArrow;
            end;
        end;
      end;
    teToolBar:
      begin
        case Details.Part of
          TP_BUTTON,
          TP_DROPDOWNBUTTON,
          TP_SPLITBUTTON: // there is another positibility to draw TP_SPLITBUTTON by CC_ToolButton
            begin
              Result.DrawVariant := qdvPrimitive;
              Result.PrimitiveElement := QStylePE_PanelButtonTool;
            end;
          TP_SPLITBUTTONDROPDOWN:
            begin
              Result.DrawVariant := qdvComplexControl;
              Result.ComplexControl := QStyleCC_ToolButton;
              Result.SubControls := QStyleSC_None;
              Result.Features := QStyleOptionToolButtonMenuButtonPopup;
            end;
          TP_SEPARATOR,
          TP_SEPARATORVERT:
            begin
              Result.DrawVariant := qdvPrimitive;
              Result.PrimitiveElement := QStylePE_IndicatorToolBarSeparator;
            end;
        end;
      end;
    teRebar:
      begin
        case Details.Part of
          RP_GRIPPER, RP_GRIPPERVERT: // used in splitter
            begin
              Result.DrawVariant := qdvControl;
              Result.ControlElement := QStyleCE_Splitter;
            end;
        end;
      end;
    teWindow:
      begin
        case Details.Part of
          WP_SYSBUTTON: Result.SubControls := QStyleSC_TitleBarSysMenu;
          WP_MINBUTTON: Result.SubControls := QStyleSC_TitleBarMinButton;
          WP_MAXBUTTON: Result.SubControls := QStyleSC_TitleBarMaxButton;
          WP_CLOSEBUTTON: Result.SubControls := QStyleSC_TitleBarCloseButton;
          WP_SMALLCLOSEBUTTON: Result.SubControls := QStyleSC_TitleBarCloseButton;
          WP_RESTOREBUTTON: Result.SubControls := QStyleSC_TitleBarNormalButton;
          WP_HELPBUTTON: Result.SubControls := QStyleSC_TitleBarContextHelpButton;
          WP_MDIHELPBUTTON: Result.SubControls := QStyleSC_TitleBarContextHelpButton;
          WP_MDIMINBUTTON: Result.SubControls := QStyleSC_MdiMinButton;
          WP_MDICLOSEBUTTON: Result.SubControls := QStyleSC_MdiCloseButton;
          WP_MDIRESTOREBUTTON: Result.SubControls := QStyleSC_MdiNormalButton;
        else
          Result.SubControls := QStyleSC_None;
        end;

        if Result.SubControls >= QStyleSC_MdiMinButton then
          Result.ComplexControl := QStyleCC_MdiControls
        else
          Result.ComplexControl := QStyleCC_TitleBar;
          
        Result.DrawVariant := qdvComplexControl;
{
        // maybe through icon
        Result.DrawVariant := qdvStandardPixmap;
        case Details.Part of
          WP_MINBUTTON: Result.StandardPixmap := QStyleSP_TitleBarMinButton;
          WP_MDIMINBUTTON: Result.StandardPixmap := QStyleSP_TitleBarMinButton;
          WP_MAXBUTTON: Result.StandardPixmap := QStyleSP_TitleBarMaxButton;
          WP_CLOSEBUTTON: Result.StandardPixmap := QStyleSP_TitleBarCloseButton;
          WP_SMALLCLOSEBUTTON: Result.StandardPixmap := QStyleSP_TitleBarCloseButton;
          WP_MDICLOSEBUTTON: Result.StandardPixmap := QStyleSP_TitleBarCloseButton;
          WP_RESTOREBUTTON: Result.StandardPixmap := QStyleSP_TitleBarNormalButton;
          WP_MDIRESTOREBUTTON: Result.StandardPixmap := QStyleSP_TitleBarNormalButton;
          WP_HELPBUTTON: Result.StandardPixmap := QStyleSP_TitleBarContextHelpButton;
          WP_MDIHELPBUTTON: Result.StandardPixmap := QStyleSP_TitleBarContextHelpButton;
        else
          Result.StandardPixmap := QStyleSP_TitleBarCloseButton;
        end;
}
      end;
    teTab:
      begin
        if Details.Part = TABP_PANE then
        begin
          Result.DrawVariant := qdvPrimitive;
          Result.PrimitiveElement := QStylePE_FrameTabWidget;
        end;
      end;
    teScrollBar:
      begin
        Result.DrawVariant := qdvComplexControl;
        Result.ComplexControl := QStyleCC_ScrollBar;
        case Details.Part of
          SBP_ARROWBTN: Result.SubControls := QStyleSC_ScrollBarAddLine;
          SBP_THUMBBTNHORZ,
          SBP_THUMBBTNVERT,
          SBP_GRIPPERHORZ,
          SBP_GRIPPERVERT: Result.SubControls := QStyleSC_ScrollBarSlider;
          SBP_LOWERTRACKHORZ,
          SBP_LOWERTRACKVERT: Result.SubControls := QStyleSC_ScrollBarAddPage;
          SBP_UPPERTRACKHORZ,
          SBP_UPPERTRACKVERT: Result.SubControls := QStyleSC_ScrollBarSubPage;
        else
          Result.SubControls := QStyleSC_None;
        end;
      end;
    teStatus:
      begin
        case Details.Part of
          SP_PANE:
            begin
              Result.DrawVariant := qdvPrimitive;
              Result.PrimitiveElement := QStylePE_FrameStatusBar;
            end;
          SP_GRIPPER:
            begin
              Result.DrawVariant := qdvControl;
              Result.ControlElement := QStyleCE_SizeGrip;
            end;
        end;
      end;
    teTreeView:
      begin
        if Details.Part = TVP_GLYPH then
        begin
          Result.DrawVariant := qdvPrimitive;
          Result.PrimitiveElement := QStylePE_IndicatorBranch;
        end;
      end;
    teToolTip:
      begin
        if Details.Part = TTP_STANDARD then
        begin
          Result.DrawVariant := qdvPrimitive;
          Result.PrimitiveElement := QStylePE_PanelTipLabel;
        end;
      end;
  end;
end;

end.


