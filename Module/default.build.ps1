<%
    $buildParams = @("task . Clean", "Build")
    if ($PLASTER_PARAM_Pester -eq "Yes")
    {
        $buildParams += "Tests"
    }

    if ($PLASTER_PARAM_PlatyPS -eq "Yes")
    {
        $buildParams += "ExportHelp"
    }

    if ($PLASTER_PARAM_PSGraph -eq "Yes")
    {
        $buildParams += "GenerateGraph"
    }

    $buildParams += "Stats"

    $buildParams -join ", "
%>
<%
    if ($PLASTER_PARAM_Pester -eq "Yes")
    {
        "task Tests ImportCompipledModule, Pester"
    }
    
%>
<%
    $tasks = @("task CreateManifest CopyPSD, UpdatPublicFunctionsToExport")
    if ($PLASTER_PARAM_FunctionFolders -contains 'DSCResources')
    {
        $tasks += "UpdateDSCResourceToExport"
    }
    ($tasks -join ", ")
%>
task Build Compile, CreateManifest
task Stats RemoveStats, WriteStats

$script:ModuleName = Split-Path -Path $PSScriptRoot -Leaf
$script:ModuleRoot = $PSScriptRoot
$script:OutPutFolder = "$PSScriptRoot\Output"
<%
    $folders = @()
    if ($PLASTER_PARAM_FunctionFolders -contains 'Public')
    {
        $folders += "'Public'"
    }

    if ($PLASTER_PARAM_FunctionFolders -contains 'Internal')
    {
        $folders += "'Internal'"
    }

    if ($PLASTER_PARAM_FunctionFolders -contains 'Classes')
    {
        $folders += "'Classes'"
    }

    if ($PLASTER_PARAM_FunctionFolders -contains 'DSCResources')
    {
        $folders += "'DSCResources'"
    }

    $importfolders = $folders -join ", "
    
    '$script:ImportFolders = @({0})' -f $importfolders
%>
$script:PsmPath = Join-Path -Path $PSScriptRoot -ChildPath "Output\$($script:ModuleName)\$($script:ModuleName).psm1"
$script:PsdPath = Join-Path -Path $PSScriptRoot -ChildPath "Output\$($script:ModuleName)\$($script:ModuleName).psd1"
<%
    if ($PLASTER_PARAM_PlatyPS -eq "Yes")
    {
        '$script:HelpPath = Join-Path -Path $PSScriptRoot -ChildPath "Output\$($script:ModuleName)\en-US"'
    }
%>

$script:PublicFolder = 'Public'
$script:DSCResourceFolder = 'DSCResources'


task "Clean" {
    if (-not(Test-Path $script:OutPutFolder))
    {
        New-Item -ItemType Directory -Path $script:OutPutFolder > $null
    }

    Remove-Item -Path "$($script:OutPutFolder)\*" -Force -Recurse
}

$compileParams = @{
    Inputs = {
        foreach ($folder in $script:ImportFolders)
        {
            Get-ChildItem -Path $folder -Recurse -File -Filter '*.ps1'
        }
    }

    Output = {
        $script:PsmPath
    }
}

task Compile @compileParams {
    if (Test-Path -Path $script:PsmPath)
    {
        Remove-Item -Path $script:PsmPath -Recurse -Force
    }
    New-Item -Path $script:PsmPath -Force > $null

    foreach ($folder in $script:ImportFolders)
    {
        $currentFolder = Join-Path -Path $script:ModuleRoot -ChildPath $folder
        Write-Verbose -Message "Checking folder [$currentFolder]"

        if (Test-Path -Path $currentFolder)
        {
            $files = Get-ChildItem -Path $currentFolder -File -Filter '*.ps1'
            foreach ($file in $files)
            {
                Write-Verbose -Message "Adding $($file.FullName)"
                Get-Content -Path $file.FullName >> $script:PsmPath
            }
        }
    }
}

task CopyPSD {
    New-Item -Path (Split-Path $script:PsdPath) -ItemType Directory -ErrorAction 0
    $copy = @{
        Path        = "$($script:ModuleName).psd1"
        Destination = $script:PsdPath
        Force       = $true
        Verbose  = $true
    }
    Copy-Item @copy
}

task UpdatPublicFunctionsToExport -if (Test-Path -Path $script:PublicFolder) {
    $publicFunctions = (Get-ChildItem -Path $script:PublicFolder |
            Select-Object -ExpandProperty BaseName) -join "', '"

    $publicFunctions = "FunctionsToExport = @('{0}')" -f $publicFunctions

    (Get-Content -Path $script:PsdPath) -replace "FunctionsToExport = '\*'", $publicFunctions |
        Set-Content -Path $script:PsdPath
}

<%
    if ($PLASTER_PARAM_FunctionFolders -contains 'DSCResources')
    {
        @'
task UpdateDSCResourceToExport -if (Test-Path -Path $script:DSCResourceFolder) {
    $resources = (Get-ChildItem -Path $script:DSCResourceFolder |
            Select-Object -ExpandProperty BaseName) -join "', '"

    $resources = "'{0}'" -f $resources

    (Get-Content -Path $script:PsdPath) -replace "'_ResourcesToExport_'", $resources |
        Set-Content -Path $script:PsdPath   
}     
'@
    }
%>

task ImportCompipledModule -if (Test-Path -Path $script:PsmPath) {
    Get-Module -Name $script:ModuleName |
        Remove-Module -Force
    Import-Module -Name $script:PsdPath -Force
}

<%
    if ($PLASTER_PARAM_Pester -eq "Yes")
    {
        @'
task Pester {
    $resultFile = "{0}\testResults{1}.xml" -f $script:OutPutFolder, (Get-date -Format 'yyyyMMdd_hhmmss')
    $testFolder = Join-Path -Path $PSScriptRoot -ChildPath 'Tests\*'
    Invoke-Pester -Path $testFolder -OutputFile $resultFile -OutputFormat NUnitxml
}     
'@
    }
%>

<%
    if ($PLASTER_PARAM_PSGraph -eq "Yes")
    {
        @'
task GenerateGraph -if (Test-Path -Path 'Graphs') {
    $Graphs = Get-ChildItem -Path "Graphs\*"
    
    Foreach ($graph in $Graphs)
    {
        $graphLocation = [IO.Path]::Combine($script:OutPutFolder, $script:ModuleName, "$($graph.BaseName).png")
        . $graph.FullName -DestinationPath $graphLocation -Hide
    }
}     
'@
    }
%>


task RemoveStats -if (Test-Path -Path "$($script:OutPutFolder)\stats.json") {
    Remove-Item -Force -Verbose -Path "$($script:OutPutFolder)\stats.json" 
}

task WriteStats {
    $folders = Get-ChildItem -Directory | 
        Where-Object {$PSItem.Name -ne 'Output'}
    
    $stats = foreach ($folder in $folders)
    {
        $files = Get-ChildItem "$($folder.FullName)\*" -File
        if($files)
        {
            Get-Content -Path $files | 
            Measure-Object -Word -Line -Character | 
            Select-Object -Property @{N = "FolderName"; E = {$folder.Name}}, Words, Lines, Characters
        }
    }
    $stats | ConvertTo-Json > "$script:OutPutFolder\stats.json"
}

<%
    if ($PLASTER_PARAM_PlatyPS -eq "Yes")
    {
        @'
task ExportHelp -if (Test-Path -Path "$script:ModuleRoot\Help") {
    New-ExternalHelp -Path "$script:ModuleRoot\Help" -OutputPath $script:HelpPath
}
'@
    }
%>