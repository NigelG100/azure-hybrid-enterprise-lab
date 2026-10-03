$ErrorActionPreference = "Stop"
Import-Module ActiveDirectory

$groupName = "SG-CloudSync-Pilot"
$ou = "OU=Security Groups,DC=corp,DC=nigellab,DC=test"

$group = Get-ADGroup `
    -LDAPFilter "(cn=$groupName)" `
    -SearchBase $ou

if (-not $group) {
    New-ADGroup `
        -Name $groupName `
        -SamAccountName $groupName `
        -GroupScope Global `
        -GroupCategory Security `
        -Path $ou

    Write-Output "Created pilot security group."
}

Add-ADGroupMember `
    -Identity $groupName `
    -Members "nortiz","lbennett"

Write-Output "Pilot group members:"

Get-ADGroupMember -Identity $groupName |
    Select-Object Name,SamAccountName |
    Format-Table

Write-Output "Group distinguished name:"

(Get-ADGroup -Identity $groupName).DistinguishedName