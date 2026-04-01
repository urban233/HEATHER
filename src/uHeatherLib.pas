unit uHeatherLib;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Process, fphttpclient{$IFDEF MSWINDOWS}, Windows{$ENDIF};

type
  { THeatherStdLib contains all our baked-in Python-parity functions }
  THeatherStdLib = class
  public
    // Console Operations
    procedure Print(const Msg: string);
    
    // Process Execution
    function Exec(const Command: string): Integer;
    function ExecOut(const Command: string): string;
    
    // File & Directory Operations
    function CopyFileStr(const Source, Dest: string; Overwrite: Boolean): Boolean;
    function CopyDir(const Source, Dest: string): Boolean;
    function RemoveDirTree(const Path: string): Boolean;
    function MakeDirs(const Path: string): Boolean;
    
    // Path Manipulation
    function JoinPath(const Path1, Path2: string): string;
    function FileExistsStr(const Path: string): Boolean;
    function DirExists(const Path: string): Boolean;
    function GetFileName(const Path: string): string;
    function GetFileExt(const Path: string): string;
    
    // Environment & Context
    function GetEnv(const Name: string): string;
    function SetEnv(const Name, Value: string): Boolean;
    function GetCwd: string;
    function SetCwd(const Path: string): Boolean;
    procedure Terminate(ExitCode: Integer);
    
    // Network Operations
    function DownloadFile(const URL, Dest: string): Boolean;
    function HttpGet(const URL: string): string;
  end;

implementation

{ THeatherStdLib }

{ Console }

{ Prints a string message to the standard output and appends a newline.
  @param Msg The message to print. }
procedure THeatherStdLib.Print(const Msg: string);
begin
  Writeln(Msg);
end;

{ Process Execution }

{ Executes a command and returns the exit code. Standard output prints directly to the console. 
  @param Command The command string to execute.
  @return The exit code of the process. }
function THeatherStdLib.Exec(const Command: string): Integer;
var
  P: TProcess;
  Buffer: array[0..2047] of byte;
  BytesRead: Integer;
begin
  P := TProcess.Create(nil);
  try
    {$IFDEF MSWINDOWS}
    P.Executable := SysUtils.GetEnvironmentVariable('ComSpec');
    P.Parameters.Add('/c');
    P.Parameters.Add(Command);
    {$ELSE}
    P.Executable := '/bin/sh';
    P.Parameters.Add('-c');
    P.Parameters.Add(Command);
    {$ENDIF}
    P.Options := [poUsePipes, poNoConsole];
    P.Execute;
    
    while P.Running do
    begin
      if P.Output.NumBytesAvailable > 0 then
      begin
        BytesRead := P.Output.Read(Buffer, SizeOf(Buffer));
        if BytesRead > 0 then
          FileWrite(StdOutputHandle, Buffer, BytesRead);
      end;
      Sleep(10);
    end;
    
    // Read remaining output
    if P.Output.NumBytesAvailable > 0 then
    begin
      BytesRead := P.Output.Read(Buffer, SizeOf(Buffer));
      if BytesRead > 0 then
        FileWrite(StdOutputHandle, Buffer, BytesRead);
    end;
    
    Result := P.ExitStatus;
  finally
    P.Free;
  end;
end;

{ Executes a command silently and returns the standard output as a string.
  @param Command The command string to execute.
  @return The standard output of the command execution, trimmed. }
function THeatherStdLib.ExecOut(const Command: string): string;
var
  OutputStr: string; { Stores the captured standard output }
begin
  if RunCommand(Command, OutputStr) then
    Result := Trim(OutputStr)
  else
    Result := '';
end;

{ File & Directory Operations }

{ Copies a file from Source to Dest.
  @param Source The path of the source file.
  @param Dest The path of the destination file.
  @param Overwrite If true, an existing destination file will be overwritten.
  @return True if successful, False otherwise. }
function THeatherStdLib.CopyFileStr(const Source, Dest: string; Overwrite: Boolean): Boolean;
var
  SrcStream, DestStream: TFileStream;
begin
  Result := False;
  if not FileExists(Source) then Exit;
  if not Overwrite and FileExists(Dest) then Exit;
  
  try
    SrcStream := TFileStream.Create(Source, fmOpenRead or fmShareDenyWrite);
    try
      DestStream := TFileStream.Create(Dest, fmCreate);
      try
        DestStream.CopyFrom(SrcStream, 0);
        Result := True;
      finally
        DestStream.Free;
      end;
    finally
      SrcStream.Free;
    end;
  except
    { Suppress exceptions to return False on failure }
  end;
end;

{ Recursively copies a directory and its contents from Source to Dest.
  @param Source The source directory path.
  @param Dest The destination directory path.
  @return True if successful, False otherwise. }
function THeatherStdLib.CopyDir(const Source, Dest: string): Boolean;
var
  SearchRec: TSearchRec; { Record used for finding files and directories }
  SrcPath, DestPath: string; { Paths for current source and destination items }
begin
  Result := True;
  
  // Ensure the destination directory exists
  if not ForceDirectories(Dest) then Exit(False);
  
  // Find all items in the source directory
  if SysUtils.FindFirst(IncludeTrailingPathDelimiter(Source) + '*', faAnyFile, SearchRec) = 0 then
  begin
    try
      repeat
        // Skip current and parent directory pointers
        if (SearchRec.Name <> '.') and (SearchRec.Name <> '..') then
        begin
          SrcPath := IncludeTrailingPathDelimiter(Source) + SearchRec.Name;
          DestPath := IncludeTrailingPathDelimiter(Dest) + SearchRec.Name;
          
          // If the item is a directory, recursively call CopyDir
          if (SearchRec.Attr and faDirectory) = faDirectory then
          begin
            if not CopyDir(SrcPath, DestPath) then
              Result := False;
          end
          else
          begin
            // If the item is a file, copy it (overwriting by default)
            if not CopyFileStr(SrcPath, DestPath, True) then
              Result := False;
          end;
        end;
      until SysUtils.FindNext(SearchRec) <> 0;
    finally
      SysUtils.FindClose(SearchRec); // Release search handle
    end;
  end;
end;

{ Recursively deletes a directory and all its contents.
  @param Path The path of the directory to remove.
  @return True if successful, False otherwise. }
function THeatherStdLib.RemoveDirTree(const Path: string): Boolean;
var
  SearchRec: TSearchRec; { Record used for finding files and directories }
  ItemPath: string; { Path of the current item being processed }
begin
  Result := True;
  
  if not DirectoryExists(Path) then Exit(True);
  
  if SysUtils.FindFirst(IncludeTrailingPathDelimiter(Path) + '*', faAnyFile, SearchRec) = 0 then
  begin
    try
      repeat
        if (SearchRec.Name <> '.') and (SearchRec.Name <> '..') then
        begin
          ItemPath := IncludeTrailingPathDelimiter(Path) + SearchRec.Name;
          
          // If directory, call recursively
          if (SearchRec.Attr and faDirectory) = faDirectory then
          begin
            if not RemoveDirTree(ItemPath) then
              Result := False;
          end
          else
          begin
            // Delete file
            if not SysUtils.DeleteFile(ItemPath) then
              Result := False;
          end;
        end;
      until SysUtils.FindNext(SearchRec) <> 0;
    finally
      SysUtils.FindClose(SearchRec); // Release search handle
    end;
  end;
  
  // Finally, remove the directory itself
  if Result then
    Result := SysUtils.RemoveDir(Path);
end;

{ Creates a directory and all necessary parent directories.
  @param Path The path of the directory to create.
  @return True if the directory was created or already exists, False otherwise. }
function THeatherStdLib.MakeDirs(const Path: string): Boolean;
begin
  Result := ForceDirectories(Path);
end;

{ Path Manipulation }

{ Safely concatenates two paths using the correct OS path delimiter.
  @param Path1 The first path component.
  @param Path2 The second path component.
  @return The joined path string. }
function THeatherStdLib.JoinPath(const Path1, Path2: string): string;
begin
  Result := IncludeTrailingPathDelimiter(Path1) + Path2;
end;

{ Checks if a file exists at the given path.
  @param Path The file path to check.
  @return True if the file exists, False otherwise. }
function THeatherStdLib.FileExistsStr(const Path: string): Boolean;
begin
  Result := FileExists(Path);
end;

{ Checks if a directory exists at the given path.
  @param Path The directory path to check.
  @return True if the directory exists, False otherwise. }
function THeatherStdLib.DirExists(const Path: string): Boolean;
begin
  Result := DirectoryExists(Path);
end;

{ Gets the base file name from a given path.
  @param Path The full file path.
  @return The base file name including extension. }
function THeatherStdLib.GetFileName(const Path: string): string;
begin
  Result := ExtractFileName(Path);
end;

{ Gets the file extension from a given path.
  @param Path The full file path.
  @return The file extension (including the dot). }
function THeatherStdLib.GetFileExt(const Path: string): string;
begin
  Result := ExtractFileExt(Path);
end;

{ Environment & Context }

{ Gets the value of an environment variable.
  @param Name The name of the environment variable.
  @return The value of the environment variable. }
function THeatherStdLib.GetEnv(const Name: string): string;
begin
  Result := SysUtils.GetEnvironmentVariable(Name);
end;

{ Sets the value of an environment variable.
  @param Name The name of the environment variable.
  @param Value The value to set.
  @return True if successful, False otherwise. }
function THeatherStdLib.SetEnv(const Name, Value: string): Boolean;
begin
{$IFDEF MSWINDOWS}
  Result := Windows.SetEnvironmentVariable(PChar(Name), PChar(Value));
{$ELSE}
  Result := False;
{$ENDIF}
end;

{ Gets the current working directory.
  @return The current working directory path. }
function THeatherStdLib.GetCwd: string;
begin
  Result := GetCurrentDir;
end;

{ Sets the current working directory.
  @param Path The new working directory path.
  @return True if successful, False otherwise. }
function THeatherStdLib.SetCwd(const Path: string): Boolean;
begin
  Result := SetCurrentDir(Path);
end;

{ Instantly halts the script and returns the exit code to the host OS.
  @param ExitCode The exit code to return. }
procedure THeatherStdLib.Terminate(ExitCode: Integer);
begin
  Halt(ExitCode);
end;

{ Network Operations }

{ Downloads a file from a URL over HTTP/HTTPS to the specified destination.
  @param URL The URL to download from.
  @param Dest The local path where the file should be saved.
  @return True if successful, False otherwise. }
function THeatherStdLib.DownloadFile(const URL, Dest: string): Boolean;
var
  Client: TFPHTTPClient;
begin
  Result := False;
  Client := TFPHTTPClient.Create(nil);
  try
    try
      // Ensure the destination directory exists
      if not ForceDirectories(ExtractFileDir(Dest)) then Exit;
      
      // Download the file
      Client.Get(URL, Dest);
      Result := True;
    except
      { Suppress exceptions to return False on failure }
    end;
  finally
    Client.Free;
  end;
end;

{ Performs a GET request and returns the response body as a string.
  @param URL The URL to request.
  @return The response body as a string, or empty string on failure. }
function THeatherStdLib.HttpGet(const URL: string): string;
var
  Client: TFPHTTPClient;
  ResponseStream: TStringStream;
begin
  Result := '';
  Client := TFPHTTPClient.Create(nil);
  ResponseStream := TStringStream.Create('');
  try
    try
      Client.Get(URL, ResponseStream);
      Result := ResponseStream.DataString;
    except
      { Suppress exceptions to return empty string on failure }
    end;
  finally
    ResponseStream.Free;
    Client.Free;
  end;
end;

end.