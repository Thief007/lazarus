      {
 /***************************************************************************
                               FileSystem.pp
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
unit FileSystem;

{$mode objfpc}

interface

uses
  classes;

type

{  TFileSystem
   FileAge -- Returns the date/time of the file in a longint.

   GetFileStream -- Creates and returns a TStream for the Filename
                    passed into it.

   RenameFile -- Renames a file.  Returns TRUE is successful

   IsReadOnly -- Returns TRUE if file is READONLY.

   DeleteFile -- Returns TRUE if successful;

   FileExists -- Returns TRUE if the file exists

   GetBackupFileName -- Returns a string which represents the backup name for
                        the filename passed into the function.  It uses the
                        name passed into it to calculate the backup name.
}

  TFileSystem = class(TAbstractFileSystem)
   private
    FileStream : TFileStream;
   public
    constructor Create;
    Function FileAge(const Filename : TFilename) : Longint; override;
    Function GetFileStream(const Filename : TFilename; Mode : Integer): TStream; override;
    Function RenameFile(const Oldname, Newname : TFilename): Boolean; override;
    Function IsReadOnly(const Filename : TFilename): Boolean; override;
    Function DeleteFile(const Filename : TFilename): Boolean; override;
    Function FileExists(const Filename : TFilename) : Boolean; override;
    Function GetBackupFileName(const Filename : TFilename): TFilename; override;
  end;


implementation

constructor TFileSystem.Create;
Begin
//don't create the file stream here.  It's created by the GEtFileStream

end;

Function TFileSystem.FileAge(const Filename : TFilename) : Longint;
Begin

end;

Function TFileSystem.GetFileStream(const Filename : TFilename; Mode : Integer): TStream;
Begin
if Assigned(FileStream) then
  Begin

  end;
FFileStream := TFIleStream.Create(FileName,Mode);
Result := FFileStream;
end;

Function TFileSystem.RenameFile(const Oldname, Newname : TFilename): Boolean;
Begin

end;

Function TFileSystem.IsReadOnly(const Filename : TFilename): Boolean;
Begin

end;

Function TFileSystem.DeleteFile(const Filename : TFilename): Boolean;
Begin

end;

Function TFileSystem.FileExists(const Filename : TFilename) : Boolean;
Begin

end;

Function TFileSystem.GetBackupFileName(const Filename : TFilename): TFilename;
Begin

end;


end.
