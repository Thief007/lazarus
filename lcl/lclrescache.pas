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

  Author: Mattias Gaertner
  
  Abstract:
    Types and methods to cache interface resources.
    See graphics.pp for examples.
}
unit LCLResCache;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FPCAdds, LCLProc, AvgLvlTree;

type
  TResourceCache = class;
  TResourceCacheDescriptor = class;

  { TResourceCacheItem }

  TResourceCacheItem = class
  protected
    FDestroying: boolean;
    FReferenceCount: integer;
  public
    Handle: THandle;
    Cache: TResourceCache;
    FirstDescriptor, LastDescriptor: TResourceCacheDescriptor;
    Next, Prev: TResourceCacheItem;
    constructor Create(TheCache: TResourceCache; TheHandle: THandle);
    destructor Destroy; override;
    procedure IncreaseRefCount;
    procedure DecreaseRefCount;
    procedure AddToList(var First, Last: TResourceCacheItem);
    procedure RemoveFromList(var First, Last: TResourceCacheItem);
    procedure WarnReferenceHigh; virtual;
  public
    property ReferenceCount: integer read FReferenceCount;
  end;
  TResourceCacheItemClass = class of TResourceCacheItem;


  { TResourceCacheDescriptor }

  TResourceCacheDescriptor = class
  protected
    FDestroying: boolean;
  public
    Item: TResourceCacheItem;
    Cache: TResourceCache;
    Next, Prev: TResourceCacheDescriptor;
    constructor Create(TheCache: TResourceCache; TheItem: TResourceCacheItem);
    destructor Destroy; override;
    procedure AddToList(var First, Last: TResourceCacheDescriptor);
    procedure RemoveFromList(var First, Last: TResourceCacheDescriptor);
  end;
  TResourceCacheDescriptorClass = class of TResourceCacheDescriptor;


  { TResourceCache }

  TResourceCache = class
  protected
    FItems: TAvgLvlTree;
    FDescriptors: TAvgLvlTree;
    FDestroying: boolean;
    FResourceCacheDescriptorClass: TResourceCacheDescriptorClass;
    FResourceCacheItemClass: TResourceCacheItemClass;
    FMaxUnusedItem: integer; // how many freed resources to keep
    FFirstUnusedItem, FLastUnusedItem: TResourceCacheItem;
    FUnUsedItemCount: integer;
    procedure RemoveItem(Item: TResourceCacheItem); virtual;
    procedure RemoveDescriptor(Desc: TResourceCacheDescriptor); virtual;
    procedure ItemUsed(Item: TResourceCacheItem);
    procedure ItemUnused(Item: TResourceCacheItem);
    function ItemIsUsed(Item: TResourceCacheItem): boolean;
  public
    constructor Create;
    destructor Destroy; override;
    function CompareItems(Tree: TAvgLvlTree; Item1, Item2: Pointer): integer; virtual;
    function CompareDescriptors(Tree: TAvgLvlTree; Desc1, Desc2: Pointer): integer; virtual; abstract;
    procedure ConsistencyCheck;
  public
    property MaxUnusedItem: integer read FMaxUnusedItem
                                           write FMaxUnusedItem;
    property ResourceCacheItemClass: TResourceCacheItemClass
                                                   read FResourceCacheItemClass;
    property ResourceCacheDescriptorClass: TResourceCacheDescriptorClass
                                             read FResourceCacheDescriptorClass;
  end;


  { THandleResourceCache }

  THandleResourceCache = class(TResourceCache)
  public
    function FindItem(Handle: THandle): TResourceCacheItem;
  end;


  { TBlockResourceCacheDescriptor }

  TBlockResourceCacheDescriptor = class(TResourceCacheDescriptor)
  public
    Data: Pointer;
    destructor Destroy; override;
  end;


  { TBlockResourceCache }

  TBlockResourceCache = class(THandleResourceCache)
  private
    FDataSize: integer;
  protected
    FOnCompareDescPtrWithDescriptor: TListSortCompare;
  public
    constructor Create(TheDataSize: integer);
    function FindDescriptor(DescPtr: Pointer): TBlockResourceCacheDescriptor;
    function AddResource(Handle: THandle; DescPtr: Pointer
                         ): TBlockResourceCacheDescriptor;
    function CompareDescriptors(Tree: TAvgLvlTree;
                                Desc1, Desc2: Pointer): integer; override;
  public
    property DataSize: integer read FDataSize;
    property OnCompareDescPtrWithDescriptor: TListSortCompare
                                           read FOnCompareDescPtrWithDescriptor;
  end;

function ComparePHandleWithResourceCacheItem(HandlePtr: PHandle; Item:
  TResourceCacheItem): integer;
function CompareDescPtrWithBlockResDesc(DescPtr: Pointer;
  Item: TBlockResourceCacheDescriptor): integer;


implementation


function ComparePHandleWithResourceCacheItem(HandlePtr: PHandle; Item:
  TResourceCacheItem): integer;
begin
  Result := CompareHandles(HandlePtr^, Item.Handle);
end;

function CompareDescPtrWithBlockResDesc(DescPtr: Pointer;
  Item: TBlockResourceCacheDescriptor): integer;
begin
  Result := CompareMemRange(DescPtr, Item.Data,
              TBlockResourceCache(Item.Cache).DataSize);
end;


{ TResourceCacheItem }

constructor TResourceCacheItem.Create(TheCache: TResourceCache;
  TheHandle: THandle);
begin
  Cache:=TheCache;
  Handle:=TheHandle;
end;

destructor TResourceCacheItem.Destroy;
begin
  if FDestroying then
    RaiseGDBException('');
  FDestroying:=true;
  Cache.RemoveItem(Self);
  //debugln('TResourceCacheItem.Destroy B ',dbgs(Self));
  Handle:=0;
  inherited Destroy;
  //debugln('TResourceCacheItem.Destroy END ',dbgs(Self));
end;

procedure TResourceCacheItem.IncreaseRefCount;
begin
  inc(FReferenceCount);
  if FReferenceCount=1 then
    Cache.ItemUsed(Self);
  if (FReferenceCount=1000) or (FReferenceCount=10000) then
    WarnReferenceHigh;
end;

procedure TResourceCacheItem.DecreaseRefCount;

  procedure RaiseRefCountZero;
  begin
    RaiseGDBException('TResourceCacheItem.DecreaseRefCount=0 '+ClassName);
  end;

begin
  //debugln('TResourceCacheItem.DecreaseRefCount ',ClassName,' ',dbgs(Self),' ',dbgs(FReferenceCount));
  if FReferenceCount=0 then
    RaiseRefCountZero;
  dec(FReferenceCount);
  if FReferenceCount=0 then
    Cache.ItemUnused(Self);
  //debugln('TResourceCacheItem.DecreaseRefCount END ');
end;

procedure TResourceCacheItem.AddToList(var First, Last: TResourceCacheItem
  );
// add as last
begin
  Next:=nil;
  Prev:=Last;
  Last:=Self;
  if First=nil then First:=Self;
  if Prev<>nil then Prev.Next:=Self;
end;

procedure TResourceCacheItem.RemoveFromList(var First,Last: TResourceCacheItem);
begin
  if First=Self then First:=Next;
  if Last=Self then Last:=Prev;
  if Next<>nil then Next.Prev:=Prev;
  if Prev<>nil then Prev.Next:=Next;
  Next:=nil;
  Prev:=nil;
end;

procedure TResourceCacheItem.WarnReferenceHigh;
begin
  debugln('WARNING: TResourceCacheItem.IncreaseRefCount ',dbgs(FReferenceCount),' ',Cache.ClassName);
end;

{ TResourceCacheDescriptor }

constructor TResourceCacheDescriptor.Create(TheCache: TResourceCache;
  TheItem: TResourceCacheItem);
begin
  Cache:=TheCache;
  Item:=TheItem;
  Item.IncreaseRefCount;
  AddToList(Item.FirstDescriptor,Item.LastDescriptor);
end;

destructor TResourceCacheDescriptor.Destroy;
begin
  if FDestroying then
    RaiseGDBException('');
  FDestroying:=true;
  Cache.RemoveDescriptor(Self);
  inherited Destroy;
end;

procedure TResourceCacheDescriptor.AddToList(
  var First, Last: TResourceCacheDescriptor);
// add as last
begin
  Next:=nil;
  Prev:=Last;
  Last:=Self;
  if First=nil then First:=Self;
  if Prev<>nil then Prev.Next:=Self;
end;

procedure TResourceCacheDescriptor.RemoveFromList(
  var First, Last: TResourceCacheDescriptor);
begin
  if First=Self then First:=Next;
  if Last=Self then Last:=Prev;
  if Next<>nil then Next.Prev:=Prev;
  if Prev<>nil then Prev.Next:=Next;
  Next:=nil;
  Prev:=nil;
end;

{ TResourceCache }

procedure TResourceCache.RemoveItem(Item: TResourceCacheItem);
begin
  if FDestroying then exit;
  while Item.FirstDescriptor<>nil do Item.FirstDescriptor.Free;
  FItems.Remove(Item);
end;

procedure TResourceCache.RemoveDescriptor(Desc: TResourceCacheDescriptor);
begin
  if FDestroying then exit;
  Desc.RemoveFromList(Desc.Item.FirstDescriptor,Desc.Item.LastDescriptor);
  FDescriptors.Remove(Desc);
  if (Desc.Item.FirstDescriptor=nil) and (not Desc.Item.FDestroying) then
    Desc.Item.Free;
end;

procedure TResourceCache.ItemUsed(Item: TResourceCacheItem);
// called after creation or when Item is used again
begin
  if not ItemIsUsed(Item) then begin
    Item.RemoveFromList(FFirstUnusedItem,FLastUnusedItem);
    dec(FUnUsedItemCount);
  end;
end;

procedure TResourceCache.ItemUnused(Item: TResourceCacheItem);
// called when Item is not used any more
begin
  //debugln('TResourceCache.ItemUnused A ',ClassName,' ',dbgs(Self));
  if not ItemIsUsed(Item) then
    raise Exception.Create('TResourceCache.ItemUnused');
  //debugln('TResourceCache.ItemUnused B ',ClassName,' ',dbgs(Self));
  Item.AddToList(FFirstUnusedItem,FLastUnusedItem);
  inc(FUnUsedItemCount);
  //debugln('TResourceCache.ItemUnused C ',ClassName,' ',dbgs(Self));
  if FUnUsedItemCount>FMaxUnusedItem then
    // maximum unused resources reached -> free the oldest
    FFirstUnusedItem.Free;
  //debugln('TResourceCache.ItemUnused END ',ClassName,' ',dbgs(Self));
end;

function TResourceCache.ItemIsUsed(Item: TResourceCacheItem): boolean;
begin
  Result:=(FFirstUnusedItem<>Item) and (Item.Next=nil)
          and (Item.Prev=nil)
end;

constructor TResourceCache.Create;
begin
  FMaxUnusedItem:=2;
  FItems:=TAvgLvlTree.CreateObjectCompare(@CompareItems);
  FDescriptors:=TAvgLvlTree.CreateObjectCompare(@CompareDescriptors);
  FResourceCacheItemClass:=TResourceCacheItem;
  FResourceCacheDescriptorClass:=TResourceCacheDescriptor;
end;

destructor TResourceCache.Destroy;
begin
  FDestroying:=true;
  FItems.FreeAndClear;
  FItems.Free;
  FItems:=nil;
  FDescriptors.FreeAndClear;
  FDescriptors.Free;
  FDescriptors:=nil;
  inherited Destroy;
end;

function TResourceCache.CompareItems(Tree: TAvgLvlTree; Item1, Item2: Pointer
  ): integer;
begin
  Result:=CompareHandles(TResourceCacheItem(Item1).Handle,
                         TResourceCacheItem(Item2).Handle);
end;

procedure TResourceCache.ConsistencyCheck;
var
  ANode: TAvgLvlTreeNode;
  Item: TResourceCacheItem;
begin
  if (FFirstUnusedItem=nil) xor (FLastUnusedItem=nil) then
    RaiseGDBException('');

  // check items
  ANode:=FItems.FindLowest;
  while ANode<>nil do begin
    Item:=TResourceCacheItem(ANode.Data);
    if Item.FirstDescriptor=nil then
      RaiseGDBException('');
    if Item.LastDescriptor=nil then
      RaiseGDBException('');
    ANode:=FItems.FindSuccessor(ANode);
  end;
end;

{ THandleResourceCache }

function THandleResourceCache.FindItem(Handle: THandle): TResourceCacheItem;
var
  ANode: TAvgLvlTreeNode;
begin
  ANode:=FItems.FindKey(@Handle,TListSortCompare(@ComparePHandleWithResourceCacheItem));
  if ANode<>nil then
    Result:=TResourceCacheItem(ANode.Data)
  else
    Result:=nil;
end;

{ TBlockResourceCache }

constructor TBlockResourceCache.Create(TheDataSize: integer);
begin
  inherited Create;
  FDataSize:=TheDataSize;
  FResourceCacheDescriptorClass:=TBlockResourceCacheDescriptor;
  FOnCompareDescPtrWithDescriptor:=TListSortCompare(@CompareDescPtrWithBlockResDesc);
end;

function TBlockResourceCache.FindDescriptor(DescPtr: Pointer
  ): TBlockResourceCacheDescriptor;
var
  ANode: TAvgLvlTreeNode;
begin
  ANode:=FDescriptors.FindKey(DescPtr,FOnCompareDescPtrWithDescriptor);
  if ANode<>nil then
    Result:=TBlockResourceCacheDescriptor(ANode.Data)
  else
    Result:=nil;
end;

function TBlockResourceCache.AddResource(Handle: THandle; DescPtr: Pointer
  ): TBlockResourceCacheDescriptor;
var
  Item: TResourceCacheItem;

  procedure RaiseDescriptorAlreadyAdded;
  var
    Msg: String;
    i: Integer;
  begin
    Msg:='TBlockResourceCache.AddResource Descriptor Already Added '#13;
    for i:=0 to DataSize-1 do
      Msg:=Msg+hexstr(ord(PChar(DescPtr)[i]),2);
    raise Exception.Create(Msg);
  end;

begin
  Result:=FindDescriptor(DescPtr);
  if Result<>nil then
    RaiseDescriptorAlreadyAdded;

  Item:=FindItem(Handle);
  if Item=nil then begin
    Item:=FResourceCacheItemClass.Create(Self,Handle);
    FItems.Add(Item);
  end;
  Result:=TBlockResourceCacheDescriptor(
                               FResourceCacheDescriptorClass.Create(Self,Item));
  ReAllocMem(Result.Data,DataSize);
  System.Move(DescPtr^,Result.Data^,DataSize);
  FDescriptors.Add(Result);
end;

function TBlockResourceCache.CompareDescriptors(Tree: TAvgLvlTree; Desc1,
  Desc2: Pointer): integer;
begin
  Result:=CompareMemRange(TBlockResourceCacheDescriptor(Desc1).Data,
                          TBlockResourceCacheDescriptor(Desc2).Data,
                          DataSize);
end;

{ TBlockResourceCacheDescriptor }

destructor TBlockResourceCacheDescriptor.Destroy;
begin
  inherited Destroy;
  ReAllocMem(Data,0);
end;

end.

