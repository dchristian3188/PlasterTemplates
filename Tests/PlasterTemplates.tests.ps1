Describe PlasterTemplates {
    BeforeAll {
        $moduleRoot = "$PSScriptRoot\.."
        $moduleData = Import-PowerShellDataFile -Path "$moduleRoot\PlasterTemplates.psd1"
    }

    It "Should have module data" {
        $moduleData | Should not be $null
    }

    It "Should have Plaster Extensions" {
        $moduleData.PrivateData.PSData.Extensions.Module -contains 'Plaster' | Should be $true
    }

    ForEach($templatePath in $moduleData.PrivateData.PSData.Extensions.Details.TemplatePaths)
    {
        $manifestPath = [System.IO.Path]::Combine($moduleRoot,$templatePath,"PlasterManifest.Xml")

        It "Should have a manifest for Path [$templatePath]" {
            Test-Path -Path $manifestPath | Should be $true
        }
    }
}