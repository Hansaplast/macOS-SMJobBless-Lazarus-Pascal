{
	SMJobBlessApp
	
	Test to create a privileged helper tool with Lazarus Pascal
	(C) 2019 Hans Luijten
	https://www.tweaking4all.com
}
unit Unit1;

{$mode objfpc}{$H+}
{$calling mwpascal}
{$linkframework ServiceManagement}
{$linkframework Security}
{$linkframework Foundation}
{$linkframework CoreFoundation}

// Comment this to not have debug messages in the console:
{$DEFINE DEBUG}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ComCtrls,
  ExtCtrls, MacOSAll, CocoaAll, dateutils, SharedFunctions;

type

  { TForm1 }

  TForm1 = class(TForm)
    btnComplicatedTask: TButton;
    btnInit: TButton;
    btnGetVersion: TButton;
    btnIsActive: TButton;
    btnAbort: TButton;
    btnLastError: TButton;
    btnQuit: TButton;
    memoMessages: TMemo;
    procedure btnAbortClick(Sender: TObject);
    procedure btnComplicatedTaskClick(Sender: TObject);
    procedure btnGetStatusClick(Sender: TObject);
    procedure btnInitClick(Sender: TObject);
    procedure btnGetVersionClick(Sender: TObject);
    procedure btnIsActiveClick(Sender: TObject);
    procedure btnQuitClick(Sender: TObject);
    procedure btnLastErrorClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
  private
    messageID : SInt32; // Generate MsdID's by counting, start at zero.
    startTime : TDateTime;
    function InitializePrivilegedHelperTool:boolean;
    function installHelperTool:boolean;
    function HelperToolIsActive(SecondsTimeOut:integer = 30):boolean;
    function SendMessage(aMessage:string):string;
  public

  end;

var
  Form1: TForm1;


// Imports
function SMJobBless(domain:CFStringRef; executableLabel:CFStringRef; auth:AuthorizationRef; outError:CFErrorRef): boolean; external name '_SMJobBless'; mwpascal;
var kSMDomainSystemLaunchd: CFStringRef; external name '_kSMDomainSystemLaunchd';

const
  kSMRightBlessPrivilegedHelper	= 'com.apple.ServiceManagement.blesshelper';
  helperLabel = 'com.tweaking4all.SMJobBlessHelper';

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.btnInitClick(Sender: TObject);
begin
  InitializePrivilegedHelperTool;
end;

procedure TForm1.btnGetVersionClick(Sender: TObject);
begin
  SendMessage('GETVERSION');
end;

procedure TForm1.btnIsActiveClick(Sender: TObject);
begin
  SendMessage('ACTIVE');
end;

procedure TForm1.btnQuitClick(Sender: TObject);
begin
  SendMessage('QUITHELPER');
  memoMessages.Append('Quiting helper');
end;

procedure TForm1.btnLastErrorClick(Sender: TObject);
begin
  memoMessages.Append('Last Error: '+SendMessage('LASTERROR'));
end;

procedure TForm1.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  SendMessage('QUITHELPER');
end;

procedure TForm1.btnComplicatedTaskClick(Sender: TObject);
begin
  SendMessage('DOSOMETHING');
end;

procedure TForm1.btnAbortClick(Sender: TObject);
begin
  SendMessage('ABORT');
end;

procedure TForm1.btnGetStatusClick(Sender: TObject);
begin
  SendMessage('STATUS');
end;

function TForm1.SendMessage(aMessage:string):string;
var
  data, returndata:CFDataRef;
  messageString:string;
  status:SInt32;
  timeout:CFTimeInterval;
  HelperPort:CFMessagePortRef;
  answerCFString:CFStringRef;
begin
  timeout   := 1; // 2 second timeout
  inc(messageID);
  Result:='';

  { Create a communication port }

  HelperPort := CFMessagePortCreateRemote(nil, CFSTR(helperLabel));

  { Check if port opened - if not; try to re-install the Helper Tool }

  if (HelperPort=nil) then
    begin
      {$IFDEF DEBUG} NSLog(NSSTR('SMJOBBLESS APP: Failed to Connect to Helper Tool')); {$ENDIF}
      Result:='';
      exit;
    end;

  { Verify Helper Tool version - in case of needed update }

  {$IFDEF DEBUG} NSLog(NSSTR('SMJOBBLESS APP: Sending Message = %@'),CFSTR(PChar(aMessage))); {$ENDIF}
  memoMessages.Append('Send Msg = '+aMessage);

  messageString := aMessage;
  data := CFStringCreateExternalRepresentation(nil,CFSTR(PChar(messageString)),kCFStringEncodingUTF8,0);

  status := CFMessagePortSendRequest(HelperPort,
                                     messageID,
                                     data,
                                     timeout,
                                     timeout,
                                     kCFRunLoopDefaultMode,
                                     @returndata);

  { Message sent? - Yes: Check version and reinstall if needed }
  if status = kCFMessagePortSuccess then
    begin
      if returndata=nil then
        {$IFDEF DEBUG}
        NSLog(NSSTR('SMJOBBLESS APP: Reply Received (SendMessage - empty)'))
        {$ELSE}
        //
        {$ENDIF}
      else if returndata<>nil then
        begin
          { Copy Answer }
          answerCFString := CFStringCreateFromExternalRepresentation(nil,returndata,kCFStringEncodingUTF8);
          Result         := CFStrToAnsiStr(answerCFString);

          {$IFDEF DEBUG} NSLog(NSSTR('SMJOBBLESS APP: Reply received: %@'),answerCFString); {$ENDIF}
          memoMessages.Append('Reply Received = '+Result);
          CFrelease(answerCFString);
        end;
    end;

  if HelperPort<>nil then CFRelease(HelperPort);
end;

function TForm1.InitializePrivilegedHelperTool:boolean;
var
  data, returndata:CFDataRef;
  messageString:string;
  status:SInt32;
  timeout:CFTimeInterval;
  HelperPort:CFMessagePortRef;
  errorString:string;
  answerString:CFStringRef;
begin
  messageID := 0; // start counting messages at "0"
  timeout   := 2; // 1 second timeout

  { Create a communication port }

  HelperPort := CFMessagePortCreateRemote(nil, CFSTR(helperLabel));

  { Check if port opened - if not; try to re-install the Helper Tool }

  if (HelperPort=nil) and not(installHelperTool) then
    begin
      {$IFDEF DEBUG} NSLog(NSSTR('SMJOBBLESS APP: Failed to Install and/or Connect to Helper Tool')); {$ENDIF}
      memoMessages.Append('Failed to Install and/or Connect to Helper Tool');
      Result:=false;
      exit;
    end;

  { Verify Helper Tool version - in case of needed update }

  {$IFDEF DEBUG} NSLog(NSSTR('SMJOBBLESS APP: Requesting Version Number')); {$ENDIF}
  messageString := 'GETVERSION';
  data := CFStringCreateExternalRepresentation(nil,CFSTR(PChar(messageString)),kCFStringEncodingUTF8,0);

  status := CFMessagePortSendRequest(HelperPort,
                                     messageID,
                                     data,
                                     timeout,
                                     timeout,
                                     kCFRunLoopDefaultMode,
                                     @returndata);

  { Message sent? - Yes: Check version and reinstall if needed }
  if status = kCFMessagePortSuccess then
    begin
      if returndata=nil then
        begin
          {$IFDEF DEBUG} NSLog(NSSTR('SMJOBBLESS APP: Reply Received (empty)')); {$ENDIF}
          memoMessages.Lines.Add('SMJOBBLESS APP: Reply Received (empty)');
        end
      else if returndata<>nil then
        begin
          { Copy Answer }

          answerString:=CFStringCreateFromExternalRepresentation(nil,returndata,kCFStringEncodingUTF8);
          {$IFDEF DEBUG} NSLog(NSSTR('SMJOBBLESS APP: Version received: %@'),answerString); {$ENDIF}

          { Check version and update if needed, by doing it all again }

          if CFStringCompare(answerString,CFSTR(HelperVersion),kCFCompareCaseInsensitive)<>kCFCompareEqualTo then
            begin
              {$IFDEF DEBUG} NSLog(NSSTR('SMJOBBLESS APP: Found Wrong Helper version (%@ but need %@) - Updating Helper'),answerString, CFSTR(HelperVersion)); {$ENDIF}
              memoMessages.Lines.Add('Found Wrong Helper version ('+CFStrToAnsiStr(answerString)+' but need '+HelperVersion+') - Updating Helper');
              CFRelease(HelperPort);

              if installHelperTool then
                begin
                  Result := InitializePrivilegedHelperTool();
                  exit;
                end
              else
                begin
                  Result:=false;
                  exit;
                end;
            end
          else
            begin
              {$IFDEF DEBUG} NSLog(NSSTR('SMJOBBLESS APP: Found Correct Helper version (%@) - Updating Helper'),answerString); {$ENDIF}
              memoMessages.Lines.Add('Found Correct Helper version ('+CFStrToAnsiStr(answerString)+')');
            end;

        end;
    end
  else
  { Message sent? - Nope: Log Error and try reinstall }
    begin
      case status of
        kCFMessagePortSendTimeout        : errorString := 'Port Send Timeout';
	kCFMessagePortReceiveTimeout     : errorString := 'Port Receive Timeout';
	kCFMessagePortIsInvalid          : errorString := 'Invalid Port';
	kCFMessagePortTransportError     : errorString := 'Transport Error';
	kCFMessagePortBecameInvalidError : errorString := 'Port Became Invalid';
        else errorString := 'Undefined Error';
      end;

      {$IFDEF DEBUG} NSLog(NSSTR('SMJOBBLESS APP: Message error: %@ (Attempting Install the Helper Tool now)'),NSSTR(PChar(errorString))); {$ENDIF}

      if installHelperTool then
        InitializePrivilegedHelperTool()
      else
        memoMessages.Lines.Add('Couldn''t get the Helper Tool to run properly');
    end;

  if data<>nil then CFRelease(data);
  if HelperPort<>nil then CFRelease(HelperPort);
end;

function TForm1.HelperToolIsActive(SecondsTimeOut:integer = 30):boolean;
var
  HelperPort:CFMessagePortRef;
  TimeOutTime:TDateTime;
begin
  TimeOutTime := IncSecond(Now,SecondsTimeOut);

  { Tries to open a port to the Helper Tool }

  repeat
    sleep(300);
    HelperPort := CFMessagePortCreateRemote(nil, CFSTR(helperLabel));
    {$IFDEF DEBUG} NSLog(NSSTR('SMJOBBLESS APP: Checking if Helper Tool is Responding')); {$ENDIF}
    memoMessages.Append('Checking if Helper Tool is Responding');
  until (HelperPort<>nil) or (Now>TimeOutTime);

  { If no port is opened -> Fail! }

  if HelperPort=nil then
    begin
      {$IFDEF DEBUG}NSLog(NSSTR('SMJOBBLESS APP: Helper Tool is not Responding'));{$ENDIF}
      memoMessages.Append('Helper Tool is not Responding');
    end
  else
    begin
      {$IFDEF DEBUG}NSLog(NSSTR('SMJOBBLESS APP: Helper Tool Responded!'));{$ENDIF}
      memoMessages.Append('Helper Tool Responded!');
    end;


  Result := HelperPort<>nil;

  if HelperPort<>nil then CFRelease(HelperPort);
end;

function TForm1.installHelperTool:boolean;
var
  status:OSStatus;
  authItem: AuthorizationItem;
  authRights: AuthorizationRights;
  authFlags: AuthorizationFlags;
  authRef: AuthorizationRef;
  error:NSError;
  AuthenticationCount:integer;
begin
  Result := False;

  { Get proper Authentication }

  authItem.flags := 0;
  authItem.name  := kSMRightBlessPrivilegedHelper;
  authItem.value := nil;
  authItem.valueLength:= 0;

  authRights.count := 1;
  authRights.items := @authItem;

  authFlags := kAuthorizationFlagDefaults or kAuthorizationFlagInteractionAllowed or kAuthorizationFlagPreAuthorize or kAuthorizationFlagExtendRights;

  authRef := nil;
  error   := nil;

  AuthenticationCount:=0;

  { Get authentication to install helper }

  status := AuthorizationCreate(@authRights, kAuthorizationEmptyEnvironment, authFlags, authRef);

  if status<>errAuthorizationSuccess then
    begin
      {$IFDEF DEBUG} NSLog(NSSTR('SMJOBBLESS APP: Authentication Failed (Error %d)'),AuthenticationCount, status); {$ENDIF}
      memoMessages.Append('Authentication Failed');
      Result := false;
      Exit;
    end;

  { Attempt Helper Tool install if authentication succeeds }

  if status=errAuthorizationSuccess then
    begin
      {$IFDEF DEBUG} NSLog(NSSTR('SMJOBBLESS APP: Trying to install Helper tool')); {$ENDIF}

      { SMJobBless - Try to actually installl privileged helper tool - overwrites any existing version automatically }
      Result := SMJobBless(kSMDomainSystemLaunchd,CFSTR(helperLabel),authRef,@error);
      if Result then
        begin
          {$IFDEF DEBUG} NSLog(NSSTR('SMJOBBLESS APP: Helper Tool Installed')); {$ENDIF}
          memoMessages.Append('Helper installed');
          Result := HelperToolIsActive; // Check if the Helper tool responds
        end
      else
        begin
          {$IFDEF DEBUG} NSLog(NSSTR('SMJOBBLESS APP: Helper Install Failed (Error: %@)'),error); {$ENDIF}
        end;
    end
  else
    begin
      {$IFDEF DEBUG} NSLog(NSSTR('SMJOBBLESS APP: Authentication Failed (Status: %d)'),status); {$ENDIF}
       memoMessages.Append('Helper Install Authentication Failed');
    end;

  AuthorizationFree(authRef,0);
end;

end.

