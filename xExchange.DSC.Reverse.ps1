<#PSScriptInfo

.VERSION 1.1.0.0

.GUID c5d39ceb-c4b0-4a22-b98f-22be7688802a

.AUTHOR Microsoft Corporation

.COMPANYNAME Microsoft Corporation

.EXTERNALMODULEDEPENDENCIES

.TAGS xExchange,ReverseDSC

.RELEASENOTES

* Initial Release;
#>

#Requires -Modules @{ModuleName="ReverseDSC";ModuleVersion="1.9.1.0"},@{ModuleName="xExchange";ModuleVersion="1.25.0.0"}

<# 

.DESCRIPTION 
 Extracts the DSC Configuration of an existing Exchange Server environment, allowing you to analyze it or to replicate it.

#> 
[cmdletbinding()]
param(
    $Thumbprint
)

<## Script Settings #>
$VerbosePreference = "SilentlyContinue"

<## Scripts Variables #>
$Script:dscConfigContent = ""
$DSCSource = "C:\Program Files\WindowsPowerShell\Modules\xExchange\"
$DSCVersion = "1.25.0.0"
#$Script:setupAccount = Get-Credential -Message "Setup Account"

try {
    $currentScript = Test-ScriptFileInfo $SCRIPT:MyInvocation.MyCommand.Path
    $Script:version = $currentScript.Version.ToString()
}
catch {
    $Script:version = "N/A"
}
$Script:DSCPath = $DSCSource + $DSCVersion

<## This is the main function for this script. It acts as a call dispatcher, calling the various functions required in the proper order to get 
the full environment's picture. #>
function Orchestrator {        
    <# Import the ReverseDSC Core Engine #>
    if ($module -eq $null) {
        $module = "ReverseDSC"
    }    
    Import-Module -Name $module -Force

    # Retrieve informaton about the SQL connection to the current server;
    <# Import the SQLServer Helper Module #>
    $xExchangeModule = "xExchange" 
    Import-Module -Name $xExchangeModule -Force
    
    $configName = "ExchangeServer"
    $Script:dscConfigContent += "<# Generated with xExchangeServer.Reverse " + $script:version + " #>`r`n"   
    $Script:dscConfigContent += "Configuration $configName`r`n"
    $Script:dscConfigContent += "{`r`n"

    Write-Host "Configuring Dependencies..." -BackgroundColor DarkGreen -ForegroundColor White
    Set-Imports

    $Script:dscConfigContent += "    Node $env:COMPUTERNAME`r`n"
    $Script:dscConfigContent += "    {`r`n"
    
    # Loop through all SQL Instances and extract their DSC information;
    foreach ($Server in $ExchangeServers) {        
        Write-Host "$($env:computername) Scanning ActiveSync Virtual Direcotry Settings" -BackgroundColor DarkGreen -ForegroundColor White
        Read-ExchActiveSyncVirtualDirectory
    }

    Write-Host "$($env:computername) Configuring Local Configuration Manager (LCM)..." -BackgroundColor DarkGreen -ForegroundColor White
    Set-LCM

    $Script:dscConfigContent += "`r`n    }`r`n"           
    $Script:dscConfigContent += "}`r`n"

    Write-Host "$($env:computername) Setting Configuration Data..." -BackgroundColor DarkGreen -ForegroundColor White
    Set-ConfigurationData

    $Script:dscConfigContent += "$configName -ConfigurationData `$ConfigData"
}

#region Reverse Functions
function Read-ExchActiveSyncVirtualDirectory {
    [cmdletbinding()]
    param()  
    $module = Resolve-Path ($Script:DSCPath + "\DSCResources\MSFT_xExchActiveSyncVirtualDirectory\MSFT_xExchActiveSyncVirtualDirectory.psm1")
    Import-Module $module
    $params = Get-DSCFakeParameters -ModulePath $module
    # Setting Exchange Session Settings
    $params.Identity = "Microsoft-Server-ActiveSync (Default Web Site)"
    $params.DomainController =  ([ADSI]”LDAP://RootDSE”).dnshostname
    $params.Credential = $Credential
    $results = Get-TargetResource @params
    $Script:dscConfigContent += "        xExchActiveSyncVirtualDirectory " + [System.Guid]::NewGuid().toString() + "`r`n"
    $Script:dscConfigContent += "        {`r`n"
    $Script:dscConfigContent += Get-DSCBlock -Params $results -ModulePath $module
    $Script:dscConfigContent += "        }`r`n"
}
function Read-ExchAntiMalwareScanning {
    [cmdletbinding()]
    param()  
    $module = Resolve-Path ($Script:DSCPath + "\DSCResources\MSFT_xExchAntiMalwareScanning\MSFT_xExchAntiMalwareScanning.psm1")
    Import-Module $module
    $params = Get-DSCFakeParameters -ModulePath $module
    # Setting Exchange Session Settings
    $params.Credential = $Credential
    $results = Get-TargetResource @params
    $Script:dscConfigContent += "        xExchAntiMalwareScanning " + [System.Guid]::NewGuid().toString() + "`r`n"
    $Script:dscConfigContent += "        {`r`n"
    $Script:dscConfigContent += Get-DSCBlock -Params $results -ModulePath $module
    $Script:dscConfigContent += "        }`r`n"
}
function Read-ExchAutodiscoverVirtualDirectory {
    [cmdletbinding()]
    param()  
    $module = Resolve-Path ($Script:DSCPath + "\DSCResources\MSFT_xExchAutodiscoverVirtualDirectory\MSFT_xExchAutodiscoverVirtualDirectory.psm1")
    Import-Module $module
    $params = Get-DSCFakeParameters -ModulePath $module
    # Setting Exchange Session Settings
    $params.Credential = $Credential
    $params.DomainController =  ([ADSI]”LDAP://RootDSE”).dnshostname
    $results = Get-TargetResource @params
    $Script:dscConfigContent += "        xExchAutodiscoverVirtualDirectory " + [System.Guid]::NewGuid().toString() + "`r`n"
    $Script:dscConfigContent += "        {`r`n"
    $Script:dscConfigContent += Get-DSCBlock -Params $results -ModulePath $module
    $Script:dscConfigContent += "        }`r`n"
}
function Read-ExchAutoMountPoint {
    [cmdletbinding()]
    param()  
    $module = Resolve-Path ($Script:DSCPath + "\DSCResources\MSFT_xExchAutoMountPoint\MSFT_xExchAutoMountPoint.psm1")
    Import-Module $module
    $params = Get-DSCFakeParameters -ModulePath $module
    # Setting Exchange Session Settings
    $results = Get-TargetResource @params
    $Script:dscConfigContent += "        xExchAutoMountPoint " + [System.Guid]::NewGuid().toString() + "`r`n"
    $Script:dscConfigContent += "        {`r`n"
    $Script:dscConfigContent += Get-DSCBlock -Params $results -ModulePath $module
    $Script:dscConfigContent += "        }`r`n"
}
function Read-ExchClientAccessServer {
    [cmdletbinding()]
    param()  
    $module = Resolve-Path ($Script:DSCPath + "\DSCResources\MSFT_xExchClientAccessServer\MSFT_xExchClientAccessServer.psm1")
    Import-Module $module
    $params = Get-DSCFakeParameters -ModulePath $module
    # Setting Exchange Session Settings
    $params.Credential = $Credential
    $params.DomainController =  ([ADSI]”LDAP://RootDSE”).dnshostname
    $results = Get-TargetResource @params
    $Script:dscConfigContent += "        xExchClientAccessServer " + [System.Guid]::NewGuid().toString() + "`r`n"
    $Script:dscConfigContent += "        {`r`n"
    $Script:dscConfigContent += Get-DSCBlock -Params $results -ModulePath $module
    $Script:dscConfigContent += "        }`r`n"
}
function Read-ExchDatabaseAvailabilityGroupMember {
    [cmdletbinding()]
    param()  
    $module = Resolve-Path ($Script:DSCPath + "\DSCResources\MSFT_xExchDatabaseAvailabilityGroupMember\MSFT_xExchDatabaseAvailabilityGroupMember.psm1")
    Import-Module $module
    $params = Get-DSCFakeParameters -ModulePath $module
    # Setting Exchange Session Settings
    $params.Credential = $Credential
    $params.DomainController =  ([ADSI]”LDAP://RootDSE”).dnshostname
    $results = Get-TargetResource @params
    $Script:dscConfigContent += "        xExchDatabaseAvailabilityGroupMember " + [System.Guid]::NewGuid().toString() + "`r`n"
    $Script:dscConfigContent += "        {`r`n"
    $Script:dscConfigContent += Get-DSCBlock -Params $results -ModulePath $module
    $Script:dscConfigContent += "        }`r`n"
}
function Read-ExchDatabaseAvailabilityGroupNetwork {
    [cmdletbinding()]
    param()  
    $module = Resolve-Path ($Script:DSCPath + "\DSCResources\MSFT_xExchDatabaseAvailabilityGroupNetwork\MSFT_xExchDatabaseAvailabilityGroupNetwork.psm1")
    Import-Module $module
    $params = Get-DSCFakeParameters -ModulePath $module
    # Setting Exchange Session Settings
    $params.Credential = $Credential
    $params.DomainController =  ([ADSI]”LDAP://RootDSE”).dnshostname
    $results = Get-TargetResource @params
    $Script:dscConfigContent += "        xExchDatabaseAvailabilityGroupNetwork " + [System.Guid]::NewGuid().toString() + "`r`n"
    $Script:dscConfigContent += "        {`r`n"
    $Script:dscConfigContent += Get-DSCBlock -Params $results -ModulePath $module
    $Script:dscConfigContent += "        }`r`n"
}
function Read-ExchEcpVirtualDirectory {
    [cmdletbinding()]
    param()  
    $module = Resolve-Path ($Script:DSCPath + "\DSCResources\MSFT_xExchEcpVirtualDirectory\MSFT_xExchEcpVirtualDirectory.psm1")
    Import-Module $module
    $params = Get-DSCFakeParameters -ModulePath $module
    # Setting Exchange Session Settings
    $params.Credential = $Credential
    $params.DomainController =  ([ADSI]”LDAP://RootDSE”).dnshostname
    $results = Get-TargetResource @params
    $Script:dscConfigContent += "        xExchEcpVirtualDirectory " + [System.Guid]::NewGuid().toString() + "`r`n"
    $Script:dscConfigContent += "        {`r`n"
    $Script:dscConfigContent += Get-DSCBlock -Params $results -ModulePath $module
    $Script:dscConfigContent += "        }`r`n"
}
function Read-ExchEventLogLevel {
    [cmdletbinding()]
    param()  
    $module = Resolve-Path ($Script:DSCPath + "\DSCResources\MSFT_xExchEventLogLevel\MSFT_xExchEventLogLevel.psm1")
    Import-Module $module
    $params = Get-DSCFakeParameters -ModulePath $module
    # Setting Exchange Session Settings
    $params.Credential = $Credential
    $results = Get-TargetResource @params
    $Script:dscConfigContent += "        xExchEventLogLevel " + [System.Guid]::NewGuid().toString() + "`r`n"
    $Script:dscConfigContent += "        {`r`n"
    $Script:dscConfigContent += Get-DSCBlock -Params $results -ModulePath $module
    $Script:dscConfigContent += "        }`r`n"
}

#Needs work
function Read-ExchExchangeCertificate {
    [cmdletbinding()]
    param(
        [string]
        $Thumbprint
    )  
    $module = Resolve-Path ($Script:DSCPath + "\DSCResources\MSFT_xExchExchangeCertificate\MSFT_xExchExchangeCertificate.psm1")
    Import-Module $module
    $params = Get-DSCFakeParameters -ModulePath $module
    # Setting Exchange Session Settings
    $params.Credential = $Credential
    $params.Thumbprint = $Thumbprint
    $params.DomainController =  ([ADSI]”LDAP://RootDSE”).dnshostname
    $results = Get-TargetResource @params
    $Script:dscConfigContent += "        xExchExchangeCertificate " + [System.Guid]::NewGuid().toString() + "`r`n"
    $Script:dscConfigContent += "        {`r`n"
    $Script:dscConfigContent += Get-DSCBlock -Params $results -ModulePath $module
    $Script:dscConfigContent += "        }`r`n"
}
#Correct DSC Module for 2016<
#What is MonitoringGroup
function Read-ExchExchangeServer {
    [cmdletbinding()]
    param(
        [string]
        $Thumbprint
    )  
    $module = Resolve-Path ($Script:DSCPath + "\DSCResources\MSFT_xExchExchangeServer\MSFT_xExchExchangeServer.psm1")
    Import-Module $module
    $params = Get-DSCFakeParameters -ModulePath $module
    # Setting Exchange Session Settings
    $params.Credential = $Credential
    $Params.Identity = $env:COMPUTERNAME
    $params.DomainController =  ([ADSI]”LDAP://RootDSE”).dnshostname
    $results = Get-TargetResource @params
    $Script:dscConfigContent += "        xExchExchangeServer " + [System.Guid]::NewGuid().toString() + "`r`n"
    $Script:dscConfigContent += "        {`r`n"
    $Script:dscConfigContent += Get-DSCBlock -Params $results -ModulePath $module
    $Script:dscConfigContent += "        }`r`n"
}
function Read-ExchImapSettings {
    [cmdletbinding()]
    param(
        [string]
        $Thumbprint
    )  
    $module = Resolve-Path ($Script:DSCPath + "\DSCResources\MSFT_xExchImapSettings\MSFT_xExchImapSettings.psm1")
    Import-Module $module
    $params = Get-DSCFakeParameters -ModulePath $module
    # Setting Exchange Session Settings
    $params.Credential = $Credential
    $Params.Server = $env:COMPUTERNAME
    $params.DomainController =  ([ADSI]”LDAP://RootDSE”).dnshostname
    $results = Get-TargetResource @params
    $Script:dscConfigContent += "        xExchImapSettings " + [System.Guid]::NewGuid().toString() + "`r`n"
    $Script:dscConfigContent += "        {`r`n"
    $Script:dscConfigContent += Get-DSCBlock -Params $results -ModulePath $module
    $Script:dscConfigContent += "        }`r`n"
}
#How to read all databases needs to be worked out
function Read-ExchMailboxDatabase {
    [cmdletbinding()]
    param()  
    $module = Resolve-Path ($Script:DSCPath + "\DSCResources\MSFT_xExchMailboxDatabase\MSFT_xExchMailboxDatabase.psm1")
    Import-Module $module
    $params = Get-DSCFakeParameters -ModulePath $module
    # Setting Exchange Session Settings
    $params.Credential = $Credential
    $params.Server = $env:COMPUTERNAME
    $params.Remove('AdServerSettingsPreferredServer')
    $params.DomainController =  ([ADSI]”LDAP://RootDSE”).dnshostname
    $results = Get-TargetResource @params
    $Script:dscConfigContent += "        xExchMailboxDatabase " + [System.Guid]::NewGuid().toString() + "`r`n"
    $Script:dscConfigContent += "        {`r`n"
    $Script:dscConfigContent += Get-DSCBlock -Params $results -ModulePath $module
    $Script:dscConfigContent += "        }`r`n"
}
#Needs work to find all database copies
function Read-ExchMailboxDatabaseCopy {
    [cmdletbinding()]
    param()  
    $module = Resolve-Path ($Script:DSCPath + "\DSCResources\MSFT_xExchMailboxDatabaseCopy\MSFT_xExchMailboxDatabaseCopy.psm1")
    Import-Module $module
    $params = Get-DSCFakeParameters -ModulePath $module
    # Setting Exchange Session Settings
    $params.Credential = $Credential
    $params.Server = $env:COMPUTERNAME
    $params.Remove('AdServerSettingsPreferredServer')
    $params.DomainController =  ([ADSI]”LDAP://RootDSE”).dnshostname
    $results = Get-TargetResource @params
    $Script:dscConfigContent += "        xExchMailboxDatabaseCopy " + [System.Guid]::NewGuid().toString() + "`r`n"
    $Script:dscConfigContent += "        {`r`n"
    $Script:dscConfigContent += Get-DSCBlock -Params $results -ModulePath $module
    $Script:dscConfigContent += "        }`r`n"
}
function Read-ExchMailboxServer {
    [cmdletbinding()]
    param()  
    $module = Resolve-Path ($Script:DSCPath + "\DSCResources\MSFT_xExchMailboxServer\MSFT_xExchMailboxServer.psm1")
    Import-Module $module
    $params = Get-DSCFakeParameters -ModulePath $module
    # Setting Exchange Session Settings
    $params.Credential = $Credential
    $params.Identity = $env:COMPUTERNAME
    $params.DomainController =  ([ADSI]”LDAP://RootDSE”).dnshostname
    $results = Get-TargetResource @params
    $Script:dscConfigContent += "        xExchMailboxServer " + [System.Guid]::NewGuid().toString() + "`r`n"
    $Script:dscConfigContent += "        {`r`n"
    $Script:dscConfigContent += Get-DSCBlock -Params $results -ModulePath $module
    $Script:dscConfigContent += "        }`r`n"
}
function Read-ExchMailboxTransportService {
    [cmdletbinding()]
    param()  
    $module = Resolve-Path ($Script:DSCPath + "\DSCResources\MSFT_xExchMailboxTransportService\MSFT_xExchMailboxTransportService.psm1")
    Import-Module $module
    $params = Get-DSCFakeParameters -ModulePath $module
    # Setting Exchange Session Settings
    $params.Credential = $Credential
    $params.Identity = $env:COMPUTERNAME
    $results = Get-TargetResource @params
    $Script:dscConfigContent += "        xExchMailboxTransportService " + [System.Guid]::NewGuid().toString() + "`r`n"
    $Script:dscConfigContent += "        {`r`n"
    $Script:dscConfigContent += Get-DSCBlock -Params $results -ModulePath $module
    $Script:dscConfigContent += "        }`r`n"
}

#endregion

# Sets the DSC Configuration Data for the current server;
function Set-ConfigurationData {
    $Script:dscConfigContent += "`$ConfigData = @{`r`n"
    $Script:dscConfigContent += "    AllNodes = @(`r`n"    

    $tempConfigDataContent += "    @{`r`n"
    $tempConfigDataContent += "        NodeName = `"$env:COMPUTERNAME`";`r`n"
    $tempConfigDataContent += "        PSDscAllowPlainTextPassword = `$true;`r`n"
    $tempConfigDataContent += "        PSDscAllowDomainUser = `$true;`r`n"
    $tempConfigDataContent += "    }`r`n"    

    $Script:dscConfigContent += $tempConfigDataContent
    $Script:dscConfigContent += ")}`r`n"
}

<## This function ensures all required DSC Modules are properly loaded into the current PowerShell session. #>
function Set-Imports {
    $Script:dscConfigContent += "    Import-DscResource -ModuleName PSDesiredStateConfiguration`r`n"
    $Script:dscConfigContent += "    Import-DscResource -ModuleName xExchange -ModuleVersion `"" + $DSCVersion + "`"`r`n"
}

<## This function sets the settings for the Local Configuration Manager (LCM) component on the server we will be configuring using our resulting DSC Configuration script. The LCM component is the one responsible for orchestrating all DSC configuration related activities and processes on a server. This method specifies settings telling the LCM to not hesitate rebooting the server we are configurating automatically if it requires a reboot (i.e. During the SharePoint Prerequisites installation). Setting this value helps reduce the amount of manual interaction that is required to automate the configuration of our SharePoint farm using our resulting DSC Configuration script. #>
function Set-LCM {
    $Script:dscConfigContent += "        LocalConfigurationManager" + "`r`n"
    $Script:dscConfigContent += "        {`r`n"
    $Script:dscConfigContent += "            RebootNodeIfNeeded = `$True`r`n"
    $Script:dscConfigContent += "        }`r`n"
}


<# This function is responsible for saving the output file onto disk. #>
function Get-ReverseDSC() {
    <## Call into our main function that is responsible for extracting all the information about our SharePoint farm. #>
    Orchestrator

    <## Prompts the user to specify the FOLDER path where the resulting PowerShell DSC Configuration Script will be saved. #>
    $fileName = "xExchange.DSC.ps1"
    $OutputDSCPath = Read-Host "Please enter the full path of the output folder for DSC Configuration (will be created as necessary)"
    
    <## Ensures the specified output folder path actually exists; if not, tries to create it and throws an exception if we can't. ##>
    while (!(Test-Path -Path $OutputDSCPath -PathType Container -ErrorAction SilentlyContinue)) {
        try {
            Write-Output "Directory `"$OutputDSCPath`" doesn't exist; creating..."
            New-Item -Path $OutputDSCPath -ItemType Directory | Out-Null
            if ($?) {break}
        }
        catch {
            Write-Warning "$($_.Exception.Message)"
            Write-Warning "Could not create folder $OutputDSCPath!"
        }
        $OutputDSCPath = Read-Host "Please Enter Output Folder for DSC Configuration (Will be Created as Necessary)"
    }
    <## Ensures the path we specify ends with a Slash, in order to make sure the resulting file path is properly structured. #>
    if (!$OutputDSCPath.EndsWith("\") -and !$OutputDSCPath.EndsWith("/")) {
        $OutputDSCPath += "\"
    }

    <## Save the content of the resulting DSC Configuration file into a file at the specified path. #>
    $outputDSCFile = $OutputDSCPath + $fileName
    $Script:dscConfigContent | Out-File $outputDSCFile
    Write-Output "Done."
    <## Wait a couple of seconds, then open our $outputDSCPath in Windows Explorer so we can review the glorious output. ##>
    Start-Sleep 2
    Invoke-Item -Path $OutputDSCPath
}

Get-ReverseDSC
