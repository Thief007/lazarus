{
 Test all with:
     ./runtests --format=plain --suite=TTestLazXML

 Test specific with:
     ./runtests --format=plain --suite=TestStrToXMLValue
     ./runtests --format=plain --suite=TestXMLValueToStr
     ./runtests --format=plain --suite=TestTranslateUTF8Chars
     ./runtests --format=plain --suite=TestXPath
}
unit TestLazXML;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testglobals, laz2_DOM, laz2_xmlutils, laz2_xpath,
  laz2_XMLRead, LazLogger;

type

  { TTestLazXML }

  TTestLazXML = class(TTestCase)
  public
  published
    procedure TestStrToXMLValue;
    procedure TestXMLValueToStr;
    procedure TestTranslateUTF8Chars;
    procedure TestXPath;
  end;

implementation

{ TTestLazXML }

procedure TTestLazXML.TestStrToXMLValue;
begin
  AssertEquals('Empty string','',StrToXMLValue(''));
  AssertEquals('Short string','a',StrToXMLValue('a'));
  AssertEquals('String with #0','',StrToXMLValue(#0));
  AssertEquals('String with &','&amp;',StrToXMLValue('&'));
  AssertEquals('String with <','&lt;',StrToXMLValue('<'));
  AssertEquals('String with >','&gt;',StrToXMLValue('>'));
  AssertEquals('String with ''','&apos;',StrToXMLValue(''''));
  AssertEquals('String with "','&quot;',StrToXMLValue('"'));
  AssertEquals('String mix 1','&lt;a&gt;&quot;',StrToXMLValue('<a>'#0'"'));
  AssertEquals('String mix 2','abc',StrToXMLValue('abc'));
end;

procedure TTestLazXML.TestXMLValueToStr;
begin
  AssertEquals('Empty string','',XMLValueToStr(''));
  AssertEquals('Short string a','a',XMLValueToStr('a'));
  AssertEquals('Short string #0',#0,XMLValueToStr(#0));
  AssertEquals('Short string abc','abc',XMLValueToStr('abc'));
  AssertEquals('String with &','&',XMLValueToStr('&amp;'));
  AssertEquals('String with <','<',XMLValueToStr('&lt;'));
  AssertEquals('String with >','>',XMLValueToStr('&gt;'));
  AssertEquals('String with ''','''',XMLValueToStr('&apos;'));
  AssertEquals('String with "','"',XMLValueToStr('&quot;'));
  AssertEquals('String mix <a>"','<a>"',XMLValueToStr('&lt;a&gt;&quot;'));
end;

procedure TTestLazXML.TestTranslateUTF8Chars;

  procedure T(Title, s, SrcChars, DstChars, Expected: string);
  var
    h: String;
  begin
    h:=s;
    TranslateUTF8Chars(h,SrcChars,DstChars);
    if h=Expected then exit;
    AssertEquals(Title+': s="'+s+'" SrcChars="'+SrcChars+'" DstChars="'+DstChars+'"',Expected,h);
  end;

begin
  T('empty','','','','');
  T('nop','a','b','b','a');
  T('a to b','a','a','b','b');
  T('switch a,b','abaa','ab','ba','babb');
  T('delete a','a','a','','');
  T('delete a','aba','a','','b');
  T('replace ä with ö','bä','ä','ö','bö');
  T('replace ä with ö','äbä','ä','ö','öbö');
  T('switch ä,ö','äbö','äö','öä','öbä');
  T('delete ä','äbö','ä','','bö');
  T('replace ä with a','äbö','ä','a','abö');
end;

procedure TTestLazXML.TestXPath;
var
  xml: String;
  ss: TStringStream;
  Doc: TXMLDocument;
  BookStoreNode: TDOMElement;
  V: TXPathVariable;
  NodeSet: TNodeSet;
  Node: TDOMElement;
begin
  xml:='<?xml version="1.0"?>'+LineEnding
      +'<bookstore>'+LineEnding
      +'  <book>'+LineEnding
      +'    <title lang="en">Lazarus</title>'+LineEnding
      +'    <author>Michael Van Canneyt</author>'+LineEnding
      +'    <author>Mattias Gaertner</author>'+LineEnding
      +'    <author>Felipe Monteiro de Carvalho</author>'+LineEnding
      +'    <author>Swen Heinig</author>'+LineEnding
      +'    <year>2011</year>'+LineEnding
      +'    <price>37,50</price>'+LineEnding
      +'  </book>'+LineEnding
      +'</bookstore>'+LineEnding;
  Doc:=nil;
  V:=nil;
  ss:=TStringStream.Create(xml);
  try
    ReadXMLFile(Doc,ss);
    BookStoreNode:=Doc.DocumentElement;

    // check return type
    V:=EvaluateXPathExpression('/bookstore',BookStoreNode);
    debugln(['TTestLazXML.TestXPath ',dbgsname(V)]);
    AssertEquals('/bookstore returns class',TXPathNodeSetVariable,V.ClassType);
    NodeSet:=V.AsNodeSet;
    AssertEquals('/bookstore AsNodeSet',True,NodeSet<>nil);
    AssertEquals('/bookstore AsNodeSet.Count',1,NodeSet.Count);
    Node:=TDOMElement(NodeSet[0]);
    AssertEquals('/bookstore AsNodeSet[0] class',TDOMElement,Node.ClassType);
    AssertEquals('/bookstore node',True,Node=BookStoreNode);
    FreeAndNil(V);

    // check //
    V:=EvaluateXPathExpression('//book',BookStoreNode);
    AssertEquals('//book AsNodeSet',True,V.AsNodeSet<>nil);
    AssertEquals('//book AsNodeSet.Count',1,V.ASNodeSet.Count);
    Node:=TDOMElement(V.AsNodeSet[0]);
    AssertEquals('//book node','book',Node.TagName);

  finally
    V.Free;
    Doc.Free;
    ss.Free;
  end;
end;

initialization
  AddToLazUtilsTestSuite(TTestLazXML);

end.

