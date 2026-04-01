program test_heather;

var
  Cwd: string;
  OutputText: string;
  ExitCode: Integer;
begin
  Print('--- HEATHER Engine Test ---');
  
  // Test GetCwd
  Cwd := GetCwd();
  Print('Current Working Directory: ' + Cwd);
  
  // Test GetEnv
  Print('OS Environment Variable: ' + GetEnv('OS'));
  
  // Test ExecOut
  Print('Running "cmd /c echo Hello from cmd"...');
  OutputText := ExecOut('cmd /c echo Hello from cmd');
  Print('ExecOut Result: ' + OutputText);
  
  // Test MakeDirs and FileExists
  Print('Creating test_dir...');
  MakeDirs('test_dir');
  if DirExists('test_dir') then
    Print('test_dir successfully created!')
  else
    Print('Failed to create test_dir.');
    
  // Test Exec
  Print('Running "cmd /c dir" (Exec)...');
  ExitCode := Exec('cmd /c dir test_dir');
  if ExitCode = 0 then
    Print('Exec exit code: 0')
  else
    Print('Exec exit code: non-zero');
  
  // Clean up
  Print('Cleaning up test_dir...');
  RemoveDirTree('test_dir');
  if not DirExists('test_dir') then
    Print('test_dir successfully removed.')
  else
    Print('Failed to remove test_dir.');
    
  Print('--- Test Complete ---');
end.