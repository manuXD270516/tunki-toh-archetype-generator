#Requires -Version 5.1
<#
.SYNOPSIS
    Tunki TOH - Java Version Switcher
    Cambia entre versiones de Java instaladas via Scoop.

.DESCRIPTION
    Equivalente a 'jenv' para Windows. Usa 'scoop reset' para cambiar
    la version activa de Java en el PATH del sistema.

    Versiones soportadas: 8, 11, 17, 21, 25
    Default del proyecto:  Java 21 - Eclipse Temurin

.PARAMETER Version
    Version de Java a activar (8, 11, 17, 21, 25)

.PARAMETER List
    Muestra todas las versiones de Java instaladas

.PARAMETER Install
    Instala una version de Java si no existe y la activa

.PARAMETER Current
    Muestra la version de Java activa

.EXAMPLE
    .\switch-java.ps1 -List              # Ver versiones instaladas
    .\switch-java.ps1 -Current           # Ver version activa
    .\switch-java.ps1 -Version 21        # Cambiar a Java 21
    .\switch-java.ps1 -Version 17        # Cambiar a Java 17
    .\switch-java.ps1 -Install 17        # Instalar + activar Java 17
    .\switch-java.ps1 21                 # Shorthand: cambiar a Java 21

.NOTES
    Proyecto: Tunki TOH v3.4
    Requiere: Scoop con bucket 'java' registrado
#>

param(
    [Parameter(Position = 0)]
    [ValidateSet(8, 11, 17, 21, 25)]
    [int]$Version,

    [switch]$List,

    [ValidateSet(8, 11, 17, 21, 25)]
    [int]$Install,

    [switch]$Current
)

# ============================================================================
# CONFIGURATION
# ============================================================================
$JAVA_MAP = [ordered]@{
    8  = @{ Package = "temurin8-jdk";  Vendor = "Eclipse Temurin";  LTS = $true;  ProjectDefault = $false }
    11 = @{ Package = "temurin11-jdk"; Vendor = "Eclipse Temurin";  LTS = $true;  ProjectDefault = $false }
    17 = @{ Package = "temurin17-jdk"; Vendor = "Eclipse Temurin";  LTS = $true;  ProjectDefault = $false }
    21 = @{ Package = "temurin21-jdk"; Vendor = "Eclipse Temurin";  LTS = $true;  ProjectDefault = $true  }
    25 = @{ Package = "openjdk";       Vendor = "OpenJDK (latest)"; LTS = $false; ProjectDefault = $false }
}

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================
function Write-JavaHeader {
    Write-Host ""
    Write-Host "  Tunki TOH - Java Version Switcher" -ForegroundColor Cyan
    Write-Host "  =================================" -ForegroundColor Cyan
    Write-Host ""
}

function Get-InstalledJavaVersions {
    $installed = @()
    foreach ($entry in $JAVA_MAP.GetEnumerator()) {
        $ver = $entry.Key
        $pkg = $entry.Value.Package
        $found = scoop list $pkg 2>$null | Select-String $pkg
        if ($found) {
            $installed += $ver
        }
    }
    return $installed
}

function Get-ActiveJavaVersion {
    try {
        $output = & java -version 2>&1 | Select-Object -First 1
        $dq = [char]34
        $verPattern = $dq + '(\d+)'
        if ($output -match $verPattern) {
            $major = [int]$Matches[1]
            # Java 8 reports as "1.8.x"
            if ($major -eq 1) {
                $ver8Pattern = $dq + '1\.(\d+)'
                if ($output -match $ver8Pattern) { $major = [int]$Matches[1] }
            }
            $fullStr = $output.ToString().Trim($dq)
            return @{ Major = $major; Full = $fullStr }
        }
    }
    catch {
        return $null
    }
    return $null
}

function Show-JavaList {
    Write-JavaHeader

    $activeJava = Get-ActiveJavaVersion
    $activeMajor = if ($activeJava) { $activeJava.Major } else { 0 }
    $installed = Get-InstalledJavaVersions

    Write-Host "  Ver   Vendor              LTS    Estado         Proyecto" -ForegroundColor Gray
    Write-Host "  ----  ------------------  -----  -------------  --------" -ForegroundColor Gray

    foreach ($entry in $JAVA_MAP.GetEnumerator()) {
        $ver = $entry.Key
        $info = $entry.Value
        $isInstalled = $installed -contains $ver
        $isActive = ($activeMajor -eq $ver)

        # Version column
        $verStr = "  $($ver.ToString().PadRight(4))"

        # Vendor column
        $vendorStr = $info.Vendor.PadRight(18)

        # LTS column
        $ltsStr = if ($info.LTS) { "LTS  " } else { "     " }

        # Status column
        if ($isActive) {
            $statusStr = '>>> ACTIVE   '
            $statusColor = "Green"
        }
        elseif ($isInstalled) {
            $statusStr = "    installed"
            $statusColor = "White"
        }
        else {
            $statusStr = "    -        "
            $statusColor = "DarkGray"
        }

        # Project default column
        $defaultStr = if ($info.ProjectDefault) { ' << default' } else { '' }

        Write-Host $verStr -NoNewline -ForegroundColor $statusColor
        Write-Host "  $vendorStr" -NoNewline -ForegroundColor $statusColor
        Write-Host "  $ltsStr" -NoNewline -ForegroundColor $(if ($info.LTS) { "Yellow" } else { "DarkGray" })
        Write-Host "  $statusStr" -NoNewline -ForegroundColor $statusColor
        Write-Host $defaultStr -ForegroundColor Magenta
    }

    Write-Host ""
    Write-Host "  Uso:" -ForegroundColor Gray
    Write-Host "    .\switch-java.ps1 21          # Cambiar a Java 21" -ForegroundColor Gray
    Write-Host "    .\switch-java.ps1 -Install 17 # Instalar + activar Java 17" -ForegroundColor Gray
    Write-Host ""
}

function Show-CurrentJava {
    Write-JavaHeader

    $activeJava = Get-ActiveJavaVersion
    if ($activeJava) {
        Write-Host "  Version activa: Java $($activeJava.Major)" -ForegroundColor Green
        Write-Host "  Detalle:        $($activeJava.Full)" -ForegroundColor Gray

        $javaHome = $env:JAVA_HOME
        if ($javaHome) {
            Write-Host "  JAVA_HOME:      $javaHome" -ForegroundColor Gray
        }
    }
    else {
        Write-Host "  [ERROR] Java no encontrado en PATH" -ForegroundColor Red
        Write-Host "  Ejecuta: .\setup-dev-env.ps1" -ForegroundColor Yellow
    }
    Write-Host ""
}

function Switch-JavaVersion {
    param([int]$TargetVersion)

    $info = $JAVA_MAP[$TargetVersion]
    if (-not $info) {
        Write-Host "  [ERROR] Version $TargetVersion no soportada" -ForegroundColor Red
        return
    }

    $pkg = $info.Package
    $installed = Get-InstalledJavaVersions

    if ($installed -notcontains $TargetVersion) {
        Write-Host "  [ERROR] Java $TargetVersion no esta instalado" -ForegroundColor Red
        Write-Host "  Ejecuta: .\switch-java.ps1 -Install $TargetVersion" -ForegroundColor Yellow
        return
    }

    $activeJava = Get-ActiveJavaVersion
    if ($activeJava -and $activeJava.Major -eq $TargetVersion) {
        Write-Host "  [OK] Java $TargetVersion ya esta activo" -ForegroundColor Green
        Write-Host "  $($activeJava.Full)" -ForegroundColor Gray
        return
    }

    Write-Host "  Cambiando a Java $TargetVersion ($($info.Vendor))..." -ForegroundColor Yellow

    # Reset all Java packages first, then activate target
    foreach ($entry in $JAVA_MAP.GetEnumerator()) {
        $otherPkg = $entry.Value.Package
        $otherInstalled = scoop list $otherPkg 2>$null | Select-String $otherPkg
        if ($otherInstalled -and $otherPkg -ne $pkg) {
            scoop reset $otherPkg 2>&1 | Out-Null
        }
    }

    scoop reset $pkg 2>&1 | Out-Null

    # Verify
    $newJava = Get-ActiveJavaVersion
    if ($newJava -and $newJava.Major -eq $TargetVersion) {
        Write-Host "  [OK] " -ForegroundColor Green -NoNewline
        Write-Host "Java $TargetVersion activado exitosamente"
        Write-Host "  $($newJava.Full)" -ForegroundColor Gray

        if (-not $info.ProjectDefault) {
            Write-Host ""
            Write-Host "  [WARN] El proyecto Tunki TOH usa Java 21 como default" -ForegroundColor Magenta
            Write-Host "  Para volver: .\switch-java.ps1 21" -ForegroundColor Gray
        }
    }
    else {
        Write-Host "  [ERROR] No se pudo activar Java $TargetVersion" -ForegroundColor Red
    }
    Write-Host ""
}

function Install-JavaVersion {
    param([int]$TargetVersion)

    $info = $JAVA_MAP[$TargetVersion]
    if (-not $info) {
        Write-Host "  [ERROR] Version $TargetVersion no soportada" -ForegroundColor Red
        return
    }

    $pkg = $info.Package
    $installed = Get-InstalledJavaVersions

    if ($installed -contains $TargetVersion) {
        Write-Host "  Java $TargetVersion ya esta instalado, activando..." -ForegroundColor Yellow
    }
    else {
        Write-Host "  Instalando Java $TargetVersion ($($info.Vendor))..." -ForegroundColor Yellow
        try {
            scoop install $pkg 2>&1 | Out-Null
            Write-Host "  [OK] Java $TargetVersion instalado" -ForegroundColor Green
        }
        catch {
            Write-Host "  [ERROR] Fallo al instalar: $_" -ForegroundColor Red
            return
        }
    }

    Switch-JavaVersion -TargetVersion $TargetVersion
}

# ============================================================================
# MAIN - Route to action
# ============================================================================
if ($List) {
    Show-JavaList
}
elseif ($Current) {
    Show-CurrentJava
}
elseif ($Install -gt 0) {
    Write-JavaHeader
    Install-JavaVersion -TargetVersion $Install
}
elseif ($Version -gt 0) {
    Write-JavaHeader
    Switch-JavaVersion -TargetVersion $Version
}
else {
    # No params - show list as default
    Show-JavaList
}
