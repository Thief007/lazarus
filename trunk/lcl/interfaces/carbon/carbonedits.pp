{ $Id$
                  --------------------------------------------
                  carbonedits.pp  -  Carbon edit-like controls
                  --------------------------------------------

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
unit CarbonEdits;

{$mode objfpc}{$H+}

interface

// debugging defines
{$I carbondebug.inc}

uses
 // rtl+ftl
  Types, Classes, SysUtils, Math, Contnrs,
 // carbon bindings
  FPCMacOSAll,
 // LCL
  LMessages, LCLMessageGlue, LCLProc, LCLType, Graphics, Controls, StdCtrls,
 // widgetset
  WSControls, WSLCLClasses, WSProc,
 // LCL Carbon
  CarbonDef, CarbonPrivate, CarbonGDIObjects;
  
type

  { TCarbonControlWithEdit }

  TCarbonControlWithEdit = class(TCarbonControl)
  private
    FMaxLength: Integer;
  protected
    procedure LimitTextLength;
    procedure AdaptCharCase;
    class function GetEditPart: ControlPartCode; virtual;
    procedure RegisterEvents; override;
  public
    procedure TextDidChange; dynamic;
  public
    function GetSelStart(var ASelStart: Integer): Boolean;
    function GetSelLength(var ASelLength: Integer): Boolean;
    function SetSelStart(ASelStart: Integer): Boolean;
    function SetSelLength(ASelLength: Integer): Boolean;

    function GetText(var S: String): Boolean; override;
    function SetText(const S: String): Boolean; override;
  public
    property MaxLength: Integer read FMaxLength write FMaxLength;
    procedure SetReadOnly(AReadOnly: Boolean); virtual;
  end;

  { TCarbonComboBox }

  TCarbonComboBox = class(TCarbonControlWithEdit)
  private
    FItemIndex: Integer;
  protected
    procedure RegisterEvents; override;
    procedure CreateWidget(const AParams: TCreateParams); override;
    class function GetEditPart: ControlPartCode; override;
  public
    procedure ListItemSelected(AIndex: Integer); virtual;
  public
    function GetItemIndex: Integer;
    function SetItemIndex(AIndex: Integer): Boolean;
    
    procedure Insert(AIndex: Integer; const S: String);
    procedure Remove(AIndex: Integer);
    
    function DropDown(ADropDown: Boolean): Boolean;
  end;
  
  { TCarbonCustomEdit }

  TCarbonCustomEdit = class(TCarbonControlWithEdit)
  public
    procedure SetPasswordChar(AChar: Char); virtual; abstract;
  end;

  { TCarbonEdit }

  TCarbonEdit = class(TCarbonCustomEdit)
  private
    FIsPassword: Boolean;
  protected
    procedure CreateWidget(const AParams: TCreateParams); override;
  public
    function GetText(var S: String): Boolean; override;
    function SetText(const S: String): Boolean; override;
    procedure SetPasswordChar(AChar: Char); override;
  end;

  { TCarbonMemo }

  TCarbonMemo = class(TCarbonCustomEdit)
  private
    FScrollView: HIViewRef;
    FScrollBars: TScrollStyle;
    procedure SetScrollBars(const AValue: TScrollStyle);
  protected
    function GetFrame: ControlRef; override;
    function GetForceEmbedInScrollView: Boolean; override;
    procedure CreateWidget(const AParams: TCreateParams); override;
    procedure DestroyWidget; override;
  public
    procedure TextDidChange; override;
  public
    procedure SetColor(const AColor: TColor); override;
    procedure SetFont(const AFont: TFont); override;
    procedure SetPasswordChar(AChar: Char); override;
    procedure SetReadOnly(AReadOnly: Boolean); override;
    procedure SetWordWrap(AWordWrap: Boolean); virtual;
  public
    property ScrollBars: TScrollStyle read FScrollBars write SetScrollBars;
  end;

implementation

uses CarbonProc, CarbonDbgConsts, CarbonUtils, CarbonStrings, CarbonWSStdCtrls;

{ TCarbonControlWithEdit }

{------------------------------------------------------------------------------
  Name: CarbonTextField_DidChange
  Handles text change
 ------------------------------------------------------------------------------}
function CarbonTextField_DidChange(ANextHandler: EventHandlerCallRef;
  AEvent: EventRef;
  AWidget: TCarbonWidget): OSStatus; {$IFDEF darwin}mwpascal;{$ENDIF}
begin
  {$IFDEF VerboseControlEvent}
    DebugLn('CarbonTextField_DidChange: ', DbgSName(AWidget.LCLObject));
  {$ENDIF}

  Result := CallNextEventHandler(ANextHandler, AEvent);

  (AWidget as TCarbonControlWithEdit).TextDidChange;
end;

{------------------------------------------------------------------------------
  Method:  TCarbonControlWithEdit.LimitTextLength

  Limits the text length to maximum length
 ------------------------------------------------------------------------------}
procedure TCarbonControlWithEdit.LimitTextLength;
var
  S: String;
  R: Boolean;
  SelStart: Integer;
begin
  if MaxLength > 0 then
  begin
    if GetText(S) then
      if UTF8Length(S) > MaxLength then
      begin
        R := GetSelStart(SelStart);
        S := UTF8Copy(S, 1, MaxLength);
        if SetText(S) then
          if R then SetSelStart(SelStart);
      end;
  end;
end;

{------------------------------------------------------------------------------
  Method:  TCarbonControlWithEdit.AdaptCharCase

  Change text char case
 ------------------------------------------------------------------------------}
procedure TCarbonControlWithEdit.AdaptCharCase;
begin
  // TODO
end;

{------------------------------------------------------------------------------
  Method:  TCarbonControlWithEdit.GetEditPart
  Returns: Control part code of edit control
 ------------------------------------------------------------------------------}
class function TCarbonControlWithEdit.GetEditPart: ControlPartCode;
begin
  Result := kControlEntireControl;
end;

{------------------------------------------------------------------------------
  Method:  TCarbonControlWithEdit.RegisterEvents

  Registers event handlers for control with edit
 ------------------------------------------------------------------------------}
procedure TCarbonControlWithEdit.RegisterEvents;
var
  TmpSpec: EventTypeSpec;
begin
  inherited RegisterEvents;
  
  TmpSpec := MakeEventSpec(kEventClassTextField, kEventTextDidChange);
  InstallControlEventHandler(Widget,
    RegisterEventHandler(@CarbonTextField_DidChange),
    1, @TmpSpec, Pointer(Self), nil);
end;

{------------------------------------------------------------------------------
  Method:  TCarbonControlWithEdit.TextDidChange

  Text changed event handler
 ------------------------------------------------------------------------------}
procedure TCarbonControlWithEdit.TextDidChange;
var
  Msg: TLMessage;
begin
  // limit the text according to MaxLength
  LimitTextLength;

  // set char case TODO
  AdaptCharCase;

  FillChar(Msg, SizeOf(Msg), 0);
  Msg.Msg := CM_TEXTCHANGED;
  DeliverMessage(LCLObject, Msg);
end;

{------------------------------------------------------------------------------
  Method:  TCarbonControlWithEdit.GetSelStart
  Params:  ASelStart - Selection start
  Returns: If the function suceeds

  Gets the selection start from the edit part of control
 ------------------------------------------------------------------------------}
function TCarbonControlWithEdit.GetSelStart(var ASelStart: Integer): Boolean;
var
  SelData: ControlEditTextSelectionRec;
begin
  Result := False;
  
  if OSError(
    GetControlData(ControlRef(Widget), GetEditPart, kControlEditTextSelectionTag,
      SizeOf(ControlEditTextSelectionRec), @SelData, nil),
    Self, 'GetSelStart', SGetData) then Exit;

  ASelStart := SelData.SelStart;
  Result := True;
end;

{------------------------------------------------------------------------------
  Method:  TCarbonControlWithEdit.GetSelLength
  Params:  ASelLength - Selection length
  Returns: If the function suceeds

  Gets the selection length from the edit part of control
 ------------------------------------------------------------------------------}
function TCarbonControlWithEdit.GetSelLength(var ASelLength: Integer): Boolean;
var
  SelData: ControlEditTextSelectionRec;
begin
  Result := False;
  
  if OSError(
    GetControlData(ControlRef(Widget), GetEditPart, kControlEditTextSelectionTag,
    SizeOf(ControlEditTextSelectionRec), @SelData, nil),
    Self, 'GetSelLength', SGetData) then Exit;

  ASelLength := SelData.SelEnd - SelData.SelStart;
  Result := True;
end;

{------------------------------------------------------------------------------
  Method:  TCarbonControlWithEdit.SetSelStart
  Params:  ASelStart - Selection start
  Returns: If the function suceeds

  Sets the selection start of the edit part of control
 ------------------------------------------------------------------------------}
function TCarbonControlWithEdit.SetSelStart(ASelStart: Integer): Boolean;
var
  SelData: ControlEditTextSelectionRec;
const
  SName = 'SetSelStart';
begin
  Result := False;
  
  if OSError(
    GetControlData(ControlRef(Widget), GetEditPart, kControlEditTextSelectionTag,
      SizeOf(ControlEditTextSelectionRec), @SelData, nil),
    Self, SName, SGetData) then Exit;

  if SelData.SelStart = ASelStart then
  begin
    Result := True;
    Exit;
  end;

  SelData.SelEnd := (SelData.SelEnd - SelData.SelStart) + ASelStart;
  SelData.SelStart := ASelStart;
  
  if OSError(
    SetControlData(ControlRef(Widget), GetEditPart, kControlEditTextSelectionTag,
      SizeOf(ControlEditTextSelectionRec), @SelData),
    Self, SName, SSetData) then Exit;
      
  Result := True;
end;

{------------------------------------------------------------------------------
  Method:  TCarbonControlWithEdit.SetSelLength
  Params:  ASelLength - Selection length
  Returns: If the function suceeds

  Sets the selection length of the edit part of control
 ------------------------------------------------------------------------------}
function TCarbonControlWithEdit.SetSelLength(ASelLength: Integer): Boolean;
var
  SelData: ControlEditTextSelectionRec;
const
  SName = 'SetSelLength';
begin
  Result := False;

  if OSError(
    GetControlData(ControlRef(Widget), GetEditPart, kControlEditTextSelectionTag,
      SizeOf(ControlEditTextSelectionRec), @SelData, nil),
    Self, SName, SGetData) then Exit;

  if SelData.SelEnd = SelData.SelStart + ASelLength then
  begin
    Result := True;
    Exit;
  end;

  SelData.SelEnd := SelData.SelStart + ASelLength;
  
  if OSError(
    SetControlData(ControlRef(Widget), GetEditPart, kControlEditTextSelectionTag,
      SizeOf(ControlEditTextSelectionRec), @SelData),
    Self, SName, SSetData) then Exit;

  Result := True;
end;

{------------------------------------------------------------------------------
  Method:  TCarbonControlWithEdit.GetText
  Params:  S - Text
  Returns: If the function succeeds

  Gets the text of edit control
 ------------------------------------------------------------------------------}
function TCarbonControlWithEdit.GetText(var S: String): Boolean;
var
  CFString: CFStringRef;
begin
  Result := False;
  
  if OSError(
    GetControlData(ControlRef(Widget), GetEditPart, kControlEditTextCFStringTag,
      SizeOf(CFStringRef), @CFString, nil),
    Self, SGetText, SGetData) then Exit;
  try
    S := CFStringToStr(CFString);
    Result := True;
  finally
    FreeCFString(CFString);
  end;
end;

{------------------------------------------------------------------------------
  Method:  TCarbonControlWithEdit.SetText
  Params:  S - New text
  Returns: If the function succeeds

  Sets the text of edit control
 ------------------------------------------------------------------------------}
function TCarbonControlWithEdit.SetText(const S: String): Boolean;
var
  CFString: CFStringRef;
begin
  Result := False;
  
  CreateCFString(S, CFString);
  try
    if OSError(
      SetControlData(ControlRef(Widget), GetEditPart, kControlEditTextCFStringTag,
        SizeOf(CFStringRef), @CFString),
      Self, SSetText, SSetData) then Exit;
      
    Result := True;
  finally
    FreeCFString(CFString);
  end;
end;

{------------------------------------------------------------------------------
  Method:  TCarbonControlWithEdit.SetReadOnly
  Params:  AReadOnly - Read only behavior

  Sets the read only behavior of edit control
 ------------------------------------------------------------------------------}
procedure TCarbonControlWithEdit.SetReadOnly(AReadOnly: Boolean);
begin
  OSError(SetControlData(ControlRef(Widget), GetEditPart,
      kControlEditTextLockedTag, SizeOf(Boolean), @AReadOnly),
    Self, 'SetReadOnly', SSetData);
end;

{ TCarbonComboBox }

{------------------------------------------------------------------------------
  Name: CarbonComboBox_ListItemSelected
  Handles combo box list item change
 ------------------------------------------------------------------------------}
function CarbonComboBox_ListItemSelected(ANextHandler: EventHandlerCallRef;
  AEvent: EventRef;
  AWidget: TCarbonWidget): OSStatus; {$IFDEF darwin}mwpascal;{$ENDIF}
var
  Index: CFIndex;
begin
  {$IFDEF VerboseControlEvent}
    DebugLn('CarbonComboBox_ListItemSelected: ', DbgSName(AWidget.LCLObject));
  {$ENDIF}

  Result := CallNextEventHandler(ANextHandler, AEvent);

  // get selected item index
  if OSError(
    GetEventParameter(AEvent, kEventParamComboBoxListSelectedItemIndex,
      typeCFIndex, nil, SizeOf(CFIndex), nil, @Index),
    'CarbonComboBox_ListItemSelected', SGetEvent,
    'kEventParamComboBoxListSelectedItemIndex') then Index := -1;

  (AWidget as TCarbonComboBox).ListItemSelected(Index);
end;

{------------------------------------------------------------------------------
  Method:  TCarbonComboBox.RegisterEvents

  Registers event handlers for combo box
 ------------------------------------------------------------------------------}
procedure TCarbonComboBox.RegisterEvents;
var
  TmpSpec: EventTypeSpec;
begin
  inherited RegisterEvents;
  
  TmpSpec := MakeEventSpec(kEventClassHIComboBox, kEventComboBoxListItemSelected);
  InstallControlEventHandler(Widget,
    RegisterEventHandler(@CarbonComboBox_ListItemSelected),
    1, @TmpSpec, Pointer(Self), nil);
end;

{------------------------------------------------------------------------------
  Method:  TCarbonComboBox.CreateWidget
  Params:  AParams - Creation parameters

  Creates Carbon combo box
 ------------------------------------------------------------------------------}
procedure TCarbonComboBox.CreateWidget(const AParams: TCreateParams);
var
  Control: ControlRef;
  CFString: CFStringRef;
begin
  CreateCFString(AParams.Caption, CFString);
  try
    if OSError(HIComboBoxCreate(ParamsToHIRect(AParams), CFString, nil, nil,
        kHIComboBoxAutoSizeListAttribute, Control),
      Self, SCreateWidget, 'HIComboBoxCreate')then RaiseCreateWidgetError(LCLObject);

    Widget := Control;

    inherited;
  finally
    FreeCFString(CFString);
  end;
  
  FItemIndex := -1;
  FMaxLength := 0;
end;

{------------------------------------------------------------------------------
  Method:  TCarbonComboBox.GetEditPart
  Returns: Control part code of edit control
 ------------------------------------------------------------------------------}
class function TCarbonComboBox.GetEditPart: ControlPartCode;
begin
  Result := kHIComboBoxEditTextPart;
end;

{------------------------------------------------------------------------------
  Method:  TCarbonComboBox.ListItemSelected
  Params:  AIndex - Index of selected item

  List item selected event handler
 ------------------------------------------------------------------------------}
procedure TCarbonComboBox.ListItemSelected(AIndex: Integer);
begin
  FItemIndex := AIndex;
  LCLSendSelectionChangedMsg(LCLObject);
end;

{------------------------------------------------------------------------------
  Method:  TCarbonComboBox.GetItemIndex
  Returns: The current item selected index
 ------------------------------------------------------------------------------}
function TCarbonComboBox.GetItemIndex: Integer;
begin
  Result := FItemIndex;
end;

{------------------------------------------------------------------------------
  Method:  TCarbonComboBox.SetItemIndex
  Params:  AIndex - New item index
  
  Changes currently selected item
 ------------------------------------------------------------------------------}
function TCarbonComboBox.SetItemIndex(AIndex: Integer): Boolean;
begin
  Result := False;
  if AIndex <> FItemIndex then
  begin
    if AIndex = -1 then
    begin
      FItemIndex := -1;
      Result := SetText('');
    end
    else
    begin
      FItemIndex := AIndex;
      Result := SetText((LCLObject as TCustomComboBox).Items[AIndex]);
    end;
  end
  else Result := True;
end;

{------------------------------------------------------------------------------
  Method:  TCarbonComboBox.Insert
  Params:  AIndex - Item index
           S      - Item text

  Inserts item with the specified text at index
 ------------------------------------------------------------------------------}
procedure TCarbonComboBox.Insert(AIndex: Integer; const S: String);
var
  CFString: CFStringRef;
begin
  CreateCFString(S, CFString);
  try
    OSError(HIComboBoxInsertTextItemAtIndex(HIViewRef(Widget), AIndex, CFString),
      Self, 'Insert', 'HIComboBoxInsertTextItemAtIndex');
  finally
    FreeCFString(CFString);
  end;
end;

{------------------------------------------------------------------------------
  Method:  TCarbonComboBox.Remove
  Params:  AIndex - Item index

  Removes item with the specified index
 ------------------------------------------------------------------------------}
procedure TCarbonComboBox.Remove(AIndex: Integer);
begin
  OSError(HIComboBoxRemoveItemAtIndex(HIViewRef(Widget), AIndex),
    Self, 'Remove', 'HIComboBoxRemoveItemAtIndex');
end;

{------------------------------------------------------------------------------
  Method:  TCarbonComboBox.DropDown
  Params:  ADropDown - Drop down
  Returns: If the function succeeds

  Shows or hides drop down list
 ------------------------------------------------------------------------------}
function TCarbonComboBox.DropDown(ADropDown: Boolean): Boolean;
begin
  Result := False;
  
  if OSError(HIComboBoxSetListVisible(ControlRef(Widget), ADropDown), Self,
    'DropDown', 'HIComboBoxSetListVisible') then Exit;

  Result := True;
end;

{ TCarbonEdit }

{------------------------------------------------------------------------------
  Method:  TCarbonEdit.CreateWidget
  Params:  AParams - Creation parameters

  Creates Carbon edit
 ------------------------------------------------------------------------------}
procedure TCarbonEdit.CreateWidget(const AParams: TCreateParams);
var
  Edit: TCustomEdit;
  Control: ControlRef;
  CFString: CFStringRef;
  SingleLine: Boolean = True;
begin
  Edit := LCLObject as TCustomEdit;

  CreateCFString(AParams.Caption, CFString);
  try
    if OSError(
      CreateEditUniCodeTextControl(GetTopParentWindow, ParamsToCarbonRect(AParams),
        CFString, (Edit.PasswordChar <> #0), nil, Control),
      Self, SCreateWidget, 'CreateEditUniCodeTextControl') then RaiseCreateWidgetError(LCLObject);

    Widget := Control;

    inherited;
  finally
    FreeCFString(CFString);
  end;

  // set edit single line
  OSError(
    SetControlData(Control, kControlEntireControl, kControlEditTextSingleLineTag,
      SizeOf(Boolean), @SingleLine),
    Self, SCreateWidget, SSetData);
    
  FIsPassword := Edit.PasswordChar <> #0;
  FMaxLength := Edit.MaxLength;
end;

{------------------------------------------------------------------------------
  Method:  TCarbonEdit.GetText
  Params:  S - Text
  Returns: If the function succeeds

  Gets the text of edit control
 ------------------------------------------------------------------------------}
function TCarbonEdit.GetText(var S: String): Boolean;
var
  CFString: CFStringRef;
begin
  if not FIsPassword then
    Result := inherited GetText(S)
  else
  begin
    Result := False;

    if OSError(
      GetControlData(ControlRef(Widget), GetEditPart,
        kControlEditTextPasswordCFStringTag, SizeOf(CFStringRef), @CFString, nil),
      Self, SGetText, SGetData) then Exit;

    try
      S := CFStringToStr(CFString);
      Result := True;
    finally
      FreeCFString(CFString);
    end;
  end;
end;

{------------------------------------------------------------------------------
  Method:  TCarbonEdit.SetText
  Params:  S - New text
  Returns: If the function succeeds

  Sets the text of edit control
 ------------------------------------------------------------------------------}
function TCarbonEdit.SetText(const S: String): Boolean;
var
  CFString: CFStringRef;
begin
  if not FIsPassword then
    Result := inherited SetText(S)
  else
  begin
    Result := False;
    
    CreateCFString(S, CFString);
    try
      if OSError(
        SetControlData(ControlRef(Widget), GetEditPart,
          kControlEditTextPasswordCFStringTag, SizeOf(CFStringRef), @CFString),
        Self, SSetText, SSetData) then Exit;
        
      Result := True;
    finally
      FreeCFString(CFString);
    end;
  end;
end;

{------------------------------------------------------------------------------
  Method:  TCarbonEdit.SetPasswordChar
  Params:  AChar     - New password char

  Sets the new password char of Carbon edit
 ------------------------------------------------------------------------------}
procedure TCarbonEdit.SetPasswordChar(AChar: Char);
begin
  if FIsPassword <> (AChar <> #0) then RecreateWnd(LCLObject);
end;

{ TCarbonMemo }

{------------------------------------------------------------------------------
  Method:  TCarbonMemo.SetScrollBars
  Params:  AValue - New scroll style

  Sets the memo scrollbars
 ------------------------------------------------------------------------------}
procedure TCarbonMemo.SetScrollBars(const AValue: TScrollStyle);
begin
  ChangeScrollBars(FScrollView, FScrollBars, AValue);
end;

{------------------------------------------------------------------------------
  Method:  TCarbonMemo.GetFrame
  Returns: Frame area control
 ------------------------------------------------------------------------------}
function TCarbonMemo.GetFrame: ControlRef;
begin
  Result := FScrollView;
end;

{------------------------------------------------------------------------------
  Method:  TCarbonMemo.GetForceEmbedInScrollView
  Returns: Whether use scroll view even if no scroll bars are needed
 ------------------------------------------------------------------------------}
function TCarbonMemo.GetForceEmbedInScrollView: Boolean;
begin
  Result := True;
end;

{------------------------------------------------------------------------------
  Method:  TCarbonMemo.CreateWidget
  Params:  AParams - Creation parameters

  Creates Carbon memo
 ------------------------------------------------------------------------------}
procedure TCarbonMemo.CreateWidget(const AParams: TCreateParams);
var
  Control: ControlRef;
  Options: FPCMacOSAll.OptionBits;
  R: HIRect;
begin
  Options := kTXNMonostyledTextMask or kOutputTextInUnicodeEncodingMask;

  R := ParamsToHIRect(AParams);
  if OSError(HITextViewCreate(@R, 0, Options, Control),
    Self, SCreateWidget, 'HITextViewCreate') then RaiseCreateWidgetError(LCLObject);

  Widget := Control;
  
  // force embed in scroll view because HITextView is not scrolling into
  // caret position when not embedded

  FScrollBars := (LCLObject as TCustomMemo).ScrollBars;
  FScrollView := EmbedInScrollView(FScrollBars);

  inherited;

  FMaxLength := 0;
end;

{------------------------------------------------------------------------------
  Method:  TCarbonMemo.DestroyWidget

  Destroys Carbon memo
 ------------------------------------------------------------------------------}
procedure TCarbonMemo.DestroyWidget;
begin
  inherited DestroyWidget;
  
  DisposeControl(FScrollView);
end;

{------------------------------------------------------------------------------
  Method:  TCarbonMemo.TextDidChange

  Text changed event handler
 ------------------------------------------------------------------------------}
procedure TCarbonMemo.TextDidChange;
var
  MemoStrings: TCarbonMemoStrings;
  Msg: TLMessage;
begin
  // limit the text according to MaxLength
  LimitTextLength;

  AdaptCharCase;

  // update memo strings
  MemoStrings := (LCLObject as TCustomMemo).Lines as TCarbonMemoStrings;
  if MemoStrings <> nil then MemoStrings.ExternalChanged;

  FillChar(Msg, SizeOf(Msg), 0);
  Msg.Msg := CM_TEXTCHANGED;
  DeliverMessage(LCLObject, Msg);
end;

{------------------------------------------------------------------------------
  Method:  TCarbonMemo.SetColor
  Params:  AColor - New color

  Sets the color of memo
 ------------------------------------------------------------------------------}
procedure TCarbonMemo.SetColor(const AColor: TColor);
var
  CGColor: CGColorRef;
begin
  CGColor := CreateCGColor(AColor);
  try
    OSError(HITextViewSetBackgroundColor(HIViewRef(Widget), CGColor),
      Self, SSetColor, 'HITextViewSetBackgroundColor');
  finally
    CGColorRelease(CGColor);
  end;
end;

{------------------------------------------------------------------------------
  Method:  TCarbonMemo.SetFont
  Params:  AFont - New font

  Sets the font of memo
 ------------------------------------------------------------------------------}
procedure TCarbonMemo.SetFont(const AFont: TFont);
var
  Attrs: Array [0..3] of TXNTypeAttributes;
  FontColor: RGBColor;
begin
 // font name
 Attrs[0].tag := kATSUFontTag;
 Attrs[0].size := SizeOf(ATSUFontID);
 Attrs[0].data.dataValue := FindCarbonFontID(AFont.Name);

 // font color
 FontColor := ColorToRGBColor(AFont.Color);
 Attrs[1].tag := kTXNQDFontColorAttribute;
 Attrs[1].size := kTXNQDFontColorAttributeSize;
 Attrs[1].data.dataPtr := @FontColor;

 // font size
 Attrs[2].tag := kTXNQDFontSizeAttribute;
 Attrs[2].size := kTXNQDFontSizeAttributeSize;
 Attrs[2].data.dataValue := AFont.Size;

 // font style
 Attrs[3].tag := kTXNATSUIStyle;
 Attrs[3].size := kTXNATSUIStyleSize;
 Attrs[3].data.dataPtr := Pointer(TCarbonFont(AFont.Handle).Style);

 // apply
 OSError(
   TXNSetTypeAttributes(HITextViewGetTXNObject(ControlRef(Widget)), 4, @Attrs[0],
     kTXNStartOffset, kTXNEndOffset),
   Self, 'SetFont', 'TXNSetTypeAttributes');

  // invalidate control
  Invalidate;
end;

{------------------------------------------------------------------------------
  Method:  TCarbonMemo.SetPasswordChar
  Params:  AChar     - New password char

  Sets the new password char of Carbon memo
 ------------------------------------------------------------------------------}
procedure TCarbonMemo.SetPasswordChar(AChar: Char);
begin
  OSError(
    TXNEchoMode(HITextViewGetTXNObject(ControlRef(Widget)),
      UniChar(AChar), CreateTextEncoding(kTextEncodingUnicodeDefault,
      kUnicodeNoSubset, kUnicodeUTF8Format), AChar <> #0),
    Self, 'SetPasswordChar', 'TXNEchoMode');

  Invalidate;
end;

{------------------------------------------------------------------------------
  Method:  TCarbonMemo.SetReadOnly
  Params:  AReadOnly - Read only behavior

  Sets the read only behavior of Carbon memo
 ------------------------------------------------------------------------------}
procedure TCarbonMemo.SetReadOnly(AReadOnly: Boolean);
var
  Tag: TXNControlTag;
  Data: TXNControlData;
begin
  Tag := kTXNNoUserIOTag;
  if AReadOnly then
    Data.uValue := UInt32(kTXNReadOnly)
  else
    Data.uValue := UInt32(kTXNReadWrite);

  OSError(
    TXNSetTXNObjectControls(HITextViewGetTXNObject(ControlRef(Widget)),
      False, 1, @Tag, @Data),
    Self, 'SetReadOnly', SSetTXNControls);
end;

{------------------------------------------------------------------------------
  Method:  TCarbonMemo.SetWordWrap
  Params:  AWordWrap - New word wrap

  Sets the word wrap of Carbon memo
 ------------------------------------------------------------------------------}
procedure TCarbonMemo.SetWordWrap(AWordWrap: Boolean);
var
  Tag: TXNControlTag;
  Data: TXNControlData;
begin
  Tag := kTXNWordWrapStateTag;
  
  if AWordWrap then
    Data.uValue := UInt32(kTXNAutoWrap)
  else
    Data.uValue := UInt32(kTXNNoAutoWrap);

  OSError(
    TXNSetTXNObjectControls(HITextViewGetTXNObject(ControlRef(Widget)),
      False, 1, @Tag, @Data),
    Self, 'SetWordWrap', SSetTXNControls);

  Invalidate;
end;

end.

