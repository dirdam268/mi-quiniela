# ── Quiniela IA · construir la app ─────────────────────────────────────
# Inyecta todos los data\jXX_YY-YY.json dentro de plantilla.html y genera
# index.html: la app completa en un solo fichero. Se abre con doble clic y es
# tambien lo que se sube al repo de GitHub Pages.
#
# Uso:
#   powershell -ExecutionPolicy Bypass -File construir.ps1
param(
  [string]$Plantilla = "plantilla.html",
  [string]$Out = "index.html"
)
$ErrorActionPreference = 'Stop'
$dir = $PSScriptRoot
$utf8 = New-Object System.Text.UTF8Encoding($false)

$rutaPlantilla = Join-Path $dir $Plantilla
if (-not (Test-Path $rutaPlantilla)) { throw "No encuentro $Plantilla" }

$dirDatos = Join-Path $dir "data"
$ficheros = @(Get-ChildItem -Path $dirDatos -Filter "j*.json" -ErrorAction SilentlyContinue)
if ($ficheros.Count -eq 0) { throw "No hay ficheros data\jXX_YY-YY.json" }

# Ordenar por temporada y jornada, de la mas reciente a la mas antigua
$ordenados = $ficheros | Sort-Object -Property `
  @{ Expression = { if ($_.Name -match '^j(\d+)_(\d+)-(\d+)') { [int]$Matches[2] } else { 0 } }; Descending = $true },
  @{ Expression = { if ($_.Name -match '^j(\d+)_') { [int]$Matches[1] } else { 0 } }; Descending = $true }

$bloques = @()
foreach ($f in $ordenados) {
  $texto = [System.IO.File]::ReadAllText($f.FullName, [System.Text.Encoding]::UTF8).TrimStart([char]0xFEFF).Trim()
  # Validacion basica: si el JSON esta roto, mejor fallar aqui que en el navegador
  try { $null = $texto | ConvertFrom-Json } catch { throw ("JSON invalido en {0}: {1}" -f $f.Name, $_.Exception.Message) }
  $bloques += $texto
  Write-Host ("  + {0}" -f $f.Name)
}

$json = "[" + ($bloques -join ",") + "]"

$html = [System.IO.File]::ReadAllText($rutaPlantilla, [System.Text.Encoding]::UTF8)
if ($html -notmatch '__JORNADAS__') { throw "La plantilla no contiene el marcador __JORNADAS__" }
$html = $html.Replace('__JORNADAS__', $json)

$rutaOut = Join-Path $dir $Out
[System.IO.File]::WriteAllText($rutaOut, $html, $utf8)
Write-Host ("OK -> {0} generado ({1} jornadas, {2} KB)" -f $Out, $bloques.Count, [math]::Round((Get-Item $rutaOut).Length/1024))
