{%MainUnit gnomeint.pas}
{ $Id$ }
(******************************************************************************
  All GNOME Winapi related stuff goes here.

  !! Keep this alphabetical !!
 ******************************************************************************)
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
}

//##apiwiz##sps##   // Do not remove

Function LoadStockPixmap(StockID: longint) : HBitmap; override;

Function PromptUser(const DialogCaption, DialogMessage : String; DialogType : longint;
  Buttons : PLongint; ButtonCount, DefaultIndex, EscapeResult : Longint) : Longint; override;
Function PromptUserAtXY(const DialogCaption, DialogMessage : String; DialogType : longint;
  Buttons : PLongint; ButtonCount, DefaultIndex, EscapeResult : Longint; X, Y : Longint) : Longint; override;

Function RequestInput(const InputCaption, InputPrompt : String; MaskInput : Boolean; var Value : String) : Boolean; override;

//##apiwiz##eps##   // Do not remove
{ =============================================================================
  $Log$
  Revision 1.9  2005/02/23 01:12:46  marc
  + Added RemoveProp winapi call
  * Some maintenace on winapi/lclintf files

  Revision 1.8  2002/10/23 14:36:53  lazarus
  AJ:Fixes to PromptUser;Switched ShowMessage* to use NotifyUser*;
     fixed TGraphicPropertyEditor for when Property is nil.

  Revision 1.7  2002/10/21 03:23:35  lazarus
  AJ: rearranged GTK init stuff for proper GNOME init & less duplication between interfaces

  Revision 1.6  2002/10/14 18:36:57  lazarus
  AJ: Improvements/Fixes to new PromptUser API

  Revision 1.5  2002/10/14 14:29:50  lazarus
  AJ: Improvements to TUpDown; Added TStaticText & GNOME DrawText

  Revision 1.4  2002/10/12 16:36:40  lazarus
  AJ: added new QueryUser/NotifyUser

  Revision 1.3  2002/10/11 16:00:39  lazarus
  AJ: made InputQuery Interface Dependant

  Revision 1.2  2002/10/10 13:29:08  lazarus
  AJ: added LoadStockPixmap routine & minor fixes to/for GNOMEInt

  
}