{
 *****************************************************************************
 *                                                                           *
 *  See the file COPYING.modifiedLGPL.txt, included in this distribution,    *
 *  for details about the copyright.                                         *
 *                                                                           *
 *  This program is distributed in the hope that it will be useful,          *
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of           *
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                     *
 *                                                                           *
 *****************************************************************************
}
unit ProjectResourcesIntf;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, ProjectIntf, resource;

type
  TAbstractProjectResources = class;

  { TAbstractProjectResource }
  TAbstractProjectResource = class
  protected
    FModified: boolean;
    FOnModified: TNotifyEvent;
    procedure SetModified(const AValue: boolean);
  public
    constructor Create; virtual;

    procedure DoBeforeBuild(AResources: TAbstractProjectResources; SaveToTestDir: boolean); virtual;
    function UpdateResources(AResources: TAbstractProjectResources; const MainFilename: string): Boolean; virtual; abstract;

    property Modified: boolean read FModified write SetModified;
    property OnModified: TNotifyEvent read FOnModified write FOnModified;
  end;

  { TAbstractProjectResources }

  TAbstractProjectResources = class
  private
    FProject: TLazProject;
    FResourceType: TResourceType;
  protected
    FMessages: TStringList;
    procedure SetResourceType(const AValue: TResourceType); virtual;
  public
    constructor Create(AProject: TLazProject); virtual;
    destructor Destroy; override;

    procedure AddSystemResource(AResource: TAbstractResource); virtual; abstract;
    procedure AddLazarusResource(AResource: TStream;
                   const AResourceName, AResourceType: String); virtual; abstract;

    property Messages: TStringList read FMessages;
    property Project: TLazProject read FProject;
    property ResourceType: TResourceType read FResourceType write SetResourceType;
  end;

implementation

{ TAbstractProjectResource }

procedure TAbstractProjectResource.SetModified(const AValue: boolean);
begin
  if FModified=AValue then exit;
  FModified:=AValue;
  if Assigned(OnModified) then OnModified(Self);
end;

constructor TAbstractProjectResource.Create;
begin
  FModified := False;
end;

procedure TAbstractProjectResource.DoBeforeBuild(
  AResources: TAbstractProjectResources; SaveToTestDir: boolean);
begin
  // nothing
end;

{ TAbstractProjectResources }

procedure TAbstractProjectResources.SetResourceType(const AValue: TResourceType);
begin
  FResourceType := AValue;
end;

constructor TAbstractProjectResources.Create(AProject: TLazProject);
begin
  FProject:=AProject;
  FMessages := TStringList.Create;
end;

destructor TAbstractProjectResources.Destroy;
begin
  FreeAndNil(FMessages);
  inherited Destroy;
end;

end.
