{
 /***************************************************************************
                           MsgView.pp - compiler message view
                           ----------------------------------
                   TMessagesView is responsible for displaying the
                   PPC386 compiler messages.


                   Initial Revision  : Mon Apr 17th 2000


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
unit MsgView;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, StdCtrls, Forms, LResources;

type

  TMessagesView = class(TForm)
    MessageView : TListBox;
  private
    Function GetMessage : String;
    Procedure MessageViewClicked(sender : TObject);
    FOnSelectionChanged : TNotifyEvent;
    LastSelectedIndex : Integer;
  protected
    Function GetSelectedLineIndex : Integer;
  public
    constructor Create(AOwner : TComponent); override;
    Procedure Add(const Texts : String);
    Procedure Clear;
    property Message : String read GetMessage;
    property SelectedMessageIndex : Integer read GetSelectedLineIndex;
    property OnSelectionChanged : TNotifyEvent read FOnSelectionChanged write FOnSelectionChanged;
  end;

var
  MessagesView : TMessagesView;


implementation

{ TMessagesView }


{------------------------------------------------------------------------------}
{  TMessagesView.Create                                                           }
{------------------------------------------------------------------------------}
constructor TMessagesView.Create(AOwner : TComponent);
Begin
  inherited Create(AOwner);
  if LazarusResources.Find(ClassName)=nil then begin
    Caption:='Compiler Messages';
    MessageView := TListBox.Create(Self);
    With MessageView do Begin
      Parent:= Self;
      Align:= alClient;
      Visible:= true;
      Name := 'MessageView';

    end;
  end;
  LastSelectedIndex := -1;
end;


{------------------------------------------------------------------------------}
{  TMessagesView.Add                                                           }
{------------------------------------------------------------------------------}
Procedure  TMessagesView.Add(const Texts : String);
Begin
  MessageView.Items.Add(Texts);
  


end;

{------------------------------------------------------------------------------}
{  TMessagesView.Clear                                                           }
{------------------------------------------------------------------------------}
Procedure  TMessagesView.Clear;
Begin
  MessageView.Clear;

  if not Assigned(MessagesView.MessageView.OnCLick) then //:= @MessagesView.MessageViewClicked;
     MessageView.OnClick := @MessageViewClicked;
end;

{------------------------------------------------------------------------------}
{  TMessagesView.GetMessage                                                           }
{------------------------------------------------------------------------------}
Function  TMessagesView.GetMessage : String;
var
  I : Integer;
Begin
  Result := '';
  if (MessageView.Items.Count > 0) and (MessageView.SelCount > 0) then
      Result := MessageView.Items.Strings[GetSelectedLineIndex];
end;

Function TMessagesView.GetSelectedLineIndex : Integer;
var
  I : Integer;
Begin
  Result := -1;
  if (MessageView.Items.Count > 0) and (MessageView.SelCount > 0) then Begin
    for i := 0 to MessageView.Items.Count-1 do
    Begin
      if MessageView.Selected[I] then
        Begin
	  Result := I;
          Break;
        end;
    end;
  end;
end;

Procedure TMessagesView.MessageViewClicked(sender : TObject);
var
  Temp : Integer;  //this temporarily holds the line # of the selection
begin
  if (MessageView.Items.Count > 0) and (MessageView.SelCount > 0) then
      Begin
         Temp := GetSelectedLineIndex;
         if Temp <> LastSelectedIndex then
            Begin
               LastSelectedIndex := Temp;
               If Assigned(OnSelectionChanged) then
                  OnSelectionChanged(self);
             end;

      end;
      
end;

initialization
  { $I msgview.lrs}


end.

