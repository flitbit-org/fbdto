param(
    [Parameter(Mandatory=$True)][string]$where,
    [Parameter(Mandatory=$False)][string]$newMajorVersion,
    [Parameter(Mandatory=$False)][string]$newMinorVersion,
	[Parameter(Mandatory=$False)][string]$newBuildVersion
)

$versionroot = (Resolve-Path ($where)).Path

$versionRootFileName = 'VersionRoot.targets'
$versionFileName = 'Version.targets'

function Outp([string] $text, [string] $cl) {
    $text    
}

function FixVersionFile([string] $where) {
    $commentary = ''
    $preamble = ''
    $needsSave = $false
    $versionRootFile = [System.String]::Concat($where, '\', $versionRootFileName)
    $versionFile = [System.String]::Concat($where, '\', $versionFileName)
    
    if (!(Test-Path $versionRootFile)) {
        $preamble = "`n  $versionRootFileName << missing file"                    
    }
    if (!(Test-Path $versionFile)) {
        $preamble = $preamble + "`n  $versionFileName << missing file"
    } 
    
    if($preamble -eq '')
    {
        $proj = [xml](Get-Content $versionFile)    
        $nsmgr = New-Object System.Xml.XmlNamespaceManager -ArgumentList $proj.NameTable
        $nsmgr.AddNamespace('p','http://schemas.microsoft.com/developer/msbuild/2003')
        
        # Ensure the VersionMajor is correct:
        $rolledMajor = $false;
        $versionMajor = $proj.SelectNodes("//p:VersionMajor", $nsmgr)
        $prevMajor = "0"
        if ($versionMajor.count -gt 0) {
            $prevMajor = $versionMajor.Item(0).InnerText
            if($newMajorVersion -eq '' -or $newMajorVersion -eq $Null) {
                $intMajor = [System.Int32]::Parse($prevMajor) 
                $userRollMajor = Read-Host "Major Version Currently '$intMajor'.  Roll Major Version? [Y/N]"
                if($userRollMajor.StartsWith("Y", [System.StringComparison]::InvariantCultureIgnoreCase) -eq $true) {
                    $intMajor = $intMajor + 1
                    $newMajorVersion = $intMajor.ToString()
                } else {
                    $newMajorVersion = $versionMajor.Item(0).InnerText
                }
            }
            $node = $proj.Project
            if (!($node -eq $null)) {
                $versionMajor | foreach {
                    if ($_.InnerText -ne $newMajorVersion) {
                        $thisParent = $_.ParentNode
                        $insert = $proj.CreateElement('VersionMajor')
                        $insert.InnerText = $newMajorVersion
                        [void]$thisParent.ReplaceChild($insert, $_)
                        $commentary = "$commentary`n    >> Modified VersionMajor to: $newMajorVersion"
                        $needsSave = $true               
                        $rolledMajor = $true
                    }
                }
            }
        }
           
        # Ensure the VersionMinor is correct:
        $rolledMinor = $false;
        $versionMinor = $proj.SelectNodes("//p:VersionMinor", $nsmgr)
        $prevMinor = "0"
        if ($versionMinor.count -gt 0) {
            $prevMinor = $versionMinor.Item(0).InnerText
            if($newMinorVersion -eq '' -or $newMinorVersion -eq $Null) {
                if($rolledMajor -eq $true) {
                    $newMinorVersion = "0"
                } else {
                    $intMinor = [System.Int32]::Parse($versionMinor.Item(0).InnerText)
                    $userRollMinor = Read-Host "Minor Version Currently '$intMinor'.  Roll Minor Version? [Y/N]"
                    if($userRollMinor.StartsWith("Y", [System.StringComparison]::InvariantCultureIgnoreCase) -eq $true) {
                        $intMinor = $intMinor + 1
                        $newMinorVersion = $intMinor.ToString()
                    } else {
                        $newMinorVersion = $versionMinor.Item(0).InnerText
                    }
                }
            }
            $node = $proj.Project
            if (!($node -eq $null)) {
                $versionMinor | foreach { 
                    if ($_.InnerText -ne $newMinorVersion) {
                        $thisParent = $_.ParentNode
                        $insert = $proj.CreateElement('VersionMinor')
                        $insert.InnerText = $newMinorVersion
                        [void]$thisParent.ReplaceChild($insert, $_)
                        $commentary = "$commentary`n    >> Modified VersionMinor to: $newMinorVersion"
                        $needsSave = $true
                        $rolledMinor = $true;
                    } 
                }
                
            }
        }
    	
    	# Ensure the VersionBuild is correct:
        $versionBuild = $proj.SelectNodes("//p:VersionBuild", $nsmgr)
        $prevBuild = "0"
        if ($versionBuild.count -gt 0) {
            $prevBuild = $versionBuild.Item(0).InnerText
            if($newBuildVersion -eq '' -or $newBuildVersion -eq $Null) {
                if($rolledMinor -eq $true) {
                    $newBuildVersion = "0"
                } else {
                    $intBuild = [System.Int32]::Parse($versionBuild.Item(0).InnerText)
                    $userRollBuild = Read-Host "Build Version Currently '$intBuild'.  Roll Build Version? [Y/N]"
                    if($userRollBuild.StartsWith("Y", [System.StringComparison]::InvariantCultureIgnoreCase) -eq $true) {
                        $intBuild = $intBuild + 1
                        $newBuildVersion = $intBuild.ToString()
                    } else {
                        $newBuildVersion = $versionBuild.Item(0).InnerText
                    }
                }
            }
            $node = $proj.Project
            if (!($node -eq $null)) {
                $versionBuild | foreach { 
                    if ($_.InnerText -ne $newBuildVersion) {
                        $thisParent = $_.ParentNode
                        $insert = $proj.CreateElement('VersionBuild')
                        $insert.InnerText = $newBuildVersion
                        [void]$thisParent.ReplaceChild($insert, $_)
                        $commentary = "$commentary`n    >> Modified VersionBuild to: $newBuildVersion"
                        $needsSave = $true               
                    } 
                }
                
            }
        }
        if ($needsSave) {
            $commentary = "$commentary`n    Old Version: $prevMajor.$prevMinor.$prevBuild >> New Version: $newMajorVersion.$newMinorVersion.$newBuildVersion"
            $proj = [xml] $proj.OuterXml.Replace(" xmlns=`"`"", "")
            $proj.Save($versionFile);
            Outp "$where$preamble$commentary" "Magenta"
        }
    } else {
        Outp "$where$preamble$commentary" "Red"
    }
}

function MakeVersionRoot([string] $where) {
    if ($where -ne $devToolsPath) {
        Outp "`nMarking version root at $where"
        FixVersionFile $where 
    } else { 
       'Cannot establish a version root without a target path'
    }
}

if (Test-Path $versionroot) { MakeVersionRoot $versionroot }
