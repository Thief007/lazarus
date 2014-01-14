{ $Id$}
{
 *****************************************************************************
 *                               CarbonWSArrow.pp                                * 
 *                               ------------                                * 
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
unit CarbonWSArrow;

{$mode objfpc}{$H+}

interface

uses
////////////////////////////////////////////////////
// I M P O R T A N T                                
////////////////////////////////////////////////////
// To get as little as posible circles,
// uncomment only when needed for registration
////////////////////////////////////////////////////
  Arrow,
////////////////////////////////////////////////////
  WSArrow, WSLCLClasses;

type

  { TCarbonWSArrow }

  TCarbonWSArrow = class(TWSArrow)
  private
  protected
  public
    class procedure SetType(const AArrow: TArrow; const AArrowType: TArrowType;
      const AShadowType: TShadowType); override;
  end;


implementation

{ TCarbonWSArrow }

class procedure TCarbonWSArrow.SetType(const AArrow: TArrow;
  const AArrowType: TArrowType; const AShadowType: TShadowType);
begin
  // TODO
end;

initialization

////////////////////////////////////////////////////
// I M P O R T A N T
////////////////////////////////////////////////////
// To improve speed, register only classes
// which actually implement something
////////////////////////////////////////////////////
  RegisterWSComponent(TArrow, TCarbonWSArrow);
////////////////////////////////////////////////////
end.