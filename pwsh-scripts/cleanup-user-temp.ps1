Get-ChildItem -Path "C:\Users" -Directory | ForEach-Object {
    $tempPath = Join-Path $_.FullName "AppData\Local\Temp"
    if (Test-Path $tempPath) {
        Write-Host "Cleaning temp for: $($_.Name)"
        Remove-Item "$tempPath\*" -Force -Recurse -ErrorAction SilentlyContinue
    }
}
