program GUIDelphiDevShell;

uses
  Vcl.Forms,
  uAbout in 'uAbout.pas' {FrmAbout},
  uCheckUpdate in 'uCheckUpdate.pas' {FrmCheckUpdate},
  uWinInet in 'uWinInet.pas',
  uUpdatesChanges in 'uUpdatesChanges.pas' {FrmUpdateChanges},
  Vcl.Styles.WebBrowser in 'Vcl.Styles.WebBrowser.pas',
  uMisc in 'uMisc.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFrmAbout, FrmAbout);
  Application.Run;
end.
