<%
"function $PLASTER_PARAM_FunctionName"
%>
{
<%
    If ($PLASTER_PARAM_Help -eq 'Yes')
    {
        @"
  <#
    .Synopsis
      Short description
    .DESCRIPTION
      Long description
    .EXAMPLE
      Example of how to use this cmdlet
  #>
"@
    }
%>
<%
    if ($PLASTER_PARAM_CmdletBinding -eq 'Simple')
    {
        @"
    [CmdletBinding()]
"@
    }
    else 
    {
        @'
    [CmdletBinding(DefaultParameterSetName='Parameter Set 1', 
                SupportsShouldProcess=$true, 
                PositionalBinding=$false,
                HelpUri = 'http://www.microsoft.com/',
                ConfirmImpact='Medium')]
'@
    }
%>
    Param
    (
<%
    if ($PLASTER_PARAM_ComputerName -eq 'Yes')
    {
        @'
        [Parameter(
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true, 
            Position=0)]
        [string[]]
        $ComputerName
'@
    }
%>
    )
<%
    if ($PLASTER_PARAM_PipelineSupport -eq 'Yes')
    {
        @'
    begin
    {

    }
    process
    {
'@
    }
%>
<%
    if ($PLASTER_PARAM_ComputerName -eq 'Yes' -and $PLASTER_PARAM_PipelineSupport -eq 'Yes')
    {
        @'
        forEach ($computer in $ComputerName)
        {

        }
'@
    }
    elseif ($PLASTER_PARAM_ComputerName -eq 'Yes') 
    {
    @'
    forEach ($computer in $ComputerName)
    {

    }
'@
    }
%>
<%
    if ($PLASTER_PARAM_PipelineSupport -eq 'Yes')
    {
        @'
    }
    end
    {

    }
'@
    }
%>
}