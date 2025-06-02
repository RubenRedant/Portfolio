# Activeer het administrator account
# if activated restart computer
Write-Host "Activeren van het administrator account..."
try {
    net user administrator /active:yes
    Write-Host "Administrator account succesvol geactiveerd. Herstarten van computer..."
    Restart-Computer -Force
} catch {
    Write-Host "Error bij het activeren van het administrator account. Error: $_"
    exit 1
}