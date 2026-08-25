#!/usr/bin/env bash
# ── Quiniela IA · construir la app (versión portable) ──────────────────
# Hace exactamente lo mismo que construir.ps1, pero corre en Linux y macOS.
# Es la que usan las rutinas de la nube; en Windows sirve cualquiera de las dos.
#
# Uso:
#   bash construir.sh
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
PLANTILLA="$DIR/plantilla.html"
SALIDA="$DIR/index.html"
MARCADOR='__JORNADAS__'

[ -f "$PLANTILLA" ] && grep -q "$MARCADOR" "$PLANTILLA" \
  || { echo "ERROR: falta plantilla.html o su marcador $MARCADOR" >&2; exit 1; }

# Orden: temporada descendente y, dentro de ella, jornada descendente.
# Los nombres son jNN_YY-YY.json, así que basta con ordenar por texto.
mapfile -t FICHEROS < <(ls "$DIR"/data/j*.json 2>/dev/null | sort -t_ -k2,2r -k1,1r)
[ "${#FICHEROS[@]}" -gt 0 ] || { echo "ERROR: no hay data/jXX_YY-YY.json" >&2; exit 1; }

TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

printf '[' > "$TMP"
PRIMERO=1
for f in "${FICHEROS[@]}"; do
  # Si el JSON está roto, mejor fallar aquí que en el navegador
  python3 -c "import json,sys; json.load(open(sys.argv[1],encoding='utf-8'))" "$f" 2>/dev/null \
    || node -e "JSON.parse(require('fs').readFileSync(process.argv[1],'utf8'))" "$f" 2>/dev/null \
    || echo "  (aviso: no se pudo validar $(basename "$f"), sigo igualmente)" >&2
  [ "$PRIMERO" -eq 1 ] || printf ',' >> "$TMP"
  PRIMERO=0
  # Sin el salto de línea final, para que el resultado sea idéntico al de construir.ps1
  printf '%s' "$(cat "$f")" >> "$TMP"
  echo "  + $(basename "$f")"
done
printf ']' >> "$TMP"

# awk en vez de sed: los datos llevan &, barras y acentos que sed interpretaría
awk -v datos="$TMP" -v marca="$MARCADOR" '
  {
    pos = index($0, marca)
    if (pos == 0) { print; next }
    printf "%s", substr($0, 1, pos - 1)
    primera = 1
    while ((getline linea < datos) > 0) {
      if (primera) { printf "%s", linea; primera = 0 } else printf "\n%s", linea
    }
    close(datos)
    print substr($0, pos + length(marca))
  }
' "$PLANTILLA" > "$SALIDA"

KB=$(( ( $(wc -c < "$SALIDA") + 1023 ) / 1024 ))
echo "OK -> index.html generado (${#FICHEROS[@]} jornadas, ${KB} KB)"
