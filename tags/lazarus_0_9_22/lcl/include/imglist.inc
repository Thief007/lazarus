{%MainUnit ../imglist.pp}

{******************************************************************************
                                  TCustomImageList
 ******************************************************************************

 *****************************************************************************
 *                                                                           *
 *  This file is part of the Lazarus Component Library (LCL)                 *
 *                                                                           *
 *  See the file COPYING.modifiedLGPL, included in this distribution,        *
 *  for details about the copyright.                                         *
 *                                                                           *
 *  This program is distributed in the hope that it will be useful,          *
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of           *
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                     *
 *                                                                           *
 *****************************************************************************
}

type
  TImageListSignature = array[0..1] of char;

const
  SIG_LAZ1 = #1#0;
  SIG_LAZ2 = 'li';
  SIG_D3   = 'IL';

{------------------------------------------------------------------------------
  Method:  CopyImage
  Params:  Destination, Source: the destination/source canvas
  	       DestinationRect: the rectangle where the image is copied to 
  	       SourceRect: the rectangle containing the part to be copied 
  Returns: Nothing

  Internal routine to copy a rectangle from a source canvas to a rectangle on 
  the destination canvas
 ------------------------------------------------------------------------------}
procedure CopyImage(Destination, Source: TCanvas; DestinationRect, SourceRect: TRect);
begin
  Destination.CopyRect(
    DestinationRect,
    Source,
    SourceRect
  );
end;


{ TCustomImageList }

{------------------------------------------------------------------------------
  Function: TCustomImageList.Add
  Params:   Image: a bitmap image
            Mask: a bitmap which defines the transparent parts of Image
  Returns:  The index of the added image, -1 if unsuccesful.

  Adds one or more (bitmap width / imagelist width) bitmaps to the list.
  If Mask is nil, the image has no transparent parts.

  The image is copied. To add it directly use AddDirect.
 ------------------------------------------------------------------------------}
function TCustomImageList.Add(Image, Mask: TBitmap): Integer;
begin
  Result:=AddCopy(Image,Mask);
end;

function TCustomImageList.AddDirect(Image, Mask: TBitmap): Integer;
begin
  try
    Result := Count;
    Insert(Result, Image, Mask);
  except
    on E: Exception do begin
      DebugLn('TCustomImageList.Add ',E.Message);
      Result := -1; // Ignore exceptions, just return -1
    end;
  end;
end;

function TCustomImageList.AddCopy(SrcImage, SrcMask: TBitmap): Integer;
var
  NewImage: TBitmap;
  NewMask: TBitmap;
begin
  NewImage:=nil;
  NewMask:=nil;
  try
    NewImage := TBitmap.Create;
    NewImage.Assign(SrcImage);
    if Assigned(SrcMask) 
    then begin
      NewMask := TBitmap.Create;
      NewMask.Assign(SrcMask);
    end;
    Result:=AddDirect(NewImage, NewMask);
    NewImage:=nil;
    NewMask:=nil;
  finally
    NewImage.Free;
    NewMask.Free;
  end;
end;

{------------------------------------------------------------------------------
  Function: TCustomImageList.AddIcon
  Params:   Image: the Icon to be added;
  Returns:  The index of the added icon, -1 if unsuccesfull.

  Adds an icon to the list.
 ------------------------------------------------------------------------------}
function TCustomImageList.AddIcon(Image: TIcon): Integer;
begin 
  //!!! check one or more

  //No Icon Support yet

  Result := -1;
end;

{------------------------------------------------------------------------------
  Method:  TCustomImageList.AddImages
  Params:  Value: An imagelist containing images to be added
  Returns: Nothing

  Adds images from another imagelist to the list.
 ------------------------------------------------------------------------------}
procedure TCustomImageList.AddImages(Value: TCustomImageList);
var
  n: Integer;
  SrcImage: TBitmap;
  SrcMask: TBitmap;
  NewImage: TBitmap;
  NewMask: TBitmap;
begin
  if (Value = nil) or (Value=Self) then exit;
  BeginUpdate;
  for n := 0 to Value.Count - 1 do begin
    SrcImage:=TBitmap(Value.FImageList[n]);
    if SrcImage<>nil then begin
      NewImage:=TBitmap.Create;
      NewImage.Assign(SrcImage);
      SrcMask:=TBitmap(Value.FMaskList[n]);
      if SrcMask<>nil then begin
        NewMask:=TBitmap.Create;
        NewMask.Assign(SrcMask);
      end else
        NewMask:=nil;
      AddDirect(NewImage,NewMask);
    end;
  end;
  EndUpdate;
end;

{------------------------------------------------------------------------------
  Function: TCustomImageList.AddMasked
  Params:   Image: A bitmap to be added
            MaskColor: The color acting as transparant color
  Returns:  The index of the added icon, -1 if unsuccesfull.

  Adds one or more (bitmap width / imagelist width) bitmaps to the list. 
  Every occurance of MaskColor will be converted to transparent.
 ------------------------------------------------------------------------------}
function TCustomImageList.AddMasked(Image: TBitmap; MaskColor: TColor): Integer;
begin
  try
    Result := Count;
    InsertMasked(Result, Image, MaskColor);
  except
    on E: Exception do begin
      DebugLn('TCustomImageList.AddMasked ',E.Message);
      Result := -1; // Ignore exceptions, just return -1
    end;
  end;
end;

{------------------------------------------------------------------------------
  function TCustomImageList.AddFromLazarusResource(const ResourceName: string
    ): integer;
    
  Load TBitmap from lazarus resources and add it.
 ------------------------------------------------------------------------------}
function TCustomImageList.AddFromLazarusResource(const ResourceName: string
  ): integer;
var
  ABitmap: TBitmap;
begin
  ABitmap:=TBitmap.Create;
  ABitmap.LoadFromLazarusResource(ResourceName);
  Result:=AddDirect(ABitmap,nil);
end;

{------------------------------------------------------------------------------
  Method:  TCustomImageList.AllocBitmap
  Params:  Amount: the amount of free image position which should be availabe 
  Returns: Nothing

  Checks if there is enough space for Amount images,  increases the internal 
  list if necessary .
 ------------------------------------------------------------------------------}
procedure TCustomImageList.AllocBitmap(Amount: Integer);
var
  Num: Integer;
begin
  Assert(FAllocCount >= FCount, 'Less space allocated than images');
  if FAllocCount < FCount + Amount
  then begin
    // calculate number of blocks
    Num := Amount div FAllocBy;
    // add an extra block for the remainder.
    if Amount mod FAllocBy <> 0 then Inc(Num);

    if FBitMap<>nil then
      FBitMap.Height := FBitMap.Height + Num * FAllocBy * FHeight;
    if FMaskBitmap<>nil then
      FMaskBitmap.Height := FBitMap.Height;
    Inc(FAllocCount, Num * FAllocBy);
  end;

  //raise Exception.Create('Unable to allocate bitmap space');
end;

{------------------------------------------------------------------------------
  Method:  TCustomImageList.Assign
  Params:  Source: Source data
  Returns: Nothing

  Very simple assign with stream exchange
 ------------------------------------------------------------------------------}
procedure TCustomImageList.Assign(Source: TPersistent);
Var
  ImgSrc : TCustomImageList;
begin
  if (Source=Self) then exit;
  if Source is TCustomImageList then
  begin
    ImgSrc:=TCustomImageList(Source);
    SetWidthHeight(ImgSrc.Width,ImgSrc.Height);
    Clear;
    AddImages(ImgSrc);
  end
  else inherited Assign(Source);
end;

{------------------------------------------------------------------------------
  Method:  TCustomImageList.AssignTo
  Params:  Dest: the destination to assign to
  Returns: Nothing

  Very simple assign with stream exchange
 ------------------------------------------------------------------------------}
procedure TCustomImageList.AssignTo(Dest: TPersistent);
begin
  if Dest is TCustomImageList then
    TCustomImageList(Dest).Assign(Self)
  else
    inherited AssignTo(Dest);
end;

{------------------------------------------------------------------------------
  Method:  TCustomImageList.BeginUpdate
  Params:  None
  Returns: Nothing

  Lock the change event for updating.
 ------------------------------------------------------------------------------}
procedure TCustomImageList.BeginUpdate;
begin
  inc(FUpdateCount);
end;

{------------------------------------------------------------------------------
  Method:  TCustomImageList.Change
  Params:  None
  Returns: Nothing

  Fires the change event.
 ------------------------------------------------------------------------------}
procedure TCustomImageList.Change;
begin
  if (not FChanged) or (FUpdateCount > 0) then exit;
  NotifyChangeLink;
  if Assigned(FOnChange) then FOnChange(Self);
  FChanged := false;
end;

{------------------------------------------------------------------------------
  Method:  TCustomImageList.Clear
  Params:  None
  Returns: Nothing

  Clears the list.
 ------------------------------------------------------------------------------}
procedure TCustomImageList.Clear;
begin
  if FCount=0 then exit;
  While Count>0 do
    Delete(0);
  FCount := 0;
  FImageList.Clear;
  FMaskList.Clear;
  Change;
end;

{------------------------------------------------------------------------------
  Method:  TCustomImageList.Create
  Params:  AOwner: the owner of the class
  Returns: Nothing

  Constructor for the class.
 ------------------------------------------------------------------------------}
constructor TCustomImageList.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  FHeight := 16;
  FWidth := 16;
  FImageList := TList.Create;  //shane
  FMaskList := TList.Create;
  Initialize;
end;

{------------------------------------------------------------------------------
  Method:  TCustomImageList.CreateSize
  Params:  AHeight: The height of an image 
           AWidth: The width of an image
  Returns: Nothing

  Runtime constructor for the class with a given width and height.
 ------------------------------------------------------------------------------}
constructor TCustomImageList.CreateSize(AWidth, AHeight: Integer);
begin
  inherited Create(nil);
  FHeight := AHeight;
  FWidth := AWidth;
  FImageList := TList.Create;  //shane
  FMaskList := TList.Create;
  Initialize;
end;

{------------------------------------------------------------------------------
  Method:  TCustomImageList.DefineProperties
  Params:  Filer: A filer for our properties
  Returns: Nothing

  Defines the images
 ------------------------------------------------------------------------------}
procedure TCustomImageList.DefineProperties(Filer: TFiler);

  function DoWrite: Boolean;
  begin
   { if Filer.Ancestor <> nil then
    begin
      Result := (not (Filer.Ancestor is TCustomImageList) or
        not Equal(TCustomImageList(Filer.Ancestor)));
    end
    else
    }
      Result := Count > 0;
  end;

begin
  inherited DefineProperties(Filer);
  Filer.DefineBinaryProperty('Bitmap', @ReadData, @WriteData, DoWrite);
end;

{------------------------------------------------------------------------------
  Method:  TCustomImageList.Delete
  Params:  Index: the index of the image to be deleted.
  Returns: Nothing

  Deletes the image identified by Index. An index of -1 deletes all
 ------------------------------------------------------------------------------}
procedure TCustomImageList.Delete(Index: Integer);
Var Obj : TObject;
begin
  if {(Index < 0) or} (Index >= FCount) // !! Delphi4 has no check for < -1
  then raise EInvalidOperation.Create(SInvalidIndex);

  if Index = -1 then
    Clear
  else
  begin
    Obj:=TObject(fImageList.Items[Index]);
    If Assigned(Obj) then
      Obj.Free;
    fImageList.Delete(Index);
    Obj:=TObject(fMaskList.Items[Index]);
    If Assigned(Obj) then
      Obj.Free;
    fMaskList.Delete(Index);
//    ShiftImages(FBitmap.Canvas, Index, 1);
//    ShiftImages(FMaskBitmap.Canvas, Index, 1);
    FCount := fImageList.Count;
    FChanged := true;
    Change;
  end;
end;

{------------------------------------------------------------------------------
  Method: TCustomImageList.Destroy
  Params:  None
  Returns: Nothing

  Destructor for the class.
 ------------------------------------------------------------------------------}
destructor TCustomImageList.Destroy;
var
  i: integer;
begin
  FBitmap.Free;
  FBitmap:=nil;
  FMaskBitmap.Free;
  FMaskBitmap:=nil;
  for i:=0 to FImageList.Count-1 do TObject(FImageList[i]).Free;
  for i:=0 to FMaskList.Count-1 do TObject(FMaskList[i]).Free;
  FreeThenNil(FImageList);
  FreeThenNil(FMaskList);
  inherited Destroy;
  while FChangeLinkList.Count>0 do
    UnregisterChanges(TChangeLink(FChangeLinkList[0]));
  FreeThenNil(FChangeLinkList);
end;

{------------------------------------------------------------------------------
  Method:  TCustomImageList.Draw
  Params:  Canvas: the canvas to draw on
           X, Y: co-ordinates of the top, left corner of thetarget location 
           Index: index of the image to be drawn
           Enabled: True, draws the image
                    False, draws the image disabled (embossed)
  Returns: Nothing

  Draws the requested image on the given canvas.
 ------------------------------------------------------------------------------}
procedure TCustomImageList.Draw(Canvas: TCanvas; X, Y, Index: Integer;
  Enabled: Boolean);
var
  aBitmap: TBitmap;
begin
  if (FCount = 0) or (Index >= FCount) then Exit;
  aBitmap := TBitmap(FImageList[Index]);
  Canvas.Draw(X,Y,aBitmap);
end;

{------------------------------------------------------------------------------
  Method:  TCustomImageList.EndUpdate
  Params:  none
  Returns: Nothing

  Decrements te update lock. When zero, changes are notified when necesary
 ------------------------------------------------------------------------------}
procedure TCustomImageList.EndUpdate;
begin
  if FUpdateCount<=0 then
    RaiseGDBException('');
  dec(FUpdateCount);
  Change;
end;

{------------------------------------------------------------------------------
  Method:  TCustomImageList.GetBitmap
  Params:  Index: the index of the requested image
           Image: a bitmap as a container for the bitmap
  Returns: Nothing

  Creates a copy of the index'th image.
 ------------------------------------------------------------------------------}
procedure TCustomImageList.GetBitmap(Index: Integer; Image: TBitmap);
begin
  if (FCount = 0) or (Image = nil) then Exit; 
  //DebugLn('TCustomImageList.GetBitmap Index=',Index,' Image=',DbgS(Image),' Bitmap=',DbgS(FImageList.Items[Index]));
  Image.Assign(TBitMap(FImageList.Items[Index]));
end;

{------------------------------------------------------------------------------
  procedure TCustomImageList.GetInternalImage(Index: integer; var Image,
    Mask: TBitmap);

  Returns the bitmaps of the n-th image. The Imagelist can combine several
  images into one bitmap (plus one mask), therefore ImageRect contains the
  bounds of the n-th image on the bitmap.
 ------------------------------------------------------------------------------}
procedure TCustomImageList.GetInternalImage(Index: integer; var Image,
  Mask: TBitmap; var ImageRect: TRect);
begin
  Image:=TBitmap(FImageList[Index]);
  Mask:=TBitmap(FMaskList[Index]);
  ImageRect:=Rect(0,0,Image.Width,Image.Height);
end;

{------------------------------------------------------------------------------
  Function: TCustomImageList.GetHotspot
  Params:   None
  Returns:  The co-ordinates for the hotspot of the drag image

  Returns the co-ordinates for the hotspot of the drag image.
 ------------------------------------------------------------------------------}
function TCustomImageList.GetHotSpot: TPoint;
begin
  Result := Point(0, 0);
end;

{------------------------------------------------------------------------------
  Method:  TCustomImageList.GetIcon
  Params:  Index: the index of the requested image
           Image: an icon as a container for the bitmap
  Returns: Nothing

  Fetches the index'th image into an icon.
 ------------------------------------------------------------------------------}
procedure TCustomImageList.GetIcon(Index: Integer; Image: TIcon);
begin
  if (Index < 0) or (Index >= FCount)
  then raise EInvalidOperation.Create(SInvalidIndex);

  //No Icon Support yet

end;

{------------------------------------------------------------------------------
  Method:  TCustomImageList.GetImages
  Params:  Index: the index of the requested image
           Image: a bitmap as a container for the bitmap
           Mask:  a bitmap as a container for the mask
  Returns: Nothing

  Fetches the index'th image and mask into a bitmap.
 ------------------------------------------------------------------------------}
procedure TCustomImageList.GetImages(Index: Integer; const Image, Mask: TBitmap);
begin
  with Image do FBitmap.Canvas.CopyRect(
    Rect(0, 0, Width, Height),
    Canvas,
    Rect(0, Index * FHeight, FWidth, (Index + 1) * FHeight)
  );
  with Mask do FMaskBitmap.Canvas.CopyRect(
    Rect(0, 0, Width, Height),
    Canvas,
    Rect(0, Index * FHeight, FWidth, (Index + 1) * FHeight)
  );
end;

{------------------------------------------------------------------------------
  Function: TCustomImageList.HandleAllocated
  Params:   None
  Returns:  True if a handle is allocated

  This function checks if the internal image is allocated
 ------------------------------------------------------------------------------}
function TCustomImageList.HandleAllocated: Boolean;
begin
  Result := (FBitmap <> nil);
end;

{------------------------------------------------------------------------------
  Method:  TCustomImageList.Initialize
  Params:  None
  Returns: Nothing

  Initializes the internal bitmap structures and the changelink list. 
  It is used by the Create and CreateSize constructors
 ------------------------------------------------------------------------------}
procedure TCustomImageList.Initialize;
begin
  FChangeLinkList := TList.Create;
  FAllocBy := 4;
  FAllocCount := 0;
  FBlendColor := clNone;
  FBkColor := clNone;

  if (Height < 1) or (Height > 32768) or (Width < 1) 
  then raise EInvalidOperation.Create(SInvalidImageSize);

  FBitmap := TBitmap.Create;
  FBitmap.Height := Height;
  FBitmap.Width := Width;
  FMaskBitmap := TBitmap.Create;
  with FMaskBitmap do
  begin
    Height := Height;
    Width := Width;
    Canvas.Brush.Color := clWhite;
    Monochrome := True;
  end;
end;

procedure TCustomImageList.SetWidthHeight(NewWidth, NewHeight: integer);
begin
  if (FHeight=NewHeight) and (FWidth=NewWidth) then exit;
  FHeight := NewHeight;
  FWidth := NewWidth;
  FBitMap.Width := 0;
  FBitMap.Height := 0;
  AllocBitmap(0);
  Clear;
end;

{------------------------------------------------------------------------------
  Method:  TCustomImageList.Insert
  Params:  Index: the index of the inserted image
           Image: a bitmap image
           Mask: a bitmap which defines the transparent parts of Image
  Returns: Nothing

  Inserts one or more (bitmap width / imagelist width) bitmaps into the list 
  at the index'th position.  If Mask is nil, the image has no transparent parts.
 ------------------------------------------------------------------------------}
procedure TCustomImageList.Insert(Index: Integer; Image, Mask: TBitmap);
begin
  if (Index > Count)
  then raise EInvalidOperation.Create(SInvalidIndex);

  if (Index < 0) then Index := 0;

  if (Image <> nil)
  then begin
    FImageList.Insert(Index,Image);
    FMaskList.Insert(Index,Mask);
    FCount := FImageList.Count;
    FChanged := true;
    Change;
  end;
end;

{------------------------------------------------------------------------------
  Method:  TCustomImageList.InsertIcon
  Params:  Index: the index of the inserted image
           Image: the Icon to be inserted
  Returns: Nothing

  Inserts an icon into the list at the index'th position.
 ------------------------------------------------------------------------------}
procedure TCustomImageList.InsertIcon(Index: Integer; Image: TIcon);
begin
  if (Index > FCount)
  then raise EInvalidOperation.Create(SInvalidIndex);

  if (Index < 0) then Index := 0;
  
  //No Icon Support yet

end;

{------------------------------------------------------------------------------
  Method:  TCustomImageList.InsertMasked
  Params:  Index: the index of the inserted image
           Image: A bitmap to be inserted
           MaskColor: The color acting as transparant color
  Returns: Nothing

  Adds one or more (bitmap width / imagelist width) bitmaps to the list. 
  Every occurance of MaskColor will be converted to transparent.
 ------------------------------------------------------------------------------}
procedure TCustomImageList.InsertMasked(Index: Integer; Image: TBitmap;
  MaskColor: TColor);
var
  Mask: TBitmap;
begin
  Mask := TBitmap.Create;
  with Mask do
  begin
    Height := Image.Height;
    Width := Image.Width;
    Assign(Image);
    Mask(MaskColor);
  end;
  Insert(Index, Image, Mask);
end;

{------------------------------------------------------------------------------
  Method:  TCustomImageList.Move
  Params:  CurIndex: the index of the image to be moved
           NewIndex: the new index of the image
  Returns: Nothing

  Moves an image from the CurIndex'th location to NewIndex'th location
 ------------------------------------------------------------------------------}
procedure TCustomImageList.Move(CurIndex, NewIndex: Integer);
begin
  if CurIndex <> NewIndex then begin
    FImageList.Move(CurIndex,NewIndex);
    FMaskList.Move(CurIndex,NewIndex);
    FChanged := true;
    Change;
  end;
end;

{------------------------------------------------------------------------------
  Method:  TCustomImageList.NotifyChangeLink
  Params:  None
  Returns: Nothing

  Internal function to notify the subscribed objects of a change 
  of the imagelist.
 ------------------------------------------------------------------------------}
procedure TCustomImageList.NotifyChangeLink;
var
  nIndex: Integer;
begin
  if FChangeLinkList <> nil then
    with FChangeLinkList do
      for nIndex := 0 to Count - 1 do TChangeLink(Items[nIndex]).Change
end;

{------------------------------------------------------------------------------
  Method:  TCustomImageList.WriteData
  Params:  AStream: The stream to write the data to
  Returns: Nothing

  Writes the imagelist data to stream
 ------------------------------------------------------------------------------}
procedure TCustomImageList.WriteData(AStream: TStream);
var
  CurImage: TBitMap;
  i: Integer;
  Signature: TImageListSignature;
begin
  //Write signature
  Signature:=SIG_LAZ2;
  AStream.Write(Signature,SizeOf(Signature));

  //Count of image
  WriteLRSInteger(AStream,Count);
  WriteLRSInteger(AStream,Width);
  WriteLRSInteger(AStream,Height);

  for i:=0 to Count-1 do
  begin
    CurImage:=TBitmap(FImageList[i]);
    //DebugLn('TCustomImageList.WriteData Position=',AStream.Position,' ',CurImage.Width,',',CurImage.Height);
    CurImage.WriteNativeStream(AStream,true,bnXPixmap);
  end;
end;

{------------------------------------------------------------------------------
  Method:  TCustomImageList.ReadData
  Params:  AStream: The stream to read the data from
  Returns: Nothing

  Reads the imagelist data from stream
 ------------------------------------------------------------------------------}
procedure TCustomImageList.ReadData(AStream: TStream);
var
  Signature: TImageListSignature;
  StreamPos: TStreamSeekType;

  procedure DoReadLaz1;
  var
    i, NewCount, Size: Integer;
    bmp: TBitmap;
  begin
    //DebugLn('TCustomImageList.ReadData DoReadLaz1');
    // provided for compatability for earlier lazarus streams
    NewCount := AStream.ReadWord;
    //DebugLn('TCustomImageList.ReadData DoReadLaz1 NewCount=',NewCount);
    for i := 0 to NewCount - 1 do
    begin
      bmp := TBitMap.Create;
      Size:=ReadLRSInteger(AStream);
      bmp.ReadStream(AStream, True, Size);
      bmp.Transparent := True;
      AddDirect(bmp, nil);
    end;
  end;

  procedure DoReadLaz2;
  var
    i, NewCount, Size: cardinal;
    bmp: TBitmap;
  begin
    //DebugLn('TCustomImageList.ReadData DoReadLaz2');
    NewCount := ReadLRSCardinal(AStream);
    Width := ReadLRSCardinal(AStream);
    Height := ReadLRSCardinal(AStream);
    //DebugLn('TCustomImageList.ReadData DoReadLaz2 NewCount=',NewCount,' Width=',Width,' Height=',Height);
    for i := 0 to NewCount - 1 do
    begin
      bmp := TBitMap.Create;
      //DebugLn('TCustomImageList.ReadData DoReadLaz2 i=',i,' ',AStream.Position);
      Size:=ReadLRSCardinal(AStream);
      //DebugLn('TCustomImageList.ReadData DoReadLaz2 Size=',Size,' ',AStream.Position);
      bmp.ReadStream(AStream, True, Size);
      AddDirect(bmp, nil);
    end;
  end;

  procedure CreateImagesFromRawImage(IntfImage: TLazIntfImage;
    NewCount: integer);
  var
    RawImage, SubRawImage: TRawImage;
    ImgHandle, MaskHandle: HBitmap;
    Img: TBitmap;
    Row: Integer;
    Col: Integer;
    ImgRect: TRect;
  begin
    BeginUpdate;
    IntfImage.GetRawImage(RawImage);
    FillChar(SubRawImage,SizeOf(SubRawImage),0);
    //NewCount:=2;
    try
      for Row := 0 to (IntfImage.Height div Height) - 1 do
      begin
        if NewCount <= 0 then Break;
        for Col := 0 to (IntfImage.Width div Width) - 1 do
        begin
          if NewCount <= 0 then Break;

          ImgRect:=Bounds(Col*Width,Row*Height,Width,Height);
          ExtractRawImageRect(@RawImage,ImgRect,@SubRawImage);
          if not CreateBitmapFromRawImage(SubRawImage,ImgHandle,MaskHandle,
            false)
          then
            raise EInvalidGraphicOperation.Create('TCustomImageList.CreateImagesFromRawImage Create bitmaps');
          //DebugLn('CreateImagesFromRawImage A ',DbgS(SubRawImage.Data),' ',SubRawImage.DataSize);
          FreeRawImageData(@SubRawImage);
          Img := TBitmap.Create;
          Img.Handle:=ImgHandle;
          Img.MaskHandle:=MaskHandle;

          AddDirect(Img, nil);
          //DebugLn('CreateImagesFromRawImage B ',Img.Width,',',Img.Height,' ',Count);
          Img := nil;
          Dec(NewCount);
        end;
      end;
    finally
      FreeRawImageData(@SubRawImage);
      EndUpdate;
    end;
  end;
  
  procedure ReadDelphiImageAndMask(HasMask: boolean; NewCount: integer);
  var
    IntfImage: TLazIntfImage;
    ImgReader: TFPReaderBMP;
    MaskIntfImage: TLazIntfImageMask;
  begin
    IntfImage:=nil;
    MaskIntfImage:=nil;
    ImgReader:=nil;
    try
      IntfImage:=TLazIntfImage.Create(0,0);
      IntfImage.GetDescriptionFromDevice(0);
      // read the image bmp stream into the IntfImage
      ImgReader:=TFPReaderBMP.Create;
      IntfImage.LoadFromStream(AStream,ImgReader);
      if HasMask then begin
        // create the mask bmp directly into the RawImage
        MaskIntfImage:=TLazIntfImageMask.CreateWithImage(IntfImage);
        MaskIntfImage.LoadFromStream(AStream,ImgReader);
      end;

      CreateImagesFromRawImage(IntfImage,NewCount);
    finally
      // clean up
      ImgReader.Free;
      IntfImage.Free;
      MaskIntfImage.Free;
    end;
  end;
  
  {$IFDEF SaveDelphiImgListStream}
  procedure SaveImgListStreamToFile;
  var
    CurStreamPos: TStreamSeekType;
    fs: TFileStream;
    i: Integer;
    Filename: string;
  begin
    i:=0;
    repeat
      inc(i);
      Filename:='TCustomImageList'+IntToStr(i)+'.stream';
    until not FileExists(Filename);
    CurStreamPos := AStream.Position;
    DebugLn('TCustomImageList.ReadData Saving stream to ',Filename);
    fs:=TFileStream.Create(Filename,fmCreate);
    AStream.Position:=StreamPos;
    fs.CopyFrom(AStream,AStream.Size-AStream.Position);
    fs.Free;
    AStream.Position:=CurStreamPos;
  end;
  {$ENDIF}
  
var
  HasMask: Boolean;
  NewCount: Integer;
  Size: integer;
begin
  Clear;

  StreamPos := AStream.Position;                // check stream signature
  AStream.Read(Signature, SizeOf(Signature));

  if Signature = SIG_LAZ1
  then begin
    DoReadLaz1;
    Exit;
  end;

  if Signature = SIG_LAZ2
  then begin
    DoReadLaz2;
    Exit;
  end;

  // Delphi streams

  {$IFDEF SaveDelphiImgListStream}
  SaveImgListStreamToFile;
  {$ENDIF}

  if Signature = SIG_D3
  then begin
    AStream.ReadWord; //Skip ?
    NewCount := ReadLRSWord(AStream);
    //DebugLn('NewCount=',NewCount);
    AStream.ReadWord; //Skip Capacity
    AStream.ReadWord; //Skip Grow
    FWidth := ReadLRSWord(AStream);
    //DebugLn('NewWidth=',FWidth);
    FHeight := ReadLRSWord(AStream);
    //DebugLn('NewHeight=',FHeight);
    FBKColor := TColor(ReadLRSInteger(AStream));
    HasMask := (ReadLRSWord(AStream) and 1) = 1;
    AStream.ReadDWord; //Skip ?
    AStream.ReadDWord; //Skip ?

    ReadDelphiImageAndMask(HasMask,NewCount);
  end
  else begin
    // D2 has no signature, so restore original position
    AStream.Position := StreamPos;
    Size:=ReadLRSInteger(AStream);
    NewCount:=ReadLRSInteger(AStream);

    ReadDelphiImageAndMask(false,NewCount);
    AStream.Position := StreamPos+Size;
  end;
end;

{------------------------------------------------------------------------------
  Method:  TCustomImageList.RegisterChanges
  Params:  Value: a reference to changelink object
  Returns: Nothing

  Registers an object to get notified of a change of the imagelist.
 ------------------------------------------------------------------------------}
procedure TCustomImageList.RegisterChanges(Value: TChangeLink);
begin
  if (Value <> nil) and (FChangeLinkList.IndexOf(Value) = -1)
  then begin
    Value.Sender := Self;
    FChangeLinkList.Add(Value);
  end;
end;

{------------------------------------------------------------------------------
  Method:  TCustomImageList.Replace
  Params:  Index: the index of the replaceded image
           Image: a bitmap image
           Mask: a bitmap which defines the transparent parts of Image
  Returns: Nothing.

  Replaces the index'th image with the image given. If Mask is nil, 
  the image has no transparent parts.
 ------------------------------------------------------------------------------}
procedure TCustomImageList.Replace(Index: Integer; Image, Mask: TBitmap);
var
  DestinationRect, SourceRect: TRect;
begin
  if (Index >= FCount)
  then raise EInvalidOperation.Create(SInvalidIndex);

  if (Index < 0) then Index := 0;

  DestinationRect := Rect(0, Index * FHeight, FWidth, (Index + 1) * FHeight);
  SourceRect := Rect(0, 0, FWidth, FHeight);

  CopyImage(FBitmap.Canvas, Image.Canvas, DestinationRect, SourceRect);
  if Mask <> nil
  then CopyImage(FMaskBitmap.Canvas, Mask.Canvas, DestinationRect, SourceRect)
  else FMaskBitmap.Canvas.FillRect(DestinationRect);

  FChanged := true;
  Change;
end;

{------------------------------------------------------------------------------
  Method:  TCustomImageList.Replace
  Params:  Index: the index of the replaceded image
           Image: an icon image
  Returns: Nothing.

  Replaces the index'th image with the image given.
 ------------------------------------------------------------------------------}
procedure TCustomImageList.ReplaceIcon(Index: Integer; Image: TIcon);
begin
  if (Index > FCount)
  then raise EInvalidOperation.Create(SInvalidIndex);

  if (Index < 0) then Index := 0;

  // No Icon suppport yet
end;

{------------------------------------------------------------------------------
  Method:  TCustomImageList.ReplaceMasked
  Params:  Index: the index of the replaceded image
           Image: A bitmap image
           MaskColor: The color acting as transparant color
  Returns: Nothing

  Replaces the index'th image with the image given.
  Every occurance of MaskColor will be converted to transparent.
 ------------------------------------------------------------------------------}
procedure TCustomImageList.ReplaceMasked(Index: Integer; NewImage: TBitmap; MaskColor: TColor);
begin
  if (Index >= FCount)
  then raise EInvalidOperation.Create(SInvalidIndex);

  if (Index < 0) then Index := 0;

end;

{------------------------------------------------------------------------------
  Method:  TCustomImageList.SetBkColor
  Params:  Value: The background color
  Returns: Nothing

  Sets the backgroundcolor for the transparen parts.
 ------------------------------------------------------------------------------}
procedure TCustomImageList.SetBkColor(const Value: TColor);
begin
  if FBkColor <> Value
  then begin
    FBkColor := Value;
    FChanged := true;
    Change;
  end;
end;

procedure TCustomImageList.SetDrawingStyle(const AValue: TDrawingStyle);
begin
  if FDrawingStyle=AValue then exit;
  FDrawingStyle:=AValue;
end;

{------------------------------------------------------------------------------
  Method:  TCustomImageList.SetHeight
  Params:  Value: the height of an image
  Returns: Nothing

  Sets the height of an image. If the height differs from the original height,
  the list contents wil be deleted.
 ------------------------------------------------------------------------------}
procedure TCustomImageList.SetHeight(const Value: Integer);
begin
  SetWidthHeight(Width,Value);
end;

procedure TCustomImageList.SetMasked(const AValue: boolean);
begin
  if FMasked=AValue then exit;
  FMasked:=AValue;
end;

procedure TCustomImageList.SetShareImages(const AValue: Boolean);
begin
  if FShareImages=AValue then exit;
  FShareImages:=AValue;
end;

{------------------------------------------------------------------------------
  Method:  TCustomImageList.SetWidth
  Params:  Value: the width of an image
  Returns: Nothing

  Sets the width of an image. If the width differs from the original width,
  the list contents wil be deleted.
 ------------------------------------------------------------------------------}
procedure TCustomImageList.SetWidth(const Value: Integer);
begin
  SetWidthHeight(Value,Height);
end;

{------------------------------------------------------------------------------
  Method:  TCustomImageList.ShiftImages
  Params:  Source: source canvas on which the images are moved
           Start: start of the image to shift 
           Shift: number of images to shift
  Returns: Nothing

  Internal routine to move images on the internal image list.
 ------------------------------------------------------------------------------}
procedure TCustomImageList.ShiftImages(const Source: TCanvas;
  Start, Shift: Integer);
var
  FMoveBitmap: TBitmap;
begin
  try
    FMoveBitmap := TBitmap.Create;
    with FMoveBitmap do
    begin
      Width := FWidth;
      Height := (1 + FCount - Start) * FHeight;
    end;
    FMoveBitmap.Canvas.CopyRect(
      Rect(0, 0, FWidth, FMoveBitmap.Height),
      Source,
      Rect(0, Start * FHeight, FWidth, (FCount + 1) * FHeight)
    );
    Source.CopyRect(
      Rect(0, (Start + Shift) * FHeight, FWidth, (FCount + Shift + 1) * FHeight),
      FMoveBitmap.Canvas,
      Rect(0, 0, FWidth, FMoveBitmap.Height)
    );
  finally
    FMoveBitmap.Free;
  end;
end;

{------------------------------------------------------------------------------
  Method:  TCustomImageList.UnRegisterChanges
  Params:  Value: a reference to changelink object
  Returns: Nothing

  Unregisters an object for notifications.
 ------------------------------------------------------------------------------}
procedure TCustomImageList.UnRegisterChanges(Value: TChangeLink);
begin
  if (FChangeLinkList<>nil) and (Value.Sender=Self) then
    FChangeLinkList.Remove(Value);
  Value.Sender:=nil;
end;

{******************************************************************************
                                  TChangeLink
 ******************************************************************************}

{------------------------------------------------------------------------------
  Method:  TChangeLink.Change
  Params:  None
  Returns: Nothing

  Fires the OnChange event.
 ------------------------------------------------------------------------------}
procedure TChangeLink.Change;
begin
  if Assigned(FOnChange) then FOnChange(Sender)
end;

{------------------------------------------------------------------------------
  Method: TChangeLink.Destroy
  Params:  None
  Returns: Nothing

  Destructor for the class.
 ------------------------------------------------------------------------------}
destructor TChangeLink.Destroy;
begin
  if Sender <> nil 
  then Sender.UnRegisterChanges(Self);
  inherited Destroy;
end;

// included by imglist.pp