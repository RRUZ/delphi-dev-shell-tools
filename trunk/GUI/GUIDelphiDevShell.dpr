program GUIDelphiDevShell;

uses
  Vcl.Forms,
  Windows,
  uAbout in 'uAbout.pas' {FrmAbout},
  uCheckUpdate in 'uCheckUpdate.pas' {FrmCheckUpdate},
  uWinInet in 'uWinInet.pas',
  uUpdatesChanges in 'uUpdatesChanges.pas' {FrmUpdateChanges},
  Vcl.Styles.WebBrowser in 'Vcl.Styles.WebBrowser.pas',
  uMisc in 'uMisc.pas',
  Vcl.Themes,
  Vcl.Styles;

{$R *.res}

procedure OnlyOne;
var
    hWnd, hMutex : THandle;
    lpName      : PWideChar;
begin
  lpName := PWideChar(Application.Title);
  hMutex := CreateMutex (nil, FALSE, lpName );
  if WaitForSingleObject (hMutex, 0) = wait_TimeOut then
  begin
     SetWindowText(Application.Handle,'');
     hWnd := FindWindow(nil,lpName);
     if hWnd<>0 then
     begin
        if IsIconic(hWnd) then ShowWindow(hWnd, SW_RESTORE);
        BringWindowToTop(hWnd);
        SetForegroundWindow(hWnd);
     end;
     Application.ShowMainForm := False;
     Application.Terminate;
     Halt(0);
  end;
end;


begin
  OnlyOne;
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  TStyleManager.TrySetStyle('Amakrits');
  Application.CreateForm(TFrmAbout, FrmAbout);
  Application.Run;
end.
