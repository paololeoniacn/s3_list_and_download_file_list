# PowerShell Script - setup.ps1

# Definizione della versione di Python richiesta
$PYTHON_VERSION = "3.12.3"

# 🔍 Controllo della versione di Python attuale
Write-Host "🔍 Verifica della versione di Python..."
$pythonVersionOutput = python --version 2>&1
if ($pythonVersionOutput -match "No global/local python version has been set yet") {
    Write-Host "❌ Nessuna versione di Python è stata impostata. Controllo Pyenv..."
    $pythonVersion = $null
} else {
    $pythonVersion = $pythonVersionOutput -replace "Python ", ""
}

# ⚠️ Se la versione di Python NON è quella richiesta, tenta di usare Pyenv
if ($pythonVersion -ne $PYTHON_VERSION) {
    Write-Host "⚠️ Versione Python errata. Richiesta: $PYTHON_VERSION, Trovata: $pythonVersion"
    
    # Controllo se Pyenv è installato
    $pyenvCheck = Get-Command pyenv -ErrorAction SilentlyContinue
    if (-not $pyenvCheck) {
        Write-Host "❌ Pyenv non è installato. Installa Pyenv e riprova."
        Exit 1
    }

    Write-Host "✅ Pyenv trovato. Provo a installare e impostare Python $PYTHON_VERSION..."

    # Controllo se la versione di Python richiesta è già installata su Pyenv
    $installedVersions = pyenv versions --bare
    if ($installedVersions -notcontains $PYTHON_VERSION) {
        Write-Host "🔄 Installazione di Python $PYTHON_VERSION tramite Pyenv..."
        pyenv install $PYTHON_VERSION
        if ($LASTEXITCODE -ne 0) {
            Write-Host "❌ Errore nell'installazione di Python con Pyenv. Esco..."
            Exit 1
        }
    }

    # Risincronizza Pyenv
    Write-Host "🔄 Aggiornamento Pyenv..."
    pyenv rehash

    # Impostare la versione di Python a livello locale per questa cartella
    Write-Host "🔄 Impostazione della versione di Python a livello locale..."
    pyenv local $PYTHON_VERSION
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Errore nell'impostare la versione locale di Python. Esco..."
        Exit 1
    }

    # Riprova a verificare la versione di Python
    $pythonVersion = python --version 2>&1
    $pythonVersion = $pythonVersion -replace "Python ", ""

    # Se la versione è ancora errata, esci con errore
    if ($pythonVersion -ne $PYTHON_VERSION) {
        Write-Host "❌ Errore critico: Python $PYTHON_VERSION non è stato impostato correttamente. Esco..."
        Exit 1
    }
}

Write-Host "✅ Versione di Python corretta ($PYTHON_VERSION). Procedo con il setup..."

# Controlla se esiste già un ambiente virtuale
if (-Not (Test-Path "venv")) {
    Write-Host "🚀 Creazione di un nuovo ambiente virtuale..."
    python -m venv venv
}

# Attiva l'ambiente virtuale (Solo Windows, quindi niente IF)
Write-Host "🔄 Attivazione dell'ambiente virtuale..."
. .\venv\Scripts\Activate

# Verifica e installa le dipendenze da requirements.txt
$requirementsPath = "requirements.txt"
if (-Not (Test-Path $requirementsPath)) {
    Write-Host "❌ Errore: Il file requirements.txt non esiste! Esco..."
    Exit 1
}

$deps = Get-Content $requirementsPath | Where-Object { -Not ($_ -match "^#") } | ForEach-Object { ($_ -split '==')[0].Trim() } | Where-Object { $_ -ne "" }
$installedDeps = python.exe -m pip list --format=freeze | ForEach-Object { ($_ -split '==')[0].Trim() }
Write-Host "Dipendenze richieste"
Write-Host "$deps"
Write-Host "Controllo se sono tutte presenti, in caso provvederò ad installarle"
foreach ($dep in $deps) {
    if ($installedDeps -notcontains $dep) {
        Write-Host "⚠️ $dep non è installato correttamente. Lo installo..."
        python.exe -m pip install $dep
        if ($LASTEXITCODE -ne 0) {
            Write-Host "❌ Errore critico: impossibile installare $dep! Esco..."
            Exit 1
        }
    }else{
        "✅ $dep correttamente installata"
    }
}

Write-Host "📜 Salvando la lista dei pacchetti installati..."
python.exe -m pip freeze | Out-File "installed_packages.txt"
Write-Host "✅ Lista pacchetti salvata in installed_packages.txt"
# get-systeminfo.ps1

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
Write-Host "🚀 Avvio dell'app ..."
python main.py

deactivate