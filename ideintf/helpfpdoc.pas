{
 *****************************************************************************
 *                                                                           *
 *  See the file COPYING.modifiedLGPL, included in this distribution,        *
 *  for details about the copyright.                                         *
 *                                                                           *
 *  This program is distributed in the hope that it will be useful,          *
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of           *
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                     *
 *                                                                           *
 *****************************************************************************

  Author: Mattias Gaertner

  Abstract:
    Help database for FPDoc.
}
unit HelpFPDoc;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LCLProc, FileCtrl, HelpIntf, HelpHTML;

type
  { TFPDocHTMLHelpDatabase }

  TFPDocHTMLHelpDatabase = class(THTMLHelpDatabase)
  public
    function ShowHelp(Query: THelpQuery; BaseNode, NewNode: THelpNode;
                      var ErrMsg: string): TShowHelpResult; override;
  end;
  

implementation

{ TFPDocHTMLHelpDatabase }

function TFPDocHTMLHelpDatabase.ShowHelp(Query: THelpQuery; BaseNode,
  NewNode: THelpNode; var ErrMsg: string): TShowHelpResult;
var
  ContextList: TPascalHelpContextList;
  UnitName: String;
  URL: String;
  TheBaseURL: String;
  Filename: String;
begin
  if (Query is THelpQueryPascalContexts)
  and (NewNode.QueryItem is TPascalHelpContextList) then begin
    // a pascal context query
    ContextList:=TPascalHelpContextList(NewNode.QueryItem);
    if (ContextList.Count>0) and (ContextList.List[0].Descriptor=pihcFilename)
    then begin
      // extract unit filename
      UnitName:=lowercase(ExtractFileNameOnly(ContextList.List[0].Context));
      DebugLn('TFPDocHTMLHelpDatabase.ShowHelp A Unitname=',Unitname,' NewNode.HelpType=',dbgs(ord(NewNode.HelpType)),' NewNode.Title=',NewNode.Title,' NewNode.URL=',NewNode.URL);
      if UnitName<>'' then begin

        Filename:=UnitName+'/';
        // TODO: context in unit
        Filename:=Filename+'index.html';
      
        TheBaseURL:='';
        if NewNode.URLValid then begin
          // the node has an URL => use only the path
          TheBaseURL:=NewNode.URL;
          debugln('A TheBaseURL=',TheBaseURL);
          if (HelpDatabases<>nil) then
            HelpDatabases.SubstituteMacros(TheBaseURL);
          debugln('B TheBaseURL=',TheBaseURL);
          TheBaseURL:=ExtractURLDirectory(TheBaseURL);
          debugln('C TheBaseURL=',TheBaseURL);
          DebugLn('TFPDocHTMLHelpDatabase.ShowHelp Node Base URL TheBaseURL=',TheBaseURL);
        end;

        if TheBaseURL='' then
          TheBaseURL:=GetEffectiveBaseURL;

        // show URL
        if TheBaseURL<>'' then
          URL:=TheBaseURL+Filename
        else
          URL:=FilenameToURL(Filename);
        Result:=ShowURL(URL,NewNode.Title,ErrMsg);
        exit;
      end;
    end;
  end;
  // otherwise use default
  Result:=inherited ShowHelp(Query, BaseNode, NewNode, ErrMsg);
end;

end.

