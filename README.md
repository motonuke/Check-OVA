# Check-OVA

This script will check a decompressed OVF for file integrity. This only works on OVF files (which are uncompressed OVA files).

Usage: 		.\check-ovf.ps1 -Recurse "Yes|No" -Path(optional) "Folder"
Example: 	.\check-ovf.ps1 -Recurse Yes -Path ".\MY_OVA_COLLECTION\OVA FOLDER"

*** If a path is not specifed, you will be promted to pick a starting folder ***

*** The Recurse option will search the specified root folder and all subfolders for MF and OVF files and check them againsts the stored hashes ***

*** Note - This script can take several minutes to run, depending on file size ***

This script can be useful to verify files before attempting to import into your virtual environment. It's particularly useful when many vmdk files are present.

This script will parse the included manifest file in the path provided and use these stored hashses to compare against newly calculated ones. A mismatch indicates a corrupt file. Missing files will also be flagged as failures.

What's new in the branch:

-Gui File Path Picker if no Path paramter specificed

-Combined 2 old scripts into 1, added Recursive functionality based on parameters



