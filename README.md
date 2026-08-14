# Quiniela IA

App de predicciones de La Quiniela española (boleto oficial LAE): 14 partidos
+ Pleno al 15, con pronóstico, % LAE reales, análisis y bajas de cada partido.

Sin Node, sin bundler, sin dependencias. Un HTML autocontenido, como el resto
de las apps del autor.

---

## Ficheros

| Fichero | Qué es |
|---|---|
| `plantilla.html` | **La app.** Aquí se toca el diseño y la lógica. Lleva el marcador `__JORNADAS__` donde se inyectan los datos. |
| `data/jXX_YY-YY.json` | Una jornada por fichero. Es lo único que hay que rellenar cada semana. |
| `construir.ps1` | Mete todos los JSON de `data/` dentro de `plantilla.html` → genera **`index-src.html`** (app completa, se abre con doble clic). |
| `build-secure.ps1` | Construye y cifra con AES-256 → genera **`index.html`**, que es lo que se publica. |
| `index-src.html` | Generado. No versionado. Es la app en claro, para probar en local. |
| `index.html` | Generado. Cifrado con contraseña. Es lo que va a GitHub Pages. |
| `referencia/` | El JSX monolítico original de Claude.ai, como histórico. |

---

## Flujo de cada jornada

1. En [eduardolosilla.es](https://www.eduardolosilla.es) coger los 15 partidos y los **% LAE**.
2. Buscar lesionados en futbolfantasy.com / jornadaperfecta.com.
3. Revisar clasificaciones en laliga.com + siguetuliga.com.
4. Copiar `data/j01_26-27.json` a `data/jXX_YY-YY.json` y rellenarlo.
5. Generar y probar en local:

```bash
powershell -ExecutionPolicy Bypass -File construir.ps1
```

6. Abrir `index-src.html` con doble clic y comprobar que todo está bien.
7. Cifrar y publicar:

```bash
powershell -ExecutionPolicy Bypass -File build-secure.ps1 -Password "TU_CLAVE"
```

8. Subir `index.html` al repo de GitHub Pages.

El selector de jornada de la cabecera aparece solo en cuanto hay más de un
JSON en `data/`, ordenadas de la más reciente a la más antigua. No hay que
tocar `plantilla.html` para añadir una jornada.

---

## Schema de `data/jXX_YY-YY.json`

```json
{
  "meta": {
    "jornada": 1,
    "temporada": "26/27",
    "fecha_cierre": "2026-08-15T16:00:00",
    "bote": 393561,
    "fuente": "eduardolosilla.es",
    "fecha_datos": "2026-08-14"
  },
  "contexto": {
    "alertas": ["⚠ ...", "🆕 ...", "🔽 ..."]
  },
  "partidos": [
    {
      "num": 1, "div": "1ª",
      "local": "Dep. Alavés", "local_emoji": "⚪", "local_nota": "",
      "visit": "Getafe",      "visit_emoji": "🔵", "visit_nota": "",
      "dia": "Sáb·19:30",
      "pred": "X",
      "p1": 38, "px": 37, "p2": 25,
      "lae_1": 40, "lae_x": 35, "lae_2": 25,
      "conf": "BAJA",
      "razon": "...",
      "bajas": "...",
      "alineaciones": {
        "actualizado": "2026-08-14",
        "local": [{ "n": "Antonio Sivera", "p": 95 }, { "n": "Nahuel Tenaglia", "p": 90 }],
        "visit": [{ "n": "David Soria", "p": 95 }, { "n": "Zaid Romero", "p": 90 }]
      },
      "suspendido": false,
      "urgente": false
    }
  ],
  "pleno": {
    "num": 15,
    "local": "RC Deportivo", "local_emoji": "🔵", "local_nota": "🆕 ASCENDIDO",
    "visit": "Elche CF",     "visit_emoji": "🟢", "visit_nota": "",
    "dia": "Lun·21:00",
    "pred_signo": "1",
    "pred_marcador": "1-0",
    "lae_p15_local": [7, 49, 37, 7],
    "lae_p15_visit": [24, 60, 14, 2],
    "razon": "...", "bajas": "...", "conf": "MEDIA"
  }
}
```

Notas del schema:

- `div` es `"1ª"` o `"2ª"`. El pleno no lleva `div`: la app le pone `"P15"`.
- `p1/px/p2` es el pronóstico propio (suma 100). `lae_1/lae_x/lae_2` es el
  reparto real de apuestas de LAE.
- `conf` es `"ALTA"`, `"MEDIA"` o `"BAJA"`.
- `lae_p15_local` / `lae_p15_visit` son los % de goles `[0, 1, 2, M]`.
- `alertas` que empiezan por `⚠` se pintan en ámbar; el resto en azul.
- `suspendido: true` pinta el borde en ámbar y añade el aviso de sorteo.
  `urgente: true` lo pinta en rojo con la etiqueta "PARTIDO CLAVE".
- `alineaciones` es **opcional** y sale siempre de las fichas de equipo de
  [futbolfantasy.com](https://www.futbolfantasy.com/laliga/equipos/alaves)
  (`/laliga/equipos/<equipo>`), donde cada jugador lleva su **% de
  titularidad**. Se copian todos los jugadores con porcentaje visible,
  **ordenados de mayor a menor**: la app pinta los 11 primeros como once
  probable y el resto bajo "Resto de la plantilla".
- Cada jugador es `{ "n": nombre, "p": porcentaje }`. También se admite un
  string suelto si no hay porcentaje (se pinta con "—").
- Si falta el campo, la app lo dice sola: "aún no publicadas" en 1ª, y
  "futbolfantasy solo publica alineaciones de Primera" en los partidos de 2ª.
  **Nunca rellenar a ojo** — mejor dejarlo fuera.

---

## Historial de jornadas

| Jornada | Temporada | Notas |
|---|---|---|
| J59 | 25/26 | Primera versión con % LAE (solo en Claude.ai) |
| J63 | 25/26 | Barça campeón, Girona+Mallorca en descenso (solo en Claude.ai) |
| J64 | 25/26 | Última jornada, descenso activo (solo en Claude.ai) |
| J1 | 26/27 | Racing+Deportivo+Málaga suben · **primera en este repo** |

---

## Pendiente

- Añadir las jornadas 59, 63 y 64 de 25/26 como JSON (están en los artifacts
  de Claude.ai).
- Crear el repo de GitHub Pages y publicar `index.html`.
- Iconos + `manifest.json` + `sw.js` para instalarla como PWA en el móvil,
  igual que ALQUILER y RetailSite.
- Chips de clasificación (`local_pos` / `local_pts`): el schema los admite
  pero la app todavía no los pinta.
