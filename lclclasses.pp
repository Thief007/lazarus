{ $Id$}
{
 *****************************************************************************
 *                               lclclasses.pp                               * 
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
unit lclclasses;

{$mode objfpc}{H+}

interface

uses
  classes, wslclclasses;

type

  { TLCLComponent }

  TLCLComponent = class(TComponent)
  private
    FWidgetSetClass: TWSLCLComponentClass;
  protected
    property WidgetSetClass: TWSLCLComponentClass read FWidgetSetClass;
  public
    class function NewInstance: TObject; override;
  end;

implementation

function TLCLComponent.NewInstance: TObject;
begin
  Result := inherited NewInstance; 
  TLCLComponent(Result).FWidgetSetClass := FindWSComponentClass(Self);
  if TLCLComponent(Result).FWidgetSetClass = nil
  then TLCLComponent(Result).FWidgetSetClass := TWSLCLComponent; 
end;

end.
