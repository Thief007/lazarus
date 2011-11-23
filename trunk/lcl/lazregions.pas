{
  Implements non-native regions with support for managing their Z-order

  Author: Felipe Monteiro de Carvalho
}
unit lazregions;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils; 

type

  { TLazRegionPart }

  TLazRegionPart = class
  public
    function IsPointInPart(AX, AY: Integer): Boolean; virtual;
  end;

  { TLazRegionRect }

  TLazRegionRect = class(TLazRegionPart)
  public
    Rect: TRect;
    function IsPointInPart(AX, AY: Integer): Boolean; override;
  end;

  TLazRegion = class
  public
    // The parts of a region should all be inside valid areas of the region
    // so if a combination operation removes some areas of the region, then
    // these areas should be removed from all parts of the region
    // There is no z-order for the parts, they are all validly inside the region area
    Parts: TFPList; // of TLazRegionPart
    IsSimpleRectRegion: Boolean; // Indicates whether this region has only 1 rectangular part
    constructor Create; virtual;
    destructor Destroy; override;
    procedure AddRectangle(ARect: TRect);
    function IsPointInRegion(AX, AY: Integer): Boolean; virtual;
  end;

  { This is a region which can hold other region holders inside it }

  { TLazRegionWithChilds }

  TLazRegionWithChilds = class(TLazRegion)
  public
    Parent: TLazRegionWithChilds;
    // The order in this list is also the Z-Order of the sub regions inside it
    // The element with index zero is the bottom-most one
    Childs: TFPList; // of TLazRegionWithChilds
    UserData: TObject; // available link to another object
    constructor Create; override;
    destructor Destroy; override;
    function IsPointInRegion(AX, AY: Integer): TLazRegionWithChilds; virtual;
  end;


implementation

{ TLazRegionPart }

function TLazRegionPart.IsPointInPart(AX, AY: Integer): Boolean;
begin
  Result := False;
end;

{ TLazRegionRect }

function TLazRegionRect.IsPointInPart(AX, AY: Integer): Boolean;
begin
  Result := (AX >= Rect.Left) and (AX < Rect.Right) and
    (AY >= Rect.Top) and (AY < Rect.Bottom);
end;

{ TLazRegion }

constructor TLazRegion.Create;
begin
  inherited Create;
  Parts := TFPList.Create;
end;

destructor TLazRegion.Destroy;
begin
  Parts.Free;
  inherited Destroy;
end;

procedure TLazRegion.AddRectangle(ARect: TRect);
var
  lNewRect: TLazRegionRect;
begin
  lNewRect := TLazRegionRect.Create;
  lNewRect.Rect := ARect;
  Parts.Add(lNewRect);
end;

{
  Checks if a point is inside this region
}
function TLazRegion.IsPointInRegion(AX, AY: Integer): Boolean;
var
  i: Integer;
begin
  Result := False;
  for i := 0 to Parts.Count-1 do
  begin
    if TLazRegionPart(Parts.Items[i]).IsPointInPart(AX, AY) then
    begin
      Result := True;
      Exit;
    end;
  end;
end;

{ TLazRegionWithChilds }

constructor TLazRegionWithChilds.Create;
begin
  inherited Create;
  Childs := TFPList.Create;
end;

destructor TLazRegionWithChilds.Destroy;
begin
  Childs.Free;
  inherited Destroy;
end;

{
  Returns itself or a child, depending on where the point was found
  or nil if the point is neither in the region nor in any children

  Part of the behavior is implemented in TLazRegionWithChilds
}
function TLazRegionWithChilds.IsPointInRegion(AX, AY: Integer): TLazRegionWithChilds;
var
  i: Integer;
  lIsInside: Boolean;
begin
  // First check if it is inside itself
  lIsInside := inherited IsPointInRegion(AX, AY);

  // If it is, then check if it is in any of the children
  if lIsInside then
  begin
    Result := nil;

    for i := 0 to Childs.Count-1 do
    begin
      Result := TLazRegionWithChilds(Childs.Items[i]).IsPointInRegion(AX, AY);
    end;

    // if it wasn't in any sub region, it is really in this region
    if Result = nil then Result := Self;
  end;
end;

end.

