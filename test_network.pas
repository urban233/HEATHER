program test_network;

{ Test script demonstrating the new network operations in HEATHER.
  This script tests DownloadFile and HttpGet functions. }

begin
  WriteLn('=== HEATHER Network Operations Test ===');
  WriteLn('');
  
  // Test HttpGet: Fetch a simple webpage
  WriteLn('Testing HttpGet...');
  WriteLn('Fetching example.com...');
  WriteLn('');
  
  // Note: HttpGet returns the response body as a string
  WriteLn('HttpGet result length: ', Length(HttpGet('https://example.com')));
  WriteLn('');
  
  // Test DownloadFile: Download a small file
  WriteLn('Testing DownloadFile...');
  WriteLn('Downloading a test file...');
  
  if DownloadFile('https://example.com', 'downloaded_example.html') then
    WriteLn('Download successful! File saved to: downloaded_example.html')
  else
    WriteLn('Download failed.');
  
  WriteLn('');
  WriteLn('=== Test Complete ===');
end.