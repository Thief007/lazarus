 {
 /***************************************************************************
                               combobox.pp  
                              -------------
                   Example/test program for combobox usage in lcl


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
program combobox;

{$mode objfpc}

uses
  classes, stdctrls,forms,buttons,menus,comctrls,sysutils, extctrls;

type
	TForm1 = class(TFORM)
	public
	  Label1 : TLabel;
	  Label2 : TLabel;
	  Label3 : TLabel;
	  Button1: TButton;
    	  Button2: TButton;
	  Button3: TButton;
	  Button4: TButton;
	  Edit1 : TEdit;
	  mnuMain: TMainMenu;
    	  itmFileQuit: TMenuItem;
    	  itmFile: TMenuItem;
          ComboBox1 : TComboBox;
          ComboBox2 : TComboBox;
          Memo1     : TMemo;
          constructor Create(AOwner: TComponent); override;	
          procedure LoadMainMenu;
	  Procedure FormKill(Sender : TObject);
	  procedure mnuQuitClicked(Sender : TObject);
	protected
	  procedure Button1CLick(Sender : TObject);
	  procedure Button2CLick(Sender : TObject);
	  procedure Button3CLick(Sender : TObject);
	  procedure Button4CLick(Sender : TObject);
	  procedure ComboOnChange (Sender:TObject);
	  procedure ComboOnClick (Sender:TObject);
	end;

var
Form1 : TForm1;

constructor TForm1.Create(AOwner: TComponent);	
begin
   inherited Create(AOwner);
   Caption := 'ComboBox Demo v 0.1';
   LoadMainMenu;
end;

procedure TForm1.Button1Click(Sender : TObject);
Begin
   if assigned (ComboBox1) and assigned (edit1)
      then ComboBox1.Text := edit1.text;
End;

procedure TForm1.Button2Click(Sender : TObject);
Begin
   if assigned (ComboBox1) 
      then Combobox1.Items.Add ('item ' + IntToStr (comboBox1.Items.Count));
   if assigned (ComboBox2) 
      then Combobox2.Items.Add ('item ' + IntToStr (comboBox2.Items.Count));
End;

procedure TForm1.Button3Click(Sender : TObject);
Begin
   if assigned (ComboBox1) and assigned (edit1) 
      then edit1.Text := ComboBox1.Text;
End;

procedure TForm1.Button4Click(Sender : TObject);
Begin
   if assigned (ComboBox1) 
      then ComboBox1.Enabled := not ComboBox1.Enabled;
End;

procedure TForm1.ComboOnChange (Sender:TObject);
var
   s : shortstring;	
begin
   if sender is TEdit 
      then s := 'TEdit'
   else if sender is TComboBox
      then s := 'TComboBox'
   else
      s := 'UNKNOWN';
   if assigned (Memo1)
      then Memo1.Lines.Add (s + 'ONChange');
end;

procedure TForm1.ComboOnClick (Sender:TObject);
begin
   if assigned (Memo1)
      then Memo1.Lines.Add ('ONClick');
end;
{------------------------------------------------------------------------------}

procedure TForm1.FormKill(Sender : TObject);
Begin
  Application.terminate;
End;

{------------------------------------------------------------------------------}
procedure TForm1.LoadMainMenu;

begin
   OnDestroy := @FormKill;

   { set the height and width }
   Height := 350;
   Width := 700;

   { Create 2 buttons inside the groupbox }
   Button2 := TButton.Create(Self);
   Button2.Parent := Self;
   Button2.Left := 50;
   Button2.Top := 40;
   Button2.Width := 120;
   Button2.Height := 30;
   Button2.Show;
   Button2.Caption := 'Add item';
   Button2.OnClick := @Button2Click;



   Button1 := TButton.Create(Self);
   Button1.Parent := Self;
   Button1.Left := 50;
   Button1.Top := 80;
   Button1.Width := 120;
   Button1.Height := 30;
   Button1.Show;
   Button1.Caption := 'Edit->Combo';
   Button1.OnClick := @Button1Click;


   { Create 2 more buttons outside the groupbox }
   Button3 := TButton.Create(Self);
   Button3.Parent := Self;
   Button3.Left := 50;
   Button3.Top := 120;
   Button3.Width := 120;
   Button3.Height := 30;
   Button3.Show;
   Button3.Caption := 'Combo->Edit';
   Button3.OnClick := @Button3Click;


   Button4 := TButton.Create(Self);
   Button4.Parent := Self;
   Button4.Left := 50;
   Button4.Top := 160;
   Button4.Width := 120;
   Button4.Height := 30;
   Button4.Show;
   Button4.Caption := 'Enabled On/Off';
   Button4.OnClick := @Button4Click;


   { Create a label for the edit field }
   label1 := TLabel.Create(Self);
   label1.Parent := self;
   label1.top	 := 50;
   label1.left	 := 320;
   label1.Height := 20;
   label1.Width  := 130;
   label1.Show;
   label1.Caption := 'TEdit :';


   Edit1 := TEdit.Create (self);
   with Edit1 do
   begin
      Parent := self;
      Left   := 500;
      Top    := 50;
      Width  := 70;
      Height := 20;
      OnChange := @ComboOnChange;	
      OnClick  := @ComboOnClick;	
      Show;	
   end;


   { Create a label for the 1st combobox }
   label2 := TLabel.Create(Self);
   label2.Parent := self;
   label2.top	 := 100;
   label2.left	 := 320;
   label2.Height := 20;
   label2.Width  := 130;
   label2.Enabled:= true;
   label2.Show;
   label2.Caption := 'Combo (unsorted)';


   { Create the menu now }
   { WARNING: If you do it after creation of the combo, the menu will not 
     appear. Reason is unknown by now!!!!!!}
   mnuMain := TMainMenu.Create(Self);
   Menu := mnuMain;
   itmFile := TMenuItem.Create(Self);
   itmFile.Caption := 'File';
   mnuMain.Items.Add(itmFile);
   itmFileQuit := TMenuItem.Create(Self);
   itmFileQuit.Caption := 'Quit';
   itmFileQuit.OnClick := @mnuQuitClicked;
   itmFile.Add(itmFileQuit);


   ComboBox1 := TComboBox.Create (self);
   with ComboBox1 do
   begin
      Parent := self;
      Left := 500;
      Top	:= 100;
      Width := 170;
      Height := 20;
      Style := csDropDown;	
      Items.Add ('wohhh!');
      Items.Add ('22222!');
      ItemIndex := 1;
      Items.Add ('33333!');
      Items.Add ('abcde!');
      OnChange := @ComboOnChange;	
      OnClick  := @ComboOnClick;	
      Show;	
   end;


   { Create a label for the 2nd combobox }
   label3 := TLabel.Create(Self);
   label3.Parent := self;
   label3.top	 := 150;
   label3.left	 := 320;
   label3.Height := 20;
   label3.Width  := 130;
   label3.Show;
   label3.Caption := 'Combo (sorted)';


   ComboBox2 := TComboBox.Create (self);
   with ComboBox2 do
   begin
      Parent := self;
      Left := 500;
      Top	:= 150;
      Width := 170;
      Height := 20;
      Items.Add ('wohhh!');
      Items.Add ('22222!');
      ItemIndex := 1;
      Items.Add ('33333!');
      Items.Add ('abcde!');
      Sorted := true;	
      Show;	
   end;


   Memo1 := TMemo.Create(Self);
   with Memo1 do
   begin
      Parent := Self;
      Scrollbars := ssBoth;	
      Left := 200;
      Top := 200;
      Width := 335;
      Height := 155;
      Show;
   end;


end;

{------------------------------------------------------------------------------}
procedure TForm1.mnuQuitClicked(Sender : TObject);
begin
   Application.Terminate;
end;
{------------------------------------------------------------------------------}

begin
   Application.Initialize; { calls InitProcedure which starts up GTK }
   Application.CreateForm(TForm1, Form1);
   Application.Run;
end.

{
  $Log$
  Revision 1.1  2000/07/13 10:28:20  michael
  + Initial import

  Revision 1.1  2000/07/03 18:10:37  lazarus
  New example for Comboboxes, stoppok

}
