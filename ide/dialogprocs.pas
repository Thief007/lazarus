{  $Id$  }
{
 /***************************************************************************
                            dialogprocs.pas
                            ---------------

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
    Common IDE functions with MessageDlg(s) for errors.
}
unit DialogProcs;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Dialogs, FileCtrl, CodeCache,
  CodeToolManager, AVL_Tree,
  IDEProcs, LazarusIDEStrConsts;

type
  // load buffer flags
  TLoadBufferFlag = (
    lbfUpdateFromDisk,
    lbfRevert,
    lbfCheckIfText,
    lbfQuiet,
    lbfCreateClearOnError
    );
  TLoadBufferFlags = set of TLoadBufferFlag;

function RenameFileWithErrorDialogs(const SrcFilename, DestFilename: string;
  ExtraButtons: TMsgDlgButtons): TModalResult;
function LoadCodeBuffer(var ACodeBuffer: TCodeBuffer; const AFilename: string;
  Flags: TLoadBufferFlags): TModalResult;
function CreateEmptyFile(const Filename: string;
  ErrorButtons: TMsgDlgButtons): TModalResult;


implementation


function RenameFileWithErrorDialogs(const SrcFilename, DestFilename: string;
  ExtraButtons: TMsgDlgButtons): TModalResult;
var
  DlgButtons: TMsgDlgButtons;
begin
  if CompareFilenames(SrcFilename,DestFilename)=0 then begin
    Result:=mrOk;
    exit;
  end;
  repeat
    if RenameFile(SrcFilename,DestFilename) then begin
      break;
    end else begin
      DlgButtons:=[mbCancel,mbRetry]+ExtraButtons;
      Result:=MessageDlg('Unable to rename file',
        'Unable to rename file "'+SrcFilename+'"'#13
        +'to "'+DestFilename+'".',
        mtError,DlgButtons,0);
      if (Result<>mrRetry) then exit;
    end;
  until false;
  Result:=mrOk;
end;

function LoadCodeBuffer(var ACodeBuffer: TCodeBuffer; const AFilename: string;
  Flags: TLoadBufferFlags): TModalResult;
var
  ACaption, AText: string;
begin
  repeat
    if (lbfCheckIfText in Flags)
    and FileExists(AFilename) and (not FileIsText(AFilename))
    then begin
      if lbfQuiet in Flags then begin
        Result:=mrCancel;
      end else begin
        ACaption:=lisFileNotText;
        AText:=Format(lisFileDoesNotLookLikeATextFileOpenItAnyway2, ['"',
          AFilename, '"', #13, #13]);
        Result:=MessageDlg(ACaption, AText, mtConfirmation,
                           [mbOk, mbIgnore, mbAbort], 0);
      end;
      if Result<>mrOk then break;
    end;
    ACodeBuffer:=CodeToolBoss.LoadFile(AFilename,lbfUpdateFromDisk in Flags,
                                       lbfRevert in Flags);
    if ACodeBuffer<>nil then begin
      Result:=mrOk;
    end else begin
      if lbfQuiet in Flags then
        Result:=mrCancel
      else begin
        ACaption:=lisReadError;
        AText:=Format(lisUnableToReadFile2, ['"', AFilename, '"']);
        Result:=MessageDlg(ACaption,AText,mtError,[mbAbort,mbRetry,mbIgnore],0);
      end;
      if Result=mrAbort then break;
    end;
  until Result<>mrRetry;
  if (ACodeBuffer=nil) and (lbfCreateClearOnError in Flags) then begin
    ACodeBuffer:=CodeToolBoss.CreateFile(AFilename);
    if ACodeBuffer<>nil then
      Result:=mrOk;
  end;
end;

function CreateEmptyFile(const Filename: string; ErrorButtons: TMsgDlgButtons
  ): TModalResult;
var
  Buffer: TCodeBuffer;
begin
  repeat
    Buffer:=CodeToolBoss.CreateFile(Filename);
    if Buffer<>nil then begin
      break;
    end else begin
      Result:=MessageDlg('Unable to create file',
        'Unable to create file "'+Filename+'".',
        mtError,ErrorButtons+[mbCancel],0);
      if Result<>mrRetry then exit;
    end;
  until false;
  repeat
    if Buffer.Save then begin
      break;
    end else begin
      Result:=MessageDlg('Unable to write file',
        'Unable to write file "'+Buffer.Filename+'"',
        mtError,ErrorButtons+[mbCancel],0);
      if Result<>mrRetry then exit;
    end;
  until false;
  Result:=mrOk;
end;

end.

