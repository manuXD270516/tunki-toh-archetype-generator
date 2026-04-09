#Requires -Version 5.1
<#
.SYNOPSIS
    Tunki TOH - Maven Azure Artifacts Feed Configuration
    Configura ~/.m2/settings.xml para conectar con el feed privado de la org.

.DESCRIPTION
    Genera o actualiza el archivo settings.xml de Maven para que pueda
    resolver dependencias del feed BackendArtifactsInDigitalpePro de Azure DevOps.

    Feed URL: https://pkgs.dev.azure.com/InDigitalpe/_packaging/
              BackendArtifactsInDigitalpePro%40Local/maven/v1

    Requiere un Personal Access Token (PAT) de Azure DevOps con scope:
      Packaging → Read (minimo) | Read & Write (para publicar)

.PARAMETER PAT
    Personal Access Token de Azure DevOps. Si no se proporciona, se solicita interactivamente.

.PARAMETER Force
    Sobreescribe settings.xml existente sin preguntar. Default: false

.PARAMETER Validate
    Solo verifica si la configuracion existente es correcta. Default: false

.EXAMPLE
    .\configure-maven-feed.ps1
    .\configure-maven-feed.ps1 -PAT "your-pat-token-here"
    .\configure-maven-feed.ps1 -Validate
    .\configure-maven-feed.ps1 -Force

.NOTES
    Proyecto: Tunki TOH v3.4
    Feed:     BackendArtifactsInDigitalpePro@Local (Organization scope)
#>

param(
    [string]$PAT,

    [switch]$Force,

    [switch]$Validate
)

# ============================================================================
# CONFIGURATION
# ============================================================================
$ErrorActionPreference = "Stop"

$FEED_ID = "BackendArtifactsInDigitalpePro@Local"
$FEED_URL = "https://pkgs.dev.azure.com/InDigitalpe/_packaging/BackendArtifactsInDigitalpePro%40Local/maven/v1"
$FEED_USERNAME = "InDigitalpe"

$M2_DIR = Join-Path $env:USERPROFILE ".m2"
$SETTINGS_FILE = Join-Path $M2_DIR "settings.xml"
$BACKUP_SUFFIX = ".backup.$(Get-Date -Format 'yyyyMMdd-HHmmss')"

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================
function Write-Header {
    param([string]$Text)
    Write-Host ""
    Write-Host "  $Text" -ForegroundColor Cyan
    Write-Host "  $('=' * $Text.Length)" -ForegroundColor Cyan
    Write-Host ""
}

function Test-SettingsXml {
    if (-not (Test-Path $SETTINGS_FILE)) {
        Write-Host "  [FAIL] settings.xml no existe en $M2_DIR" -ForegroundColor Red
        return $false
    }

    $content = Get-Content $SETTINGS_FILE -Raw

    $checks = @(
        @{ Name = "Server ID";     Pattern = "<id>$([regex]::Escape($FEED_ID))</id>" }
        @{ Name = "Feed URL";      Pattern = [regex]::Escape($FEED_URL) }
        @{ Name = "Username";      Pattern = "<username>$FEED_USERNAME</username>" }
        @{ Name = "PAT (password)"; Pattern = "<password>.+</password>" }
        @{ Name = "Profile";       Pattern = "<id>tunki-feed</id>" }
    )

    $allOk = $true
    foreach ($check in $checks) {
        if ($content -match $check.Pattern) {
            Write-Host "  [OK]   $($check.Name)" -ForegroundColor Green
        }
        else {
            Write-Host "  [FAIL] $($check.Name) - no encontrado" -ForegroundColor Red
            $allOk = $false
        }
    }

    if ($allOk) {
        Write-Host ""
        Write-Host "  settings.xml configurado correctamente" -ForegroundColor Green

        # Test connectivity
        Write-Host ""
        Write-Host "  Probando conectividad con el feed..." -ForegroundColor Yellow
        if (Test-CommandExists "mvn") {
            try {
                $output = & mvn help:effective-settings 2>&1 | Select-String $FEED_ID
                if ($output) {
                    Write-Host "  [OK] Maven reconoce el feed" -ForegroundColor Green
                }
            }
            catch {
                Write-Host "  [WARN] No se pudo verificar con Maven" -ForegroundColor Magenta
            }
        }
    }

    return $allOk
}

function Test-CommandExists {
    param([string]$Command)
    return [bool](Get-Command $Command -ErrorAction SilentlyContinue)
}

function New-SettingsXml {
    param([string]$Token)

    return @"
<?xml version="1.0" encoding="UTF-8"?>
<!--
    Maven Settings - Tunki TOH v3.4
    Feed: BackendArtifactsInDigitalpePro@Local (Azure Artifacts)
    Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

    IMPORTANT: Este archivo contiene un PAT (Personal Access Token).
    NO subir a ningun repositorio. El .gitignore ya lo excluye.
-->
<settings xmlns="http://maven.apache.org/SETTINGS/1.0.0"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.0.0
                              https://maven.apache.org/xsd/settings-1.0.0.xsd">

    <!-- ================================================================= -->
    <!-- SERVERS - Credenciales para Azure Artifacts                       -->
    <!-- ================================================================= -->
    <servers>
        <server>
            <id>$FEED_ID</id>
            <username>$FEED_USERNAME</username>
            <password>$Token</password>
        </server>
    </servers>

    <!-- ================================================================= -->
    <!-- PROFILES - Repositorio Maven del feed privado                     -->
    <!-- ================================================================= -->
    <profiles>
        <profile>
            <id>tunki-feed</id>

            <repositories>
                <repository>
                    <id>$FEED_ID</id>
                    <url>$FEED_URL</url>
                    <releases>
                        <enabled>true</enabled>
                    </releases>
                    <snapshots>
                        <enabled>true</enabled>
                    </snapshots>
                </repository>
            </repositories>

            <pluginRepositories>
                <pluginRepository>
                    <id>$FEED_ID</id>
                    <url>$FEED_URL</url>
                    <releases>
                        <enabled>true</enabled>
                    </releases>
                    <snapshots>
                        <enabled>true</enabled>
                    </snapshots>
                </pluginRepository>
            </pluginRepositories>
        </profile>
    </profiles>

    <!-- ================================================================= -->
    <!-- ACTIVE PROFILES - Activar feed por defecto                        -->
    <!-- ================================================================= -->
    <activeProfiles>
        <activeProfile>tunki-feed</activeProfile>
    </activeProfiles>

</settings>
"@
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================
Write-Header "Tunki TOH - Maven Azure Artifacts Configuration"

# --- Validate mode ---
if ($Validate) {
    Write-Host "  Validando configuracion existente..." -ForegroundColor Yellow
    Write-Host ""
    $result = Test-SettingsXml
    Write-Host ""
    exit $(if ($result) { 0 } else { 1 })
}

# --- Check existing settings.xml ---
if (Test-Path $SETTINGS_FILE) {
    if (-not $Force) {
        Write-Host "  [WARN] Ya existe: $SETTINGS_FILE" -ForegroundColor Magenta
        Write-Host ""
        $response = Read-Host "  Sobreescribir? Se creara backup (s/N)"
        if ($response -notin @("s", "S", "si", "SI", "y", "Y")) {
            Write-Host "  Cancelado." -ForegroundColor Yellow
            exit 0
        }
    }

    # Backup
    $backupFile = "$SETTINGS_FILE$BACKUP_SUFFIX"
    Copy-Item $SETTINGS_FILE $backupFile
    Write-Host "  [OK] Backup creado: $backupFile" -ForegroundColor Green
}

# --- Get PAT ---
if ([string]::IsNullOrWhiteSpace($PAT)) {
    Write-Host "  Se requiere un Personal Access Token (PAT) de Azure DevOps." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Para crear uno:" -ForegroundColor Gray
    Write-Host "    1. Ir a: https://dev.azure.com/InDigitalpe/_usersSettings/tokens" -ForegroundColor Gray
    Write-Host "    2. Click 'New Token'" -ForegroundColor Gray
    Write-Host "    3. Name: tunki-maven-feed" -ForegroundColor Gray
    Write-Host "    4. Scopes > Packaging: Read (o Read & Write)" -ForegroundColor Gray
    Write-Host "    5. Expiration: 90 dias" -ForegroundColor Gray
    Write-Host "    6. Click 'Create' y copiar el token" -ForegroundColor Gray
    Write-Host ""
    $PAT = Read-Host "  Pega tu PAT aqui"

    if ([string]::IsNullOrWhiteSpace($PAT)) {
        Write-Host "  [ERROR] PAT vacio. Cancelando." -ForegroundColor Red
        exit 1
    }
}

# --- Create ~/.m2 directory ---
if (-not (Test-Path $M2_DIR)) {
    New-Item -ItemType Directory -Path $M2_DIR -Force | Out-Null
    Write-Host "  [OK] Directorio creado: $M2_DIR" -ForegroundColor Green
}

# --- Generate settings.xml ---
$settingsContent = New-SettingsXml -Token $PAT
Set-Content -Path $SETTINGS_FILE -Value $settingsContent -Encoding UTF8
Write-Host "  [OK] settings.xml generado en: $SETTINGS_FILE" -ForegroundColor Green

# --- Validate ---
Write-Host ""
Write-Host "  Verificando configuracion..." -ForegroundColor Yellow
Write-Host ""
Test-SettingsXml | Out-Null

Write-Host ""
Write-Host "  Configuracion completada." -ForegroundColor Green
Write-Host "  Ahora puedes ejecutar: mvn clean compile" -ForegroundColor Gray
Write-Host ""
