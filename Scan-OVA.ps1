function Scan-OVA {    
    <#
    .SYNOPSIS
        This script is used to scan uncompressed OVA/OVF file(s) against the included manifest (SHA1 or SHA256).

    .DESCRIPTION
        This script is used to scan uncompressed OVA/OVF file(s) against the included manifest (SHA1 or SHA256).  
        
    .EXAMPLE
        Scan-OVA -Path "\\Share\Foo\Bar.ova", "\\Share\NewFoo\NewBar.ovf"
        Scans [\\Share\Foo\Bar.ova] and [\\Share\NewFoo\NewBar.ovf] against their respective .MF and .VMDK file(s).
    
    .EXAMPLE
        Scan-OVA
        Opens Windows File Explorer for file selection. Scans selected OVA/OVF file(s) against their respective .MF and .VMDK file(s).

    .NOTES
        Written By: Motonuke
        Date: 2017-Aug-11

        Edited by: JBear
        Date: 2017-Oct-19
    #>

    param (

        [Parameter(ValueFromPipeline=$true,HelpMessage="Enter OVA/OVF path(s)")]
        [String[]]$Path = $null,

        #Write-Progress starting values
        $i = 0,
        $j = 0,
        $k = 0,
        $l = 0
    )

    #PS Version check
    if($PSVersionTable.PSVersion.major -lt 4) {

        Write-Host -ForegroundColor Red "`nRequires Powershell version 4.0 or higher, please update the installed version.`n" 
        Break
    }

    if($Path -eq $null) {

        Add-Type -AssemblyName System.Windows.Forms

        $Dialog = New-Object System.Windows.Forms.OpenFileDialog
        $Dialog.InitialDirectory = "\\Server01\IT\VMware"
        $Dialog.Title = "Select OVF/OVA File(s)"
        $Dialog.Filter = "OVA/OVF Files (*.ova,*.ovf)|*.ova; *.ovf"
        $Dialog.Multiselect=$true
        $Result = $Dialog.ShowDialog()

        if($Result -eq 'OK') {

            Try {
        
                $Path = $Dialog.FileNames
            }

            Catch {

                $null
	            Break
            }
        }

        else {

            #Shows upon cancellation of Save Menu
            Write-Host -ForegroundColor Yellow "Notice: No file(s) selected to scan."
            Break
        }
    }

    foreach($P in $Path) {

        Write-Progress -Activity "Verifying file hash..." -Status ("Percent Complete:" + "{0:N0}" -f ((($i++) / $Path.count) * 100) + "%") -CurrentOperation "Processing $($P)..." -PercentComplete ((($j++) / $Path.count) * 100)

        $Option = [System.StringSplitOptions]::RemoveEmptyEntries
        $StartTime = Get-Date

        $Parent = (Split-Path -Path $P)
        $Split = (Split-Path -Path $P -Leaf).Split(".")
        $Leaf = $Split[0]

        Try {
        
            if($Parent.substring($Parent.length - 1) -ne "\") {

                $Manifest = Get-Content (-Join ($Parent,"\") + "$Leaf.mf") -ErrorAction Stop
            }

            else {
        
                $Manifest = Get-Content ($Parent + "$Leaf.mf") -ErrorAction Stop
            }
        }

        Catch {

            Write-Host -ForegroundColor Red "`nDid not find $Manifest, check that one exists in the path specified."
            Break
        }

        #Parse Manifest and check SHA1
        $HashCheck = foreach($Line in $Manifest) {

            $LineItem = $Line.Split("(").Split(")")

            Write-Progress -Activity "Verifying manifest file..." -Status ("Percent Complete:" + "{0:N0}" -f ((($k++) / $Manifest.count) * 100) + "%") -CurrentOperation "Processing $($LineItem[1])..." -PercentComplete ((($l++) / $Manifest.count) * 100)     

            #Break each line into variables
            $File = $Line.split( "()= ",$Option )
            $Filename = $File[1]
            $Hash = $File[2]
            $Hash = $Hash.ToUpper()
            $Alg = $File[0]

            $VerifyPath = @(
        
                if($Parent.substring($Parent.length - 1) -ne "\") {

                    -Join ($Parent,"\") + "$Filename"
                }

                else {
        
                    $Parent + $Filename
                }        
            )

            #Test for file
            if(Test-Path $VerifyPath) {

	            $Check = Get-FileHash -Path $VerifyPath -Algorithm $Alg -ErrorAction SilentlyContinue

                #Check hash matching
	            if($Check.Hash -eq $Hash) {
 
                    "Pass"
                } 
        
                else {

                    "Fail"
		        }
	        }

            #File test failed
            else {
    
                $HashCheck= "Fail"
            }
        }

        $Verification = @(
    
            if($HashCheck -eq $null) {

                "N\A"
            }
        
            elseif($HashCheck -contains "Fail") {
        
                "FAIL"
            }

            else {
        
                "PASS"
            }
        )

        $ElapsedTime = $(Get-Date) - $StartTime

        [PSCustomObject] @{
        
            Filename="$Filename"
            HashVerification="$Verification"
            TimeElapsed="$ElapsedTime"
        }
    }
}
