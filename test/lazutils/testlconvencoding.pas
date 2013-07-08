{
 Test all with:
     ./runtests --format=plain --suite=TTestLConvEncoding

 Test specific with:
     ./runtests --format=plain --suite=Test_CP_UTF8_CP
}
unit TestLConvEncoding;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, LConvEncoding, LazLogger, testglobals, LCLProc;

type

  { TTestLConvEncoding }

  TTestLConvEncoding = class(TTestCase)
  public
  published
    procedure Test_CP_UTF8_CP;
  end;

implementation

{ TTestLConvEncoding }

procedure TTestLConvEncoding.Test_CP_UTF8_CP;

  procedure Test(CodePageName: string; const CP2UTF8,UTF82CP: TConvertEncodingFunction);
  var
    c: Char;
    AsUTF8, Back: string;
    l: integer;
  begin
    for c:=#1 to High(Char) do begin
      AsUTF8:=CP2UTF8(c);
      if AsUTF8='' then
        AssertEquals('CodePage '+CodePageName+' to UTF8 creates empty string for character #'+IntToStr(ord(c)),true,false);
      Back:=UTF82CP(AsUTF8);
      if Back<>c then
        AssertEquals('CodePage '+CodePageName+' ('+IntToStr(ord(c))+') to UTF8 ('+dbgs(UTF8CharacterToUnicode(PChar(AsUTF8),l))+') and back differ for character #'+IntToStr(ord(c)),DbgStr(c),dbgstr(Back));
    end;
  end;

begin
  Test('1250',@CP1250ToUTF8,@UTF8ToCP1250);
  Test('1251',@CP1251ToUTF8,@UTF8ToCP1251);
  Test('866',@CP866ToUTF8,@UTF8ToCP866);
end;

initialization
  AddToLazUtilsTestSuite(TTestLConvEncoding);

end.

