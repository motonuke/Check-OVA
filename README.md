# Check-OVA

This script will check a decompressed OVA/OVF for file integrity.

Usage: 		.\check-ova.ps1 -Path "Folder"
Example: 	.\check-ova.ps1 -Path ".\MY_OVA_COLLECTION\OVA FOLDER"

*** Note - This script can take several minutes to run, depending on file size ***

This script can be useful to verify files before attempting to import into your virtual environment. It's particularly useful when many vmdk files are present.

This script will parse the included manifest file in the path provided and use these stored hashses to compare against newly calculated ones. A mismatch indicates a corrupt file. Missing files will also be flagged as failures.
