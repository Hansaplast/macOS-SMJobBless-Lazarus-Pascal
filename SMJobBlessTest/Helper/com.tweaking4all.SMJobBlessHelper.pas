{
	SMJobBlessHelper
	
	Test to create a privileged helper tool with Lazarus Pascal
	(C) 2019 Hans Luijten
	https://www.tweaking4all.com
}
program com.tweaking4all.SMJobBlessHelper;
{$linkframework ServiceManagement}
{$linkframework Security}
{$linkframework Foundation}
{$linkframework CoreFoundation}
{$calling mwpascal}

// Comment this out to not have debug messages in the console:
{$DEFINE DEBUG}

uses Classes, SysUtils {$IFDEF DEBUG}, CocoaAll {$ENDIF}, MacOSAll, BaseUnix, dateutils,
  SharedFunctions;

var
  TerminateHelper:boolean;
  DoSomethingComplicated: boolean;

function ReceiveMessage(local:CFMessagePortRef; msgid: SInt32; data: CFDataRef; info:Pointer): CFDataRef; mwpascal;
var
  messageString:CFStringRef;
  messagePascalStr:string;
  returnString:string;
  returnData:CFDataRef;
begin
  messageString:=CFStringCreateFromExternalRepresentation(nil,data,kCFStringEncodingUTF8);
  {$IFDEF DEBUG} NSLog(NSSTR('SMJOBBLESS HELPER: Received Message = %@'),messageString); {$ENDIF}
  messagePascalStr:=CFStrToAnsiStr(messageString);

  if messagePascalStr='GETVERSION' then
    begin
      {$IFDEF DEBUG} NSLog(NSSTR('SMJOBBLESS HELPER: CMD - GET VERSION')); {$ENDIF}
      returnString := HelperVersion;
    end
  else if messagePascalStr='ACTIVE' then
    begin
      {$IFDEF DEBUG} NSLog(NSSTR('SMJOBBLESS HELPER: CMD - CHECK IF ACTIVE')); {$ENDIF}
      returnString := BoolToStr(DoSomethingComplicated,'YES','NO');
    end
  else if messagePascalStr='DOSOMETHING' then
    begin
      {$IFDEF DEBUG} NSLog(NSSTR('SMJOBBLESS HELPER: CMD - DO SOMETHING COMPLICATED')); {$ENDIF}
      returnString := 'Doing something';
      DoSomethingComplicated := true;
    end
  else if messagePascalStr='ABORT' then
    begin
      {$IFDEF DEBUG} NSLog(NSSTR('SMJOBBLESS HELPER: CMD - ABORT DO SOMETHING COMPLICATED')); {$ENDIF}
      returnString := 'Stop doing something';
      DoSomethingComplicated := false;
    end
  else if messagePascalStr='LASTERROR' then
    begin
      {$IFDEF DEBUG} NSLog(NSSTR('SMJOBBLESS HELPER: CMD - GET LAST ERROR')); {$ENDIF}
      returnString := 'All is fine here';
    end
  else if messagePascalStr='QUITHELPER' then
    begin
      {$IFDEF DEBUG} NSLog(NSSTR('SMJOBBLESS HELPER: CMD - QUITHELPER')); {$ENDIF}
      returnString := 'Quiting Helper Tool';
      TerminateHelper:=true;
    end
  else 
    begin
      {$IFDEF DEBUG} NSLog(NSSTR('SMJOBBLESS HELPER: CMD - UNKNOWN')); {$ENDIF}
      returnString := 'UNKNOWN COMMAND';
    end;

  returndata := CFStringCreateExternalRepresentation(nil,CFSTR(PChar(returnString)),kCFStringEncodingUTF8,0);

  Result := returnData;
end;


// ***** MAIN *****

var
  tmpString:string;
  receivingPort:CFMessagePortRef;
  receivingRunLoop:CFRunLoopSourceRef;
  context: CFMessagePortContext;
  shouldFreeInfo:boolean;
  reason:SInt32;
begin
  tmpString := 'Started at '+TimeToStr(Now)+': UID='+IntToStr(FpGetUID)+' ,EUID='+IntToStr(FpGetEUID)+' ,PID='+IntToStr(FpGetPID);
  {$IFDEF DEBUG} NSLog(NSSTR('SMJOBBLESS HELPER: %@'),NSSTR(PChar(tmpString))); {$ENDIF}

  TerminateHelper := false;
  DoSomethingComplicated := false;

  receivingPort:=CFMessagePortCreateLocal(nil,CFSTR('com.tweaking4all.SMJobBlessHelper'),@ReceiveMessage,context,shouldFreeInfo);

  {$IFDEF DEBUG}
  if receivingPort=nil then
    NSLog(NSSTR('SMJOBBLESS HELPER: FAILED CFMessagePortCreateLocal'))
  else
    NSLog(NSSTR('SMJOBBLESS HELPER: SUCCESS CFMessagePortCreateLocal'));
  {$ENDIF}

  receivingRunLoop:= CFMessagePortCreateRunLoopSource(nil, receivingPort, 0);

  {$IFDEF DEBUG}
  if receivingRunLoop=nil then
    NSLog(NSSTR('SMJOBBLESS HELPER: FAILED CFMessagePortCreateRunLoopSource'))
  else
    NSLog(NSSTR('SMJOBBLESS HELPER: SUCCESS CFMessagePortCreateRunLoopSource'));

  NSLog(NSSTR('SMJOBBLESS HELPER: Executing CFRunLoopAddSource'));
  {$ENDIF}

  CFRunLoopAddSource(CFRunLoopGetCurrent(), receivingRunLoop, kCFRunLoopDefaultMode);

  {$IFDEF DEBUG} NSLog(NSSTR('SMJOBBLESS HELPER: Executing CFRunLoopRunInMode')); {$ENDIF}
  repeat
    reason := CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1, false);
    // my loop:
    if DoSomethingComplicated then
      begin
        NSLog(NSSTR('SMJOBBLESS HELPER: Doing Something Complicated at %@'),NSSTR(PChar(TimeToStr(Now))));
        sleep(200);
      end;
  until (reason<>kCFRunLoopRunTimedOut) or TerminateHelper;

  {$IFDEF DEBUG} NSLog(NSSTR('SMJOBBLESS HELPER: BEYOND CFRunLoopRun (Terminating)')); {$ENDIF}

  CFRelease(receivingPort);
  ExitCode:=0;
end.

