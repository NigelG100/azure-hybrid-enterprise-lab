$ErrorActionPreference = "Stop"

Write-Output "=== APPLIED GROUP POLICY ==="

$result = gpresult.exe /scope computer /r

$matches = $result | Select-String `
    -Pattern "LAB - Enforce Domain Firewall" `
    -SimpleMatch

if (-not $matches) {
    throw "Firewall GPO not found in applied policies."
}

Write-Output "VERIFIED: Firewall GPO applied"

Write-Output "`n=== FIREWALL POLICY ==="

$path = "HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\DomainProfile"

$policy = Get-ItemProperty `
    -Path $path `
    -Name EnableFirewall `
    -ErrorAction Stop

Write-Output "Policy EnableFirewall: $($policy.EnableFirewall)"

if ($policy.EnableFirewall -ne 1) {
    throw "Firewall policy not enabled."
}

Write-Output "`n=== EFFECTIVE FIREWALL ==="

Get-NetFirewallProfile -Name Domain |
    Select-Object Name,Enabled |
    Format-Table -AutoSize |
    Out-String