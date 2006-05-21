{
 *****************************************************************************
 *                                                                           *
 *  This file is part of the Lazarus Component Library (LCL)                 *
 *                                                                           *
 *  See the file COPYING.LCL, included in this distribution,                 *
 *  for details about the copyright.                                         *
 *                                                                           *
 *  This program is distributed in the hope that it will be useful,          *
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of           *
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                     *
 *                                                                           *
 *****************************************************************************

  LCL Test 4_1

  Showing a form at 0,0,320,240 with a TSynEdit Align=alClient and a TSynPasSyn.
}
program Test4_1Synedit;

{$mode objfpc}{$H+}

uses
  Interfaces, FPCAdds, LCLProc, LCLType, Classes, Controls, Forms, TypInfo,
  LMessages, Buttons, ExtCtrls, ComCtrls, SynEdit, SynHighlighterPas,
  Graphics;

type

  { TForm1 }

  TForm1 = class(TForm)
    SynEdit1: TSynEdit;
    SynPasSyn1: TSynPasSyn;
    procedure Form1Create(Sender: TObject);
  public
    constructor Create(TheOwner: TComponent); override;
  end;

{ TForm1 }

procedure TForm1.Form1Create(Sender: TObject);
begin
  debugln('TForm1.Form1Create ',DbgSName(Sender));
  SetBounds(50,50,950,700);

  SynPasSyn1:=TSynPasSyn.Create(Self);
  with SynPasSyn1 do begin
    Name:='SynPasSyn1';
    CommentAttri.Foreground:=clBlue;
    CommentAttri.Style:=[fsBold];
    NumberAttri.Foreground:=clBlue;
    StringAttri.Foreground:=clBlue;
    SymbolAttri.Foreground:=clRed;
    DirectiveAttri.Foreground:=clRed;
    DirectiveAttri.Style:=[fsBold];
  end;

  SynEdit1:=TSynEdit.Create(Self);
  with SynEdit1 do begin
    Name:='SynEdit1';
    Align:=alClient;
    Highlighter:=SynPasSyn1;
    Parent:=Self;
    Lines.LoadFromFile('../controls.pp');
  end;
end;

constructor TForm1.Create(TheOwner: TComponent);
begin
  OnCreate:=@Form1Create;
  inherited Create(TheOwner);
end;

var
  Form1: TForm1 = nil;
begin
  Application.Initialize;
  Application.CreateForm(TForm1,Form1);
  Application.Run;
end.

