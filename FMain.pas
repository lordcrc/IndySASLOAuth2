//   Copyright 2014 Asbjørn Heid
//
//   Licensed under the Apache License, Version 2.0 (the "License");
//   you may not use this file except in compliance with the License.
//   You may obtain a copy of the License at
//
//       http://www.apache.org/licenses/LICENSE-2.0
//
//   Unless required by applicable law or agreed to in writing, software
//   distributed under the License is distributed on an "AS IS" BASIS,
//   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//   See the License for the specific language governing permissions and
//   limitations under the License.

unit FMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, IdIOHandler, IdIOHandlerSocket,
  IdIOHandlerStack, IdSSL, IdSSLOpenSSL, IdBaseComponent, IdComponent,
  IdTCPConnection, IdTCPClient, IdExplicitTLSClientServerBase, IdMessageClient,
  IdIMAP4, Vcl.StdCtrls, Vcl.ExtCtrls, SASLXOAuth2, REST.Authenticator.OAuth;

type
  TMain = class(TForm)
    imap: TIdIMAP4;
    sslio: TIdSSLIOHandlerSocketOpenSSL;
    lbMailboxes: TListBox;
    btnListMailboxes: TButton;
    edClientID: TLabeledEdit;
    edClientSecret: TLabeledEdit;
    edEmail: TLabeledEdit;
    chkUseSSL: TCheckBox;
    btnResetAuth: TButton;
    function sslioVerifyPeer(Certificate: TIdX509; AOk: Boolean; ADepth,
      AError: Integer): Boolean;
    procedure FormCreate(Sender: TObject);
    procedure btnListMailboxesClick(Sender: TObject);
    procedure btnResetAuthClick(Sender: TObject);
  private
    { Private declarations }
    saslXOAuth2: TSASLXOAuth2;

    procedure LoadSettings;
    procedure SaveSettings;

    procedure InitializeGoogleOAuth2Settings;
    procedure InitializeIMAP;
    procedure PrepareAuthentication;

    procedure OAuth2_Google_BrowserTitleChanged(const ATitle: string; var DoCloseWebView : boolean);
  public
    { Public declarations }
  end;

var
  Main: TMain;

implementation

uses
  System.IniFiles, System.StrUtils, IdException, IdReplyIMAP4;

{$R *.dfm}

procedure TMain.btnListMailboxesClick(Sender: TObject);
var
  i: integer;
begin
  lbMailboxes.Clear;
  SaveSettings;

  InitializeIMAP;

  // try logging in a few times
  for i := 0 to 2 do
  begin
    // if not authenticated we try again or raise an exception
    PrepareAuthentication;

    try
      if (not imap.Connected) then
        imap.Connect(False);

      imap.Login;
    except
      on E: EIdSilentException do;
      on E: EIdReplyIMAP4Error do
      begin
        if (saslXOAuth2.StatusCode <> '') then
        begin
          if (saslXOAuth2.StatusCode = '400') then
          begin
            // from what I can gather, 400 means access token has expired
            // in any case need to get new access token
            saslXOAuth2.ResetAuth;
            SaveSettings;
          end
          else
            // 401 is invalid credentials or similar
            raise Exception.Create('Server replied ' + saslXOAuth2.StatusCode + ' ' + saslXOAuth2.ErrorScope);
        end
        else
          raise;
      end;
    end;
    if imap.ConnectionState = csAuthenticated then
      break;
  end;

  imap.ListMailBoxes(lbMailboxes.Items);

  // we're done
  imap.DisconnectNotifyPeer;
end;

procedure TMain.btnResetAuthClick(Sender: TObject);
begin
  saslXOAuth2.ResetAuth;
  SaveSettings;
end;

procedure TMain.FormCreate(Sender: TObject);
begin
  saslXOAuth2 := TSASLXOAuth2.Create(Self);

  LoadSettings;
end;

procedure TMain.InitializeGoogleOAuth2Settings;
var
  accessToken: string;
  refreshToken: string;
begin
  // site specific
  imap.Host := 'imap.gmail.com';
  imap.Port := 993;

  accessToken := saslXOAuth2.AccessToken;
  refreshToken := saslXOAuth2.RefreshToken;

  saslXOAuth2.AccessTokenEndpoint := 'https://accounts.google.com/o/oauth2/token';
  saslXOAuth2.AuthorizationEndpoint := 'https://accounts.google.com/o/oauth2/auth';
  saslXOAuth2.RedirectionEndpoint := 'urn:ietf:wg:oauth:2.0:oob';
  saslXOAuth2.ResponseType := TOAuth2ResponseType.rtCODE;
  saslXOAuth2.Scope := 'https://mail.google.com/';
  saslXOAuth2.OnAuthWebFormTitleChanged := OAuth2_Google_BrowserTitleChanged;

  saslXOAuth2.AccessToken := accessToken;
  saslXOAuth2.RefreshToken := refreshToken;
end;

procedure TMain.InitializeIMAP;
begin
  imap.ConnectTimeout := 10000;

  imap.IOHandler := nil;
  if chkUseSSL.Checked then
  begin
    sslio.Host := imap.Host;
    sslio.Port := imap.Port;
    sslio.ConnectTimeout := 30000;

    imap.IOHandler := sslio;
    imap.UseTLS := utUseImplicitTLS;
  end;
end;

procedure TMain.LoadSettings;
var
  ini: TMemIniFile;
begin
  ini := nil;
  try
    ini := TMemIniFile.Create('settings.ini');

    edClientID.Text := ini.ReadString('OAuth2', 'ClientID', '');
    edClientSecret.Text := ini.ReadString('OAuth2', 'ClientSecret', '');
    saslXOAuth2.AccessToken := ini.ReadString('OAuth2', 'AccessToken', '');
    saslXOAuth2.RefreshToken := ini.ReadString('OAuth2', 'RefreshToken', '');

    edEmail.Text := ini.ReadString('IMAP', 'Username', '');
    chkUseSSL.Checked := ini.ReadBool('IMAP', 'UseSSL', True);
  finally
    ini.Free;
  end;
end;

procedure TMain.OAuth2_Google_BrowserTitleChanged(const ATitle: string;
  var DoCloseWebView: boolean);
begin
  if (StartsText('Success code', ATitle)) then
  begin
    saslXOAuth2.AuthCode := Copy(ATitle, 14, Length(ATitle));

    if (saslXOAuth2.AuthCode <> '') then
      DoCloseWebView := True;
  end;
end;

procedure TMain.PrepareAuthentication;
begin
  InitializeGoogleOAuth2Settings;

  saslXOAuth2.ClientID := edClientID.Text;
  saslXOAuth2.ClientSecret := edClientSecret.Text;
  saslXOAuth2.Username := edEmail.Text;

  // aquiring an access token may be a lengthy process,
  // so do this before we connect
  saslXOAuth2.AquireAccessToken;

  SaveSettings;

  if (saslXOAuth2.AccessToken = '') then
    raise Exception.Create('No access token');

  imap.Username := saslXOAuth2.Username;

  imap.AuthType := iatSASL;
  imap.SASLMechanisms.Clear;
  imap.SASLMechanisms.Add.SASL := saslXOAuth2;
end;

procedure TMain.SaveSettings;
var
  ini: TMemIniFile;
begin
  ini := nil;
  try
    ini := TMemIniFile.Create('settings.ini');

    ini.WriteString('OAuth2', 'ClientID', edClientID.Text);
    ini.WriteString('OAuth2', 'ClientSecret', edClientSecret.Text);
    ini.WriteString('OAuth2', 'AccessToken', saslXOAuth2.AccessToken);
    ini.WriteString('OAuth2', 'RefreshToken', saslXOAuth2.RefreshToken);

    ini.WriteString('IMAP', 'Username', edEmail.Text);
    ini.WriteBool('IMAP', 'UseSSL', chkUseSSL.Checked);

    ini.UpdateFile;
  finally
    ini.Free;
  end;
end;

function TMain.sslioVerifyPeer(Certificate: TIdX509; AOk: Boolean; ADepth,
  AError: Integer): Boolean;
begin
  // NSA will listen anyway
  result := True;
end;

end.
