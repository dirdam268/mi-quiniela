# Quiniela IA - capturar el escrutinio oficial de una o varias jornadas
#
# Lee la pagina de eduardolosilla DIRECTAMENTE (sin resumen de ningun modelo),
# extrae acertantes y premio por categoria, la valida y la guarda en
# data\escrutinios.json. Lo que se guarda es lo que REALMENTE se pago.
#
# Reparto teorico publicado (el 55% de la recaudacion va a premios):
#   15 aciertos 7,5% + bote | 14 aciertos 16% | 13, 12 y 11 aciertos 7,5% cada una
#   | 10 aciertos 9%. Los premios de mas de 40.000 EUR llegan con el 20% retenido
#   sobre lo que pasa de 40.000, asi que se deshace esa retencion para comparar.
#
# OJO: el reparto REAL se desvia de ese teorico (premios minimos que pasan a bote,
# categorias sin pagar, sobrantes que suben a otra categoria). Por eso la formula
# NO es el juez: solo genera avisos (campo "notas"). La validacion que puede
# rechazar una captura usa invariantes que siempre se cumplen:
#   - estan las seis categorias (15, 14, 13, 12, 11, 10 aciertos)
#   - hay mas acertantes cuantos menos aciertos
#   - los premios que se pagan crecen con los aciertos
#   - lo cobrado en cada categoria esta en un orden de magnitud razonable
#     (atrapa un decimal mal leido, que daria 10x o 1000x)
# Si una captura no cumple, NO se guarda: mas vale un hueco que un dato mal leido.
#
# IMPORTANTE: este fichero es ASCII PURO a proposito. PowerShell 5.1 lee como ANSI
# los .ps1 sin BOM y convierte acentos, el simbolo del euro y las rayas en comillas
# tipograficas que rompen el codigo. No meter caracteres no ASCII aqui.
#
# Uso:
#   powershell -ExecutionPolicy Bypass -File escrutinio.ps1 -Jornadas 7
#   powershell -ExecutionPolicy Bypass -File escrutinio.ps1 -Jornadas 1..12
#   powershell -ExecutionPolicy Bypass -File escrutinio.ps1 -Jornadas 3,5,9
param(
  [Parameter(Mandatory = $true)][string]$Jornadas,
  [string]$Temporada = '26/27',
  [switch]$Forzar
)
$ErrorActionPreference = 'Stop'

# Con -File, PowerShell pasa la lista como un unico texto: se interpreta aqui
$lista = @()
foreach ($tok in ($Jornadas -split ',')) {
  $tok = $tok.Trim()
  if ($tok -match '^(\d+)\.\.(\d+)$') { $lista += [int]$Matches[1]..[int]$Matches[2] }
  elseif ($tok -match '^\d+$') { $lista += [int]$tok }
  else { throw "Jornadas no valido: '$tok'. Usa 7, 1,2,3 o 1..12" }
}

$inv = [System.Globalization.CultureInfo]::InvariantCulture
$utf8 = New-Object System.Text.UTF8Encoding($false)
$destino = Join-Path $PSScriptRoot 'data\escrutinios.json'
$ua = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36'
$EUR = [string][char]0x20AC

$PCT = @{ 14 = 0.16; 13 = 0.075; 12 = 0.075; 11 = 0.075; 10 = 0.09 }
$AVISO = 0.015     # desvio sobre el reparto teorico a partir del cual se anota
$MAGNITUD = 4.0    # por encima de x4 (o por debajo de /4) del teorico se rechaza

function Limpia([string]$s) {
  $t = [regex]::Replace($s, '<[^>]+>', ' ')
  $t = $t -replace '&nbsp;', ' ' -replace '&quot;', '"' -replace '&amp;', '&'
  return ($t -replace '\s+', ' ').Trim()
}
# "3.901" -> 3901 ; "177.368,29" -> 177368.29
function Num([string]$s) {
  $t = ($s -replace '[^\d,\.]', '') -replace '\.', '' -replace ',', '.'
  return [double]::Parse($t, $inv)
}
# Deshace la retencion del 20% sobre lo que pasa de 40.000 EUR
function Bruto([double]$neto) {
  if ($neto -gt 40000) { return 40000 + ($neto - 40000) / 0.8 }
  return $neto
}

function LeeJornada([int]$n) {
  $url = "https://www.eduardolosilla.es/quiniela/ayudas/escrutinio/jornada_$n"
  $r = Invoke-WebRequest -Uri $url -UseBasicParsing -UserAgent $ua -TimeoutSec 40
  $h = [string]$r.Content

  $cap = [regex]::Match($h, '<caption[^>]*>(.*?)</caption>', 'Singleline')
  if (-not $cap.Success) { throw "no encuentro el titulo de la tabla" }
  $titulo = Limpia $cap.Groups[1].Value
  $m = [regex]::Match($titulo, 'JORNADA\s+(\d+)\s*-\s*(\d+/\d+)\s*\((\d{2})/(\d{2})/(\d{4})\)')
  if (-not $m.Success) { throw ("titulo con formato inesperado: " + $titulo) }
  if ([int]$m.Groups[1].Value -ne $n) { throw ("pedi la jornada $n y la pagina es la " + $m.Groups[1].Value) }
  if ($m.Groups[2].Value -ne $Temporada) { throw ("temporada " + $m.Groups[2].Value + ", esperaba $Temporada") }
  $fecha = "{0}-{1}-{2}" -f $m.Groups[5].Value, $m.Groups[4].Value, $m.Groups[3].Value

  $rec = [regex]::Match($h, 'recaudacion__price[^>]*>\s*([\d\.,]+)')
  $bote = [regex]::Match($h, 'bote__price[^>]*>\s*([\d\.,]+)')
  if (-not $rec.Success) { throw "no encuentro la recaudacion" }
  if (-not $bote.Success) { throw "no encuentro el bote" }

  $cats = @()
  foreach ($row in [regex]::Matches($h, '<tr[^>]*c-tabla-categorias__table__category[^>]*>(.*?)</tr>', 'Singleline')) {
    $b = $row.Groups[1].Value
    $q = [regex]::Match($b, '__aciertos__qty">\s*(\d+)\s*<')
    $a = [regex]::Match($b, '__acertantes">\s*([\d\.]+)\s*<')
    $p = [regex]::Match($b, '__premio">\s*([\d\.,]+)')
    if ($q.Success -and $a.Success -and $p.Success) {
      $cats += [pscustomobject]@{ aciertos = [int]$q.Groups[1].Value; acertantes = [int](Num $a.Groups[1].Value); premio = (Num $p.Groups[1].Value) }
    }
  }

  # Elige 8: viene en una fila con otro formato
  $e8 = $null
  $tabla = [regex]::Match($h, '<table[^>]*c-tabla-categorias[^>]*>.*?</table>', 'Singleline').Value
  $e = [regex]::Match((Limpia $tabla), ('Elige 8\s+([\d\.]+)\s+([\d\.,]+)\s*' + $EUR))
  if ($e.Success) { $e8 = [pscustomobject]@{ acertantes = [int](Num $e.Groups[1].Value); premio = (Num $e.Groups[2].Value) } }

  return [pscustomobject]@{
    jornada = $n; fecha = $fecha; recaudacion = (Num $rec.Groups[1].Value); bote = (Num $bote.Groups[1].Value)
    categorias = $cats; elige8 = $e8; fuente = $url
  }
}

# Devuelve problemas (rechazan), notas (solo avisan) y lo pagado
function Valida($e) {
  $problemas = @(); $notas = @()
  if ($e.recaudacion -le 0) { $problemas += "recaudacion no positiva" }
  $porC = @{}
  foreach ($c in $e.categorias) { $porC[[int]$c.aciertos] = $c }
  foreach ($k in 15, 14, 13, 12, 11, 10) {
    if (-not $porC.ContainsKey($k)) { $problemas += "falta la categoria de $k aciertos" }
  }
  if ($problemas.Count -gt 0) { return [pscustomobject]@{ problemas = $problemas; notas = $notas; pagado = 0.0 } }

  # Mas acertantes cuantos menos aciertos
  $orden = 10, 11, 12, 13, 14, 15
  for ($i = 0; $i -lt 5; $i++) {
    $menos = $porC[$orden[$i]].acertantes; $mas = $porC[$orden[$i + 1]].acertantes
    if ($menos -lt $mas) { $problemas += ("{0} aciertos tiene menos acertantes ({1}) que {2} aciertos ({3})" -f $orden[$i], $menos, $orden[$i + 1], $mas) }
  }
  # Los premios que se pagan crecen con los aciertos
  $prev = 0.0
  foreach ($k in 10, 11, 12, 13, 14) {
    $pr = $porC[$k].premio
    if ($pr -gt 0) {
      if ($pr -lt $prev) { $problemas += "el premio de $k aciertos es menor que el de una categoria con menos aciertos" }
      $prev = $pr
    }
  }

  $pagado = 0.0
  foreach ($k in 14, 13, 12, 11, 10) {
    $cat = $porC[$k]
    $n = $cat.acertantes
    if ($k -eq 14) { $n += $porC[15].acertantes }   # los de 15 aciertos cobran tambien el premio de 14
    $pool = $PCT[$k] * $e.recaudacion
    if ($n -eq 0) {
      if ($cat.premio -ne 0) { $problemas += "$k aciertos: sin acertantes pero con premio" }
      continue
    }
    if ($cat.premio -eq 0) {
      $notas += ("{0} aciertos: {1} acertantes sin premio (el teorico seria {2:N2} EUR cada uno; pasa a bote)" -f $k, $n, ($pool / $n))
      continue
    }
    $cobrado = $n * (Bruto $cat.premio)
    $pagado += $cobrado
    $ratio = $cobrado / $pool
    if ($ratio -gt $MAGNITUD -or $ratio -lt (1 / $MAGNITUD)) {
      $problemas += ("{0} aciertos: se habria pagado {1:N0} EUR frente a {2:N0} del reparto teorico (x{3:N1}): probable error de lectura" -f $k, $cobrado, $pool, $ratio)
    } elseif ([math]::Abs($ratio - 1) -gt $AVISO) {
      $notas += ("{0} aciertos: cobran {1:P1} de lo teorico (reparto distinto del publicado)" -f $k, $ratio)
    }
  }
  return [pscustomobject]@{ problemas = $problemas; notas = $notas; pagado = $pagado }
}

# Carga lo que ya hubiera guardado
$almacen = [ordered]@{}   # temporada -> (jornada -> escrutinio)
if (Test-Path $destino) {
  $viejo = [System.IO.File]::ReadAllText($destino, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
  foreach ($t in $viejo.PSObject.Properties) {
    $almacen[$t.Name] = [ordered]@{}
    foreach ($j in $t.Value.PSObject.Properties) { $almacen[$t.Name][$j.Name] = $j.Value }
  }
}
if (-not $almacen.Contains($Temporada)) { $almacen[$Temporada] = [ordered]@{} }

$hoy = (Get-Date).ToString('yyyy-MM-dd')
$guardadas = 0; $fallidas = @()
foreach ($n in $lista) {
  try {
    $e = LeeJornada $n
    $v = Valida $e
    $linea = "J{0,-2} {1}  recaudacion {2,13:N2}  bote {3,13:N2}  pagado {4:P1}" -f $n, $e.fecha, $e.recaudacion, $e.bote, ($v.pagado / $e.recaudacion)
    if ($v.problemas.Count -gt 0 -and -not $Forzar) {
      Write-Host ($linea + "  NO GUARDADA") -ForegroundColor Red
      foreach ($p in $v.problemas) { Write-Host ("      - " + $p) -ForegroundColor Red }
      $fallidas += $n
      continue
    }
    Write-Host ($linea + "  OK")
    foreach ($nt in $v.notas) { Write-Host ("      nota: " + $nt) -ForegroundColor DarkYellow }
    $e | Add-Member -NotePropertyName notas -NotePropertyValue @($v.notas)
    $e | Add-Member -NotePropertyName capturado -NotePropertyValue $hoy
    $almacen[$Temporada][[string]$n] = $e
    $guardadas++
  } catch {
    Write-Host ("J{0}: ERROR - {1}" -f $n, $_.Exception.Message) -ForegroundColor Red
    $fallidas += $n
  }
}

# Guarda con un formato legible (una categoria por linea)
function Fmt([double]$d) { return $d.ToString('0.##', $inv) }
function Txt([string]$s) { return '"' + ($s -replace '\\', '\\' -replace '"', '\"') + '"' }
$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine('{')
$temps = @($almacen.Keys)
for ($ti = 0; $ti -lt $temps.Count; $ti++) {
  $t = $temps[$ti]
  [void]$sb.AppendLine('  "' + $t + '": {')
  $js = @($almacen[$t].Keys | Sort-Object { [int]$_ })
  for ($ji = 0; $ji -lt $js.Count; $ji++) {
    $e = $almacen[$t][$js[$ji]]
    [void]$sb.AppendLine('    "' + $js[$ji] + '": {')
    [void]$sb.AppendLine('      "fecha": "' + $e.fecha + '", "recaudacion": ' + (Fmt $e.recaudacion) + ', "bote": ' + (Fmt $e.bote) + ',')
    [void]$sb.AppendLine('      "categorias": [')
    $cs = @($e.categorias)
    for ($ci = 0; $ci -lt $cs.Count; $ci++) {
      $coma = if ($ci -lt $cs.Count - 1) { ',' } else { '' }
      [void]$sb.AppendLine('        {"aciertos": ' + $cs[$ci].aciertos + ', "acertantes": ' + $cs[$ci].acertantes + ', "premio": ' + (Fmt $cs[$ci].premio) + '}' + $coma)
    }
    [void]$sb.AppendLine('      ],')
    if ($e.elige8) { [void]$sb.AppendLine('      "elige8": {"acertantes": ' + $e.elige8.acertantes + ', "premio": ' + (Fmt $e.elige8.premio) + '},') }
    $nts = @($e.notas)
    if ($nts.Count -gt 0) {
      [void]$sb.AppendLine('      "notas": [' + (($nts | ForEach-Object { Txt ([string]$_) }) -join ', ') + '],')
    }
    [void]$sb.AppendLine('      "fuente": "' + $e.fuente + '", "capturado": "' + $e.capturado + '"')
    $cierraJ = if ($ji -lt $js.Count - 1) { ',' } else { '' }
    [void]$sb.AppendLine('    }' + $cierraJ)
  }
  $cierraT = if ($ti -lt $temps.Count - 1) { ',' } else { '' }
  [void]$sb.AppendLine('  }' + $cierraT)
}
[void]$sb.AppendLine('}')

if ($guardadas -gt 0) {
  [System.IO.File]::WriteAllText($destino, $sb.ToString(), $utf8)
  Write-Host ("`nGuardadas {0} en {1}" -f $guardadas, $destino)
}
if ($fallidas.Count -gt 0) { Write-Host ("Sin guardar: J" + ($fallidas -join ', J')) -ForegroundColor Yellow }
