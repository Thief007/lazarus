unit SynGutterCodeFolding;

{$I synedit.inc}

interface

uses
  SysUtils, Classes, Controls, Graphics, Menus, LCLIntf, SynGutterBase, SynEditMiscProcs,
  SynEditFoldedView, SynEditMouseCmds, SynEditHighlighterFoldBase, LCLProc;

type

  { TSynEditMouseActionsGutterFold }

  TSynEditMouseActionsGutterFold = class(TSynEditMouseActions)
  public
    procedure ResetDefaults; override;
  end;

  // Line with [-] => ALL nodes expanded

  { TSynEditMouseActionsGutterFoldExpanded }

  TSynEditMouseActionsGutterFoldExpanded = class(TSynEditMouseActions)
  public
    procedure ResetDefaults; override;
  end;

  // Line with [+] => at LEAST ONE node collapsed

  { TSynEditMouseActionsGutterFoldCollapsed }

  TSynEditMouseActionsGutterFoldCollapsed = class(TSynEditMouseActions)
  public
    procedure ResetDefaults; override;
  end;

  { TSynGutterCodeFolding }

  TSynGutterCodeFolding = class(TSynGutterPartBase)
  private
    FFoldView: TSynEditFoldedView;
    FMouseActionsCollapsed: TSynEditMouseActions;
    FMouseActionsExpanded: TSynEditMouseActions;
    FPopUp: TPopupMenu;
    FMenuInf: Array of TFoldViewNodeInfo;
    FIsFoldHidePreviousLine: Boolean;
    procedure SetMouseActionsCollapsed(const AValue: TSynEditMouseActions);
    procedure SetMouseActionsExpanded(const AValue: TSynEditMouseActions);
    function  FoldTypeForLine(AScreenLine: Integer): TSynEditFoldLineCapability;
    function  IsFoldHidePreviousLine(AScreenLine: Integer): Boolean;
    function  IsSingleLineHide(AScreenLine: Integer): Boolean;
  protected
    procedure DoChange(Sender: TObject); override;
    procedure PopClicked(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure Paint(Canvas: TCanvas; AClip: TRect; FirstLine, LastLine: integer);
      override;
    function RealGutterWidth(CharWidth: integer): integer;  override;
    procedure DoOnGutterClick(X, Y: integer); override;
    function MaybeHandleMouseAction(var AnInfo: TSynEditMouseActionInfo;
               HandleActionProc: TSynEditMouseActionHandler): Boolean; override;
    function DoHandleMouseAction(AnAction: TSynEditMouseAction;
                                 var AnInfo: TSynEditMouseActionInfo): Boolean; override;
  published
    property MarkupInfo;
    property MouseActionsExpanded: TSynEditMouseActions
      read FMouseActionsExpanded write SetMouseActionsExpanded;
    property MouseActionsCollapsed: TSynEditMouseActions
      read FMouseActionsCollapsed write SetMouseActionsCollapsed;
  end;

implementation
uses
  SynEdit;

{ TSynGutterCodeFolding }

procedure TSynGutterCodeFolding.SetMouseActionsCollapsed(const AValue: TSynEditMouseActions);
begin
  if AValue = nil then
    FMouseActionsCollapsed.Clear
  else
    FMouseActionsCollapsed.Assign(AValue);
end;

procedure TSynGutterCodeFolding.SetMouseActionsExpanded(const AValue: TSynEditMouseActions);
begin
  if AValue = nil then
    FMouseActionsExpanded.Clear
  else
    FMouseActionsExpanded.Assign(AValue);
end;

function TSynGutterCodeFolding.FoldTypeForLine(AScreenLine: Integer): TSynEditFoldLineCapability;
var
  tmp, tmp2: TSynEditFoldLineCapabilities;
begin
  tmp := FFoldView.FoldType[AScreenLine];
  tmp2 := FFoldView.FoldType[AScreenLine-1];
  FIsFoldHidePreviousLine := False;

  if (AScreenLine = 0) and (FFoldView.TextIndexToViewPos(FFoldView.TextIndex[0]) = 1) and
     (cfCollapsedHide in tmp2)
  then begin
    Result := cfCollapsedHide;
    FIsFoldHidePreviousLine := True;
  end
  //if tmp * [cfHideStart, cfFoldStart, cfCollapsedFold] = [cfHideStart, cfFoldStart, cfCollapsedFold]
  //                               then Result := cfHideStart
  else if cfCollapsedFold in tmp then Result := cfCollapsedFold
  else if cfCollapsedHide in tmp then Result := cfCollapsedHide
  else if cfFoldStart     in tmp then Result := cfFoldStart
  else if cfHideStart     in tmp then Result := cfHideStart
  else if cfFoldEnd       in tmp then Result := cfFoldEnd
  else if cfFoldBody      in tmp then Result := cfFoldBody
  else
    Result := cfNone;

  if Result in [cfFoldBody, cfFoldEnd] then begin
    tmp := FFoldView.FoldType[AScreenLine - 1];
    if tmp * [cfHideStart, cfFoldStart, cfCollapsedFold, cfCollapsedHide]
       = [cfHideStart, cfFoldStart]
    then begin
      FIsFoldHidePreviousLine := True;
      Result := cfHideStart // hide for previous line
    end;
  end;
end;

function TSynGutterCodeFolding.IsFoldHidePreviousLine(AScreenLine: Integer): Boolean;
begin
  FoldTypeForLine(AScreenLine);
  Result := FIsFoldHidePreviousLine;
end;

function TSynGutterCodeFolding.IsSingleLineHide(AScreenLine: Integer): Boolean;
var
  tmp: TSynEditFoldLineCapabilities;
begin
  Result := False;
  tmp := FFoldView.FoldType[AScreenLine];
  if tmp * [cfHideStart, cfFoldStart, cfCollapsedFold] =
     [cfHideStart, cfFoldStart, cfCollapsedFold]
  then
    Result := True;
  if cfSingleLineHide in tmp then
    Result := True;
end;

procedure TSynGutterCodeFolding.DoChange(Sender: TObject);
begin
  if AutoSize then
    FWidth := 10;
  inherited DoChange(Sender);
end;

constructor TSynGutterCodeFolding.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FFoldView := Gutter.FoldView;
  FMouseActions := TSynEditMouseActionsGutterFold.Create(self);
  FMouseActionsExpanded := TSynEditMouseActionsGutterFoldExpanded.Create(self);
  FMouseActionsCollapsed := TSynEditMouseActionsGutterFoldCollapsed.Create(self);
  FMouseActions.ResetDefaults;
  FMouseActionsCollapsed.ResetDefaults;
  FMouseActionsExpanded.ResetDefaults;

  MarkupInfo.Background := clNone;
  MarkupInfo.Foreground := clDkGray;
  MarkupInfo.FrameColor := clNone;

  FWidth := 10;
  FPopUp := TPopupMenu.Create(nil);
end;

destructor TSynGutterCodeFolding.Destroy;
begin
  FreeAndNil(FMouseActions);
  FreeAndNil(FMouseActionsCollapsed);
  FreeAndNil(FMouseActionsExpanded);
  FreeAndNil(FPopUp);
  inherited Destroy;
end;

function TSynGutterCodeFolding.RealGutterWidth(CharWidth : integer) : integer;
begin
  If Visible then
    Result := Width
  else
    Result := 0;
end;

procedure TSynGutterCodeFolding.PopClicked(Sender: TObject);
var
  inf: TFoldViewNodeInfo;
begin
   inf := FMenuInf[(Sender as TMenuItem).tag];
   if inf.Folded then
     FFoldView.UnFoldAtTextIndex(inf.LineNum-1, inf.ColIndex, 1, False)
   else
     FFoldView.FoldAtTextIndex(inf.LineNum-1, inf.ColIndex, 1, False);
end;

procedure TSynGutterCodeFolding.DoOnGutterClick(X, Y : integer);
begin
  // Do Nothing
end;

function TSynGutterCodeFolding.MaybeHandleMouseAction(var AnInfo: TSynEditMouseActionInfo;
  HandleActionProc: TSynEditMouseActionHandler): Boolean;
var
  tmp: TSynEditFoldLineCapability;
begin
  Result := False;
  tmp := FoldTypeForLine(FFoldView.TextIndexToScreenLine(AnInfo.NewCaret.LinePos-1));
  case tmp of
    cfCollapsedFold, cfCollapsedHide:
      Result := HandleActionProc(MouseActionsCollapsed, AnInfo);
    cfFoldStart, cfHideStart:
      Result := HandleActionProc(MouseActionsExpanded, AnInfo);
  end;

  if not Result then
    Result := HandleActionProc(MouseActions, AnInfo);
end;

function TSynGutterCodeFolding.DoHandleMouseAction(AnAction: TSynEditMouseAction;
  var AnInfo: TSynEditMouseActionInfo): Boolean;
var
  c, i, line, ScrLine: Integer;
  inf: TFoldViewNodeInfo;
  m: TMenuItem;
  s, s2: String;
  ACommand: Word;
  KeepVisible: Integer;
begin
  Result := False;
  if AnAction = nil then exit;
  ACommand := AnAction.Command;
  if (ACommand = emcNone) then exit;
  line := AnInfo.NewCaret.LinePos;
  ScrLine := FFoldView.TextIndexToScreenLine(Line-1);
  KeepVisible := 1;
  if FoldTypeForLine(ScrLine) = cfHideStart then KeepVisible := 0;

  if (FoldTypeForLine(ScrLine) = cfCollapsedHide) then begin
    if IsFoldHidePreviousLine(ScrLine) then
      line := FFoldView.TextIndex[ScrLine-1] + 1;
    inc(line);
    KeepVisible := 0;
  end
  else
    if IsFoldHidePreviousLine(ScrLine) then dec(line);

  Result := True;
  case ACommand of
    emcCodeFoldCollaps:
      begin
        case AnAction.Option of
          emcoCodeFoldCollapsOne:
            begin
              FFoldView.FoldAtTextIndex(Line-1, -1, 1, True, KeepVisible);
            end;
          emcoCodeFoldCollapsAll:
            begin
              FFoldView.FoldAtTextIndex(Line-1, -1, 0, False, KeepVisible);
            end;
          emcoCodeFoldCollapsAtCaret:
            // Keyword at mouseclick/caret position
            begin
              i := FFoldView.LogicalPosToNodeIndex(Line-1, AnInfo.NewCaret.BytePos, False);
              if i >= 0 then
                FFoldView.FoldAtTextIndex(Line-1, i, 1, False, KeepVisible)
              else
                Result := False;
            end;
          emcoCodeFoldCollapsPreCaret:
            // mouseclick/caret position anywhere inside the fold
            begin
              i := FFoldView.LogicalPosToNodeIndex(Line-1, AnInfo.NewCaret.BytePos, True);
              if i >= 0 then
                FFoldView.FoldAtTextIndex(Line-1, i, 1, False, KeepVisible)
              else begin
                i := FFoldView.ExpandedLineForBlockAtLine(Line);
                if i > 0 then
                  FFoldView.FoldAtTextIndex(i-1, -1, 1, True, KeepVisible);
              end;
            end;
        end;
      end;
    emcCodeFoldExpand:
      begin
        case AnAction.Option of
          emcoCodeFoldExpandOne:
            FFoldView.UnFoldAtTextIndex(line-1, 0, 1, True, KeepVisible);
          emcoCodeFoldExpandAll:
            FFoldView.UnFoldAtTextIndex(line-1, -1, 0, False, KeepVisible);
        end;
      end;
    emcCodeFoldContextMenu:
      begin
        FPopUp.Items.Clear;
        c := FFoldView.OpenFoldCount(line-1);
        if c > 0 then begin
          SetLength(FMenuInf,c);
          for i := c-1 downto 0 do begin
            inf := FFoldView.OpenFoldInfo(line-1, i);
            if sfaInvalid in inf.HNode.FoldAction then
              continue;
            FMenuInf[i] := inf;
            if (i < c-1) and (FMenuInf[i+1].LineNum = line) and (inf.LineNum <> line)
            then begin
              m := TMenuItem.Create(FPopUp);
              m.Caption := cLineCaption;
              m.Tag := -1;
              FPopUp.Items.Add(m);
            end;
            s := copy(inf.Text, 1, inf.HNode.LogXStart-1);
            if length(s) > 30 then s := copy(s,1,15) + '...' + copy(s, inf.HNode.LogXStart-11,10);
            s := s + copy(inf.Text, inf.HNode.LogXStart, 30 + (30 - length(s)));
            s2 := '';
            if inf.OpenCount > 1 then
              s2 := format(' (%d/%d)', [inf.ColIndex+1, inf.OpenCount]);
            m := TMenuItem.Create(FPopUp);
            m.Caption := format('%4d %-12s %s', [ inf.LineNum, inf.Keyword+s2+':', s]);
            m.ShowAlwaysCheckable := true;
            m.Checked := inf.Folded;
            m.Tag := i;
            m.OnClick := {$IFDEF FPC}@{$ENDIF}PopClicked;
            FPopUp.Items.Add(m);
          end;
          FPopUp.PopUp;
        end;
      end;
    else
      Result := False;
  end;
end;

procedure TSynGutterCodeFolding.Paint(Canvas : TCanvas; AClip : TRect; FirstLine, LastLine : integer);
const cNodeOffset = 1;
var
  iLine: integer;
  rcLine: TRect;
  rcCodeFold: TRect;
  tmp: TSynEditFoldLineCapability;
  LineHeight, LineOffset, BoxSize: Integer;

  procedure DrawNodeBox(rcCodeFold: TRect; NodeType: TSynEditFoldLineCapability);
  var
    rcNode: TRect;
    ptCenter : TPoint;
    isPrevLine: Boolean;
    Points: Array [0..3] of TPoint;
  begin
    isPrevLine := IsFoldHidePreviousLine(iLine);
    LineOffset := 0;

    //center of the draw area
    ptCenter.X := (rcCodeFold.Left + rcCodeFold.Right) div 2;
    ptCenter.Y := (rcCodeFold.Top + rcCodeFold.Bottom) div 2;

    // If belongs to line above, draw at very top
    if isPrevLine then
      ptCenter.Y := rcCodeFold.Top + (BoxSize div 2) - 1;

    //area of drawbox
    rcNode.Left   := ptCenter.X - (BoxSize div 2) + 1;
    rcNode.Right  := ptCenter.X + (BoxSize div 2);
    rcNode.Top    := ptCenter.Y - (BoxSize div 2) + 1;
    rcNode.Bottom := ptCenter.Y + (BoxSize div 2);

    Canvas.Brush.Style := bsClear;

    //draw Paragraph end
    if isPrevLine and (cfFoldEnd in FFoldView.FoldType[iLine]) and
       (rcCodeFold.Bottom-1 > rcNode.Bottom)
    then begin
      Canvas.MoveTo(ptCenter.X, rcNode.Bottom);
      Canvas.LineTo(ptCenter.X, rcCodeFold.Bottom-1);
      Canvas.LineTo(rcCodeFold.Right, rcCodeFold.Bottom-1);
      LineOffset := min(2, (rcCodeFold.Top + rcCodeFold.Bottom) div 2);
    end
    else
    //draw bottom handle to paragraph line
    if (cfFoldBody in FFoldView.FoldType[iLine + 1]) and
       (not IsSingleLineHide(iLine))
    then begin
      Canvas.MoveTo(ptCenter.X, rcNode.Bottom);
      Canvas.LineTo(ptCenter.X, rcCodeFold.Bottom);
    end;

    if (NodeType in [cfCollapsedFold, cfCollapsedHide]) and
       (MarkupInfo.FrameColor <> clNone)
    then
      Canvas.Pen.Color := MarkupInfo.FrameColor;

    Canvas.Rectangle(rcNode);

    //draw folded sign
    case NodeType of
      cfFoldStart:
        begin
          // [-]
          Canvas.MoveTo(ptCenter.X - 2, ptCenter.Y);
          Canvas.LineTo(ptCenter.X + 3, ptCenter.Y);
        end;
      cfHideStart:
        begin
          // [.]
          Canvas.MoveTo(ptCenter.X, ptCenter.Y);
          Canvas.LineTo(ptCenter.X + 1, ptCenter.Y);
        end;
      cfCollapsedFold:
        begin
          // [+]
          Canvas.MoveTo(ptCenter.X - 2, ptCenter.Y);
          Canvas.LineTo(ptCenter.X + 3, ptCenter.Y);
          Canvas.MoveTo(ptCenter.X, ptCenter.Y - 2);
          Canvas.LineTo(ptCenter.X, ptCenter.Y + 3);
        end;
      cfCollapsedHide:
        begin
          if isPrevLine then begin
            // [v]
            Points[0].X := ptCenter.X;
            Points[0].y := ptCenter.Y - 2;
            Points[1].X := ptCenter.X - 2;
            Points[1].y := ptCenter.Y;
            Points[2].X := ptCenter.X + 2;
            Points[2].y := ptCenter.Y;
            Points[3].X := ptCenter.X;
            Points[3].y := ptCenter.Y - 2;
          end else begin
            // [v]
            Points[0].X := ptCenter.X;
            Points[0].y := ptCenter.Y + 2;
            Points[1].X := ptCenter.X - 2;
            Points[1].y := ptCenter.Y;
            Points[2].X := ptCenter.X + 2;
            Points[2].y := ptCenter.Y;
            Points[3].X := ptCenter.X;
            Points[3].y := ptCenter.Y + 2;
          end;
          Canvas.Polygon(Points);
        end;
    end;
    Canvas.Pen.Color := MarkupInfo.Foreground;
    Canvas.Brush.Style := bsSolid;
  end;

  procedure DrawParagraphContinue(rcCodeFold: TRect);
  var
    iCenter : integer;
  begin
    //center of the draw area
    iCenter := (rcCodeFold.Left + rcCodeFold.Right) div 2;

    Canvas.MoveTo(iCenter, rcCodeFold.Top + LineOffset);
    Canvas.LineTo(iCenter, rcCodeFold.Bottom);
    LineOffset := 0;
  end;

  procedure DrawParagraphEnd(rcCodeFold: TRect);
  var
    X : Integer;
  begin
    //center of the draw area
    X := (rcCodeFold.Left + rcCodeFold.Right) div 2;

    Canvas.MoveTo(X, rcCodeFold.Top + LineOffset);
    Canvas.LineTo(X, rcCodeFold.Bottom - 1);
    Canvas.LineTo(rcCodeFold.Right, rcCodeFold.Bottom - 1);
    LineOffset := min(2, (rcCodeFold.Top + rcCodeFold.Bottom) div 2);
  end;

begin
  if not Visible then exit;
  LineHeight := TSynEdit(SynEdit).LineHeight;
  LineOffset := 0;
  if (FirstLine > 0) and
     (FFoldView.FoldType[FirstLine-1] - [cfFoldBody] = [cfFoldEnd]) then
    LineOffset := 2;
  BoxSize := Min(Width, LineHeight - cNodeOffset*2);

  if MarkupInfo.Background <> clNone then
  begin
    Canvas.Brush.Color := MarkupInfo.Background;
    LCLIntf.SetBkColor(Canvas.Handle, Canvas.Brush.Color);
    Canvas.FillRect(AClip);
  end;

  with Canvas do
  begin
    Pen.Color := MarkupInfo.Foreground;
    Pen.Width := 1;

    rcLine.Bottom := FirstLine * LineHeight;
    for iLine := FirstLine to LastLine do
    begin
      // next line rect
      rcLine.Top := rcLine.Bottom;
      Inc(rcLine.Bottom, LineHeight);

      rcCodeFold.Left := AClip.Left;
      rcCodeFold.Right := AClip.Left + self.Width;
      rcCodeFold.Top := rcLine.Top;
      rcCodeFold.Bottom := rcLine.Bottom;

      tmp := FoldTypeForLine(iLine);
      case tmp of
        cfFoldStart, cfHideStart, cfCollapsedFold, cfCollapsedHide:
          DrawNodeBox(rcCodeFold, tmp);
        cfFoldBody:
          DrawParagraphContinue(rcCodeFold);
        cfFoldEnd:
          DrawParagraphEnd(rcCodeFold);
        else
          LineOffset := 0;
      end;
    end;
  end;

end;

{ TSynEditMouseActionsGutterFold }

procedure TSynEditMouseActionsGutterFold.ResetDefaults;
begin
  Clear;
  AddCommand(emcCodeFoldContextMenu, False, mbRight, ccSingle, cdUp, [], []);
  AddCommand(emcCodeFoldCollaps, False, mbMiddle, ccAny, cdDown, [], [ssShift], emcoCodeFoldCollapsOne);
  AddCommand(emcCodeFoldCollaps, False, mbMiddle, ccAny, cdDown, [ssShift], [ssShift], emcoCodeFoldCollapsAll);
  AddCommand(emcNone, False, mbLeft, ccAny, cdDown, [], []);
end;

{ TSynEditMouseActionsGutterFoldExpanded }

procedure TSynEditMouseActionsGutterFoldExpanded.ResetDefaults;
begin
  Clear;
  AddCommand(emcCodeFoldCollaps, False, mbLeft, ccAny, cdDown, [], [], emcoCodeFoldCollapsOne);
end;

{ TSynEditMouseActionsGutterFoldCollapsed }

procedure TSynEditMouseActionsGutterFoldCollapsed.ResetDefaults;
begin
  Clear;
  AddCommand(emcCodeFoldExpand, False, mbLeft, ccAny, cdDown, [ssCtrl], [ssCtrl], emcoCodeFoldExpandOne);
  AddCommand(emcCodeFoldExpand, False, mbLeft, ccAny, cdDown, [], [ssCtrl], emcoCodeFoldExpandAll);
end;

end.

