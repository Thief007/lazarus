{ $Id$}
{
 *****************************************************************************
 *                               wscontrols.pp                               * 
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
unit wscontrols;

{$mode objfpc}{H+}

interface

uses
////////////////////////////////////////////////////
// I M P O R T A N T                                
////////////////////////////////////////////////////
// To get as litle as posible circles,
// Uncomment only when needed for registration
////////////////////////////////////////////////////
//  controls,
////////////////////////////////////////////////////
  wslclclasses, wsimglist;

type

  { TWSDragImageList }

  TWSDragImageList = class(TWSCustomImageList)
  private
  protected
  public
  end;

  { TWSControl }

  TWSControl = class(TWSLCLComponent)
  private
  protected
  public
  end;

  { TWSWinControl }

  TWSWinControl = class(TWSControl)
  private
  protected
  public
  end;

  { TWSGraphicControl }

  TWSGraphicControl = class(TWSControl)
  private
  protected
  public
  end;

  { TWSCustomControl }

  TWSCustomControl = class(TWSWinControl)
  private
  protected
  public
  end;

  { TWSImageList }

  TWSImageList = class(TWSDragImageList)
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
//  RegisterWSComponent(TDragImageList, TWSDragImageList);
//  RegisterWSComponent(TControl, TWSControl);
//  RegisterWSComponent(TWinControl, TWSWinControl);
//  RegisterWSComponent(TGraphicControl, TWSGraphicControl);
//  RegisterWSComponent(TCustomControl, TWSCustomControl);
//  RegisterWSComponent(TImageList, TWSImageList);
////////////////////////////////////////////////////
end.
