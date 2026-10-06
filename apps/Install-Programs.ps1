#Requires -Version 5.1
<#
.SYNOPSIS
    Instala automaticamente os programas usados no dia a dia via winget.

.DESCRIPTION
    Compatível com Windows PowerShell 5.1 e PowerShell 7+.
    Programas já instalados são ignorados. Para adicionar um novo programa,
    inclua uma entrada na lista $Programs abaixo.

    Source: 'winget'  -> repositório da comunidade
            'msstore' -> Microsoft Store

.EXAMPLE
    .\Install-Programs.ps1
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$Programs = @(
    @{ Name = 'PowerShell 7';       Id = 'Microsoft.PowerShell';       Source = 'winget'  }
    @{ Name = 'Claude Desktop';     Id = 'Anthropic.Claude';           Source = 'winget'  }
    @{ Name = 'Claude Code';        Id = 'Anthropic.ClaudeCode';       Source = 'winget'  }
    @{ Name = 'Bitwarden';          Id = '9PJSDV0VPK04';               Source = 'msstore' }
    @{ Name = 'Visual Studio Code'; Id = 'Microsoft.VisualStudioCode'; Source = 'winget'  }
    @{ Name = 'Git';                Id = 'Git.Git';                    Source = 'winget'  }
    @{ Name = 'GitHub CLI';         Id = 'GitHub.cli';                 Source = 'winget'  }
    @{ Name = 'mise-en-place';      Id = 'jdx.mise';                   Source = 'winget'  }
    @{ Name = 'Caffeine';           Id = 'ZhornSoftware.Caffeine';     Source = 'winget'  }
    @{ Name = 'Postman';            Id = 'Postman.Postman';            Source = 'winget'  }
    @{ Name = 'DBeaver';            Id = 'DBeaver.DBeaver.Community';  Source = 'winget'  }
    @{ Name = 'PowerToys';          Id = 'Microsoft.PowerToys';        Source = 'winget'  }
    @{ Name = 'Ngrok';              Id = 'Ngrok.Ngrok';                Source = 'winget'  }
    @{ Name = 'Windhawk';           Id = 'RamenSoftware.Windhawk';     Source = 'winget'  }
    @{ Name = 'Everything';         Id = 'voidtools.Everything';       Source = 'winget'  }
)

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Error 'winget não encontrado. Instale o "App Installer" pela Microsoft Store e execute novamente.'
}

function Test-Installed {
    param([string]$Id, [string]$Source)
    $null = winget list --id $Id --exact --source $Source --accept-source-agreements 2>&1
    return ($LASTEXITCODE -eq 0)
}

$results = @()

foreach ($p in $Programs) {
    Write-Host "`n==> $($p.Name) ($($p.Id))" -ForegroundColor Cyan

    if (Test-Installed -Id $p.Id -Source $p.Source) {
        Write-Host '    Já instalado, ignorando.' -ForegroundColor DarkGray
        $results += [pscustomobject]@{ Programa = $p.Name; Status = 'Já instalado' }
        continue
    }

    winget install --id $p.Id --exact --source $p.Source `
        --accept-package-agreements --accept-source-agreements --silent

    if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq -1978335189) {
        $results += [pscustomobject]@{ Programa = $p.Name; Status = 'Instalado' }
    }
    else {
        Write-Warning "Falha ao instalar $($p.Name) (código $LASTEXITCODE)."
        $results += [pscustomobject]@{ Programa = $p.Name; Status = "Falhou ($LASTEXITCODE)" }
    }
}

Write-Host "`n===== Resumo =====" -ForegroundColor Green
$results | Format-Table -AutoSize

if ($results | Where-Object { $_.Status -like 'Falhou*' }) { exit 1 }
