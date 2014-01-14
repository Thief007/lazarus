{%MainUnit ../dialogs.pp}

{
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
const
  DialogResult : Array[mrNone..mrYesToAll] of Longint = (
    -1, idButtonOK, idButtonCancel, idButtonAbort, idButtonRetry,
    idButtonIgnore, idButtonYes,idButtonNo, idButtonAll, idButtonNoToAll,
    idButtonYesToAll);

  DialogButtonKind : Array[idButtonOK..idButtonNoToAll] of TBitBtnKind = (
    bkOk, bkCancel, bkHelp, bkYes, bkNo, bkClose, bkAbort, bkRetry,
    bkIgnore, bkAll, bkCustom, bkCustom);

  {DialogButtonText : Array[idButtonOK..idButtonNoToAll] of String = (
    rsmbOk, rsmbCancel, rsmbHelp, rsmbYes, rsmbNo, rsmbClose, rsmbAbort,
    rsmbRetry, rsmbIgnore, rsmbAll, rsmbYesToAll, rsmbNoToAll);}

  {DialogCaption : Array[idDialogWarning..idDialogConfirm] of String = (
    rsMtWarning, rsMtError, rsMtInformation, rsMtConfirmation);}

type
  TPromptDialog = class(TForm)
    procedure PromptDialogKeyDown(Sender: TObject; var Key: Word;
          Shift: TShiftState);
  public
    TheDefaultIndex : Longint;

    FBitmap : TBitmap;
    MSG : AnsiString;
    NumButtons : Longint;
    Buttons : PLongint;

    TextBox : TRect;
    TextStyle : TTextStyle;

    procedure LayoutDialog;
    procedure Paint; override;
    constructor CreateMessageDialog(const ACaption, aMsg: string;
      DialogType : longint; TheButtons: PLongint; ButtonCount, DefaultIndex : Longint);
    destructor Destroy; override;
  end;

{** Return the localized or not title of dialog}
function GetDialogCaption(idDiag: Integer): String;
begin
  Result:='?';
  Case idDiag of
    idDialogWarning : Result:=rsMtWarning;
    idDialogError   : Result:=rsMtError;
    idDialogInfo    : Result:=rsMtInformation;
    idDialogConfirm : Result:=rsMtConfirmation;
  end;
end;

{** Return the text associed a an standard button}
function GetDialogButtonText(idBut: Integer): string;
begin
  Result:='';
  Case idBut of
    idButtonOk       : Result:=rsmbOk;
    idButtonCancel   : Result:=rsmbCancel;
    idButtonHelp     : Result:=rsmbHelp;
    idButtonYes      : Result:=rsmbYes;
    idButtonNo       : Result:=rsmbNo;
    idButtonClose    : Result:=rsmbClose;
    idButtonAbort    : Result:=rsmbAbort;
    idButtonRetry    : Result:=rsmbRetry;
    idButtonIgnore   : Result:=rsmbIgnore;
    idButtonAll      : Result:=rsmbAll;
    idButtonYesToAll : Result:=rsmbYesToAll;
    idButtonNoToAll  : Result:=rsmbNoToAll;
  end;
end;

procedure TPromptDialog.PromptDialogKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  OldFocusControl, NewFocusControl: TWinControl;
  i: integer;
begin
  if (Key=VK_Escape) then
    ModalResult := -1;

  if (Key=VK_LEFT) or (Key=VK_RIGHT) then begin
    // focus the next button to the left or right
    
    // search old focused button
    OldFocusControl:=FindOwnerControl(LCLIntf.GetFocus);
    if (OldFocusControl=nil) or (GetParentForm(OldFocusControl)<>Self)
    or (not (OldFocusControl is TCustomButton)) then
    begin
      OldFocusControl:=nil;
      for i:=0 to ComponentCount-1 do
        if (Components[i] is TCustomButton)
        and (TCustomButton(Components[i]).Default) then
        begin
          OldFocusControl:=TCustomButton(Components[i]);
          break;
        end;
    end;
    
    // find next focused button
    if (OldFocusControl<>nil) then begin
      i:=ComponentCount-1;
      while i>=0 do begin
        if Components[i]=OldFocusControl then
          break
        else
          dec(i);
      end;
      if i<0 then exit;
      NewFocusControl:=nil;
      repeat
        if Key=VK_LEFT then begin
          dec(i);
          if i<0 then i:=ComponentCount-1;
        end else begin
          inc(i);
          if i>=ComponentCount then i:=0;
        end;
        if Components[i] is TCustomButton then begin
          NewFocusControl:=TWinControl(Components[i]);
          break;
        end;
      until false;
      ActiveControl:=NewFocusControl;
      Key:=VK_UNKNOWN;
    end;
  end;
end;

procedure TPromptDialog.Paint;
begin
  Inherited Paint;
  Canvas.Brush := Brush;
  Canvas.TextRect(TextBox, TextBox.Left, TextBox.Top, MSG, TextStyle);
  if assigned (FBitmap) then
    Canvas.CopyRect(Bounds(cBitmapX, cBitmapY,FBitmap.Width,FBitmap.Height),
                    FBitmap.Canvas, Rect(0,0,FBitmap.Width,FBitmap.Height));
end;

constructor TPromptDialog.CreateMessageDialog(const ACaption, aMsg: string;
  DialogType : longint; TheButtons: PLongint; ButtonCount, DefaultIndex : Longint);
begin
  inherited Create(nil);

  OnKeyDown :=@PromptDialogKeyDown;
  //debugln('TPromptDialog.CreateMessageDialog A ButtonCount=',dbgs(ButtonCount));

  ControlStyle:= ControlStyle-[csSetCaption];
  BorderStyle := bsDialog;
  Position    := poScreenCenter;
  SetInitialBounds(0,0,200,100);
  MSG         := AMSG;
  Buttons     := nil;
  FBitmap := nil;
  Case DialogType of
    idDialogConfirm,
    idDialogInfo,
    idDialogWarning,
    idDialogError :
      begin
        FBitmap := TBitmap.Create;
        FBitmap.Handle := LoadStockPixmap(DialogType);
        If ACaption <> '' then
          Caption := ACaption
        else
          Caption := GetDialogCaption(DialogType);
      end;
    else begin
      FBitmap := TBitmap.Create;
      FBitmap.Handle := LoadStockPixmap(idDialogInfo);
      If ACaption <> '' then
        Caption := ACaption
      else
        Caption := Application.Title;
    end
  end;
  NumButtons := ButtonCount;
  Buttons := TheButtons;

  If (DefaultIndex >= ButtonCount) or
    (DefaultIndex < 0)
  then
    TheDefaultIndex := 0
  else
    theDefaultIndex := DefaultIndex;

  LayoutDialog;
end;

Destructor TPromptDialog.Destroy;
begin
  FBitmap.Free;
  inherited destroy;
end;

procedure TPromptDialog.LayoutDialog;
Const
  //AVGBuffer : PChar = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890()|_ ';
  cBtnCalcWidth  = 50;
  cBtnCalcHeight = 13;
  cBtnCalcSpace   = 4;
  cBtnCalcBorder = 4;
  cBtnDist = 10;
var
  curBtn      : Longint; // variable to loop through TMsgDlgButtons
  cMinLeft,
  ButtonLeft  : integer;    // left position of button(s)
  TextLeft    : integer;    // left position of text
  reqBtnWidth : integer;    // width neccessary to display buttons
  reqWidth, reqHeight : integer;    // width and height neccessary to display all
  i        : integer;
  ButtonIndex : integer;
  MinBtnWidth: Integer; // minimum width for a single button
  MinBtnHeight: Integer; // minimum height for a single button
  CurButton: TBitBtn;
  ButtonTop: Integer;
  CurBtnSize: TPoint;

  function GetButtonSize(AButton: TBitBtn): TPoint;
  var
    curBtnSize: tagSIZE;
  begin
    curBtnSize:=Canvas.TextExtent(AButton.Caption);
    inc(curBtnSize.cx,AButton.Glyph.Width+4);
    if curBtnSize.cy<AButton.Glyph.Height then
      curBtnSize.cy:=AButton.Glyph.Height;
    //debugln('GetButtonSize A ',AButton.Caption,' ',dbgs(curBtnSize.cx),',',dbgs(curBtnSize.cy));

    inc(curBtnSize.cx,2*cBtnCalcBorder);
    inc(curBtnSize.cy,2*cBtnCalcBorder);
    if MinBtnHeight<curBtnSize.cy then
      MinBtnHeight:=curBtnSize.cy
    else if curBtnSize.cy<MinBtnHeight then
      curBtnSize.cy:=MinBtnHeight;
    if curBtnSize.cx < MinBtnWidth then
      curBtnSize.cx := MinBtnWidth;
      
    Result:=Point(curBtnSize.cx,curBtnSize.cy);
    //debugln('GetButtonSize ',AButton.Caption,' ',dbgs(Result));
  end;
  
begin
  FillChar(TextStyle, SizeOf(TTextStyle), 0);

  With TextStyle do
  begin
    Clipping   := True;
    Wordbreak  := True;
    SystemFont := True;
    Opaque     := False;
  end;

  // calculate the width & height we need to display the Message
  If MSG = '' then
    MSG := '   ';

  // calculate the needed size for the text
  TextBox := Rect(0,0, Screen.Width div 2,Screen.Height - 100);
  SelectObject(Canvas.Handle, GetStockObject(DEFAULT_GUI_FONT));
  DrawText(Canvas.Handle, PChar(MSG), Length(MSG),
    TextBox, DT_WORDBREAK or DT_INTERNAL or DT_CALCRECT);

  // calculate the width we need to display the buttons
  MinBtnWidth:=Max(25,MinimumDialogButtonWidth);
  MinBtnHeight:=Max(15,MinimumDialogButtonHeight);
  reqBtnWidth := 0;

  // create the buttons, without positioning
  ButtonIndex := -1;
  for curBtn := 0 to NumButtons - 1 do
  begin
    If (Buttons[curBtn] >= Low(DialogButtonKind)) and
      (Buttons[curBtn] <= High(DialogButtonKind))
    then
    begin
      inc(ButtonIndex);

      CurButton:=TBitBtn.Create(Self);
      with CurButton do
      begin
        Parent:= Self;
        Layout  := blGlyphLeft;
        OnKeyDown := @PromptDialogKeyDown;
        Case Buttons[curBtn] of
          idButtonYesToAll,
          idButtonNoToAll :
            begin
              Glyph.Handle := LoadStockPixmap(Buttons[curBtn]);
              If Buttons[curBtn] = idButtonYesToAll then
              begin
                ModalResult := mrYesToAll;
                Caption := rsmbYesToAll;
              end
              else
              begin
                ModalResult := mrNoToAll;
                Caption := rsmbNoToAll;
              end;
            end;
          else
            Kind := DialogButtonKind[Buttons[curBtn]];
        end;
        if Height < Glyph.Height + 5 then
          Height := Glyph.Height + 5;

        if ButtonIndex = TheDefaultIndex then Default := true;

        CurBtnSize:=GetButtonSize(CurButton);
        if reqBtnWidth > 0 then inc(reqBtnWidth, cBtnDist);
        Inc(reqBtnWidth, CurBtnSize.X);
      end;
    end;
  end;

  // calculate the minimum text offset from left
  If FBitmap <> nil then
    cMinLeft := cBitmapX + max(32,FBitmap.Width) + cLabelSpacing
  else
    cMinLeft := 0;

  // calculate required width for the text
  reqWidth := cMinLeft + TextBox.Right;

  // if buttons require more space than the text, center the text
  // as much as possible
  if reqWidth < reqBtnWidth then begin
    reqWidth := reqBtnWidth;
    TextLeft := max(cMinLeft, cLabelSpacing + (reqWidth - TextBox.Right) div 2);
  end
  else
    TextLeft := (cMinLeft + reqWidth - TextBox.Right) div 2;

  // position the text
  OffsetRect(TextBox, TextLeft, cLabelSpacing);

  // calculate the height of the text+icon
  reqHeight:= max(TextBox.Bottom, 32);
  if (FBitmap <> nil) and (FBitmap.Height > reqHeight) then
    reqHeight := FBitmap.Height;

  // set size of form
  SetBounds(Left, Top, reqWidth + 2 * cLabelSpacing,
        3 * cLabelSpacing + reqHeight + MinBtnHeight);

  // calculate the left of the buttons
  ButtonLeft := ((reqWidth - reqBtnWidth) div 2) + cLabelSpacing;
  ButtonTop := reqHeight + 2*cLabelSpacing;

  // position buttons and activate default
  for i:=0 to ComponentCount-1 do begin
    if (Components[i] is TBitBtn) then begin
      CurButton:=TBitBtn(Components[i]);
      CurBtnSize:=GetButtonSize(CurButton);
      CurButton.SetBounds(ButtonLeft,ButtonTop,CurBtnSize.X,CurBtnSize.Y);
      inc(ButtonLeft,CurButton.Width+cBtnDist);
      
      if (CurButton.Default) then begin
        ActiveControl:=CurButton;
        DefaultControl:=CurButton;
      end;
    end;
  end;
end;

Function ShowPromptDialog(const DialogCaption,
  DialogMessage : String;
  DialogType : longint; Buttons : PLongint;
  ButtonCount, DefaultIndex, EscapeResult : Longint;
  UseDefaultPos: boolean;
  X, Y : Longint) : Longint;
var
  theModalResult : longint;
begin
  with TPromptDialog.CreateMessageDialog (DialogCaption, DialogMessage,
    DialogType, Buttons, ButtonCount, DefaultIndex)
  do
    try
      if not UseDefaultPos then begin
        Position := poDesigned;
        Left := X;
        Top := Y;
      end;
      theModalResult := ShowModal;
      Case theModalResult of
        -1 : Result := EscapeResult
        else
          Result := DialogResult[theModalResult];
      end;
    finally
      Free;
    end;
end;


type

  { TQuestionDlg }

  TQuestionDlg = class(TForm)
    procedure ButtonKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
  private
    FButtons: TList;
    FBitmap: TBitmap;
    FBitmapX, FBitmapY: Integer;
  public
    TextBox : TRect;
    TextStyle : TTextStyle;
    MessageTxt: String;
    constructor CreateQuestionDlg(const aCaption, aMsg: string;
      DlgType: TMsgDlgType; Buttons: array of const; HelpCtx: Longint);
    destructor Destroy; override;
    procedure Paint; override;
    procedure LayoutDialog;
    function ShowModal: TModalResult; override;
    function FindButton(Order: array of TModalResult): TBitBtn;
    procedure CalcButtonSize(AButton: TBitBtn; var w, h: Integer);
  end;

{ TQuestionDlg }

procedure TQuestionDlg.Paint;
begin
  Inherited Paint;
  //Canvas.Brush.Color := clRed;
  //Canvas.FillRect(TextBox);
  Canvas.TextRect(TextBox, TextBox.Left, TextBox.Top, MessageTxt, TextStyle);
  if Assigned(FBitmap) then begin
    //Canvas.Brush.Color := clBlue;
    //Canvas.FillRect(Bounds(FBitmapX,FBitmapY,FBitmap.Width,FBitmap.Height));
    Canvas.CopyRect(Bounds(FBitmapX,FBitmapY,FBitmap.Width,FBitmap.Height),
                    FBitmap.Canvas, Rect(0,0,FBitmap.Width,FBitmap.Height));
  end;
end;

procedure TQuestionDlg.LayoutDialog;
const
  cBtnDist = 10; // distance between buttons
  cLabelSpacing = 8; // space around label
var
  Flags: Cardinal;
  i: Integer;
  CurButton: TBitBtn;
  CurBtnWidth, CurBtnHeight: Integer;
  reqBtnWidth: Integer;
  reqWidth: LongInt;
  cMinLeft: Integer;
  ButtonLeft: Integer;
  reqHeight: LongInt;
  CurBtnPos: Integer;
begin
  FillChar(TextStyle, SizeOf(TTextStyle), 0);

  With TextStyle do
  begin
    Clipping   := True;
    Wordbreak  := True;
    SystemFont := True;
    Opaque     := False;
  end;

  // calculate the width & height we need to display the Message
  If MessageTxt = '' then
    MessageTxt := '   ';
  TextBox := Rect(0,0, Screen.Width div 2,Screen.Height - 100);
  Flags:=DT_CalcRect or DT_NoPrefix or DT_WordBreak;
  DrawText(Canvas.GetUpdatedHandle([csHandleValid,csFontValid]),
           PChar(MessageTxt),Length(MessageTxt),TextBox,Flags);

  // calculate the width we need to display the buttons
  reqBtnWidth:=0;
  CurBtnHeight:=25;
  if FButtons<>nil then
    for i:=0 to FButtons.Count-1 do begin
      if i>0 then
        Inc(reqBtnWidth, cBtnDist);
      CurButton:=TBitBtn(FButtons[i]);
      CalcButtonSize(CurButton,CurBtnWidth,CurBtnHeight);
      Inc(reqBtnWidth, CurBtnWidth);
    end;

  // calculate the width of the dialog
  If FBitmap <> nil then
    cMinLeft := cLabelSpacing + max(20,FBitmap.Width) + cLabelSpacing
  else
    cMinLeft := cLabelSpacing;
  reqWidth:= reqBtnWidth + 2*cBtnDist;
  if reqWidth < (TextBox.Right + cMinLeft + cLabelSpacing) then
    reqWidth:= TextBox.Right + cMinLeft + cLabelSpacing;
  ButtonLeft := ((reqWidth - reqBtnWidth) div 2);

  // calculate the height of the dialog
  reqHeight:= TextBox.Bottom;
  if (FBitmap <> nil) and (FBitmap.Height > reqHeight) then
    reqHeight := FBitmap.Height;
  inc(reqHeight,CurBtnHeight+3*cLabelSpacing);

  // calculate the text position
  OffsetRect(TextBox,
             ((reqWidth-cMinLeft-TextBox.Right-cLabelSpacing) div 2) + cMinLeft,
             cLabelSpacing);

  // calculate the icon position
  if FBitmap<>nil then begin
    FBitmapX:=cLabelSpacing;
    FBitmapY:=(reqHeight-CurBtnHeight-FBitmap.Height-cLabelSpacing) div 2;
  end;

  // set size of form
  SetBounds((Screen.Width-reqWidth-10) div 2, (Screen.Height-reqHeight-50) div 2,
         reqWidth,reqHeight);

  // position buttons
  CurBtnPos:=ButtonLeft;
  if FButtons<>nil then
    for i:=0 to FButtons.Count-1 do begin
      if i>0 then
        Inc(CurBtnPos,cBtnDist);
      CurButton:=TBitBtn(FButtons[i]);
      CalcButtonSize(CurButton,CurBtnWidth,CurBtnHeight);
      CurButton.SetBounds(CurBtnPos,ClientHeight-CurBtnHeight-cLabelSpacing,
                          CurBtnWidth,CurBtnHeight);
      Inc(CurBtnPos,CurBtnWidth);
    end;
end;

function TQuestionDlg.ShowModal: TModalResult;
begin
  LayoutDialog;
  Result:=inherited ShowModal;
end;

function TQuestionDlg.FindButton(Order: array of TModalResult): TBitBtn;
var
  i: Integer;
  CurValue: TModalResult;
  j: Integer;
begin
  if FButtons=nil then begin
    Result:=nil;
    exit;
  end;
  for i:=Low(Order) to High(Order) do begin
    CurValue:=Order[i];
    for j:=0 to FButtons.Count-1 do begin
      Result:=TBitBtn(FButtons[j]);
      if Result.ModalResult=CurValue then exit;
    end;
  end;
  Result:=nil;
end;

procedure TQuestionDlg.CalcButtonSize(AButton: TBitBtn; var w, h: Integer);
var
  TxtSize: TSize;
begin
  TxtSize:=Canvas.TextExtent(AButton.Caption);
  w:=Max(TxtSize.cx,MinimumDialogButtonWidth);
  h:=Max(TxtSize.cy,MinimumDialogButtonHeight);
  if AButton.Kind<>bkCustom then begin
    inc(w,22); // icon
  end;
  h:=Max(h,22); // icon
  inc(w,12); // borders
  inc(h,6); // borders
end;

procedure TQuestionDlg.ButtonKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  Handled: Boolean;
begin
  if Shift<>[] then exit;
  Handled:=true;
  if (Key=VK_ESCAPE) and (CancelControl<>nil) then
    CancelControl.ExecuteCancelAction
  else if (Key in [VK_RETURN,VK_SPACE]) and (Sender is TBitBtn) then
    ModalResult:=TBitBtn(Sender).ModalResult
  else if (Key=VK_RETURN) and (DefaultControl<>nil) then
    DefaultControl.ExecuteDefaultAction
  else if (Key=VK_LEFT) then
    TWinControl(Sender).PerformTab(false)
  else if (Key=VK_RIGHT) then
    TWinControl(Sender).PerformTab(true)
  else
    Handled:=false;
  if Handled then Key:=VK_UNKNOWN;
end;

constructor TQuestionDlg.CreateQuestionDlg(const aCaption, aMsg: string;
  DlgType: TMsgDlgType; Buttons: array of const; HelpCtx: Longint);
var
  i: Integer;
  CurBtnValue: TModalResult;
  CurBtnCaption: String;
  NewButton: TBitBtn;
  NewKind: TBitBtnKind;
  NewCaption: String;
  dlgId: LongInt;
  ok: Boolean;
begin
  inherited Create(nil);
  MessageTxt:=aMsg;
  HelpContext:=HelpCtx;
  OnKeyDown:=@ButtonKeyDown;
  ok:=false;
  try
    i:=Low(Buttons);
    while i<=High(Buttons) do begin
      if Buttons[i].VType<>vtInteger then
        RaiseGDBException('TQuestionDlg.CreateQuestionDlg integer expected at '
          +IntToStr(i)+' but '+IntToStr(ord(Buttons[i].VType))+' found.');
      if Buttons[i].VType=vtInteger then begin
        // get TModalResult
        CurBtnValue:=Buttons[i].VInteger;
        //debugln('TQuestionDlg.CreateQuestionDlg i=',dbgs(i),' CurBtnValue=',dbgs(CurBtnValue));
        inc(i);
        
        // get button caption
        CurBtnCaption:='';
        if (i<=High(Buttons)) then begin
          //debugln('TQuestionDlg.CreateQuestionDlg i=',dbgs(i),' Buttons[i].VType=',dbgs(Buttons[i].VType),' vtString=',dbgs(vtString));
          case Buttons[i].VType of
          vtString: CurBtnCaption:=Buttons[i].VString^;
          vtAnsiString: CurBtnCaption:=AnsiString(Buttons[i].VAnsiString);
          vtChar: CurBtnCaption:=Buttons[i].VChar;
          vtPChar: CurBtnCaption:=Buttons[i].VPChar;
          vtPWideChar: CurBtnCaption:=Buttons[i].VPWideChar;
          vtWideChar: CurBtnCaption:=Buttons[i].VWideChar;
          vtWidestring: CurBtnCaption:=WideString(Buttons[i].VWideString);
          else
            dec(i); // prevent the following inc(i)
          end;
          inc(i);
        end;
        //DebugLn('TQuestionDlg.CreateQuestionDlg CurBtnCaption=',CurBtnCaption);
        if CurBtnCaption='' then begin
          // find default caption
          Case CurBtnValue of
            mrOk       : CurBtnCaption:=rsmbOk;
            mrCancel   : CurBtnCaption:=rsmbCancel;
            mrYes      : CurBtnCaption:=rsmbYes;
            mrNo       : CurBtnCaption:=rsmbNo;
            mrAbort    : CurBtnCaption:=rsmbAbort;
            mrRetry    : CurBtnCaption:=rsmbRetry;
            mrIgnore   : CurBtnCaption:=rsmbIgnore;
            mrAll      : CurBtnCaption:=rsmbAll;
            mrYesToAll : CurBtnCaption:=rsmbYesToAll;
            mrNoToAll  : CurBtnCaption:=rsmbNoToAll;
          end;
        end;
        if CurBtnCaption='' then begin
          raise Exception.Create(
            'TQuestionDlg.Create: missing Button caption '+dbgs(i-1));
        end;
        
        // get button kind
        case curBtnValue of
        mrOk:       NewKind:=bkOK;
        mrCancel:   NewKind:=bkCancel;
        mrYes:      NewKind:=bkYes;
        mrNo:       NewKind:=bkNo;
        mrAbort:    NewKind:=bkAbort;
        mrRetry:    NewKind:=bkRetry;
        mrIgnore:   NewKind:=bkIgnore;
        mrAll:      NewKind:=bkAll;
        mrNoToAll:  NewKind:=bkNoToAll;
        mrYesToAll: NewKind:=bkYesToAll;
        else NewKind:=bkCustom;
        end;

        // add button
        if FButtons=nil then FButtons:=TList.Create;
        NewButton:=TBitBtn.Create(Self);
        with NewButton do begin
          AutoSize:=false;
          ModalResult:=curBtnValue;
          Layout:=blGlyphLeft;
          Kind:=NewKind;
          Caption:=curBtnCaption;
          Parent:=Self;
          OnKeyDown:=@ButtonKeyDown;
        end;
        FButtons.Add(NewButton);
      end else
        raise Exception.Create(
          'TQuestionDlg.Create: invalid Buttons parameter '+dbgs(i));
    end;
    ok:=true;
  finally
    if not Ok then
      FreeAndNil(FButtons);
  end;

  FBitmap := nil;
  NewCaption:=ACaption;
  FBitmap := TBitmap.Create;
  Case DlgType of
    mtWarning, mtError, mtInformation, mtConfirmation:
      begin
        dlgId:=DialogIds[DlgType];
        FBitmap.Handle := LoadStockPixmap(dlgId);
        if NewCaption='' then
          NewCaption := GetDialogCaption(dlgId);
      end;
    else begin
      FBitmap.Handle := LoadStockPixmap(idDialogInfo);
    end
  end;
  if NewCaption='' then
    NewCaption := Application.Title;
  Caption:=NewCaption;
  
  // find default and cancel button
  DefaultControl:=FindButton([mrYes,mrOk,mrYesToAll,mrAll,mrRetry,mrCancel,
                              mrNo,mrNoToAll,mrAbort,mrIgnore]);
  CancelControl:=FindButton([mrNo,mrAbort,mrCancel,mrIgnore,mrNoToAll,mrYes,
                             mrOk,mrRetry,mrAll,mrYesToAll])
end;

destructor TQuestionDlg.Destroy;
begin
  FreeAndNil(FButtons);
  FreeAndNil(FBitmap);
  inherited Destroy;
end;


function QuestionDlg(const aCaption, aMsg: string; DlgType: TMsgDlgType;
  Buttons: array of const; HelpCtx: Longint): TModalResult;
{ Show a dialog with aCaption as Title, aMsg as Text, DlgType as Icon,
  HelpCtx as Help context and Buttons to define the shown buttons and their
  TModalResult.
  Buttons is a list of TModalResult and strings. For each number a button is
  created. To set a custom caption, add a string after a button.
  The default TModalResults defined in controls.pp (mrNone..mrLast) don't need
  a caption. The default captions will be used.

  Examples for Buttons:
    [mrOk,mrCancel,'Cancel now',mrIgnore,300,'Do it']
    This will result in 4 buttons:
      'Ok' returning mrOk
      'Cancel now' returning mrCancel
      'Ignore' returning mrIgnore
      'Do it' returning 300
}
var
  QuestionDialog: TQuestionDlg;
begin
  QuestionDialog:=TQuestionDlg.CreateQuestionDlg(aCaption,aMsg,DlgType,Buttons,
                                                 HelpCtx);
  try
    Result:=QuestionDialog.ShowModal;
  finally
    QuestionDialog.Free;
  end;
end;

function QuestionDlg(const aCaption, aMsg: string; DlgType: TMsgDlgType;
  Buttons: array of const; const HelpKeyword: string): TModalResult;
begin
  // TODO: handle HelpKeyword
  Result:=QuestionDlg(aCaption,aMsg,DlgType,Buttons,0);
end;

// included by dialogs.pp