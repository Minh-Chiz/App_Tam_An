# Enable TCP/IP for SQL Server Express
# Run this script as Administrator

Write-Host "=== Enabling TCP/IP for SQL Server SQLEXPRESS ===" -ForegroundColor Green
Write-Host ""

# Import SQL Server module
$modulePath = "SQLPS"
if (Get-Module -ListAvailable -Name $modulePath) {
    Import-Module $modulePath -ErrorAction SilentlyContinue
}

# Method 1: Using WMI
try {
    Write-Host "Attempting to enable TCP/IP using WMI..." -ForegroundColor Yellow
    
    $smo = 'Microsoft.SqlServer.Management.Smo.'
    $wmi = new-object ($smo + 'Wmi.ManagedComputer')
    
    # Get the instance
    $instance = $wmi.ServerInstances['SQLEXPRESS']
    
    if ($instance) {
        $tcp = $instance.ServerProtocols['Tcp']
        
        if ($tcp.IsEnabled -eq $false) {
            $tcp.IsEnabled = $true
            $tcp.Alter()
            Write-Host "✅ TCP/IP has been enabled!" -ForegroundColor Green
        } else {
            Write-Host "✅ TCP/IP is already enabled!" -ForegroundColor Green
        }
        
        # Set TCP Port to 1433
        $ipAll = $tcp.IPAddresses['IPAll']
        $ipAll.IPAddressProperties['TcpPort'].Value = '1433'
        $tcp.Alter()
        Write-Host "✅ TCP Port set to 1433" -ForegroundColor Green
    }
} catch {
    Write-Host "⚠️  WMI method failed: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Please enable TCP/IP manually:" -ForegroundColor Cyan
    Write-Host "1. Run: SQLServerManager15.msc" -ForegroundColor White
    Write-Host "2. SQL Server Network Configuration → Protocols for SQLEXPRESS" -ForegroundColor White
    Write-Host "3. Right-click TCP/IP → Enable" -ForegroundColor White
}

# Restart SQL Server Service
Write-Host ""
Write-Host "Restarting SQL Server service..." -ForegroundColor Yellow

try {
    Restart-Service 'MSSQL$SQLEXPRESS' -Force
    Write-Host "✅ SQL Server restarted successfully!" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Could not restart service automatically" -ForegroundColor Yellow
    Write-Host "Please restart manually in SQL Server Configuration Manager" -ForegroundColor Cyan
}

# Start SQL Browser
Write-Host ""
Write-Host "Starting SQL Server Browser..." -ForegroundColor Yellow

try {
    Start-Service 'SQLBrowser' -ErrorAction Stop
    Set-Service 'SQLBrowser' -StartupType Automatic
    Write-Host "✅ SQL Browser started and set to automatic!" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Could not start SQL Browser: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "This is optional but recommended" -ForegroundColor Gray
}

Write-Host ""
Write-Host "=== Configuration Complete ===" -ForegroundColor Green
Write-Host "You can now test the connection from Node.js" -ForegroundColor Cyan
