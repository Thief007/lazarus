{ $Id$}
{
 *****************************************************************************
 *                               gtkwsgrids.pp                               * 
 *                               -------------                               * 
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
unit gtkwsgrids;

{$mode objfpc}{H+}

interface

uses
////////////////////////////////////////////////////
// I M P O R T A N T                                
////////////////////////////////////////////////////
// To get as litle as posible circles,
// Uncomment only when needed for registration
////////////////////////////////////////////////////
//  grids,
////////////////////////////////////////////////////
  wsgrids, wslclclasses;

type

  { TGtkWSStringCellEditor }

  TGtkWSStringCellEditor = class(TWSStringCellEditor)
  private
  protected
  public
  end;

  { TGtkWSCustomGrid }

  TGtkWSCustomGrid = class(TWSCustomGrid)
  private
  protected
  public
  end;

  { TGtkWSDrawGrid }

  TGtkWSDrawGrid = class(TWSDrawGrid)
  private
  protected
  public
  end;

  { TGtkWSStringGrid }

  TGtkWSStringGrid = class(TWSStringGrid)
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
//  RegisterWSComponent(TStringCellEditor, TGtkWSStringCellEditor);
//  RegisterWSComponent(TCustomGrid, TGtkWSCustomGrid);
//  RegisterWSComponent(TDrawGrid, TGtkWSDrawGrid);
//  RegisterWSComponent(TStringGrid, TGtkWSStringGrid);
////////////////////////////////////////////////////
end.
