
{/***************************************************************************
                          global.pp  -  description
                             -------------------
    begin                : Tue Apr 6 1999
    copyright            : (C) 1999 by
    email                :
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

unit global;

{$mode objfpc}

interface
uses 
   Classes,sysutils;

type
   TPRojFlags = (pfProject, pfForm, pfSource, pfNone);

   TUnitInfo = class(TObject)
   private
      FName : String;
      FFormName : String;
      FFileName : String;
      FFlags : TProjFlags;
      FSource : TStringList;
      FPage : Integer;
 //   FForm  : TDesignerForm;
      Procedure SetFormName(Value : String);
      Function GetFormName : String;
      Procedure SetPage(Value : Integer);
      Function GetPage : Integer;
   public
      constructor Create;
      destructor Destroy; override;
      Procedure AddControlLine(value : String); //adds the "Edit1 : TEdit" line
      Procedure AddProcedureLine(value : String); //adds the "Procedure TFomr.Button1Click(sender: TObject);" line
      Function FindStartClass(cName: String; LineStart: Integer) : Integer;
      Property Name : String read FName write FName;
      Property FormName: String read GetFormName write SetFormName;
      Property Source : TStringList read FSource write FSource;
      Property Page : Integer read GetPage write SetPage;
      Property FileName : String read FFileName write FFilename;
      Property Flags : TProjFlags read FFlags write FFLags;
//    property Form  : TDesignerForm read fform write fform;

   end;

var
  ActivePage : Integer;

implementation

uses
   mwCustomEdit;

{$I global.inc}

end.


{ =============================================================================

  $Log$
  Revision 1.4  2000/12/19 18:43:12  lazarus
  Removed IDEEDITOR.  This causes the PROJECT class to not function.
  Saving projects no longer works.

  I added TSourceNotebook and TSourceEditor.  They do all the work for saving/closing/opening units.  Somethings work but they are in early development.
  Shane

  Revision 1.3  2000/12/01 18:12:40  lazarus
  Modified Gloabal so TDesignForm isn't included anymore.
  Shane

  Revision 1.2  2000/12/01 15:50:39  lazarus
  changed the TCOmponentInterface SetPropByName.  It works for a few properties, but not all.
  Shane

  Revision 1.1  2000/07/13 10:27:47  michael
  + Initial import

  Revision 1.13  2000/07/09 20:18:55  lazarus
  MWE:
    + added new controlselection
    + some fixes
    ~ some cleanup

  Revision 1.12  2000/06/16 13:33:20  lazarus
  Created a new method for adding controls to the toolbar to be dropped onto the form!
  Shane

  Revision 1.10  2000/06/12 15:54:24  lazarus
  Added grid dots to the form created via New Form.
  Added the mouse speedbutton and when clicked they stay down.
  Shane

  Revision 1.9  2000/03/03 22:58:25  lazarus
  MWE:
    Fixed focussing problem.
      LM-FOCUS was bound to the wrong signal
    Added GetKeyState api func.
      Now LCL knows if shift/trl/alt is pressed (might be handy for keyboard
      selections ;-)

  Revision 1.8  2000/03/03 20:22:02  lazarus
  Trying to add TBitBtn
  Shane

  Revision 1.7  2000/03/01 21:54:05  lazarus
  90% finished with SAVE PROJECT and OPEN PROJECT
  Shane

  Revision 1.6  2000/02/29 23:00:04  lazarus
  Adding code for the ide.
  Shane

  Revision 1.5  1999/05/14 18:44:11  lazarus
  *** empty log message ***

  Revision 1.4  1999/05/07 05:46:51  lazarus
  *** empty log message ***

  Revision 1.3  1999/05/01 04:44:53  lazarus
  *** empty log message ***

  Revision 1.2  1999/04/18 05:42:09  lazarus
  *** empty log message ***

  Revision 1.1  1999/04/14 07:31:44  michael
  + Initial implementation

}
