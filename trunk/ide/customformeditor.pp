{
 /***************************************************************************
                               CustomFormEditor.pp
                             -------------------




 ***************************************************************************/

/***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/
}
unit CustomFormEditor;

{$mode objfpc}{$H+}

{$I ide.inc}

interface

uses
{$IFDEF IDE_MEM_CHECK}
  MemCheck,
{$ENDIF}
  Classes, AbstractFormeditor, Controls, PropEdits, TypInfo, ObjectInspector ,
  Forms, IDEComp, JITForms,Compreg;

Const OrdinalTypes = [tkInteger,tkChar,tkENumeration,tkbool];

type
{
TComponentInterface is derived from TIComponentInterface.  It gives access to
each control that's dropped onto the form
}

  TCustomFormEditor = class; //forward declaration


  TComponentInterface = class(TIComponentInterface)
  private
    FControl : TComponent;
    FFormEditor : TCustomFormEditor;  //used to call it's functions
    Function FSetProp(PRI : PPropInfo; const Value) : Boolean;
    Function FGetProp(PRI : PPropInfo; var Value) : Boolean;

  protected
    Function GetPPropInfobyIndex(Index : Integer) : PPropInfo;
    Function GetPPropInfobyName(Name : ShortString) : PPropInfo;

  public
    constructor Create;
    destructor Destroy; override;

    Function GetComponentType    : ShortString; override;
    Function GetComponentHandle  : LongInt; override;
    Function GetParent           : TIComponentInterface; override;
    Function IsTControl          : Boolean; override;
    Function GetPropCount	   : Integer; override;
    Function GetPropType(Index : Integer) : TTypeKind; override;
    Function GetPropTypeInfo(Index : Integer) : PTypeInfo;
    Function GetPropName(Index : Integer) : ShortString; override;
    Function GetPropTypeName(Index : Integer) : ShortString; override;
    Function GetPropTypebyName(Name : ShortString) : TTypeKind; override;

    Function GetPropValue(Index : Integer; var Value) : Boolean; override;
    Function GetPropValuebyName(Name: ShortString; var Value) : Boolean; override;
    Function SetProp(Index : Integer; const Value) : Boolean; override;
    Function SetPropbyName(Name : ShortString; const Value) : Boolean; override;


    Function GetControlCount: Integer; override;
    Function GetControl(Index : Integer): TIComponentInterface; override;

    Function GetComponentCount: Integer; override;
    Function GetComponent(Index : Integer): TIComponentInterface; override;

    Function Select : Boolean; override;
    Function Focus : Boolean; override;
    Function Delete : Boolean; override;
    property Control : TComponent read FCOntrol;
  end;

{
TCustomFormEditor

}

  TControlClass = class of TControl;

  TCustomFormEditor = class(TAbstractFormEditor)
  private
    FModified     : Boolean;
    FComponentInterfaceList : TList; //used to track and find controls
    FSelectedComponents : TComponentSelectionList;
    FObj_Inspector : TObjectInspector;
    JITFormList : TJITForms;
  protected
    Procedure RemoveFromComponentInterfaceList(Value :TIComponentInterface);
    procedure SetSelectedComponents(TheSelectedComponents : TComponentSelectionList);
    procedure OnObjectInspectorModified(Sender: TObject);
    procedure SetObj_Inspector(AnObjectInspector: TObjectInspector);
  public
    constructor Create;
    destructor Destroy; override;

    Function AddSelected(Value : TComponent) : Integer;
    Procedure DeleteControl(Value : TComponent);
    Function FormModified : Boolean; override;
    Function FindComponentByName(const Name : ShortString) : TIComponentInterface; override;
    Function FindComponent(AComponent: TComponent): TIComponentInterface; override;
    Function GetFormComponent : TIComponentInterface; override;
//    Function CreateComponent(CI : TIComponentInterface; TypeName : String;
    Function CreateControlComponentInterface(Control: TCOmponent) : TIComponentInterface;

    Function CreateComponent(ParentCI : TIComponentInterface;
      TypeClass : TComponentClass;  X,Y,W,H : Integer): TIComponentInterface; override;
    Function CreateFormFromStream(BinStream: TStream): TIComponentInterface; override;
    Procedure SetFormNameAndClass(CI: TIComponentInterface; 
      const NewFormName, NewClassName: shortstring);
    Procedure ClearSelected;
    property SelectedComponents : TComponentSelectionList 
      read FSelectedComponents write SetSelectedComponents;
    property Obj_Inspector : TObjectInspector read FObj_Inspector write SetObj_Inspector;
  end;


implementation

uses
  SysUtils;

{TComponentInterface}

constructor TComponentInterface.Create;
begin
  inherited Create;
end;

destructor TComponentInterface.Destroy;
begin
  inherited Destroy;
end;

Function TComponentInterface.FSetProp(PRI : PPropInfo;
const Value) : Boolean;
Begin
//writeln('Index = '+inttostr(PRI^.index));
  case PRI^.PropType^.Kind of
  tkBool: Begin
             //Writeln('Boolean....');
             SetOrdProp(FControl,PRI,longint(Value));
             Result := True;
             end;
  tkSString,
  tkLString,
  tkAString,
  tkWString : Begin
              //Writeln('String...');
              SetStrProp(FControl,PRI,ShortString(Value));
              Result := True;
             end;
  tkInteger,
  tkInt64   : Begin
              //Writeln('Int64...');
              SetInt64Prop(FControl,PRI,Int64(Value));
              Result := True;
             end;
  tkFloat  : Begin
              //Writeln('Float...');
              SetFloatProp(FControl,PRI,Extended(Value));
              Result := True;
             end;
  tkVariant  : Begin
              //Writeln('Variant...');
              SetVariantProp(FControl,PRI,Variant(Value));
              Result := True;
             end;
  tkMethod  : Begin
              //Writeln('Method...');
              SetMethodProp(FControl,PRI,TMethod(value));
              Result := True;
             end;
  else
    Result := False;
  end;//case
end;

Function TComponentInterface.FGetProp(PRI : PPropInfo; var Value) : Boolean;
Begin
Result := True;
       case PRI^.PropType^.Kind of
       tkBool    : Longint(Value) := GetOrdProp(FControl,PRI);
       tkSString,
       tkLString,
       tkAString,
       tkWString : Begin
                    //Writeln('Get String...');
                    ShortString(Value) := GetStrProp(FControl,PRI);
                    Writeln('The string returned is '+String(value));
                    Writeln('*Get String...');
                   end;
       tkInteger,
       tkInt64   : Begin
                    //Writeln('Get Int64...');
                    Int64(Value) := GetInt64Prop(FControl,PRI);
                   end;
       tkFloat  : Begin
                    //Writeln('Get Float...');
                    Extended(Value) := GetFloatProp(FControl,PRI);
                   end;
       tkVariant  : Begin
                    //Writeln('Get Variant...');
                    Variant(Value) := GetVariantProp(FControl,PRI);
                   end;
       tkMethod  : Begin
                    //Writeln('Get Method...');
                    TMethod(Value) := GetMethodProp(FControl,PRI);
                   end;
         else
          Result := False;
       end;//case
end;


Function TComponentInterface.GetPPropInfoByIndex(Index:Integer): PPropInfo;
var
  PT : PTypeData;
  PP : PPropList;
  PI : PTypeInfo;
Begin
  PI := FControl.ClassInfo;
  PT:=GetTypeData(PI);
  GetMem (PP,PT^.PropCount*SizeOf(Pointer));
  GetPropInfos(PI,PP);
  if Index < PT^.PropCount then
    Result:=PP^[index]
    else
    Result := nil;

   Freemem(PP);
end;

Function TComponentInterface.GetPPropInfoByName(Name:ShortString): PPropInfo;
var
  PT : PTypeData;
  PP : PPropList;
  PI : PTypeInfo;
  I  : Longint;
Begin
  Name := Uppercase(name);
  PI := FControl.ClassInfo;
  PT:=GetTypeData(PI);
  GetMem (PP,PT^.PropCount*SizeOf(Pointer));
  GetPropInfos(PI,PP);
  I := -1;
  repeat
    inc(i);
  until (PP^[i]^.Name = Name) or (i = PT^.PropCount-1);

  if PP^[i]^.Name = Name then
    Result:=PP^[i]
  else
    Result := nil;

   Freemem(PP);
end;

Function TComponentInterface.GetComponentType    : ShortString;
Begin
  Result:=FControl.ClassName;
end;

Function TComponentInterface.GetComponentHandle  : LongInt;
Begin
//return the TWinControl handle?
  if (FControl is TWinControl) then
  Result := TWinControl(FControl).Handle;
end;

Function TComponentInterface.GetParent : TIComponentInterface;
Begin
  result := nil;
  if (FCOntrol is TControl) then
  if TControl(FControl).Parent <> nil then
  begin
     Result := FFormEditor.FindComponent(TControl(FControl).Parent);
  end;
end;

Function TComponentInterface.IsTControl : Boolean;
Begin
  Result := (FControl is TControl);
end;

Function TComponentInterface.GetPropCount : Integer;
var
  PT : PTypeData;
Begin
  PT:=GetTypeData(FControl.ClassInfo);
  Result := PT^.PropCount;
end;

Function TComponentInterface.GetPropType(Index : Integer) : TTypeKind;
var
PT : PTypeData;
PP : PPropList;
PI : PTypeInfo;
Begin
  PI:=FControl.ClassInfo;
  PT:=GetTypeData(PI);
  GetMem (PP,PT^.PropCount*SizeOf(Pointer));
  GetPropInfos(PI,PP);
  if Index < PT^.PropCount then
      Result := PP^[Index]^.PropType^.Kind
      else
      Result := tkUnknown;

  freemem(PP);
end;

Function TComponentInterface.GetPropTypeInfo(Index : Integer) : PTypeInfo;
var
PT : PTypeData;
PP : PPropList;
PI : PTypeInfo;
Begin
  PI:=FControl.ClassInfo;
  PT:=GetTypeData(PI);
  GetMem (PP,PT^.PropCount*SizeOf(Pointer));
  GetPropInfos(PI,PP);
  if Index < PT^.PropCount then
      Result := PP^[Index]^.PropType
      else
      Result := nil;
  freemem(PP);
end;


{This returns "Integer" or "Boolean"}
Function TComponentInterface.GetPropTypeName(Index : Integer) : ShortString;
var
  PT : PTypeData;
  PP : PPropList;
  PI : PTypeInfo;
Begin
  PI:=FControl.ClassInfo;
  PT:=GetTypeData(PI);
  GetMem (PP,PT^.PropCount*SizeOf(Pointer));
  GetPropInfos(PI,PP);
  if Index < PT^.PropCount then
      Result := PP^[Index]^.PropType^.Name
      else
      Result := '';
  freemem(PP);
end;


{This returns "Left" "Align" "Visible"}
Function TComponentInterface.GetPropName(Index : Integer) : ShortString;
var
PT : PTypeData;
PP : PPropList;
PI : PTypeInfo;
Begin
  PI:=FControl.ClassInfo;
  PT:=GetTypeData(PI);
  GetMem (PP,PT^.PropCount*SizeOf(Pointer));
  GetPropInfos(PI,PP);
  if Index < PT^.PropCount then
//      Result := PP^[Index]^.PropType^.Name
      Result := PP^[Index]^.Name
      else
      Result := '';
  freemem(PP);
end;

Function TComponentInterface.GetPropTypebyName(Name : ShortString) : TTypeKind;
var
  PT  : PTypeData;
  PP  : PPropList;
  PI  : PTypeInfo;
  I   : Longint;
Begin
  PI:=FControl.ClassInfo;
  PT:=GetTypeData(PI);
  GetMem (PP,PT^.PropCount*SizeOf(Pointer));
  GetPropInfos(PI,PP);

  Result := tkUnknown;
  For I:=0 to PT^.PropCount-1 do
  If PP^[i]<>Nil then
  begin
    if PP^[i]^.Name = Name then
    begin
      Result := PP^[i]^.PropType^.Kind;
      Break;
    end;
  end;

  freemem(PP);
end;

Function TComponentInterface.GetPropValue(Index : Integer; var Value) : Boolean;
var
PP : PPropInfo;
Begin
PP := GetPPropInfoByIndex(Index);
Result := FGetProp(PP,Value);
end;

Function TComponentInterface.GetPropValuebyName(Name: ShortString; var Value) : Boolean;
var
PRI : PPropInfo;
Begin
Result := False;
PRI := GetPPropInfoByName(Name);

if PRI <> nil then
Result := FGetProp(PRI,Value);
end;

Function TComponentInterface.SetProp(Index : Integer; const Value) : Boolean;
var
PRI : PPropInfo;
Begin
  Result := False;
  PRI := GetPPropInfoByIndex(Index);
  if PRI <> nil then
      Begin
        Result := FSetProp(PRI,Value);
      end;
end;


Function TComponentInterface.SetPropbyName(Name : ShortString; const Value) : Boolean;
var
  PRI : PPropInfo;
Begin
  //Writeln('SetPropByName Name='''+Name+'''');
  Result := False;

  PRI := GetPropInfo(FControl.ClassInfo,Name);
  if PRI <> nil then
  Begin
    Result :=FSetProp(PRI,Value);
  end;
end;

Function TComponentInterface.GetControlCount: Integer;
Begin
  // XXX Todo:
  Result := -1;
end;

Function TComponentInterface.GetControl(Index : Integer): TIComponentInterface;
Begin
  // XXX Todo:
  Result := nil;
end;

Function TComponentInterface.GetComponentCount: Integer;
Begin
  // XXX Todo:
   Result := -1;
end;

Function TComponentInterface.GetComponent(Index : Integer): TIComponentInterface;
Begin
  // XXX Todo:
  Result := nil;
end;

Function TComponentInterface.Select : Boolean;
Begin
  // XXX Todo:
  Result := False;
end;

Function TComponentInterface.Focus : Boolean;
Begin
  Result := False;
  if (FCOntrol is TWinControl) and (TWinControl(FControl).CanFocus) then
  Begin
    TWinControl(FControl).SetFocus;
    Result := True;
  end;
end;

Function TComponentInterface.Delete : Boolean;
Begin
   Control.Destroy;
   Destroy;
   Result := True;
end;


{TCustomFormEditor}

constructor TCustomFormEditor.Create;
begin
  inherited Create;
  FComponentInterfaceList := TList.Create;
  FSelectedComponents := TComponentSelectionList.Create;
  JITFormList := TJITForms.Create;
  JITFormList.RegCompList := RegCompList;
end;

destructor TCustomFormEditor.Destroy;
begin
  JITFormList.Destroy;
  FComponentInterfaceList.Free;
  FSelectedComponents.Free;
  inherited;
end;

procedure TCustomFormEditor.SetSelectedComponents(
  TheSelectedComponents : TComponentSelectionList);
begin
  if FSelectedComponents.Count>0 then begin
    if FSelectedComponents[0].Owner<>nil then begin
      Obj_Inspector.PropertyEditorHook.LookupRoot:=
        FSelectedComponents[0].Owner;
    end else begin
      Obj_Inspector.PropertyEditorHook.LookupRoot:=FSelectedComponents[0];
    end;
  end;
  FSelectedComponents.Assign(TheSelectedComponents);
  Obj_Inspector.Selections := FSelectedComponents;
end;

Function TCustomFormEditor.AddSelected(Value : TComponent) : Integer;
Begin
  FSelectedComponents.Add(Value);
  Result := FSelectedComponents.Count;
  Obj_Inspector.Selections := FSelectedComponents;
end;

Procedure TCustomFormEditor.DeleteControl(Value : TComponent);
var
  Temp : TComponentInterface;
Begin
  Temp := TComponentInterface(FindComponent(Value));
  if Temp <> nil then
     begin
       RemoveFromComponentInterfaceList(Temp);
       if (Value is TCustomForm) then begin
         JITFormList.DestroyJITFOrm(TForm(Value));
         Temp.Destroy;
       end
       else
         Temp.Delete;
     end;
end;


Function TCustomFormEditor.FormModified : Boolean;
Begin
  Result := FModified;
end;

Function TCustomFormEditor.FindComponentByName(
  const Name : ShortString) : TIComponentInterface;
Var
  Num : Integer;
Begin
  Num := 0;
  While Num < FComponentInterfaceList.Count do
  Begin
    Result := TIComponentInterface(FComponentInterfaceList.Items[Num]);
    if Upcase(TComponentInterface(Result).FControl.Name) = UpCase(Name) then
      exit;
    inc(num);
  end;
  Result:=nil;
end;

Function TCustomFormEditor.FindComponent(AComponent:TComponent): TIComponentInterface;
Var
  Num : Integer;
Begin
  Num := 0;
  While Num < FComponentInterfaceList.Count do
  Begin
    Result := TIComponentInterface(FComponentInterfaceList.Items[Num]);
    if TComponentInterface(Result).FControl = AComponent then exit;
    inc(num);
  end;
  Result:=nil;
end;

Function TCustomFormEditor.CreateComponent(ParentCI : TIComponentInterface;
  TypeClass : TComponentClass;  X,Y,W,H : Integer): TIComponentInterface;
Var
  Temp : TComponentInterface;
  TempName    : String;
  Found : Boolean;
  I, Num,NewFormIndex : Integer;
  CompLeft, CompTop, CompWidth, CompHeight: integer;
  DummyComponent:TComponent;
Begin
  writeln('[TCustomFormEditor.CreateComponent] Class='''+TypeClass.ClassName+'''');
{$IFDEF IDE_MEM_CHECK}
CheckHeap('TCustomFormEditor.CreateComponent A '+IntToStr(GetMem_Cnt));
{$ENDIF}
  Temp := TComponentInterface.Create;
{$IFDEF IDE_MEM_CHECK}
CheckHeap('TCustomFormEditor.CreateComponent B '+IntToStr(GetMem_Cnt));
{$ENDIF}
  if Assigned(ParentCI) then
  begin
    if (not(TComponentInterface(ParentCI).FControl is TCustomForm)) and
       Assigned(TComponentInterface(ParentCI).FControl.Owner) then
      Temp.FControl := TypeClass.Create(TComponentInterface(ParentCI).FControl.Owner)
    else
      Temp.FControl := TypeClass.Create(TComponentInterface(ParentCI).FControl)
  end else begin
    //this should be a form
{$IFDEF IDE_MEM_CHECK}
CheckHeap('TCustomFormEditor.CreateComponent B2 '+IntToStr(GetMem_Cnt));
{$ENDIF}
    NewFormIndex := JITFormList.AddNewJITForm;
{$IFDEF IDE_MEM_CHECK}
CheckHeap('TCustomFormEditor.CreateComponent B3 '+IntToStr(GetMem_Cnt));
{$ENDIF}
    if NewFormIndex >= 0 then
      Temp.FControl := JITFormList[NewFormIndex]
    else begin
      Temp:=nil;
      exit;
    end;
  end;
{$IFDEF IDE_MEM_CHECK}
CheckHeap('TCustomFormEditor.CreateComponent C '+IntToStr(GetMem_Cnt));
{$ENDIF}

  if Assigned(ParentCI) and (Temp.FControl is TControl) then
    Begin
      if (TComponentInterface(ParentCI).FControl is TWinControl)
      and (csAcceptsControls in
        TWinControl(TComponentInterface(ParentCI).FControl).ControlStyle) then
      begin
        TWinControl(Temp.FControl).Parent :=
          TWinControl(TComponentInterface(ParentCI).FControl);
        writeln('Parent is '''+TWinControl(Temp.FControl).Parent.Name+'''');
      end
      else begin
        TControl(Temp.FControl).Parent :=
          TControl(TComponentInterface(ParentCI).FControl).Parent;
        writeln('Parent is '''+TControl(Temp.FControl).Parent.Name+'''');
      end;
    end;

{$IFDEF IDE_MEM_CHECK}
CheckHeap('TCustomFormEditor.CreateComponent D '+IntToStr(GetMem_Cnt));
{$ENDIF}
  if ParentCI <> nil then Begin
    Writeln('ParentCI <> nil');
    TempName := Temp.FControl.ClassName;
    delete(TempName,1,1);
    writeln('TempName is '''+TempName+'''');
    Num := 0;
    Found := True;
    While Found do Begin
      Found := False;
      inc(num);
      for I := 0 to Temp.FControl.Owner.ComponentCount-1 do
      begin
        DummyComponent:=Temp.FControl.Owner.Components[i];
        if UpCase(DummyComponent.Name)=UpCase(TempName+IntToStr(Num)) then
        begin
          Found := True;
          break;
        end;
      end;
    end;
    Temp.FControl.Name := TempName+IntToStr(Num);
    Writeln('TempName + num = '+TempName+Inttostr(num));
  end;

{$IFDEF IDE_MEM_CHECK}
CheckHeap('TCustomFormEditor.CreateComponent E '+IntToStr(GetMem_Cnt));
{$ENDIF}
  if (Temp.FControl is TControl) then
  Begin
    CompLeft:=X;
    CompTop:=Y;
    CompWidth:=W;
    CompHeight:=H;
    if CompWidth<=0 then CompWidth:=TControl(Temp.FControl).Width;
    if CompHeight<=0 then CompHeight:=TControl(Temp.FControl).Height;
    if CompLeft<0 then
      CompLeft:=(TControl(Temp.FControl).Parent.Width + CompWidth) div 2;
    if CompTop<0 then
      CompTop:=(TControl(Temp.FControl).Parent.Height+ CompHeight) div 2;
    TControl(Temp.FControl).SetBounds(CompLeft,CompTop,CompWidth,CompHeight);
  end else begin
    with LongRec(Temp.FControl.DesignInfo) do begin
      Lo:=X;
      Hi:=Y;
    end;
  end;

{$IFDEF IDE_MEM_CHECK}
CheckHeap('TCustomFormEditor.CreateComponent F '+IntToStr(GetMem_Cnt));
{$ENDIF}
  FComponentInterfaceList.Add(Temp);

  Result := Temp;
end;

Function TCustomFormEditor.CreateFormFromStream(
  BinStream: TStream): TIComponentInterface;
var NewFormIndex: integer;
  Temp : TComponentInterface;
begin
  Temp := TComponentInterface.Create;
  NewFormIndex := JITFormList.AddJITFormFromStream(BinStream);
  if NewFormIndex >= 0 then
    Temp.FControl := JITFormList[NewFormIndex]
  else begin
    Temp:=nil;
    exit;
  end;
  FComponentInterfaceList.Add(Temp);

  Result := Temp;
end;

Procedure TCustomFormEditor.SetFormNameAndClass(CI: TIComponentInterface;
  const NewFormName, NewClassName: shortstring);
var AComponent: TComponent;
begin
  AComponent:=TComponentInterface(CI).FControl;
  if (AComponent<>nil) and (AComponent is TForm) then begin
    JITFormList.RenameFormClass(TForm(AComponent),NewClassName);
    TForm(AComponent).Name:=NewFormName;
  end;
end;

Procedure TCustomFormEditor.RemoveFromComponentInterfaceList(
  Value :TIComponentInterface);
Begin
  if (FComponentInterfaceList.IndexOf(Value) <> -1) then
      FComponentInterfaceList.Delete(FComponentInterfaceList.IndexOf(Value));
end;

Function TCustomFormEditor.GetFormComponent : TIComponentInterface;
Begin
  //this can only be used IF you have one FormEditor per form.  I currently don't
  Result := nil;
end;

Procedure TCustomFormEditor.ClearSelected;
Begin
  FSelectedComponents.Clear;
end;

Function TCustomFormEditor.CreateControlComponentInterface(
  Control: TComponent) :TIComponentInterface;
var
  Temp : TComponentInterface;

Begin
  Temp := TComponentInterface.Create;
  Temp.FControl := Control;
  FComponentInterfaceList.Add(Temp);
  Result := Temp;
end;

procedure TCustomFormEditor.OnObjectInspectorModified(Sender: TObject);
var CustomForm: TCustomForm;
begin
  if (FSelectedComponents<>nil) and (FSelectedComponents.Count>0) then begin
    if FSelectedComponents[0] is TCustomForm then
      CustomForm:=TCustomForm(FSelectedComponents[0])
    else if (FSelectedComponents[0].Owner<>nil)
    and (FSelectedComponents[0].Owner is TCustomForm) then
      CustomForm:=TCustomForm(FSelectedComponents[0].Owner)
    else
      CustomForm:=nil;
    if (CustomForm<>nil) and (CustomForm.Designer<>nil) then
      CustomForm.Designer.Modified;
  end;
end;

procedure TCustomFormEditor.SetObj_Inspector(
  AnObjectInspector: TObjectInspector);
begin
  if AnObjectInspector=FObj_Inspector then exit;
  if FObj_Inspector<>nil then FObj_Inspector.OnModified:=nil;
  FObj_Inspector:=AnObjectInspector;
  FObj_Inspector.OnModified:=@OnObjectInspectorModified;
end;

end.
