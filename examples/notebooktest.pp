{  $Id$  }
{
 /***************************************************************************
                               NoteBookTest.pp  
                             -------------------




 ***************************************************************************/

/***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/
} 
{
@abstract(An example application for TNotebook)
@author(NoteBookTest.pp - Marc Weustink <weus@quicknet.nl>)
}
{$H+}
program NotebookTest;
 
{$mode delphi}

uses
  classes, Controls, forms,buttons,sysutils, stdctrls,
	Graphics, extctrls;

type
	  
  TForm1 = class(TFORM)
    notebook1 : TNotebook;
    Button1: TButton; 
    Button2: TButton; 
    procedure Button1CLick(Sender : TObject);
    procedure Button2CLick(Sender : TObject);
  public
    constructor Create(AOwner: TComponent); override;	
  end;

  
constructor TForm1.Create(AOwner: TComponent);	
begin
  inherited Create(AOwner);
  Caption := 'Notebook Testing';
  Left := 0;
  Top := 0;
  Width := 700; 
  height := 300;
  Position:= poMainFormCenter;

  Button1 := TButton.Create(Self);
  with Button1 do begin
    Top:= 0;
    Left:= 0;
    Width:= 50;
    Height:= 20;
    Parent:= Self;
    Visible:= true;
    Caption := 'Button';
    OnClick := Button1Click;
  end;
  
  Button2 := TButton.Create(Self);
  with Button2 do begin
    Top:= 0;
    Left:= 50;
    Width:= 50;
    Height:= 20;
    Parent:= Self;
    Visible:= true;
    Caption := 'Button';
    OnClick := Button2Click;
  end;

  NoteBook1 := TNoteBook.Create(Self);
  with NoteBook1 do
  begin
    Top:= 25;
    Left:= 0;
    Width:= 650;
    Height:= 250;
    Parent:= Self;
    Visible:= true;
  end;
end;

procedure TForm1.Button1Click(Sender : TObject);
begin
  Notebook1.Pages.Add(Format('[Page %d]', [Notebook1.Pages.Count]));
end;

procedure TForm1.Button2Click(Sender : TObject);
begin
  Notebook1.Pages[Notebook1.PageIndex] := 'Test';
end;

var
  F1: TForm1;

begin
   WriteLN('------ INIT ------- ');
   Application.Initialize; 
   WriteLN('------ CREATE ------- ');
   Application.CreateForm(TForm1, F1);
   WriteLN('------ RUN ------- ');
   Application.Run;
   WriteLN('------ DONE ------- ');
end.