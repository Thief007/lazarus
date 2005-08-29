{ $Id$
 /***************************************************************************
                               checklst.pas
                               ------------

                   Initial Revision  : Thu Jun 19 CST 2003

 ***************************************************************************/

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

unit CheckLst;

{$mode objfpc} {$H+}

interface

uses
  Classes, SysUtils, LCLProc, LCLType, GraphType, Graphics, LMessages,
  LResources, Controls, StdCtrls;
  

type
  { TCustomCheckListBox }

  TCustomCheckListBox = class(TCustomListBox)
  private
    FItemDataOffset: Integer;
    function GetChecked(const AIndex: Integer): Boolean;
    procedure SetChecked(const AIndex: Integer; const AValue: Boolean);
    procedure SendItemChecked(const AIndex: Integer; const AChecked: Boolean);
  protected
    procedure AssignItemDataToCache(const AIndex: Integer; const AData: Pointer); override;
    procedure AssignCacheToItemData(const AIndex: Integer; const AData: Pointer); override;
    function  GetCachedDataSize: Integer; override;
    procedure DefineProperties(Filer: TFiler); override;
    procedure ReadData(Stream: TStream);
    procedure WriteData(Stream: TStream);
  public
    constructor Create(AOwner: TComponent); override;
    property Checked[const AIndex: Integer]: Boolean read GetChecked write SetChecked;
  end;
  
  
  { TCheckListBox }
  
  TCheckListBox = class(TCustomCheckListBox)
  published
    property Align;
    property Anchors;
    property BorderSpacing;
    property BorderStyle;
    property Constraints;
    property ExtendedSelect;
    property Items;
    property ItemHeight;
    property MultiSelect;
    property OnClick;
    property OnDblClick;
    property OnDrawItem;
    property OnEnter;
    property OnExit;
    property OnKeyPress;
    property OnKeyDown;
    property OnKeyUp;
    property OnMouseMove;
    property OnMouseDown;
    property OnMouseUp;
    property OnResize;
    property ParentShowHint;
    property ShowHint;
    property Sorted;
    property Style;
    property TabOrder;
    property TabStop;
    property TopIndex;
    property Visible;
  end;


procedure Register;

implementation

uses
  WSCheckLst;

procedure Register;
begin
  RegisterComponents('Additional',[TCheckListBox]);
end;

type
  PCachedItemData = ^TCachedItemData;
  TCachedItemData = Boolean;

{ TCustomCheckListBox }

procedure TCustomCheckListBox.AssignCacheToItemData(const AIndex: Integer;
  const AData: Pointer);
begin
  inherited AssignCacheToItemData(AIndex, AData);
  if PCachedItemData(AData + FItemDataOffset)^
  then SendItemChecked(AIndex, True);
end;

procedure TCustomCheckListBox.AssignItemDataToCache(const AIndex: Integer;
  const AData: Pointer);
begin
  inherited AssignItemDataToCache(AIndex, AData);
  PCachedItemData(AData + FItemDataOffset)^ := Checked[AIndex];
end;

constructor TCustomCheckListBox.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCompStyle := csCheckListBox;
  FItemDataOffset := inherited GetCachedDataSize;
end;

function TCustomCheckListBox.GetCachedDataSize: Integer;
begin
  FItemDataOffset := inherited GetCachedDataSize;
  Result := FItemDataOffset + SizeOf(TCachedItemData);
end;

function TCustomCheckListBox.GetChecked(const AIndex: Integer): Boolean;
begin
  CheckIndex(AIndex);

  if HandleAllocated then
    Result := TWSCustomCheckListBoxClass(WidgetSetClass).GetChecked(Self, AIndex)
  else
    Result := PCachedItemData(GetCachedData(AIndex) + FItemDataOffset)^;
end;

procedure TCustomCheckListBox.SendItemChecked(const AIndex: Integer;
  const AChecked: Boolean);
begin
  if HandleAllocated then
    TWSCustomCheckListBoxClass(WidgetSetClass).SetChecked(Self,AIndex,AChecked);
end;

procedure TCustomCheckListBox.SetChecked(const AIndex: Integer;
  const AValue: Boolean);
begin
  CheckIndex(AIndex);

  if HandleAllocated
  then SendItemChecked(AIndex, AValue)
  else PCachedItemData(GetCachedData(AIndex) + FItemDataOffset)^ := AValue;
end;

procedure TCustomCheckListBox.DefineProperties(Filer: TFiler);
begin
  inherited DefineProperties(Filer);
  Filer.DefineBinaryProperty('Data', @ReadData, @WriteData,Items.Count>0);
end;

procedure TCustomCheckListBox.ReadData(Stream: TStream);
var
  ChecksCount: integer;
  Checks: string;
  i: Integer;
  v: Integer;
begin
  ChecksCount:=ReadLRSInteger(Stream);
  if ChecksCount>0 then begin
    SetLength(Checks,ChecksCount);
    Stream.ReadBuffer(Checks[1], ChecksCount);
    for i:=0 to ChecksCount-1 do begin
      v:=ord(Checks[i+1]);
      Checked[i]:=((v and 1)>0);
      //debugln('TCustomCheckListBox.ReadData Checked[',dbgs(i),']=',dbgs(Checked[i]),' v=',dbgs(v));
    end;
  end;
end;

procedure TCustomCheckListBox.WriteData(Stream: TStream);
var
  ChecksCount: integer;
  Checks: string;
  i: Integer;
  v: Integer;
begin
  ChecksCount:=Items.Count;
  WriteLRSInteger(Stream,ChecksCount);
  if ChecksCount>0 then begin
    SetLength(Checks,ChecksCount);
    for i:=0 to ChecksCount-1 do begin
      v:=0;
      if Checked[i] then inc(v,1);
      //debugln('TCustomCheckListBox.WriteData Checked[',dbgs(i),']=',dbgs(Checked[i]));
      Checks[i+1]:=chr(v);
    end;
    Stream.WriteBuffer(Checks[1], ChecksCount);
  end;
end;

end.

