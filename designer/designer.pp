{ /***************************************************************************
                   designer.pp  -  Lazarus IDE unit
                   --------------------------------

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
unit Designer;

{$mode objfpc}{$H+}

interface

uses
  Classes, LCLType, LCLLinux, Forms, Controls, LMessages, Graphics,
  ControlSelection, CustomFormEditor, FormEditor, UnitEditor, CompReg, Menus,
  AlignCompsDlg, SizeCompsDlg, ScaleCompsDlg, ExtCtrls;

type
  TDesigner = class;

  TOnGetSelectedComponentClass = procedure(Sender: TObject; 
    var RegisteredComponent: TRegisteredComponent) of object;
  TOnSetDesigning = procedure(Sender: TObject; Component: TComponent;
    Value: boolean) of object;
  TOnAddComponent = procedure(Sender: TObject; Component: TComponent;
    ComponentClass: TRegisteredComponent) of object;
  TOnRemoveComponent = procedure(Sender: TObject; Component: TComponent)
    of object;
  TOnGetNonVisualCompIconCanvas = procedure(Sender: TObject;
    AComponent: TComponent; var IconCanvas: TCanvas) of object;
  TOnRenameComponent = procedure(Designer: TDesigner; AComponent: TComponent;
    const NewName: string) of object;

  TDesigner = class(TIDesigner)
  private
    FCustomForm: TCustomForm;
    FFormEditor : TFormEditor;
    FSourceEditor : TSourceEditor;
    FHasSized: boolean;
    FGridColor: TColor;
    FDuringPaintControl: boolean;
    FOnAddComponent: TOnAddComponent;
    FOnComponentListChanged: TNotifyEvent;
    FOnGetSelectedComponentClass: TOnGetSelectedComponentClass;
    FOnGetNonVisualCompIconCanvas: TOnGetNonVisualCompIconCanvas;
    FOnModified: TNotifyEvent;
    FOnPropertiesChanged: TNotifyEvent;
    FOnRemoveComponent: TOnRemoveComponent;
    FOnSetDesigning: TOnSetDesigning;
    FOnUnselectComponentClass: TNotifyEvent;
    FOnActivated: TNotifyEvent;
    FOnRenameComponent: TOnRenameComponent;
    FPopupMenu: TPopupMenu;
    FAlignMenuItem: TMenuItem;
    FMirrorHorizontalMenuItem: TMenuItem;
    FMirrorVerticalMenuItem: TMenuItem;
    FScaleMenuItem: TMenuItem;
    FSizeMenuItem: TMenuItem;
    FBringToFrontMenuItem: TMenuItem;
    FSendToBackMenuItem: TMenuItem;
    FShowHints: boolean;

    //hint stuff
    FHintTimer : TTimer;
    FHintWIndow : THintWindow;
    function GetIsControl: Boolean;
    procedure SetIsControl(Value: Boolean);
    procedure InvalidateWithParent(AComponent: TComponent);
    Procedure HintTimer(sender : TObject);
  protected
    MouseDownComponent, MouseDownSender : TComponent;
    MouseDownPos, MouseUpPos, LastMouseMovePos : TPoint;

    function PaintControl(Sender: TControl; Message: TLMPaint):boolean;
    function SizeControl(Sender: TControl; Message: TLMSize):boolean;
    function MoveControl(Sender: TControl; Message: TLMMove):boolean;
    Procedure MouseDownOnControl(Sender : TControl; Message : TLMMouse);
    Procedure MouseMoveOnControl(Sender : TControl; var Message : TLMMouse);
    Procedure MouseLeftUpOnControl(Sender : TControl; Message:TLMMouse);
    Procedure MouseRightUpOnControl(Sender : TControl; Message:TLMMouse);
    Procedure KeyDown(Sender : TControl; Message:TLMKEY);
    Procedure KeyUP(Sender : TControl; Message:TLMKEY);

    Procedure RemoveControl(Control : TComponent);
    Procedure NudgeControl(DiffX, DiffY: Integer);
    Procedure NudgeSize(DiffX, DiffY: Integer);

    procedure BuildPopupMenu;
    procedure OnAlignPopupMenuClick(Sender: TObject);
    procedure OnMirrorHorizontalPopupMenuClick(Sender: TObject);
    procedure OnMirrorVerticalPopupMenuClick(Sender: TObject);
    procedure OnScalePopupMenuClick(Sender: TObject);
    procedure OnSizePopupMenuClick(Sender: TObject);
    procedure OnBringToFrontMenuClick(Sender: TObject);
    procedure OnSendToBackMenuClick(Sender: TObject);
    Procedure OnFormActivated;
  public
    ControlSelection : TControlSelection;
    constructor Create(Customform : TCustomform; AControlSelection: TControlSelection);
    destructor Destroy; override;

    function IsDesignMsg(Sender: TControl; var Message: TLMessage): Boolean; override;
    procedure Modified; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure PaintGrid; override;
    procedure ValidateRename(AComponent: TComponent;
       const CurName, NewName: string); override;
    Procedure SelectOnlyThisComponent(AComponent:TComponent);

    property IsControl: Boolean read GetIsControl write SetIsControl;
    property Form: TCustomForm read FCustomForm write FCustomForm;
    property FormEditor : TFormEditor read FFormEditor write FFormEditor;
    property SourceEditor : TSourceEditor read FSourceEditor write FSourceEditor;
    property OnAddComponent: TOnAddComponent read FOnAddComponent write FOnAddComponent;
    property OnComponentListChanged: TNotifyEvent
       read FOnComponentListChanged write FOnComponentListChanged;
    property OnGetSelectedComponentClass: TOnGetSelectedComponentClass
       read FOnGetSelectedComponentClass write FOnGetSelectedComponentClass;
    property OnModified: TNotifyEvent read FOnModified write FOnModified;
    property OnPropertiesChanged: TNotifyEvent
       read FOnPropertiesChanged write FOnPropertiesChanged;
    property OnRemoveComponent: TOnRemoveComponent
       read FOnRemoveComponent write FOnRemoveComponent;
    property OnSetDesigning: TOnSetDesigning read FOnSetDesigning write FOnSetDesigning;
    property OnUnselectComponentClass: TNotifyEvent
       read FOnUnselectComponentClass write FOnUnselectComponentClass;
    property OnActivated: TNotifyEvent
       read FOnActivated write FOnActivated;
    property OnRenameComponent: TOnRenameComponent
       read FOnRenameComponent write FOnRenameComponent;
    function NonVisualComponentAtPos(x,y: integer): TComponent;
    procedure DrawNonVisualComponents(DC: HDC);
    property OnGetNonVisualCompIconCanvas: TOnGetNonVisualCompIconCanvas
       read FOnGetNonVisualCompIconCanvas write FOnGetNonVisualCompIconCanvas;
    property ShowHints: boolean read FShowHints write FShowHints;
  end;


var GridSizeX, GridSizeY: integer;


implementation


uses
  Sysutils, Math;


const
  mk_lbutton =   1;
  mk_rbutton =   2;
  mk_shift   =   4;
  mk_control =   8;
  mk_mbutton = $10;


constructor TDesigner.Create(CustomForm : TCustomForm; 
  AControlSelection: TControlSelection);
begin
  inherited Create;
  FCustomForm := CustomForm;
  ControlSelection:=AControlSelection;
  FHasSized:=false;
  FGridColor:=clGray;
  FDuringPaintControl:=false;

  FHintTimer := TTimer.Create(nil);
  FHintTimer.Interval := 500;
  FHintTimer.Enabled := False;
  FHintTimer.OnTimer := @HintTimer;
  
  FHintWindow := THintWindow.Create(nil);

  FHIntWindow.Visible := False;
  FHintWindow.Caption := 'This is a hint window'#13#10'NEat huh?';
  FHintWindow.HideInterval := 4000;
  FHintWindow.AutoHide := True;
end;

destructor TDesigner.Destroy;
Begin
  if FPopupMenu<>nil then
    FPopupMenu.Free;
    
  FHintWIndow.Free;
  FHintTimer.Free;
  Inherited Destroy;
end;

Procedure TDesigner.RemoveControl(Control : TComponent);
Begin
  Writeln('[TDesigner.RemoveControl] ',Control.Name,':',Control.ClassName);
  if Assigned(FOnRemoveComponent) then
    FOnRemoveComponent(Self,Control);
  FCustomForm.RemoveControl(TCOntrol(Control));
  //this send a message to notification and removes it from the controlselection
  FFormEditor.DeleteControl(Control);
end;

Procedure TDesigner.NudgeControl(DiffX, DiffY : Integer);
Begin
  Writeln('[TDesigner.NudgeControl]');
  ControlSelection.MoveSelection(DiffX, DiffY);
  if ControlSelection.OnlyNonVisualComponentsSelected then
    FCustomForm.Invalidate;
end;

Procedure TDesigner.NudgeSize(DiffX, DiffY: Integer);
Begin
  Writeln('[TDesigner.NudgeSize]');
  ControlSelection.SizeSelection(DiffX, DiffY);
end;

procedure TDesigner.SelectOnlyThisComponent(AComponent:TComponent);
begin
  ControlSelection.BeginUpdate;
  ControlSelection.Clear;
  ControlSelection.Add(TControl(AComponent));
  ControlSelection.EndUpdate;
end;

procedure TDesigner.InvalidateWithParent(AComponent: TComponent);
begin
writeln('INVALIDATEWITHPARENT');
  if AComponent is TControl then begin
    if TControl(AComponent).Parent<>nil then
      TControl(AComponent).Parent.Invalidate
    else
      TControl(AComponent).Invalidate;
  end else begin
    FCustomForm.Invalidate;
  end;
end;

function TDesigner.PaintControl(Sender: TControl; Message: TLMPaint):boolean;
var OldDuringPaintControl: boolean;
begin
  Result:=true;

//writeln('***  LM_PAINT A ',Sender.Name,':',Sender.ClassName,' DC=',HexStr(Message.DC,8));
  OldDuringPaintControl:=FDuringPaintControl;
  FDuringPaintControl:=true;
  Sender.Dispatch(Message);
  

//writeln('***  LM_PAINT B ',Sender.Name,':',Sender.ClassName,' DC=',HexStr(Message.DC,8));
  if (ControlSelection.IsSelected(Sender)) then begin
    // writeln('***  LM_PAINT ',Sender.Name,':',Sender.ClassName,' DC=',HexStr(Message.DC,8));
    ControlSelection.DrawMarker(Sender,Message.DC);
  end;
  //if OldDuringPaintControl=false then begin
    DrawNonVisualComponents(Message.DC);
    ControlSelection.DrawGrabbers(Message.DC);
    if ControlSelection.RubberBandActive then
      ControlSelection.DrawRubberBand(Message.DC);
//  end;
  FDuringPaintControl:=OldDuringPaintControl;
end;

function TDesigner.SizeControl(Sender: TControl; Message: TLMSize):boolean;
begin
  Result:=true;
  Sender.Dispatch(Message);
  if (ControlSelection.IsSelected(Sender)) then begin
//    writeln('***  LM_Size ',Sender.Name,':',Sender.ClassName,' Type=',Message.SizeType
// ,' ',Message.Width,',',Message.Height,' Pos=',Sender.Left,',',Sender.Top);
    if not ControlSelection.IsResizing then begin
      ControlSelection.AdjustSize;
      if Assigned(FOnPropertiesChanged) then
        FOnPropertiesChanged(Self);
    end;
  end;
end;

function TDesigner.MoveControl(Sender: TControl; Message: TLMMove):boolean;
begin
  Result:=true;
  Sender.Dispatch(Message);
  if (ControlSelection.IsSelected(Sender)) then begin
//    writeln('***  LM_Move ',Sender.Name,':',Sender.ClassName);
    ControlSelection.AdjustSize;
    if Assigned(FOnPropertiesChanged) then
      FOnPropertiesChanged(Self);
  end;

end;

procedure TDesigner.MouseDownOnControl(Sender : TControl; Message : TLMMouse);
var i,
  MouseX,MouseY,
  CompIndex:integer;
  SenderOrigin:TPoint;
  AControlSelection:TControlSelection;
  SelectedCompClass: TRegisteredComponent;
  NonVisualComp: TComponent;
Begin
  FHintTimer.Enabled := False;
  FHasSized:=false;
  if (MouseDownComponent<>nil) or (getParentForm(Sender)=nil) then exit;
  MouseDownComponent:=Sender;
  MouseDownSender:=Sender; 


  SenderOrigin:=GetFormRelativeControlTopLeft(Sender);
  MouseX:=Message.Pos.X+SenderOrigin.X;
  MouseY:=Message.Pos.Y+SenderOrigin.Y;

  MouseDownPos := Point(MouseX,MouseY);
  LastMouseMovePos:=MouseDownPos;

  writeln('************************************************************');
  write('MouseDownOnControl');
  write(' ',Sender.Name,':',Sender.ClassName,' Origin=',SenderOrigin.X,',',SenderOrigin.Y);
  write(' Msg=',Message.Pos.X,',',Message.Pos.Y);
  write(' Mouse=',MouseX,',',MouseY);
  writeln('');


  if (Message.Keys and MK_Shift) = MK_Shift then
    Write(' Shift down')
  else
    Write(' No Shift down');

  if (Message.Keys and MK_Control) = MK_Control then
    Writeln(', CTRL down')
  else
    Writeln(', No CTRL down');

  if (Message.Keys and MK_LButton) > 0 then begin
    ControlSelection.ActiveGrabber:=
      ControlSelection.GrabberAtPos(MouseDownPos.X,MouseDownPos.Y)
  end else
    ControlSelection.ActiveGrabber:=nil;

  if Assigned(FOnGetSelectedComponentClass) then
    FOnGetSelectedComponentClass(Self,SelectedCompClass)
  else
    SelectedCompClass:=nil;

  if (Message.Keys and MK_LButton) > 0 then begin
    if SelectedCompClass = nil then begin
      // selection mode
      if ControlSelection.ActiveGrabber=nil then begin
        NonVisualComp:=NonVisualComponentAtPos(
           MouseDownPos.X,MouseDownPos.Y);
        Writeln('ActiveGrabber = nil');
        if NonVisualComp<>nil then Writeln('1') else Writeln('2');
        if NonVisualComp<>nil then MouseDownComponent:=NonVisualComp;
        CompIndex:=ControlSelection.IndexOf(MouseDownComponent);
        if (Message.Keys and MK_SHIFT)>0 then begin
          // shift key  (multiselection)
          if CompIndex<0 then begin
            // not selected
            // add component to selection
            if (ControlSelection.Count=0)
            or (not (Sender is TCustomForm)) then begin
              ControlSelection.Add(MouseDownComponent);
              InvalidateWithParent(MouseDownComponent);
            end;
          end else begin
            // remove from multiselection
            ControlSelection.Delete(CompIndex);
            InvalidateWithParent(MouseDownComponent);
          end;
        end else begin
          // no shift key (single selection)
          if (CompIndex<0) then begin
            // select only this component
            AControlSelection:=TControlSelection.Create;
            AControlSelection.Assign(ControlSelection);
            ControlSelection.BeginUpdate;
            ControlSelection.Clear;
            for i:=0 to AControlSelection.Count-1 do
              if AControlSelection[i].Component is TControl then
                TControl(AControlSelection[i].Component).Invalidate;
            ControlSelection.Add(MouseDownComponent);
            ControlSelection.EndUpdate;
            InvalidateWithParent(MouseDownComponent);
            AControlSelection.Free;
          end;  
        end;
      end else begin
        // mouse down on grabber -> begin sizing
        // grabber is already activated
        // the sizing is handled in mousemove
writeln('[TDesigner.MouseDownOnControl] Grabber activated');
      end;
    end else begin
      // add component mode  -> handled in mousemove and mouseup
    end;
  end;

writeln('[TDesigner.MouseDownOnControl] END');
End;

procedure TDesigner.MouseLeftUpOnControl(Sender : TControl; Message:TLMMouse);
var
  ParentCI, NewCI : TComponentInterface;
  NewLeft, NewTop, NewWidth, NewHeight,
  MouseX, MouseY : Integer;
  Shift : TShiftState;
  SenderParentForm:TCustomForm;
  RubberBandWasActive:boolean;
  SenderOrigin:TPoint;
  SelectedCompClass: TRegisteredComponent;
Begin
  FHintTimer.Enabled := False;

  SenderParentForm:=GetParentForm(Sender);
  if (MouseDownComponent=nil) or (SenderParentForm=nil) then exit;

  ControlSelection.ActiveGrabber:=nil;
  RubberBandWasActive:=ControlSelection.RubberBandActive;

  Shift := [];
  if (Message.keys and MK_Shift) = MK_Shift then
    Shift := [ssShift];
  if (Message.keys and MK_Control) = MK_Control then
    Shift := Shift +[ssCTRL];



  SenderOrigin:=GetFormRelativeControlTopLeft(Sender);
  MouseX:=Message.Pos.X+SenderOrigin.X;
  MouseY:=Message.Pos.Y+SenderOrigin.Y;
  MouseUpPos := Point(MouseX,MouseY);
  dec(MouseX,MouseDownPos.X);
  dec(MouseY,MouseDownPos.Y);

  writeln('************************************************************');
  write('MouseLeftUpOnControl');
  write(' ',Sender.Name,':',Sender.ClassName,' Origin=',SenderOrigin.X,',',SenderOrigin.Y);
  write(' Msg=',Message.Pos.X,',',Message.Pos.Y);
  write(' Mouse=',MouseX,',',MouseY);
  writeln('');


  if Assigned(FOnGetSelectedComponentClass) then
    FOnGetSelectedComponentClass(Self,SelectedCompClass)
  else
    SelectedCompClass:=nil;

  if (Message.Keys and MK_LButton) > 0 then begin
    // left mouse button
    if SelectedCompClass = nil then begin
      // selection mode
      ControlSelection.BeginUpdate;
      if not FHasSized then begin
        if RubberBandWasActive then begin
          if (not (ssShift in Shift)) 
          or ((ControlSelection.Count=1) 
           and (ControlSelection[0].Component is TCustomForm)) then
            ControlSelection.Clear;
          ControlSelection.SelectWithRubberBand(
            SenderParentForm,ssShift in Shift);
          if ControlSelection.Count=0 then
            ControlSelection.Add(SenderParentForm);
          ControlSelection.RubberbandActive:=false;
        end else begin
          if (not (ssShift in Shift)) then begin
            ControlSelection.Clear;
            ControlSelection.Add(Sender);
          end;
        end;
        ControlSelection.EndUpdate;
        SenderParentForm.Invalidate;
      end;
    end else begin 
      // add a new control
      ControlSelection.RubberbandActive:=false;
      ControlSelection.BeginUpdate;
      if Assigned(FOnSetDesigning) then FOnSetDesigning(Self,FCustomForm,False);
      ParentCI:=TComponentInterface(FFormEditor.FindComponent(Sender));
      if (Sender is TWinControl)
      and (not (csAcceptsControls in TWinControl(Sender).ControlStyle)) then begin
        ParentCI:=TComponentInterface(
          FFormEditor.FindComponent(TWinControl(Sender).Parent));
      end;
      if Assigned(ParentCI) then begin
        NewLeft:=Min(MouseDownPos.X,MouseUpPos.X)-SenderOrigin.X;
        NewWidth:=Abs(MouseUpPos.X-MouseDownPos.X)-SenderOrigin.Y;
        NewTop:=Min(MouseDownPos.Y,MouseUpPos.Y);
        NewHeight:=Abs(MouseUpPos.Y-MouseDownPos.Y);
        if Abs(NewWidth+NewHeight)<7 then begin
          // this very small component is probably only a wag, take default size
          NewWidth:=0;
          NewHeight:=0;
        end;
        NewCI := TComponentInterface(FFormEditor.CreateComponent(
           ParentCI,SelectedCompClass.ComponentClass
          ,NewLeft,NewTop,NewWidth,NewHeight));
        NewCI.SetPropByName('Visible',True);
        NewCI.SetPropByName('Designing',True);
        if Assigned(FOnSetDesigning) then
          FOnSetDesigning(Self,NewCI.Control,True);
        if Assigned(FOnComponentListChanged) then
          FOnComponentListChanged(Self);
        if Assigned(FOnAddComponent) then
          FOnAddComponent(Self,NewCI.Control,SelectedCompClass);

        SelectOnlyThisComponent(TComponent(NewCI.Control));
        Writeln('Calling ControlClick with nil from MouseLeftUpOnControl');
        if not (ssShift in Shift) then
          if Assigned(FOnUnselectComponentClass) then
            // this resets the component toolbar to the mouse. (= selection tool)
            FOnUnselectComponentClass(Self);
        if Assigned(FOnSetDesigning) then
          FOnSetDesigning(Self,FCustomForm,True);
        Form.Invalidate;
writeln('NEW COMPONENT ADDED: ',Form.ComponentCount,'  ',NewCI.Control.Owner.Name);
      end;
      ControlSelection.EndUpdate;
    end;
  end;
  LastMouseMovePos.X:=-1;
  FHasSized:=false;

  MouseDownComponent:=nil;
  MouseDownSender:=nil;
writeln('[TDesigner.MouseLeftUpOnControl] END');
end;

Procedure TDesigner.MouseMoveOnControl(Sender : TControl; var Message : TLMMouse);
var
  Shift : TShiftState;
  SenderOrigin:TPoint;
  SenderParentForm:TCustomForm;
  MouseX, MouseY :integer;
  UpdateLastMove : Boolean;
begin
try
  UpdateLastMove := True;
  if FShowHints then begin
    FHintTimer.Enabled := False;

    { don't want it enabled when a mouse button is pressed.
 }
    FHintTimer.Enabled := (Message.keys or (MK_LButton and MK_RButton and MK_MButton) = 0);
    if FHintWindow.Visible then
 FHintWindow.Visible := False;
  end;

  if MouseDownComponent=nil then exit;

  SenderParentForm:=GetParentForm(Sender);
  if SenderParentForm=nil then exit;


  SenderOrigin:=GetFormRelativeControlTopLeft(Sender);

  MouseX:=Message.Pos.X+SenderOrigin.X;
  MouseY:=Message.Pos.Y+SenderOrigin.Y;
  if (Mouse.CursorPos.X < SenderParentForm.Left) or (Mouse.CursorPos.Y < SenderParentForm.Top) or
     (Mouse.CursorPos.X > (SenderParentForm.Left+SenderParentForm.Width+(TForm(senderparentform).borderwidth))) or (Mouse.CursorPos.Y > (SenderParentForm.Top+SenderParentForm.Height+(22)))  then
  begin
    UpdateLastMove := False;
    Exit;
  end;

//debugging commented out
{  if (Message.keys and MK_LButton) = MK_LButton then begin
    Write('MouseMoveOnControl'
          ,' ',Sender.ClassName
          ,' ',GetCaptureControl<>nil
          ,' ',Sender.Left,',',Sender.Top
          ,' Origin=',SenderOrigin.X,',',SenderOrigin.Y
          ,' Msg=',Message.Pos.x,',',Message.Pos.Y
          ,' Mouse=',MouseX,',',MouseY
    );
    write(' ',MouseDownComponent is TWinControl);
    if (MouseDownComponent is TControl) then begin
      write(' ',csCaptureMouse in TWinControl(MouseDownComponent).ControlStyle);
    end;
    writeln();
  end;
}
  Shift := [];
  if (TLMMouse(Message).keys and MK_Shift) = MK_Shift then
    Shift := [ssShift];
  if (TLMMouse(Message).keys and MK_Control) = MK_Control then
    Shift := Shift + [ssCTRL];

  if (Message.keys and MK_LButton) = MK_LButton then begin
    if ControlSelection.ActiveGrabber<>nil then
      begin
        FHasSized:=true;
        ControlSelection.SizeSelection(MouseX-LastMouseMovePos.X, MouseY-LastMouseMovePos.Y);
       //commented out by sxm 2001-11-21
       // if Assigned(FOnPropertiesChanged) then
       //    FOnPropertiesChanged(Self);
      end
      else
      begin
      if (not (MouseDownComponent is TCustomForm)) and (ControlSelection.Count>=1)
          and not (ControlSelection[0].Component is TCustomForm) then
        begin
          // move selection
          FHasSized:=true;
          //TODO:create a rubberband looking control to move instead of the components
          //that will speed up to updates.
          
          ControlSelection.MoveSelection(MouseX-LastMouseMovePos.X, MouseY-LastMouseMovePos.Y);
       //commented out by sxm 2001-11-21
        //  if Assigned(FOnPropertiesChanged) then
        //     FOnPropertiesChanged(Self);
        end
        else
        begin
          // rubberband selection/creation
          ControlSelection.RubberBandBounds:=Rect(MouseDownPos.X,MouseDownPos.Y,MouseX,MouseY);
          ControlSelection.RubberBandActive:=true;
          SenderParentForm.Invalidate;
        end;
    end;
  end else begin
    ControlSelection.ActiveGrabber:=nil;
  end;
 finally
    SenderOrigin:=GetFormRelativeControlTopLeft(Sender);
    if UpdateLastMove then
       LastMouseMovePos:=Point(MouseX,MouseY);
 end;
end;

procedure TDesigner.MouseRightUpOnControl(Sender : TControl; Message:TLMMouse);
var
  MouseX, MouseY : Integer;
  SenderOrigin: TPoint;
begin
  FHintTimer.Enabled := False;

  SenderOrigin:=GetFormRelativeControlTopLeft(Sender);
  MouseX:=Message.Pos.X+SenderOrigin.X;
  MouseY:=Message.Pos.Y+SenderOrigin.Y;
  BuildPopupMenu;
  FPopupMenu.Popup(MouseX,MouseY);
end;

{
-----------------------------K E Y D O W N -------------------------------
}
{
 Handles the keydown messages.  DEL deletes the selected controls, CTRL-ARROR
 moves the selection up one, SHIFT-ARROW resizes, etc.
}
Procedure TDesigner.KeyDown(Sender : TControl; Message:TLMKEY);
var
  I : Integer;
  Shift : TShiftState;
Begin
Writeln('KEYDOWN');
  with MEssage do
  Begin
    Writeln('CHARCODE = '+inttostr(charcode));
    Writeln('KEYDATA = '+inttostr(KeyData));
  end;


  Shift := KeyDataToShiftState(Message.KeyData);

  if (Message.CharCode = 46) then //DEL KEY
  begin
    if (ControlSelection.Count = 1) and (ControlSelection.Items[0].Component = FCustomForm) then
       Exit;
    ControlSelection.BeginUpdate;
    for  I := ControlSelection.Count-1 downto 0 do Begin
      Writeln('I = '+inttostr(i));
      RemoveControl(ControlSelection.Items[I].Component);
    End;
    SelectOnlythisComponent(FCustomForm);
    ControlSelection.EndUpdate;
  end
  else
  if Message.CharCode = 38 then //UP ARROW
  Begin
    if (ssCtrl in Shift) then
      NudgeControl(0,-1)
    else if (ssShift in Shift) then
      NudgeSize(0,-1);
    end
  else if Message.CharCode = 40 then //DOWN ARROW
  Begin
    if (ssCtrl in Shift) then
      NudgeControl(0,1)
    else if (ssShift in Shift) then
      NudgeSize(0,1);
    end
  else
  if Message.CharCode = 39 then //RIGHT ARROW
  Begin
    if (ssCtrl in Shift) then
      NudgeControl(1,0)
    else if (ssShift in Shift) then
      NudgeSize(1,0);
    end
  else
  if Message.CharCode = 37 then //LEFT ARROW
  Begin
    if (ssCtrl in Shift) then
      NudgeControl(-1,0)
    else if (ssShift in Shift) then
      NudgeSize(-1,0);
    end;
end;


{-----------------------------------------K E Y U P --------------------------------}
Procedure TDesigner.KeyUp(Sender : TControl; Message:TLMKEY);
Begin
Writeln('KEYUp');
  with MEssage do
  Begin
    Writeln('CHARCODE = '+inttostr(charcode));
    Writeln('KEYDATA = '+inttostr(KeyData));
  end;

end;

function TDesigner.IsDesignMsg(Sender: TControl; var Message: TLMessage): Boolean;
Begin
  Result := false;
  if csDesigning in Sender.ComponentState then begin

    if ((Message.Msg >= LM_MOUSEFIRST) and (Message.Msg <= LM_MOUSELAST)) then
      Result := true
    else
    if ((Message.Msg >= LM_KeyFIRST) and (Message.Msg <= LM_KeyLAST)) then
      Result:=true
    else
    if (Message.Msg = LM_ACTIVATE) then
      Result := True;
//    else
//    if ((Message.Msg >= CM_MOUSEENTER) and (Message.Msg <= CM_MOUSELEAVE)) then
//      Result:=true;

    case Message.Msg of
      LM_PAINT:   Result:=PaintControl(Sender,TLMPaint(Message));
      LM_KEYDOWN: KeyDown(Sender,TLMKey(Message));
      LM_KEYUP:   KeyUP(Sender,TLMKey(Message));
      LM_LBUTTONDOWN,LM_RBUTTONDOWN: MouseDownOnControl(Sender,TLMMouse(Message));
      LM_LBUTTONUP:    MouseLeftUpOnControl(Sender,TLMMouse(Message));
      LM_RBUTTONUP:    MouseRightUpOnControl(sender,TLMMouse(Message));
      LM_MOUSEMOVE:    MouseMoveOnControl(Sender, TLMMouse(Message));
      LM_SIZE:    Result:=SizeControl(Sender,TLMSize(Message));
      LM_MOVE:    Result:=MoveControl(Sender,TLMMove(Message));
      LM_ACTIVATE : OnFormActivated;
//      CM_MOUSELEAVE:  Writeln('MOUSELEAVE!!!!!!!!!!!!');//Result:=MoveControl(Sender,TLMMove(Message));
    end;
  end;
end;

procedure TDesigner.Modified;
Begin
  ControlSelection.SaveBounds;
  if Assigned(FOnModified) then FOnModified(Self);
end;

procedure TDesigner.Notification(AComponent: TComponent; Operation: TOperation);
Begin
  if Operation = opInsert then
    begin
    Writeln('opInsert');
    end
  else
  if Operation = opRemove then
    begin
      writeln('[TDesigner.Notification] opRemove '+
        ''''+AComponent.ClassName+'.'+AComponent.Name+'''');
      if (AComponent is TControl) then
        if ControlSelection.IsSelected(AComponent) then
          ControlSelection.Remove(AComponent);
    end;
end;

procedure TDesigner.PaintGrid;
var
  x,y : integer;
begin
  with FCustomForm.Canvas do begin
    Pen.Color := FGridColor;
    x := 0;
    while x <= FCustomForm.Width do begin
      y := 0;
      while y <= FCustomForm.Height do begin

         MoveTo(x,y);
         LineTo(x+1,y);
//         Pixels[X,Y]:=FGridColor;

         Inc(y, GridSizeY);
      end;
      Inc(x, GridSizeX);
    end;
  end;
end;

procedure TDesigner.ValidateRename(AComponent: TComponent;
  const CurName, NewName: string);
Begin
  // check if contol is initialized
  if CurName='' then exit;
  // check if control is the form
  if AComponent=nil then AComponent:=FCustomForm;
  // consistency check
  if CurName<>AComponent.Name then
    writeln('WARNING: TDesigner.ValidateRename: OldComponentName="',CurName,'"');
  if Assigned(OnRenameComponent) then
    OnRenameComponent(Self,AComponent,NewName);
end;

function TDesigner.GetIsControl: Boolean;
Begin
  Result := True;
end;

procedure TDesigner.SetIsControl(Value: Boolean);
Begin

end;

procedure TDesigner.DrawNonVisualComponents(DC: HDC);
var i, j, ItemLeft, ItemTop, ItemRight, ItemBottom: integer;
  FormOrigin, DCOrigin, Diff: TPoint;
  SaveIndex: HDC;
  IconRect: TRect;
  IconCanvas: TCanvas;
begin
  GetWindowOrgEx(DC, DCOrigin);
  FormOrigin:=FCustomForm.ClientOrigin;
  Diff.X:=FormOrigin.X-DCOrigin.X;
  Diff.Y:=FormOrigin.Y-DCOrigin.Y;
  SaveIndex:=SaveDC(DC);
  FCustomForm.Canvas.Handle:=DC;
  for i:=0 to FCustomForm.ComponentCount-1 do begin
    if not (FCustomForm.Components[i] is TControl) then begin
      // non-visual component
      ItemLeft:=LongRec(FCustomForm.Components[i].DesignInfo).Lo+Diff.X;
      ItemTop:=LongRec(FCustomForm.Components[i].DesignInfo).Hi+Diff.Y;
      ItemRight:=ItemLeft+NonVisualCompWidth;
      ItemBottom:=ItemTop+NonVisualCompWidth;
      with FCustomForm.Canvas do begin
        Brush.Color:=clWhite;
        for j:=0 to NonVisualCompBorder-1 do begin
          MoveTo(ItemLeft+j,ItemBottom-j);
          LineTo(ItemLeft+j,ItemTop+j);
          LineTo(ItemRight-j,ItemTop+j);
        end;
        Brush.Color:=clBlack;
        for j:=0 to NonVisualCompBorder-1 do begin
          MoveTo(ItemLeft+j,ItemBottom-j);
          LineTo(ItemRight-j,ItemBottom-j);
          MoveTo(ItemRight-j,ItemTop+j);
          LineTo(ItemRight-j,ItemBottom-j+1);
        end;
        IconRect:=Rect(ItemLeft+NonVisualCompBorder,ItemTop+NonVisualCompBorder,
             ItemRight-NonVisualCompBorder,ItemBottom-NonVisualCompBorder);
        Brush.Color:=clBtnFace;
        FillRect(Rect(IconRect.Left,IconRect.Top,
           IconRect.Right+1,IconRect.Bottom+1));
      end;
      if Assigned(FOnGetNonVisualCompIconCanvas) then begin
        IconCanvas:=nil;
        FOnGetNonVisualCompIconCanvas(Self,FCustomForm.Components[i]
             ,IconCanvas);
        if IconCanvas<>nil then
          FCustomForm.Canvas.CopyRect(IconRect, IconCanvas,
             Rect(0,0,NonVisualCompIconWidth,NonVisualCompIconWidth));
      end;
      if (ControlSelection.Count>1)
      and (ControlSelection.IsSelected(FCustomForm.Components[i])) then
        ControlSelection.DrawMarkerAt(FCustomForm.Canvas,
          ItemLeft,ItemTop,NonVisualCompWidth,NonVisualCompWidth);
    end;
  end;
  FCustomForm.Canvas.Handle:=0;
  RestoreDC(DC,SaveIndex);
end;

function TDesigner.NonVisualComponentAtPos(x,y: integer): TComponent;
var i, ALeft, ATop: integer;
begin
  for i:=FCustomForm.ComponentCount-1 downto 0 do begin
    Result:=FCustomForm.Components[i];
    if (Result is TControl)=false then begin
      with Result do begin
        ALeft:=LongRec(DesignInfo).Lo;
        ATop:=LongRec(DesignInfo).Hi;
        if (ALeft<=x) and (ATop<=y)
        and (ALeft+NonVisualCompWidth>x)
        and (ATop+NonVisualCompWidth>y) then
          exit;
      end;
    end;
  end;
  Result:=nil;
end;

procedure TDesigner.BuildPopupMenu;
var
  ControlSelIsNotEmpty, FormIsSelected, OnlyNonVisualCompsAreSelected,
  CompsAreSelected: boolean;
begin
  if FPopupMenu<>nil then FPopupMenu.Free;

  ControlSelIsNotEmpty:=ControlSelection.Count>0;
  FormIsSelected:=ControlSelIsNotEmpty 
    and (ControlSelection[0].Component is TCustomForm);
  OnlyNonVisualCompsAreSelected:=
    ControlSelection.OnlyNonVisualComponentsSelected;
  CompsAreSelected:=ControlSelIsNotEmpty and not FormIsSelected;

  FPopupMenu:=TPopupMenu.Create(nil);

  FAlignMenuItem := TMenuItem.Create(nil);
  with FAlignMenuItem do begin
    Caption := 'Align';
    OnClick := @OnAlignPopupMenuClick;
    Enabled := CompsAreSelected;
  end;
  FPopupMenu.Items.Add(FAlignMenuItem);

  FMirrorHorizontalMenuItem := TMenuItem.Create(nil);
  with FMirrorHorizontalMenuItem do begin
    Caption := 'Mirror horizontal';
    OnClick := @OnMirrorHorizontalPopupMenuClick;
    Enabled := CompsAreSelected;
  end;
  FPopupMenu.Items.Add(FMirrorHorizontalMenuItem);

  FMirrorVerticalMenuItem := TMenuItem.Create(nil);
  with FMirrorVerticalMenuItem do begin
    Caption := 'Mirror vertical';
    OnClick := @OnMirrorVerticalPopupMenuClick;
    Enabled := CompsAreSelected;
  end;
  FPopupMenu.Items.Add(FMirrorVerticalMenuItem);

  FScaleMenuItem := TMenuItem.Create(nil);
  with FScaleMenuItem do begin
    Caption := 'Scale';
    OnClick := @OnScalePopupMenuClick;
    Enabled := CompsAreSelected and OnlyNonVisualCompsAreSelected;
  end;
  FPopupMenu.Items.Add(FScaleMenuItem);

  FSizeMenuItem := TMenuItem.Create(nil);
  with FSizeMenuItem do begin
    Caption := 'Size';
    OnClick := @OnSizePopupMenuClick;
    Enabled := CompsAreSelected and OnlyNonVisualCompsAreSelected;
  end;
  FPopupMenu.Items.Add(FSizeMenuItem);
  
  FBringToFrontMenuItem := TMenuItem.Create(nil);
  with FBringToFrontMenuItem do begin
    Caption:= 'Bring to front';
    OnClick:= @OnBringToFrontMenuClick;
    Enabled:= CompsAreSelected;
  end;
  FPopupMenu.Items.Add(FBringToFrontMenuItem);
  
  FSendToBackMenuItem:= TMenuItem.Create(nil);
  with FSendToBackMenuItem do begin
    Caption:= 'Send to back';
    OnClick:= @OnSendToBackMenuClick;
    Enabled:= CompsAreSelected;
  end;
  FPopupMenu.Items.Add(FSendToBackMenuItem);
  
end;

procedure TDesigner.OnAlignPopupMenuClick(Sender: TObject);
var HorizAlignment, VertAlignment: TComponentAlignment;
begin
  if ShowAlignComponentsDialog=mrOk then begin
    case AlignComponentsDialog.HorizontalRadioGroup.ItemIndex of
     0: HorizAlignment:=csaNone;
     1: HorizAlignment:=csaSides1;
     2: HorizAlignment:=csaCenters;
     3: HorizAlignment:=csaSides2;
     4: HorizAlignment:=csaCenterInWindow;
     5: HorizAlignment:=csaSpaceEqually;
     6: HorizAlignment:=csaSide1SpaceEqually;
     7: HorizAlignment:=csaSide2SpaceEqually;
    end;
    case AlignComponentsDialog.VerticalRadioGroup.ItemIndex of
     0: VertAlignment:=csaNone;
     1: VertAlignment:=csaSides1;
     2: VertAlignment:=csaCenters;
     3: VertAlignment:=csaSides2;
     4: VertAlignment:=csaCenterInWindow;
     5: VertAlignment:=csaSpaceEqually;
     6: VertAlignment:=csaSide1SpaceEqually;
     7: VertAlignment:=csaSide2SpaceEqually;
    end;
    ControlSelection.AlignComponents(HorizAlignment,VertAlignment);
  end;
  ControlSelection.SaveBounds;
end;

procedure TDesigner.OnMirrorHorizontalPopupMenuClick(Sender: TObject);
begin
  ControlSelection.MirrorHorizontal;
  ControlSelection.SaveBounds;
end;

procedure TDesigner.OnMirrorVerticalPopupMenuClick(Sender: TObject);
begin
  ControlSelection.MirrorVertical;
  ControlSelection.SaveBounds;
end;

procedure TDesigner.OnScalePopupMenuClick(Sender: TObject);
begin
  if ShowScaleComponentsDialog=mrOk then begin
    ControlSelection.ScaleComponents(
      StrToIntDef(ScaleComponentsDialog.PercentEdit.Text,100));
  end;
  ControlSelection.SaveBounds;
end;

procedure TDesigner.OnSizePopupMenuClick(Sender: TObject);
var HorizSizing, VertSizing: TComponentSizing;
  AWidth, AHeight: integer;
begin
  if ShowSizeComponentsDialog=mrOk then begin
    case SizeComponentsDialog.WidthRadioGroup.ItemIndex of
     0: HorizSizing:=cssNone;
     1: HorizSizing:=cssShrinkToSmallest;
     2: HorizSizing:=cssGrowToLargest;
     3: HorizSizing:=cssFixed;
    end;
    case SizeComponentsDialog.HeightRadioGroup.ItemIndex of
     0: VertSizing:=cssNone;
     1: VertSizing:=cssShrinkToSmallest;
     2: VertSizing:=cssGrowToLargest;
     3: VertSizing:=cssFixed;
    end;
    if HorizSizing=cssFixed then
      AWidth:=StrToIntDef(SizeComponentsDialog.WidthEdit.Text,0)
    else
      AWidth:=0;
    if VertSizing=cssFixed then
      AHeight:=StrToIntDef(SizeComponentsDialog.HeightEdit.Text,0)
    else
      AHeight:=0;
    ControlSelection.SizeComponents(HorizSizing,AWidth,VertSizing,AHeight);
  end;
  ControlSelection.SaveBounds;
end;

procedure TDesigner.OnBringToFrontMenuClick(Sender: TObject);
var AComponent : TComponent;
begin
  if ControlSelection.Count = 1 then begin
    AComponent:= ControlSelection.Items[0].Component;
    if AComponent is TControl then TControl(AComponent).BringToFront;
  end;    
end;

procedure TDesigner.OnSendToBackMenuClick(Sender: TObject);
var AComponent : TComponent;
begin
  if ControlSelection.Count = 1 then begin
    AComponent:= ControlSelection.Items[0].Component;
    if AComponent is TControl then TControl(AComponent).SendToBack;
  end;
end;

Procedure TDesigner.HintTimer(sender : TObject);
var
  Rect : TRect;
  AHint : String;
  Control : TControl;
  Position : TPoint;
  BW       : Integer;
  Window : TWInControl;
begin
  FHintTimer.Enabled := False;
  if not FShowHints then exit;

  Position := Mouse.CursorPos;
  Window := FindLCLWindow(Position);
  if not(Assigned(window)) then Exit;

  //get the parent until parent is nil
  While Window.Parent <> nil do
  Window := Window.Parent;

  if (window <> FCustomForm) then Exit;

  BW := 0;
  if (FCustomForm is TForm) then
     BW := TForm(FCustomForm).BorderWidth;

  if ((Position.X < (FCustomForm.LEft +BW)) or (Position.X > (FCustomForm.Left+FCustomForm.Width - BW)) or (Position.Y < FCustomForm.Top+22) or (Position.Y > (FCustomForm.Top+FCustomForm.Height - BW))) then Exit;

  Position := FCustomForm.ScreenToClient(Position);

  Control := FCustomForm.ControlAtPos(Position,True);
  if not Assigned(Control) then
     Control := FCustomForm;
  AHint := Control.Name + ' : '+Control.ClassName;
  AHint := AHint + #10+'Left : '+Inttostr(Control.Left)+ '  Top : '+Inttostr(Control.Top)+
                   #10+'Width : '+Inttostr(Control.Width)+ '  Height : '+Inttostr(Control.Height);

  Rect := FHintWindow.CalcHintRect(0,AHint,nil);  //no maxwidth
  Rect.Left := Mouse.CursorPos.X+10;
  Rect.Top := Mouse.CursorPos.Y+5;
  Rect.Right := Rect.Left + Rect.Right;
  Rect.Bottom := Rect.Top + Rect.Bottom;

  FHintWindow.ActivateHint(Rect,AHint);
end;

Procedure TDesigner.OnFormActivated;
begin
  //the form was activated.
  if Assigned(FOnActivated) then
     FOnActivated(Form);
end;


initialization
  GridSizex := 10;
  GridSizeY := 10;

end.

