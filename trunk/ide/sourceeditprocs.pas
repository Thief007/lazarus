{
/***************************************************************************
                             sourceeditprocs.pas
                             -------------------

 ***************************************************************************/

 ***************************************************************************
 *                                                                         *
 *   This source is free software; you can redistribute it and/or modify   *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This code is distributed in the hope that it will be useful, but      *
 *   WITHOUT ANY WARRANTY; without even the implied warranty of            *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU     *
 *   General Public License for more details.                              *
 *                                                                         *
 *   A copy of the GNU General Public License is available on the World    *
 *   Wide Web at <http://www.gnu.org/copyleft/gpl.html>. You can also      *
 *   obtain it by writing to the Free Software Foundation,                 *
 *   Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.        *
 *                                                                         *
 ***************************************************************************

  Support functions and types for the source editor.

}
unit SourceEditProcs;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LCLProc, BasicCodeTools, CodeTree, CodeToolManager,
  PascalParserTool, IdentCompletionTool, GraphType, Graphics,
  TextTools, EditorOptions,
  SynEdit, SynRegExpr, SynCompletion, MainIntf;

type
  TCompletionType = (
    ctNone, ctWordCompletion, ctTemplateCompletion, ctIdentCompletion);
  TIdentComplValue = (
    icvIdentifier, icvProcWithParams, icvIndexedProp);

// completion form and functions
function PaintCompletionItem(const AKey: string; ACanvas: TCanvas;
  X, Y, MaxX: integer; ItemSelected: boolean; Index: integer;
  aCompletion : TSynCompletion; CurrentCompletionType: TCompletionType;
  MeasureOnly: Boolean = False): TPoint;

function GetIdentCompletionValue(aCompletion : TSynCompletion;
  var ValueType: TIdentComplValue; var CursorToLeft: integer): string;
function BreakLinesInText(const s: string; MaxLineLength: integer): string;

implementation

var
  SynREEngine: TRegExpr;

function PaintCompletionItem(const AKey: string; ACanvas: TCanvas;
  X, Y, MaxX: integer; ItemSelected: boolean; Index: integer;
  aCompletion : TSynCompletion; CurrentCompletionType: TCompletionType;
  MeasureOnly: Boolean): TPoint;
var
  BGRed: Integer;
  BGGreen: Integer;
  BGBlue: Integer;
  TokenStart: Integer;

  function InvertColor(AColor: TColor): TColor;
  var Red, Green, Blue: integer;
  begin
    Red:=(AColor shr 16) and $ff;
    Green:=(AColor shr 8) and $ff;
    Blue:=AColor and $ff;
    if Abs($80-Red)+Abs($80-Green)+Abs($80-Blue)<$140 then begin
      Red:=Red+$a0;
      Green:=Green+$a0;
      Blue:=Blue+$a0;
    end else begin
      Red:=$ff-Red;
      Green:=$ff-Green;
      Blue:=$ff-Blue;
    end;
    Result:=((Red and $ff) shl 16)+((Green and $ff) shl 8)+(Blue and $ff);
  end;

  procedure SetFontColor(NewColor: TColor);
  var
    FGRed: Integer;
    FGGreen: Integer;
    FGBlue: Integer;
  begin
    FGRed:=(NewColor shr 16) and $ff;
    FGGreen:=(NewColor shr 8) and $ff;
    FGBlue:=NewColor and $ff;
    if Abs(FGRed-BGRed)+Abs(FGGreen-BGGreen)+Abs(FGBlue-BGBlue)<$180 then
      NewColor:=InvertColor(NewColor);
    ACanvas.Font.Color:=NewColor;
  end;
  
  procedure WriteToken(var TokenStart, TokenEnd: integer);
  var
    CurToken: String;
  begin
    if TokenStart>=1 then begin
      CurToken:=copy(AKey,TokenStart,TokenEnd-TokenStart);
      if MeasureOnly then
        Inc(Result.X, ACanvas.TextWidth(CurToken))
      else
        ACanvas.TextOut(x+1, y, CurToken);
      x := x + ACanvas.TextWidth(CurToken);
      //debugln('Paint A Text="',CurToken,'" x=',dbgs(x),' y=',dbgs(y),' "',ACanvas.Font.Name,'" ',dbgs(ACanvas.Font.Height),' ',dbgs(ACanvas.TextWidth(CurToken)));
      TokenStart:=0;
    end;
  end;
  
  
var
  i: Integer;
  s: string;
  IdentItem: TIdentifierListItem;
  AColor: TColor;
  ANode: TCodeTreeNode;
  BackgroundColor: TColor;
begin
  Result.X := 0;
  Result.Y := ACanvas.TextHeight('W');
  if CurrentCompletionType=ctIdentCompletion then begin
    // draw
    IdentItem:=CodeToolBoss.IdentifierList.FilteredItems[Index];
    if IdentItem=nil then begin
      if not MeasureOnly then
        ACanvas.TextOut(x+1, y, 'PaintCompletionItem: BUG in codetools');
      exit;
    end;
    BackgroundColor:=ACanvas.Brush.Color;
    BGRed:=(BackgroundColor shr 16) and $ff;
    BGGreen:=(BackgroundColor shr 8) and $ff;
    BGBlue:=BackgroundColor and $ff;

    // first write the type
    // var, procedure, property, function, type, const
    case IdentItem.GetDesc of

    ctnVarDefinition:
      begin
        AColor:=clMaroon;
        s:='var';
      end;

    ctnTypeDefinition, ctnEnumerationType:
      begin
        AColor:=clDkGray;
        s:='type';
      end;

    ctnConstDefinition:
      begin
        AColor:=clOlive;
        s:='const';
      end;
      
    ctnProcedure:
      if (IdentItem.Node<>nil)
      and IdentItem.Tool.NodeIsFunction(IdentItem.Node) then begin
        AColor:=clTeal;
        s:='function';
      end else begin
        AColor:=clNavy;
        s:='procedure';
      end;
      
    ctnProperty:
      begin
        AColor:=clPurple;
        s:='property';
      end;
      
    ctnEnumIdentifier:
      begin
        AColor:=clOlive;
        s:='enum';
      end;
      
    ctnUnit:
      begin
        AColor:=clBlack;
        s:='unit';
      end;

    else
      AColor:=clGray;
      s:='';
    end;

    SetFontColor(AColor);
    if MeasureOnly then
      Inc(Result.X, ACanvas.TextWidth('procedure '))
    else
      ACanvas.TextOut(x+1,y,s);
    inc(x,ACanvas.TextWidth('procedure '));
    if x>MaxX then exit;

    SetFontColor(clBlack);
    ACanvas.Font.Style:=ACanvas.Font.Style+[fsBold];
    s:=GetIdentifier(IdentItem.Identifier);
    if MeasureOnly then
      Inc(Result.X, ACanvas.TextWidth(s))
    else
      ACanvas.TextOut(x+1,y,s);
    inc(x,ACanvas.TextWidth(s));
    if x>MaxX then exit;
    ACanvas.Font.Style:=ACanvas.Font.Style-[fsBold];

    if IdentItem.Node<>nil then begin
      case IdentItem.Node.Desc of

      ctnProcedure:
        begin
          s:=IdentItem.Tool.ExtractProcHead(IdentItem.Node,
            [phpWithoutClassName,phpWithoutName,phpWithVarModifiers,
             phpWithParameterNames,phpWithDefaultValues,phpWithResultType,
             phpWithOfObject]);
        end;

      ctnProperty:
        begin
          s:=IdentItem.Tool.ExtractProperty(IdentItem.Node,
            [phpWithoutName,phpWithVarModifiers,
             phpWithParameterNames,phpWithDefaultValues,phpWithResultType]);
        end;

      ctnVarDefinition:
        begin
          ANode:=IdentItem.Tool.FindTypeNodeOfDefinition(IdentItem.Node);
          s:=' : '+IdentItem.Tool.ExtractNode(ANode,[]);
        end;

      ctnTypeDefinition:
        begin
          ANode:=IdentItem.Tool.FindTypeNodeOfDefinition(IdentItem.Node);
          s:=' = '+IdentItem.Tool.ExtractNode(ANode,[]);
        end;

      ctnConstDefinition:
        begin
          ANode:=IdentItem.Tool.FindTypeNodeOfDefinition(IdentItem.Node);
          if ANode<>nil then
            s:=' = '+IdentItem.Tool.ExtractNode(ANode,[])
          else begin
            s:=IdentItem.Tool.ExtractCode(IdentItem.Node.StartPos+length(s),
                                          IdentItem.Node.EndPos,[]);
          end;
        end;

      else
        exit;

      end;
    end else begin
      // IdentItem.Node=nil
      exit;
    end;
    
    SetFontColor(clBlack);
    if MeasureOnly then
      Inc(Result.X, ACanvas.TextWidth(s))
    else
      ACanvas.TextOut(x+1,y,s);

  end else begin
    // parse AKey for text and style
    i := 1;
    TokenStart:=0;
    while i <= Length(AKey) do begin
      case AKey[i] of
      #1, #2:
        begin
          WriteToken(TokenStart,i);
          // set color
          ACanvas.Font.Color := (Ord(AKey[i + 3]) shl 8
                        + Ord(AKey[i + 2])) shl 8
                        + Ord(AKey[i + 1]);
          inc(i, 4);
        end;
      #3:
        begin
          WriteToken(TokenStart,i);
          // set style
          case AKey[i + 1] of
          'B': ACanvas.Font.Style := ACanvas.Font.Style + [fsBold];
          'b': ACanvas.Font.Style := ACanvas.Font.Style - [fsBold];
          'U': ACanvas.Font.Style := ACanvas.Font.Style + [fsUnderline];
          'u': ACanvas.Font.Style := ACanvas.Font.Style - [fsUnderline];
          'I': ACanvas.Font.Style := ACanvas.Font.Style + [fsItalic];
          'i': ACanvas.Font.Style := ACanvas.Font.Style - [fsItalic];
          end;
          inc(i, 2);
        end;
      else
        if TokenStart<1 then TokenStart:=i;
        inc(i);
      end;
    end;
    WriteToken(TokenStart,i);
  end;
end;

function GetIdentCompletionValue(aCompletion : TSynCompletion;
  var ValueType: TIdentComplValue; var CursorToLeft: integer): string;
var
  Index: Integer;
  IdentItem: TIdentifierListItem;
  IdentList: TIdentifierList;
  CursorAtEnd: boolean;
begin
  Result:='';
  CursorToLeft:=0;
  CursorAtEnd:=true;
  ValueType:=icvIdentifier;
  Index:=aCompletion.Position;
  IdentList:=CodeToolBoss.IdentifierList;

  IdentItem:=IdentList.FilteredItems[Index];
  if IdentItem=nil then exit;

  if not CodeToolBoss.IdentItemCheckHasChilds(IdentItem) then begin
    MainIDEInterface.DoJumpToCodeToolBossError;
    exit;
  end;

  Result:=GetIdentifier(IdentItem.Identifier);

  case IdentItem.GetDesc of

    ctnProcedure:
      if IdentItem.IsProcNodeWithParams then
        ValueType:=icvProcWithParams;

    ctnProperty:
      if IdentItem.IsPropertyWithParams then
        ValueType:=icvIndexedProp;

  end;

  // add brackets for parameter lists
  case ValueType of
  
    icvProcWithParams:
      if (not IdentList.StartUpAtomBehindIs('('))
      and (not IdentList.StartUpAtomInFrontIs('@')) then begin
        Result:=Result+'()';
        inc(CursorToLeft);
        CursorAtEnd:=false;
      end;

    icvIndexedProp:
      if (not IdentList.StartUpAtomBehindIs('[')) then begin
        Result:=Result+'[]';
        inc(CursorToLeft);
        CursorAtEnd:=false;
      end;
  end;

  {if (ilcfStartIsLValue in IdentList.ContextFlags)
  and (not IdentItem.HasChilds)
  and IdentItem.CanBeAssigned
  then begin
    Result:=Result+' := ';
    CursorAtEnd:=false;
  end;}

  // add semicolon for statement ends
  if (ilcfContextNeedsEndSemicolon in IdentList.ContextFlags) then begin
    Result:=Result+';';
    if (not CursorAtEnd) or IdentItem.HasChilds
    or (ilcfStartIsLValue in IdentList.ContextFlags) then
      inc(CursorToLeft);
  end;
end;

function BreakLinesInText(const s: string; MaxLineLength: integer): string;
begin
  Result:=BreakString(s,MaxLineLength,GetLineIndent(s,1));
end;

procedure InitSynREEngine;
begin
  if SynREEngine=nil then
    SynREEngine:=TRegExpr.Create;
end;

function SynREMatches(const TheText, RegExpr, ModifierStr: string): boolean;
begin
  InitSynREEngine;
  SynREEngine.ModifierStr:=ModifierStr;
  SynREEngine.Expression:=RegExpr;
  Result:=SynREEngine.Exec(TheText);
end;

function SynREVar(Index: Integer): string;
begin
  if SynREEngine<>nil then
    Result:=SynREEngine.Match[Index]
  else
    Result:='';
end;

procedure SynREVarPos(Index: Integer; var MatchStart, MatchLength: integer);
begin
  if SynREEngine<>nil then begin
    MatchStart:=SynREEngine.MatchPos[Index];
    MatchLength:=SynREEngine.MatchLen[Index];
  end else begin
    MatchStart:=-1;
    MatchLength:=-1;
  end;
end;

function SynREVarCount: Integer;
begin
  if SynREEngine<>nil then
    Result:=SynREEngine.SubExprMatchCount
  else
    Result:=0;
end;

function SynREReplace(const TheText, FindRegExpr, ReplaceRegExpr: string;
  UseSubstutition: boolean; const ModifierStr: string): string;
begin
  InitSynREEngine;
  SynREEngine.ModifierStr:=ModifierStr;
  SynREEngine.Expression:=FindRegExpr;
  Result:=SynREEngine.Replace(TheText,ReplaceRegExpr,UseSubstutition);
end;

procedure SynRESplit(const TheText, SeparatorRegExpr: string; Pieces: TStrings;
  const ModifierStr: string);
begin
  InitSynREEngine;
  SynREEngine.ModifierStr:=ModifierStr;
  SynREEngine.Expression:=SeparatorRegExpr;
  SynREEngine.Split(TheText,Pieces);
end;

initialization
  REException:=ERegExpr;
  REMatchesFunction:=@SynREMatches;
  REVarFunction:=@SynREVar;
  REVarPosProcedure:=@SynREVarPos;
  REVarCountFunction:=@SynREVarCount;
  REReplaceProcedure:=@SynREReplace;
  RESplitFunction:=@SynRESplit;

finalization
  FreeAndNil(SynREEngine);

end.

