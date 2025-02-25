# 🚀 Avvio dell'ambiente virtuale e raccolta dati di sistema
Write-Host "🔄 [INFO] Attivazione dell'ambiente virtuale..." -ForegroundColor Cyan

# Controlla se esiste già un ambiente virtuale
if (-Not (Test-Path "venv")) {
    Write-Host "🚀 Creazione di un nuovo ambiente virtuale..."
    python -m venv venv
}

# Attiva l'ambiente virtuale (Solo Windows, quindi niente IF)
Write-Host "🔄 Attivazione dell'ambiente virtuale..."
. .\venv\Scripts\Activate

Write-Host "===== SYSTEM INFORMATION ====="

# CPU Info
$cpu = Get-CimInstance Win32_Processor | Select-Object -Property Name, NumberOfCores, MaxClockSpeed
Write-Host "`n--- CPU ---"
Write-Host "Nome CPU:         $($cpu.Name)"
Write-Host "Core Fisici:      $($cpu.NumberOfCores)"
Write-Host "Frequenza Max:    $($cpu.MaxClockSpeed) MHz"

# RAM Info
Write-Host "`n--- RAM ---"
# Memoria Fisica Totale (in MB)
$ramCs = Get-CimInstance Win32_ComputerSystem | Select-Object -Property TotalPhysicalMemory
$totalPhysicalMB = [Math]::Round($ramCs.TotalPhysicalMemory / 1MB, 2)

# Memoria realmente disponibile (in MB)
$os = Get-CimInstance Win32_OperatingSystem
$freePhysicalMB = [Math]::Round($os.FreePhysicalMemory / 1KB, 2) # FreePhysicalMemory è in KB

# Memoria fisica utilizzata
$usedPhysicalMB = $totalPhysicalMB - $freePhysicalMB

Write-Host ("Memoria Fisica Totale:   {0} MB" -f $totalPhysicalMB)
Write-Host ("Memoria Disponibile:     {0} MB" -f $freePhysicalMB)
Write-Host ("Memoria Utilizzata:      {0} MB" -f $usedPhysicalMB)

# Disk Info
$disks = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" |
    Select-Object DeviceID, Size, FreeSpace
Write-Host "`n--- DISCHI ---"
foreach ($disk in $disks) {
    $usedSpace = $disk.Size - $disk.FreeSpace
    $usedPct = [Math]::Round(($usedSpace / $disk.Size) * 100, 2)
    Write-Host "Drive $($disk.DeviceID):"
    Write-Host ("  Spazio Totale:   {0} GB" -f ([Math]::Round($disk.Size / 1GB, 2)))
    Write-Host ("  Spazio Libero:   {0} GB" -f ([Math]::Round($disk.FreeSpace / 1GB, 2)))
    Write-Host ("  Utilizzato:      {0}% di spazio" -f $usedPct)
}

Write-Host "`n===== FINE INFORMAZIONI ====="

# Avvia l'app 
Write-Host "🚀 Avvio dell'app ..." -ForegroundColor Green
python main.py

deactivate