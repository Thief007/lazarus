{
/***************************************************************************
                             LazDocFrm.pas
                             -------------

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
}

{
  see for todo list: http://wiki.lazarus.freepascal.org/index.php/LazDoc
}

unit LazDocFrm;

{$mode objfpc}{$H+}

{$define dbgLazDoc}

interface

uses
  Buttons,
  Classes,
  ComCtrls,
  Controls,
  Dialogs,
  DOM,
  Forms,
  Graphics,
  IDEProcs,
  LazarusIDEStrConsts,
  LCLProc,
  LResources,
  StdCtrls,
  StrUtils,
  SynEdit,
  SysUtils,
  XMLread,
  XMLwrite;

type
  TFPDocNode = record
    Short: String;
    Descr: String;
    Errors: String;
  end;

  { TLazDocForm }

  TLazDocForm = class(TForm)
    DescrMemo: TMemo;
    ShortEdit: TEdit;
    ErrorsMemo: TMemo;
    PageControl: TPageControl;
    DescrTabSheet: TTabSheet;
    ErrorsTabSheet: TTabSheet;
    ShortTabSheet: TTabSheet;
    procedure DocumentationTagChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { private declarations }
    FChanged: Boolean;
    FDocFileName: String;
    FCurrentElement: String;
    FLastElement: String;
    procedure SetDocFileName(Value: String);
    function NodeByName(ElementName: String): TDOMNode;
    function GetFirstChildValue(n: TDOMNode): String;
    function ElementFromNode(Node: TDOMNode): TFPDocNode;
    function ExtractFuncProc(startpos: tpoint; keyword: String;
      src: tStrings): String;
    function GetNearestSourceElement(source: tStrings;
      caretpos: tpoint): String;
    procedure SetCaption;
    procedure Save;
  public
    { public declarations }
    procedure Reset;
    procedure UpdateLazDoc(source: TStrings; pos: TPoint);
    property DocFileName: String read FDocFileName write SetDocFileName;
  end;

var
  LazDocForm: TLazDocForm;
  doc: TXMLdocument = Nil; //maybe better to make it a member field of TLazFormDoc

procedure DoShowLazDoc;

implementation

{ TLazDocForm }

procedure DoShowLazDoc;
begin
  if LazDocForm = Nil then
    Application.CreateForm(TLazDocForm, LazDocForm);

  LazDocForm.Show;
end;

procedure TLazDocForm.SetDocFileName(Value: String);
begin
  if FileExists(Value) and (Value <> FDocFileName) then
  begin
    //reset Self
    Reset;

    FDocFileName := Value;

    if Assigned(doc) then
      FreeAndNil(doc);

    ReadXMLFile(doc, FDocFileName);

    SetCaption;

    {$ifdef dbgLazDoc}
    DebugLn('TLazDocForm.SetDocFileName: document is set: ' + Value);
    {$endif}

  end;
end;

procedure TLazDocForm.FormCreate(Sender: TObject);
begin
  Caption := lisLazDocMainFormCaption;

  with PageControl do
  begin
    Page[0].Caption := lisLazDocShortTag;
    Page[1].Caption := lisLazDocDescrTag;
    Page[2].Caption := lisLazDocErrorsTag;
    PageIndex := 0;
  end;

  Reset;

  FChanged := False;
end;

function TLazDocForm.NodeByName(ElementName: String): TDOMNode;
var
  n: TDOMNode;
begin
  Result := Nil;

  if not Assigned(doc) then
  begin
    {$ifdef dbgLazDoc}
    DebugLn('TLazDocForm.NodeByName: document is not set');
    {$endif}

    Exit;
  end;

  //get first node
  n := doc.FindNode('fpdoc-descriptions');

  //proceed to package (could there be more packages in one file??)
  n := n.FirstChild;

  //proceed to module  (could there be more modules in one file??)
  n := n.FirstChild;
  while n.NodeName <> 'module' do
    n := n.NextSibling;

  //proceed to element
  n := n.FirstChild;
  while n.NodeName <> 'element' do
    n := n.NextSibling;

  //search elements for ElementName
  while Assigned(n) and (TDomElement(n)['name'] <> ElementName) do
  begin
    n := n.NextSibling;

    if not Assigned(n) then
      Exit;

    while n.NodeName = '#comment' do
      n := n.NextSibling;
  end;

  {$ifdef dbgLazDoc}
  DebugLn('TLazDocForm.NodeByName: element node found where name is: ' +
    ElementName);
  {$endif}

  Result := n;
end;

function TLazDocForm.GetFirstChildValue(n: TDOMNode): String;
begin
  if Assigned(n.FirstChild) then
  begin
    {$ifdef dbgLazDoc}
    DebugLn('TLazDocForm.GetFirstChildValue: retrieving node ' +
      n.NodeName + '=' + n.FirstChild.NodeValue);
    {$endif}

    Result := n.FirstChild.NodeValue;
  end
  else
  begin
    {$ifdef dbgLazDoc}
    DebugLn('TLazDocForm.GetFirstChildValue: retrieving empty node ' +
      n.NodeName);
    {$endif}

    Result := '';
  end;
end;

function TLazDocForm.ElementFromNode(Node: TDOMNode): TFPDocNode;
var
  S: String;
begin
  Node := Node.FirstChild;
  while Assigned(Node) do
  begin
    if (Node.NodeType = ELEMENT_NODE) then
    begin
      S := Node.NodeName;

      if S = 'short' then
        Result.Short := GetFirstChildValue(Node);

      if S = 'descr' then
        Result.Descr := GetFirstChildValue(Node);

      if S = 'errors' then
        Result.Errors := GetFirstChildValue(Node);
    end;
    Node := Node.NextSibling;
  end;
end;

function TLazDocForm.ExtractFuncProc(startpos: tpoint;
  keyword: String; src: tStrings): String;
var
  xpos: Integer;
  ypos: Integer;
begin
  xpos := Succ(startpos.x + length(keyword));
  ypos := startpos.y;

  result := '';
  while (src[ypos][xpos] <> '(') and (src[ypos][xpos] <> ';') and
    (src[ypos][xpos] <> ':') do
  begin
    Result := Result + src[ypos][xpos];
    Inc(xpos);
    if xpos > length(src[ypos]) then
    begin
      xpos := 0;
      Inc(ypos);
    end;
  end;
end;

function TLazDocForm.GetNearestSourceElement(source: tStrings;
  caretpos: tpoint): String;
var
  xpos: Integer;
  ypos: Integer;
begin
  //find preceding keyword
  xpos := Succ(caretpos.x);
  ypos := caretpos.y;
  while (xpos > 0) or (ypos > 0) do
  begin
    Dec(xpos);

    if xpos < 0 then
    begin
      Dec(ypos);
      xpos := length(source[ypos]);
    end;

    //check for keywords
    if PosEx('procedure', source[ypos], xpos) = 1 then
    begin
      Result := ExtractFuncProc(Point(xpos, ypos), 'procedure', source);
      Exit;
    end;
    if PosEx('function', source[ypos], xpos) = 1 then
    begin
      Result := ExtractFuncProc(Point(xpos, ypos), 'function', source);
      Exit;
    end;
    if PosEx('constructor', source[ypos], xpos) = 1 then
    begin
      Result := ExtractFuncProc(Point(xpos, ypos), 'constructor', source);
      Exit;
    end;
    if PosEx('desctructor', source[ypos], xpos) = 1 then
    begin
      Result := ExtractFuncProc(Point(xpos, ypos), 'desctructor', source);
      Exit;
    end;
  end;
end;

procedure TLazDocForm.SetCaption;
var
  strCaption: String;
begin
  strCaption := lisLazDocMainFormCaption + ' - ';

  if FCurrentElement <> '' then
    strCaption := strCaption + FCurrentElement + ' - '
  else
    strCaption := strCaption + lisLazDocNoTagCaption + ' - ';

  if FDocFileName <> '' then
    Caption := strCaption + FDocFileName
  else
    Caption := strCaption + lisLazDocNoTagCaption;
end;

procedure TLazDocForm.Reset;
begin
  FreeAndNil(Doc);
  FCurrentElement := '';
  FDocFileName    := '';
  SetCaption;

  //clear all element editors/viewers
  ShortEdit.Clear;
  DescrMemo.Clear;
  ErrorsMemo.Clear;

  FChanged := False;
end;

procedure TLazDocForm.UpdateLazDoc(source: TStrings; pos: TPoint);
var
  dn: TFPDocNode;
  n:  TDOMNode;
  EnabledState: Boolean;
begin
  if not Assigned(doc) then
  begin
    {$ifdef dbgLazDoc}
    DebugLn('TLazDocForm.UpdateLazDoc: document is not set');
    {$endif}

    Exit;
  end;

  FCurrentElement := GetNearestSourceElement(source, pos);

  SetCaption;

  //do not continue if FCurrentElement=FLastElement
  //or FCurrentElement is empty (J. Reyes)
  if (FCurrentElement = FLastElement) or (FCurrentElement = '') then
    Exit;

  FLastElement := FCurrentElement;

  n := NodeByName(FCurrentElement);

  EnabledState := Assigned(n);

  ShortEdit.Enabled := True;
  DescrMemo.Enabled := True;
  ErrorsMemo.Enabled := True;

  if Assigned(n) then
  begin
    dn := ElementFromNode(n);

    ShortEdit.Text := dn.Short;
    DescrMemo.Lines.Text := ConvertLineEndings(dn.Descr);
    ErrorsMemo.Lines.Text := ConvertLineEndings(dn.Errors);
  end
  else
  begin
    ShortEdit.Text := lisLazDocNoDocumentation;
    DescrMemo.Lines.Text := lisLazDocNoDocumentation;
    ErrorsMemo.Lines.Text := lisLazDocNoDocumentation;
  end;

  FChanged := False;

  ShortEdit.Enabled := EnabledState;
  DescrMemo.Enabled := EnabledState;
  ErrorsMemo.Enabled := EnabledState;
end;

procedure TLazDocForm.Save;
var
  n: TDOMNode;
  S: String;
  child: TDOMNode;

begin
  //nothing changed, so exit
  if not FChanged then
    Exit;

  n := NodeByName(FCurrentElement);

  if not Assigned(n) then
    Exit;

  n := n.FirstChild;
  while Assigned(n) do
  begin
    if (n.NodeType = ELEMENT_NODE) then
    begin
      S := n.NodeName;

      if S = 'short' then
        if not Assigned(n.FirstChild) then
        begin
          child := doc.CreateTextNode(ShortEdit.Text);
          n.AppendChild(child);
        end
        else
          n.FirstChild.NodeValue := ShortEdit.Text;

      if S = 'descr' then
        if not Assigned(n.FirstChild) then
        begin
          child := doc.CreateTextNode(StringListToText(DescrMemo.Lines, #10));
          n.AppendChild(child);
        end
        else
          n.FirstChild.NodeValue := StringListToText(DescrMemo.Lines, #10);

      if S = 'errors' then
        if not Assigned(n.FirstChild) then
        begin
          child := doc.CreateTextNode(StringListToText(ErrorsMemo.Lines, #10));
          n.AppendChild(child);
        end
        else
          n.FirstChild.NodeValue := StringListToText(ErrorsMemo.Lines, #10);

    end;
    n := n.NextSibling;
  end;

  WriteXMLFile(doc, FDocFileName);

  FChanged := False;
end;

procedure TLazDocForm.DocumentationTagChange(Sender: TObject);
begin
  FChanged := True;
end;

initialization
  {$I lazdocfrm.lrs}

finalization
  FreeAndNil(doc)

end.
