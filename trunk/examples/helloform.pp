unit helloform;

{$mode objfpc}
{$H+}

interface

uses classes, forms, buttons;

type
   THello = class(TForm)
   private
   protected
   public
      button1 : TButton;
      constructor Create(AOwner: TComponent); override;
      procedure button1Click(Sender : TObject);
      procedure FormDestroy(Sender : TObject);
   end;

var
   Hello : THello;

implementation

constructor THello.Create(AOwner: TComponent);
begin
   inherited Create(AOwner);
   Caption := 'Hello World';
   Width := 200;
   Height := 75;
   Left := 200;
   Top := 200;

//   OnDestroy := @FormDestroy;

   button1 := TButton.Create(Self);
   button1.OnClick := @button1click;
   button1.Parent := Self;
   button1.left := (width - 75) div 2 ;
   button1.top := (height - 32) div 2;
   button1.width := 75;
   button1.height := 32;
   button1.caption := 'Close';
   button1.Show;
end;

procedure THello.FormDestroy(Sender : TObject);
begin
//   Application.Terminate;
end;

procedure THello.button1Click(Sender : TObject);
begin
//   Application.Terminate;
close;
end;

end.

{ =============================================================================

  $Log$
  Revision 1.1  2000/07/13 10:28:20  michael
  + Initial import

  Revision 1.5  1999/12/10 00:47:00  lazarus
  MWE:
    Fixed some samples
    Fixed Dialog parent is no longer needed
    Fixed (Win)Control Destruction
    Fixed MenuClick


}
