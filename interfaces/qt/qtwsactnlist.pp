{ $Id$}
{
 *****************************************************************************
 *                              qtwsactnlist.pp                              * 
 *                              ---------------                              * 
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
unit qtwsactnlist;

{$mode objfpc}{H+}

interface

uses
////////////////////////////////////////////////////
// I M P O R T A N T                                
////////////////////////////////////////////////////
// To get as litle as posible circles,
// Uncomment only when needed for registration
////////////////////////////////////////////////////
//  actnlist,
////////////////////////////////////////////////////
  wsactnlist, wslclclasses;

type

  { TQtWSCustomActionList }

  TQtWSCustomActionList = class(TWSCustomActionList)
  private
  protected
  public
  end;

  { TQtWSActionList }

  TQtWSActionList = class(TWSActionList)
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
//  RegisterWSComponent(TCustomActionList, TQtWSCustomActionList);
//  RegisterWSComponent(TActionList, TQtWSActionList);
////////////////////////////////////////////////////
end.
