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
    This unit defines various base classes for loading and saving of configs.
}
unit ConfigStorage;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils; 
  
type
  { TConfigStorage }

  TConfigStorage = class
  private
    FPathStack: TStrings;
    FCurrentBasePath: string;
  protected
    function  GetFullPathValue(const APath, ADefault: String): String; virtual; abstract;
    function  GetFullPathValue(const APath: String; ADefault: Integer): Integer; virtual; abstract;
    function  GetFullPathValue(const APath: String; ADefault: Boolean): Boolean; virtual; abstract;
    procedure SetFullPathValue(const APath, AValue: String); virtual; abstract;
    procedure SetDeleteFullPathValue(const APath, AValue, DefValue: String); virtual; abstract;
    procedure SetFullPathValue(const APath: String; AValue: Integer); virtual; abstract;
    procedure SetDeleteFullPathValue(const APath: String; AValue, DefValue: Integer); virtual; abstract;
    procedure SetFullPathValue(const APath: String; AValue: Boolean); virtual; abstract;
    procedure SetDeleteFullPathValue(const APath: String; AValue, DefValue: Boolean); virtual; abstract;
    procedure DeleteFullPath(const APath: string); virtual; abstract;
    procedure DeleteFullPathValue(const APath: string); virtual; abstract;
  public
    destructor Destroy; override;
    function  GetValue(const APath, ADefault: String): String;
    function  GetValue(const APath: String; ADefault: Integer): Integer;
    function  GetValue(const APath: String; ADefault: Boolean): Boolean;
    procedure SetValue(const APath, AValue: String);
    procedure SetDeleteValue(const APath, AValue, DefValue: String);
    procedure SetValue(const APath: String; AValue: Integer);
    procedure SetDeleteValue(const APath: String; AValue, DefValue: Integer);
    procedure SetValue(const APath: String; AValue: Boolean);
    procedure SetDeleteValue(const APath: String; AValue, DefValue: Boolean);
    procedure DeletePath(const APath: string);
    procedure DeleteValue(const APath: string);
    property CurrentBasePath: string read FCurrentBasePath;
    function ExtendPath(const APath: string): string;
    procedure AppendBasePath(const Path: string);
    procedure UndoAppendBasePath;
  end;

implementation

{ TConfigStorage }

destructor TConfigStorage.Destroy;
begin
  FPathStack.Free;
  inherited Destroy;
end;

function TConfigStorage.GetValue(const APath, ADefault: String): String;
begin
  Result:=GetFullPathValue(ExtendPath(APath),ADefault);
end;

function TConfigStorage.GetValue(const APath: String; ADefault: Integer
  ): Integer;
begin
  Result:=GetFullPathValue(ExtendPath(APath),ADefault);
end;

function TConfigStorage.GetValue(const APath: String; ADefault: Boolean
  ): Boolean;
begin
  Result:=GetFullPathValue(ExtendPath(APath),ADefault);
end;

procedure TConfigStorage.SetValue(const APath, AValue: String);
begin
  SetFullPathValue(ExtendPath(APath),AValue);
end;

procedure TConfigStorage.SetDeleteValue(const APath, AValue, DefValue: String);
begin
  SetDeleteFullPathValue(ExtendPath(APath),AValue,DefValue);
end;

procedure TConfigStorage.SetValue(const APath: String; AValue: Integer);
begin
  SetFullPathValue(ExtendPath(APath),AValue);
end;

procedure TConfigStorage.SetDeleteValue(const APath: String; AValue,
  DefValue: Integer);
begin
  SetDeleteFullPathValue(ExtendPath(APath),AValue,DefValue);
end;

procedure TConfigStorage.SetValue(const APath: String; AValue: Boolean);
begin
  SetFullPathValue(ExtendPath(APath),AValue);
end;

procedure TConfigStorage.SetDeleteValue(const APath: String; AValue,
  DefValue: Boolean);
begin
  SetDeleteFullPathValue(ExtendPath(APath),AValue,DefValue);
end;

procedure TConfigStorage.DeletePath(const APath: string);
begin
  DeleteFullPath(ExtendPath(APath));
end;

procedure TConfigStorage.DeleteValue(const APath: string);
begin
  DeleteFullPathValue(ExtendPath(APath));
end;

function TConfigStorage.ExtendPath(const APath: string): string;
begin
  Result:=FCurrentBasePath+APath;
end;

procedure TConfigStorage.AppendBasePath(const Path: string);
begin
  if FPathStack=nil then FPathStack:=TStringList.Create;
  FPathStack.Add(FCurrentBasePath);
  FCurrentBasePath:=FCurrentBasePath+Path;
  if (FCurrentBasePath<>'')
  and (FCurrentBasePath[length(FCurrentBasePath)]<>'/') then
    FCurrentBasePath:=FCurrentBasePath+'/';
end;

procedure TConfigStorage.UndoAppendBasePath;
begin
  if (FPathStack=nil) or (FPathStack.Count=0) then
    raise Exception.Create('TConfigStorage.UndoAppendBasePath');
  FCurrentBasePath:=FPathStack[FPathStack.Count-1];
  FPathStack.Delete(FPathStack.Count-1);
end;

end.

