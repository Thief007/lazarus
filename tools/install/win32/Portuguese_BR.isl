; ******************************************************
; *** Inno Setup version 4.2.2+ PT_BR messages       ***
; ***                                                ***
; *** Original Author:                               ***
; ***                                                ***
; ***       S�rgio Marcelo da Silva Gomes      	     ***
; *** (smace at smace.com.br) < www.smace.com.br >   ***
; ***                                                ***
; ******************************************************
;
;
; To download user-contributed translations of this file, go to:
;   http://www.jrsoftware.org/is3rdparty.php
;
; Note: When translating this text, do not add periods (.) to the end of
; messages that didn't have them already, because on those messages Inno
; Setup adds the periods automatically (appending a period would result in
; two periods being displayed).
;
; $jrsoftware: issrc/Files/Default.isl,v 1.58 2004/04/07 20:17:13 jr Exp $

[LangOptions]
LanguageName=Portugu�s (Brasil)
LanguageID=$0416
LanguageCodePage=0
; If the language you are translating to requires special font faces or
; sizes, uncomment any of the following entries and change them accordingly.
;DialogFontName=
;DialogFontSize=8
;WelcomeFontName=Verdana
;WelcomeFontSize=12
;TitleFontName=Arial
;TitleFontSize=29
;CopyrightFontName=Arial
;CopyrightFontSize=8

[Messages]

; *** Application titles
SetupAppTitle=Instala��o
SetupWindowTitle=Instala��o - %1
UninstallAppTitle=Desinstala��o
UninstallAppFullTitle=%1 Desinstala��o

; *** Misc. common
InformationTitle=Informa��o
ConfirmTitle=Confirme
ErrorTitle=Erro

; *** SetupLdr messages
SetupLdrStartupMessage=Este � um instalador para %1. Deseja continuar?
LdrCannotCreateTemp=N�o foi poss�vel criar um arquivo tempor�rio. Instala��o cancelada
LdrCannotExecTemp=N�o foi poss�vel executar o arquivo no diret�rio tempor�rio. Instala��o cancelada

; *** Startup error messages
LastErrorMessage=%1.%n%nErro %2: %3
SetupFileMissing=Est� faltando o arquivo %1 no diret�rio da instala��o. Por favor, corrija o problema ou obtenha uma nova c�pia do programa.
SetupFileCorrupt=Os arquivos da instala��o est�o corrompidos. Por favor obtenha uma nova c�pia do programa.
SetupFileCorruptOrWrongVer=Os arquivos da instala��o est�o corrompidos, ou s�o incompat�veis com esta vers�o do Instalador. Por favor, corrija o problema ou obtenha uma nova c�pia do programa.
NotOnThisPlatform=Este programa n�o vai ser executado em %1.
OnlyOnThisPlatform=Este programa precisa ser executado em %1.
WinVersionTooLowError=Este programa requer %1 vers�o %2 ou superior.
WinVersionTooHighError=Este programa n�o pode ser instalado no %1 vers�o %2 ou superior.
AdminPrivilegesRequired=Voc� precisa estar logado como administrador quando for instalar este programa.
PowerUserPrivilegesRequired=Voc� precisa estar logado como administrador ou como um usu�rio membro do Grupo de Usu�rios Poderosos quando for instalar este programa
SetupAppRunningError=O instalador detectou que %1 est� em execu��o.%n%nPor favor feche todas as inst�ncias dele agora, ent�o, clique em OK para continuar, ou Cancelar para sair.
UninstallAppRunningError=O desinstalador detectou que %1 est� em execu��o.%n%nPor favor feche todas as inst�ncias dele agora, ent�o, clique em OK para continuar, ou Cancelar para sair.

; *** Misc. errors
ErrorCreatingDir=O instalador n�o conseguiu criar o diret�rio "%1"
ErrorTooManyFilesInDir=N�o foi poss�vel criar um arquivo no diret�rio "%1" por que ele cont�m arquivos demais.

; *** Setup common messages
ExitSetupTitle=Sair do Instalador
ExitSetupMessage=A instala��o ainda n�o est� completa. Se voc� sair agora, o programa n�o vai ser instalado.%n%nVoc� pode executar o Instalador denovo uma outra hora para completar a instala��o. Sair do Instalador?
AboutSetupMenuItem=&Sobre o Instalador...
AboutSetupTitle=Sobre o Instalador
AboutSetupMessage=%1 vers�o %2%n%3%n%n%1 P�gina Inicial:%n%4
AboutSetupNote=Vers�o Portugu�s-Brasil. Traduzido por S�rgio Marcelo < smace at smace.com.br >

; *** Buttons
ButtonBack=< &Voltar
ButtonNext=&Pr�ximo >
ButtonInstall=&Instalar
ButtonOK=OK
ButtonCancel=Cancelar
ButtonYes=&Sim
ButtonYesToAll=Sim para &Todos
ButtonNo=&N�o
ButtonNoToAll=N�&o para Todos
ButtonFinish=&Finalizar
ButtonBrowse=&Procurar...
ButtonWizardBrowse=Procura&r...
ButtonNewFolder=&Criar Nova Pasta

; *** "Select Language" dialog messages
SelectLanguageTitle=Selecione o Idioma do Instalador
SelectLanguageLabel=Selecione o idioma a ser usado durante a instala��o:

; *** Common wizard text
ClickNext=Clique em Pr�ximo para continuar, ou Cancelar para sair do Instalador.
BeveledLabel=
BrowseDialogTitle=Procurar Pasta
BrowseDialogLabel=Selecione uma pasta na lista abaixo, ent�o clique OK.
NewFolderName=Nova Pasta

; *** "Welcome" wizard page
WelcomeLabel1=Bem vindo ao Instalador do [name]
WelcomeLabel2=Ser� instalado no seu computador o programa:%n[name/ver].%n%n� recomendado que voc� feche todos os outros aplicativos antes de continuar.

; *** "Password" wizard page
WizardPassword=Senha
PasswordLabel1=Esta instala��o � protegida por senha.
PasswordLabel3=Por favor forne�a a sua senha, ent�o clique em Pr�ximo para continuar. Senhas s�o case-sensitive. (Faz diferen�a 'a' e 'A')
PasswordEditLabel=&Senha:
IncorrectPassword=A senha que voc� informou n�o � correta. Por favor tente denovo.

; *** "License Agreement" wizard page
WizardLicense=Termos da Licen�a
LicenseLabel=Por favor leia atentamente as seguintes informa��es antes de continuar.
LicenseLabel3=Por favor leia os seguintes Termos da Licen�a. Voc� precisa aceitar os termos para este acordo antes de continuar com a instala��o.
LicenseAccepted=Eu aceito os termo&s
LicenseNotAccepted=Eu &n�o aceito os termos

; *** "Information" wizard pages
WizardInfoBefore=Informa��o
InfoBeforeLabel=Por favor leia as seguintes informa��es importantes antes de continuar.
InfoBeforeClickLabel=Quando voc� estiver pronto para continuar com a Instala��o, clique em Pr�ximo.
WizardInfoAfter=Informa��o
InfoAfterLabel=Por favor leia as seguintes informa��es importantes antes de continuar.
InfoAfterClickLabel=Quando voc� estiver pronto para continuar com a Instala��o, clique em Pr�ximo.

; *** "User Information" wizard page
WizardUserInfo=Informa��es do Usu�rio
UserInfoDesc=Por favor complete as suas informa��es.
UserInfoName=&Nome do Usu�rio:
UserInfoOrg=&Organiza��o:
UserInfoSerial=&N�mero de S�rie:
UserInfoNameRequired=Voc� precisa colocar um nome.

; *** "Select Destination Location" wizard page
WizardSelectDir=Selecione um Local de Destino
SelectDirDesc=Aonde o [name] deveria ser instalado?
SelectDirLabel3=O [name] vai ser instalado no seguinte diret�rio:
SelectDirBrowseLabel=Para continuar, clique em Pr�ximo. Se voc� preferir um diret�rio diferente, clique em Procurar.
DiskSpaceMBLabel=� requerido no m�nimo [mb] MB de espa�o livre em disco
ToUNCPathname= O Instalador n�o pode instalar em um diret�rio UNC. Se voc� est� tentando instalar em uma rede, voc� vai precisar mapear uma unidade de rede.
InvalidPath=You precisa informar um caminho com a letra da unidade; por exemplo:%n%nC:\APP%n%nou um caminho UNC no formato:%n%n\\servidor\compartilhamento
InvalidDrive=A unidade ou compartilhamento UNC que voc� selecionou n�o existe ou n�o � acess�vel. Por favor selecione outro.
DiskSpaceWarningTitle=Espa�o insuficiente no disco
DiskSpaceWarning=A instala��o requer no m�nimo %1 KB de espa�o livre para prosseguir, mas o drive selecionado tem somente %2 KB dispon�vel.%n%nDeseja continuar mesmo assim?
DirNameTooLong=O nome do diret�rio ou caminho � grande demais.
InvalidDirName=O nome do diret�rio n�o � v�lido.
BadDirName32=O nome da pasta n�o pode incluir nenhum dos seguintes caracteres:%n%n%1
DirExistsTitle=Pasta Existe
DirExists=O diret�rio:%n%n%1%n%nj� existe. Voc� gostaria de instalar nesta pasta mesmo assim?
DirDoesntExistTitle=Pasta N�o Existe
DirDoesntExist=A pasta:%n%n%1%n%nn�o existe. Deseja cri�-la?


; *** "Select Components" wizard page
WizardSelectComponents=Selecione os Componentes
SelectComponentsDesc=Quais componentes deveriam ser instalados?
SelectComponentsLabel2=Selecione os componentes que voc� deseja instalar; desmarque os componentes que voc� n�o deseja instalar.
FullInstallation=Instala��o Completa

; if possible don't translate 'Compact' as 'Minimal' (I mean 'Minimal' in your language)
CompactInstallation=Instala��o Compacta
CustomInstallation=Instala��o Personalizada
NoUninstallWarningTitle=O Componente Existe
NoUninstallWarning=O Instalador detectou que os seguintes componentes j� est�o instalado no seu computador:%n%n%1%n%nDesmarcando estes componentes n�o ir� desinstal�-los.%n%nVoc� gostaria de continuar mesmo assim?
ComponentSize1=%1 KB
ComponentSize2=%1 MB
ComponentsDiskSpaceMBLabel=A sele��o atual requer no m�nimo [mb] MB de espa�o em disco.

; *** "Select Additional Tasks" wizard page
WizardSelectTasks=Selecione as Tarefas Adicionais
SelectTasksDesc=Quais tarefas adicionais deveriam ser realizadas?
SelectTasksLabel2=Selecione as tarefas adicionais que voc� gostaria que fossem realizadas durante a instala��o do [name], ent�o clique em Pr�ximo.

; *** "Select Start Menu Folder" wizard page
WizardSelectProgramGroup=Selecione a Pasta do Menu Iniciar
SelectStartMenuFolderDesc=Aonde dever� ser colocado os atalhos do programa?
SelectStartMenuFolderLabel3=Os atalhos do programa ser�o criados na seguinte pasta do Menu Iniciar:
SelectStartMenuFolderBrowseLabel=Para continuar, clique em Pr�ximo. Se voc� preferir escolher uma pasta diferente, clique em Procurar.
NoIconsCheck=&N�o criar �cones
MustEnterGroupName=Voc� precisa especificar um nome para a pasta.
GroupNameTooLong=O nome da pasta ou caminho � longo demais.
InvalidGroupName=O nome da pasta n�o � v�lido.
BadGroupName=O nome da pasta n�o pode conter nenhum dos seguintes caracteres:%n%n%1
NoProgramGroupCheck2=&N�o crie uma pasta no Menu Iniciar


; *** "Ready to Install" wizard page
WizardReady=Pronto para Instalar
ReadyLabel1=O instalador est� pronto para come�ar a instalar o [name] no seu computador.
ReadyLabel2a=Clique em instalar para continuar com a instala��o, ou clique em Voltar se voc� quiser revisar ou mudar alguma configura��o.
ReadyLabel2b=Clique em Instalar para continuar com a instala��o.
ReadyMemoUserInfo=Informa��es do Usu�rio:
ReadyMemoDir=Diret�rio de Destino
ReadyMemoType=Tipo da Instala��o:
ReadyMemoComponents=Componentes Selecionados:
ReadyMemoGroup=Pasta do Menu Iniciar:
ReadyMemoTasks=Tarefas Adicionais:

; *** "Preparing to Install" wizard page
WizardPreparing=Preparando Instala��o
PreparingDesc=Preparando instala��o do [name] no seu computador.

PreviousInstallNotCompleted=A instala��o/remo��o do programa anterior n�o foi conclu�da. � necess�rio reiniciar o computador para completar a instala��o.%n%nDepois de reiniciar o seu computador, execute o Instalador novamente para completar a instala��o do [name].

CannotContinue=A instala��o n�o pode continuar. Por favor clique em cancelar para sair.

; *** "Installing" wizard page
WizardInstalling=Instalando
InstallingLabel=Por favor aguarde enquanto � instalado o [name] no seu computador.

; *** "Setup Completed" wizard page
FinishedHeadingLabel=Finalizando o Assistente de Instala��o do [name]
FinishedLabelNoIcons=A instala��o do [name] foi conclu�da com sucesso.
FinishedLabel=A instala��o do [name] foi conclu�da com sucesso. O aplicativo pode ser iniciado � partir dos �cones instalados.
ClickFinish=Clique em Finalizar para Sair da Instala��o.
FinishedRestartLabel=Para completar a instala��o do [name], � necess�rio reiniciar o seu computador. Deseja Reiniciar agora?
FinishedRestartMessage=Para completar a instala��o do [name], � necess�rio reiniciar o seu computador.%n%nDeseja Reiniciar agora?
ShowReadmeCheck=Sim, Eu gostaria de ver o arquivo LEIAME
YesRadio=&Sim, Reiniciar o computador agora
NoRadio=&N�o, Eu vou reiniciar mais tarde

; used for example as 'Run MyProg.exe'
RunEntryExec=Executar %1
; used for example as 'View Readme.txt'
RunEntryShellExec=Exibir %1

; *** "Setup Needs the Next Disk" stuff
ChangeDiskTitle=Insira o pr�ximo disco
SelectDiskLabel2=Por favor insira o Disco %1 e clique OK.%n%NSe os arquivos no disco podem ser encontrados em uma pasta diferente da mostrada abaixo, insira o caminho correto ou clique em Procurar.
PathLabel=&Caminho:
FileNotInDir2=O arquivo "%1" n�o pode ser localizado em "%2". Por favor insira o disco correto ou selecione uma outra pasta.
SelectDirectoryLabel=Por favor especifique a localiza��o do pr�ximo disco.

; *** Installation phase messages
SetupAborted=A instala��o n�o foi completada.%n%nPor favor corrija o problema e execute a Instala��o denovo.
EntryAbortRetryIgnore=Clique em Repetir para tentar denovo, Ignorar para proceder mesmo assim, ou Abortar pra cancelar a instala��o.

; *** Installation status messages
StatusCreateDirs=Criando diret�rios...
StatusExtractFiles=Extraindo arquivos...
StatusCreateIcons=Criando atalhos...
StatusCreateIniEntries=Criando entradas INI...
StatusCreateRegistryEntries=Criando entradas de registro...
StatusRegisterFiles=Registrando arquivo...
StatusSavingUninstall=Salvando informa��es para desinstala��o...
StatusRunProgram=Finalizando instala��o...
StatusRollback=Revertendo mudan�as...

; *** Misc. errors
ErrorInternal2=Erro Interno: %1
ErrorFunctionFailedNoCode=%1 falhou
ErrorFunctionFailed=%1 falhou; c�digo %2
ErrorFunctionFailedWithMessage=%1 falhou; c�digo %2.%n%3
ErrorExecutingProgram=N�o foi poss�vel executar o arquivo:%n%1

; *** Registry errors
ErrorRegOpenKey=Erro ao abrir a chave de registro:%n%1\%2
ErrorRegCreateKey=Erro ao criar a chave de registro:%n%1\%2
ErrorRegWriteKey=Erro ao gravar na chave de registro:%n%1\%2

; *** INI errors
ErrorIniEntry=Erro criando entrada INI no arquivo "%1".

; *** File copying errors
FileAbortRetryIgnore=Clique em Repetir para tentar denovo, Ignorar para pular este arquivo (n�o recomendado), ou Abortar para cancelar a instala��o.
FileAbortRetryIgnore2=Clique em Repetir para tentar denovo, Ignorar para proceder mesmo assim (n�o recomendado), ou Abortar para cancelar a instala��o.
SourceIsCorrupted=O arquivo fonte est� corrompido
SourceDoesntExist=O arquivo fonte "%1" n�o existe
ExistingFileReadOnly=O arquivo existe est� como somente-leitura.%n%nClique em repetir para remover a propriedade Somente Leitura e tentar denovo, Ignorar para pular este arquivo, ou Abortar para cancelar a instala��o.
ErrorReadingExistingDest=Um erro ocorreu ao tentar ler o arquivo existente:
FileExists=O arquivo j� existe.%n%nDeseja sobrescrev�-lo?
ExistingFileNewer=O arquivo existente � mais novo do que o Instalador est� tentando instalar. � recomendado que voc� mantenha o arquivo existente. Deseja manter o arquivo existente?
ErrorChangingAttr=Um erro ocorreu enquanto tentava mudar as propriedades do arquivo existente:
ErrorCreatingTemp=Um erro ocorreu enquanto tentava criar um arquivo no diret�rio de destino:
ErrorReadingSource=Um erro ocorreu enquanto tentava ler o c�digo fonte:
ErrorCopying=Um erro ocorreu enquanto tentva copiar o arquivo:
ErrorReplacingExistingFile=Um erro ocorreu enquanto tentava substituir o arquivo existente:
ErrorRestartReplace=Reinicio de Substitui��o falhou:
ErrorRenamingTemp=Um erro ocorreu enquanto tentava renomear um arquivo no diret�rio de destino:
ErrorRegisterServer=N�o foi poss�vel registar a DLL/OCX:%1
ErrorRegisterServerMissingExport=A exporta��o da DllRegisterServer n�o foi encontrada
ErrorRegisterTypeLib=N�o foi poss�vel registrar a biblioteca de tipo: %1

; *** Post-installation errors
ErrorOpeningReadme=Um erro ocorreu enquanto tentava abrir o arquivo LEIAME.
ErrorRestartingComputer=O instalador n�o conseguiu reiniciar o computador. Por favor, fa�a isso manualmente.



; *** Uninstaller messages
UninstallNotFound=O arquivo "%1" n�o existe. N�o � poss�vel desinstalar.
UninstallOpenError=O arquivo "%1" n�o pode ser aberto. N�o � poss�vel desinstal�-lo
UninstallUnsupportedVer=O arquivo de log "%1" do desinstalador est� em formato n�o reconhec�vel por esta vers�o do desinstalador. N�o � poss�vel desinstalar
UninstallUnknownEntry=Uma entrada desconhecida (%1) foi encontrada no log de desinstala��o
ConfirmUninstall=Voc� tem certeza que deseja remover complementamente %1 e todos os seus componentes?
OnlyAdminCanUninstall=Esta instala��o pode somente ser desinstalada por um usu�rio com privil�gios de administrador.
UninstallStatusLabel=Por favor aguarde enquanto %1 � removido do seu computador.
UninstalledAll=%1 foi removido com sucesso do seu computador.
UninstalledMost=Desinstala��o do %1 completa.%n%nAlguns elementos n�o puderam ser removidos. Eles podem ser removidos manualmente.
UninstalledAndNeedsRestart=Para completar a desinstala��o do %1, seu computador precisa ser reiniciado.%n%nGostaria de reinici�-lo agora?
UninstallDataCorrupted=O arquivo "%1" est� corrompido. N�o � poss�vel Desinstalar

; *** Uninstallation phase messages
ConfirmDeleteSharedFileTitle=Remover Arquivo Compartilhado?

ConfirmDeleteSharedFile2=O sistema informa que os seguintes arquivos compatilhados n�o est�o mais em uso por nenhum programa. Voc� gostaria que estes arquivos compartilhados sejam removidos?%n%nSe algum programa ainda estiver usando este arquivo e ele for removido, estes programas podem n�o mais funcionar corretamente. Se voc� n�o tiver certeza, escolha N�o. Deixando o arquivo no seu sistema n�o lhe causar� mal algum.


SharedFileNameLabel=Nome do Arquivo:
SharedFileLocationLabel=Localiza��o:
WizardUninstalling=Status da Desinstala��o
StatusUninstalling=Desinstalando %1...

; The custom messages below aren't used by Setup itself, but if you make
; use of them in your scripts, you'll want to translate them.

[CustomMessages]

NameAndVersion=%1 vers�o %2
AdditionalIcons=�cones adicionais:
CreateDesktopIcon=Criar um �cone na �rea de traba&lho
CreateQuickLaunchIcon=Criar um �cone na Iniciali&za��o R�pida
ProgramOnTheWeb=%1 na Internet
UninstallProgram=Desinstalar %1
LaunchProgram=Executar %1
AssocFileExtension=&Associar %1 com a extens�o do arquivo %2
AssocingFileExtension=Associar %1 com a extens�o do arquivo %2...
