{%MainUnit ../graphics.pp}
{
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

{ TGraphic }

constructor TGraphic.Create;
begin
  Inherited Create;
end;

procedure TGraphic.DefineProperties(Filer: TFiler);

  function DoWrite: Boolean;
  begin
    //debugln('TGraphic.DefineProperties DoWrite A ',dbgs(Filer.Ancestor <> nil));
    if Filer.Ancestor <> nil then
      Result := not (Filer.Ancestor is TGraphic) or
        not Equals(TGraphic(Filer.Ancestor))
    else
      Result := not Empty;
    //debugln('TGraphic.DefineProperties DoWrite End ');
  end;

begin
  //debugln('TGraphic.DefineProperties A ',dbgs(Filer<>nil),' ',Filer.ClassName);
  Filer.DefineBinaryProperty('Data', @ReadData, @WriteData, DoWrite);
  //debugln('TGraphic.DefineProperties END');
end;

function TGraphic.GetPalette: HPALETTE;
begin
  Result:=0;
end;

procedure TGraphic.Changed(Sender: TObject);
begin
  FModified := True;
  if Assigned(FOnChange) then FOnChange(Self);
end;

procedure TGraphic.Progress(Sender: TObject; Stage: TProgressStage;
  PercentDone: Byte; RedrawNow: Boolean; const R: TRect; const Msg: string;
  var DoContinue: boolean);
begin
  DoContinue:=true;
  if Assigned(FOnProgress) then
    FOnProgress(Sender, Stage, PercentDone, RedrawNow, R, Msg, DoContinue);
end;

function TGraphic.Equals(Graphic: TGraphic): Boolean;
var
  SelfImage, GraphicsImage: TMemoryStream;
  IsEmpty: boolean;
begin
  Result := (Graphic <> nil) and (ClassType = Graphic.ClassType);
  if not Result then exit;
  IsEmpty:=Empty;
  Result:=(IsEmpty=Graphic.Empty);
  if (not Result) or IsEmpty or (Self=Graphic) then exit;
  SelfImage := TMemoryStream.Create;
  try
    WriteData(SelfImage);
    GraphicsImage := TMemoryStream.Create;
    try
      Graphic.WriteData(GraphicsImage);
      Result := (SelfImage.Size = GraphicsImage.Size) and
             CompareMem(SelfImage.Memory, GraphicsImage.Memory,
                        TCompareMemSize(SelfImage.Size));
    finally
      GraphicsImage.Free;
    end;
  finally
    SelfImage.Free;
  end;
end;

procedure TGraphic.ReadData(Stream: TStream);
begin
  LoadFromStream(Stream);
end;

procedure TGraphic.SetPalette(Value: HPALETTE);
begin

end;

procedure TGraphic.SaveToFile(const Filename: string);
var
  Stream: TStream;
begin
  Stream := TFileStream.Create(Filename, fmCreate);
  try
    SaveToStream(Stream);
  finally
    Stream.Free;
  end;
end;

procedure TGraphic.LoadFromMimeStream(Stream: TStream; const MimeType: string);
var
  DefMimeType: String;
begin
  DefMimeType:=GetDefaultMimeType;
  if (DefMimeType<>'') and (MimeType=GetDefaultMimeType) then
    LoadFromStream(Stream)
  else
    raise Exception.Create(ClassName+': Unsupported MimeType: '+MimeType);
end;

procedure TGraphic.LoadFromClipboardFormat(FormatID: TClipboardFormat);
begin
  LoadFromClipboardFormatID(ctClipboard,FormatID);
end;

procedure TGraphic.LoadFromClipboardFormatID(ClipboardType: TClipboardType;
  FormatID: TClipboardFormat);
begin
  if OnLoadSaveClipBrdGraphicValid
  and Assigned(OnLoadGraphicFromClipboardFormat) then
    OnLoadGraphicFromClipboardFormat(Self,ClipboardType,FormatID);
end;

procedure TGraphic.SaveToClipboardFormat(FormatID: TClipboardFormat);
begin
  SaveToClipboardFormatID(ctClipboard,FormatID);
end;

procedure TGraphic.SaveToClipboardFormatID(ClipboardType: TClipboardType;
  FormatID: TClipboardFormat);
begin
  if OnLoadSaveClipBrdGraphicValid
  and Assigned(OnSaveGraphicToClipboardFormat) then
    OnSaveGraphicToClipboardFormat(Self,ClipboardType,FormatID);
end;

procedure TGraphic.GetSupportedSourceMimeTypes(List: TStrings);
var
  DefMimeType: String;
begin
  List.Clear;
  DefMimeType:=GetDefaultMimeType;
  if DefMimeType<>'' then
    List.Add(DefMimeType);
end;

function TGraphic.GetDefaultMimeType: string;
begin
  Result:='';
end;

{-------------------------------------------------------------------------------
  function TGraphic.GetFileExtensions: string;

  Returns standard file extensions for reading and writing separated by
  semicolon and without point. For example: "bmp;xpm"
-------------------------------------------------------------------------------}
function TGraphic.GetFileExtensions: string;
begin
  Result:='';
end;

procedure TGraphic.LoadFromFile(const Filename: string);
var
  Stream: TStream;
begin
  Stream := TFileStream.Create(Filename, fmOpenRead{ or fmShareDenyWrite});
  try
    LoadFromStream(Stream);
  finally
    Stream.Free;
  end;
end;

procedure TGraphic.WriteData(Stream: TStream);
begin
  SaveToStream(Stream);
end;

function TGraphic.GetTransparent: Boolean;
begin
  Result := FTransparent;
end;

procedure TGraphic.SetModified(Value: Boolean);
begin
  if Value then
    Changed(Self)
  else
    FModified := False;
end;

function TGraphic.GetFPReaderForFileExt(const FileExtension: string
  ): TFPCustomImageReaderClass;
begin
  Result:=nil;
end;

function TGraphic.GetFPWriterForFileExt(const FileExtension: string
  ): TFPCustomImageWriterClass;
begin
  Result:=nil;
end;

function TGraphic.GetDefaultFPReader: TFPCustomImageReaderClass;
begin
  Result:=nil;
end;

function TGraphic.GetDefaultFPWriter: TFPCustomImageWriterClass;
begin
  Result:=nil;
end;

procedure TGraphic.SetTransparent(Value: Boolean);
begin
  if Value <> FTransparent then begin
    FTransparent := Value;
    Changed(Self);
  end;
end;

// included by graphics.pp
