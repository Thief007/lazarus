{ $Id$}
{
 *****************************************************************************
 *                           gtkwspairsplitter.pp                            * 
 *                           --------------------                            * 
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
unit gtkwspairsplitter;

{$mode objfpc}{H+}

interface

uses
////////////////////////////////////////////////////
// I M P O R T A N T                                
////////////////////////////////////////////////////
// To get as litle as posible circles,
// Uncomment only when needed for registration
////////////////////////////////////////////////////
//  pairsplitter,
////////////////////////////////////////////////////
  wspairsplitter, wslclclasses;

type

  { TGtkWSPairSplitterSide }

  TGtkWSPairSplitterSide = class(TWSPairSplitterSide)
  private
  protected
  public
  end;

  { TGtkWSCustomPairSplitter }

  TGtkWSCustomPairSplitter = class(TWSCustomPairSplitter)
  private
  protected
  public
  end;

  { TGtkWSPairSplitter }

  TGtkWSPairSplitter = class(TWSPairSplitter)
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
//  RegisterWSComponent(TPairSplitterSide, TGtkWSPairSplitterSide);
//  RegisterWSComponent(TCustomPairSplitter, TGtkWSCustomPairSplitter);
//  RegisterWSComponent(TPairSplitter, TGtkWSPairSplitter);
////////////////////////////////////////////////////
end.
