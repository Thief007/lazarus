{
 /***************************************************************************
                              lazcanvas.pas
                              ---------------

 ***************************************************************************/

 *****************************************************************************
 *                                                                           *
 *  This file is part of the Lazarus Component Library (LCL)                 *
 *                                                                           *
 *  See the file COPYING.modifiedLGPL.txt, included in this distribution,    *
 *  for details about the copyright.                                         *
 *                                                                           *
 *  This program is distributed in the hope that it will be useful,          *
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of           *
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                     *
 *                                                                           *
 *****************************************************************************

  Author: Felipe Monteiro de Carvalho

  Abstract:
    Classes and functions for extending TFPImageCanvas to support more stretching
    filters and to support all features from the LCL TCanvas
}
unit lazcanvas;

{$mode objfpc}{$H+}

interface

uses
  // RTL
  Classes, SysUtils,
  // FCL-Image
  fpimgcanv, fpcanvas, fpimage;

type

  { TFPSharpInterpolation }

  // This does a very sharp and square interpolation for stretching,
  // similar to StretchBlt from the Windows API
  TFPSharpInterpolation = class (TFPCustomInterpolation)
  protected
    procedure Execute (x,y,w,h : integer); override;
  end;

  { TLazCanvas }

  TLazCanvas = class(TFPImageCanvas)
  private
    FAssignedBrush: TFPCustomBrush;
    function GetAssignedBrush: TFPCustomBrush;
  public
    constructor create (AnImage : TFPCustomImage);
    destructor destroy; override;
    // Utilized by LCLIntf.SelectObject
    procedure AssignBrushData(ABrush: TFPCustomBrush);
    // These properties are utilized to implement LCLIntf.SelectObject
    property AssignedBrush: TFPCustomBrush read GetAssignedBrush write FAssignedBrush;
  end;

implementation

{ TLazCanvas }

function TLazCanvas.GetAssignedBrush: TFPCustomBrush;
begin
  if FAssignedBrush = nil then
    Result := TFPEmptyBrush.Create
  else
    Result := FAssignedBrush;
end;

constructor TLazCanvas.create(AnImage: TFPCustomImage);
begin
  inherited Create(AnImage);
end;

destructor TLazCanvas.destroy;
begin
  if FAssignedBrush <> nil then FAssignedBrush.Free;
  inherited destroy;
end;

procedure TLazCanvas.AssignBrushData(ABrush: TFPCustomBrush);
begin
  Brush.FPColor := ABrush.FPColor;
end;

{ TFPWindowsSharpInterpolation }

procedure TFPSharpInterpolation.Execute(x, y, w, h: integer);
// paint Image on Canvas at x,y,w*h
var
  srcx, srcy: Integer; // current coordinates in the source image
  dx, dy: Integer; // current coordinates in the destination canvas
  lWidth, lHeight: Integer; // Image size
begin
  if (w<=0) or (h<=0) or (image.Width=0) or (image.Height=0) then
    exit;

  lWidth := Image.Width-1;
  lHeight := Image.Height-1;

  for dx := 0 to w-1 do
   for dy := 0 to h-1 do
   begin
     srcx := Round((dx / w) * lWidth);
     srcy := Round((dy / w) * lHeight);
     Canvas.Colors[dx+x, dy+y] := Image.Colors[srcx, srcy];
   end;
end;

end.

