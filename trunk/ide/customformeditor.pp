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
{$H+}
unit CustomFormEditor;

{$mode objfpc}

interface

uses
  classes, abstractformeditor, controls,propedits,Typinfo,ObjectInspector,forms;

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
    Function GetPPropInfobyName(Name : String) : PPropInfo;

  public
    constructor Create;
    destructor Destroy; override;

    Function GetComponentType    : String; override;
    Function GetComponentHandle  : LongInt; override;
    Function GetParent           : TIComponentInterface; override;
    Function IsTControl          : Boolean; override;
    Function GetPropCount	   : Integer; override;
    Function GetPropType(Index : Integer) : TTypeKind; override;
    Function GetPropName(Index : Integer) : String; override;
    Function GetPropTypebyName(Name : String) : TTypeKind; override;

    Function GetPropValue(Index : Integer; var Value) : Boolean; override;
    Function GetPropValuebyName(Name: String; var Value) : Boolean; override;
    Function SetProp(Index : Integer; const Value) : Boolean; override;
    Function SetPropbyName(Name : String; const Value) : Boolean; override;

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
  protected
  public
    constructor Create;
    destructor Destroy; override;

    Function AddSelected(Value : TComponent) : Integer;
    Function Filename : String; override;
    Function FormModified : Boolean; override;
    Function FindComponentByName(const Name : String) : TIComponentInterface; override;
    Function FindComponent(AComponent: TComponent): TIComponentInterface; override;
    Function GetFormComponent : TIComponentInterface; override;
//    Function CreateComponent(CI : TIComponentInterface; TypeName : String;
    Function CreateComponent(ParentCI : TIComponentInterface;
      TypeClass : TComponentClass;  X,Y,W,H : Integer): TIComponentInterface; override;
    Procedure ClearSelected;
    property SelectedComponents : TComponentSelectionList read FSelectedComponents write FSelectedComponents;
    property Obj_Inspector : TObjectInspector read FObj_Inspector write FObj_Inspector;

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
writeln('Index = '+inttostr(PRI^.index));
  case PRI^.PropType^.Kind of
  tkBool: Begin
             Writeln('Boolean....');
             SetOrdProp(FControl,PRI,longint(Value));
             Result := True;
             end;
  tkSString,
  tkLString,
  tkAString,
  tkWString : Begin
              Writeln('String...');
              SetStrProp(FControl,PRI,String(Value));
              Result := True;
             end;
  tkInteger,
  tkInt64   : Begin
              Writeln('Int64...');
              SetInt64Prop(FControl,PRI,Int64(Value));
              Result := True;
             end;
  tkFloat  : Begin
              Writeln('Float...');
              SetFloatProp(FControl,PRI,Extended(Value));
              Result := True;
             end;
  tkVariant  : Begin
              Writeln('Variant...');
              SetVariantProp(FControl,PRI,Variant(Value));
              Result := True;
             end;
  tkMethod  : Begin
              Writeln('Method...');
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
                    Writeln('Get String...');
                    String(Value) := GetStrProp(FControl,PRI);
                    Writeln('The string returned is '+String(value));
                    Writeln('*Get String...');
                   end;
       tkInteger,
       tkInt64   : Begin
                    Writeln('Get Int64...');
                    Int64(Value) := GetInt64Prop(FControl,PRI);
                   end;
       tkFloat  : Begin
                    Writeln('Get Float...');
                    Extended(Value) := GetFloatProp(FControl,PRI);
                   end;
       tkVariant  : Begin
                    Writeln('Get Variant...');
                    Variant(Value) := GetVariantProp(FControl,PRI);
                   end;
       tkMethod  : Begin
                    Writeln('Get Method...');
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

//does freeing this kill my result?  Check this...
//   Freemem(PP);
end;

Function TComponentInterface.GetPPropInfoByName(Name:String): PPropInfo;
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

//does freeing this kill my result?  Check this...
//   Freemem(PP);
end;

Function TComponentInterface.GetComponentType    : String;
Begin
//???What do I return? TObject's Classtype?
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
Num : Integer;
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

Function TComponentInterface.GetPropName(Index : Integer) : String;
var
PT : PTypeData;
PP : PPropList;
PI : PTypeInfo;
Num : Integer;
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

Function TComponentInterface.GetPropTypebyName(Name : String) : TTypeKind;
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

Function TComponentInterface.GetPropValuebyName(Name: String; var Value) : Boolean;
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


Function TComponentInterface.SetPropbyName(Name : String; const Value) : Boolean;
var
  PRI : PPropInfo;
Begin
  Writeln('SetPropByName Name='''+Name+'''');
  Result := False;

  PRI := GetPropInfo(FControl.ClassInfo,Name);
  if PRI <> nil then
  Begin
    Result :=FSetProp(PRI,Value);
  end;

if Result = true then
Writeln('SETPROPBYNAME result = true')
else
Writeln('SETPROPBYNAME result = false');

end;

Function TComponentInterface.GetControlCount: Integer;
Begin
  // XXX Todo:

end;

Function TComponentInterface.GetControl(Index : Integer): TIComponentInterface;
Begin
  // XXX Todo:

end;

Function TComponentInterface.GetComponentCount: Integer;
Begin
  // XXX Todo:

end;

Function TComponentInterface.GetComponent(Index : Integer): TIComponentInterface;
Begin
  // XXX Todo:

end;

Function TComponentInterface.Select : Boolean;
Begin
  // XXX Todo:

end;

Function TComponentInterface.Focus : Boolean;
Begin
  // XXX Todo:

end;

Function TComponentInterface.Delete : Boolean;
Begin
  // XXX Todo:

end;


{TCustomFormEditor}

constructor TCustomFormEditor.Create;
begin
  inherited Create;
  FComponentInterfaceList := TList.Create;
  FSelectedComponents := TComponentSelectionList.Create;
end;

destructor TCustomFormEditor.Destroy;
begin
  inherited;
  FComponentInterfaceList.Free;
  FSelectedComponents.Free;
end;

Function TCustomFormEditor.AddSelected(Value : TComponent) : Integer;
Begin
  FSelectedComponents.Add(Value);
  Result := FSelectedComponents.Count;
  // call the OI to update it's selected.
  writeln('[TCustomFormEditor.AddSelected] '+Value.Name);
  Obj_Inspector.Selections := FSelectedComponents;
end;


Function TCustomFormEditor.Filename : String;
begin
  Result := 'testing.pp';
end;

Function TCustomFormEditor.FormModified : Boolean;
Begin
  Result := FModified;
end;

Function TCustomFormEditor.FindComponentByName(const Name : String) : TIComponentInterface;
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

//Function TCustomFormEditor.CreateComponent(CI : TIComponentInterface; TypeName : String;
Function TCustomFormEditor.CreateComponent(
ParentCI : TIComponentInterface;
TypeClass : TComponentClass;  X,Y,W,H : Integer): TIComponentInterface;
Var
  Temp : TComponentInterface;
  TempInterface : TComponentInterface;
  TempClass    : TPersistentClass;
  TempName    : String;
  Found : Boolean;
  I, Num : Integer;
  CompLeft, CompTop, CompWidth, CompHeight: integer;
  DummyComponent:TComponent;
Begin
  writeln('[TCustomFormEditor.CreateComponent] Class='''+TypeClass.ClassName+'''');
  Temp := TComponentInterface.Create;
  Writeln('TComponentInterface created......');
  if Assigned(ParentCI) then begin
    if Assigned(TComponentInterface(ParentCI).FControl.Owner) then
      Temp.FControl :=
        TypeClass.Create(TComponentInterface(ParentCI).FControl.Owner)
    else
      Temp.FControl :=
        TypeClass.Create(TComponentInterface(ParentCI).FControl)
  end else
    Temp.FControl := TypeClass.Create(nil);
{  if SelectedComponents.Count = 0 then
  else
  Begin
    Writeln('Selected Components > 0');
    if (SelectedComponents.Items[0] is TWinControl)
    and (csAcceptsControls in
         TWinControl(SelectedComponents.Items[0]).ControlStyle) then
    Begin
      Writeln('The Control is a TWinControl and it accepts controls');
      Writeln('The owners name is '+TWinControl(SelectedComponents.Items[0]).Name);
      Temp.FControl := TypeClass.Create(SelectedComponents.Items[0]);
    end
    else
    Begin
      Writeln('The Control is not a TWinControl or it does not accept controls');
      Temp.FControl := TypeClass.Create(SelectedComponents.Items[0].Owner);
    end;
  end;}

  Writeln('4');

  if Assigned(ParentCI) then
    Begin
      if (TComponentInterface(ParentCI).FControl is TWinControl)
      and (csAcceptsControls in
        TWinControl(TComponentInterface(ParentCI).FControl).ControlStyle) then
      begin
        TWinControl(Temp.FControl).Parent :=
          TWinControl(TComponentInterface(ParentCI).FControl);
        writeln('Parent is '''+TWinControl(Temp.FControl).Parent.Name+'''');
      end
      else
      begin
        TWinControl(Temp.FControl).Parent :=
          TWinControl(TComponentInterface(ParentCI).FControl).Parent;
        writeln('Parent is '''+TWinControl(Temp.FControl).Parent.Name+'''');
      end;
{    End
  else
    Begin //ParentCI is not assigned so check the selected control
      Writeln('ParentCI is not assigned....');
      if SelectedComponents.Count > 0 then
        Begin
          Writeln('ParentCI is not assigned but something is selected....');
          TempInterface := TComponentInterface(
            FindComponent(SelectedComponents.Items[0]));
          Writeln('The selected control is '''+TempInterface.FControl.Name+'''');

          if (TempInterface.FControl is TWinControl) and
             (csAcceptsControls in
               TWinControl(TempInterface.FControl).ControlStyle) then
          Begin
            Writeln('The selected control IS a TWincontrol and accepts controls');
            TWinControl(Temp.FControl).Parent :=
              TWinControl(TempInterface.FControl);
          end
          else
            TWinControl(Temp.FControl).Parent :=
              TWinControl(TempInterface.FControl).Parent;
        end}
    end;

Writeln('5');

  TempName := Temp.FControl.ClassName;
  delete(TempName,1,1);
  writeln('TempName is '''+TempName+'''');
  Num := 0;
  Found := True;
  While Found do
  Begin
    Found := False;
    inc(num);
    for I := 0 to FComponentInterfaceList.Count-1 do
    begin
      DummyComponent:=TComponent(TComponentInterface(
        FComponentInterfaceList.Items[i]).FControl);
      if UpCase(DummyComponent.Name)=UpCase(TempName+IntToStr(Num)) then
      begin
        Found := True;
        break;
      end;
    end;
  end;
  Temp.FControl.Name := TempName+IntToStr(Num);
  Writeln('TempName + num = '+TempName+Inttostr(num));

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
  end;

  FComponentInterfaceList.Add(Temp);

  Result := Temp;
end;

Function TCustomFormEditor.GetFormComponent : TIComponentInterface;
Begin
  //this can only be used IF you have one FormEditor per form.  I currently don't
end;

Procedure TCustomFormEditor.ClearSelected;
Begin
  FSelectedComponents.Clear;
end;


end.
