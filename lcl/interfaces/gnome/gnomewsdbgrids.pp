{ $Id$}
{
 *****************************************************************************
 *                             gnomewsdbgrids.pp                             * 
 *                             -----------------                             * 
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
unit gnomewsdbgrids;

{$mode objfpc}{H+}

interface

uses
////////////////////////////////////////////////////
// I M P O R T A N T                                
////////////////////////////////////////////////////
// To get as litle as posible circles,
// Uncomment only when needed for registration
////////////////////////////////////////////////////
//  dbgrids,
////////////////////////////////////////////////////
  wsdbgrids, wslclclasses;

type

  { TGnomeWSCustomDbGrid }

  TGnomeWSCustomDbGrid = class(TWSCustomDbGrid)
  private
  protected
  public
  end;

  { TGnomeWSdbGrid }

  TGnomeWSdbGrid = class(TWSdbGrid)
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
//  RegisterWSComponent(TCustomDbGrid, TGnomeWSCustomDbGrid);
//  RegisterWSComponent(TdbGrid, TGnomeWSdbGrid);
////////////////////////////////////////////////////
end.
