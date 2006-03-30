{
 /***************************************************************************
                               DirSel.pas
                               ----------
                            Component Library


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
unit DirSel;

{$mode objfpc}{$H+}

{$IF defined(VER2_0_2) and defined(win32)}
// FPC <= 2.0.2 compatibility code
// WINDOWS define was added after FPC 2.0.2
  {$define WINDOWS}
{$endif}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, Buttons,
  StdCtrls, ComCtrls, ExtCtrls, FileCtrl;

type
  TDirSelDlg = class(TForm)
    Button1: TBUTTON;
    Button2: TBUTTON;
    Label1: TLABEL;
    Panel1: TPANEL;
    Panel2: TPANEL;
    Panel3: TPANEL;
    Panel4: TPANEL;
    TV: TTREEVIEW;
    procedure FormCreate(Sender: TObject);
    //procedure Create(AOwner: TComponent);
    procedure FormShow(Sender: TObject);
    procedure TVExpanded(Sender: TObject; Node: TTreeNode);
    procedure TVItemDoubleClick(Sender: TObject);
  private
    { private declarations }
    FRootDir: string;
    FDir: string;
    FShowHidden: Boolean;
    //TheImageList: TImageList;
    Procedure AddDirectories(Node: TTreeNode; Dir: string);
    function GetAbsolutePath(Node: TTreeNode): string;
    procedure SetDir(const Value: string);
    procedure SetRootDir(const Value: string);
  public
    { public declarations }
    function SelectedDir: string;
    property Directory: string read FDir write SetDir;
    property RootDirectory: string read FRootDir write SetRootDir;
    property ShowHidden: Boolean read FShowHidden write FShowHidden;
  end; 

var
  DirSelDlg: TDirSelDlg;

  
implementation

const
  {$IFDEF WINDOWS}
  FindMask = '*.*';
  {$ELSE}
  FindMask = '*';
  {$ENDIF}

{ TDirSelDlg }

{Function HasSubDirs returns True if the directory passed has subdirectories}
function HasSubDirs(const Dir: string; IgnoreHidden: boolean): Boolean;
var
  //Result of FindFirst, FindNext
  FileInfo: TSearchRec;
  FCurrentDir: string;
begin
 //Assume No
 Result:= False;
 if Dir <> '' then
 begin
   FCurrentDir:= Dir;
   FileCtrl.AppendPathDelim(FCurrentDir);
   FCurrentDir:= Dir + FindMask;
   Try
     if SysUtils.FindFirst(FCurrentDir, (faAnyFile),FileInfo)=0 then
     begin
       repeat
         // check if special file
         if ((FileInfo.Name='.') or (FileInfo.Name='..')) or (FileInfo.Name='')
            (((faHidden and FileInfo.Attr)>0) and
              IgnoreHidden) then continue;
         Result:= ((faDirectory and FileInfo.Attr)>0);
         //We found at least one non special dir, that's all we need.
         if Result then break;
       until SysUtils.FindNext(FileInfo)<>0;
     end;//if
   finally
     SysUtils.FindClose(FileInfo);
   end;//Try-Finally
 end;//if
end;//HasSubDirs


{Procedure AddDirectories Adds Subdirectories to a passed node if they exist}
procedure TDirSelDlg.AddDirectories(Node: TTreeNode; Dir: string);
var
  FileInfo: TSearchRec;
  NewNode: TTreeNode;
  i: integer;
  FCurrentDir: string;
  //used to sort the directories.
  SortList: TStringList;
begin
  if Dir <> '' then
  begin
    FCurrentDir:= Dir;
    FileCtrl.AppendPathDelim(FCurrentDir);
    i:= length(FCurrentDir);
    FCurrentDir:= Dir + FindMask;
    Try
      if SysUtils.FindFirst(FCurrentDir, faAnyFile,FileInfo)=0 then
      begin
        Try
          SortList:= TStringList.Create;
          SortList.Sorted:= True;
          repeat
            // check if special file
            if (FileInfo.Name='.') or (FileInfo.Name='..') or (FileInfo.Name='')
            then
              continue;
            // if this is a directory then add it to the tree.
            if ((faDirectory and FileInfo.Attr)>0) then
            begin
              //if this is a hidden file and we have not been requested to show
              //hidder files then do not add it to the list.
              if ((faHidden and FileInfo.Attr)>0)
                                         and not (FShowHidden) then continue;
              SortList.Add(FileInfo.Name);
            end;//if
          until SysUtils.FindNext(FileInfo)<>0;
          for i:= 0 to SortList.Count - 1 do
          begin
            NewNode:= TV.Items.AddChild(Node,SortList[i]);
            //if subdirectories then indicate so.
            NewNode.HasChildren:= HasSubDirs(Dir + PathDelim + NewNode.Text, FShowHidden);
          end;//for
        finally
          SortList.free;
        end;//Try-Finally
      end;//if
    finally
      SysUtils.FindClose(FileInfo);
    end;//Try-Finally
  end;//if
  if Node.Level = 0 then Node.Text := Dir;
end;//AddDirectories

{Procedure SetRootNode Clear the TreeView and Add the root with it's
 subdirectories}
Procedure TDirSelDlg.SetRootDir(const Value: string);
var
  RootNode: TTreeNode;
begin
  //Clear the list
  TV.Items.Clear;
  FRootDir:= Value;
  //Remove the path delimiter unless this is root.
  if FRootDir = '' then FRootDir := PathDelim;
  if (FRootDir <> PathDelim) and (FRootDir[length(FRootDir)] = PathDelim) then
    FRootDir:= copy(FRootDir,1,length(FRootDir) - 1);
  //Create the root node and add it to the Tree View.
  RootNode:= TV.Items.Add(nil,FRootDir);
  //Add the Subdirectories to Root.
  AddDirectories(RootNode,FRootDir);
  //Set the root node as the selected node.
  TV.Selected:= RootNode;
end;//SetRootDir

{Returns the absolute path to a node.}
function TDirSelDlg.GetAbsolutePath(Node: TTreeNode): string;
begin
  Result:= '';
  While Node<>nil do
  begin
    if Node.Text = PathDelim then
      Result:= Node.Text + Result
    else
      Result:= Node.Text + PathDelim + Result;
    Node:= Node.Parent;
  end;//while
end;//GetAbsolutePath


procedure TDirSelDlg.FormCreate(Sender: TObject);
begin
  TV.HandleNeeded;
end;

procedure TDirSelDlg.FormShow(Sender: TObject);
begin
  if TV.Selected <> nil then
    TV.Selected.Expand(false);
end;//FormShow

procedure TDirSelDlg.TVExpanded(Sender: TObject; Node: TTreeNode);
begin
  if Node.Count = 0 then
    AddDirectories(Node, GetAbsolutePath(Node));
end;//TVExpanded

procedure TDirSelDlg.TVItemDoubleClick(Sender: TObject);
begin

end;

procedure TDirSelDlg.SetDir(const Value: string);
var
  StartDir: string;
  Node: TTreeNode;
  i,p: integer;
  SubDir: PChar;
begin

  FDir:= Value;
  StartDir:= Value;
  if TV.Items.Count = 0 then exit;
  p:= AnsiPos(FRootDir, StartDir);
  if p = 1 then
    Delete(StartDir,P,Length(FRootDir));
  for i:= 1 to Length(StartDir) do
    if (StartDir[i] = PathDelim) then StartDir[i] := #0;
  SubDir:= PChar(StartDir);
  if SubDir[0] = #0 then
    SubDir:= @SubDir[1];
  Node:= TV.Items.GetFirstNode;
  While SubDir[0] <> #0 do
  begin
    Node:= Node.GetFirstChild;
    while (Node <> nil) and (AnsiCompareStr(Node.Text, SubDir) <> 0) do
      Node:= Node.GetNextSibling;
    if Node = nil then break
    else
    begin
      Node.Expand(False);
    end;//else
    SubDir:= SubDir + StrLen(SubDir) + 1
  end;//While
  TV.Selected.MakeVisible;
end;//SetDir

function TDirSelDlg.SelectedDir: string;
begin
  Result:= '';
  if TV.Selected <> nil then
    Result:= GetAbsolutePath(TV.Selected);
end;//SelectedDir

initialization
  {$I dirsel.lrs}

end.
