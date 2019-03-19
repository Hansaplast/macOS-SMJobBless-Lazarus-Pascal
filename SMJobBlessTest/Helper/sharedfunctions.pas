{
	SMJobBlessHelper - shared unit
	
	Test to create a privileged helper tool with Lazarus Pascal
	(C) 2019 Hans Luijten
	https://www.tweaking4all.com
}
unit SharedFunctions;

{$mode objfpc}{$H+}

interface

Uses MacOSAll;

const HelperVersion = 'VERSION 0.2';

function CFStrToAnsiStr(cfStr: CFStringRef; encoding: CFStringEncoding = kCFStringEncodingWindowsLatin1): AnsiString;

implementation

{
  Convert CFStringRef to a Pascal AnsiString
}
function CFStrToAnsiStr(cfStr: CFStringRef; encoding: CFStringEncoding = kCFStringEncodingWindowsLatin1): AnsiString;
var
  StrPtr   : Pointer;
  StrRange : CFRange;
  StrSize  : CFIndex;
begin
  if cfStr = nil then
    begin
      Result := '';
      Exit;
    end;

   {First try the optimized function}
  StrPtr := CFStringGetCStringPtr(cfStr, encoding);

  if StrPtr <> nil then  {Succeeded?}
    Result := PChar(StrPtr)
  else  {Use slower approach - see comments in CFString.pas}
    begin
      StrRange.location := 0;
      StrRange.length := CFStringGetLength(cfStr);

       {Determine how long resulting string will be}
      CFStringGetBytes(cfStr, StrRange, encoding, Ord('?'), False, nil, 0, StrSize);
      SetLength(Result, StrSize);  {Expand string to needed length}

      if StrSize > 0 then  {Convert string?}
        CFStringGetBytes(cfStr, StrRange, encoding, Ord('?'), False, @Result[1], StrSize, StrSize);
    end;
end;

end.

