param(
    [Parameter(Mandatory=$true)]
    [string]$CsvBase64
)

$ErrorActionPreference = "Stop"
Import-Module ActiveDirectory

$domainDN = (Get-ADDomain).DistinguishedName

$departmentGroups = @{
    "IT"              = "SG-IT"
    "Human Resources" = "SG-HR"
    "Finance"         = "SG-Finance"
    "Operations"      = "SG-Operations"
}

$csvText = [Text.Encoding]::UTF8.GetString(
    [Convert]::FromBase64String($CsvBase64)
)

$employees = $csvText -split '\r?\n' |
    Where-Object { $_.Trim() } |
    ConvertFrom-Csv

foreach ($employee in $employees) {

    $username = $employee.Username.Trim()
    $department = $employee.Department.Trim()

    if ($username -notmatch '^[a-z][a-z0-9._-]{2,19}$') {
        throw "Invalid username format."
    }

    if (-not $departmentGroups.ContainsKey($department)) {
        throw "Unapproved department: $department"
    }

    $existing = Get-ADUser `
        -LDAPFilter "(sAMAccountName=$username)" `
        -SearchBase $domainDN

    if ($existing) {
        Write-Output "SKIPPED existing account: $username"
        continue
    }

    $ouPath = "OU=$department,OU=Departments,$domainDN"
    $group = $departmentGroups[$department]

    New-ADUser `
        -Name "$($employee.FirstName) $($employee.LastName)" `
        -GivenName $employee.FirstName `
        -Surname $employee.LastName `
        -SamAccountName $username `
        -UserPrincipalName "$username@corp.nigellab.test" `
        -Department $department `
        -Path $ouPath `
        -Enabled $false

    Add-ADGroupMember -Identity $group -Members $username

    Write-Output "CREATED: $username"
    Write-Output "ASSIGNED: $username -> $group"
}