{ $Id$}
{
 *****************************************************************************
 *                             Gtk2WSFileCtrl.pp                             * 
 *                             -----------------                             * 
 *                                                                           *
 *                                                                           *
 *****************************************************************************

 *****************************************************************************
 *                                                                           *
 *  This file is part of the Lazarus Component Library (LCL)                 *
 *                                                                           *
 *  See the file COPYING.modifiedLGPL, included in this distribution,        *
 *  for details about the copyright.                                         *
 *                                                                           *
 *  This program is distributed in the hope that it will be useful,          *
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of           *
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                     *
 *                                                                           *
 *****************************************************************************
}
unit Gtk2WSFileCtrl;

{$mode objfpc}{$H+}

interface

uses
////////////////////////////////////////////////////
// I M P O R T A N T                                
////////////////////////////////////////////////////
// To get as little as posible circles,
// uncomment only when needed for registration
////////////////////////////////////////////////////
//  FileCtrl,
////////////////////////////////////////////////////
  WSFileCtrl, WSLCLClasses;

type

  { TGtk2WSCustomFileListBox }

  TGtk2WSCustomFileListBox = class(TWSCustomFileListBox)
  private
  protected
  public
  end;

  { TGtk2WSFileListBox }

  TGtk2WSFileListBox = class(TWSFileListBox)
  private
  protected
  public
  end;


implementation

initialization

////////////////////////////////////////////////////
// I M P O R T A N T
////////////////////////////////////////////////////
// To improve speed, register only classes
// which actually implement something
////////////////////////////////////////////////////
//  RegisterWSComponent(TCustomFileListBox, TGtk2WSCustomFileListBox);
//  RegisterWSComponent(TFileListBox, TGtk2WSFileListBox);
////////////////////////////////////////////////////
end.