#Requires -Version 5.1
<#
.SYNOPSIS
    Tunki TOH - Developer Environment Setup Script
    Instala Java 21 (Temurin), Maven 3.9.x y herramientas necesarias via Scoop.

.DESCRIPTION
    Este script automatiza la configuracion completa del entorno de desarrollo
    para los microservicios del ecosistema Tunki TOH v3.4.

    Herramientas instaladas:
      - Scoop (package manager para Windows)
      - Java 21 LTS (Eclipse Temurin) - default
      - Apache Maven 3.9.x
      - Git (si no existe)
      - MongoDB Shell (mongosh)
      - Redis CLI

.PARAMETER JavaVersion
    Version de Java a instalar como default. Default: 21

.PARAMETER SkipOptional
    Omite herramientas opcionales (mongosh, redis-cli). Default: false

.PARAMETER DryRun
    Muestra que se instalaria sin ejecutar. Default: false

.EXAMPLE
    .\setup-dev-env.ps1
    .\setup-dev-env.ps1 -JavaVersion 21
    .\setup-dev-env.ps1 -SkipOptional
    .\setup-dev-env.ps1 -DryRun

.NOTES
    Proyecto: Tunki TOH v3.4 - Ecosistema de Microservicios SIP
    Equipo:   Novacomp / SomosOH / Financiera OH
    Fecha:    2026-04-06
#>

param(
    [ValidateSet(8, 11, 17, 21, 25)]
    [int]$JavaVersion = 21,

    [switch]$SkipOptional,

    [switch]$DryRun
)

# ============================================================================
# CONFIGURATION
# ============================================================================
$ErrorActionPreference = "Stop"

$JAVA_PACKAGES = @{
    8  = "temurin8-jdk"
    11 = "temurin11-jdk"
    17 = "temurin17-jdk"
    21 = "temurin21-jdk"
    25 = "openjdk"
}

$REQUIRED_PACKAGES = @(
    @{ Name = "maven";  Display = "Apache Maven 3.9.x";    Bucket = "main" }
)

$OPTIONAL_PACKAGES = @(
    @{ Name = "mongosh";      Display = "MongoDB Shell";       Bucket = "main" }
    @{ Name = "redis";        Display = "Redis CLI";            Bucket = "main" }
    @{ Name = "docker";       Display = "Docker CLI";           Bucket = "main" }
)

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================
function Write-Header {
    param([string]$Text)
    $line = "=" * 60
    Write-Host ""
    Write-Host $line -ForegroundColor Cyan
    Write-Host "  $Text" -ForegroundColor Cyan
    Write-Host $line -ForegroundColor Cyan
    Write-Host ""
}

function Write-Step {
    param([string]$Step, [string]$Text)
    Write-Host "  [$Step] " -ForegroundColor Yellow -NoNewline
    Write-Host $Text
}

function Write-Success {
    param([string]$Text)
    Write-Host "  [OK] " -ForegroundColor Green -NoNewline
    Write-Host $Text
}

function Write-Skip {
    param([string]$Text)
    Write-Host "  [SKIP] " -ForegroundColor DarkGray -NoNewline
    Write-Host $Text -ForegroundColor DarkGray
}

function Write-Warn {
    param([string]$Text)
    Write-Host "  [WARN] " -ForegroundColor Magenta -NoNewline
    Write-Host $Text -ForegroundColor Magenta
}

function Test-CommandExists {
    param([string]$Command)
    return [bool](Get-Command $Command -ErrorAction SilentlyContinue)
}

function Get-ToolVersion {
    param([string]$Command, [string]$Flag = "--version")
    $prevEAP = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $result = & $Command $Flag 2>&1 | ForEach-Object { $_.ToString() } | Select-Object -First 1
        return $result
    }
    catch { return "unknown" }
    finally { $ErrorActionPreference = $prevEAP }
}

function Install-ScoopPackage {
    param(
        [string]$PackageName,
        [string]$DisplayName,
        [string]$Bucket = "main"
    )

    if (scoop list $PackageName 2>$null | Select-String $PackageName) {
        Write-Skip "$DisplayName ya instalado"
        return $true
    }

    if ($DryRun) {
        Write-Step "DRY" "Instalaria: scoop install $PackageName"
        return $true
    }

    Write-Step "..." "Instalando $DisplayName..."
    try {
        $output = scoop install $PackageName 2>&1
        $outputStr = $output | Out-String
        if ($outputStr -match "ERROR|Couldn't find") {
            Write-Warn "Error instalando $DisplayName : $outputStr"
            return $false
        }
        Write-Success "$DisplayName instalado correctamente"
        return $true
    }
    catch {
        Write-Warn "Error instalando $DisplayName : $_"
        return $false
    }
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================
Write-Header "Tunki TOH v3.4 - Developer Environment Setup"

Write-Host "  Configuracion:" -ForegroundColor White
Write-Host "    Java Version:   $JavaVersion - Eclipse Temurin" -ForegroundColor Gray
Write-Host "    Skip Optional:  $SkipOptional" -ForegroundColor Gray
Write-Host "    Dry Run:        $DryRun" -ForegroundColor Gray
Write-Host ""

# --- STEP 1: Scoop -----------------------------------------------------------
Write-Header "Paso 1/5 - Package Manager (Scoop)"

if (Test-CommandExists "scoop") {
    Write-Skip "Scoop ya instalado"
    if (-not $DryRun) {
        Write-Step "..." "Actualizando Scoop..."
        scoop update 2>&1 | Out-Null
        Write-Success "Scoop actualizado"
    }
}
else {
    if ($DryRun) {
        Write-Step "DRY" "Instalaria Scoop"
    }
    else {
        Write-Step "..." "Instalando Scoop..."
        try {
            Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force -ErrorAction SilentlyContinue
        } catch {
            # GPO may override - that's OK if current policy already allows scripts
        }
        Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
        Write-Success "Scoop instalado"
    }
}

# --- STEP 2: Scoop Buckets ---------------------------------------------------
Write-Header "Paso 2/5 - Scoop Buckets"

$requiredBuckets = @("java", "extras")
foreach ($bucket in $requiredBuckets) {
    $existingBuckets = scoop bucket list 2>$null | Select-String $bucket
    if ($existingBuckets) {
        Write-Skip "Bucket '$bucket' ya registrado"
    }
    else {
        if ($DryRun) {
            Write-Step "DRY" "Agregaria bucket: $bucket"
        }
        else {
            Write-Step "..." "Agregando bucket '$bucket'..."
            scoop bucket add $bucket 2>&1 | Out-Null
            Write-Success "Bucket '$bucket' agregado"
        }
    }
}

# --- STEP 3: Java -------------------------------------------------------------
Write-Header "Paso 3/5 - Java $JavaVersion (Eclipse Temurin)"

$javaPackage = $JAVA_PACKAGES[$JavaVersion]
if (-not $javaPackage) {
    Write-Warn "Version Java $JavaVersion no soportada. Usando 21."
    $JavaVersion = 21
    $javaPackage = "temurin21-jdk"
}

$javaInstalled = Install-ScoopPackage -PackageName $javaPackage `
    -DisplayName "Java $JavaVersion (Eclipse Temurin)" -Bucket "java"

if ($javaInstalled -and -not $DryRun) {
    # Asegurar que esta version es la activa
    Write-Step "..." "Activando Java $JavaVersion como default..."
    scoop reset $javaPackage 2>&1 | Out-Null
    Write-Success "Java $JavaVersion activado como default"

    # Verificar
    $javaVer = Get-ToolVersion "java" "-version"
    Write-Success "Verificado: $javaVer"
}

# --- STEP 4: Maven + Required Tools ------------------------------------------
Write-Header "Paso 4/5 - Maven y Herramientas Requeridas"

foreach ($pkg in $REQUIRED_PACKAGES) {
    Install-ScoopPackage -PackageName $pkg.Name -DisplayName $pkg.Display -Bucket $pkg.Bucket
}

if (-not $DryRun -and (Test-CommandExists "mvn")) {
    $mvnVer = Get-ToolVersion "mvn" "-version"
    Write-Success "Verificado: $mvnVer"
}

# --- STEP 5: Optional Tools --------------------------------------------------
Write-Header "Paso 5/5 - Herramientas Opcionales"

if ($SkipOptional) {
    Write-Skip "Herramientas opcionales omitidas (-SkipOptional)"
}
else {
    foreach ($pkg in $OPTIONAL_PACKAGES) {
        Install-ScoopPackage -PackageName $pkg.Name -DisplayName $pkg.Display -Bucket $pkg.Bucket
    }
}

# ============================================================================
# SUMMARY
# ============================================================================
Write-Header "Resumen de Instalacion"

$tools = @(
    @{ Name = "java";    Label = "Java $JavaVersion" }
    @{ Name = "mvn";     Label = "Maven" }
    @{ Name = "git";     Label = "Git" }
    @{ Name = "mongosh"; Label = "MongoDB Shell" }
    @{ Name = "docker";  Label = "Docker CLI" }
)

$maxLabel = ($tools | ForEach-Object { $_.Label.Length } | Measure-Object -Maximum).Maximum

foreach ($tool in $tools) {
    $label = $tool.Label.PadRight($maxLabel + 2)
    if (Test-CommandExists $tool.Name) {
        $version = ""
        switch ($tool.Name) {
            "java"    { $version = Get-ToolVersion "java" "-version" }
            "mvn"     { $version = Get-ToolVersion "mvn" "-version" }
            "git"     { $version = Get-ToolVersion "git" "--version" }
            "mongosh" { $version = "installed" }
            "docker"  { $version = (& docker --version 2>&1) }
        }
        Write-Host "  $label" -NoNewline
        Write-Host "[OK]" -ForegroundColor Green -NoNewline
        Write-Host "  $version" -ForegroundColor DarkGray
    }
    else {
        Write-Host "  $label" -NoNewline
        Write-Host "[NOT FOUND]" -ForegroundColor Red
    }
}

# --- Maven settings.xml hint -------------------------------------------------
$m2Dir = Join-Path $env:USERPROFILE ".m2"
$settingsFile = Join-Path $m2Dir "settings.xml"

Write-Host ""
if (-not (Test-Path $settingsFile)) {
    Write-Warn "No existe ~/.m2/settings.xml"
    Write-Host "    Ejecuta " -NoNewline -ForegroundColor Gray
    Write-Host ".\configure-maven-feed.ps1" -ForegroundColor Yellow -NoNewline
    Write-Host " para configurar Azure Artifacts" -ForegroundColor Gray
}
else {
    Write-Success "settings.xml encontrado en $settingsFile"
}

Write-Host ""
Write-Host "  Setup completado. Ejecuta " -NoNewline
Write-Host ".\validate-env.ps1" -ForegroundColor Yellow -NoNewline
Write-Host " para verificar todo."
Write-Host ""
