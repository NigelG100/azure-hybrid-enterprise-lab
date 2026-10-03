$ErrorActionPreference = "Stop"

Import-Module ActiveDirectory

$accountName = "gmsaCloudSync"
$domainName = "corp.nigellab.test"

Write-Output "Checking KDS root key..."

$keys = @(
    Get-KdsRootKey |
    Where-Object { $null -ne $_ }
)

if ($keys.Count -eq 0) {
    # Isolated single-domain-controller lab only
    Add-KdsRootKey -EffectiveTime ((Get-Date).AddHours(-10)) |
        Out-Null

    Write-Output "Created lab KDS root key."
}
else {
    Write-Output "KDS root key exists."

    $ready = @(
        $keys | Where-Object {
            $_.EffectiveTime -le (Get-Date)
        }
    )

    if ($ready.Count -eq 0) {
        throw "Existing KDS key is not yet effective. Stop and check its effective time."
    }
}

Write-Output "Checking MEMBER01..."

$member = Get-ADComputer -Identity "MEMBER01"

Write-Output "Checking gMSA..."

$existing = Get-ADServiceAccount `
    -Filter "Name -eq '$accountName'"

if (-not $existing) {

    New-ADServiceAccount `
        -Name $accountName `
        -DNSHostName "$accountName.$domainName" `
        -PrincipalsAllowedToRetrieveManagedPassword $member `
        -KerberosEncryptionType AES128,AES256

    Write-Output "Created gMSA: $accountName"
}
else {
    Write-Output "gMSA already exists."

    Set-ADServiceAccount `
        -Identity $accountName `
        -PrincipalsAllowedToRetrieveManagedPassword $member
}

Get-ADServiceAccount -Identity $accountName `
    -Properties PrincipalsAllowedToRetrieveManagedPassword |
    Select-Object Name,Enabled,DNSHostName,
        PrincipalsAllowedToRetrieveManagedPassword |
    Format-List