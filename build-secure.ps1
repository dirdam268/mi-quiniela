# ── Quiniela IA · build cifrado para GitHub Pages ──────────────────────
# Regenera index-src.html con construir.ps1 y lo cifra con AES-256 en
# index.html, protegido por contraseña. index.html es lo que se publica.
#
# Uso:
#   powershell -ExecutionPolicy Bypass -File build-secure.ps1 -Password "TU_CLAVE"
#   powershell -ExecutionPolicy Bypass -File build-secure.ps1 -Password "TU_CLAVE" -SinConstruir
param(
  [Parameter(Mandatory=$true)][string]$Password,
  [switch]$SinConstruir,
  [string]$Src = "index-src.html",
  [string]$Out = "index.html"
)
$ErrorActionPreference = 'Stop'
$dir = $PSScriptRoot

# 0) Regenerar index-src.html desde plantilla.html + data\*.json
if (-not $SinConstruir) {
  & (Join-Path $dir "construir.ps1")
}

$srcPath = Join-Path $dir $Src
if (-not (Test-Path $srcPath)) { throw "No existe $Src. Ejecuta construir.ps1 primero." }

# 1) Leer la app en claro y anteponer un sello para verificar el descifrado
$plainBytes = [System.IO.File]::ReadAllBytes($srcPath)
$sentinel = [System.Text.Encoding]::UTF8.GetBytes("QNL_OK|")
$data = New-Object byte[] ($sentinel.Length + $plainBytes.Length)
[Array]::Copy($sentinel, 0, $data, 0, $sentinel.Length)
[Array]::Copy($plainBytes, 0, $data, $sentinel.Length, $plainBytes.Length)

# 2) Derivar clave (PBKDF2-SHA256) y cifrar (AES-256-CBC)
$rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
$salt = New-Object byte[] 16; $rng.GetBytes($salt)
$iv   = New-Object byte[] 16; $rng.GetBytes($iv)
$iter = 100000
$kdf = New-Object System.Security.Cryptography.Rfc2898DeriveBytes($Password, $salt, $iter, [System.Security.Cryptography.HashAlgorithmName]::SHA256)
$key = $kdf.GetBytes(32)
$aes = [System.Security.Cryptography.Aes]::Create()
$aes.KeySize = 256; $aes.Mode = 'CBC'; $aes.Padding = 'PKCS7'; $aes.Key = $key; $aes.IV = $iv
$encryptor = $aes.CreateEncryptor()
$ct = $encryptor.TransformFinalBlock($data, 0, $data.Length)

$payload = @{
  v = 1; iter = $iter
  salt = [Convert]::ToBase64String($salt)
  iv   = [Convert]::ToBase64String($iv)
  ct   = [Convert]::ToBase64String($ct)
} | ConvertTo-Json -Compress

# 3) Pantalla de acceso (descifra en el navegador con Web Crypto)
$gate = @'
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<title>Quiniela IA</title>
<meta name="theme-color" content="#09090f">
<meta name="mobile-web-app-capable" content="yes">
<meta name="apple-mobile-web-app-capable" content="yes">
<meta name="apple-mobile-web-app-title" content="Quiniela IA">
<style>
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body { font-family: system-ui, -apple-system, sans-serif; background: #09090f; color: #e0e0f0; min-height: 100vh; display: flex; align-items: center; justify-content: center; padding: 20px; }
  .gate { background: #111118; border: 1px solid #1a1a28; padding: 32px 28px; width: 100%; max-width: 380px; text-align: center; }
  .lock { font-size: 40px; margin-bottom: 14px; }
  .logo { font-weight: 900; font-size: 26px; letter-spacing: 0.04em; color: #e8ff00; margin-bottom: 4px; }
  .sub { font-family: monospace; font-size: 11px; color: #555577; letter-spacing: 0.12em; text-transform: uppercase; margin-bottom: 22px; }
  input { width: 100%; border: 1px solid #222244; background: #09090f; color: #e0e0f0; padding: 12px 14px; font-size: 16px; outline: none; margin-bottom: 12px; }
  input:focus { border-color: #e8ff00; }
  button { width: 100%; background: #e8ff00; border: none; color: #09090f; padding: 12px; font-weight: 800; font-size: 15px; cursor: pointer; text-transform: uppercase; letter-spacing: 0.06em; }
  button:disabled { opacity: 0.5; cursor: default; }
  .err { color: #ff4466; font-size: 13px; font-weight: 600; margin-top: 12px; min-height: 18px; }
  .recover { margin-top: 18px; font-size: 12px; color: #555577; }
  .recover a { color: #44aaff; font-weight: 600; text-decoration: none; }
</style>
</head>
<body>
<div class="gate">
  <div class="lock">&#128274;</div>
  <div class="logo">QUINIELA IA</div>
  <div class="sub">Acceso privado</div>
  <input id="pw" type="password" placeholder="Contrase&ntilde;a" autocomplete="current-password" autofocus>
  <button id="go">Entrar</button>
  <div class="err" id="err"></div>
  <div class="recover">&iquest;Olvidaste la contrase&ntilde;a?<br><a href="mailto:bordetass@gmail.com?subject=Acceso%20Quiniela%20IA">Escribe a bordetass@gmail.com</a></div>
</div>
<script>
const PAYLOAD = __PAYLOAD__;
const b64 = s => Uint8Array.from(atob(s), c => c.charCodeAt(0));

async function decryptApp(password) {
  const salt = b64(PAYLOAD.salt), iv = b64(PAYLOAD.iv), ct = b64(PAYLOAD.ct);
  const km = await crypto.subtle.importKey('raw', new TextEncoder().encode(password), 'PBKDF2', false, ['deriveKey']);
  const key = await crypto.subtle.deriveKey(
    { name: 'PBKDF2', salt, iterations: PAYLOAD.iter, hash: 'SHA-256' },
    km, { name: 'AES-CBC', length: 256 }, false, ['decrypt']
  );
  const buf = await crypto.subtle.decrypt({ name: 'AES-CBC', iv }, key, ct);
  const text = new TextDecoder().decode(buf);
  if (!text.startsWith('QNL_OK|')) throw new Error('sello');
  return text.slice(7);
}

async function enter() {
  const btn = document.getElementById('go');
  const err = document.getElementById('err');
  const pw = document.getElementById('pw').value;
  if (!pw) { err.textContent = 'Introduce la contrasena.'; return; }
  btn.disabled = true; err.textContent = 'Descifrando...';
  try {
    const html = await decryptApp(pw);
    // Recordar en este dispositivo: solo se pide la primera vez
    try { localStorage.setItem('qnl_pw', pw); } catch(_) {}
    document.open(); document.write(html); document.close();
  } catch (e) {
    try { localStorage.removeItem('qnl_pw'); } catch(_) {}
    err.textContent = 'Contrasena incorrecta.';
    btn.disabled = false;
  }
}

document.getElementById('go').addEventListener('click', enter);
document.getElementById('pw').addEventListener('keydown', e => { if (e.key === 'Enter') enter(); });

// Si ya se valido antes en este dispositivo, entrar directo sin preguntar
const saved = (() => { try { return localStorage.getItem('qnl_pw'); } catch(_) { return null; } })();
if (saved) {
  document.getElementById('pw').value = saved;
  enter();
}
</script>
</body>
</html>
'@

$gate = $gate.Replace('__PAYLOAD__', $payload)
$outPath = Join-Path $dir $Out
$outDir = Split-Path $outPath -Parent
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Force -Path $outDir | Out-Null }
[System.IO.File]::WriteAllText($outPath, $gate, (New-Object System.Text.UTF8Encoding($false)))
Write-Host ("OK -> {0} generado. Datos cifrados: {1} KB" -f $Out, [math]::Round($ct.Length/1024))
