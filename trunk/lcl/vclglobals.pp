{/***************************************************************************
                          vclglobals.pp  -  description
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

unit vclglobals;

{$mode objfpc}{$H+}

interface
//uses
//  glib,gdk,gtk;

const

{These should be moved to the correct area eventually}
WS_EX_CLIENTEDGE = $200;
WS_HSCroll = $100000;
WS_VSCroll = $200000;
WS_BORDER = $800000;
WS_CLIPCHILDREN = $2000000;
{}

csNone = 0;
csAlignment = 1;
csBox = 2;
csButton = 3;
csComboBox = 4;
csCheckbox = 5;
csEdit = 6;
csForm= 7;
csLabel = 8;
csgtkTable = 9;
csScrollBar = 10;
csListView = 11;
csMainForm = 12;
csMemo = 13;
csMainMenu = 14;
csMenuBar = 15;
csMenuItem = 16;
csNotebook = 17;
csFileDialog = 18;
csRadioButton = 19;
csScrolledWindow= 20;
csSpinedit = 21;
csStatusBar = 22;
csTable = 23;
csToggleBox = 24;
//csVScrollBar = 25;
csFrame = 26;
csButtonBox = 27;
csCanvas = 28;
csGroupBox = 29;

csFont = 30;
csPen = 31;
csBrush = 32;
//csTimer = 33;
csPage = 34;

csColorDialog = 35;
csListBox = 36;
csFontDialog = 37;
csProgressBar = 38;
csTrackBar = 39;
csFixed = 40;
csImage = 41;
csToolbar = 42;
csToolButton = 43;
csBitBtn = 44;
csCListBox = 45;
csSpeedButton = 46;
csPopupMenu = 47;
type

  //TODO: check this against lcllinux

TgComponentStyle = LongInt;
AnsiChar = Char;  //Should be moved
WideChar = Char;
Short = SmallInt;
HFont = LongWord;
THAndle = Integer;
hwnd    = THandle;
TCaption = string;
//TMessage = Pointer;
HMENU = type LongWord;
HPEN = type LongWord;
HBitmap = type LongWord;
HPalette = type LongWord;

HDC = type LongWord;
HBRUSH = type LongWord;





const


  {Mouse message key states}
   MK_LBUTTON  = 1;
   MK_RBUTTON = 2;
   MK_SHIFT = 4;
   MK_CONTROL = 8;
   MK_MBUTTON = $10;


{ Generic Key names }
{$I hkeys.inc}

implementation

initialization
//writeln('vclglobals.pp - initialization');

finalization
//writeln('vclglobals.pp - finalization');

end.

