{ /***************************************************************************
                   widgetstack.pp  -  Designer Widget Stack
                             -------------------
                 Implements a widget list created by TDesigner.


                 Initial Revision  : Sat May 10 23:15:32 CST 1999


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
unit designer;

{$mode objfpc}

interface

uses
  classes, Forms, controls, lmessages, graphics, ControlSelection, FormEditor;

type
  TGridPoint = record
      x: integer;
      y: integer;
    end;

  TDesigner = class(TIDesigner)
  private
    FCustomForm: TCustomForm;
    FFormEditor : TFormEditor;
    function GetIsControl: Boolean;
    procedure SetIsControl(Value: Boolean);
    FSource : TStringList;
    Function GetFormAncestor : String;
  protected
    Function NewModuleSource(nmUnitName, nmForm, nmAncestor: String) : Boolean;
  public
    ControlSelection : TControlSelection;
    constructor Create(customform : TCustomform);
    destructor Destroy; override;
    Function AddControlCode(Control : TComponent) : Boolean;
    procedure CreateNew(FileName : string);
    procedure LoadFile(FileName: string);

    function IsDesignMsg(Sender: TControl; var Message: TLMessage): Boolean; override;
    procedure Modified; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure PaintGrid; override;
    procedure ValidateRename(AComponent: TComponent; const CurName, NewName: string); override;
    property IsControl: Boolean read GetIsControl write SetIsControl;
    property Form: TCustomForm read FCustomForm write FCustomForm;
    property FormEditor : TFormEditor read FFormEditor write FFormEditor;
    property FormAncestor : String read GetFormAncestor;
 end;

 implementation

uses
  Sysutils, Typinfo;

var
  GridPoints : TGridPoint;


constructor TDesigner.Create(CustomForm : TCustomForm);
var
  nmUnit : String;
  I : Integer;
begin
  inherited Create;


  FCustomForm := CustomForm;
  FSource := TStringList.Create;
  //create the code for the unit

  if UpperCase(copy(FormAncestor,1,4))='FORM' then
    nmUnit:='Unit'+copy(FormAncestor,5,length(FormAncestor)-4)
  else
    nmUnit:='Unit1';
  NewModuleSource(nmUnit,CustomForm.Name,FormAncestor);

  // The controlselection should NOT be owned by the form.
  // When it is it shows up in the OI
  // XXX ToDo: The OI should ask the formeditor for a good list of components
  ControlSelection := TControlSelection.Create(CustomForm);

  try
    Writeln('**********************************************');
    for I := 1 to FSource.Count do
    writeln(FSource.Strings[i-1]);
    Writeln('**********************************************');
  except
    Application.MessageBox('error','error',0);
  end;
end;

destructor TDesigner.Destroy;
Begin
  ControlSelection.free;
  FSource.Free;

  Inherited;
end;

Function TDesigner.GetFormAncestor : String;
var
  PI : PTypeInfo;
begin
  PI := FCustomForm.ClassInfo;
  Result := PI^.Name;
  Delete(Result,1,1);
end;


procedure TDesigner.CreateNew(FileName : string);
begin

end;

function TDesigner.IsDesignMsg(Sender: TControl; var Message: TLMessage): Boolean;
Begin

end;

procedure TDesigner.LoadFile(FileName: string);
begin

end;

procedure TDesigner.Modified;
Begin

end;

Function TDesigner.NewModuleSource(nmUnitName, nmForm, nmAncestor: String): Boolean;
Var
  I : Integer;
Begin
  FSource.Clear;
  Result := True;
  with FSource do
   try
     Add(Format('unit %s;', [nmUnitname]));
     Add('');
     Add('interface');
     Add('');
     Add('uses Classes, Graphics, Controls, Forms, Dialogs;');
     Add('');
     Add('type');
     Add(Format('     T%s = class(T%s)', [nmForm,nmAncestor]));
     Add('     private');
     Add('     { private declarations}');
     Add('     public');
     Add('     { public declarations }');
     Add('     end;');
     Add('');
     Add('var');
     Add(Format('     %s: T%0:s;', [nmForm]));
     Add('');
     Add('implementation');
     Add('');
     Add('end.');
   except
     Result := False;
   end;
end;

Function TDesigner.AddControlCode(Control : TComponent) : Boolean;
var
  PT : PTypeData;
  PI : PTypeInfo;
  nmControlType : String;
  I : Integer;
  NewSource : String;
begin
  //get the control name
  PI := Control.ClassInfo;
  nmControlType := PI^.Name;

//find the place in the code to add this now.
//Anyone have good method sfor parsing the source to find spots like this?
//here I look for the Name of the customform, the word "Class", and it's ancestor on the same line
//not very good because it could be a comment or just a description of the class.
//but for now I'll use it.
For I := 0 to FSource.Count-1 do
    if (pos(FormAncestor,FSource.Strings[i]) <> 0) and (pos(FCustomForm.Name,FSource.Strings[i]) <> 0) and (pos('CLASS',Uppercase(FSource.Strings[i])) <> 0) then
        Break;



  //if I => FSource.Count then I didn't find the line...
  If I < FSource.Count then
     Begin
       //alphabetical
       inc(i);
       NewSource := Control.Name+' : '+nmControlType+';';

       //  Here I decide if I need to try and insert the control's text code in any certain order.
       //if there's no controls then I just insert it, otherwise...
       if TWincontrol(Control.Owner).ControlCount > 0 then
       while NewSource > (trim(FSource.Strings[i])) do
         inc(i);

          FSource.Insert(i,'       '+NewSource);
     end;
//debugging
  try
    Writeln('**********************************************');
    for I := 1 to FSource.Count do
    writeln(FSource.Strings[i-1]);
    Writeln('**********************************************');
  except
    Application.MessageBox('error','error',0);
  end;
//debugging end


end;

procedure TDesigner.Notification(AComponent: TComponent; Operation: TOperation);
Begin
 if Operation = opInsert then
   begin
   end
  else
  if Operation = opRemove then
    begin
     writeln('[TDesigner.Notification] opRemove '+
       ''''+AComponent.ClassName+'.'+AComponent.Name+'''');
      if (AComponent is TControl) then
      if ControlSelection.IsSelected(TControl(AComponent)) then
          ControlSelection.Remove(TControl(AComponent));
    end;
end;

procedure TDesigner.PaintGrid;
var
  x,y : integer;
begin
  with FCustomForm do
    Begin
      canvas.Pen.Color := clGray;
      x := left;
      while x <= left + width do
        begin
          y := Top;
          while y <= top+height do
            begin
              Canvas.Rectangle(x-left,y-top,x-left+1,y-top);
              Inc(y, GridPoints.Y);
            end;
          Inc(x, GridPoints.X);
        end;
    end;
end;

procedure TDesigner.ValidateRename(AComponent: TComponent; const CurName, NewName: string);
Begin

end;

function TDesigner.GetIsControl: Boolean;
Begin

end;

procedure TDesigner.SetIsControl(Value: Boolean);
Begin

end;

initialization
  GridPoints.x := 10;
  GridPoints.Y := 10;

end.

