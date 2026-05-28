program XtreamFlowDelphi;

uses
  Forms,
  uMain in 'uMain.pas' {MainForm};

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'Xtream IPTV Flow Desktop';
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
