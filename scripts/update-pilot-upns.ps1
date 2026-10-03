$ErrorActionPreference = "Stop"
Import-Module ActiveDirectory

$suffix = "nigelgoodall70hotmail.onmicrosoft.com"

# Register the alternate UPN suffix in AD
$forest = Get-ADForest

if ($forest.UPNSuffixes -notcontains $suffix) {
    Set-ADForest -Identity $forest.Name `
        -UPNSuffixes @{Add=$suffix}

    Write-Output "Added alternate UPN suffix."
}

# Update only the two pilot accounts
$users = @("nortiz", "lbennett")

foreach ($username in $users) {
    $newUPN = "$username@$suffix"

    Set-ADUser -Identity $username `
        -UserPrincipalName $newUPN

    Write-Output "Updated: $newUPN"
}

# Verify
$users | ForEach-Object {
    Get-ADUser $_ -Properties UserPrincipalName,Enabled |
        Select-Object Name,UserPrincipalName,Enabled
} | Format-Table -AutoSize