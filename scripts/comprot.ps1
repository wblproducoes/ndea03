Param(
    [switch]$Watch,
    [int]$IntervalMinutes = 2,
    [string]$Message,
    [switch]$Init,
    [switch]$SetLocalUser,
    [string]$UserName = "Auto Commit Bot",
    [string]$UserEmail = "auto-commit@example.com"
)

function Ensure-Repo {
    try {
        git rev-parse --is-inside-work-tree | Out-Null
    } catch {
        if ($Init) {
            git init | Out-Null
        } else {
            Write-Host "Repositório Git não encontrado. Use -Init para inicializar." -ForegroundColor Yellow
            throw
        }
    }
    if ($SetLocalUser) {
        git config user.name $UserName
        git config user.email $UserEmail
    }
}

function Get-ChangeSummary {
    $status = git status --porcelain
    $count = ($status | Measure-Object -Line).Count
    $files = ($status -replace "^..\s+", "")
    return @{ Count = $count; Files = $files }
}

function Commit-Once {
    $summary = Get-ChangeSummary
    if ($summary.Count -gt 0) {
        git add -A
        $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        if (-not $Message -or $Message.Trim().Length -eq 0) {
            $Message = "auto: $ts ($($summary.Count) arquivos)"
        }
        git commit -m $Message | Out-Null
        Write-Host "Commit realizado: $Message" -ForegroundColor Green
        foreach ($f in $summary.Files) { Write-Host " - $f" }
    } else {
        Write-Host "Nenhuma alteração para commit" -ForegroundColor DarkGray
    }
}

Ensure-Repo

if ($Watch) {
    Write-Host "Iniciando commits automáticos a cada $IntervalMinutes min..." -ForegroundColor Cyan
    while ($true) {
        try { Commit-Once } catch { Write-Host $_ -ForegroundColor Red }
        Start-Sleep -Seconds ($IntervalMinutes * 60)
    }
} else {
    Commit-Once
}

