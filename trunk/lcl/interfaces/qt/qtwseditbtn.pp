{ $Id$}
{
 *****************************************************************************
 *                              qtwseditbtn.pp                               * 
 *                              --------------                               * 
 *                                                                           *
 *                                                                           *
 *****************************************************************************

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
unit qtwseditbtn;

{$mode objfpc}{H+}

interface

uses
////////////////////////////////////////////////////
// I M P O R T A N T                                
////////////////////////////////////////////////////
// To get as litle as posible circles,
// Uncomment only when needed for registration
////////////////////////////////////////////////////
//  editbtn,
////////////////////////////////////////////////////
  wseditbtn, wslclclasses;

type

  { TQtWSCustomEditButton }

  TQtWSCustomEditButton = class(TWSCustomEditButton)
  private
  protected
  public
  end;

  { TQtWSEditButton }

  TQtWSEditButton = class(TWSEditButton)
  private
  protected
  public
  end;

  { TQtWSFileNameEdit }

  TQtWSFileNameEdit = class(TWSFileNameEdit)
  private
  protected
  public
  end;

  { TQtWSDirectoryEdit }

  TQtWSDirectoryEdit = class(TWSDirectoryEdit)
  private
  protected
  public
  end;

  { TQtWSDateEdit }

  TQtWSDateEdit = class(TWSDateEdit)
  private
  protected
  public
  end;

  { TQtWSCalcEdit }

  TQtWSCalcEdit = class(TWSCalcEdit)
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
//  RegisterWSComponent(TCustomEditButton, TQtWSCustomEditButton);
//  RegisterWSComponent(TEditButton, TQtWSEditButton);
//  RegisterWSComponent(TFileNameEdit, TQtWSFileNameEdit);
//  RegisterWSComponent(TDirectoryEdit, TQtWSDirectoryEdit);
//  RegisterWSComponent(TDateEdit, TQtWSDateEdit);
//  RegisterWSComponent(TCalcEdit, TQtWSCalcEdit);
////////////////////////////////////////////////////
end.
