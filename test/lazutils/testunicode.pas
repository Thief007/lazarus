program TestUnicode;

{$mode objfpc}{$H+}

uses
  sysutils, lazutf8;

procedure WriteStringHex(Str: utf8string);
var
  StrOut: utf8string;
  i: Integer;
begin
  StrOut := '';
  for i := 1 to Length(Str) do
  begin
    StrOut := StrOut + IntToHex(Byte(Str[i]), 2) + ' ';
  end;
  Write(StrOut);
end;

procedure AssertStringOperation(AMsg, AStr1, AStr2, AStrExpected2: utf8string);
begin
  Write(AMsg, ' ', AStr1, ' => ', AStr2);
  if UTF8CompareStr(AStr2, AStrExpected2) <> 0 then
  begin
    Write(' Expected ', AStrExpected2, ' !Error!');
    WriteLn();
    Write('Got      Len=', Length(AStr2),' ');
    WriteStringHex(AStr2);
    WriteLn('');
    Write('Expected Len=', Length(AStrExpected2),' ');
    WriteStringHex(AStrExpected2);
    WriteLn();
  end;
  WriteLn();
end;

procedure AssertStringOperationUTF8UpperCase(AMsg, ALocale, AStr1, AStrExpected2: utf8string);
begin
  AssertStringOperation(AMsg, AStr1, UTF8UpperCase(AStr1, ALocale), AStrExpected2);
end;

procedure AssertStringOperationUTF8LowerCase(AMsg, ALocale, AStr1, AStrExpected2: utf8string);
begin
  AssertStringOperation(AMsg, AStr1, UTF8LowerCase(AStr1, ALocale), AStrExpected2);
end;

function DateTimeToMilliseconds(aDateTime: TDateTime): Int64;
var
  TimeStamp: TTimeStamp;
begin
  {Call DateTimeToTimeStamp to convert DateTime to TimeStamp:}
  TimeStamp:= DateTimeToTimeStamp (aDateTime);
  {Multiply and add to complete the conversion:}
  Result:= TimeStamp.Time;
end;

procedure TestUTF8UpperCase;
var
  lStartTime, lTimeDiff: TDateTime;
  Str: UTF8String;
  i: Integer;
begin
  // ASCII
  AssertStringOperationUTF8UpperCase('ASCII UTF8UpperCase', '', 'abcdefghijklmnopqrstuwvxyz', 'ABCDEFGHIJKLMNOPQRSTUWVXYZ');
  // Latin
  AssertStringOperationUTF8UpperCase('Polish UTF8UpperCase 1', '', 'aąbcćdeęfghijklłmnńoóprsśtuwyzźż', 'AĄBCĆDEĘFGHIJKLŁMNŃOÓPRSŚTUWYZŹŻ');
  AssertStringOperationUTF8UpperCase('Polish UTF8UpperCase 2', '', 'AĄBCĆDEĘFGHIJKLŁMNŃOÓPRSŚTUWYZŹŻ', 'AĄBCĆDEĘFGHIJKLŁMNŃOÓPRSŚTUWYZŹŻ');
  // Turkish
  AssertStringOperationUTF8UpperCase('Turkish UTF8UpperCase 1', 'tu', 'abcçdefgğhıijklmnoöprsştuüvyz', 'ABCÇDEFGĞHIİJKLMNOÖPRSŞTUÜVYZ');
  AssertStringOperationUTF8UpperCase('Turkish UTF8UpperCase 2', 'tu', 'ABCÇDEFGĞHIİJKLMNOÖPRSŞTUÜVYZ', 'ABCÇDEFGĞHIİJKLMNOÖPRSŞTUÜVYZ');

  // Performance test
  lStartTime := Now;
  for i := 0 to 9999 do
  begin
    Str := UTF8UpperCase('ABCDEFGHIJKLMNOPQRSTUWVXYZ');
    Str := Str + UTF8UpperCase('aąbcćdeęfghijklłmnńoóprsśtuwyzźż');
    Str := Str + UTF8UpperCase('AĄBCĆDEĘFGHIJKLŁMNŃOÓPRSŚTUWYZŹŻ');
  end;
  lTimeDiff := Now - lStartTime;
  WriteLn('UpperCase Performance test took: ', DateTimeToMilliseconds(lTimeDiff), ' ms');
end;

procedure TestUTF8LowerCase;
var
  i: Integer;
  lStartTime, lTimeDiff: TDateTime;
  Str: UTF8String;
begin
  // ASCII
  AssertStringOperationUTF8LowerCase('ASCII UTF8LowerCase', '', 'ABCDEFGHIJKLMNOPQRSTUWVXYZ', 'abcdefghijklmnopqrstuwvxyz');
  // Latin
  AssertStringOperationUTF8LowerCase('Polish UTF8UpperCase 1', '', 'aąbcćdeęfghijklłmnńoóprsśtuwyzźż', 'aąbcćdeęfghijklłmnńoóprsśtuwyzźż');
  AssertStringOperationUTF8LowerCase('Polish UTF8UpperCase 2', '', 'AĄBCĆDEĘFGHIJKLŁMNŃOÓPRSŚTUWYZŹŻ', 'aąbcćdeęfghijklłmnńoóprsśtuwyzźż');
  // Turkish
  AssertStringOperationUTF8LowerCase('Turkish UTF8UpperCase 1', 'tu', 'abcçdefgğhıijklmnoöprsştuüvyz', 'abcçdefgğhıijklmnoöprsştuüvyz');
  AssertStringOperationUTF8LowerCase('Turkish UTF8UpperCase 2', 'tu', 'ABCÇDEFGĞHIİJKLMNOÖPRSŞTUÜVYZ', 'abcçdefgğhıijklmnoöprsştuüvyz');

  // Performance test
  lStartTime := Now;
  for i := 0 to 9999 do
  begin
    //Str := UTF8LowerCase('abcdefghijklmnopqrstuwvxyz');
    //Str := Str + UTF8LowerCase('aąbcćdeęfghijklłmnńoóprsśtuwyzźż');
    //Str := Str + UTF8LowerCase('AĄBCĆDEĘFGHIJKLŁMNŃOÓPRSŚTUWYZŹŻ');
    Str := UTF8LowerCase('名字叫嘉英，嘉陵江的嘉，英國的英');
  end;
  lTimeDiff := Now - lStartTime;
  WriteLn('LowerCase Performance test took: ', DateTimeToMilliseconds(lTimeDiff), ' ms');
  lStartTime := Now;
  for i := 0 to 9999 do
  begin
    //Str := UTF8LowerCaseMattias('aąbcćdeęfghijklłmnńoóprsśtuwyzźż');
    //Str := Str + UTF8LowerCaseMattias('AĄBCĆDEĘFGHIJKLŁMNŃOÓPRSŚTUWYZŹŻ');
    Str := UTF8LowerCaseMattias('名字叫嘉英，嘉陵江的嘉，英國的英');
  end;
  lTimeDiff := Now - lStartTime;
  WriteLn('Mattias LowerCase Performance test took: ', DateTimeToMilliseconds(lTimeDiff), ' ms');
end;

begin
  TestUTF8UpperCase();
  TestUTF8LowerCase();
end.

