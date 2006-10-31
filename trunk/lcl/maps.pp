{ $Id$ }
{
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

  Author: Marc Weustink

  Abstract:
    The Map maps an unique ID to arbitrary data. The ID->Data is stored in a
    Average Level binary Tree for fast indexing.
    The map maintans also a linked list beween the ordered items for fast
    iterating throug all elements.
    The ID can be signed or unsigned, with a size of 1,2,4,8,16 or 32 bytes
    The data can be of any (constant) size.
}
unit maps;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, AvgLvlTree;
  
type
  TMapIdType = (itu1, its1, itu2, its2, itu4, its4, itu8, its8, itu16, its16,
                itu32, its32);

  PMapItem = ^TMapItem;

  PMapLink = ^TMapLink;
  TMapLink = record
    Previous, Next: PMapItem;
  end;

  PMapID = ^TMapID;
  TMapID = record
    case TMapIdType of
      itu1: (U1: Byte);
      its1: (S1: ShortInt);
      itu2: (U2: Word);
      its2: (S2: SmallInt);
      itu4: (U4: LongWord);
      its4: (S4: LongInt);
      itu8: (U8: QWord);
      its8: (S8: Int64);
      {$IFDEF ENDIAN_LITTLE}
      itu16: (U16L: QWord; U16H: QWord);
      its16: (S16L: QWord; S16H: Int64);
      itu32: (U32LL: QWord; U32LH: QWord; U32HL: QWord; U32HH: QWord);
      its32: (S32LL: QWord; S32LH: QWord; S32HL: QWord; S32HH: Int64);
      {$ELSE}
      itu16: (U16H: QWord; U16L: QWord);
      its16: (S16H: Int64; S16L: QWord);
      itu32: (U32HH: QWord; U32HL: QWord; U32LH: QWord; U32LL: QWord);
      its32: (S32HH: Int64; S32HL: QWord; S32LH: QWord; S32LL: QWord);
      {$ENDIF}
  end;

  TMapItem = packed record
    Link: TMapLink;
    ID: TMapID
    { Data: record end; }
    { Data follows imediately }
  end;
  
  { TBaseMap }
  
  TBaseMapIterator = class;

  TBaseMap = class(TPersistent)
  private
    FTree: TAvgLvlTree;
    FIdType: TMapIdType;
    FDataSize: Cardinal;
    FFirst: PMapItem;   // First element of our linkedlist
    FLast: PMapItem;    // Last element of our linkedlist
    FIterators: TList;  // A List of iterators iterating us
    function FindNode(const AId): TAvgLvlTreeNode;
    function FindItem(const AId): PMapItem;
    function TreeCompareID(Sender: TAvgLvlTree; AItem1, AItem2: Pointer): Integer;
    //--
    procedure IteratorAdd(AIterator: TBaseMapIterator);
    procedure IteratorRemove(AIterator: TBaseMapIterator);
  protected
    function InternalGetData(AItem: PMapItem; out AData): Boolean;
    function InternalGetDataPtr(AItem: PMapItem): Pointer;
    function InternalGetId(AItem: PMapItem; out AID): Boolean;
    function InternalSetData(AItem: PMapItem; const AData): Boolean;
  public
    procedure Add(const AId, AData);
    constructor Create(AIdType: TMapIdType; ADataSize: Cardinal);
    function Count: Integer;
    function Delete(const AId): Boolean;
    destructor Destroy; override;
  end;
  
  { TBaseMapIterator }

  TBaseMapIterator = class(TObject)
  private
    FMap: TBaseMap;
    FCurrent: PMapItem;
    FInValid: Boolean;           // Set if our current is removed or when a locate failed, in those cases current is next
                                 // will be set to next
    FBOM: Boolean;               // Begin Of Map
    FEOM: Boolean;               // End Of Map
    procedure MapDestroyed;      // Called when outr map is destroyed
    procedure ItemRemove(AData: Pointer); // Called when an Item is removed from the map
  protected
    function InternalLocate(const AId): Boolean; //True if match found. If not found, current is next and Invalid is set
    procedure Validate;
    procedure ValidateMap;
    property Current: PMapItem read FCurrent;
  public
    constructor Create(AMap: TBaseMap);
    destructor Destroy; override;
    procedure First;
    procedure Next;
    procedure Previous;
    procedure Last;
    function Valid: Boolean;     // false if our map is gone

    property BOM: Boolean read FBOM;
    property EOM: Boolean read FEOM;
  end;
  
  { TMap }

  TMap = class(TBaseMap)
  private
  protected
  public
    function HasId(const AID): Boolean;
    function GetData(const AId; out AData): Boolean;
    function GetDataPtr(const AId): Pointer;
    function SetData(const AId, AData): Boolean;
  end;
  
  { TMapIterator }

  TMapIterator = class(TBaseMapIterator)
  private
  protected
  public
    function  DataPtr: Pointer;
    procedure GetData(out AData);
    procedure GetID(out AID);
    function  Locate(const AId): Boolean;
    procedure SetData(const AData);
  end;
  
function MapReport(AMap: TBaseMap): String;

implementation

const
  DUPLICATE_ID = 'Duplicate ID: %s';
  
const
  ID_LENGTH: array[TMapIdType] of Byte = (1,1,2,2,4,4,8,8,16,16,32,32);


function MapReport(AMap: TBaseMap): String;
begin
  if (AMap = nil) or (AMap.FTree = nil)
  then Result := ''
  else Result := AMap.FTree.ReportAsString;
end;


{ TBaseMap }

procedure TBaseMap.Add(const AId, AData);
  procedure Error;
  const
    a: PChar =  '0123456789ABCDEF';
  var
    n: Integer;
    S: String;
    p: PByte;
  begin
    SetLength(S, ID_LENGTH[FIdType] * 2);
    {$IFDEF ENDIAN_BIG}
    p := @AId;
    {$ELSE}
    p := @AId + ID_LENGTH[FIdType] - 1;
    {$ENDIF}
    for n := 1 to ID_LENGTH[FIdType] do
    begin
      S[2 * n - 1] := a[(p^ shr 4) and $F];
      S[2 * n] := a[p^ and $F];
      {$IFDEF ENDIAN_BIG}
      Inc(p);
      {$ELSE}
      Dec(p);
      {$ENDIF}
    end;

    raise EListError.CreateFmt(DUPLICATE_ID, [S]);
  end;
var
  item: PMapItem;
  p: Pointer;
  Node, NewNode: TAvgLvlTreeNode;
begin
  if FindNode(AId) <> nil
  then begin
    Error;
    Exit;
  end;
  
  Item := GetMem(SizeOF(TMapLink) + cardinal(ID_LENGTH[FIdType]) + FDataSize);
  p := @item^.ID;
  Move(AId, p^, ID_LENGTH[FIdType]);
  inc(p, ID_LENGTH[FIdType]);
  Move(Adata, p^, FDataSize);
  NewNode := FTree.Add(item);

  // Update linked list
  Node := FTree.FindPrecessor(NewNode);
  if Node = nil
  then begin
    // no previous node
    FFirst := Item;
    Node := FTree.FindSuccessor(NewNode);
    Item^.Link.Previous := nil;
    if Node = nil
    then begin
      // We're the only one
      Item^.Link.Next := nil;
      FLast := Item;
    end
    else begin
      Item^.Link.Next := Node.Data;
      PMapItem(Node.Data)^.Link.Previous := Item;
    end;
  end
  else begin
    // there is a prevous node
    Item^.Link.Previous := Node.Data;
    Item^.Link.Next := PMapItem(Node.Data)^.Link.Next;
    PMapItem(Node.Data)^.Link.Next := Item;
    if Item^.Link.Next = nil // no item after us, so we're last
    then FLast := Item
    else Item^.Link.Next^.Link.Previous := Item;
  end;
end;

function TBaseMap.Count: Integer;
begin
  Result := FTree.Count;
end;

constructor TBaseMap.Create(AIdType: TMapIdType; ADataSize: Cardinal);
begin
  inherited Create;
  FIdType := AIdType;
  FDataSize := ADataSize;
  FTree := TAvgLvlTree.CreateObjectCompare(@TreeCompareID);
end;

function TBaseMap.Delete(const AId): Boolean;
var
  Node: TAvgLvlTreeNode;
  n: integer;
begin
  Node := FindNode(AId);
  Result := Node <> nil;
  if not result then Exit;
  
  // Remove from linked list
  if PMapItem(Node.Data)^.Link.Next = nil //we were last
  then FLast := PMapItem(Node.Data)^.Link.Previous
  else PMapItem(Node.Data)^.Link.Next^.Link.Previous := PMapItem(Node.Data)^.Link.Previous;
  if PMapItem(Node.Data)^.Link.Previous = nil //we were fist
  then FFirst := PMapItem(Node.Data)^.Link.Next
  else PMapItem(Node.Data)^.Link.Previous^.Link.Next := PMapItem(Node.Data)^.Link.Next;

  // CheckIterators
  if FIterators <> nil
  then begin
    for n := 0 to FIterators.Count - 1 do
      TBaseMapIterator(FIterators[n]).ItemRemove(Node.Data);
  end;

  FreeMem(Node.Data);
  FTree.Delete(Node);
end;

destructor TBaseMap.Destroy;

  procedure FreeData(ANode: TAvgLvlTreeNode);
  begin
    if ANode = nil then Exit;
    FreeData(ANode.Left);
    FreeData(ANode.Right);
    FreeMem(ANode.Data);
  end;

var
  n: Integer;
begin
  // notify our iterators
  if FIterators <> nil
  then begin
    for n := 0 to FIterators.Count - 1 do
      TBaseMapIterator(FIterators[n]).MapDestroyed;
  end;

  FreeData(FTree.Root);
  FTree.Clear;
  FreeAndNil(FTree);
  inherited Destroy;
end;

function TBaseMap.FindItem(const AId): PMapItem;
var
  Node: TAvgLvlTreeNode;
begin
  Node := FindNode(AId);
  if Node = nil
  then Result := nil
  else Result := Node.Data;
end;

function TBaseMap.FindNode(const AId): TAvgLvlTreeNode;
var
  Item: TMapItem;
begin
  Move(AID, Item.ID, ID_LENGTH[FIdType]);
  Result := FTree.Find(@Item);
end;

function TBaseMap.InternalGetData(AItem: PMapItem; out AData): Boolean;
var
  p: Pointer;
begin
  Result := AItem <> nil;
  if not result then Exit;

  p := @AItem^.ID;
  Inc(p, ID_LENGTH[FIdType]);
  Move(p^, AData, FDataSize);
end;

function TBaseMap.InternalGetDataPtr(AItem: PMapItem): Pointer;
begin
  if AItem = nil
  then begin
    Result := nil;
    Exit;
  end;
  
  Result := @AItem^.ID;
  Inc(Result, ID_LENGTH[FIdType]);
end;

function TBaseMap.InternalGetId(AItem: PMapItem; out AID): Boolean;
begin
  Result := AItem <> nil;
  if not Result then Exit;

  Move(AItem^.ID, AID, ID_LENGTH[FIdType]);
end;

function TBaseMap.InternalSetData(AItem: PMapItem; const AData): Boolean;
var
  p: Pointer;
begin
  Result := AItem <> nil;
  if not Result then Exit;

  p := @AItem^.ID;
  Inc(p, ID_LENGTH[FIdType]);
  Move(AData, p^, FDataSize);
end;

procedure TBaseMap.IteratorAdd(AIterator: TBaseMapIterator);
begin
  if FIterators = nil then FIterators := TList.Create;
  FIterators.Add(AIterator);
end;

procedure TBaseMap.IteratorRemove(AIterator: TBaseMapIterator);
begin
  if FIterators = nil then Exit;
  FIterators.Remove(AIterator);
  if FIterators.Count = 0 then FreeAndNil(FIterators);
end;

function TBaseMap.TreeCompareID(Sender: TAvgLvlTree; AItem1, AItem2: Pointer): Integer;
var
  Item1: PMapItem absolute AItem1;
  Item2: PMapItem absolute AItem2;
begin
  case FIdType of
    itu1: Result := Item1^.ID.U1 - Item2^.ID.U1;
    its1: Result := Item1^.ID.S1 - Item2^.ID.S1;
    itu2: Result := Item1^.ID.U2 - Item2^.ID.U2;
    its2: Result := Item1^.ID.S2 - Item2^.ID.S2;
    itu4: Result := Item1^.ID.U4 - Item2^.ID.U4;
    its4: Result := Item1^.ID.S4 - Item2^.ID.S4;
    itu8: Result := Item1^.ID.U8 - Item2^.ID.U8;
    its8: Result := Item1^.ID.S8 - Item2^.ID.S8;
    itu16: begin
      Result := Item1^.ID.U16H - Item2^.ID.U16H;
      if Result = 0
      then Result := Item1^.ID.U16L - Item2^.ID.U16L;
    end;
    its16: begin
      Result := Item1^.ID.S16H - Item2^.ID.S16H;
      if Result = 0
      then Result := Item1^.ID.S16L - Item2^.ID.S16L;
    end;
    itu32: begin
      Result := Item1^.ID.U32HH - Item2^.ID.U32HH;
      if Result = 0
      then Result := Item1^.ID.U32HL - Item2^.ID.U32HL;
      if Result = 0
      then Result := Item1^.ID.U32LH - Item2^.ID.U32LH;
      if Result = 0
      then Result := Item1^.ID.U32LL - Item2^.ID.U32LL;
    end;
    its32: begin
      Result := Item1^.ID.S32HH - Item2^.ID.S32HH;
      if Result = 0
      then Result := Item1^.ID.S32HL - Item2^.ID.S32HL;
      if Result = 0
      then Result := Item1^.ID.S32LH - Item2^.ID.S32LH;
      if Result = 0
      then Result := Item1^.ID.S32LL - Item2^.ID.S32LL;
    end;
  end;
end;

{ TBaseMapIterator }


constructor TBaseMapIterator.Create(AMap: TBaseMap);
begin
  inherited Create;
  FMap := AMap;
  FMap.IteratorAdd(Self);
  FCurrent := FMap.FFirst;
  FBOM := FCurrent = nil;
  FEOM := FCurrent = nil;
end;

destructor TBaseMapIterator.Destroy;
begin
  if FMap <> nil then FMap.IteratorRemove(Self);
  FMap := nil;
  inherited Destroy;
end;

procedure TBaseMapIterator.First;
begin
  if FMap = nil then Exit;
  FCurrent := FMap.FFirst;
  FBOM := FCurrent = nil;
end;

function TBaseMapIterator.InternalLocate(const AId): Boolean;
var
  C: Integer;
  Node, LastNext: TAvgLvlTreeNode;
  Item: TMapItem;
begin
  ValidateMap;
  
  FInvalid := True;
  Node := FMap.FTree.Root;
  if Node <> nil
  then begin
    Move(AID, Item.ID, ID_LENGTH[FMap.FIdType]);
    LastNext := nil;
    while True do
    begin
      C := FMap.TreeCompareID(nil, @Item, Node.Data);
      if C = 0
      then begin
        FInvalid := False;
        Break;
      end;
      if C < 0
      then begin
        if Node.Left = nil then Break; // no smaller node so we're at next best
        LastNext := Node;
        Node := Node.Left;
      end
      else begin
        Node := Node.Right; // try a bigger one
        if Node = nil
        then begin
          Node := LastNext;
          Break; // not larger
        end;
      end;
    end;
  end;

  if Node = nil
  then begin
    FEOM := True;
  end
  else begin
    FCurrent := Node.Data;
  end;
  Result := not FInvalid;
end;

procedure TBaseMapIterator.ItemRemove(AData: Pointer);
begin
  if AData <> FCurrent then Exit;
  FInvalid := True;
  FCurrent := FCurrent^.Link.Next;
  FEOM := FCurrent = nil;
end;

procedure TBaseMapIterator.Last;
begin
  if FMap = nil then Exit;
  FCurrent := FMap.FLast;
  FEOM := FCurrent = nil;
end;

procedure TBaseMapIterator.MapDestroyed;
begin
  FMap := nil;
  FCurrent := nil;
  FBOM := True;
  FEOM := True;
  FInvalid := False;
end;

procedure TBaseMapIterator.Next;
  procedure Error;
  begin
    raise EInvalidOperation.Create('Cannot move past end');
  end;
begin
  if FInvalid
  then begin
    // We are already at the next
    FInvalid := False;
    Exit;
  end;
  if FEOM then Error;

  if FBOM then
  begin
    // Get first element
    FCurrent := FMap.FFirst;
    FBOM := FCurrent = nil;
  end
  else begin
    FCurrent := FCurrent^.Link.Next;
  end;
  
  FEOM := FCurrent = nil
end;

procedure TBaseMapIterator.Previous;
  procedure Error;
  begin
    raise EInvalidOperation.Create('Cannot move before start');
  end;
begin
  if FBOM then Error;
  FInvalid := False;

  if FEOM then
  begin
    // Get last element
    FCurrent := FMap.FLast;
    FEOM := FCurrent = nil
  end
  else begin
    FCurrent := FCurrent^.Link.Previous;
  end;

  FBOM := FCurrent = nil
end;

function TBaseMapIterator.Valid: Boolean;
begin
  Result := FMap <> nil;
end;

procedure TBaseMapIterator.Validate;
begin
  ValidateMap;

  if FCurrent = nil
  then raise EInvalidOperation.Create('No current item');
  
  if FInvalid
  then raise EInvalidOperation.Create('Current item removed');
end;

procedure TBaseMapIterator.ValidateMap;
begin
  if FMap = nil
  then raise EInvalidOperation.Create('Map destroyed');
end;

{ TMap }

function TMap.GetData(const AId; out AData): Boolean;
begin
  Result := InternalGetData(FindItem(AId), AData);
end;

function TMap.GetDataPtr(const AId): Pointer;
begin
  Result := InternalGetDataPtr(FindItem(AId));
end;

function TMap.HasId(const AID): Boolean;
begin
  Result := FindNode(AId) <> nil;
end;

function TMap.SetData(const AId, AData): Boolean;
begin
  Result := InternalSetData(FindItem(AId), AData);
end;

{ TMapIterator }

function TMapIterator.DataPtr: Pointer;
begin
  Validate;
  Result:=FMap.InternalGetDataPtr(FCurrent);
end;

procedure TMapIterator.GetData(out AData);
begin
  Validate;
  FMap.InternalGetData(FCurrent, AData);
end;

procedure TMapIterator.GetID(out AID);
begin
  Validate;
  FMap.InternalGetId(FCurrent, AId);
end;

function TMapIterator.Locate(const AId): Boolean;
begin
  Result := InternalLocate(AID);
end;

procedure TMapIterator.SetData(const AData);
begin
  Validate;
  FMap.InternalSetData(FCurrent, AData);
end;

end.
