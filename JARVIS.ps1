# Force the script to run out of its exact current relative directory, bypass empty variables
if ($PSScriptRoot) {
    Set-Location -Path $PSScriptRoot
} else {
    $ScriptDir = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
    if ($ScriptDir) { Set-Location -Path $ScriptDir }
}

$Host.UI.RawUI.WindowTitle = "J.A.R.V.I.S. - Llamafile Launcher"
Clear-Host

# Completely isolated literal string block to shield art symbols from parsing engines
Write-Output @'
==================================================================================
 ::::::::   :::::::: :::::::::::       ::::::::::: ::::::::  :::::::::: :::::::::
 :+:    :+: :+:    :+:    :+:               :+:    :+:    :+: :+:        :+:    :+:
 +:+        +:+    +:+    +:+               +:+    +:+    +:+ +:+        +:+    +:+
 :#:        +#+    +:+    +#+               +#+    +#+    +:+ +#++:++#   +#+    +1
 +#+   +#+# +#+    +#+    +#+               +#+    +#+    +#+ +#+        +#+    +#+
 #+#    #+# #+#    #+#    #+#           #+# #+#    #+#    #+# #+#        #+#    #+#
  ########   ########     ###            #####      ########  ########## #########
==================================================================================
                         J.A.R.V.I.S. - Llamafile Launcher
==================================================================================
'@

Write-Output " Scanning host hardware specs..."

# 1. Native Hardware Scanning with Safe Fallbacks
$RamGB = 16
try {
    $OSData = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
    if ($OSData) { $RamGB = [Math]::Round($OSData.TotalVisibleMemorySize / 1024 / 1024) }
} catch { $RamGB = 16 }

$CpuName = "Generic Intel/AMD Processor"
try {
    $CPUData = Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue
    if ($CPUData) { $CpuName = $CPUData.Name.Trim() }
} catch { $CpuName = "Generic Intel/AMD Processor" }

# Detect true physical cores for precise thread allocation (-t)
$CpuCores = 4
try {
    if ($CPUData) { $CpuCores = $CPUData.NumberOfCores }
} catch { $CpuCores = 4 }
if (-not $CpuCores -or $CpuCores -le 0) { $CpuCores = 4 }

$GpuName = "Integrated Graphics Engine"
$GpuVramGB = 0
try {
    $Gpu = Get-CimInstance Win32_VideoController | Select-Object -First 1 -ErrorAction SilentlyContinue
    if ($Gpu) { 
        $GpuName = $Gpu.Name 
        $RawVRAM = $Gpu.AdapterRAM
        if ($RawVRAM -and $RawVRAM -gt 0) {
            $GpuVramGB = [Math]::Round($RawVRAM / 1GB)
        } elseif ($RawVRAM -lt 0) {
            $GpuVramGB = [Math]::Round(([uint32]$RawVRAM) / 1GB)
        }
    }
} catch {
    $GpuName = "Integrated Graphics Engine"
    $GpuVramGB = 0
}

Write-Output "     -> System RAM:     $RamGB GB"
Write-Output "     -> CPU:            $CpuName ($CpuCores Physical Cores)"
Write-Output "     -> GPU MODEL/VRAM: $GpuName ($GpuVramGB GB VRAM)"
Write-Output ""

# 2. Dynamic Model Scanning via Relative Working Paths
$ModelDir = ".\model"
if (-not (Test-Path $ModelDir)) { New-Item -ItemType Directory -Path $ModelDir -Force | Out-Null }
$GgufFiles = Get-ChildItem -Path $ModelDir -Filter "*.gguf" -ErrorAction SilentlyContinue

# 3. Error Page if Folder is Empty
if (-not $GgufFiles -or $GgufFiles.Count -eq 0) {
    Write-Host "[ERROR] NO AI MODEL DETECTED" -ForegroundColor Red
    Write-Output "JARVIS needs a .gguf model file inside the /model/ folder to work."
    Write-Output ""
    Write-Output "1. Download a standalone GGUF model from huggingface.co"
    Write-Output "2. Copy the file directly inside: .\model\"
    Write-Output "--------------------------------------------------------------"
    Write-Output ""
    Read-Host "Press [ENTER] to exit, then rerun JARVIS.ps1 once the file is copied"
    Exit
}

# 4. Generate Recommendations Matrix & Core Dynamic Computations
$ModelList = @()
$Index = 1

foreach ($File in $GgufFiles) {
    $SizeGB = [Math]::Ceiling($File.Length / 1GB)
    if ($SizeGB -eq 0) { $SizeGB = 1 }
    
    $ReqVram = ($SizeGB * 12) / 10
    $MinSafeRam = $SizeGB + 4
    
    # Base Recommendation Flag
    if ($GpuVramGB -gt 0 -and $GpuVramGB -ge $ReqVram) {
        $RecFlag = "[RECOMMENDED (Full GPU Acceleration)]"
        $Color = "Green"
    } elseif ($GpuVramGB -gt 0 -and $GpuVramGB -lt $ReqVram) {
        $RecFlag = "[RECOMMENDED (GPU Accelerated Split)]"
        $Color = "Green"
    } elseif ($RamGB -ge $MinSafeRam) {
        $RecFlag = "[RECOMMENDED (CPU/System RAM)]"
        $Color = "Cyan"
    } else {
        $RecFlag = "[WARNING: HEAVY RESOURCE RUNTIME (Slow/Low RAM)]"
        $Color = "Red"
    }
    
    # --- SMART HARDWARE ADAPTIVE PROFILE ENGINE ---
    # Extract Parameter Size correctly from file name characters safely utilizing array indexing
    $ParamBillion = 0
    if ($File.Name -match '(\d+)[bB]') {
        $ParamBillion = [int]$Matches[1]
    } else {
        # Fallback approximation based on file size if text match is missing
        $ParamBillion = [Math]::Round($SizeGB * 1.5)
    }

    $NglLayers = 0
    $TargetThreads = $CpuCores
    $OptimizationProfile = ""
    $ProfileColor = "Magenta"

    # Scenario A: Device has Dedicated Video memory
    if ($GpuVramGB -gt 0) {
        # 1. MAX PERFORMANCE MODE (High-End Scenario)
        if ($GpuVramGB -ge ($ReqVram + 2)) {
            $NglLayers = 99  
            $OptimizationProfile = "MAX PERFORMANCE MODE (100% GPU VRAM Lockout)"
            $ProfileColor = "Green"
        } 
        # 2. SEMI-PERFORMANCE MODE (Mid-Range Balancing Scenario)
        elseif ($GpuVramGB -ge $ReqVram) {
            $SafeVramCapacity = [Math]::Floor($GpuVramGB * 0.9)
            $PercentFit = $SafeVramCapacity / $ReqVram
            $NglLayers = [Math]::Floor(35 * $PercentFit)
            if ($NglLayers -gt 35) { $NglLayers = 32 }
            if ($NglLayers -lt 1) { $NglLayers = 16 }
            $OptimizationProfile = "SEMI-PERFORMANCE MODE (90% Safe VRAM Cap Enabled: $NglLayers Layers)"
            $ProfileColor = "Yellow"
        } 
        # 3. HARDWARE-FRIENDLY MODE (Heavy Split Scenario)
        else {
            $SafeVramCapacity = [Math]::Floor($GpuVramGB * 0.8)
            if ($SafeVramCapacity -gt 0) {
                $NglLayers = [Math]::Floor(12 * ($GpuVramGB / $ReqVram))
                if ($NglLayers -lt 1) { $NglLayers = 6 }
                $OptimizationProfile = "HARDWARE-FRIENDLY MODE (Heavy Parameters Split: $NglLayers GPU Layers)"
                $ProfileColor = "Cyan"
            } else {
                $NglLayers = 0
                $OptimizationProfile = "HARDWARE-FRIENDLY CPU MODE (VRAM Overrun Protection engaged)"
                $ProfileColor = "Red"
            }
        }
    } 
    # Scenario B: Device is CPU Only
    else {
        $NglLayers = 0
        if ($RamGB -ge $MinSafeRam) {
            $OptimizationProfile = "STANDARD CPU VECTOR ENGINE"
            $ProfileColor = "Cyan"
        } else {
            $OptimizationProfile = "HARDWARE-FRIENDLY MODE (Low-Memory Warning Paging)"
            $ProfileColor = "Red"
        }
    }

    $ModelList += [PSCustomObject]@{
        Number        = $Index
        Name          = $File.Name
        Flag          = $RecFlag
        Color         = $Color
        NglLayers     = $NglLayers
        Threads       = $TargetThreads
        ProfileNotes  = $OptimizationProfile
        ProfileColor  = $ProfileColor
        ParamSize     = $ParamBillion
    }
    $Index++
}

# 5. Model Selection Menu UI
Write-Output "MODELS DETECTED:"
foreach ($Item in $ModelList) {
    Write-Host "  $($Item.Number). $($Item.Name) - " -NoNewline
    Write-Host $Item.Flag -ForegroundColor $Item.Color
}
Write-Output "--------------------------------------------------------------"
Write-Output ""

$ChosenModelObj = $null
while ($true) {
    $Choice = Read-Host "CHOOSE YOUR AI MODEL (Enter Number)"
    $Selection = $ModelList | Where-Object { $_.Number -eq $Choice }
    if ($Selection) {
        $ChosenModelObj = $Selection
        $ChosenModel = $Selection.Name
        Write-Output ""
        Write-Output "[JARVIS] Selected model: $ChosenModel ($($ChosenModelObj.ParamSize)B Parameter Class)"
        Write-Host "[JARVIS] Active Adaptive Profile: " -NoNewline
        Write-Host $ChosenModelObj.ProfileNotes -ForegroundColor $ChosenModelObj.ProfileColor
        Write-Output "         -> Dynamic Thread Allocation: -t $($ChosenModelObj.Threads)"
        Write-Output "         -> Safety VRAM Layer Bounds:  -ngl $($ChosenModelObj.NglLayers)"
        break
    }
    Write-Host "Invalid selection. Please choose a valid number from the list." -ForegroundColor Yellow
}

# 6. Automatic Executable Management & Launch
Write-Output "[JARVIS] Initializing local LLM environment..."
if (Test-Path ".\bin\llamafile") {
    Write-Output "[JARVIS] Found 'llamafile'. Renaming to 'llamafile.exe'..."
    Rename-Item -Path ".\bin\llamafile" -NewName "llamafile.exe"
}

# Airgapped Native Loopback Port Allocator Engine
$Port = 8080
$LoopbackIP = [System.Net.IPAddress]::Loopback

while ($true) {
    $Socket = New-Object System.Net.Sockets.TcpListener($LoopbackIP, $Port)
    try {
        $Socket.Start()
        $Socket.Stop()
        break
    } catch {
        Write-Host "[JARVIS] Port $Port is occupied. Diverting system allocation..." -ForegroundColor Yellow
        $Port++
    } finally {
        if ($Socket) { $Socket.Stop() }
    }
}

Write-Output "[JARVIS] Launching $ChosenModel on http://127.0.0.1:$Port..."
Write-Output "[JARVIS] Please keep this window open while chatting."
Write-Output "--------------------------------------------------"

# Executing Llamafile with fully resolved adaptive parameters and compatibility flags
if ($ChosenModelObj.NglLayers -gt 0) {
    .\bin\llamafile.exe -m ".\model\$ChosenModel" `
        --host "127.0.0.1" --port $Port `
        -t $($ChosenModelObj.Threads) `
        -ngl $($ChosenModelObj.NglLayers) `
        --no-warmup `
        --no-mmap `
        --server
} else {
    .\bin\llamafile.exe -m ".\model\$ChosenModel" `
        --host "127.0.0.1" --port $Port `
        -t $($ChosenModelObj.Threads) `
        --no-warmup `
        --no-mmap `
        --server
}