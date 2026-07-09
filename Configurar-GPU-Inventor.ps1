<#
================================================================================
 Configurar-GPU-Inventor.ps1
 --------------------------------------------------------------------------------
 Forca o Autodesk Inventor a usar a GPU dedicada NVIDIA (RTX) neste notebook
 hibrido (Intel UHD + NVIDIA), diagnostica o estado atual e prepara o ambiente
 para maximo desempenho grafico.

 O QUE ELE FAZ (seguro e reversivel):
   1) Diagnostico completo: GPUs, driver, plano de energia, Inventor em execucao.
   2) Define a preferencia de GPU do Windows p/ o Inventor.exe = "Alto desempenho"
      (grava em HKCU\...\DirectX\UserGpuPreferences => GpuPreference=2).
      * E EXATAMENTE o que a tela Configuracoes > Video > Graficos faz, so que
        automatico. Mexe apenas no usuario atual (HKCU). Nao exige admin.
   3) Ativa o plano de energia "Alto desempenho" (reversivel; mostra como voltar).
   4) Abre o Painel de Controle NVIDIA e a tela de Graficos do Windows para os
      poucos ajustes que SO podem ser feitos na interface (ver LEIA-GPU.md).
   5) Abre o proprio Autodesk Inventor ja com a preferencia de GPU valendo
      (se ele nao estiver aberto).
   6) Verifica o resultado com nvidia-smi.

 USO:
   .\Configurar-GPU-Inventor.ps1            (aplica as melhorias)
   .\Configurar-GPU-Inventor.ps1 -Reverter  (desfaz a preferencia de GPU)
   .\Configurar-GPU-Inventor.ps1 -SemAbrirPaineis  (nao abre janelas de config)

 OBS: rode em PowerShell normal (nao precisa admin). Feche o Inventor antes;
 a preferencia de GPU vale a partir da PROXIMA vez que ele abrir.
================================================================================
#>

param(
    [switch]$Reverter,
    [switch]$SemAbrirPaineis
)

$ErrorActionPreference = "Continue"

function Titulo($t) {
    Write-Host ""
    Write-Host ("=" * 74) -ForegroundColor DarkCyan
    Write-Host "  $t" -ForegroundColor Cyan
    Write-Host ("=" * 74) -ForegroundColor DarkCyan
}
function OK($t)    { Write-Host "  [OK]   $t"   -ForegroundColor Green }
function Info($t)  { Write-Host "  [INFO] $t"   -ForegroundColor Gray }
function Aviso($t) { Write-Host "  [!]    $t"   -ForegroundColor Yellow }
function Erro($t)  { Write-Host "  [X]    $t"   -ForegroundColor Red }

# ------------------------------------------------------------------------------
# 1) DIAGNOSTICO
# ------------------------------------------------------------------------------
Titulo "1) DIAGNOSTICO DO SISTEMA"

$gpus = Get-CimInstance Win32_VideoController
foreach ($g in $gpus) {
    $rend = if ($g.CurrentHorizontalResolution) { "  <== compondo a tela ($($g.CurrentHorizontalResolution)px)" } else { "" }
    Info ("GPU: {0} | driver {1}{2}" -f $g.Name, $g.DriverVersion, $rend)
}

$nv = $gpus | Where-Object { $_.Name -match "NVIDIA" } | Select-Object -First 1
if ($nv) { OK "GPU dedicada encontrada: $($nv.Name)" }
else     { Erro "Nenhuma GPU NVIDIA detectada - este script assume Optimus (Intel+NVIDIA)." }

# Localiza o(s) Inventor.exe instalado(s)
$invExes = @()
Get-ChildItem "C:\Program Files\Autodesk" -Directory -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -like "Inventor*" } | ForEach-Object {
        $p = Join-Path $_.FullName "Bin\Inventor.exe"
        if (Test-Path $p) { $invExes += $p }
        $ps = Join-Path $_.FullName "Bin\InventorServer.exe"
        if (Test-Path $ps) { $invExes += $ps }
    }
if ($invExes.Count -gt 0) { $invExes | ForEach-Object { OK "Inventor: $_" } }
else { Aviso "Inventor.exe nao encontrado no caminho padrao - informe manualmente se preciso." }

# Inventor esta aberto agora?
$invProc = Get-Process Inventor -ErrorAction SilentlyContinue
if ($invProc) { Aviso "Inventor esta ABERTO (PID $($invProc.Id)). Feche e reabra p/ a preferencia valer." }

# Plano de energia atual
$plano = (powercfg /getactivescheme) 2>$null
Info "Plano de energia atual: $plano"

# nvidia-smi disponivel?
$temSmi = [bool](Get-Command nvidia-smi -ErrorAction SilentlyContinue)
if (-not $temSmi) { Aviso "nvidia-smi nao esta no PATH - verificacao final sera pulada." }

# ------------------------------------------------------------------------------
# MODO REVERTER
# ------------------------------------------------------------------------------
$regPath = "HKCU:\Software\Microsoft\DirectX\UserGpuPreferences"
if ($Reverter) {
    Titulo "REVERTENDO: removendo preferencia de GPU do Inventor"
    if (Test-Path $regPath) {
        foreach ($exe in $invExes) {
            $prop = (Get-ItemProperty $regPath -ErrorAction SilentlyContinue).PSObject.Properties |
                    Where-Object { $_.Name -eq $exe }
            if ($prop) { Remove-ItemProperty $regPath -Name $exe -ErrorAction SilentlyContinue; OK "Removido: $exe" }
        }
    }
    Info "Para voltar o plano de energia ao Balanceado: powercfg -setactive SCHEME_BALANCED"
    Write-Host ""
    Write-Host "  Reversao concluida." -ForegroundColor Green
    return
}

# ------------------------------------------------------------------------------
# 2) PREFERENCIA DE GPU DO WINDOWS (HKCU) => ALTO DESEMPENHO (=2)
#    0 = deixar o Windows decidir | 1 = economia (Intel) | 2 = alto desempenho (NVIDIA)
# ------------------------------------------------------------------------------
Titulo "2) DEFININDO PREFERENCIA DE GPU = ALTO DESEMPENHO (NVIDIA)"

if (-not (Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }
foreach ($exe in $invExes) {
    try {
        New-ItemProperty -Path $regPath -Name $exe -Value "GpuPreference=2;" -PropertyType String -Force | Out-Null
        OK "Preferencia 'Alto desempenho' aplicada para: $([System.IO.Path]::GetFileName($exe))"
    } catch {
        Erro "Falha ao definir preferencia para $exe : $($_.Exception.Message)"
    }
}
Info "Isto equivale a: Configuracoes > Sistema > Video > Graficos > Inventor > Alto desempenho."

# ------------------------------------------------------------------------------
# 3) PLANO DE ENERGIA = ALTO DESEMPENHO
# ------------------------------------------------------------------------------
Titulo "3) PLANO DE ENERGIA = ALTO DESEMPENHO"
try {
    powercfg -setactive SCHEME_MIN 2>$null   # SCHEME_MIN = plano 'Alto desempenho'
    if ($LASTEXITCODE -eq 0) {
        OK "Plano de energia definido para 'Alto desempenho'."
        Info "Para voltar depois: powercfg -setactive SCHEME_BALANCED"
    } else {
        Aviso "Nao foi possivel trocar via SCHEME_MIN. Ajuste manual em Config > Energia."
    }
} catch { Aviso "Falha ao trocar plano de energia: $($_.Exception.Message)" }
Aviso "Mantenha o notebook NA TOMADA ao usar o Inventor (na bateria o Optimus poupa a NVIDIA)."

# ------------------------------------------------------------------------------
# 4) ABRIR PAINEIS PARA OS AJUSTES MANUAIS (ver LEIA-GPU.md)
# ------------------------------------------------------------------------------
if (-not $SemAbrirPaineis) {
    Titulo "4) ABRINDO PAINEIS PARA AJUSTE MANUAL"
    # Tela de Graficos do Windows (para conferir a preferencia aplicada)
    try { Start-Process "ms-settings:display" ; OK "Abri Configuracoes de Video (va em 'Graficos')." } catch {}
    # Painel de Controle NVIDIA
    $abriuNv = $false
    foreach ($c in @("nvcplui.exe", "C:\Windows\System32\nvcplui.exe")) {
        try { Start-Process $c -ErrorAction Stop; $abriuNv = $true; break } catch {}
    }
    if ($abriuNv) { OK "Abri o Painel de Controle NVIDIA (Gerenciar configuracoes 3D > Configuracoes de programa)." }
    else { Aviso "Nao consegui abrir o Painel NVIDIA. Abra pelo menu Iniciar > 'Painel de Controle NVIDIA'." }
    Info "No Painel NVIDIA: Programa = Inventor.exe | Processador grafico = 'Processador NVIDIA de alto desempenho'."
    Info "Consulte o passo a passo completo em: X:\-Sistema-\GPU\LEIA-GPU.md"
}

# ------------------------------------------------------------------------------
# 5) ABRIR O INVENTOR (ja com a preferencia de GPU aplicada)
# ------------------------------------------------------------------------------
Titulo "5) ABRINDO O AUTODESK INVENTOR"
$invMain = $invExes | Where-Object { [System.IO.Path]::GetFileName($_) -ieq "Inventor.exe" } | Select-Object -First 1
if ($invProc) {
    Aviso "Inventor ja esta ABERTO (PID $($invProc.Id)). Feche e reabra p/ a preferencia valer - nao vou abrir outra instancia."
} elseif ($invMain) {
    try {
        Start-Process -FilePath $invMain
        OK "Inventor iniciado: $invMain"
    } catch {
        Erro "Nao consegui abrir o Inventor: $($_.Exception.Message)"
    }
} else {
    Aviso "Inventor.exe nao localizado - abra manualmente pelo menu Iniciar."
}

# ------------------------------------------------------------------------------
# 6) VERIFICACAO
# ------------------------------------------------------------------------------
Titulo "6) VERIFICACAO"
Info "Preferencias de GPU gravadas (HKCU):"
if (Test-Path $regPath) {
    (Get-ItemProperty $regPath).PSObject.Properties |
        Where-Object { $_.Name -like "*Inventor*" } |
        ForEach-Object { Write-Host ("     {0} = {1}" -f $_.Name, $_.Value) -ForegroundColor White }
}
if ($temSmi) {
    Write-Host ""
    Info "Uso atual da NVIDIA (nvidia-smi):"
    nvidia-smi --query-gpu=name,utilization.gpu,memory.used,memory.total,power.draw --format=csv,noheader
    Write-Host ""
    Info "Processos na NVIDIA (procure por Inventor.exe quando ele estiver aberto):"
    nvidia-smi --query-compute-apps=pid,used_memory,process_name --format=csv,noheader 2>$null
}

Titulo "CONCLUIDO"
Write-Host "  1. FECHE e REABRA o Inventor para a preferencia de GPU passar a valer." -ForegroundColor White
Write-Host "  2. No Inventor: Ferramentas > Opcoes do Aplicativo > aba Hardware." -ForegroundColor White
Write-Host "     - Ative a aceleracao de hardware / escolha a NVIDIA (ver LEIA-GPU.md)." -ForegroundColor White
Write-Host "  3. (Opcional) Ray Tracing na GPU para renderizacao realista." -ForegroundColor White
Write-Host ""
Write-Host "  Guia detalhado: X:\-Sistema-\GPU\LEIA-GPU.md" -ForegroundColor Cyan
Write-Host ""
