unit mainform; 

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs,
  LCLProc;

type

  { TSubControl }

  TSubControl = class(TCustomControl)
  public
    procedure MouseDown(Button: TMouseButton; Shift:TShiftState; X,Y:Integer); override;
    procedure MouseMove(Shift: TShiftState; X,Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift:TShiftState; X,Y:Integer); override;
 {   procedure MouseEnter; virtual;
    procedure MouseLeave; virtual;}
    procedure Paint; override;
  end;

  { TForm1 }

  TForm1 = class(TForm)
    procedure FormClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure FormPaint(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
    SubControl: TSubControl;
    ClickCounter: Integer;
  end; 

var
  Form1: TForm1; 

implementation

{ TSubControl }

procedure TSubControl.MouseDown(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
begin
  DebugLn('TSubControl.MouseDown');
end;

procedure TSubControl.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  DebugLn('TSubControl.MouseMove');
end;

procedure TSubControl.MouseUp(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
begin
  DebugLn('TSubControl.MouseUp');
end;

procedure TSubControl.Paint;
begin
  Canvas.Brush.Color := clBlue;
  Canvas.Rectangle(0, 0, Width, Height);
end;

{$R *.lfm}

{ TForm1 }

procedure TForm1.FormClick(Sender: TObject);
begin
  DebugLn(Format('Form click #%d', [ClickCounter]));
  Inc(ClickCounter);
//  Invalidate;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  SubControl := TSubControl.Create(Self);
  SubControl.Left := 100;
  SubControl.Top := 100;
  SubControl.Width := 100;
  SubControl.Height := 100;
  SubControl.Parent := Self;
end;

procedure TForm1.FormMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
  DebugLn(Format('MouseMove x=%d y=%d', [x, y]));
end;

procedure TForm1.FormPaint(Sender: TObject);
begin
//  Canvas.Brush.Color := clWhite;
//  Canvas.Rectangle(0, 0, Width, Height);
  Canvas.Brush.Color := clRed;//RGBToColor(255-ClickCounter, 0, 0);
  Canvas.Rectangle(10, 10, 100, 100);
  Canvas.Brush.Color := clGreen;
  Canvas.Rectangle(100, 100, 200, 200);
  Canvas.Brush.Color := clBlue;
  Canvas.Rectangle(200, 200, 300, 300);
end;

end.

