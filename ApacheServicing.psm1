

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
    $RunConfig = Get-ApacheConfigurationPath
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
    [string]$LogPath = '/var/log/httpd',
        [Parameter(Mandatory=$False)]
    [string[]]$Directory 
    )





$LogPath = $LogPath -replace "\/$"
$vHostConfig = @"
<VirtualHost $($IP):$($Port)>
ServerAdmin $ServerAdmin
DocumentRoot "$DocumentRoot"
ServerName $ServerName

ErrorLog "$LogPath/$ServerName-error_log"
CustomLog "$LogPath/$ServerName-access_log" combined

$(
    @($Directory) | %{$_.ToString()}
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
New-ApacheDirectoryDirective -Directory '/data/www/dir3' -Options 'someopt'
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
    [string]$Require = 'all granted'
    )
    $Directory = @"

<Directory "$Directory">
DirectoryIndex $DirectoryIndex
Options $Options
AllowOverride $AllowOverride
Require $Require
</Directory>

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
New-ApacheDirectoryDirective -Directory '/data/www/dir3' -Options 'someopt'
)
New-ApacheVirtualHostConfiguration -ServerName 'test1.domain.tld' -DocumentRoot '/data/www' -Directory $dirs

Generate Virtual Host with additional Directory blocks

#>

}#end function 
