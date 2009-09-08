{ Example designer for the Lazarus IDE

  Copyright (C) 2009 Mattias Gaertner mattias@freepascal.org

  This library is free software; you can redistribute it and/or modify it
  under the terms of the GNU Library General Public License as published by
  the Free Software Foundation; either version 2 of the License, or (at your
  option) any later version with the following modification:

  As a special exception, the copyright holders of this library give you
  permission to link this library with independent modules to produce an
  executable, regardless of the license terms of these independent modules,and
  to copy and distribute the resulting executable under terms of your choice,
  provided that you also meet, for each linked independent module, the terms
  and conditions of the license of that module. An independent module is a
  module which is not derived from or based on this library. If you modify
  this library, you may extend this exception to your version of the library,
  but you are not obligated to do so. If you do not wish to do so, delete this
  exception statement from your version.

  This program is distributed in the hope that it will be useful, but WITHOUT
  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
  FITNESS FOR A PARTICULAR PURPOSE. See the GNU Library General Public License
  for more details.

  You should have received a copy of the GNU Library General Public License
  along with this library; if not, write to the Free Software Foundation,
  Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
}

unit MyWidgetDesigner;

{$mode objfpc}{$H+}

interface

uses
  LCLProc, LCLType, Classes, SysUtils, FormEditingIntf, LCLIntf, Graphics,
  MyWidgetSet;

type

  { TMyWidgetMediator }

  TMyWidgetMediator = class(TDesignerMediator,IMyWidgetDesigner)
  private
    FMyForm: TMyForm;
  public
    // needed by the lazarus form editor
    class function CreateMediator(TheOwner, aForm: TComponent): TDesignerMediator;
      override;
    class function FormClass: TComponentClass; override;
    procedure GetBounds(AComponent: TComponent; out CurBounds: TRect); override;
    procedure SetBounds(AComponent: TComponent; NewBounds: TRect); override;
    procedure Paint(aRect: TRect); override;
  public
    // needed by TMyWidget
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure InvalidateRect(Sender: TObject; ARect: TRect; Erase: boolean);
    property MyForm: TMyForm read FMyForm;
  end;

procedure Register;

implementation

procedure Register;
begin
  FormEditingHook.RegisterDesignerMediator(TMyWidgetMediator);
end;

{ TMyWidgetMediator }

constructor TMyWidgetMediator.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
end;

destructor TMyWidgetMediator.Destroy;
begin
  inherited Destroy;
end;

class function TMyWidgetMediator.CreateMediator(TheOwner, aForm: TComponent
  ): TDesignerMediator;
begin
  Result:=TMyWidgetMediator.Create(TheOwner);
  TMyWidgetMediator(Result).FMyForm:=aForm as TMyForm;
end;

class function TMyWidgetMediator.FormClass: TComponentClass;
begin
  Result:=TMyForm;
end;

procedure TMyWidgetMediator.GetBounds(AComponent: TComponent; out
  CurBounds: TRect);
var
  w: TMyWidget;
begin
  if AComponent is TMyWidget then begin
    w:=TMyWidget(AComponent);
    CurBounds:=Bounds(w.Left,w.Top,w.Width,w.Height);
  end;
end;

procedure TMyWidgetMediator.InvalidateRect(Sender: TObject; ARect: TRect;
  Erase: boolean);
begin
  if (LCLForm=nil) or (not LCLForm.HandleAllocated) then exit;
  LCLIntf.InvalidateRect(LCLForm.Handle,@ARect,Erase);
end;

procedure TMyWidgetMediator.SetBounds(AComponent: TComponent; NewBounds: TRect
  );
begin
  if AComponent is TMyWidget then
    TMyWidget(AComponent).SetBounds(NewBounds.Left,NewBounds.Top,
      NewBounds.Right-NewBounds.Left,NewBounds.Bottom-NewBounds.Top);
end;

procedure TMyWidgetMediator.Paint(aRect: TRect);

  procedure PaintWidget(AWidget: TMyWidget);
  var
    i: Integer;
    DC: LongInt;
    SavedDC: LongInt;
    Child: TMyWidget;
    SavedDC2: LongInt;
  begin
    with LCLForm.Canvas do begin
      // fill background
      Brush.Style:=bsSolid;
      Brush.Color:=clLtGray;
      FillRect(0,0,AWidget.Width,AWidget.Height);
      // outer frame
      Pen.Color:=clRed;
      Rectangle(0,0,AWidget.Width,AWidget.Height);
      // inner frame
      Pen.Color:=clMaroon;
      Rectangle(AWidget.BorderLeft,AWidget.BorderTop,
                AWidget.Width-AWidget.BorderRight,
                AWidget.Height-AWidget.BorderBottom);
      // caption
      TextOut(5,2,AWidget.Caption);
      // childs
      DC:=Handle;
      if AWidget.ChildCount>0 then begin
        SavedDC:=SaveDC(DC);
        // clip client area
        MoveWindowOrgEx(DC,AWidget.BorderLeft,AWidget.BorderTop);
        if IntersectClipRect(DC, 0, 0, AWidget.Width-AWidget.BorderLeft-AWidget.BorderRight,
                             AWidget.Height-AWidget.BorderTop-AWidget.BorderBottom)<>NullRegion
        then begin
          for i:=0 to AWidget.ChildCount-1 do begin
            SavedDC2:=SaveDC(DC);
            Child:=AWidget.Childs[i];
            // clip child area
            MoveWindowOrgEx(DC,Child.Left,Child.Top);
            if IntersectClipRect(DC,0,0,Child.Width,Child.Height)<>NullRegion then
              PaintWidget(Child);
            RestoreDC(DC,SavedDC2);
          end;
        end;
        RestoreDC(DC,SavedDC);
      end;
    end;
  end;

begin
  //debugln(['TMyWidgetMediator.Paint ',dbgs(aRect)]);
  PaintWidget(MyForm);
  inherited Paint(aRect);
end;

end.

