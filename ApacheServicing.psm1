

function Get-ApacheRunningConfig {
    (httpd -t -D DUMP_RUN_CFG ) | % {
        $_ -replace '^(.+)\s*:\s*"*([^"].+[^"])"*$','$1=$2'
        } | ConvertFrom-StringData


    <#
    .SYNOPSIS 
    Get current running config from httpd itself

    .DESCRIPTION
    Generate hashtable containing current running configuration
    http://httpd.apache.org/docs/current/mod/core.html#directory
    
    .INPUTS
    None. You cannot pipe objects to this function

    .OUTPUTS
    Current configuration stored in hashtable

    .EXAMPLE
    Get-ApacheRunningConfig

    Generate current configuration

    #>

    }

function Get-ApacheConfigurationPath {

    #https://wiki.apache.org/httpd/DistrosDefaultLayout
    $ApacheDistroSpecificConfPath = (
    "/usr/local/apache2/conf/httpd.conf",
    "/etc/apache2/apache2.conf",
    "/etc/httpd/httpd.conf",
    "/etc/apache2/httpd.conf",
    "/etc/httpd/conf/httpd.conf",
    "/usr/pkg/etc/httpd/httpd.conf",
    "/usr/local/etc/apache22/httpd.conf",
    "/usr/local/etc/apache2/httpd.conf",
    "/var/www/conf/httpd.conf",
    "/etc/apache2/httpd2.conf")

    $RunConfig = Get-ApacheRunningConfig
    $Apache.config = "" | select httpdconf, vdir
    $Apache.httpdconf = $RunConfig.'ServerRoot' + "/conf/httpd.conf"
    $Apache.vdir = $RunConfig.'ServerRoot' + '/conf.d/'
    }
    
function New-ApacheVirtualHostConfiguration {
[CmdletBinding()]
param (
        [Parameter(Mandatory=$True)]
        [Alias('FQDN','Hostname')]
    [string]$ServerName,
        [Parameter(Mandatory=$True)]
        [Alias('PhysicalPath')]
    [string]$DocumentRoot,
        [Parameter(Mandatory=$False)]
    [string]$IP = '*',
        [Parameter(Mandatory=$False)]
    [int]$Port = '80',
        [Parameter(Mandatory=$False)]
    [string]$ServerAdmin = 'webservices@localhost',
        [Parameter(Mandatory=$False)]
    [string]$LogPath,
        [Parameter(Mandatory=$False)]
    [string[]]$Directory,
        [Parameter(Mandatory=$False)]
    [string[]]$CustomOptions
    )
    if (-not ($LogPath)) {
        try {
            $RunningConfig = Get-ApacheRunningConfig
            $TestingPath = ( $RunningConfig.'Main ErrorLog' -replace "(.+\/).+$",'$1' )
            if (Test-Path $TestingPath -PathType Container ) {
                $LogPath = $TestingPath
                } #end if 
            }
        catch {
            "Couldn't get errorlog path from running config" | Write-Warning
            }
        } #end if logpath

$vHostConfig = @"
<VirtualHost $($IP):$($Port)>
ServerAdmin $ServerAdmin
DocumentRoot "$DocumentRoot"
ServerName $ServerName
$( 
    if ($LogPath) { 
#remove trailing slash
$LogPath = $LogPath -replace "\/$"
@"
ErrorLog "$LogPath/$ServerName-error_log"
CustomLog "$LogPath/$ServerName-access_log" combined
"@
    }#end if logpath
)
$(  #
    @($CustomOptions) | % {$_} 
    )

$(  #
    @($Directory) | % {$_} 
    )

</VirtualHost>
"@
    return $vHostConfig


<#
.SYNOPSIS 
Generate an Apache Virtual Host configuration

.DESCRIPTION
Generate an Apache Virtual Host configuration file contents.
http://httpd.apache.org/docs/current/mod/core.html#virtualhost
    
.PARAMETER ServerName
Servername directive - should be FQDN of your server

.PARAMETER DocumentRoot
DocumentRoot directive - location of web-site on your filesystem

.PARAMETER LogPath
Path where log files for virtual host will be stored. If parameter is not given, default location will be determined through call to running httpd instance (and logs directory should exist).
If parameter is given it will be passed to configuration 'as is'

.INPUTS
None. You cannot pipe objects to this function

.OUTPUTS
Generated configuration. 

.EXAMPLE
New-ApacheVirtualHostConfiguration -ServerName 'test1.domain.tld' -DocumentRoot '/data/www'

Generate simple Virtual Host configuration

.EXAMPLE
$dirs = @(
New-ApacheDirectoryDirective -Directory '/data/www/dir1' -AllowOverride 'all'
New-ApacheDirectoryDirective -Directory '/data/www/dir2' 
New-ApacheDirectoryDirective -Directory '/data/www/dir3' -Options 'IncludesNOEXEC'
)
New-ApacheVirtualHostConfiguration -ServerName 'test1.domain.tld' -DocumentRoot '/data/www' -Directory $dirs

Generate Virtual Host with additional Directory blocks using New-ApacheDirectoryDirective 

#>

}

function New-ApacheDirectoryDirective {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)]
    [string]$Directory,
        [Parameter(Mandatory=$False)]
    [string]$DirectoryIndex = 'index.html index.php',
        [Parameter(Mandatory=$False)]
    [string]$Options = 'FollowSymLinks',
        [Parameter(Mandatory=$False)]
    [string]$AllowOverride = 'None',
        [Parameter(Mandatory=$False)]
    [string]$Require = 'all granted',
        [Parameter(Mandatory=$False)]
    [string[]]$CustomOptions
    )
$Directory = @"
#start directory
<Directory "$Directory">
DirectoryIndex $DirectoryIndex
Options $Options
AllowOverride $AllowOverride
Require $Require
$( @($CustomOptions) | % {$_} )
</Directory>
#end directory 

"@
    return $Directory

<#
.SYNOPSIS 
Generate an Apache 'Directory' directive configuration

.DESCRIPTION
Generate an Apache 'Directory' directive for use in site configurations.
http://httpd.apache.org/docs/current/mod/core.html#directory
    
.PARAMETER Directory
Directory directive - should be full path to a directory, or a wild-card string using Unix shell-style matching

.PARAMETER DirectoryIndex
DirectoryIndex directive - list of resources to look for, when the client requests an index of the directory by specifying a / at the end of the directory name

.INPUTS
None. You cannot pipe objects to this function

.OUTPUTS
Generated configuration. 

.EXAMPLE
New-ApacheDirectoryDirective -Directory '/data/www/dir1' -AllowOverride 'all'

Generate Directory configuration

.EXAMPLE
$dirs = @(
New-ApacheDirectoryDirective -Directory '/data/www/dir1' -AllowOverride 'all'
New-ApacheDirectoryDirective -Directory '/data/www/dir2' 
New-ApacheDirectoryDirective -Directory '/data/www/dir3' -Options 'IncludesNOEXEC'
)
New-ApacheVirtualHostConfiguration -ServerName 'test1.domain.tld' -DocumentRoot '/data/www' -Directory $dirs

Generate Virtual Host with additional Directory blocks

#>

}#end function 

function Test-ApacheConfiguration {
    $ApacheOutput = httpd -t 2>&1
    if ($ApacheOutput -match 'Syntax OK') {
        $true
        If (@($ApacheOutput).Count -gt 1 ) {
            $ApacheOutput.Exception.Message | Write-Warning
            }
        } 
        else {
        $false
        $ApacheOutput.Exception.Message | Write-Warning
        }

<#
.SYNOPSIS 
Test httpd/apache2 configuration

.DESCRIPTION
Invoke Apache HTTP Daemon built-in configuration test.

.INPUTS
None. You cannot pipe objects to this function.

.OUTPUTS
Boolean value corresponding to state of configuration.
All warnings and errors will be reported to Warnings channel.

.EXAMPLE
Test-ApacheConfiguration

Get test result

.EXAMPLE
If (Test-ApacheConfiguration) { "Everything is OK!"} else { "Errors in configuration!"}
Use coding and algorithms to determine script flow!

#>

    } #end funct

New-Alias Get-ApacheConfigurationTest Test-ApacheConfiguration
