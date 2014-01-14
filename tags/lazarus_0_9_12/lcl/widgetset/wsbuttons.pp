{ $Id$}
{
 *****************************************************************************
 *                               WSButtons.pp                                * 
 *                               ------------                                * 
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
unit WSButtons;

{$mode objfpc}{$H+}

interface
////////////////////////////////////////////////////
// I M P O R T A N T                                
////////////////////////////////////////////////////
// 1) Only class methods allowed
// 2) Class methods have to be published and virtual
// 3) To get as little as posible circles, the uses
//    clause should contain only those LCL units 
//    needed for registration. WSxxx units are OK
// 4) To improve speed, register only classes in the 
//    initialization section which actually 
//    implement something
// 5) To enable your XXX widgetset units, look at
//    the uses clause of the XXXintf.pp
////////////////////////////////////////////////////
uses
////////////////////////////////////////////////////
// To get as little as posible circles,
// uncomment only when needed for registration
////////////////////////////////////////////////////
  Buttons, Graphics, 
////////////////////////////////////////////////////
  WSLCLClasses, WSStdCtrls, WSControls, LCLType;

type

  { TWSButton }

  TWSButton = class(TWSButtonControl)
    class procedure ActiveDefaultButtonChanged(const AButton: TCustomButton); virtual;
    class procedure SetShortCut(const AButton: TCustomButton; const OldShortCut, NewShortCut: TShortCut); virtual;
  end;
  TWSButtonClass = class of TWSButton;

  { TWSBitBtn } 
  
  TWSBitBtnClass = class of TWSBitBtn;
  TWSBitBtn = class(TWSButton)
    class procedure SetGlyph(const ABitBtn: TCustomBitBtn; const AValue: TBitmap); virtual;
    class procedure SetLayout(const ABitBtn: TCustomBitBtn; const AValue: TButtonLayout); virtual;
    class procedure SetMargin(const ABitBtn: TCustomBitBtn; const AValue: Integer); virtual;
    class procedure SetSpacing(const ABitBtn: TCustomBitBtn; const AValue: Integer); virtual;
  end;

  { TWSSpeedButton }

  TWSSpeedButton = class(TWSGraphicControl)
  end;


implementation 

// TODO: Can't be virtual abstract ?

{ TWSButton }

procedure TWSButton.ActiveDefaultButtonChanged(const AButton: TCustomButton);
begin
end;

procedure TWSButton.SetShortCut(const AButton: TCustomButton; const OldShortCut, NewShortCut: TShortCut);
begin
end;

{ TWSCustomBitBtn }

procedure TWSBitBtn.SetGlyph(const ABitBtn: TCustomBitBtn;
  const AValue: TBitmap);
begin
end;

procedure TWSBitBtn.SetLayout(const ABitBtn: TCustomBitBtn;
  const AValue: TButtonLayout);
begin
end;

procedure TWSBitBtn.SetMargin(const ABitBtn: TCustomBitBtn;
  const AValue: Integer);
begin
end;

procedure TWSBitBtn.SetSpacing(const ABitBtn: TCustomBitBtn;
  const AValue: Integer);
begin
end;


initialization

////////////////////////////////////////////////////
// To improve speed, register only classes
// which actually implement something
////////////////////////////////////////////////////
//  RegisterWSComponent(TCustomButton, TWSButton);
//  RegisterWSComponent(TCustomBitBtn, TWSBitBtn);
//  RegisterWSComponent(TCustomSpeedButton, TWSSpeedButton);
////////////////////////////////////////////////////
end.