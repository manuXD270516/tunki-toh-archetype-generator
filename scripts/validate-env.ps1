#Requires -Version 5.1
<#
.SYNOPSIS
    Tunki TOH - Environment Validation Script
    Verifica que todas las herramientas y configuraciones esten correctas.

.DESCRIPTION
    Ejecuta una bateria de checks para validar el entorno de desarrollo:
      1. Java 21 instalado y activo
      2. Maven 3.9+ instalado
      3. Git disponible
      4. settings.xml configurado con Azure Artifacts feed
      5. sip-toh-platform compilable
      6. Herramientas opcionales (mongosh, docker)

    Devuelve exit code 0 si todo OK, 1 si hay errores criticos.

.PARAMETER Verbose
    Muestra detalle adicional de cada check

.PARAMETER Fix
    Intenta corregir problemas encontrados automaticamente

.EXAMPLE
    .\validate-env.ps1
    .\validate-env.ps1 -Verbose
    .\validate-env.ps1 -Fix

.NOTES
    Proyecto: Tunki TOH v3.4
#>

param(
    [switch]$Fix
)

# ============================================================================
# CONFIGURATION
# ============================================================================
$ErrorActionPreference = "Continue"
$TOTAL_CHECKS = 0
$PASSED_CHECKS = 0
$FAILED_CHECKS = 0
$WARN_CHECKS = 0

$FEED_ID = "BackendArtifactsInDigitalpePro@Local"
$SETTINGS_FILE = Join-Path $env:USERPROFILE ".m2\settings.xml"

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================
function Write-Header {
    param([string]$Text)
    $line = "-" * 60
    Write-Host ""
    Write-Host "  $Text" -ForegroundColor Cyan
    Write-Host "  $line" -ForegroundColor DarkGray
}

function Write-Check {
    param(
        [string]$Name,
        [string]$Status,    # PASS, FAIL, WARN, SKIP
        [string]$Detail = ""
    )

    $script:TOTAL_CHECKS++

    $icon = switch ($Status) {
        "PASS" { $script:PASSED_CHECKS++; "[PASS]" }
        "FAIL" { $script:FAILED_CHECKS++; "[FAIL]" }
        "WARN" { $script:WARN_CHECKS++;   "[WARN]" }
        "SKIP" { "[SKIP]" }
    }

    $color = switch ($Status) {
        "PASS" { "Green" }
        "FAIL" { "Red" }
        "WARN" { "Magenta" }
        "SKIP" { "DarkGray" }
    }

    $nameStr = $Name.PadRight(35)
    Write-Host "  $icon " -ForegroundColor $color -NoNewline
    Write-Host $nameStr -NoNewline
    if ($Detail) {
        Write-Host " $Detail" -ForegroundColor DarkGray
    }
    else {
        Write-Host ""
    }
}

function Test-CommandExists {
    param([string]$Command)
    return [bool](Get-Command $Command -ErrorAction SilentlyContinue)
}

function Get-CommandVersion {
    param([string]$Command, [string]$VersionFlag = "--version")
    try {
        $output = & $Command $VersionFlag 2>&1 | ForEach-Object { $_.ToString() } | Select-Object -First 1
        return $output.ToString().Trim()
    }
    catch {
        return $null
    }
}

# ============================================================================
# CHECKS
# ============================================================================
Write-Host ""
Write-Host "  ============================================================" -ForegroundColor Cyan
Write-Host "  Tunki TOH v3.4 - Environment Validation" -ForegroundColor Cyan
Write-Host "  ============================================================" -ForegroundColor Cyan
Write-Host "  Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host "  User: $env:USERNAME" -ForegroundColor Gray
Write-Host "  Host: $env:COMPUTERNAME" -ForegroundColor Gray

# --- 1. Package Manager ---
Write-Header "1. Package Manager"

if (Test-CommandExists "scoop") {
    Write-Check "Scoop instalado" "PASS"
}
else {
    Write-Check "Scoop instalado" "FAIL" "Ejecutar: setup-dev-env.ps1"
}

# --- 2. Java ---
Write-Header "2. Java Runtime"

if (Test-CommandExists "java") {
    $javaVerStr = Get-CommandVersion "java" "-version"
    if (-not $javaVerStr) { $javaVerStr = "unknown" }

    Write-Check "Java instalado" "PASS" $javaVerStr

    # Check version is 21
    if ($javaVerStr -match '"21\.') {
        Write-Check "Java 21 (project default)" "PASS"
    }
    elseif ($javaVerStr -match '"(\d+)\.') {
        $major = $Matches[1]
        Write-Check "Java 21 (project default)" "WARN" "Activo: Java $major (proyecto requiere 21)"
    }

    # Check JAVA_HOME
    $javaHome = $env:JAVA_HOME
    if ($javaHome -and (Test-Path $javaHome)) {
        Write-Check "JAVA_HOME configurado" "PASS" $javaHome
    }
    else {
        Write-Check "JAVA_HOME configurado" "WARN" "No definido (Scoop lo maneja via PATH)"
    }
}
else {
    Write-Check "Java instalado" "FAIL" "Ejecutar: setup-dev-env.ps1"
    Write-Check "Java 21 (project default)" "FAIL"
    Write-Check "JAVA_HOME configurado" "FAIL"
}

# --- 3. Maven ---
Write-Header "3. Apache Maven"

if (Test-CommandExists "mvn") {
    $mvnVerStr = Get-CommandVersion "mvn" "-version"
    if (-not $mvnVerStr) { $mvnVerStr = "unknown" }

    Write-Check "Maven instalado" "PASS" $mvnVerStr

    # Check version >= 3.9
    if ($mvnVerStr -match 'Maven (\d+)\.(\d+)') {
        $major = [int]$Matches[1]
        $minor = [int]$Matches[2]
        if ($major -ge 3 -and $minor -ge 9) {
            Write-Check "Maven >= 3.9" "PASS"
        }
        else {
            Write-Check "Maven >= 3.9" "WARN" "Version $major.$minor (recomendado 3.9+)"
        }
    }
}
else {
    Write-Check "Maven instalado" "FAIL" "Ejecutar: setup-dev-env.ps1"
    Write-Check "Maven >= 3.9" "FAIL"
}

# --- 4. Git ---
Write-Header "4. Git"

if (Test-CommandExists "git") {
    $gitVer = Get-CommandVersion "git"
    Write-Check "Git instalado" "PASS" $gitVer

    # Check SSH key
    $sshKey = Join-Path $env:USERPROFILE ".ssh\id_rsa"
    $sshKeyEd = Join-Path $env:USERPROFILE ".ssh\id_ed25519"
    if ((Test-Path $sshKey) -or (Test-Path $sshKeyEd)) {
        Write-Check "SSH key configurada" "PASS"
    }
    else {
        Write-Check "SSH key configurada" "WARN" "No encontrada en ~/.ssh/"
    }

    # Check Azure DevOps connectivity
    $sshTest = try { & ssh -T git@ssh.dev.azure.com 2>&1 | ForEach-Object { $_.ToString() } | Select-String "Shell access" } catch { $null }
    if ($sshTest) {
        Write-Check "Azure DevOps SSH conectividad" "PASS"
    }
    else {
        Write-Check "Azure DevOps SSH conectividad" "WARN" "No se pudo verificar"
    }
}
else {
    Write-Check "Git instalado" "FAIL"
}

# --- 5. Maven settings.xml ---
Write-Header "5. Maven Azure Artifacts Feed"

if (Test-Path $SETTINGS_FILE) {
    Write-Check "~/.m2/settings.xml existe" "PASS"

    $content = Get-Content $SETTINGS_FILE -Raw
    if ($content -match [regex]::Escape($FEED_ID)) {
        Write-Check "Feed ID configurado" "PASS" $FEED_ID
    }
    else {
        Write-Check "Feed ID configurado" "FAIL" "Ejecutar: configure-maven-feed.ps1"
    }

    if ($content -match "<password>.{10,}</password>") {
        Write-Check "PAT configurado" "PASS" "(token presente)"
    }
    else {
        Write-Check "PAT configurado" "FAIL" "Ejecutar: configure-maven-feed.ps1"
    }

    if ($content -match "tunki-feed") {
        Write-Check "Profile tunki-feed activo" "PASS"
    }
    else {
        Write-Check "Profile tunki-feed activo" "FAIL"
    }
}
else {
    Write-Check "~/.m2/settings.xml existe" "FAIL" "Ejecutar: configure-maven-feed.ps1"
    Write-Check "Feed ID configurado" "FAIL"
    Write-Check "PAT configurado" "FAIL"
    Write-Check "Profile tunki-feed activo" "FAIL"
}

# --- 6. Optional Tools ---
Write-Header "6. Herramientas Opcionales"

$optionalTools = @(
    @{ Cmd = "mongosh"; Name = "MongoDB Shell (mongosh)" }
    @{ Cmd = "docker";  Name = "Docker" }
    @{ Cmd = "redis-cli"; Name = "Redis CLI" }
    @{ Cmd = "kubectl"; Name = "kubectl" }
)

foreach ($tool in $optionalTools) {
    if (Test-CommandExists $tool.Cmd) {
        $ver = Get-CommandVersion $tool.Cmd
        Write-Check $tool.Name "PASS" $ver
    }
    else {
        Write-Check $tool.Name "SKIP" "No instalado (opcional)"
    }
}

# --- 7. Platform Build Test ---
Write-Header "7. Platform Build Test"

$platformDir = Join-Path $PSScriptRoot ".."
$platformPom = Join-Path $platformDir "pom.xml"

if (Test-Path $platformPom) {
    Write-Check "sip-toh-platform/pom.xml" "PASS"

    if ((Test-CommandExists "java") -and (Test-CommandExists "mvn")) {
        Write-Host "  [....] Ejecutando mvn validate (puede tomar unos segundos)..." -ForegroundColor Yellow
        try {
            Push-Location $platformDir
            $buildOutput = & mvn validate -B -q 2>&1
            $buildExit = $LASTEXITCODE
            Pop-Location

            if ($buildExit -eq 0) {
                Write-Check "mvn validate exitoso" "PASS"
            }
            else {
                Write-Check "mvn validate exitoso" "FAIL" "Exit code: $buildExit"
            }
        }
        catch {
            Pop-Location
            Write-Check "mvn validate exitoso" "WARN" "Error: $_"
        }
    }
    else {
        Write-Check "mvn validate exitoso" "SKIP" "Java o Maven no disponible"
    }
}
else {
    Write-Check "sip-toh-platform/pom.xml" "WARN" "No encontrado en directorio padre"
}

# ============================================================================
# SUMMARY
# ============================================================================
Write-Host ""
Write-Host "  ============================================================" -ForegroundColor Cyan
Write-Host "  RESULTADO" -ForegroundColor Cyan
Write-Host "  ============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Total checks:  $TOTAL_CHECKS" -ForegroundColor White
Write-Host "  Passed:        $PASSED_CHECKS" -ForegroundColor Green
Write-Host "  Warnings:      $WARN_CHECKS" -ForegroundColor Magenta
Write-Host "  Failed:        $FAILED_CHECKS" -ForegroundColor $(if ($FAILED_CHECKS -gt 0) { "Red" } else { "Green" })
Write-Host ""

$percentage = if ($TOTAL_CHECKS -gt 0) { [math]::Round(($PASSED_CHECKS / $TOTAL_CHECKS) * 100) } else { 0 }

if ($FAILED_CHECKS -eq 0) {
    Write-Host "  [$percentage%] Entorno listo para desarrollo Tunki TOH v3.4" -ForegroundColor Green
}
elseif ($FAILED_CHECKS -le 2) {
    Write-Host "  [$percentage%] Entorno casi listo - corrige los items marcados [FAIL]" -ForegroundColor Yellow
}
else {
    Write-Host "  [$percentage%] Entorno incompleto - ejecuta setup-dev-env.ps1 primero" -ForegroundColor Red
}

if ($Fix -and $FAILED_CHECKS -gt 0) {
    Write-Host ""
    Write-Host "  Auto-fix: ejecutando setup-dev-env.ps1..." -ForegroundColor Yellow
    $setupScript = Join-Path $PSScriptRoot "setup-dev-env.ps1"
    if (Test-Path $setupScript) {
        & $setupScript
    }
}

Write-Host ""

exit $(if ($FAILED_CHECKS -gt 0) { 1 } else { 0 })
