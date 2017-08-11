######################################################################
## 																	##
## This script is used to check an uncompressed OVA/OVF set of 	   	##
## 	files against the included manifest (SHA1 or SHA256)			##
##																	##
## Created by - Tom Wnukowski - 2017-Aug-11							##
##																	##
######################################################################


## Setting environment
param ([Parameter(Mandatory=$true)] $Path)
if (!$path) {write-host "`nA path parameter must be specified`n" -f red;exit}

## Checking input format, correcting if needed
$last = $path.substring($path.length - 1)
if ($last -ne "\") {
    # write-host "`nSanitizing Input..." -f green
    $path = -join ($path, "\")
    }

$option = [System.StringSplitOptions]::RemoveEmptyEntries
$error = 0
$script:StartTime = get-date
$ScriptName = $MyInvocation.MyCommand.Name

## PS Version check
if ($PSVersionTable.PSVersion.major -lt 4) {write-host "`nRequires Powershell version 4.0 or higher, please update the installed version.`n" -f red;exit}

## Find manifest
$mf = get-content $path"*.mf" -erroraction silentlycontinue

## Checking for required files
if (!$mf) {write-host "`nDid not find a MANIFEST file, check that one exists in the path specified.`n" -f red; exit}

write-host "`nWorking with files in directory $path. This will take several minutes...`n"

## Parse Manifest and check SHA1
foreach ($line in $mf) {
## Breaking out each line into variables
$file = $line.split("()= ",$option)
$filename = $file[1]
## Checking for empty lines (uncomment as needed, found it's not required)
if ($filename.length -eq 0) {write-host "Found empty line, skipping..." -f yellow;continue}
$hash = $file[2]
$hash = $hash.ToUpper()
$alg = $file[0]
## Uncomment for troubleshooting
# write-host "`nFile is "$filename""
# write-host "Stored Hash is "$hash""
# write-host "Algorithm is "$alg""



## checking if file exists
$filecheck = test-path "$path$filename"
if ($filecheck) {
	# write-host "File $filename found, checking hash.."
	$check = get-filehash -path $path$filename -algorithm $alg -ErrorAction SilentlyContinue
	if ($check.hash -eq $hash) {write-host "File hash verified - $filename"-f green} else {
		write-host "==========================================================================" -f yellow
		write-host "File hash verification FAILED!!" -f red
		write-host "Failed File: `t`t"$filename"" -f yellow
		write-host "Stored Hash: `t`t"$hash""
		write-host "Calculated Hash: `t"$check.hash""
		write-host "==========================================================================" -f yellow
		$error++
		}
	} else {write-host "File $filename NOT Found, THIS FILE IS MISSING AND IS LISTED IN THE MANIFEST!" -f red;$error++}
}
## Status report
write-host "=========================================================================="
if ($error -gt 0) {write-host "`nFile Verification errors found, there are either missing or corrupt files!`n" -f red}
if ($error -eq 0) {write-host "`nAll files passed verification, the OVA/OVF is safe to import`n" -f green}
write-host "=========================================================================="
$elapsedTime = $(get-date) - $script:StartTime
write-host "`n$scriptname took"$elapsedTime.Minutes"Minutes and"$elapsedTime.Seconds"Seconds to complete.`n" @fggreen
write-host "=========================================================================="
