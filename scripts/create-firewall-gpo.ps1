$ErrorActionPreference = "Stop"

Import-Module GroupPolicy

$gpoName = "LAB - Enforce Domain Firewall"
$domain = "corp.nigellab.test"

$targetOU = "OU=Member Servers,DC=corp,DC=nigellab,DC=test"

# Check whether GPO already exists
$gpo = Get-GPO -Name $gpoName -Domain $domain `
    -ErrorAction SilentlyContinue

if (-not $gpo) {
    $gpo = New-GPO -Name $gpoName `
        -Domain $domain `
        -Comment "Enforce Windows Firewall on domain servers"

    Write-Output "CREATED GPO: $gpoName"
}
else {
    Write-Output "GPO ALREADY EXISTS: $gpoName"
}

# Enable Windows Firewall for Domain Profile
Set-GPRegistryValue `
    -Guid $gpo.Id `
    -Domain $domain `
    -Key "HKLM\SOFTWARE\Policies\Microsoft\WindowsFirewall\DomainProfile" `
    -ValueName "EnableFirewall" `
    -Type DWord `
    -Value 1

Write-Output "CONFIGURED: Domain Firewall Enabled"

# Link policy to Member Servers OU if needed
$existingLink = (Get-GPInheritance -Target $targetOU).GpoLinks |
    Where-Object { $_.GpoId -eq $gpo.Id }

if (-not $existingLink) {
    New-GPLink -Guid $gpo.Id `
        -Domain $domain `
        -Target $targetOU `
        -LinkEnabled Yes | Out-Null

    Write-Output "GPO LINKED: Member Servers"
}
else {
    Write-Output "GPO LINK ALREADY EXISTS"
}

Write-Output "GPO CONFIGURATION COMPLETE"