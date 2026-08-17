# ── Quiniela IA · generar iconos de la PWA ─────────────────────────────
# Genera icons\*.png a partir de nada: fondo verde y un "1X2" centrado.
# Solo hay que volver a ejecutarlo si se cambia el diseño del icono.
#
# Uso:
#   powershell -ExecutionPolicy Bypass -File gen-icons.ps1
Add-Type -AssemblyName System.Drawing

function New-Icon([int]$size, [string]$path, [bool]$rounded, [double]$pad) {
  $bmp = New-Object System.Drawing.Bitmap $size, $size
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
  $g.Clear([System.Drawing.Color]::Transparent)

  # Verde #16a34a, el mismo de la marca en el resto de las apps
  $bg = [System.Drawing.Color]::FromArgb(255, 22, 163, 74)
  $brush = New-Object System.Drawing.SolidBrush $bg

  if ($rounded) {
    $r = $size * 0.22
    $forma = New-Object System.Drawing.Drawing2D.GraphicsPath
    $d = $r * 2
    $forma.AddArc(0, 0, $d, $d, 180, 90)
    $forma.AddArc($size - $d, 0, $d, $d, 270, 90)
    $forma.AddArc($size - $d, $size - $d, $d, $d, 0, 90)
    $forma.AddArc(0, $size - $d, $d, $d, 90, 90)
    $forma.CloseFigure()
    $g.FillPath($brush, $forma)
  } else {
    $g.FillRectangle($brush, 0, 0, $size, $size)
  }

  # "1X2" centrado, escalado al hueco que dejan los margenes
  $inner = $size * (1 - $pad * 2)
  $fuente = New-Object System.Drawing.Font("Segoe UI", ($inner * 0.34), [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
  $blanco = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::White)
  $fmt = New-Object System.Drawing.StringFormat
  $fmt.Alignment = [System.Drawing.StringAlignment]::Center
  $fmt.LineAlignment = [System.Drawing.StringAlignment]::Center
  $caja = New-Object System.Drawing.RectangleF ($size * $pad), ($size * $pad), $inner, $inner
  $g.DrawString("1X2", $fuente, $blanco, $caja, $fmt)

  $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
  $fuente.Dispose(); $blanco.Dispose(); $brush.Dispose()
  $g.Dispose(); $bmp.Dispose()
}

$dir = Join-Path $PSScriptRoot "icons"
New-Item -ItemType Directory -Force -Path $dir | Out-Null

New-Icon -size 512 -path (Join-Path $dir "icon-512.png")          -rounded $true  -pad 0.10
New-Icon -size 512 -path (Join-Path $dir "icon-512-maskable.png") -rounded $false -pad 0.20
New-Icon -size 192 -path (Join-Path $dir "icon-192.png")          -rounded $true  -pad 0.10
New-Icon -size 180 -path (Join-Path $dir "apple-touch-icon.png")  -rounded $false -pad 0.12
New-Icon -size 32  -path (Join-Path $dir "favicon-32.png")        -rounded $true  -pad 0.06

Write-Host "Iconos generados en $dir"
