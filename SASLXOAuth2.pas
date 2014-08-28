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

unit SASLXOAuth2;

interface

uses
  IdSASL,
  REST.Authenticator.OAuth,
  REST.Authenticator.OAuth.WebForm.Win;

type
  TOAuth2ResponseType = REST.Authenticator.OAuth.TOAuth2ResponseType;

  TSASLXOAuth2 = class(TIdSASL)
  private
    FOAuth2Authenticator: TOAuth2Authenticator;
    FOnAuthWebFormAfterRedirect: TOAuth2WebFormRedirectEvent;
    FOnAuthWebFormBeforeRedirect: TOAuth2WebFormRedirectEvent;
    FOnAuthWebFormBrowserTitleChanged : TOAuth2WebFormTitleChangedEvent;
    FUsername: string;
    FStatusCode: string;
    FErrorScope: string;
    FErrorSchemes: string;

    function GetAccessToken: string;
    function GetClientID: string;
    function GetClientSecret: string;
    function GetRefreshToken: string;
    function GetAuthCode: string;
    function GetAccessTokenEndpoint: string;
    function GetAuthorizationEndpoint: string;
    function GetRedirectionEndpoint: string;
    function GetResponseType: TOAuth2ResponseType;
    function GetScope: string;
    procedure SetUsername(const Value: string);
    procedure SetAccessToken(const Value: string);
    procedure SetClientID(const Value: string);
    procedure SetClientSecret(const Value: string);
    procedure SetRefreshToken(const Value: string);
    procedure SetAuthCode(const Value: string);
    procedure SetAccessTokenEndpoint(const Value: string);
    procedure SetAuthorizationEndpoint(const Value: string);
    procedure SetRedirectionEndpoint(const Value: string);
    procedure SetResponseType(const Value: TOAuth2ResponseType);
    procedure SetScope(const Value: string);
  protected
    procedure InitComponent; override;

    property OAuth2Authenticator: TOAuth2Authenticator read FOAuth2Authenticator;
  public
    //constructor Create(
    class function ServiceName: TIdSASLServiceName; override;

    function TryStartAuthenticate(const AHost, AProtocolName : string; var VInitialResponse: String): Boolean; override;
    function StartAuthenticate(const AChallenge, AHost, AProtocolName : string) : String; override;
    function ContinueAuthenticate(const ALastResponse, AHost, AProtocolName : String): String; override;

    procedure AquireAccessToken;
    procedure ResetAuth;
    
    property StatusCode: string read FStatusCode;
    property ErrorSchemes: string read FErrorSchemes;
    property ErrorScope: string read FErrorScope;

    property Username: string read FUsername write SetUsername;
    property AccessToken: string read GetAccessToken write SetAccessToken;
    property RefreshToken: string read GetRefreshToken write SetRefreshToken;

    property AuthCode: string read GetAuthCode write SetAuthCode;
        
    property ClientID: string read GetClientID write SetClientID;
    property ClientSecret: string read GetClientSecret write SetClientSecret;
    property AccessTokenEndpoint: string read GetAccessTokenEndpoint write SetAccessTokenEndpoint;
    property AuthorizationEndpoint: string read GetAuthorizationEndpoint write SetAuthorizationEndpoint;
    property RedirectionEndpoint: string read GetRedirectionEndpoint write SetRedirectionEndpoint;
    property ResponseType: TOAuth2ResponseType read GetResponseType write SetResponseType;
    property Scope: string read GetScope write SetScope;
    
    property OnAuthWebFormAfterRedirect: TOAuth2WebFormRedirectEvent read FOnAuthWebFormAfterRedirect write FOnAuthWebFormAfterRedirect;
    property OnAuthWebFormBeforeRedirect: TOAuth2WebFormRedirectEvent read FOnAuthWebFormBeforeRedirect write FOnAuthWebFormBeforeRedirect;
    property OnAuthWebFormTitleChanged : TOAuth2WebFormTitleChangedEvent read FOnAuthWebFormBrowserTitleChanged write FOnAuthWebFormBrowserTitleChanged;
  end;

implementation

uses
  System.SysUtils, Vcl.Forms, System.JSON, REST.Utils, IPPeerClient;

{ TSASLXOAuth2 }

procedure TSASLXOAuth2.AquireAccessToken;
var
  url: string;
  wv: Tfrm_OAuthWebForm;
begin
  if (AccessToken <> '') then
    exit;

  if (ClientID = '') then
    raise Exception.Create('ClientID required');

  if (ClientSecret = '') then
    raise Exception.Create('ClientSecret required');

  url := OAuth2Authenticator.AuthorizationRequestURI;
  url := url + '&login_hint=' + URIEncode(Username);

  wv := Tfrm_OAuthWebForm.Create(self);
  try
    wv.OnAfterRedirect := FOnAuthWebFormAfterRedirect;
    wv.OnBeforeRedirect := FOnAuthWebFormBeforeRedirect;
    wv.OnTitleChanged := FOnAuthWebFormBrowserTitleChanged;
    wv.Position := poScreenCenter;
    wv.ShowModalWithURL(url);
  finally
    wv.Release;
  end;

  if (OAuth2Authenticator.AuthCode = '') then
    raise TOAuth2Exception.Create('Authentication failed');

  OAuth2Authenticator.ChangeAuthCodeToAccesToken();

  if (AccessToken = '') then
    raise TOAuth2Exception.Create('Failed to aquire access token');
end;

function TSASLXOAuth2.ContinueAuthenticate(const ALastResponse, AHost,
  AProtocolName: String): String;
var
  response: TJSONObject;
begin
  response := nil;
  try
    response := TJSONObject.ParseJSONValue(ALastResponse) as TJSONObject;

    FStatusCode := response.Values['status'].Value;
    FErrorSchemes := response.Values['schemes'].Value;
    FErrorScope := response.Values['scope'].Value;
  finally
    response.Free;
  end;
end;

function TSASLXOAuth2.GetAccessToken: string;
begin
  result := OAuth2Authenticator.AccessToken;
end;

function TSASLXOAuth2.GetAccessTokenEndpoint: string;
begin
  result := OAuth2Authenticator.AccessTokenEndpoint;
end;

function TSASLXOAuth2.GetAuthCode: string;
begin
  result := OAuth2Authenticator.AuthCode;
end;

function TSASLXOAuth2.GetAuthorizationEndpoint: string;
begin
  result := OAuth2Authenticator.AuthorizationEndpoint;
end;

function TSASLXOAuth2.GetClientID: string;
begin
  result := OAuth2Authenticator.ClientID;
end;

function TSASLXOAuth2.GetClientSecret: string;
begin
  result := OAuth2Authenticator.ClientSecret;
end;

function TSASLXOAuth2.GetRedirectionEndpoint: string;
begin
  result := OAuth2Authenticator.RedirectionEndpoint;
end;

function TSASLXOAuth2.GetRefreshToken: string;
begin
  result := OAuth2Authenticator.RefreshToken;
end;

function TSASLXOAuth2.GetResponseType: TOAuth2ResponseType;
begin
  result := OAuth2Authenticator.ResponseType;
end;

function TSASLXOAuth2.GetScope: string;
begin
  result := OAuth2Authenticator.Scope;
end;

procedure TSASLXOAuth2.InitComponent;
begin
  inherited;
  if not Assigned(OAuth2Authenticator) then
    FOAuth2Authenticator := TOAuth2Authenticator.Create(Self);
  FSecurityLevel := 1000000; // pretty darn good
end;

procedure TSASLXOAuth2.ResetAuth;
begin
  OAuth2Authenticator.ResetToDefaults;
end;

class function TSASLXOAuth2.ServiceName: TIdSASLServiceName;
begin
  Result := 'XOAUTH2';   {Do not translate}
end;

procedure TSASLXOAuth2.SetAccessToken(const Value: string);
begin
  OAuth2Authenticator.AccessToken := Value;
end;

procedure TSASLXOAuth2.SetAccessTokenEndpoint(const Value: string);
begin
  OAuth2Authenticator.AccessTokenEndpoint := Value;
end;

procedure TSASLXOAuth2.SetAuthCode(const Value: string);
begin
  OAuth2Authenticator.AuthCode := Value;
end;

procedure TSASLXOAuth2.SetAuthorizationEndpoint(const Value: string);
begin
  OAuth2Authenticator.AuthorizationEndpoint := Value;
end;

procedure TSASLXOAuth2.SetClientID(const Value: string);
begin
  OAuth2Authenticator.ClientID := Value;
end;

procedure TSASLXOAuth2.SetClientSecret(const Value: string);
begin
  OAuth2Authenticator.ClientSecret := Value;
end;

procedure TSASLXOAuth2.SetRedirectionEndpoint(const Value: string);
begin
  OAuth2Authenticator.RedirectionEndpoint := Value;
end;

procedure TSASLXOAuth2.SetRefreshToken(const Value: string);
begin
  OAuth2Authenticator.RefreshToken := Value;
end;

procedure TSASLXOAuth2.SetResponseType(const Value: TOAuth2ResponseType);
begin
  OAuth2Authenticator.ResponseType := Value;
end;

procedure TSASLXOAuth2.SetScope(const Value: string);
begin
  OAuth2Authenticator.Scope := Value;
end;

procedure TSASLXOAuth2.SetUsername(const Value: string);
begin
  FUsername := Value;
end;

function TSASLXOAuth2.StartAuthenticate(const AChallenge, AHost,
  AProtocolName: string): String;
begin
  FStatusCode := '';
  FErrorSchemes := '';
  FErrorScope := '';

  result := 'user=' + Username + #1 + 'auth=Bearer ' + AccessToken + #1#1;
end;

function TSASLXOAuth2.TryStartAuthenticate(const AHost, AProtocolName: string;
  var VInitialResponse: String): Boolean;
begin
  result := False;
end;

end.
