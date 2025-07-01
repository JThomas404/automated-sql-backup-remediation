$users = Get-ChildItem -Path "C:\Users" -Directory | Where-Object { $_.Name -notin @("Default", "Default User", "Public", "All Users") }
foreach ($user in $users) {
    $recyclePath = "C:\$Recycle.Bin"
    $userSID = (Get-Acl $user.FullName).Owner
    $userBin = Join-Path $recyclePath $userSID
    if (Test-Path $userBin) {
        Write-Host "Clearing recycle bin for: $($user.Name)"
        Remove-Item "$userBin\*" -Force -Recurse -ErrorAction SilentlyContinue
    }
}
