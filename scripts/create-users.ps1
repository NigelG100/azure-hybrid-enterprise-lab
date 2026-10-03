$ErrorActionPreference = "Stop"

Import-Module ActiveDirectory

$domainDN = (Get-ADDomain).DistinguishedName
$domainName = "corp.nigellab.test"

$employees = @(
    @("Jordan", "Miller", "jmiller", "IT", "SG-IT"),
    @("Taylor", "Reed", "treed", "IT", "SG-IT"),
    @("Avery", "Brooks", "abrooks", "Human Resources", "SG-HR"),
    @("Morgan", "Ellis", "mellis", "Human Resources", "SG-HR"),
    @("Casey", "Nguyen", "cnguyen", "Finance", "SG-Finance"),
    @("Riley", "Parker", "rparker", "Finance", "SG-Finance"),
    @("Cameron", "Davis", "cdavis", "Operations", "SG-Operations"),
    @("Jamie", "Wilson", "jwilson", "Operations", "SG-Operations")
)

foreach ($employee in $employees) {

    $first = $employee[0]
    $last = $employee[1]
    $username = $employee[2]
    $department = $employee[3]
    $group = $employee[4]

    $ouPath = "OU=$department,OU=Departments,$domainDN"

    # Check if the account exists
    $existing = Get-ADUser `
        -LDAPFilter "(sAMAccountName=$username)" `
        -SearchBase $domainDN

    if (-not $existing) {

        New-ADUser `
            -Name "$first $last" `
            -GivenName $first `
            -Surname $last `
            -SamAccountName $username `
            -UserPrincipalName "$username@$domainName" `
            -Department $department `
            -Path $ouPath `
            -Enabled $false

        Write-Output "CREATED: $username"
    }
    else {
        Write-Output "EXISTS: $username"
    }

    # Assign departmental security group
    $members = Get-ADGroupMember -Identity $group

    if ($username -notin $members.SamAccountName) {
        Add-ADGroupMember `
            -Identity $group `
            -Members $username

        Write-Output "GROUP ASSIGNED: $username -> $group"
    }
}

# Verify employee accounts
Write-Output "`nEMPLOYEE DIRECTORY"

Get-ADUser -Filter * `
    -SearchBase "OU=Departments,$domainDN" `
    -Properties Department |
    Select-Object Name,SamAccountName,Department,Enabled |
    Sort-Object Department,Name |
    Format-Table -AutoSize |
    Out-String -Width 180