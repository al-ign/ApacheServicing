# ApacheServicing
Apache ''configuration'' using PowerShell

This module was ad-hoc written to create httpd virtual-host configurations parametrically and programmatically.
Of course, it didn't stop after that...

Currently available functions:
 Get-ApacheConfigurationPath
 Get-ApacheRunningConfig
 New-ApacheDirectoryDirective
 New-ApacheVirtualHostConfiguration
 Test-ApacheConfiguration
 Get-ApacheConfigurationTest

Usage example:
$dirs = @(
  New-ApacheDirectoryDirective -Directory '/data/www/dir1' -AllowOverride 'all'
  New-ApacheDirectoryDirective -Directory '/data/www/dir2' 
  New-ApacheDirectoryDirective -Directory '/data/www/dir3' -Options 'IncludesNOEXEC'
  )
New-ApacheVirtualHostConfiguration -ServerName 'test1.domain.tld' -DocumentRoot '/data/www' -Directory $dirs
