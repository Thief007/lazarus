unit mainform;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, customdrawncontrols, Forms, Controls, Graphics,
  Dialogs, StdCtrls, ExtCtrls, ComCtrls;

type

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    CDButton1: TCDButton;
    CDButton2: TCDButton;
    CDButton3: TCDButton;
    CDButton4: TCDButton;
    CDCheckBox1: TCDCheckBox;
    CDCheckBox2: TCDCheckBox;
    CDEdit1: TCDEdit;
    CDEdit2: TCDEdit;
    CDRadioButton1: TCDRadioButton;
    CDRadioButton2: TCDRadioButton;
    CDRadioButton3: TCDRadioButton;
    CDStaticText1: TCDStaticText;
    CDTrackBar2: TCDTrackBar;
    CDTrackBar4: TCDTrackBar;
    editWinXP: TCDEdit;
    CDGroupBox1: TCDGroupBox;
    CDGroupBox2: TCDGroupBox;
    CDPageControl1: TCDPageControl;
    CDPageControl2: TCDPageControl;
    CDTabSheet1: TCDTabSheet;
    CDTabSheet2: TCDTabSheet;
    CDTabSheet3: TCDTabSheet;
    CDTabSheet4: TCDTabSheet;
    CDTabSheet5: TCDTabSheet;
    CheckBox1: TCheckBox;
    comboControls: TComboBox;
    Edit1: TEdit;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    GroupBox3: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    Memo1: TMemo;
    memoLog: TMemo;
    notebookControls: TNotebook;
    Page1: TPage;
    Page2: TPage;
    Page3: TPage;
    Page4: TPage;
    pageScrollBars: TPage;
    pageToggleBoxes: TPage;
    pageComboBoxes: TPage;
    pageStaticTexts: TPage;
    pageMenu: TPage;
    pagePopUp: TPage;
    pageEditMultiline: TPage;
    pageRadioButton: TPage;
    pagePanels: TPage;
    pageButtonGlyph: TPage;
    pageListBoxes: TPage;
    pageProgressBars: TPage;
    pageButtons: TPage;
    PageControl1: TPageControl;
    pageEdits: TPage;
    pageCheckboxes: TPage;
    pageGroupBoxes: TPage;
    pageTrackBars: TPage;
    pagePageControls: TPage;
    pageTabControls: TPage;
    Panel1: TPanel;
    RadioButton1: TRadioButton;
    RadioButton2: TRadioButton;
    RadioButton3: TRadioButton;
    StaticText1: TStaticText;
    StaticText2: TStaticText;
    StaticText3: TStaticText;
    StaticText4: TStaticText;
    StaticText5: TStaticText;
    StaticText6: TStaticText;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    TabSheet3: TTabSheet;
    TrackBar1: TTrackBar;
    CDTrackBar1: TCDTrackBar;
    TrackBar2: TTrackBar;
    procedure comboControlsChange(Sender: TObject);
    procedure HandleClick(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end; 

var
  Form1: TForm1; 

implementation

uses TypInfo, customdrawndrawers;

{$R *.lfm}

{ TForm1 }

procedure TForm1.comboControlsChange(Sender: TObject);
begin
  notebookControls.PageIndex := comboControls.ItemIndex;
//  Caption := GetEnumName(TypeInfo(TCDDrawStyle), Integer(editWinXP.DrawStyle));
end;

procedure TForm1.HandleClick(Sender: TObject);
begin
  memoLog.Lines.Add(Format('%s: %s OnClick', [TControl(Sender).Name, TControl(Sender).ClassName]));
end;

end.

