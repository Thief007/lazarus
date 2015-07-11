{ 
 /*************************************************************************** 
                 Interfaces.pp  -  determines what interface to use
                             ------------------- 
 
                   Initial Revision  : Thu July 1st CST 1999 
 
 
 ***************************************************************************/ 
 
 *****************************************************************************
  This file is part of the Lazarus Component Library (LCL)

  See the file COPYING.modifiedLGPL.txt, included in this distribution,
  for details about the license.
 *****************************************************************************
}
unit Interfaces;
 
{$mode objfpc}{$H+} 

{$IFDEF GTK2}
{$ERROR wrong gtk2 interfaces source}
{$ENDIF}

interface

uses 
  InterfaceBase;

implementation

uses 
  GTK1Int, Forms;

initialization
  CreateWidgetset(TGTK1WidgetSet);

finalization
  FreeWidgetSet;

end.
