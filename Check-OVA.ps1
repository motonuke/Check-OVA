
## Setting environment
[CmdletBinding()]
	param (
		[Parameter(
		Mandatory=$true,
		Position=1
		)]
		[ValidateSet("Yes","No")]
		[string]$Recurse = $(throw "Valid responses are Yes or No"),
		
		[Parameter(
		Mandatory=$false,
		Position=2
		)]
		[string]$Path = $()
	)

Function Get-FilePath
{
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
    $OpenFileDialog = New-Object System.Windows.Forms.FolderBrowserDialog
	$OpenFileDialog.Description = "Choose a base folder to search for Manifest (.mf) Files"
    $OpenFileDialog.ShowDialog() | Out-Null
    Return $OpenFileDialog.SelectedPath
}
	
## If path not provided as parameter, prompt user for path via GUI directory picker
if (!$path) {$path = Get-FilePath}

if ($Recurse -ieq "no") {
	## Checking input format, correcting if needed
	$last = $path.substring($path.length - 1)
	if ($last -ne "\") {
		write-verbose "Sanitizing Input, adding missing trailing back slash onto the path..."
		$path = -join ($path, "\")
		}
}
write-verbose "I'm working with file path - $path"
$option = [System.StringSplitOptions]::RemoveEmptyEntries
$error = 0
$script:StartTime = get-date
$ScriptName = $MyInvocation.MyCommand.Name

## PS Version check
if ($PSVersionTable.PSVersion.major -lt 4) {write-host "`nRequires Powershell version 4.0 or higher, please update the installed version.`n" -f red;exit}

## Finding all available manifest files
## Setting Recursive search paramters
switch ($Recurse) {
	"yes" 	{write-host "`nSearching Recursively for Manifest files`n" -f green
			$mffiles = get-childitem -path $path"*.mf" -Recurse -erroraction silentlycontinue
			}
	"no"	{write-host "`nSearching NON Recursively for Manifest files`n" -f green
			$mffiles = get-content $path"*.mf" -erroraction silentlycontinue
			}
}
if ($mffiles -lt 1) {write-host "`nNo manifest files found, please check your settings and that you're using extracted OVF files.`n`nI was looking in $path`n" -f yellow;exit}

## Start loop for all found manifest files
foreach ($mffile in $mffiles) {
$error=0
$filepath = $mffile.fullname | split-path
$mf = get-content $mffile.fullname -erroraction silentlycontinue
## Check that the manifest file contains some expected text.
write-host "=========================================================================="
write-host "`nWorking with files in directory $filepath."
if ($mf -match "vmdk" -and $mf -match "ovf") {write-host "`nFound what appears to be a valid Manifest File, proceeding..." -f green} else 
	{write-host "`nManifest file appears to be invalid, skipping this directory." -f yellow;continue}
write-host "`nThis will take several minutes...`n" -f green
write-host "=========================================================================="

	## Parse Manifest and check hash
	foreach ($line in $mf) {
	
	## Breaking out each line into variables
	$file = $line.split("()= ",$option)
	$filename = $file[1]
	$fullfilename = "$filepath\$filename"
	## Checking for empty lines (uncomment as needed, found it's not required)
	if ($filename.length -eq 0) {write-host "Found empty line, skipping..." -f yellow;continue}
	$hash = $file[2]
	$hash = $hash.ToUpper()
	$alg = $file[0]
	## Uncomment for troubleshooting
	write-verbose "`nFile is "$filename""
	write-verbose "Stored Hash is "$hash""
	write-verbose "Algorithm is "$alg""

	## checking if file exists
	$filecheck = test-path "$fullfilename"
	if ($filecheck) {
		# write-host "File $filename found, checking hash.."
		$check = get-filehash -path $fullfilename -algorithm $alg -ErrorAction SilentlyContinue
		if ($check.hash -eq $hash) {write-host "File hash verified - $filename"-f green} else {
			write-host "==========================================================================" -f yellow
			write-host "File hash verification FAILED!!" -f red
			write-host "Failed File: `t`t"$filename"" -f yellow
			write-host "Stored Hash: `t`t"$hash""
			write-host "Calculated Hash: `t"$check.hash""
			write-host "Location: `t"$fullfilename""
			write-host "==========================================================================" -f yellow
			$error++
			}
		} else {write-host "File $fullfilename NOT Found, `nTHIS FILE IS MISSING AND IS LISTED IN THE MANIFEST!" -f red;$error++}
	}
## Status report
write-host "=========================================================================="
if ($error -gt 0) {write-host "`nFile Verification errors found in directory `n$filepath, `nthere are either missing or corrupt files!`n" -f red}
if ($error -eq 0) {write-host "`nAll files passed verification, the OVA/OVF located at `n$filepath is safe to import`n" -f green}
write-host "=========================================================================="
}
$elapsedTime = $(get-date) - $script:StartTime
write-host "`n$scriptname took"$elapsedTime.Minutes"Minutes and"$elapsedTime.Seconds"Seconds to complete.`n" -f green
write-host "=========================================================================="
