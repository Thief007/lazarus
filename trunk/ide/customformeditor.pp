{
 /***************************************************************************
                               CustomFormEditor.pp
                             -------------------

 ***************************************************************************/

 ***************************************************************************
 *                                                                         *
 *   This source is free software; you can redistribute it and/or modify   *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This code is distributed in the hope that it will be useful, but      *
 *   WITHOUT ANY WARRANTY; without even the implied warranty of            *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU     *
 *   General Public License for more details.                              *
 *                                                                         *
 *   A copy of the GNU General Public License is available on the World    *
 *   Wide Web at <http://www.gnu.org/copyleft/gpl.html>. You can also      *
 *   obtain it by writing to the Free Software Foundation,                 *
 *   Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.        *
 *                                                                         *
 ***************************************************************************
}
unit CustomFormEditor;

{$mode objfpc}{$H+}

{$I ide.inc}

interface

{ $DEFINE VerboseFormEditor}

uses
{$IFDEF IDE_MEM_CHECK}
  MemCheck,
{$ENDIF}
  // LCL+FCL
  {$IFNDEF Ver1_0}Variants,{$ENDIF}
  Classes, SysUtils, TypInfo, Math, LCLProc, Graphics, Controls, Forms, Menus,
  Dialogs,
  // components
  OldAvLTree, PropEdits, ObjectInspector, IDECommands,
  // IDE
  LazarusIDEStrConsts, JITForms, NonControlForms, FormEditingIntf, ComponentReg,
  IDEProcs, ComponentEditors, KeyMapping, EditorOptions, DesignerProcs;

Const OrdinalTypes = [tkInteger,tkChar,tkENumeration,tkbool];

type
{
TComponentInterface is derived from TIComponentInterface.  It gives access to
each control that's dropped onto the form
}

  TCustomFormEditor = class; //forward declaration


  TComponentInterface = class(TIComponentInterface)
  private
    FComponentEditor: TBaseComponentEditor;
    FDesigner: TComponentEditorDesigner;
    FFormEditor : TCustomFormEditor;  //used to call it's functions
    Function FSetProp(PRI : PPropInfo; const Value) : Boolean;
    Function FGetProp(PRI : PPropInfo; var Value) : Boolean;
    function GetDesigner: TComponentEditorDesigner;
  protected
    Function GetPPropInfoByIndex(Index : Integer) : PPropInfo;
    Function GetPPropInfoByName(Name : ShortString) : PPropInfo;
  public
    constructor Create;
    constructor Create(AComponent: TComponent);
    destructor Destroy; override;

    Function GetComponentType: ShortString; override;
    Function GetComponentHandle: LongInt; override;
    Function GetParent: TIComponentInterface; override;
    Function IsTControl: Boolean; override;
    Function GetPropCount: Integer; override;
    Function GetPropType(Index: Integer): TTypeKind; override;
    Function GetPropTypeInfo(Index: Integer): PTypeInfo;
    Function GetPropName(Index: Integer): ShortString; override;
    Function GetPropTypeName(Index: Integer): ShortString; override;
    Function GetPropTypebyName(Name: ShortString): TTypeKind; override;

    Function GetPropValue(Index : Integer; var Value) : Boolean; override;
    Function GetPropValuebyName(Name: ShortString; var Value) : Boolean; override;
    Function SetProp(Index : Integer; const Value) : Boolean; override;
    Function SetPropbyName(Name : ShortString; const Value) : Boolean; override;

    Function GetControlCount: Integer; override;
    Function GetControl(Index : Integer): TIComponentInterface; override;

    Function GetComponentCount: Integer; override;
    Function GetComponent(Index : Integer): TIComponentInterface; override;

    Function Select: Boolean; override;
    Function Focus: Boolean; override;
    Function Delete: Boolean; override;
    
    function GetComponentEditor: TBaseComponentEditor;
    property Designer: TComponentEditorDesigner read GetDesigner write FDesigner;
  end;


  { TCustomFormEditor }

  TControlClass = class of TControl;

  TCustomFormEditor = class(TAbstractFormEditor)
  private
    FComponentInterfaces: TAVLTree; // tree of TComponentInterface sorted for
                                    // component
    FSelection: TPersistentSelectionList;
    FObj_Inspector: TObjectInspector;
    FDefineProperties: TAVLTree;
    function GetPropertyEditorHook: TPropertyEditorHook;
  protected
    FNonControlForms: TAVLTree; // tree of TNonFormDesignerForm sorted for LookupRoot
    procedure SetSelection(const ASelection: TPersistentSelectionList);
    procedure OnObjectInspectorModified(Sender: TObject);
    procedure SetObj_Inspector(AnObjectInspector: TObjectInspector); virtual;
    procedure JITListReaderError(Sender: TObject; ErrorType: TJITFormError;
          var Action: TModalResult); virtual;
    procedure JITListPropertyNotFound(Sender: TObject; Reader: TReader;
      Instance: TPersistent; var PropName: string; IsPath: boolean;
      var Handled, Skip: Boolean);

    procedure OnDesignerMenuItemClick(Sender: TObject); virtual;
    function FindNonControlFormNode(LookupRoot: TComponent): TAVLTreeNode;
  public
    JITFormList: TJITForms;// designed forms
    JITNonFormList: TJITNonFormComponents;// designed data modules

    constructor Create;
    destructor Destroy; override;

    // selection
    Function AddSelected(Value: TComponent) : Integer;
    Procedure DeleteComponent(AComponent: TComponent; FreeComponent: boolean);
    Function FindComponentByName(const Name: ShortString
                                 ): TIComponentInterface; override;
    Function FindComponent(AComponent: TComponent): TIComponentInterface; override;
    function SaveSelectionToStream(s: TStream): Boolean; override;
    function InsertFromStream(s: TStream; Parent: TWinControl;
                              Flags: TComponentPasteSelectionFlags): Boolean; override;
    function ClearSelection: Boolean; override;
    function DeleteSelection: Boolean; override;
    function CopySelectionToClipboard: Boolean; override;
    function CutSelectionToClipboard: Boolean; override;
    function PasteSelectionFromClipboard(Flags: TComponentPasteSelectionFlags
                                         ): Boolean; override;

    // JIT components
    function IsJITComponent(AComponent: TComponent): boolean;
    function GetJITListOfType(AncestorType: TComponentClass): TJITComponentList;
    function FindJITList(AComponent: TComponent): TJITComponentList;
    function FindJITListByClassName(const AComponentClassName: string
                                    ): TJITComponentList;
    function GetDesignerForm(AComponent: TComponent): TCustomForm; override;
    function FindNonControlForm(LookupRoot: TComponent): TNonFormDesignerForm;
    function CreateNonControlForm(LookupRoot: TComponent): TNonFormDesignerForm;
    procedure RenameJITComponent(AComponent: TComponent;
                                 const NewName: shortstring);
    procedure UpdateDesignerFormName(AComponent: TComponent);
    function CreateNewJITMethod(AComponent: TComponent;
                                const AMethodName: shortstring): TMethod;
    procedure RenameJITMethod(AComponent: TComponent;
                           const OldMethodName, NewMethodName: shortstring);
    procedure SaveHiddenDesignerFormProperties(AComponent: TComponent);
    function FindJITComponentByClassName(const AComponentClassName: string
                                         ): TComponent;
    
    // designers
    function DesignerCount: integer; override;
    function GetDesigner(Index: integer): TIDesigner; override;
    function GetCurrentDesigner: TIDesigner; override;
    function GetDesignerByComponent(AComponent: TComponent): TIDesigner; override;

    // component editors
    function GetComponentEditor(AComponent: TComponent): TBaseComponentEditor;
    
    // component creation
    function CreateUniqueComponentName(AComponent: TComponent): string;
    function CreateUniqueComponentName(const AClassName: string;
                                       OwnerComponent: TComponent): string;
    Function CreateComponentInterface(AComponent: TComponent): TIComponentInterface;
    procedure CreateChildComponentInterfaces(AComponent: TComponent);
    Function GetDefaultComponentParent(TypeClass: TComponentClass
                                       ): TIComponentInterface; override;
    Function GetDefaultComponentPosition(TypeClass: TComponentClass;
                                         ParentCI: TIComponentInterface;
                                         var X,Y: integer): boolean; override;
    Function CreateComponent(ParentCI : TIComponentInterface;
                             TypeClass: TComponentClass;
                             X,Y,W,H : Integer): TIComponentInterface; override;
    Function CreateComponentFromStream(BinStream: TStream;
                       AncestorType: TComponentClass;
                       const NewUnitName: ShortString;
                       Interactive: boolean): TIComponentInterface; override;
    Function CreateChildComponentFromStream(BinStream: TStream;
                       ComponentClass: TComponentClass; Root: TComponent;
                       ParentControl: TWinControl): TIComponentInterface; override;
    Procedure SetComponentNameAndClass(CI: TIComponentInterface;
      const NewName, NewClassName: shortstring);
      
    // define properties
    procedure FindDefineProperty(const APersistentClassName,
                                 AncestorClassName, Identifier: string;
                                 var IsDefined: boolean);

    // keys
    function TranslateKeyToDesignerCommand(Key: word; Shift: TShiftState): word;
  public
    property Selection: TPersistentSelectionList read FSelection
                                                 write SetSelection;
    property Obj_Inspector: TObjectInspector
                                     read FObj_Inspector write SetObj_Inspector;
    property PropertyEditorHook: TPropertyEditorHook read GetPropertyEditorHook;
  end;
  
  
  { TDefinePropertiesCacheItem }
  
  TDefinePropertiesCacheItem = class
  public
    PersistentClassname: string;
    RegisteredComponent: TRegisteredComponent;
    DefineProperties: TStrings;
    destructor Destroy; override;
  end;
  
  
  { TDefinePropertiesReader }
  
  TDefinePropertiesReader = class(TFiler)
  private
    FDefinePropertyNames: TStrings;
  protected
    procedure AddPropertyName(const Name: string);
  public
    destructor Destroy; override;
    procedure DefineProperty(const Name: string;
      ReadData: TReaderProc; WriteData: TWriterProc;
      HasData: Boolean); override;
    procedure DefineBinaryProperty(const Name: string;
      ReadData, WriteData: TStreamProc;
      HasData: Boolean); override;
    property DefinePropertyNames: TStrings read FDefinePropertyNames;
  end;
  
  
  { TDefinePropertiesPersistent }
  
  TDefinePropertiesPersistent = class(TPersistent)
  private
    FTarget: TPersistent;
  public
    constructor Create(TargetPersistent: TPersistent);
    procedure PublicDefineProperties(Filer: TFiler);
    property Target: TPersistent read FTarget;
  end;
  
  
  
function CompareComponentInterfaces(Data1, Data2: Pointer): integer;
function CompareComponentAndInterface(Key, Data: Pointer): integer;
function CompareDefPropCacheItems(Item1, Item2: TDefinePropertiesCacheItem): integer;
function ComparePersClassNameAndDefPropCacheItem(Key: Pointer;
                                     Item: TDefinePropertiesCacheItem): integer;
procedure RegisterStandardClasses;


implementation


function CompareComponentInterfaces(Data1, Data2: Pointer): integer;
var
  CompIntf1: TComponentInterface;
  CompIntf2: TComponentInterface;
begin
  CompIntf1:=TComponentInterface(Data1);
  CompIntf2:=TComponentInterface(Data2);
  Result:=integer(CompIntf1.Component)-integer(CompIntf2.Component);
end;

function CompareComponentAndInterface(Key, Data: Pointer): integer;
var
  AComponent: TComponent;
  CompIntf: TComponentInterface;
begin
  AComponent:=TComponent(Key);
  CompIntf:=TComponentInterface(Data);
  Result:=integer(AComponent)-integer(CompIntf.Component);
end;

function CompareDefPropCacheItems(Item1, Item2: TDefinePropertiesCacheItem
  ): integer;
begin
  Result:=CompareText(Item1.PersistentClassname,Item2.PersistentClassname);
end;

function ComparePersClassNameAndDefPropCacheItem(Key: Pointer;
                                     Item: TDefinePropertiesCacheItem): integer;
begin
  Result:=CompareText(AnsiString(Key),Item.PersistentClassname);
end;

procedure RegisterStandardClasses;
begin
  RegisterClasses([TStrings]);
end;

{ TComponentInterface }

constructor TComponentInterface.Create;
begin
  inherited Create;
end;

constructor TComponentInterface.Create(AComponent: TComponent);
begin
  inherited Create;
  FComponent:=AComponent;
end;

destructor TComponentInterface.Destroy;
begin
  FreeAndNil(FComponentEditor);
  inherited Destroy;
end;

Function TComponentInterface.FSetProp(PRI : PPropInfo;
const Value) : Boolean;
Begin
//writeln('Index = '+inttostr(PRI^.index));
  case PRI^.PropType^.Kind of
  tkBool: Begin
             //Writeln('Boolean....');
             SetOrdProp(FComponent,PRI,longint(Value));
             Result := True;
             end;
  tkSString,
  tkLString,
  tkAString,
  tkWString : Begin
              //Writeln('String...');
              SetStrProp(FComponent,PRI,ShortString(Value));
              Result := True;
             end;
  tkInteger,
  tkInt64   : Begin
              //Writeln('Int64...');
              SetInt64Prop(FComponent,PRI,Int64(Value));
              Result := True;
             end;
  tkFloat  : Begin
              //Writeln('Float...');
              SetFloatProp(FComponent,PRI,Extended(Value));
              Result := True;
             end;
  {$IFDEF HasVariant}
  tkVariant  : Begin
              //Writeln('Variant...');
              SetVariantProp(FComponent,PRI,Variant(Value));
              Result := True;
             end;
  {$ENDIF}
  tkMethod  : Begin
              //Writeln('Method...');
              SetMethodProp(FComponent,PRI,TMethod(value));
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
       tkBool    : Longint(Value) := GetOrdProp(FComponent,PRI);
       tkSString,
       tkLString,
       tkAString,
       tkWString : Begin
                    //Writeln('Get String...');
                    ShortString(Value) := GetStrProp(FComponent,PRI);
                    DebugLn('The string returned is '+String(value));
                    DebugLn('*Get String...');
                   end;
       tkInteger,
       tkInt64   : Begin
                    //Writeln('Get Int64...');
                    Int64(Value) := GetInt64Prop(FComponent,PRI);
                   end;
       tkFloat  : Begin
                    //Writeln('Get Float...');
                    Extended(Value) := GetFloatProp(FComponent,PRI);
                   end;
       tkVariant  : Begin
                    //Writeln('Get Variant...');
                    Variant(Value) := GetVariantProp(FComponent,PRI);
                   end;
       tkMethod  : Begin
                    //Writeln('Get Method...');
                    TMethod(Value) := GetMethodProp(FComponent,PRI);
                   end;
         else
          Result := False;
       end;//case
end;

function TComponentInterface.GetDesigner: TComponentEditorDesigner;
var
  DesignerForm: TCustomForm;
begin
  if FDesigner=nil then begin
    DesignerForm:=GetDesignerForm(Component);
    if DesignerForm=nil then begin
      raise Exception.Create('TComponentInterface.GetDesigner: '
        +Component.Name+' DesignerForm=nil');
    end;
    FDesigner:=TComponentEditorDesigner(DesignerForm.Designer);
    if FDesigner=nil then begin
      raise Exception.Create('TComponentInterface.GetDesigner: '
        +Component.Name+' Designer=nil');
    end;
    if not (FDesigner is TComponentEditorDesigner) then begin
      raise Exception.Create('TComponentInterface.GetDesigner: '
         +Component.Name+' Designer='+FDesigner.ClassName);
    end;
  end;
  Result:=FDesigner;
end;

Function TComponentInterface.GetPPropInfoByIndex(Index:Integer): PPropInfo;
var
  PT : PTypeData;
  PP : PPropList;
  PI : PTypeInfo;
Begin
  PI := FComponent.ClassInfo;
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
  PI := FComponent.ClassInfo;
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
  Result:=FComponent.ClassName;
end;

Function TComponentInterface.GetComponentHandle  : LongInt;
Begin
//return the TWinControl handle?
  if (Component is TWinControl) then
  Result := TWinControl(Component).Handle;
end;

Function TComponentInterface.GetParent : TIComponentInterface;
Begin
  result := nil;
  if (FComponent is TControl) then
  if TControl(FComponent).Parent <> nil then
  begin
     Result := FFormEditor.FindComponent(TControl(FComponent).Parent);
  end;
end;

Function TComponentInterface.IsTControl : Boolean;
Begin
  Result := (FComponent is TControl);
end;

Function TComponentInterface.GetPropCount : Integer;
var
  PT : PTypeData;
Begin
  PT:=GetTypeData(FComponent.ClassInfo);
  Result := PT^.PropCount;
end;

Function TComponentInterface.GetPropType(Index : Integer) : TTypeKind;
var
PT : PTypeData;
PP : PPropList;
PI : PTypeInfo;
Begin
  PI:=FComponent.ClassInfo;
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
  PI:=FComponent.ClassInfo;
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
  PI:=FComponent.ClassInfo;
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
  PI:=FComponent.ClassInfo;
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
  PI:=FComponent.ClassInfo;
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

  PRI := GetPropInfo(FComponent.ClassInfo,Name);
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
  if (FComponent is TWinControl) and (TWinControl(FComponent).CanFocus) then
  Begin
    TWinControl(FComponent).SetFocus;
    Result := True;
  end;
end;

Function TComponentInterface.Delete: Boolean;
var
  OldName, OldClassName: string;
Begin
  {$IFDEF VerboseFormEditor}
  writeln('TComponentInterface.Delete A ',Component.Name,':',Component.ClassName);
  {$ENDIF}
  {$IFNDEF NoCompCatch}
  try
  {$ENDIF}
    OldName:=Component.Name;
    OldClassName:=Component.ClassName;
    Component.Free;
  {$IFNDEF NoCompCatch}
  except
    on E: Exception do begin
      DebugLn('TComponentInterface.Delete ERROR:',
        ' "'+OldName+':'+OldClassName+'" ',E.Message);
      MessageDlg('Error',
        'An exception occured during deletion of'#13
        +'"'+OldName+':'+OldClassName+'"'#13
        +E.Message,
        mtError,[mbOk],0);
    end;
  end;
  {$ENDIF}
  FComponent:=nil;
  {$IFDEF VerboseFormEditor}
  writeln('TComponentInterface.Delete B ');
  {$ENDIF}
  Free;
  Result := True;
end;

function TComponentInterface.GetComponentEditor: TBaseComponentEditor;
begin
  if FComponentEditor=nil then begin
    FComponentEditor:=ComponentEditors.GetComponentEditor(Component,Designer);
  end;
  Result:=FComponentEditor;
end;


{ TCustomFormEditor }

constructor TCustomFormEditor.Create;
begin
  inherited Create;
  FComponentInterfaces := TAVLTree.Create(@CompareComponentInterfaces);
  FNonControlForms:=TAVLTree.Create(@CompareNonControlForms);
  FSelection := TPersistentSelectionList.Create;
  
  JITFormList := TJITForms.Create;
  JITFormList.OnReaderError:=@JITListReaderError;
  JITFormList.OnPropertyNotFound:=@JITListPropertyNotFound;

  JITNonFormList := TJITNonFormComponents.Create;
  JITNonFormList.OnReaderError:=@JITListReaderError;
  JITNonFormList.OnPropertyNotFound:=@JITListPropertyNotFound;

  DesignerMenuItemClick:=@OnDesignerMenuItemClick;
  OnGetDesignerForm:=@GetDesignerForm;
  FormEditingHook:=Self;
end;

destructor TCustomFormEditor.Destroy;
begin
  FormEditingHook:=nil;
  DesignerMenuItemClick:=nil;
  if FDefineProperties<>nil then begin
    FDefineProperties.FreeAndClear;
    FreeAndNil(FDefineProperties);
  end;
  FreeAndNil(JITFormList);
  FreeAndNil(JITNonFormList);
  FreeAndNil(FComponentInterfaces);
  FreeAndNil(FSelection);
  FreeAndNil(FNonControlForms);
  inherited Destroy;
end;

procedure TCustomFormEditor.SetSelection(
  const ASelection: TPersistentSelectionList);
begin
  FSelection.Assign(ASelection);
  if FSelection.Count>0 then begin
    Obj_Inspector.PropertyEditorHook.LookupRoot:=
      GetLookupRootForComponent(FSelection[0]);
  end;
  Obj_Inspector.Selection := FSelection;
end;

Function TCustomFormEditor.AddSelected(Value : TComponent) : Integer;
Begin
  Result := FSelection.Add(Value) + 1;
  Obj_Inspector.Selection := FSelection;
end;

Procedure TCustomFormEditor.DeleteComponent(AComponent: TComponent;
  FreeComponent: boolean);
var
  Temp : TComponentInterface;
  i: integer;
  AForm: TCustomForm;
Begin
  Temp := TComponentInterface(FindComponent(AComponent));
  if Temp <> nil then
  begin
    FComponentInterfaces.Remove(Temp);

    DebugLn('TCustomFormEditor.DeleteControl ',
            AComponent.ClassName,' ',BoolToStr(IsJITComponent(AComponent)));
    if IsJITComponent(AComponent) then begin
      // value is a top level component
      if FreeComponent then begin
        i:=AComponent.ComponentCount-1;
        while i>=0 do begin
          DeleteComponent(AComponent.Components[i],true);
          dec(i);
          if i>AComponent.ComponentCount-1 then
            i:=AComponent.ComponentCount-1;
        end;
        if PropertyEditorHook.LookupRoot=AComponent then
          PropertyEditorHook.LookupRoot:=nil;
        if JITFormList.IsJITForm(AComponent) then
          // free a form component
          JITFormList.DestroyJITComponent(AComponent)
        else if JITNonFormList.IsJITNonForm(AComponent) then begin
          // free a non form component and its designer form
          AForm:=GetDesignerForm(AComponent);
          if not (AForm is TNonFormDesignerForm) then
            RaiseException('TCustomFormEditor.DeleteControl  Where is the TNonFormDesignerForm? '+AComponent.ClassName);
          FNonControlForms.Remove(AForm);
          TNonFormDesignerForm(AForm).LookupRoot:=nil;
          AForm.Free;
          JITNonFormList.DestroyJITComponent(AComponent);
        end else
          RaiseException('TCustomFormEditor.DeleteControl '+AComponent.ClassName);
      end;
      Temp.Free;
    end
    else begin
      // value is a normal child component
      if FreeComponent then
        Temp.Delete
      else
        Temp.Free;
    end;
  end;
end;

Function TCustomFormEditor.FindComponentByName(
  const Name: ShortString) : TIComponentInterface;
Var
  ANode: TAVLTreeNode;
Begin
  ANode:=FComponentInterfaces.FindLowest;
  while ANode<>nil do begin
    Result := TIComponentInterface(ANode.Data);
    if AnsiCompareText(TComponentInterface(Result).Component.Name,Name)=0 then
      exit;
    ANode:=FComponentInterfaces.FindSuccessor(ANode);
  end;
  Result:=nil;
end;

Function TCustomFormEditor.FindComponent(AComponent: TComponent
  ): TIComponentInterface;
Var
  ANode: TAVLTreeNode;
Begin
  ANode:=FComponentInterfaces.FindKey(Pointer(AComponent),
                                      @CompareComponentAndInterface);
  if ANode<>nil then
    Result:=TIComponentInterface(ANode.Data)
  else
    Result:=nil;
end;

function TCustomFormEditor.SaveSelectionToStream(s: TStream): boolean;
var
  ADesigner: TIDesigner;
begin
  ADesigner:=GetCurrentDesigner;
  if ADesigner is TComponentEditorDesigner then
    Result:=TComponentEditorDesigner(ADesigner).CopySelectionToStream(s)
  else
    Result:=false;
end;

function TCustomFormEditor.InsertFromStream(s: TStream; Parent: TWinControl;
  Flags: TComponentPasteSelectionFlags): Boolean;
var
  ADesigner: TIDesigner;
begin
  ADesigner:=GetCurrentDesigner;
  if ADesigner is TComponentEditorDesigner then
    Result:=TComponentEditorDesigner(ADesigner).InsertFromStream(s,Parent,Flags)
  else
    Result:=false;
end;

function TCustomFormEditor.ClearSelection: Boolean;
var
  ASelection: TPersistentSelectionList;
begin
  if Selection.Count=0 then exit;
  ASelection:=TPersistentSelectionList.Create;
  try
    Selection:=ASelection;
  except
    on E: Exception do begin
      MessageDlg('Error',
        'Unable to clear form editing selection'#13
        +E.Message,mtError,[mbCancel],0);
    end;
  end;
  ASelection.Free;
  Result:=(Selection=nil) or (Selection.Count=0);
end;

function TCustomFormEditor.DeleteSelection: Boolean;
var
  ADesigner: TIDesigner;
begin
  if (Selection.Count=0) then begin
    Result:=true;
    exit;
  end;
  if Selection[0] is TComponent then begin
    ADesigner:=FindRootDesigner(TComponent(Selection[0]));
    if ADesigner is TComponentEditorDesigner then begin
      TComponentEditorDesigner(ADesigner).DeleteSelection;
    end;
  end;
  Result:=Selection.Count=0;
  if Selection.Count>0 then begin
    MessageDlg('Error',
      'Do not know how to delete this form editing selection',
      mtError,[mbCancel],0);
  end;
end;

function TCustomFormEditor.CopySelectionToClipboard: Boolean;
var
  ADesigner: TIDesigner;
begin
  if (Selection.Count=0) then begin
    Result:=false;
    exit;
  end;
  if Selection[0] is TComponent then begin
    ADesigner:=FindRootDesigner(TComponent(Selection[0]));
    if ADesigner is TComponentEditorDesigner then begin
      TComponentEditorDesigner(ADesigner).CopySelection;
    end;
  end;
  Result:=Selection.Count=0;
  if Selection.Count>0 then begin
    MessageDlg('Error',
      'Do not know how to copy this form editing selection',
      mtError,[mbCancel],0);
  end;
end;

function TCustomFormEditor.CutSelectionToClipboard: Boolean;
var
  ADesigner: TIDesigner;
begin
  if (Selection.Count=0) then begin
    Result:=false;
    exit;
  end;
  if Selection[0] is TComponent then begin
    ADesigner:=FindRootDesigner(TComponent(Selection[0]));
    if ADesigner is TComponentEditorDesigner then begin
      TComponentEditorDesigner(ADesigner).CutSelection;
    end;
  end;
  Result:=Selection.Count=0;
  if Selection.Count>0 then begin
    MessageDlg('Error',
      'Do not know how to cut this form editing selection',
      mtError,[mbCancel],0);
  end;
end;

function TCustomFormEditor.PasteSelectionFromClipboard(
  Flags: TComponentPasteSelectionFlags): Boolean;
var
  ADesigner: TIDesigner;
begin
  ADesigner:=GetCurrentDesigner;
  if ADesigner is TComponentEditorDesigner then begin
    Result:=TComponentEditorDesigner(ADesigner).PasteSelection(Flags);
  end else
    Result:=false;
end;

function TCustomFormEditor.IsJITComponent(AComponent: TComponent): boolean;
begin
  Result:=JITFormList.IsJITForm(AComponent)
          or JITNonFormList.IsJITNonForm(AComponent);
end;

function TCustomFormEditor.GetJITListOfType(AncestorType: TComponentClass
  ): TJITComponentList;
begin
  if AncestorType.InheritsFrom(TForm) then
    Result:=JITFormList
  else if AncestorType.InheritsFrom(TComponent) then
    Result:=JITNonFormList
  else
    Result:=nil;
end;

function TCustomFormEditor.FindJITList(AComponent: TComponent
  ): TJITComponentList;
begin
  if JITFormList.IndexOf(AComponent)>=0 then
    Result:=JITFormList
  else if JITNonFormList.IndexOf(AComponent)>=0 then
    Result:=JITNonFormList
  else
    Result:=nil;
end;

function TCustomFormEditor.FindJITListByClassName(
  const AComponentClassName: string): TJITComponentList;
begin
  if JITFormList.FindComponentByClassName(AComponentClassName)>=0 then
    Result:=JITFormList
  else if JITNonFormList.FindComponentByClassName(AComponentClassName)>=0 then
    Result:=JITNonFormList
  else
    Result:=nil;
end;

function TCustomFormEditor.GetDesignerForm(AComponent: TComponent
  ): TCustomForm;
var
  OwnerComponent: TComponent;
begin
  Result:=nil;
  OwnerComponent:=AComponent;
  while OwnerComponent.Owner<>nil do
    OwnerComponent:=OwnerComponent.Owner;
  if OwnerComponent is TCustomForm then
    Result:=TCustomForm(OwnerComponent)
  else
    Result:=FindNonControlForm(OwnerComponent);
end;

function TCustomFormEditor.FindNonControlForm(LookupRoot: TComponent
  ): TNonFormDesignerForm;
var
  AVLNode: TAVLTreeNode;
begin
  AVLNode:=FindNonControlFormNode(LookupRoot);
  if AVLNode<>nil then
    Result:=TNonFormDesignerForm(AVLNode.Data)
  else
    Result:=nil;
end;

function TCustomFormEditor.CreateNonControlForm(LookupRoot: TComponent
  ): TNonFormDesignerForm;
begin
  if FindNonControlFormNode(LookupRoot)<>nil then
    RaiseException('TCustomFormEditor.CreateNonControlForm exists already');
  if LookupRoot is TComponent then begin
    Result:=TNonFormDesignerForm.Create(nil);
    Result.LookupRoot:=LookupRoot;
    FNonControlForms.Add(Result);
  end else
    RaiseException('TCustomFormEditor.CreateNonControlForm Unknown type '
      +LookupRoot.ClassName);
end;

procedure TCustomFormEditor.RenameJITComponent(AComponent: TComponent;
  const NewName: shortstring);
var
  JITComponentList: TJITComponentList;
begin
  JITComponentList:=FindJITList(AComponent);
  if JITComponentList=nil then
    RaiseException('TCustomFormEditor.RenameJITComponent');
  JITComponentList.RenameComponentClass(AComponent,NewName);
end;

procedure TCustomFormEditor.UpdateDesignerFormName(AComponent: TComponent);
var
  ANonControlForm: TNonFormDesignerForm;
begin
  ANonControlForm:=FindNonControlForm(AComponent);
  DebugLn('TCustomFormEditor.UpdateDesignerFormName ',
    BoolToStr(ANonControlForm<>nil), ' ',AComponent.Name);
  if ANonControlForm<>nil then
    ANonControlForm.Caption:=AComponent.Name;
end;

function TCustomFormEditor.CreateNewJITMethod(AComponent: TComponent;
  const AMethodName: shortstring): TMethod;
var
  JITComponentList: TJITComponentList;
begin
  JITComponentList:=FindJITList(AComponent);
  if JITComponentList=nil then
    RaiseException('TCustomFormEditor.CreateNewJITMethod');
  Result:=JITComponentList.CreateNewMethod(AComponent,AMethodName);
end;

procedure TCustomFormEditor.RenameJITMethod(AComponent: TComponent;
  const OldMethodName, NewMethodName: shortstring);
var
  JITComponentList: TJITComponentList;
begin
  JITComponentList:=FindJITList(AComponent);
  if JITComponentList=nil then
    RaiseException('TCustomFormEditor.RenameJITMethod');
  JITComponentList.RenameMethod(AComponent,OldMethodName,NewMethodName);
end;

procedure TCustomFormEditor.SaveHiddenDesignerFormProperties(
  AComponent: TComponent);
var
  NonControlForm: TNonFormDesignerForm;
begin
  NonControlForm:=FindNonControlForm(AComponent);
  if NonControlForm<>nil then
    NonControlForm.DoSaveBounds;
end;

function TCustomFormEditor.FindJITComponentByClassName(
  const AComponentClassName: string): TComponent;
var
  JITComponentList: TJITComponentList;
  i: LongInt;
begin
  Result:=nil;
  JITComponentList:=FindJITListByClassName(AComponentClassName);
  if JITComponentList=nil then exit;
  i:=JITComponentList.FindComponentByClassName(AComponentClassName);
  if i<0 then exit;
  Result:=JITComponentList[i];
end;

function TCustomFormEditor.DesignerCount: integer;
begin
  Result:=JITFormList.Count+JITNonFormList.Count;
end;

function TCustomFormEditor.GetDesigner(Index: integer): TIDesigner;
var
  AForm: TCustomForm;
begin
  if Index<JITFormList.Count then
    Result:=JITFormList[Index].Designer
  else begin
    AForm:=GetDesignerForm(JITNonFormList[Index-JITFormList.Count]);
    Result:=TIDesigner(AForm.Designer);
  end;
end;

function TCustomFormEditor.GetCurrentDesigner: TIDesigner;
begin
  Result:=nil;
  if (Selection<>nil) and (Selection.Count>0) and (Selection[0] is TComponent)
  then
    Result:=GetDesignerByComponent(TComponent(Selection[0]));
end;

function TCustomFormEditor.GetDesignerByComponent(AComponent: TComponent
  ): TIDesigner;
var
  AForm: TCustomForm;
begin
  AForm:=GetDesignerForm(AComponent);
  if AForm=nil then
    Result:=nil
  else
    Result:=AForm.Designer;
end;

function TCustomFormEditor.GetComponentEditor(AComponent: TComponent
  ): TBaseComponentEditor;
var
  ACompIntf: TComponentInterface;
begin
  Result:=nil;
  if AComponent=nil then exit;
  ACompIntf:=TComponentInterface(FindComponent(AComponent));
  if ACompIntf=nil then exit;
  Result:=ACompIntf.GetComponentEditor;
end;

Function TCustomFormEditor.CreateComponent(ParentCI: TIComponentInterface;
  TypeClass: TComponentClass;  X,Y,W,H: Integer): TIComponentInterface;
Var
  Temp: TComponentInterface;
  NewJITIndex: Integer;
  CompLeft, CompTop, CompWidth, CompHeight: integer;
  NewComponent: TComponent;
  OwnerComponent: TComponent;
  ParentComponent: TComponent;
  JITList: TJITComponentList;
  AControl: TControl;
  NewComponentName: String;
  DesignForm: TCustomForm;
Begin
  Result:=nil;
  Temp:=nil;
  try
    DebugLn('[TCustomFormEditor.CreateComponent] Class='''+TypeClass.ClassName+'''');
    {$IFDEF IDE_MEM_CHECK}CheckHeapWrtMemCnt('TCustomFormEditor.CreateComponent A');{$ENDIF}

    OwnerComponent:=nil;
    if Assigned(ParentCI) then
    begin
      // add as child component
      ParentComponent:=TComponentInterface(ParentCI).Component;
      OwnerComponent:=ParentComponent;
      if OwnerComponent.Owner<>nil then
        OwnerComponent:=OwnerComponent.Owner;
      try
        NewComponent := TypeClass.Create(OwnerComponent);
      except
        on e: Exception do begin
          MessageDlg('Error creating component',
            'Error creating component: '+TypeClass.ClassName,
            mtError,[mbCancel],0);
          exit;
        end;
      end;
      // check if Owner was properly set
      if NewComponent.Owner<>OwnerComponent then begin
        MessageDlg('Invalid component owner',
          'The component of type '+NewComponent.ClassName
          +' failed to set its owner to '
          +OwnerComponent.Name+':'+OwnerComponent.ClassName,
          mtError,[mbCancel],0);
        exit;
      end;
      
      // create component interface
      Temp := TComponentInterface.Create(NewComponent);
      // set parent
      if Temp.IsTControl then begin
        if (ParentComponent is TWinControl)
        and (csAcceptsControls in TWinControl(ParentComponent).ControlStyle) then
        begin
          TWinControl(Temp.Component).Parent :=
            TWinControl(ParentComponent);
          DebugLn('Parent is '''+TWinControl(Temp.Component).Parent.Name+'''');
        end
        else begin
          TControl(Temp.Component).Parent :=
            TControl(ParentComponent).Parent;
          DebugLn('Parent is '''+TControl(Temp.Component).Parent.Name+'''');
        end;
      end;
    end else begin
      // create a toplevel component
      // -> a form or a datamodule or a custom component
      ParentComponent:=nil;
      JITList:=GetJITListOfType(TypeClass);
      if JITList=nil then
        RaiseException('TCustomFormEditor.CreateComponent '+TypeClass.ClassName);
      NewJITIndex := JITList.AddNewJITComponent(DefaultJITUnitName,TypeClass);
      if NewJITIndex >= 0 then
        // create component interface
        Temp := TComponentInterface.Create(JITList[NewJITIndex])
      else
        exit;
    end;
    {$IFDEF IDE_MEM_CHECK}CheckHeapWrtMemCnt('TCustomFormEditor.CreateComponent D ');{$ENDIF}
    try
      NewComponentName := CreateUniqueComponentName(Temp.Component);
      Temp.Component.Name := NewComponentName;
    except
      on e: Exception do begin
        MessageDlg('Error naming component',
          'Error setting the name of a component '
          +Temp.Component.Name+':'+Temp.Component.ClassName
          +' to '+NewComponentName,
          mtError,[mbCancel],0);
        exit;
      end;
    end;

    try
      // set bounds
      CompLeft:=X;
      CompTop:=Y;
      CompWidth:=W;
      CompHeight:=H;
      if (Temp.Component is TControl) then
      Begin
        AControl:=TControl(Temp.Component);
        if CompWidth<=0 then CompWidth:=Max(5,AControl.Width);
        if CompHeight<=0 then CompHeight:=Max(5,AControl.Height);
        if CompLeft<0 then begin
          if AControl.Parent<>nil then
            CompLeft:=(AControl.Parent.Width - CompWidth) div 2
          else if AControl is TCustomForm then
            CompLeft:=Max(1,Min(250,Screen.Width-CompWidth-50))
          else
            CompLeft:=0;
        end;
        if CompTop<0 then begin
          if AControl.Parent<>nil then
            CompTop:=(AControl.Parent.Height - CompHeight) div 2
          else if AControl is TCustomForm then
            CompTop:=Max(1,Min(250,Screen.Height-CompHeight-50))
          else
            CompTop:=0;
        end;
        AControl.SetBounds(CompLeft,CompTop,CompWidth,CompHeight);
      end
      else if (Temp.Component is TDataModule) then begin
        // data module
        with TDataModule(Temp.Component) do begin
          if CompWidth<=0 then CompWidth:=Max(50,DesignSize.X);
          if CompHeight<=0 then CompHeight:=Max(50,DesignSize.Y);
          if CompLeft<0 then
            CompLeft:=Max(1,Min(250,Screen.Width-CompWidth-50));
          if CompTop<0 then
            CompTop:=Max(1,Min(250,Screen.Height-CompHeight-50));
          DesignOffset:=Point(CompLeft,CompTop);
          DesignSize:=Point(CompWidth,CompHeight);
          //debugln('TCustomFormEditor.CreateComponent TDataModule Bounds ',dbgsName(Temp.Component),' ',dbgs(DesignOffset.X),',',dbgs(DesignOffset.Y),' ',HexStr(Cardinal(Temp.Component),8),' ',HexStr(Cardinal(@DesignOffset),8));
        end;
      end
      else begin
        // non TControl
        with LongRec(Temp.Component.DesignInfo) do begin
          Lo:=word(Min(32000,CompLeft));
          Hi:=word(Min(32000,CompTop));
        end;
        if (ParentComponent<>nil) then begin
          DesignForm:=GetDesignerForm(ParentComponent);
          if DesignForm<>nil then DesignForm.Invalidate;
        end;
      end;
    except
      on e: Exception do begin
        MessageDlg(lisErrorMovingComponent,
          Format(lisErrorMovingComponent2, [Temp.Component.Name,
            Temp.Component.ClassName]),
          mtError,[mbCancel],0);
        exit;
      end;
    end;

    {$IFDEF IDE_MEM_CHECK}CheckHeapWrtMemCnt('TCustomFormEditor.CreateComponent F ');{$ENDIF}
    // add to component list
    FComponentInterfaces.Add(Temp);

    if Temp.Component.Owner<>nil then
      CreateChildComponentInterfaces(Temp.Component.Owner);

    Result := Temp;
  finally
    // clean up carefully
    if Result=nil then begin
      if Temp=nil then begin
        if NewComponent<>nil then begin
          try
            NewComponent.Free;
            NewComponent:=nil;
          except
            MessageDlg('Error destroying component',
              'Error destroying component of type '+TypeClass.ClassName,
              mtError,[mbCancel],0);
          end;
        end;
      end;
      if (Result<>Temp) then begin
        Temp.Free;
        Temp:=nil;
      end;
    end;
  end;
end;

Function TCustomFormEditor.CreateComponentFromStream(
  BinStream: TStream; AncestorType: TComponentClass;
  const NewUnitName: ShortString; Interactive: boolean): TIComponentInterface;
var
  NewJITIndex: integer;
  NewComponent: TComponent;
  JITList: TJITComponentList;
begin
  // create JIT Component
  JITList:=GetJITListOfType(AncestorType);
  if JITList=nil then
    RaiseException('TCustomFormEditor.CreateComponentFromStream ClassName='+
                   AncestorType.ClassName);
  NewJITIndex := JITList.AddJITComponentFromStream(BinStream,AncestorType,
                                                   NewUnitName,Interactive);
  if NewJITIndex < 0 then begin
    Result:=nil;
    exit;
  end;
  NewComponent:=JITList[NewJITIndex];
  
  // create a component interface for the form
  Result:=CreateComponentInterface(NewComponent);

  CreateChildComponentInterfaces(NewComponent);
end;

function TCustomFormEditor.CreateChildComponentFromStream(BinStream: TStream;
  ComponentClass: TComponentClass; Root: TComponent;
  ParentControl: TWinControl): TIComponentInterface;
var
  NewComponent: TComponent;
  JITList: TJITComponentList;
  i: Integer;
begin
  Result:=nil;
  
  JITList:=FindJITList(Root);
  if JITList=nil then
    RaiseException('TCustomFormEditor.CreateChildComponentFromStream ClassName='+
                   Root.ClassName);

  NewComponent:=JITList.AddJITChildComponentFromStream(
                                   Root,BinStream,ComponentClass,ParentControl);
                                                 
  // create a component interface for the new child component
  Result:=CreateComponentInterface(NewComponent);

  // create a component interface for each new child component
  for i:=0 to Root.ComponentCount-1 do
    if FindComponent(Root.Components[i])=nil then
      CreateComponentInterface(Root.Components[i]);
end;

Procedure TCustomFormEditor.SetComponentNameAndClass(CI: TIComponentInterface;
  const NewName, NewClassName: shortstring);
var
  AComponent: TComponent;
  JITList: TJITComponentList;
begin
  AComponent:=TComponentInterface(CI).Component;
  JITList:=GetJITListOfType(TComponentClass(AComponent.ClassType));
  JITList.RenameComponentClass(AComponent,NewClassName);
  AComponent.Name:=NewName;
end;

procedure TCustomFormEditor.FindDefineProperty(
  const APersistentClassName, AncestorClassName, Identifier: string;
  var IsDefined: boolean);
var
  AutoFreePersistent: Boolean;
  APersistent: TPersistent;
  CacheItem: TDefinePropertiesCacheItem;
  DefinePropertiesReader: TDefinePropertiesReader;
  ANode: TAVLTreeNode;
  OldClassName: String;
  DefinePropertiesPersistent: TDefinePropertiesPersistent;

  function CreateTempPersistent(
    const APersistentClass: TPersistentClass): boolean;
  begin
    Result:=false;
    if APersistent<>nil then
      RaiseGDBException('TCustomFormEditor.FindDefineProperty.CreateTempPersistent Inconsistency');
    try
      if APersistentClass.InheritsFrom(TComponent) then
        APersistent:=TComponentClass(APersistentClass).Create(nil)
      else if APersistentClass.InheritsFrom(TGraphic) then
        APersistent:=TGraphicClass(APersistentClass).Create
      else
        APersistent:=APersistentClass.Create;
      Result:=true;
      AutoFreePersistent:=true;
    except
      on E: Exception do begin
        debugln('TCustomFormEditor.GetDefineProperties Error creating ',
          APersistentClass.Classname,
          ': ',E.Message);
      end;
    end;
  end;
  
  function GetDefinePersistent(const AClassName: string): Boolean;
  var
    APersistentClass: TPersistentClass;
  begin
    Result:=false;
    
    // try to find the AClassName in the registered components
    if APersistent=nil then begin
      CacheItem.RegisteredComponent:=IDEComponentPalette.FindComponent(AClassname);
      if (CacheItem.RegisteredComponent<>nil)
      and (CacheItem.RegisteredComponent.ComponentClass<>nil) then begin
        debugln('TCustomFormEditor.GetDefineProperties ComponentClass ',AClassName,' is registered');
        if not CreateTempPersistent(CacheItem.RegisteredComponent.ComponentClass)
        then exit;
      end;
    end;
    
    // try to find the AClassName in the registered TPersistent classes
    if APersistent=nil then begin
      APersistentClass:=Classes.GetClass(AClassName);
      if APersistentClass<>nil then begin
        debugln('TCustomFormEditor.GetDefineProperties PersistentClass ',AClassName,' is registered');
        if not CreateTempPersistent(APersistentClass) then exit;
      end;
    end;

    if APersistent=nil then begin
      // try to find the AClassName in the open forms/datamodules
      APersistent:=FindJITComponentByClassName(AClassName);
      if APersistent<>nil then
        debugln('TCustomFormEditor.GetDefineProperties ComponentClass ',
          AClassName,' is a resource,'
          +' but inheriting design is not yet implemented');
    end;

    // try default classes
    if (APersistent=nil) and (CompareText(AClassName,'TDataModule')=0) then
    begin
      if not CreateTempPersistent(TDataModule) then exit;
    end;
    if (APersistent=nil) and (CompareText(AClassName,'TForm')=0) then begin
      if not CreateTempPersistent(TForm) then exit;
    end;
    
    Result:=true;
  end;
  
begin
  //debugln('TCustomFormEditor.GetDefineProperties ',
  //  ' APersistentClassName="',APersistentClassName,'"',
  //  ' AncestorClassName="',AncestorClassName,'"',
  //  ' Identifier="',Identifier,'"');
  IsDefined:=false;
  if FDefineProperties=nil then
    FDefineProperties:=
                   TAVLTree.Create(TListSortCompare(@CompareDefPropCacheItems));
  ANode:=FDefineProperties.FindKey(PChar(APersistentClassName),
                    TListSortCompare(@ComparePersClassNameAndDefPropCacheItem));
  if ANode=nil then begin
    // cache component class, try to retrieve the define properties
    CacheItem:=TDefinePropertiesCacheItem.Create;
    CacheItem.PersistentClassname:=APersistentClassName;
    FDefineProperties.Add(CacheItem);
    debugln('TCustomFormEditor.GetDefineProperties APersistentClassName="',APersistentClassName,'" AncestorClassName="',AncestorClassName,'"');

    APersistent:=nil;
    AutoFreePersistent:=false;

    if not GetDefinePersistent(APersistentClassName) then exit;
    if (APersistent=nil) then begin
      if not GetDefinePersistent(AncestorClassName) then exit;
    end;

    if APersistent<>nil then begin
      //debugln('TCustomFormEditor.GetDefineProperties Getting define properties for ',APersistent.ClassName);
      // try creating a component class and call DefineProperties
      DefinePropertiesReader:=nil;
      DefinePropertiesPersistent:=nil;
      try
        try
          DefinePropertiesReader:=TDefinePropertiesReader.Create;
          DefinePropertiesPersistent:=
                                TDefinePropertiesPersistent.Create(APersistent);
          DefinePropertiesPersistent.PublicDefineProperties(
                                                        DefinePropertiesReader);
        except
          on E: Exception do begin
            debugln('TCustomFormEditor.GetDefineProperties Error calling DefineProperties for ',
              CacheItem.RegisteredComponent.ComponentClass.Classname,
              ': ',E.Message);
          end;
        end;
        // free component
        if AutoFreePersistent then begin
          try
            OldClassName:=APersistent.ClassName;
            APersistent.Free;
          except
            on E: Exception do begin
              debugln('TCustomFormEditor.GetDefineProperties Error freeing ',
                OldClassName,': ',E.Message);
            end;
          end;
        end;
      finally
        // cache defined properties
        if (DefinePropertiesReader<>nil)
        and (DefinePropertiesReader.DefinePropertyNames<>nil) then begin
          CacheItem.DefineProperties:=TStringList.Create;
          CacheItem.DefineProperties.Assign(
                                    DefinePropertiesReader.DefinePropertyNames);
          debugln('TCustomFormEditor.GetDefineProperties Class=',APersistentClassName,
            ' DefineProps="',CacheItem.DefineProperties.Text,'"');
        end;
        DefinePropertiesReader.Free;
        DefinePropertiesPersistent.Free;
      end;
    end else begin
      debugln('TCustomFormEditor.GetDefineProperties Persistent is NOT registered');
    end;
    //debugln('TCustomFormEditor.GetDefineProperties END APersistentClassName="',APersistentClassName,'" AncestorClassName="',AncestorClassName,'"');
  end else begin
    CacheItem:=TDefinePropertiesCacheItem(ANode.Data);
  end;
  if CacheItem.DefineProperties<>nil then
    IsDefined:=CacheItem.DefineProperties.IndexOf(Identifier)>=0;
end;

procedure TCustomFormEditor.JITListReaderError(Sender: TObject;
  ErrorType: TJITFormError; var Action: TModalResult);
var
  aCaption, aMsg: string;
  DlgType: TMsgDlgType;
  Buttons: TMsgDlgButtons;
  HelpCtx: Longint;
  JITComponentList: TJITComponentList;
begin
  JITComponentList:=TJITComponentList(Sender);
  aCaption:='Error reading '+JITComponentList.ComponentPrefix;
  aMsg:='';
  DlgType:=mtError;
  Buttons:=[mbCancel];
  HelpCtx:=0;
  
  with JITComponentList do begin
    aMsg:=aMsg+ComponentPrefix+': ';
    if CurReadJITComponent<>nil then
      aMsg:=aMsg+CurReadJITComponent.Name+':'+CurReadJITComponent.ClassName
    else
      aMsg:=aMsg+'?';
    if CurReadChild<>nil then
      aMsg:=aMsg+#13'Component: '
        +CurReadChild.Name+':'+CurReadChild.ClassName
    else if CurReadChildClass<>nil then
      aMsg:=aMsg+#13'Component Class: '+CurReadChildClass.ClassName;
    aMsg:=aMsg+#13+CurReadErrorMsg;
  end;

  case ErrorType of
    jfeUnknownProperty, jfeReaderError:
      begin
        Buttons:=[mbIgnore,mbCancel];
      end;
    jfeUnknownComponentClass:
      begin
        aMsg:=aMsg+#13+'Class "'+JITComponentList.CurUnknownClass+'" not found.';
      end;
  end;
  Action:=MessageDlg(aCaption,aMsg,DlgType,Buttons,HelpCtx);
end;

procedure TCustomFormEditor.OnDesignerMenuItemClick(Sender: TObject);
var
  CompEditor: TBaseComponentEditor;
  MenuItem: TMenuItem;
begin
  if (Sender=nil) or (not (Sender is TMenuItem)) then exit;
  MenuItem:=TMenuItem(Sender);
  if (MenuItem.Count>0) or MenuItem.IsInMenuBar then exit;

  CompEditor:=GetComponentEditor(TComponent(Sender));
  if CompEditor=nil then exit;
  try
    CompEditor.Edit;
  except
    on E: Exception do begin
      DebugLn('TCustomFormEditor.OnDesignerMenuItemClick ERROR: ',E.Message);
      MessageDlg('Error in '+CompEditor.ClassName,
        'The component editor of class "'+CompEditor.ClassName+'"'
        +'has created the error:'#13
        +'"'+E.Message+'"',
        mtError,[mbOk],0);
    end;
  end;
end;

function TCustomFormEditor.FindNonControlFormNode(LookupRoot: TComponent
  ): TAVLTreeNode;
begin
  Result:=FNonControlForms.FindKey(Pointer(LookupRoot),
                                   @CompareLookupRootAndNonControlForm);
end;

procedure TCustomFormEditor.JITListPropertyNotFound(Sender: TObject;
  Reader: TReader; Instance: TPersistent; var PropName: string;
  IsPath: boolean; var Handled, Skip: Boolean);
begin
  DebugLn('TCustomFormEditor.JITListPropertyNotFound ',Sender.ClassName,
    ' Instance=',Instance.ClassName,' PropName="',PropName,
    '" IsPath=',BoolToStr(IsPath));
end;

function TCustomFormEditor.GetPropertyEditorHook: TPropertyEditorHook;
begin
  Result:=Obj_Inspector.PropertyEditorHook;
end;

function TCustomFormEditor.CreateUniqueComponentName(AComponent: TComponent
  ): string;
begin
  Result:='';
  if (AComponent=nil) then exit;
  Result:=AComponent.Name;
  if (AComponent.Owner=nil) or (Result<>'') then exit;
  Result:=CreateUniqueComponentName(AComponent.ClassName,AComponent.Owner);
end;

function TCustomFormEditor.CreateUniqueComponentName(const AClassName: string;
  OwnerComponent: TComponent): string;
var
  i, j: integer;
begin
  Result:=AClassName;
  if (OwnerComponent=nil) or (Result='') then exit;
  i:=1;
  while true do begin
    j:=OwnerComponent.ComponentCount-1;
    Result:=AClassName;
    if (length(Result)>1) and (Result[1]='T') then
      Result:=RightStr(Result,length(Result)-1);
    {$IfDef VER1_0}
    //make it more presentable
    Result := Result[1] + lowercase(Copy(Result,2,length(Result)));
    {$EndIf}
    Result:=Result+IntToStr(i);
    while (j>=0)
    and (AnsiCompareText(Result,OwnerComponent.Components[j].Name)<>0) do
      dec(j);
    if j<0 then exit;
    inc(i);
  end;
end;

function TCustomFormEditor.TranslateKeyToDesignerCommand(Key: word;
  Shift: TShiftState): word;
begin
  Result:=EditorOpts.KeyMap.TranslateKey(Key,Shift,[caDesigner]);
end;

Function TCustomFormEditor.CreateComponentInterface(
  AComponent: TComponent): TIComponentInterface;
Begin
  if FindComponent(AComponent)<>nil then exit;
  Result := TComponentInterface.Create(AComponent);
  FComponentInterfaces.Add(Result);
end;

procedure TCustomFormEditor.CreateChildComponentInterfaces(
  AComponent: TComponent);
var
  i: Integer;
begin
  // create a component interface for each component owned by the new component
  for i:=0 to AComponent.ComponentCount-1 do
    CreateComponentInterface(AComponent.Components[i]);
end;

function TCustomFormEditor.GetDefaultComponentParent(TypeClass: TComponentClass
  ): TIComponentInterface;
var
  NewParent: TComponent;
  Root: TPersistent;
begin
  Result:=nil;
  // find selected component
  if (FSelection = nil) or (FSelection.Count <= 0) then Exit;
  NewParent:=TComponent(FSelection[0]);
  if not (NewParent is TComponent) then exit;
  if TypeClass<>nil then begin
    if TypeClass.InheritsFrom(TControl) then begin
      // New TypeClass is a TControl => use only a TWinControl as parent
      while (NewParent<>nil) do begin
        if (NewParent is TWinControl)
        and (csAcceptsControls in TWinControl(NewParent).ControlStyle) then
          break;
      end;
    end else begin
      // New TypeClass is not a TControl => Root component as parent
      Root:=GetLookupRootForComponent(NewParent);
      if Root is TComponent then
        NewParent:=TComponent(Root);
    end;
  end;
  Result:=FindComponent(NewParent);
end;

function TCustomFormEditor.GetDefaultComponentPosition(
  TypeClass: TComponentClass; ParentCI: TIComponentInterface; var X, Y: integer
  ): boolean;
var
  ParentComponent: TComponent;
  i: Integer;
  CurComponent: TComponent;
  P: TPoint;
  AForm: TNonFormDesignerForm;
  MinX: Integer;
  MinY: Integer;
  MaxX: Integer;
  MaxY: Integer;
begin
  Result:=true;
  X:=10;
  Y:=10;
  if ParentCI=nil then
    ParentCI:=GetDefaultComponentParent(TypeClass);
  if (ParentCI=nil) or (ParentCI.Component=nil) then exit;
  if TypeClass<>nil then begin
    if not (TypeClass.InheritsFrom(TControl)) then begin
      // a non visual component
      // put it somewhere right or below the other non visual components
      ParentComponent:=ParentCI.Component;
      MinX:=-1;
      MinY:=-1;
      if ParentComponent is TWinControl then begin
        MaxX:=TWinControl(ParentComponent).ClientWidth-ComponentPaletteBtnWidth;
        MaxY:=TWinControl(ParentComponent).ClientHeight-ComponentPaletteBtnHeight;
      end else begin
        AForm:=FindNonControlForm(ParentComponent);
        if AForm<>nil then begin
          MaxX:=AForm.ClientWidth-ComponentPaletteBtnWidth;
          MaxY:=AForm.ClientHeight-ComponentPaletteBtnHeight;
        end else begin
          MaxX:=300;
          MaxY:=0;
        end;
      end;
      // find top left most non visual component
      for i:=0 to ParentComponent.ComponentCount-1 do begin
        CurComponent:=ParentComponent.Components[i];
        if ComponentIsNonVisual(CurComponent) then begin
          P:=GetParentFormRelativeTopLeft(CurComponent);
          if (P.X>=0) and (P.Y>=0) then begin
            if (MinX<0) or (P.Y<MinY) or ((P.Y=MinY) and (P.X<MinX)) then begin
              MinX:=P.X;
              MinY:=P.Y;
            end;
          end;
        end;
      end;
      if MinX<0 then begin
        MinX:=10;
        MinY:=10;
      end;
      // find a position without intersection
      X:=MinX;
      Y:=MinY;
      //debugln('TCustomFormEditor.GetDefaultComponentPosition Min=',dbgs(MinX),',',dbgs(MinY));
      i:=0;
      while i<ParentComponent.ComponentCount do begin
        CurComponent:=ParentComponent.Components[i];
        inc(i);
        if ComponentIsNonVisual(CurComponent) then begin
          P:=GetParentFormRelativeTopLeft(CurComponent);
          //debugln('TCustomFormEditor.GetDefaultComponentPosition ',dbgsName(CurComponent),' P=',dbgs(P));
          if (P.X>=0) and (P.Y>=0) then begin
            if (X+ComponentPaletteBtnWidth>=P.X)
            and (X<=P.X+ComponentPaletteBtnWidth)
            and (Y+ComponentPaletteBtnHeight>=P.Y)
            and (Y<=P.Y+ComponentPaletteBtnHeight) then begin
              // intersection found
              // move position
              inc(X,ComponentPaletteBtnWidth+2);
              if X>MaxX then begin
                inc(Y,ComponentPaletteBtnHeight+2);
                X:=MinX;
              end;
              // restart intersection test
              i:=0;
            end;
          end;
        end;
      end;
      // keep it visible
      if X>MaxX then X:=MaxX;
      if Y>MaxY then Y:=MaxY;
    end;
  end;
end;

procedure TCustomFormEditor.OnObjectInspectorModified(Sender: TObject);
var
  CustomForm: TCustomForm;
  Instance: TPersistent;
begin
  if (FSelection = nil)
  or (FSelection.Count <= 0) then Exit;
  
  Instance := FSelection[0];
  if Instance is TComponent then
    CustomForm:=GetDesignerForm(TComponent(Instance))
  else
    CustomForm:=nil;

  if (CustomForm<>nil) and (CustomForm.Designer<>nil) then
    CustomForm.Designer.Modified;
end;

procedure TCustomFormEditor.SetObj_Inspector(
  AnObjectInspector: TObjectInspector);
begin
  if AnObjectInspector=FObj_Inspector then exit;
  if FObj_Inspector<>nil then begin
    FObj_Inspector.OnModified:=nil;
  end;

  FObj_Inspector:=AnObjectInspector;
  
  if FObj_Inspector<>nil then begin
    FObj_Inspector.OnModified:=@OnObjectInspectorModified;
  end;
end;


{ TDefinePropertiesCacheItem }

destructor TDefinePropertiesCacheItem.Destroy;
begin
  DefineProperties.Free;
  inherited Destroy;
end;

{ TDefinePropertiesReader }

procedure TDefinePropertiesReader.AddPropertyName(const Name: string);
begin
  debugln('TDefinePropertiesReader.AddPropertyName Name="',Name,'"');
  if FDefinePropertyNames=nil then FDefinePropertyNames:=TStringList.Create;
  if FDefinePropertyNames.IndexOf(Name)<=0 then
    FDefinePropertyNames.Add(Name);
end;

destructor TDefinePropertiesReader.Destroy;
begin
  FDefinePropertyNames.Free;
  inherited Destroy;
end;

procedure TDefinePropertiesReader.DefineProperty(const Name: string;
  ReadData: TReaderProc; WriteData: TWriterProc; HasData: Boolean);
begin
  AddPropertyName(Name);
end;

procedure TDefinePropertiesReader.DefineBinaryProperty(const Name: string;
  ReadData, WriteData: TStreamProc; HasData: Boolean);
begin
  AddPropertyName(Name);
end;

{ TDefinePropertiesPersistent }

constructor TDefinePropertiesPersistent.Create(TargetPersistent: TPersistent);
begin
  FTarget:=TargetPersistent;
end;

procedure TDefinePropertiesPersistent.PublicDefineProperties(Filer: TFiler);
begin
  debugln('TDefinePropertiesPersistent.PublicDefineProperties A ',ClassName,' ',dbgsName(FTarget));
  Target.DefineProperties(Filer);
  debugln('TDefinePropertiesPersistent.PublicDefineProperties END ',ClassName,' ',dbgsName(FTarget));
end;

initialization
  RegisterStandardClasses;

end.

