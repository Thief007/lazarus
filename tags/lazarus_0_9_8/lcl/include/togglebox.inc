{%MainUnit ../stdctrls.pp}

{
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
{------------------------------------------------------------------------------}

constructor TToggleBox.Create(TheOwner : TComponent);
begin
  inherited Create(TheOwner);
  fCompStyle := csToggleBox;
  SetInitialBounds(0,0,90,25);
end;

{------------------------------------------------------------------------------}

// included by stdctrls.pp
