{ $Header$
 /***************************************************************************
                               EditTest.pp
                             -------------------
                           Test aplication for editors
                   Initial Revision  : Sun Dec 31 17:30:00:00 CET 2000




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
@author(Marc Weustink <marc@lazarus.dommelstein.net>)
@created(31-Dec-2000)

Detailed description of the Unit.
}
program EditTest;

{$mode objfpc}{$H+}

uses
  Interfaces,
  StdCtrls, Buttons, Classes, Forms, Controls, SysUtils, Graphics,
  SynEdit, SynHighlighterPas;

type
  TEditTestForm = class(TForm)
  public
    FText: TEdit;
    FEdit: TSynEdit;
    FHighlighter: TSynPasSyn;
    constructor Create(AOwner: TComponent); override;
  end;

var
  EditTestForm: TEditTestForm;

{------------------------------------------------------------------------------}
{  TEditTestorm                                          }
{------------------------------------------------------------------------------}
constructor TEditTestForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := 300;
  Height := 250;
  Left := 200;
  Top := 200;
  Caption := 'Editor tester';

  FHighlighter := TSynPasSyn.Create(Self);
  FHighlighter.CommentAttri.Foreground := clNavy;
  FHighlighter.NumberAttri.Foreground := clRed;
  FHighlighter.KeyAttri.Foreground := clGreen;

  FEdit := TSynEdit.Create(Self);
  with FEdit
  do begin
    Parent := Self;
		Width := 300;
		Height := 200;
    Gutter.Color := clBtnface;
    Gutter.ShowLineNumbers := True;
    Color := clWindow;
    Visible := True;
    Font.Name := 'courier';
    Font.Size := 12;
    HighLighter := Self.FHighLighter;
  end;
  
  FText := TEdit.Create(Self);
  with FText do 
  begin
    Parent := Self;
    Top := 208;
		Width := 300;
		Height := 25;
    Visible := True;
    Font.Name := 'courier';
    Font.Size := 12;
  end;
end;

begin
   Application.Initialize;
   Application.CreateForm(TEditTestForm, EditTestForm);
   Application.Run;
end.

{
  $Log$
  Revision 1.5  2002/10/29 08:22:32  lazarus
  MG: added interfaces unit

  Revision 1.4  2002/05/10 06:57:50  lazarus
  MG: updated licenses

  Revision 1.3  2002/02/05 23:16:48  lazarus
  MWE: * Updated tebugger
       + Added debugger to IDE

  Revision 1.2  2002/02/04 10:54:33  lazarus
  Keith:
    * Fixes for Win32
    * Added new listviewtest.pp example

  Revision 1.1  2000/12/31 15:48:41  lazarus
  MWE:
    + Added Editor test app.

}

