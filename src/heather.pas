program heather;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils, uPSComponent, uPSRuntime, uPSCompiler, uHeatherLib;

type
  { THeatherEngine is the main wrapper around Pascal Script to execute scripts }
  THeatherEngine = class
  private
    FScriptEngine: TPSScript; { The Pascal Script engine instance }
    FLibrary: THeatherStdLib; { The standard library providing system functions }
    { Event handler called during script compilation to register library methods.
      @param Sender The Pascal Script engine. }
    procedure OnCompile(Sender: TPSScript);
  public
    { Initializes the script engine and the standard library }
    constructor Create;
    { Cleans up the engine and the library }
    destructor Destroy; override;
    { Loads, compiles, and runs the script from the specified path.
      @param ScriptPath The path to the script to execute. }
    procedure Run(const ScriptPath: string);
  end;

{ THeatherEngine }

{ Initializes the Pascal Script engine, hooks up the compilation event,
  and creates an instance of the standard library for script use. }
constructor THeatherEngine.Create;
begin
  FScriptEngine := TPSScript.Create(nil);
  FScriptEngine.OnCompile := @OnCompile;
  FLibrary := THeatherStdLib.Create;
end;

{ Frees the standard library and the script engine to prevent memory leaks. }
destructor THeatherEngine.Destroy;
begin
  FLibrary.Free;
  FScriptEngine.Free;
  inherited Destroy;
end;

{ Registers all standard library functions to make them available in Pascal scripts. }
procedure THeatherEngine.OnCompile(Sender: TPSScript);
begin
  // Console Operations
  Sender.AddMethod(FLibrary, @THeatherStdLib.Print, 'procedure Print(const Msg: string);');
  
  // Process Execution
  Sender.AddMethod(FLibrary, @THeatherStdLib.Exec, 'function Exec(const Command: string): Integer;');
  Sender.AddMethod(FLibrary, @THeatherStdLib.ExecOut, 'function ExecOut(const Command: string): string;');
  
  // File & Directory Operations
  Sender.AddMethod(FLibrary, @THeatherStdLib.CopyFileStr, 'function CopyFile(const Source, Dest: string; Overwrite: Boolean): Boolean;');
  Sender.AddMethod(FLibrary, @THeatherStdLib.CopyDir, 'function CopyDir(const Source, Dest: string): Boolean;');
  Sender.AddMethod(FLibrary, @THeatherStdLib.RemoveDirTree, 'function RemoveDirTree(const Path: string): Boolean;');
  Sender.AddMethod(FLibrary, @THeatherStdLib.MakeDirs, 'function MakeDirs(const Path: string): Boolean;');
  
  // Path Manipulation
  Sender.AddMethod(FLibrary, @THeatherStdLib.JoinPath, 'function JoinPath(const Path1, Path2: string): string;');
  Sender.AddMethod(FLibrary, @THeatherStdLib.FileExistsStr, 'function FileExists(const Path: string): Boolean;');
  Sender.AddMethod(FLibrary, @THeatherStdLib.DirExists, 'function DirExists(const Path: string): Boolean;');
  Sender.AddMethod(FLibrary, @THeatherStdLib.GetFileName, 'function GetFileName(const Path: string): string;');
  Sender.AddMethod(FLibrary, @THeatherStdLib.GetFileExt, 'function GetFileExt(const Path: string): string;');
  
  // Environment & Context
  Sender.AddMethod(FLibrary, @THeatherStdLib.GetEnv, 'function GetEnv(const Name: string): string;');
  Sender.AddMethod(FLibrary, @THeatherStdLib.SetEnv, 'function SetEnv(const Name, Value: string): Boolean;');
  Sender.AddMethod(FLibrary, @THeatherStdLib.GetCwd, 'function GetCwd: string;');
  Sender.AddMethod(FLibrary, @THeatherStdLib.SetCwd, 'function SetCwd(const Path: string): Boolean;');
  Sender.AddMethod(FLibrary, @THeatherStdLib.Terminate, 'procedure Terminate(ExitCode: Integer);');
  
  // Network Operations
  Sender.AddMethod(FLibrary, @THeatherStdLib.DownloadFile, 'function DownloadFile(const URL, Dest: string): Boolean;');
  Sender.AddMethod(FLibrary, @THeatherStdLib.HttpGet, 'function HttpGet(const URL: string): string;');
end;

{ Loads the given script from file, compiles it, and executes it.
  Halts the program on missing file, syntax error, or runtime error. }
procedure THeatherEngine.Run(const ScriptPath: string);
var
  ScriptText: TStringList; { Holds the loaded script lines }
begin
  if not FileExists(ScriptPath) then
  begin
    Writeln('HEATHER Error: Script not found -> ', ScriptPath);
    Halt(1);
  end;

  ScriptText := TStringList.Create;
  try
    ScriptText.LoadFromFile(ScriptPath);
    FScriptEngine.Script.Assign(ScriptText);

    if FScriptEngine.Compile then
    begin
      if not FScriptEngine.Execute then
      begin
        Writeln('HEATHER Runtime Error: ', FScriptEngine.ExecErrorToString);
        Halt(1);
      end;
    end
    else
    begin
      Writeln('HEATHER Syntax Error:');
      Writeln(FScriptEngine.CompilerErrorToStr(0));
      Halt(1);
    end;
  finally
    ScriptText.Free;
  end;
end;

const
  HEATHER_VERSION = '0.5.1';

var
  Engine: THeatherEngine; { Main engine instance }
  Param: string;
begin
  if ParamCount < 1 then
  begin
    Writeln('HEATHER - Host Environment for Automated Task Handling');
    Writeln('Usage: heather.exe [options] <script.pas>');
    Writeln('Options:');
    Writeln('  -v, --version    Show the version of HEATHER');
    Halt(0);
  end;

  Param := ParamStr(1);
  if (Param = '-v') or (Param = '--version') then
  begin
    Writeln('HEATHER v', HEATHER_VERSION);
    Halt(0);
  end;

  Engine := THeatherEngine.Create;
  try
    Engine.Run(Param);
  finally
    Engine.Free;
  end;
end.