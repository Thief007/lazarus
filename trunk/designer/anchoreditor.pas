{ /***************************************************************************
                 AnchorEditor.pas - Lazarus IDE unit
                 -----------------------------------

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

  Author: Mattias Gaertner

  Abstract:
    Editor for editing Anchors, AnchorSide properties.
}
unit AnchorEditor;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LCLProc, LResources, Forms, Controls, Graphics, Dialogs,
  StdCtrls, Buttons, Spin,
  IDECommands, PropEdits,
  LazarusIDEStrConsts, EnvironmentOpts, IDEOptionDefs;

type

  { TAnchorDesignerSideValues }

  TAnchorDesignerSideValues = class
  private
    FAmbigiousBorderSpace: boolean;
    FAmbigiousEnabled: boolean;
    FAmbigiousSide: boolean;
    FAmbigiousSibling: boolean;
    FAnchorKind: TAnchorKind;
    FBorderSpace: integer;
    FEnabled: boolean;
    FSibling: string;
    FSide: TAnchorSideReference;
  public
    constructor Create(TheKind: TAnchorKind);
    procedure SetValues(AControl: TControl);
    procedure MergeValues(AControl: TControl);
  public
    property AnchorKind: TAnchorKind read FAnchorKind;
    property Enabled: boolean read FEnabled write FEnabled;
    property AmbigiousEnabled: boolean read FAmbigiousEnabled write FAmbigiousEnabled;
    property Sibling: string read FSibling write FSibling;
    property AmbigiousSibling: boolean read FAmbigiousSibling write FAmbigiousSibling;
    property Side: TAnchorSideReference read FSide write FSide;
    property AmbigiousSide: boolean read FAmbigiousSide write FAmbigiousSide;
    property BorderSpace: integer read FBorderSpace write FBorderSpace;
    property AmbigiousBorderSpace: boolean read FAmbigiousBorderSpace write FAmbigiousBorderSpace;
  end;
  

  { TAnchorDesignerValues }

  TAnchorDesignerValues = class
  private
    FAmbigiousBorderspaceAround: boolean;
    FBorderspaceAround: integer;
    FSides: array[TAnchorKind] of TAnchorDesignerSideValues;
    function GetSides(Kind: TAnchorKind): TAnchorDesignerSideValues;
    procedure SetAmbigiousBorderspaceAround(const AValue: boolean);
    procedure SetBorderspaceAround(const AValue: integer);
  public
    constructor Create;
    destructor Destroy; override;
    procedure SetValues(AControl: TControl);
    procedure MergeValues(AControl: TControl);
  public
    property Sides[Kind: TAnchorKind]: TAnchorDesignerSideValues read GetSides;
    property BorderspaceAround: integer read FBorderspaceAround write SetBorderspaceAround;
    property AmbigiousBorderspaceAround: boolean read FAmbigiousBorderspaceAround write SetAmbigiousBorderspaceAround;
  end;
  

  { TAnchorDesigner }

  TAnchorDesigner = class(TForm)
    AroundBorderSpaceSpinEdit: TSpinEdit;
    BorderSpaceGroupBox: TGroupBox;
    BottomAnchoredCheckBox: TCheckBox;
    BottomBorderSpaceSpinEdit: TSpinEdit;
    BottomGroupBox: TGroupBox;
    BottomRefBottomSpeedButton: TSpeedButton;
    BottomRefCenterSpeedButton: TSpeedButton;
    BottomRefTopSpeedButton: TSpeedButton;
    BottomSiblingComboBox: TComboBox;
    BottomSiblingLabel: TLabel;
    LeftAnchoredCheckBox: TCheckBox;
    LeftBorderSpaceSpinEdit: TSpinEdit;
    LeftGroupBox: TGroupBox;
    LeftRefCenterSpeedButton: TSpeedButton;
    LeftRefLeftSpeedButton: TSpeedButton;
    LeftRefRightSpeedButton: TSpeedButton;
    LeftSiblingComboBox: TComboBox;
    LeftSiblingLabel: TLabel;
    RightAnchoredCheckBox: TCheckBox;
    RightBorderSpaceSpinEdit: TSpinEdit;
    RightGroupBox: TGroupBox;
    RightRefCenterSpeedButton: TSpeedButton;
    RightRefLeftSpeedButton: TSpeedButton;
    RightRefRightSpeedButton: TSpeedButton;
    RightSiblingComboBox: TComboBox;
    RightSiblingLabel: TLabel;
    TopAnchoredCheckBox: TCheckBox;
    TopBorderSpaceSpinEdit: TSpinEdit;
    TopGroupBox: TGroupBox;
    TopRefBottomSpeedButton: TSpeedButton;
    TopRefCenterSpeedButton: TSpeedButton;
    TopRefTopSpeedButton: TSpeedButton;
    TopSiblingComboBox: TComboBox;
    TopSiblingLabel: TLabel;
    procedure AnchorDesignerClose(Sender: TObject; var CloseAction: TCloseAction
      );
    procedure AnchorDesignerCreate(Sender: TObject);
    procedure AnchorDesignerDestroy(Sender: TObject);
    procedure AnchorDesignerShow(Sender: TObject);
    procedure AnchorEnabledCheckBoxChange(Sender: TObject);
    procedure BorderSpaceSpinEditChange(Sender: TObject);
    procedure SiblingComboBoxChange(Sender: TObject);
    procedure ReferenceSideButtonClicked(Sender: TObject);
  private
    FSelection: TPersistentSelectionList;
    FUpdating: Boolean;
  protected
    procedure KeyUp(var Key: Word; Shift: TShiftState); override;
    procedure FillComboBoxWithSiblings(AComboBox: TComboBox);
    function AnchorDesignerNoSiblingText: string;
  public
    Values: TAnchorDesignerValues;
    procedure Refresh(Force: boolean);
    procedure OnRefreshPropertyValues;
    function GetSelectedControls: TList;
    function FindSibling(const Sibling: string): TControl;
    class function ControlToStr(AControl: TControl): string;
    procedure CollectValues(const ASelection: TList;
                            var TheValues: TAnchorDesignerValues;
                            var SelectedControlCount: integer);
    procedure OnSetSelection(const ASelection: TPersistentSelectionList);
    property Selection: TPersistentSelectionList read FSelection;
  end;
  
var
  AnchorDesigner: TAnchorDesigner;

implementation

{ TAnchorDesigner }

procedure TAnchorDesigner.AnchorDesignerCreate(Sender: TObject);
var
  AnchorEnabledHint: String;
begin
  Name:=NonModalIDEWindowNames[nmiwAnchorEditor];
  EnvironmentOptions.IDEWindowLayoutList.Apply(Self,Name);
  KeyPreview:=true;
  FSelection:=TPersistentSelectionList.Create;

  AnchorEnabledHint:='Enabled = Include %s in Anchors';

  AroundBorderSpaceSpinEdit.Hint:='Borderspace around the control. The other four borderspaces are added to this value.';
  BorderSpaceGroupBox.Caption:='BorderSpace';
  BottomAnchoredCheckBox.Caption:='Enabled';
  BottomAnchoredCheckBox.Hint:=Format(AnchorEnabledHint,['akBottom']);
  BottomBorderSpaceSpinEdit.Hint:='Bottom borderspace. This value is added to base borderspace and used for the space below the control.';
  BottomGroupBox.Caption:='Bottom anchoring';
  BottomRefBottomSpeedButton.Hint:='Anchor to bottom side of sibling, keep border space';
  BottomRefCenterSpeedButton.Hint:='Center control vertically relative to the given sibling';
  BottomRefTopSpeedButton.Hint:='Anchor to top side of sibling, keep border space';
  BottomSiblingComboBox.Hint:='This is the sibling control to which the bottom side is anchored. Leave empty for parent.';
  BottomSiblingLabel.Caption:='Sibling';
  LeftAnchoredCheckBox.Caption:='Enabled';
  LeftAnchoredCheckBox.Hint:=Format(AnchorEnabledHint,['akLeft']);
  LeftBorderSpaceSpinEdit.Hint:='Left borderspace. This value is added to base borderspace and used for the space left to the control.';
  LeftGroupBox.Caption:='Left anchoring';
  LeftRefCenterSpeedButton.Hint:='Center control horizontally relative to the given sibling';
  LeftRefLeftSpeedButton.Hint:='Anchor to left side of sibling, keep border space';
  LeftRefRightSpeedButton.Hint:='Anchor to right side of sibling, keep border space';
  LeftSiblingComboBox.Hint:='This is the sibling control to which the left side is anchored. Leave empty for parent.';
  LeftSiblingLabel.Caption:='Sibling';
  RightAnchoredCheckBox.Caption:='Enabled';
  RightAnchoredCheckBox.Hint:=Format(AnchorEnabledHint,['akRight']);
  RightBorderSpaceSpinEdit.Hint:='Right borderspace. This value is added to base borderspace and used for the space right to the control.';
  RightGroupBox.Caption:='Right anchoring';
  RightRefCenterSpeedButton.Hint:='Center control horizontally relative to the given sibling';
  RightRefLeftSpeedButton.Hint:='Anchor to left side of sibling, keep border space';
  RightRefRightSpeedButton.Hint:='Anchor to right side of sibling, keep border space';
  RightSiblingComboBox.Hint:='This is the sibling control to which the right side is anchored. Leave empty for parent.';
  RightSiblingLabel.Caption:='Sibling';
  TopAnchoredCheckBox.Caption:='Enabled';
  TopAnchoredCheckBox.Hint:=Format(AnchorEnabledHint,['akTop']);
  TopBorderSpaceSpinEdit.Hint:='Top borderspace. This value is added to base borderspace and used for the space above the control.';
  TopGroupBox.Caption:='Top anchoring';
  TopRefBottomSpeedButton.Hint:='Anchor to bottom side of sibling, keep border space';
  TopRefCenterSpeedButton.Hint:='Center control vertically relative to the given sibling';
  TopRefTopSpeedButton.Hint:='Anchor to top side of sibling, keep border space';
  TopSiblingComboBox.Hint:='This is the sibling control to which the top side is anchored. Leave empty for parent.';
  TopSiblingLabel.Caption:='Sibling';

  LeftRefLeftSpeedButton.Glyph.LoadFromLazarusResource('anchorleftleft');
  LeftRefCenterSpeedButton.Glyph.LoadFromLazarusResource('anchorcenterhorizontal');
  LeftRefRightSpeedButton.Glyph.LoadFromLazarusResource('anchorleftright');
  RightRefLeftSpeedButton.Glyph.LoadFromLazarusResource('anchorleftright');
  RightRefCenterSpeedButton.Glyph.LoadFromLazarusResource('anchorcenterhorizontal');
  RightRefRightSpeedButton.Glyph.LoadFromLazarusResource('anchorrightright');
  TopRefTopSpeedButton.Glyph.LoadFromLazarusResource('anchortoptop');
  TopRefCenterSpeedButton.Glyph.LoadFromLazarusResource('anchorcentervertical');
  TopRefBottomSpeedButton.Glyph.LoadFromLazarusResource('anchortopbottom');
  BottomRefTopSpeedButton.Glyph.LoadFromLazarusResource('anchortopbottom');
  BottomRefCenterSpeedButton.Glyph.LoadFromLazarusResource('anchorcentervertical');
  BottomRefBottomSpeedButton.Glyph.LoadFromLazarusResource('anchorbottombottom');

  // autosizing
  BottomSiblingLabel.AnchorToNeighbour(akLeft,10,BottomAnchoredCheckBox);
  BottomSiblingComboBox.AnchorToNeighbour(akLeft,5,BottomSiblingLabel);
  BottomSiblingLabel.AnchorVerticalCenterTo(BottomSiblingComboBox);
  BottomAnchoredCheckBox.AnchorVerticalCenterTo(BottomSiblingComboBox);
  TopSiblingLabel.AnchorToNeighbour(akLeft,10,TopAnchoredCheckBox);
  TopSiblingComboBox.AnchorToNeighbour(akLeft,5,TopSiblingLabel);
  TopSiblingLabel.AnchorVerticalCenterTo(TopSiblingComboBox);
  TopAnchoredCheckBox.AnchorVerticalCenterTo(TopSiblingComboBox);

  GlobalDesignHook.AddHandlerRefreshPropertyValues(@OnRefreshPropertyValues);
  GlobalDesignHook.AddHandlerSetSelection(@OnSetSelection);
end;

procedure TAnchorDesigner.AnchorDesignerDestroy(Sender: TObject);
begin
  FreeAndNil(Values);
  GlobalDesignHook.RemoveAllHandlersForObject(Self);
  FreeAndNil(FSelection);
end;

procedure TAnchorDesigner.AnchorDesignerShow(Sender: TObject);
begin
  Refresh(true);
end;

procedure TAnchorDesigner.AnchorEnabledCheckBoxChange(Sender: TObject);
var
  Kind: TAnchorKind;
  CurSide: TAnchorDesignerSideValues;
  NewValue: Boolean;
  SelectedControls: TList;
  i: Integer;
  CurControl: TControl;
begin
  debugln('TAnchorDesigner.AnchorEnabledCheckBoxChange ',DbgSName(Sender),' ',dbgs(TCheckBox(Sender).Checked));
  if FUpdating or (Values=nil) then exit;
  if Sender=LeftAnchoredCheckBox then
    Kind:=akLeft
  else if Sender=RightAnchoredCheckBox then
    Kind:=akRight
  else if Sender=TopAnchoredCheckBox then
    Kind:=akTop
  else if Sender=BottomAnchoredCheckBox then
    Kind:=akBottom
  else
    exit;
  NewValue:=TCheckBox(Sender).Checked;
  CurSide:=Values.Sides[Kind];
  debugln('TAnchorDesigner.AnchorEnabledCheckBoxChange CurSide.AmbigiousEnabled=',dbgs(CurSide.AmbigiousEnabled),' CurSide.Enabled=',dbgs(CurSide.Enabled),' NewValue=',dbgs(NewValue));
  if CurSide.AmbigiousEnabled or (CurSide.Enabled<>NewValue) then begin
    debugln('TAnchorDesigner.AnchorEnabledCheckBoxChange ',DbgSName(Sender),' NewValue=',dbgs(NewValue));
    // user changed an anchor
    SelectedControls:=GetSelectedControls;
    if SelectedControls=nil then exit;
    for i:=0 to SelectedControls.Count-1 do begin
      CurControl:=TControl(SelectedControls[i]);
      if NewValue then
        CurControl.Anchors:=CurControl.Anchors+[Kind]
      else
        CurControl.Anchors:=CurControl.Anchors-[Kind];
    end;
    GlobalDesignHook.RefreshPropertyValues;
  end;
end;

procedure TAnchorDesigner.BorderSpaceSpinEditChange(Sender: TObject);
var
  Around: Boolean;
  NewValue: LongInt;
  CurSide: TAnchorDesignerSideValues;
  SelectedControls: TList;
  i: Integer;
  CurControl: TControl;
  Kind: TAnchorKind;
begin
  debugln('TAnchorDesigner.BorderSpaceSpinEditChange ',DbgSName(Sender),' ',dbgs(TSpinEdit(Sender).Value));
  if FUpdating or (Values=nil) then exit;
  Around:=false;
  if Sender=LeftBorderSpaceSpinEdit then
    Kind:=akLeft
  else if Sender=RightBorderSpaceSpinEdit then
    Kind:=akRight
  else if Sender=TopBorderSpaceSpinEdit then
    Kind:=akTop
  else if Sender=BottomBorderSpaceSpinEdit then
    Kind:=akBottom
  else if Sender=AroundBorderSpaceSpinEdit then begin
    Kind:=akLeft;
    Around:=true;
  end else
    exit;
  NewValue:=RoundToInt(TSpinEdit(Sender).Value);
  CurSide:=Values.Sides[Kind];
  if (Around and (Values.AmbigiousBorderspaceAround
                  or (Values.BorderspaceAround<>NewValue)))
  or ((not Around) and (CurSide.AmbigiousBorderSpace
                        or (CurSide.BorderSpace<>NewValue)))
  then begin
    debugln('TAnchorDesigner.BorderSpaceSpinEditChange ',DbgSName(Sender),' NewValue=',dbgs(NewValue));
    // user changed a BorderSpace
    SelectedControls:=GetSelectedControls;
    if SelectedControls=nil then exit;
    for i:=0 to SelectedControls.Count-1 do begin
      CurControl:=TControl(SelectedControls[i]);
      if Around then
        CurControl.BorderSpacing.Around:=NewValue
      else
        CurControl.BorderSpacing.Space[Kind]:=NewValue;
    end;
    GlobalDesignHook.RefreshPropertyValues;
  end;
end;

procedure TAnchorDesigner.SiblingComboBoxChange(Sender: TObject);
var
  Kind: TAnchorKind;
  NewSibling: TControl;
  CurSide: TAnchorDesignerSideValues;
  SelectedControls: TList;
  i: Integer;
  CurControl: TControl;
  NewValue: String;
begin
  debugln('TAnchorDesigner.SiblingComboBoxChange ',DbgSName(Sender),' ',TComboBox(Sender).Text);
  if FUpdating or (Values=nil) then exit;
  if Sender=LeftSiblingComboBox then
    Kind:=akLeft
  else if Sender=RightSiblingComboBox then
    Kind:=akRight
  else if Sender=TopSiblingComboBox then
    Kind:=akTop
  else if Sender=BottomSiblingComboBox then
    Kind:=akBottom
  else
    exit;
  NewValue:=TComboBox(Sender).Caption;
  CurSide:=Values.Sides[Kind];
  if CurSide.AmbigiousSibling or (CompareText(CurSide.Sibling,NewValue)<>0) then
  begin
    NewSibling:=FindSibling(NewValue);
    if NewSibling=nil then exit;
    debugln('TAnchorDesigner.SiblingComboBoxChange ',DbgSName(Sender),' NewSibling=',DbgSName(NewSibling));
    // user changed a sibling
    SelectedControls:=GetSelectedControls;
    if SelectedControls=nil then exit;
    for i:=0 to SelectedControls.Count-1 do begin
      CurControl:=TControl(SelectedControls[i]);
      CurControl.AnchorSide[Kind].Control:=NewSibling;
    end;
    GlobalDesignHook.RefreshPropertyValues;
  end;
end;

procedure TAnchorDesigner.ReferenceSideButtonClicked(Sender: TObject);
var
  CurSide: TAnchorDesignerSideValues;
  Kind: TAnchorKind;
  Side: TAnchorSideReference;
  SelectedControls: TList;
  i: Integer;
  CurControl: TControl;
begin
  debugln('TAnchorDesigner.ReferenceSideButtonClicked ',DbgSName(Sender),' ',dbgs(TSpeedButton(Sender).Down));
  if FUpdating or (Values=nil) then exit;
  if Sender=LeftRefCenterSpeedButton then begin
    Kind:=akLeft;
    Side:=asrCenter;
  end
  else if Sender=LeftRefLeftSpeedButton then begin
    Kind:=akLeft;
    Side:=asrLeft;
  end
  else if Sender=LeftRefRightSpeedButton then begin
    Kind:=akLeft;
    Side:=asrRight;
  end
  else if Sender=RightRefCenterSpeedButton then begin
    Kind:=akRight;
    Side:=asrCenter;
  end
  else if Sender=RightRefLeftSpeedButton then begin
    Kind:=akRight;
    Side:=asrLeft;
  end
  else if Sender=RightRefRightSpeedButton then begin
    Kind:=akRight;
    Side:=asrRight;
  end
  else if Sender=TopRefCenterSpeedButton then begin
    Kind:=akTop;
    Side:=asrCenter;
  end
  else if Sender=TopRefTopSpeedButton then begin
    Kind:=akTop;
    Side:=asrTop;
  end
  else if Sender=TopRefBottomSpeedButton then begin
    Kind:=akTop;
    Side:=asrBottom;
  end
  else if Sender=BottomRefCenterSpeedButton then begin
    Kind:=akBottom;
    Side:=asrCenter;
  end
  else if Sender=BottomRefTopSpeedButton then begin
    Kind:=akBottom;
    Side:=asrTop;
  end
  else if Sender=BottomRefBottomSpeedButton then begin
    Kind:=akBottom;
    Side:=asrBottom;
  end else
    exit;
  if not TSpeedButton(Sender).Down then exit;
  CurSide:=Values.Sides[Kind];
  if CurSide.AmbigiousSide or (CurSide.Side<>Side) then
  begin
    debugln('TAnchorDesigner.ReferenceSideButtonClicked ',DbgSName(Sender));
    // user changed a sibling
    SelectedControls:=GetSelectedControls;
    if SelectedControls=nil then exit;
    for i:=0 to SelectedControls.Count-1 do begin
      CurControl:=TControl(SelectedControls[i]);
      CurControl.AnchorSide[Kind].Side:=Side;
    end;
    GlobalDesignHook.RefreshPropertyValues;
  end;
end;

procedure TAnchorDesigner.KeyUp(var Key: Word; Shift: TShiftState);
begin
  inherited KeyUp(Key, Shift);
  ExecuteIDECommand(Self,Key,Shift,caMenuOnly);
end;

procedure TAnchorDesigner.FillComboBoxWithSiblings(AComboBox: TComboBox);
var
  sl: TStringList;
  i: Integer;
  CurControl: TControl;
  j: Integer;
  Sibling: TControl;
  SelectedControls: TList;
begin
  sl:=TStringList.Create;
  sl.Add(AnchorDesignerNoSiblingText);
  SelectedControls:=GetSelectedControls;
  if SelectedControls<>nil then begin
    for i:=0 to SelectedControls.Count-1 do begin
      if TObject(SelectedControls[i]) is TControl then begin
        CurControl:=TControl(SelectedControls[i]);
        if CurControl.Parent<>nil then begin
          for j:=0 to CurControl.Parent.ControlCount-1 do begin
            Sibling:=CurControl.Parent.Controls[j];
            if Sibling<>CurControl then
              sl.Add(ControlToStr(Sibling));
          end;
        end;
        break;
      end;
    end;
  end;
  AComboBox.Items.Assign(sl);
  sl.Free;
end;

function TAnchorDesigner.AnchorDesignerNoSiblingText: string;
begin
  Result:='(parent borders)';
end;

procedure TAnchorDesigner.Refresh(Force: boolean);
var
  SelectedControlCount: Integer;
  CurSide: TAnchorDesignerSideValues;
  Sibling: String;
  CurSelection: TList;
begin
  //debugln('TAnchorDesigner.Refresh A ');
  if not Force then begin
    // check if uddate is needed
    if not Visible then exit;
  end;
  if FUpdating then exit;
  FUpdating:=true;
  try
    FreeAndNil(Values);
    CurSelection:=GetSelectedControls;
    CollectValues(CurSelection,Values,SelectedControlCount);
    //debugln('TAnchorDesigner.Refresh B ',dbgs(SelectedControlCount));

    if (Values=nil) then begin
      Caption:='Anchor Editor - no control selected';
      BorderSpaceGroupBox.Enabled:=false;
      TopGroupBox.Enabled:=false;
      LeftGroupBox.Enabled:=false;
      RightGroupBox.Enabled:=false;
      BottomGroupBox.Enabled:=false;
    end else begin
      Caption:='Anchors of selected controls';

      // all
      BorderSpaceGroupBox.Enabled:=true;
      if Values.AmbigiousBorderspaceAround then
        AroundBorderSpaceSpinEdit.Value:=-1
      else
        AroundBorderSpaceSpinEdit.Value:=Values.BorderspaceAround;

      // Top
      TopGroupBox.Enabled:=true;
      CurSide:=Values.Sides[akTop];
      TopAnchoredCheckBox.AllowGrayed:=CurSide.AmbigiousEnabled;
      if CurSide.AmbigiousEnabled then
        TopAnchoredCheckBox.State:=cbGrayed
      else
        TopAnchoredCheckBox.Checked:=CurSide.Enabled;
      if CurSide.AmbigiousBorderSpace then
        TopBorderSpaceSpinEdit.Value:=-1
      else
        TopBorderSpaceSpinEdit.Value:=CurSide.BorderSpace;
      TopBorderSpaceSpinEdit.ValueEmpty:=CurSide.AmbigiousBorderSpace;
      Sibling:=CurSide.Sibling;
      TopSiblingComboBox.Text:=Sibling;
      FillComboBoxWithSiblings(TopSiblingComboBox);
      TopRefBottomSpeedButton.Enabled:=Sibling<>'';
      TopRefBottomSpeedButton.Down:=(CurSide.Side=asrBottom);
      TopRefCenterSpeedButton.Enabled:=Sibling<>'';
      TopRefCenterSpeedButton.Down:=(CurSide.Side=asrCenter);
      TopRefTopSpeedButton.Enabled:=Sibling<>'';
      TopRefTopSpeedButton.Down:=(CurSide.Side=asrTop);

      // Bottom
      BottomGroupBox.Enabled:=true;
      CurSide:=Values.Sides[akBottom];
      BottomAnchoredCheckBox.AllowGrayed:=CurSide.AmbigiousEnabled;
      if CurSide.AmbigiousEnabled then
        BottomAnchoredCheckBox.State:=cbGrayed
      else
        BottomAnchoredCheckBox.Checked:=CurSide.Enabled;
      if CurSide.AmbigiousBorderSpace then
        BottomBorderSpaceSpinEdit.Value:=-1
      else
        BottomBorderSpaceSpinEdit.Value:=CurSide.BorderSpace;
      BottomBorderSpaceSpinEdit.ValueEmpty:=CurSide.AmbigiousBorderSpace;
      Sibling:=CurSide.Sibling;
      BottomSiblingComboBox.Text:=Sibling;
      FillComboBoxWithSiblings(BottomSiblingComboBox);
      BottomRefBottomSpeedButton.Enabled:=Sibling<>'';
      BottomRefBottomSpeedButton.Down:=(CurSide.Side=asrBottom);
      BottomRefCenterSpeedButton.Enabled:=Sibling<>'';
      BottomRefCenterSpeedButton.Down:=(CurSide.Side=asrCenter);
      BottomRefTopSpeedButton.Enabled:=Sibling<>'';
      BottomRefTopSpeedButton.Down:=(CurSide.Side=asrTop);

      // Left
      LeftGroupBox.Enabled:=true;
      CurSide:=Values.Sides[akLeft];
      LeftAnchoredCheckBox.AllowGrayed:=CurSide.AmbigiousEnabled;
      if CurSide.AmbigiousEnabled then
        LeftAnchoredCheckBox.State:=cbGrayed
      else
        LeftAnchoredCheckBox.Checked:=CurSide.Enabled;
      if CurSide.AmbigiousBorderSpace then
        LeftBorderSpaceSpinEdit.Value:=-1
      else
        LeftBorderSpaceSpinEdit.Value:=CurSide.BorderSpace;
      LeftBorderSpaceSpinEdit.ValueEmpty:=CurSide.AmbigiousBorderSpace;
      Sibling:=CurSide.Sibling;
      LeftSiblingComboBox.Text:=Sibling;
      FillComboBoxWithSiblings(LeftSiblingComboBox);
      LeftRefRightSpeedButton.Enabled:=Sibling<>'';
      LeftRefRightSpeedButton.Down:=(CurSide.Side=asrBottom);
      LeftRefCenterSpeedButton.Enabled:=Sibling<>'';
      LeftRefCenterSpeedButton.Down:=(CurSide.Side=asrCenter);
      LeftRefLeftSpeedButton.Enabled:=Sibling<>'';
      LeftRefLeftSpeedButton.Down:=(CurSide.Side=asrTop);

      // Right
      RightGroupBox.Enabled:=true;
      CurSide:=Values.Sides[akRight];
      RightAnchoredCheckBox.AllowGrayed:=CurSide.AmbigiousEnabled;
      if CurSide.AmbigiousEnabled then
        RightAnchoredCheckBox.State:=cbGrayed
      else
        RightAnchoredCheckBox.Checked:=CurSide.Enabled;
      if CurSide.AmbigiousBorderSpace then
        RightBorderSpaceSpinEdit.Value:=-1
      else
        RightBorderSpaceSpinEdit.Value:=CurSide.BorderSpace;
      RightBorderSpaceSpinEdit.ValueEmpty:=CurSide.AmbigiousBorderSpace;
      Sibling:=CurSide.Sibling;
      RightSiblingComboBox.Text:=Sibling;
      FillComboBoxWithSiblings(RightSiblingComboBox);
      RightRefRightSpeedButton.Enabled:=Sibling<>'';
      RightRefRightSpeedButton.Down:=(CurSide.Side=asrBottom);
      RightRefCenterSpeedButton.Enabled:=Sibling<>'';
      RightRefCenterSpeedButton.Down:=(CurSide.Side=asrCenter);
      RightRefLeftSpeedButton.Enabled:=Sibling<>'';
      RightRefLeftSpeedButton.Down:=(CurSide.Side=asrTop);
    end;
  finally
    FUpdating:=false;
  end;
end;

procedure TAnchorDesigner.OnRefreshPropertyValues;
begin
  Refresh(false);
end;

function TAnchorDesigner.GetSelectedControls: TList;
var
  CurPersistent: TPersistent;
  AControl: TControl;
  i: Integer;
begin
  Result:=nil;
  GlobalDesignHook.GetSelection(FSelection);
  if FSelection=nil then exit;
  // collect values of selected controls
  for i:=0 to FSelection.Count-1 do begin
    CurPersistent:=FSelection[i];
    if CurPersistent is TControl then begin
      AControl:=TControl(CurPersistent);
      if Result=nil then Result:=TList.Create;
      Result.Add(AControl);
    end;
  end;
end;

function TAnchorDesigner.FindSibling(const Sibling: string): TControl;
var
  Root: TPersistent;
  RootComponent: TComponent;
  i: Integer;
  CurComponent: TComponent;
  CurControl: TControl;
begin
  Root:=GlobalDesignHook.LookupRoot;
  if not (Root is TComponent) then exit;
  RootComponent:=TComponent(Root);
  for i:=0 to RootComponent.ComponentCount-1 do begin
    CurComponent:=TComponent(RootComponent.Components[i]);
    if CurComponent is TControl then begin
      CurControl:=TControl(CurComponent);
      if CompareText(Sibling,ControlToStr(CurControl))=0 then begin
        Result:=CurControl;
        exit;
      end;
    end;
  end;
end;

function TAnchorDesigner.ControlToStr(AControl: TControl): string;
begin
  if AControl=nil then
    Result:=''
  else
    Result:=AControl.Name+':'+AControl.ClassName;
end;

procedure TAnchorDesigner.CollectValues(
  const ASelection: TList; var TheValues: TAnchorDesignerValues;
  var SelectedControlCount: integer);
var
  i: Integer;
  AControl: TControl;
  CurObject: TObject;
begin
  TheValues:=nil;
  SelectedControlCount:=0;
  //debugln('TAnchorDesigner.CollectValues A ');
  if ASelection=nil then exit;
  // collect values of selected controls
  for i:=0 to ASelection.Count-1 do begin
    CurObject:=TObject(ASelection[i]);
    //debugln('TAnchorDesigner.CollectValues B ',dbgs(i),' ',DbgSName(CurObject));
    if CurObject is TControl then begin
      AControl:=TControl(CurObject);
      if SelectedControlCount=0 then begin
        TheValues:=TAnchorDesignerValues.Create;
        TheValues.SetValues(AControl);
      end else begin
        TheValues.MergeValues(AControl);
      end;
      inc(SelectedControlCount);
    end;
  end;
end;

procedure TAnchorDesigner.OnSetSelection(
  const ASelection: TPersistentSelectionList);
begin
  if FSelection.IsEqual(ASelection) then exit;
  Refresh(false);
end;

procedure TAnchorDesigner.AnchorDesignerClose(Sender: TObject;
  var CloseAction: TCloseAction);
begin
  EnvironmentOptions.IDEWindowLayoutList.ItemByForm(Self).GetCurrentPosition;
end;

{ TAnchorDesignerValues }

function TAnchorDesignerValues.GetSides(Kind: TAnchorKind
  ): TAnchorDesignerSideValues;
begin
  Result:=FSides[Kind];
end;

procedure TAnchorDesignerValues.SetAmbigiousBorderspaceAround(
  const AValue: boolean);
begin
  if FAmbigiousBorderspaceAround=AValue then exit;
  FAmbigiousBorderspaceAround:=AValue;
end;

procedure TAnchorDesignerValues.SetBorderspaceAround(const AValue: integer);
begin
  if FBorderspaceAround=AValue then exit;
  FBorderspaceAround:=AValue;
end;

constructor TAnchorDesignerValues.Create;
var
  a: TAnchorKind;
begin
  for a:=Low(TAnchorKind) to High(TAnchorKind) do
    FSides[a]:=TAnchorDesignerSideValues.Create(a);
end;

destructor TAnchorDesignerValues.Destroy;
var
  a: TAnchorKind;
begin
  for a:=Low(TAnchorKind) to High(TAnchorKind) do FSides[a].Free;
  inherited Destroy;
end;

procedure TAnchorDesignerValues.SetValues(AControl: TControl);
var
  a: TAnchorKind;
begin
  BorderspaceAround:=AControl.BorderSpacing.Around;
  AmbigiousBorderspaceAround:=false;
  for a:=Low(TAnchorKind) to High(TAnchorKind) do
    FSides[a].SetValues(AControl);
end;

procedure TAnchorDesignerValues.MergeValues(AControl: TControl);
var
  a: TAnchorKind;
begin
  FAmbigiousBorderspaceAround:=FAmbigiousBorderspaceAround
                         or (FBorderspaceAround<>AControl.BorderSpacing.Around);
  for a:=Low(TAnchorKind) to High(TAnchorKind) do
    FSides[a].MergeValues(AControl);
end;

{ TAnchorDesignerSideValues }

constructor TAnchorDesignerSideValues.Create(TheKind: TAnchorKind);
begin
  FAnchorKind:=TheKind;
end;

procedure TAnchorDesignerSideValues.SetValues(AControl: TControl);
var
  CurSide: TAnchorSide;
begin
  FAmbigiousBorderSpace:=false;
  FBorderSpace:=AControl.BorderSpacing.GetSpace(FAnchorKind);
  FAmbigiousEnabled:=false;
  FEnabled:=(FAnchorKind in AControl.Anchors);
  CurSide:=AControl.AnchorSide[FAnchorKind];
  FAmbigiousSide:=false;
  FSide:=CurSide.Side;
  FAmbigiousSibling:=false;
  FSibling:=TAnchorDesigner.ControlToStr(CurSide.Control);
end;

procedure TAnchorDesignerSideValues.MergeValues(AControl: TControl);
var
  CurSide: TAnchorSide;
begin
  FAmbigiousBorderSpace:=FAmbigiousBorderSpace
                or (FBorderSpace<>AControl.BorderSpacing.GetSpace(FAnchorKind));
  FAmbigiousEnabled:=FAmbigiousEnabled
                     or (FEnabled<>(FAnchorKind in AControl.Anchors));
  CurSide:=AControl.AnchorSide[FAnchorKind];
  FAmbigiousSide:=FAmbigiousSide or (CurSide.Side<>FSide);
  FAmbigiousSibling:=FAmbigiousSibling
                   or (TAnchorDesigner.ControlToStr(CurSide.Control)<>FSibling);
end;

initialization
  {$I anchoreditor.lrs}

end.

