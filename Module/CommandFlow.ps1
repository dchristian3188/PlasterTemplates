Param(
    [Parameter()]
    [string]
    $DestinationPath,

    [Parameter()]
    [switch]
    $HideGraph
)

$exportParams = @{
    ShowGraph = $true
}

if($HideGraph)
{
    $exportParams.ShowGraph = $false
}

if($DestinationPath)
{
    $exportParams.DestinationPath = $DestinationPath
}

graph CommandFlow {
    $moduleRoot = Split-Path -Path $PSScriptRoot -Parent
    $scripts = @{}
    Get-ChildItem -Path "$moduleRoot\Public\*ps1","$moduleRoot\Internal\*ps1"  |
        ForEach-Object -Process {
            $scripts[$PSItem.BaseName] = $PSItem.FullName
    }

    $scriptNames = $scripts.Keys | Sort-Object
    ForEach ($script in $scriptNames)
    {

        node $script
        $contents = Get-Content -Path $scripts[$script] -ErrorAction Stop
        $errors = $null
        $commands = ([System.Management.Automation.PSParser]::Tokenize($contents, [ref]$errors) |
                Where-Object -FilterScript {$PSItem.Type -eq 'Command'}).Content
        ForEach ($command in $commands)
        {
            If ($scripts[$command])
            {
               Edge  $script -To $command
            }
        }
    }
} | Export-PSGraph @exportParams