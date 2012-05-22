{
 Test with:
     ./runtests --format=plain --suite=TTestCodetoolsCfgScript
     ./runtests --format=plain --suite=TestCfgScript
}
unit TestCfgScript;

{$mode objfpc}{$H+}

{$DEFINE VerboseTestCfgScript}

interface

uses
  Classes, SysUtils, fpcunit, testglobals, FileProcs,
  CodeToolsCfgScript;

type

  { TTestCodetoolsCfgScript }

  TTestCodetoolsCfgScript = class(TTestCase)
  protected
    procedure TestResult(Script, ExpectedResult: string);
  published
    procedure TestCfgScript;
  end;

implementation

{ TTestCodetoolsCfgScript }

procedure TTestCodetoolsCfgScript.TestResult(Script, ExpectedResult: string);
var
  Engine: TCTConfigScriptEngine;
  ScriptResult: String;
  i: Integer;
begin
  Engine:=TCTConfigScriptEngine.Create;
  try
    Engine.MaxErrorCount:=1;
    if not Engine.Execute(Script) then begin
      writeln('Script failed to run:');
      for i:=0 to Engine.ErrorCount-1 do
        writeln(Engine.GetErrorStr(i));
      AssertEquals('Syntax error in script "'+Script+'"',true,false);
    end else begin
      ScriptResult:=Engine.Variables['Result'];
      if ScriptResult<>ExpectedResult then
        Engine.Variables.WriteDebugReport('Variables');
      AssertEquals(Script,ExpectedResult,ScriptResult);
    end;
  finally
    Engine.Free;
  end;
end;

procedure TTestCodetoolsCfgScript.TestCfgScript;
begin
  TestResult('Result:=2;','2');
  TestResult('a:=2; b:=a; Result:=b;','2');
  TestResult('Result:=1+2;','3');
  //TestResult('Result:=1+2*3;','7');
end;

initialization
  AddToCodetoolsTestSuite(TTestCodetoolsCfgScript);

end.

