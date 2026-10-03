$ErrorActionPreference = "Stop"

Import-Module ActiveDirectory

$domainDN = (Get-ADDomain).DistinguishedName

$groupOU = "OU=Security Groups,$domainDN"

$groups = @(
    "SG-IT",
    "SG-HR",
    "SG-Finance",
    "SG-Operations"
)

foreach ($group in $groups) {

    $existing = Get-ADGroup `
        -LDAPFilter "(sAMAccountName=$group)" `
        -SearchBase $groupOU

    if (-not $existing) {

        New-ADGroup `
            -Name $group `
            -SamAccountName $group `
            -GroupCategory Security `
            -GroupScope Global `
            -Path $groupOU

        Write-Output "CREATED: $group"
    }
    else {
        Write-Output "EXISTS: $group"
    }
}

Write-Output "`nSECURITY GROUPS"

Get-ADGroup -Filter * -SearchBase $groupOU |
    Select-Object Name,GroupScope,GroupCategory |
    Format-Table -AutoSize |
    Out-String