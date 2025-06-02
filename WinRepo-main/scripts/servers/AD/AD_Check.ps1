# Function to display Active Directory configuration
function Show-ADConfig {
    # Get the domain information
    $domain = Get-ADDomain

    # Get the forest information
    $forest = Get-ADForest

    # Display domain information
    Write-Host "Domain Name: $($domain.Name)"
    Write-Host "Domain Mode: $($domain.DomainMode)"
    Write-Host "PDC Emulator: $($domain.PdcEmulator)"
    Write-Host "RID Master: $($domain.RidMaster)"
    Write-Host "Infrastructure Master: $($domain.InfrastructureMaster)"
    Write-Host "Domain Controllers: $($domain.DomainControllers)"
    Write-Host "----------------------------------------"

    # Display forest information
    Write-Host "Forest Name: $($forest.Name)"
    Write-Host "Forest Mode: $($forest.ForestMode)"
    Write-Host "Schema Master: $($forest.SchemaMaster)"
    Write-Host "Domain Naming Master: $($forest.DomainNamingMaster)"
    Write-Host "Global Catalogs: $($forest.GlobalCatalogs)"
    Write-Host "----------------------------------------"
}

# Call the function to display AD configuration
Show-ADConfig

Write-Host "Active Directory configuration displayed successfully."