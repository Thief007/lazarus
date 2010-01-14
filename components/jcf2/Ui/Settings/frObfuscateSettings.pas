{(*}
(*------------------------------------------------------------------------------
 Delphi Code formatter source code 

The Original Code is frObfuscateSettings.pas, released April 2000.
The Initial Developer of the Original Code is Anthony Steele. 
Portions created by Anthony Steele are Copyright (C) 1999-2008 Anthony Steele.
All Rights Reserved. 
Contributor(s): Anthony Steele. 

The contents of this file are subject to the Mozilla Public License Version 1.1
(the "License"). you may not use this file except in compliance with the License.
You may obtain a copy of the License at http://www.mozilla.org/NPL/

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either express or implied.
See the License for the specific language governing rights and limitations 
under the License.

Alternatively, the contents of this file may be used under the terms of
the GNU General Public License Version 2 or later (the "GPL") 
See http://www.gnu.org/licenses/gpl.html
------------------------------------------------------------------------------*)
{*)}

unit frObfuscateSettings;

{$I JcfGlobal.inc}

interface

uses
  { delphi }
  Classes, Controls, Forms, StdCtrls, ExtCtrls,
  { local }
  IDEOptionsIntf;

type
  { TfObfuscateSettings }

  TfObfuscateSettings = class(TAbstractIDEOptionsEditor)
    cbRemoveWhiteSpace: TCheckBox;
    cbRemoveComments: TCheckBox;
    rgObfuscateCaps: TRadioGroup;
    cbRebreak: TCheckBox;
    cbRemoveIndent: TCheckBox;
    cbEnabled: TCheckBox;
  public
    constructor Create(AOwner: TComponent); override;

    function GetTitle: String; override;
    procedure Setup(ADialog: TAbstractOptionsEditorDialog); override;
    procedure ReadSettings(AOptions: TAbstractIDEOptions); override;
    procedure WriteSettings(AOptions: TAbstractIDEOptions); override;
    class function SupportedOptionsClass: TAbstractIDEOptionsClass; override;
  end;

implementation

{$R *.lfm}

uses
  JcfSettings, SettingsTypes, JcfHelp, SetObfuscate;

{ TfObfuscateSettings }

constructor TfObfuscateSettings.Create(AOwner: TComponent);
begin
  inherited;
  //fiHelpContext := HELP_OBFUSCATE_SETTINGS;
end;

function TfObfuscateSettings.GetTitle: String;
begin
  Result := 'Obfuscate';
end;

procedure TfObfuscateSettings.Setup(ADialog: TAbstractOptionsEditorDialog);
begin
  // nothing
end;

procedure TfObfuscateSettings.ReadSettings(AOptions: TAbstractIDEOptions);
begin
  with FormatSettings.Obfuscate do
  begin
    cbEnabled.Checked      := Enabled;
    rgObfuscateCaps.ItemIndex := Ord(Caps);
    cbRemoveWhiteSpace.Checked := RemoveWhiteSpace;
    cbRemoveComments.Checked := RemoveComments;
    cbRemoveIndent.Checked := RemoveIndent;
    cbRebreak.Checked      := RebreakLines;
  end;
end;

procedure TfObfuscateSettings.WriteSettings(AOptions: TAbstractIDEOptions);
begin
  with FormatSettings.Obfuscate do
  begin
    Enabled := cbEnabled.Checked;
    Caps    := TCapitalisationType(rgObfuscateCaps.ItemIndex);
    RemoveWhiteSpace := cbRemoveWhiteSpace.Checked;
    RemoveComments := cbRemoveComments.Checked;
    RemoveIndent := CbRemoveIndent.Checked;
    RebreakLines := cbRebreak.Checked;
  end;
end;

class function TfObfuscateSettings.SupportedOptionsClass: TAbstractIDEOptionsClass;
begin
  Result := TFormatSettings;
end;

initialization
  RegisterIDEOptionsEditor(JCFOptionsGroup, TfObfuscateSettings, JCFOptionObfuscate);
end.
