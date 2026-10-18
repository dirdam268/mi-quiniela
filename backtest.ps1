# Quiniela IA - backtest: las estadisticas de Understat, aportan algo sobre LAE?
#
# Para cada partido de 1a Division de nuestras jornadas ya cerradas:
#   1) Cruza nuestro resultado con el de Understat (auditoria de datos gratis).
#   2) Reconstruye lo que se sabia ANTES del partido: la diferencia de xG por
#      partido de cada equipo con los partidos anteriores a esa fecha (nada del
#      propio partido ni posteriores, para no hacer trampa).
#   3) Compara dos predictores:
#        A = el favorito de LAE
#        B = "gana el de mejor diferencia de xG" (1 o 2, nunca X). Regla fijada de
#            antemano, sin tocar parametros para no ajustarla a estos datos.
#
# Solo sirve para LaLiga: Understat no cubre Segunda, Liga F ni Europa.
# Usa data\crudo\understat_laliga_2026.json (lo deja estadisticas.ps1).
#
# IMPORTANTE: este fichero es ASCII PURO a proposito (ver estadisticas.ps1).
#
# Uso:
#   powershell -ExecutionPolicy Bypass -File backtest.ps1
param([int]$Anio = 2026, [int]$PartidosMinimos = 3)
$ErrorActionPreference = 'Stop'
$inv = [System.Globalization.CultureInfo]::InvariantCulture
$dir = Join-Path $PSScriptRoot 'data'

Add-Type -AssemblyName System.Web.Extensions
$ser = New-Object System.Web.Script.Serialization.JavaScriptSerializer
$ser.MaxJsonLength = [int]::MaxValue
$crudo = Join-Path $dir "crudo\understat_laliga_$Anio.json"
if (-not (Test-Path $crudo)) { throw ("falta " + $crudo + " - ejecuta antes estadisticas.ps1") }
$us = $ser.DeserializeObject([System.IO.File]::ReadAllText($crudo, [System.Text.Encoding]::UTF8))

function Normaliza([string]$s) {
  $t = $s.Normalize([System.Text.NormalizationForm]::FormD)
  $t = [regex]::Replace($t, '\p{Mn}', '')
  $t = ($t.ToLowerInvariant() -replace '[^a-z ]', ' ' -replace '\s+', ' ')
  return $t.Trim()
}
# Nombres nuestros que difieren de los de Understat una vez normalizados
$ALIAS = @{ 'dep alaves' = 'alaves'; 'fc barcelona' = 'barcelona'; 'rc deportivo' = 'deportivo la coruna'; 'rcd espanyol' = 'espanyol'; 'elche cf' = 'elche' }
function Clave([string]$s) { $n = Normaliza $s; if ($ALIAS.ContainsKey($n)) { return $ALIAS[$n] }; return $n }
function Dbl($v) { return [double]::Parse([string]$v, $inv) }
function Fecha($s) { return [datetime]::ParseExact(([string]$s).Substring(0, 10), 'yyyy-MM-dd', $inv) }
function Margen($k, $n) { if ($n -eq 0) { return 0 }; $p = $k / $n; return [math]::Round(196 * [math]::Sqrt($p * (1 - $p) / $n)) }
function Pct($k, $n) { if ($n -eq 0) { return 'n/d' }; return ("{0}/{1} ({2:P0} +-{3})" -f $k, $n, ($k / $n), (Margen $k $n)) }

# Historial por equipo (para el xG previo) y partidos jugados por pareja
$hist = @{}
foreach ($kv in $us['teams'].GetEnumerator()) {
  $hist[(Clave ([string]$kv.Value['title']))] = @($kv.Value['history'] | ForEach-Object { [pscustomobject]@{ f = (Fecha $_['date']); xg = (Dbl $_['xG']); xga = (Dbl $_['xGA']) } })
}
$partidosUs = @{}
foreach ($m in $us['dates']) {
  if ($m['isResult'] -ne $true) { continue }
  $k = (Clave ([string]$m['h']['title'])) + '|' + (Clave ([string]$m['a']['title']))
  if (-not $partidosUs.ContainsKey($k)) { $partidosUs[$k] = @() }
  $partidosUs[$k] += [pscustomobject]@{ f = (Fecha $m['datetime']); gh = [int]$m['goals']['h']; ga = [int]$m['goals']['a'] }
}
function XgPrevio($clave, [datetime]$antes) {
  $h = @($hist[$clave] | Where-Object { $_.f -lt $antes })
  if ($h.Count -eq 0) { return [pscustomobject]@{ n = 0; dif = 0.0 } }
  $s = 0.0; foreach ($x in $h) { $s += ($x.xg - $x.xga) }
  return [pscustomobject]@{ n = $h.Count; dif = $s / $h.Count }
}

$filas = @(); $sinCruce = 0; $discrepancias = @()
foreach ($f in Get-ChildItem "$dir\j*.json" | Sort-Object Name) {
  $j = [System.IO.File]::ReadAllText($f.FullName, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
  foreach ($p in $j.partidos) {
    if (-not $p.resultado) { continue }
    if (-not ($p.div -like '1*')) { continue }          # solo 1a Division masculina
    $kl = Clave $p.local; $kv = Clave $p.visit
    $lista = @($partidosUs[$kl + '|' + $kv])
    if ($lista.Count -eq 0 -or $lista[0] -eq $null) { $sinCruce++; continue }
    $u = $lista[0]
    $signoUs = if ($u.gh -gt $u.ga) { '1' } elseif ($u.gh -lt $u.ga) { '2' } else { 'X' }
    if ($signoUs -ne $p.resultado) { $discrepancias += ("J{0} P{1} {2}-{3}: nuestro resultado {4}, Understat {5}-{6} ({7})" -f $j.meta.jornada, $p.num, $p.local, $p.visit, $p.resultado, $u.gh, $u.ga, $signoUs) }

    $xl = XgPrevio $kl $u.f; $xv = XgPrevio $kv $u.f
    $laeFav = $null
    if ($p.lae_1 -ne $null) {
      $m = @{ '1' = [double]$p.lae_1; 'X' = [double]$p.lae_x; '2' = [double]$p.lae_2 }
      $laeFav = ($m.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 1).Key
    }
    $filas += [pscustomobject]@{
      J = $j.meta.jornada; Real = $signoUs; LaeFav = $laeFav
      Valido = ($xl.n -ge $PartidosMinimos -and $xv.n -ge $PartidosMinimos)
      B = $(if (($xl.dif - $xv.dif) -gt 0) { '1' } else { '2' })
      Dif = ($xl.dif - $xv.dif)
    }
  }
}

"PARTIDOS DE 1a CRUZADOS CON UNDERSTAT: " + $filas.Count + "   (sin cruce: " + $sinCruce + ")"
"AUDITORIA DE NUESTROS RESULTADOS: " + $discrepancias.Count + " discrepancias"
foreach ($x in $discrepancias) { "   " + $x }
""
$val = @($filas | Where-Object { $_.Valido })
"Con al menos $PartidosMinimos partidos previos de cada equipo: " + $val.Count
$conLae = @($val | Where-Object { $_.LaeFav })
"  ... de ellos con porcentajes LAE: " + $conLae.Count
""
if ($conLae.Count -gt 0) {
  $aA = @($conLae | Where-Object { $_.LaeFav -eq $_.Real }).Count
  $aB = @($conLae | Where-Object { $_.B -eq $_.Real }).Count
  "A) favorito de LAE:           " + (Pct $aA $conLae.Count)
  "B) mejor diferencia de xG:    " + (Pct $aB $conLae.Count) + "   (nunca predice X)"
  $acu = @($conLae | Where-Object { $_.LaeFav -eq $_.B })
  $dis = @($conLae | Where-Object { $_.LaeFav -ne $_.B })
  "  Coinciden A y B:            " + $acu.Count + " partidos; aciertan " + (Pct @($acu | Where-Object { $_.B -eq $_.Real }).Count $acu.Count)
  "  Discrepan A y B:            " + $dis.Count + " partidos"
  "     gana A (LAE):            " + @($dis | Where-Object { $_.LaeFav -eq $_.Real }).Count
  "     gana B (xG):             " + @($dis | Where-Object { $_.B -eq $_.Real }).Count
  "     ninguno (sale otro):     " + @($dis | Where-Object { $_.LaeFav -ne $_.Real -and $_.B -ne $_.Real }).Count
  ""
  "Empates en estos partidos:    " + (Pct @($conLae | Where-Object { $_.Real -eq 'X' }).Count $conLae.Count) + "  (B no puede acertar ninguno)"
}
