$ErrorActionPreference = "Stop"

Import-Module ActiveDirectory

$domainDN = (Get-ADDomain).DistinguishedName

function Ensure-OU {
    param(
        [string]$Name,
        [string]$Path
    )

    $existing = Get-ADOrganizationalUnit `
        -LDAPFilter "(ou=$Name)" `
        -SearchBase $Path `
        -SearchScope OneLevel

    if (-not $existing) {
        New-ADOrganizationalUnit `
            -Name $Name `
            -Path $Path `
            -ProtectedFromAccidentalDeletion $true

        Write-Output "CREATED: $Name"
    }
    else {
        Write-Output "EXISTS: $Name"
    }
}

# Create top-level OUs
Ensure-OU "Departments" $domainDN
Ensure-OU "Security Groups" $domainDN
Ensure-OU "Workstations" $domainDN

# Create department OUs
$parentDN = "OU=Departments,$domainDN"

Ensure-OU "IT" $parentDN
Ensure-OU "Human Resources" $parentDN
Ensure-OU "Finance" $parentDN
Ensure-OU "Operations" $parentDN

# Verify results
Write-Output "`nACTIVE DIRECTORY ORGANIZATIONAL UNITS"

Get-ADOrganizationalUnit -Filter * |
    Select-Object Name, DistinguishedName |
    Sort-Object DistinguishedName |
    Format-Table -AutoSize |
    Out-String -Width 220

    Ensure-OU "Member Servers" $domainDN