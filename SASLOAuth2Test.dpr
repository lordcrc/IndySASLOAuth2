program SASLOAuth2Test;

uses
  Vcl.Forms,
  FMain in 'FMain.pas' {Main},
  SASLXOAuth2 in 'SASLXOAuth2.pas';

{$R *.res}

begin
  ReportMemoryLeaksOnShutdown := True;

  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMain, Main);
  Application.Run;
end.
