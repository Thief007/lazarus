{ $Id$}
{
 *****************************************************************************
 *                            win32wscontrols.pp                             * 
 *                            ------------------                             * 
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
unit win32wscontrols;

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
  wscontrols, wslclclasses;

type

  { TWin32WSDragImageList }

  TWin32WSDragImageList = class(TWSDragImageList)
  private
  protected
  public
  end;

  { TWin32WSControl }

  TWin32WSControl = class(TWSControl)
  private
  protected
  public
  end;

  { TWin32WSWinControl }

  TWin32WSWinControl = class(TWSWinControl)
  private
  protected
  public
  end;

  { TWin32WSGraphicControl }

  TWin32WSGraphicControl = class(TWSGraphicControl)
  private
  protected
  public
  end;

  { TWin32WSCustomControl }

  TWin32WSCustomControl = class(TWSCustomControl)
  private
  protected
  public
  end;

  { TWin32WSImageList }

  TWin32WSImageList = class(TWSImageList)
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
//  RegisterWSComponent(TDragImageList, TWin32WSDragImageList);
//  RegisterWSComponent(TControl, TWin32WSControl);
//  RegisterWSComponent(TWinControl, TWin32WSWinControl);
//  RegisterWSComponent(TGraphicControl, TWin32WSGraphicControl);
//  RegisterWSComponent(TCustomControl, TWin32WSCustomControl);
//  RegisterWSComponent(TImageList, TWin32WSImageList);
////////////////////////////////////////////////////
end.
