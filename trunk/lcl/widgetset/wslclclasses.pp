{ $Id$}
{
 *****************************************************************************
 *                              wslclclasses.pp                              * 
 *                              ---------------                              * 
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
unit WSLCLClasses;

{$mode objfpc}{$H+}

{$DEFINE VerboseWSRegistration}

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
  Classes, LCLProc; //, LCLType; //, InterfaceBase;

type
  { TWSPrivate }

  {
    Internal WidgetSet specific object tree
  }
  TWSPrivate = class(TObject)
  end;
  TWSPrivateClass = class of TWSPrivate;
  
  { TWSLCLComponent }

{$M+}
  TWSLCLComponent = class(TObject) 
  protected
    class function WSPrivate: TWSPrivateClass; //inline;
  end;
{$M-}

  TWSLCLComponentClass = class of TWSLCLComponent;


function FindWSComponentClass(const AComponent: TComponentClass): TWSLCLComponentClass;
procedure RegisterWSComponent(const AComponent: TComponentClass;
                              const AWSComponent: TWSLCLComponentClass;
                              const AWSPrivate: TWSPrivateClass = nil);

implementation

uses
  SysUtils, LCLClasses;

////////////////////////////////////////////////////
// Registration code
////////////////////////////////////////////////////
type
  PClassNode = ^TClassNode;
  TClassNode = record
    LCLClass: TComponentClass;
    WSClass: TWSLCLComponentClass;
    VClass: Pointer;
    VClassName: ShortString;
    Parent: PClassNode;
    Child: PClassNode;
    Sibling: PClassNode;
  end;

const
  // To my knowledge there is no way to tell the size of the
  // VMT of a given class.
  // Assume we have no more than 100 virtual entries
  VIRTUAL_VMT_COUNT = 100;
  VIRTUAL_VMT_SIZE = vmtMethodStart + VIRTUAL_VMT_COUNT * SizeOf(Pointer);

const
  // vmtAutoTable is something Delphi 2 and not used, we 'borrow' the vmt entry
  vmtWSPrivate = vmtAutoTable;

var
  MComponentIndex: TStringList;
  MWSRegisterIndex: TStringList;

function FindWSComponentClass(
  const AComponent: TComponentClass): TWSLCLComponentClass;
var
  idx: Integer;
  cls: TClass;
  Node: PClassNode;
begin
  Result := nil;
  cls := AComponent;
  while cls <> nil do
  begin
    idx := MWSRegisterIndex.IndexOf(cls.ClassName);
    if idx <> -1 
    then begin
      Node := PClassNode(MWSRegisterIndex.Objects[idx]);  
      Result := TWSLCLComponentClass(Node^.VClass);
      Exit;
    end;
    cls := cls.ClassParent;
  end;
end;   

type
  TMethodNameTableEntry = packed record
      Name: PShortstring;
      Addr: Pointer;
    end;

  TMethodNameTable = packed record
    Count: DWord;
    Entries: packed array[0..9999999] of TMethodNameTableEntry;
  end;
  PMethodNameTable =  ^TMethodNameTable;
  
  TPointerArray = packed array[0..9999999] of Pointer;
  PPointerArray = ^TPointerArray;

procedure RegisterWSComponent(const AComponent: TComponentClass;
  const AWSComponent: TWSLCLComponentClass;
  const AWSPrivate: TWSPrivateClass = nil);
  
  function GetNode(const AClass: TClass): PClassNode;
  var
    idx: Integer;
    Name: String;
  begin  
    if (AClass = nil)
    or not (AClass.InheritsFrom(TLCLComponent))
    then begin
      Result := nil;
      Exit;
    end;
    
    Name := AClass.ClassName;
    idx := MComponentIndex.IndexOf(Name);
    if idx = -1 
    then begin
      New(Result);
      Result^.LCLClass := TComponentClass(AClass);
      Result^.WSClass := nil;
      Result^.VClass := nil;
      Result^.VClassName := '';
      Result^.Child := nil;
      Result^.Parent := GetNode(AClass.ClassParent);
      if Result^.Parent = nil
      then begin
        Result^.Sibling := nil;
      end
      else begin
        Result^.Sibling := Result^.Parent^.Child;
        Result^.Parent^.Child := Result;
      end;
      MComponentIndex.AddObject(Name, TObject(Result));
    end
    else begin
      Result := PClassNode(MComponentIndex.Objects[idx]);
    end;
  end;
  
  function FindParentWSClassNode(const ANode: PClassNode): PClassNode;
  begin
    Result := ANode^.Parent;
    while Result <> nil do
    begin
      if Result^.WSClass <> nil then Exit;
      Result := Result^.Parent;
    end;
    Result := nil;
  end;        
  
  function FindCommonAncestor(const AClass1, AClass2: TClass): TClass;
  begin
    Result := AClass1;
    if AClass2.InheritsFrom(Result)
    then Exit;
    
    Result := AClass2;
    while Result <> nil do
    begin
      if AClass1.InheritsFrom(Result)
      then Exit;
      Result := Result.ClassParent;
    end;
    
    Result := nil;
  end;
  
  procedure CreateVClass(const ANode: PClassNode);
  var
    ParentWSNode: PClassNode;
    CommonClass: TClass;
    Vvmt, Cvmt, Pvmt: PPointerArray;
    Cmnt: PMethodNameTable;
    SearchAddr: Pointer;
    n, idx: Integer;    
    WSPrivate: TClass;
    Processed: array[0..VIRTUAL_VMT_COUNT-1] of Boolean; 
    {$IFDEF VerboseWSRegistration}
    Indent: String;
    {$ENDIF}
  begin
    if AWSPrivate = nil
    then WSPrivate := TWSPrivate
    else WSPrivate := AWSPrivate;

    if ANode^.VClass = nil
    then begin
      ANode^.VClass := GetMem(VIRTUAL_VMT_SIZE)
    end
    else begin
      // keep original WSPrivate (only when different than default class)
      if  (PClass(ANode^.VClass + vmtWSPrivate)^ <> nil)
      and (PClass(ANode^.VClass + vmtWSPrivate)^ <> TWSPrivate)
      then WSPrivate := PClass(ANode^.VClass + vmtWSPrivate)^;
    end;

    // Initially copy the WSClass
    // Tricky part, the source may get beyond read mem limit
    Move(Pointer(ANode^.WSClass)^, ANode^.VClass^, VIRTUAL_VMT_SIZE);
    
    // Set WSPrivate class
    ParentWSNode := FindParentWSClassNode(ANode);
    if ParentWSNode = nil
    then begin
      // nothing to do
      PClass(ANode^.VClass + vmtWSPrivate)^ := WSPrivate;
      {$IFDEF VerboseWSRegistration}
      DebugLn('Virtual parent: nil, WSPrivate: ', PClass(ANode^.VClass + vmtWSPrivate)^.ClassName);
      {$ENDIF}
      Exit;
    end;
    
    if WSPrivate = TWSPrivate
    then begin
      if ParentWSNode^.VClass = nil
      then begin
        DebugLN('[WARNING] Missing VClass for: ', ParentWSNode^.WSClass.ClassName);
        PClass(ANode^.VClass + vmtWSPrivate)^ := TWSPrivate;
      end
      else PClass(ANode^.VClass + vmtWSPrivate)^ := PClass(ParentWSNode^.VClass + vmtWSPrivate)^;
    end
    else PClass(ANode^.VClass + vmtWSPrivate)^ := WSPrivate;

    {$IFDEF VerboseWSRegistration}
    DebugLn('Virtual parent: ', ParentWSNode^.WSClass.ClassName, ', WSPrivate: ', PClass(ANode^.VClass + vmtWSPrivate)^.ClassName);
    {$ENDIF}


    // Try to find the common ancestor
    CommonClass := FindCommonAncestor(ANode^.WSClass, ParentWSNode^.WSClass);
    {$IFDEF VerboseWSRegistration}
    DebugLn('Common: ', CommonClass.ClassName);
    Indent := '';
    {$ENDIF}
    
    Vvmt := ANode^.VClass + vmtMethodStart;
    Pvmt := ParentWSNode^.VClass + vmtMethodStart;
    FillChar(Processed[0], SizeOf(Processed), 0);
    
    while CommonClass <> nil do
    begin
      Cmnt := PPointer(Pointer(CommonClass) + vmtMethodTable)^;
      if Cmnt <> nil
      then begin
        {$IFDEF VerboseWSRegistration}
        DebugLn(Indent, '*', CommonClass.Classname, ' method count: ', IntToStr(Cmnt^.Count));
        Indent := Indent + ' ';
        {$ENDIF}

        Cvmt := Pointer(CommonClass) + vmtMethodStart;
        Assert(Cmnt^.Count < VIRTUAL_VMT_COUNT, 'MethodTable count is larger that assumed VIRTUAL_VMT_COUNT');
            
        // Loop though the VMT to see what is overridden    
        for n := 0 to Cmnt^.Count - 1 do
        begin                
          {$IFDEF VerboseWSRegistration}
          DebugLn(Indent, 'Search: ', Cmnt^.Entries[n].Name^);
          {$ENDIF}
          
          SearchAddr := Cmnt^.Entries[n].Addr;
          for idx := 0 to VIRTUAL_VMT_COUNT - 1 do
          begin
            if Cvmt^[idx] = SearchAddr
            then begin
              {$IFDEF VerboseWSRegistration}
              DebugLn(Indent, 'Found at index: ', IntToStr(idx));
              {$ENDIF}          
              
              if Processed[idx] 
              then begin
                {$IFDEF VerboseWSRegistration}
                DebugLn(Indent, 'Procesed -> skipping');
                {$ENDIF}
                Break;
              end;
              Processed[idx] := True;
              
              if  (Vvmt^[idx] = SearchAddr)  //original
              and (Pvmt^[idx] <> SearchAddr) //overridden by parent
              then begin
                {$IFDEF VerboseWSRegistration}
                DebugLn(Indent, Format('Updating %p -> %p', [Vvmt^[idx], Pvmt^[idx]]));
                {$ENDIF}
                Vvmt^[idx] := Pvmt^[idx];
              end;
              
              Break;
            end;
            if idx = VIRTUAL_VMT_COUNT - 1
            then begin
              DebugLn('[WARNING] VMT entry "', Cmnt^.Entries[n].Name^, '" not found in "', CommonClass.ClassName, '"');
              Break;
            end;
          end;
        end;
      end;
      CommonClass := Commonclass.ClassParent;
    end;
    
    // Adjust classname
    ANode^.VClassName := '(V)' + ANode^.WSClass.ClassName;
    PPointer(ANode^.VClass + vmtClassName)^ := @ANode^.VClassName;
    // Adjust classparent
    PPointer(ANode^.VClass + vmtParent)^ := PPointer(Pointer(ParentWSNode^.WSClass) + vmtParent)^;
    // Delete methodtable entry         
    PPointer(ANode^.VClass + vmtMethodTable)^ := nil;
  end;
  
  procedure UpdateChildren(const ANode: PClassNode);
  var
    Node: PClassNode;
  begin           
    Node := ANode^.Child;
    while Node <> nil do
    begin
      if Node^.WSClass <> nil
      then begin 
        {$IFDEF VerboseWSRegistration}
        DebugLn('Update VClass for: ', Node^.WSClass.ClassName);
        {$ENDIF}
        CreateVClass(Node);
      end;
      UpdateChildren(Node);
      Node := Node^.Sibling;
    end;
  end;
  
var
  Node: PClassNode;
begin          
  Node := GetNode(AComponent);
  if Node = nil then Exit;
  
  if Node^.WSClass = nil
  then MWSRegisterIndex.AddObject(AComponent.ClassName, TObject(Node));
  
  Node^.WSClass := AWSComponent;
  {$IFDEF VerboseWSRegistration}
  DebugLn('Create VClass for: ', Node^.WSClass.ClassName);
  {$ENDIF}
  CreateVClass(Node); 
  
  // Since child classes may depend on us, recreate them
  UpdateChildren(Node);
end;

procedure DoInitialization;
begin
  MComponentIndex := TStringList.Create;
  MComponentIndex.Sorted := True;
  MComponentIndex.Duplicates := dupError;

  MWSRegisterIndex := TStringList.Create;
  MWSRegisterIndex.Sorted := True;
  MWSRegisterIndex.Duplicates := dupError;
end;

procedure DoFinalization;
var                
  n: Integer;
  Node: PClassNode;
begin
  for n := 0 to MComponentIndex.Count - 1 do
  begin
    Node := PClassNode(MComponentIndex.Objects[n]);
    if Node^.VClass <> nil
    then Freemem(Node^.VClass);
    Dispose(Node);
  end;
  FreeAndNil(MComponentIndex);
  FreeAndNil(MWSRegisterIndex);
end;

{ TWSLCLComponent }

function TWSLCLComponent.WSPrivate: TWSPrivateClass; //inline;
begin
  Result := TWSPrivateClass(PClass(Pointer(Self) + vmtWSPrivate)^);
end;

initialization
  DoInitialization;

finalization
  DoFinalization;

end.
