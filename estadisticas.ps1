# Quiniela IA - capturar estadisticas avanzadas de LaLiga (xG, forma, jugadores)
#
# Fuente: Understat (understat.com), que sirve sus tablas por AJAX en
# /getLeagueData/La_liga/<anio>. Se lee DIRECTAMENTE, sin resumen de ningun modelo.
#
# Que trae: por equipo, xG y xGA por partido (total, en casa y fuera), PPDA
# (presion), goles, puntos frente a puntos esperados, y los ultimos 5 resultados;
# por jugador, minutos, xG, xA, pases clave. TODO solo de LaLiga.
#
# Que NO trae, y no se inventa: duelos aereos ganados, posesion, ni nada de
# Segunda Division, Liga F o competiciones europeas. Tampoco se usa el campo
# "forecast" de Understat: existe solo en partidos ya jugados porque se calcula
# con el xG del propio partido, asi que usarlo como pronostico seria hacer trampa.
#
# Guarda dos ficheros:
#   data\crudo\understat_laliga_<anio>.json   la respuesta tal cual (auditable)
#   data\estadisticas_laliga.json             el resumen que usa la app
#
# IMPORTANTE: este fichero es ASCII PURO a proposito. PowerShell 5.1 lee como ANSI
# los .ps1 sin BOM y convierte acentos y simbolos en comillas tipograficas que
# rompen el codigo. No meter caracteres no ASCII aqui.
#
# Uso:
#   powershell -ExecutionPolicy Bypass -File estadisticas.ps1
param(
  [int]$Anio = 2026,
  [int]$MinutosMinimos = 270   # un jugador entra en las listas con al menos 3 partidos completos
)
$ErrorActionPreference = 'Stop'
$inv = [System.Globalization.CultureInfo]::InvariantCulture
$utf8 = New-Object System.Text.UTF8Encoding($false)
$dirData = Join-Path $PSScriptRoot 'data'
$dirCrudo = Join-Path $dirData 'crudo'
if (-not (Test-Path $dirCrudo)) { New-Item -ItemType Directory -Path $dirCrudo | Out-Null }

$ua = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36'
$cab = @{
  'X-Requested-With' = 'XMLHttpRequest'
  'Referer'          = "https://understat.com/league/La_liga/$Anio"
  'Accept'           = 'application/json, text/javascript, */*'
}
$url = "https://understat.com/getLeagueData/La_liga/$Anio"
Write-Host "Leyendo $url ..."
$r = Invoke-WebRequest -Uri $url -UseBasicParsing -UserAgent $ua -Headers $cab -TimeoutSec 90
# Se decodifica a mano como UTF-8: si el servidor no declara charset, PowerShell
# lo leeria como ISO-8859-1 y los nombres con tilde saldrian rotos
$txt = [System.Text.Encoding]::UTF8.GetString($r.RawContentStream.ToArray())
[System.IO.File]::WriteAllText((Join-Path $dirCrudo "understat_laliga_$Anio.json"), $txt, $utf8)

Add-Type -AssemblyName System.Web.Extensions
$ser = New-Object System.Web.Script.Serialization.JavaScriptSerializer
$ser.MaxJsonLength = [int]::MaxValue
$d = $ser.DeserializeObject($txt)
if (-not $d.ContainsKey('teams') -or -not $d.ContainsKey('players') -or -not $d.ContainsKey('dates')) {
  throw "la respuesta no tiene teams/players/dates: Understat ha cambiado el formato"
}

function Dbl($v) { return [double]::Parse([string]$v, $inv) }
function Redond($v, [int]$n) { return [math]::Round([double]$v, $n) }
function Fecha($s) { return [datetime]::ParseExact(([string]$s).Substring(0, 10), 'yyyy-MM-dd', $inv) }

# Ultimo partido jugado de toda la liga: hasta aqui llegan los datos
$jugados = @($d['dates'] | Where-Object { $_['isResult'] -eq $true })
if ($jugados.Count -eq 0) { throw "no hay partidos jugados en Understat para $Anio" }
$hasta = ($jugados | ForEach-Object { Fecha $_['datetime'] } | Measure-Object -Maximum).Maximum

# Jugadores agrupados por equipo (un traspasado figura como "A,B": cuenta para el ultimo)
$porEquipo = @{}
foreach ($p in $d['players']) {
  $eq = ([string]$p['team_title']).Split(',')[-1].Trim()
  $min = Dbl $p['time']
  if ($min -lt $MinutosMinimos) { continue }
  if (-not $porEquipo.ContainsKey($eq)) { $porEquipo[$eq] = @() }
  $porEquipo[$eq] += [pscustomobject]@{
    nombre = [string]$p['player_name']; posicion = [string]$p['position']; minutos = [int]$min
    goles = [int](Dbl $p['goals']); asistencias = [int](Dbl $p['assists'])
    xg90 = (Redond ((Dbl $p['xG']) * 90 / $min) 2); xa90 = (Redond ((Dbl $p['xA']) * 90 / $min) 2)
    pc90 = (Redond ((Dbl $p['key_passes']) * 90 / $min) 2)
  }
}

$letra = @{ 'w' = 'V'; 'd' = 'E'; 'l' = 'D' }
$equipos = [ordered]@{}
foreach ($kv in ($d['teams'].GetEnumerator() | Sort-Object { $_.Value['title'] })) {
  $t = $kv.Value
  $nombre = [string]$t['title']
  $h = @($t['history'] | Sort-Object { Fecha $_['date'] })
  $n = $h.Count
  if ($n -eq 0) { continue }
  $xg = 0.0; $xga = 0.0; $gf = 0; $gc = 0; $pts = 0; $xpts = 0.0; $pAtt = 0.0; $pDef = 0.0
  $hxg = 0.0; $hxga = 0.0; $hn = 0; $axg = 0.0; $axga = 0.0; $an = 0
  foreach ($m in $h) {
    $xg += Dbl $m['xG']; $xga += Dbl $m['xGA']; $gf += [int]$m['scored']; $gc += [int]$m['missed']
    $pts += [int]$m['pts']; $xpts += Dbl $m['xpts']
    $pAtt += Dbl $m['ppda']['att']; $pDef += Dbl $m['ppda']['def']
    if ($m['h_a'] -eq 'h') { $hxg += Dbl $m['xG']; $hxga += Dbl $m['xGA']; $hn++ } else { $axg += Dbl $m['xG']; $axga += Dbl $m['xGA']; $an++ }
  }
  $ult5 = @($h | Select-Object -Last 5)
  $forma = (($ult5 | ForEach-Object { $letra[[string]$_['result']] }) -join '')
  $jug = @(); if ($porEquipo.ContainsKey($nombre)) { $jug = @($porEquipo[$nombre]) }
  $goleadores = @($jug | Sort-Object xg90 -Descending | Select-Object -First 2)
  $creadores = @($jug | Sort-Object xa90 -Descending | Select-Object -First 2)

  $equipos[$nombre] = [ordered]@{
    pj = $n; forma = $forma
    xg = (Redond ($xg / $n) 2); xga = (Redond ($xga / $n) 2)
    xg_casa = $(if ($hn) { Redond ($hxg / $hn) 2 } else { $null }); xga_casa = $(if ($hn) { Redond ($hxga / $hn) 2 } else { $null })
    xg_fuera = $(if ($an) { Redond ($axg / $an) 2 } else { $null }); xga_fuera = $(if ($an) { Redond ($axga / $an) 2 } else { $null })
    goles = (Redond ($gf / $n) 2); goles_contra = (Redond ($gc / $n) 2)
    ppda = $(if ($pDef -gt 0) { Redond ($pAtt / $pDef) 1 } else { $null })
    pts = $pts; xpts = (Redond $xpts 1)
    goleadores = $goleadores; creadores = $creadores
  }
}

$salida = [ordered]@{
  fuente = 'understat.com'; liga = 'LaLiga'; temporada = '26/27'
  capturado = (Get-Date).ToString('yyyy-MM-dd'); datos_hasta = $hasta.ToString('yyyy-MM-dd')
  partidos_jugados = $jugados.Count
  nota = 'Solo LaLiga. Sin duelos aereos ni posesion: no hay fuente abierta accesible. Los datos van con retraso respecto al calendario.'
  equipos = $equipos
}
$json = $salida | ConvertTo-Json -Depth 8
[System.IO.File]::WriteAllText((Join-Path $dirData 'estadisticas_laliga.json'), $json, $utf8)

Write-Host ""
Write-Host ("Datos hasta el {0} | {1} partidos jugados | {2} equipos" -f $hasta.ToString('dd/MM/yyyy'), $jugados.Count, $equipos.Count)
foreach ($k in $equipos.Keys) {
  $e = $equipos[$k]
  Write-Host ("  {0,-20} PJ{1} {2}  xG {3:N2}  xGA {4:N2}  dif {5:+0.00;-0.00}" -f $k, $e.pj, $e.forma, $e.xg, $e.xga, ($e.xg - $e.xga))
}
