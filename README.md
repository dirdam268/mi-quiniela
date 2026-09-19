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
| `construir.ps1` | Mete todos los JSON de `data/` dentro de `plantilla.html` → genera **`index.html`**. |
| `index.html` | Generado, pero **sí se versiona**: es lo que sirve GitHub Pages. Se abre igual con doble clic. |
| `referencia/` | El JSX monolítico original de Claude.ai, como histórico. |

Además: `manifest.json`, `sw.js` e `icons/` la convierten en **PWA instalable**.
Los iconos los genera `gen-icons.ps1` y solo hay que volver a ejecutarlo si se
cambia el diseño. El service worker va a **red primero** al abrir la app, así
que la jornada nueva se ve en cuanto se publica; la última copia guardada solo
entra en juego si no hay conexión.

La app se publica **abierta, sin contraseña**, en
<https://dirdam268.github.io/mi-quiniela>. Son pronósticos de fútbol, no hay
nada que proteger. Si algún día hiciera falta cifrarla, el `build-secure.ps1`
que hacía ese trabajo (AES-256 + PBKDF2, pantalla de acceso en el navegador)
está en el historial de git: `git show d708ef2:build-secure.ps1`.

---

## Actualización automática

No hay que hacer nada cada semana: una **rutina en la nube** mantiene la app al
día por su cuenta, sin necesidad de tener ningún ordenador encendido.

**Martes a las 15:00**, de una sola pasada:

1. Cierra la jornada terminada: rellena los resultados del escrutinio oficial y
   recalcula los aciertos y el acumulado histórico.
2. Prepara la jornada siguiente: % LAE, alineaciones, bajas y pronósticos.
3. Reconstruye, hace commit y publica.
4. Manda un informe con las dos mitades: en qué se falló la semana pasada y qué
   boleto propone para la siguiente.

El martes no es casual: muchas jornadas terminan el lunes por la noche, y es el
primer día en que el escrutinio está completo.

Se gestiona en <https://claude.ai/code/routines>. Corre en Linux, así que usa
`construir.sh`. El cron está en UTC (`0 13 * * 2`): al cambiar la hora en
octubre habrá que pasarlo a `0 14 * * 2` para mantener las 15:00 locales.

El flujo manual de abajo sigue funcionando, por si hace falta adelantarse o
corregir algo.

## Flujo de cada jornada

1. En [eduardolosilla.es](https://www.eduardolosilla.es) coger los 15 partidos y los **% LAE**.
2. Buscar lesionados en futbolfantasy.com / jornadaperfecta.com.
3. Revisar clasificaciones en laliga.com + siguetuliga.com.
4. Copiar `data/j01_26-27.json` a `data/jXX_YY-YY.json` y rellenarlo.
5. Generar la app:

```bash
powershell -ExecutionPolicy Bypass -File construir.ps1
```

6. Abrir `index.html` con doble clic y comprobar que todo está bien.
7. Publicar:

```bash
git add -A && git commit -m "Jornada XX" && git push
```

GitHub Pages tarda un minuto en refrescar.

El selector de jornada de la cabecera aparece solo en cuanto hay más de un
JSON en `data/`, ordenadas de la más reciente a la más antigua. No hay que
tocar `plantilla.html` para añadir una jornada.

---

## Botón «Actualizar jornada»

En la cabecera hay un botón que trae el boleto de la jornada abierta
directamente desde eduardolosilla, **sin depender de nadie**. Tarda unos
segundos.

Cómo funciona: eduardolosilla no permite CORS, así que se lee a través de
`https://r.jina.ai/<url>` con la cabecera `x-return-format: html`, el mismo
truco que usa la app del equipo con la RFFM. Del HTML se sacan las 15 filas de
partido y, de los **cuatro** bloques de porcentajes que trae cada uno
(% Jugados · **% LAE** · % Probables · % Jugados), se coge el segundo.

**Validación antes de tocar nada:** 15 partidos, 60 bloques y cada trío sumando
entre 95 y 105. Si algo falla, lanza un error, lo dice y **no modifica la app**.
Más vale quedarse sin jornada que pintar porcentajes falsos.

Lo que trae y lo que no:

| Sí | No |
|---|---|
| Los 15 partidos con día y hora | El análisis de cada partido |
| Los % LAE reales | Las alineaciones y las bajas |
| El pronóstico (favorito de LAE) y los 3 dobles | La división de cada partido (salen todos como «Boleto») |
| El marcador más apostado del Pleno | El bote y la hora de cierre |

La jornada traída **vive en el `localStorage` de ese dispositivo**: la página es
estática y no puede escribir en el repositorio. Si la jornada ya está preparada
a mano en `data/`, esa manda y el botón lo dice.

## Instalar en el móvil o el ordenador

Se instala desde <https://dirdam268.github.io/mi-quiniela>.

- **Android (Chrome)**: menú ⋮ → *Instalar aplicación* / *Añadir a pantalla de inicio*.
- **iPhone / iPad (Safari)**: botón compartir → *Añadir a pantalla de inicio*.
  Tiene que ser Safari; desde Chrome en iOS no aparece la opción.
- **Windows (Chrome / Edge)**: icono de instalar en la barra de direcciones, o
  menú ⋮ → *Instalar Quiniela IA*.

Queda con su icono propio, sin barra de navegador, y funciona sin conexión con
los datos de la última vez que se abrió.

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
      "resultado": "1",
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
    "razon": "...", "bajas": "...", "conf": "MEDIA",
    "resultado_marcador": "1-0"
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
  futbolfantasy.com, donde cada jugador lleva su **% de titularidad**:
  - 1ª: `https://www.futbolfantasy.com/laliga/equipos/<equipo>`
  - 2ª: `https://www.futbolfantasy.com/laliga2/equipos/<equipo>`

  Se copian todos los jugadores con porcentaje visible, **ordenados de mayor a
  menor**: la app pinta los 11 primeros como once probable y el resto bajo
  "Resto de la plantilla".
- Cada jugador es `{ "n": nombre, "p": porcentaje }`. También se admite un
  string suelto si no hay porcentaje (se pinta con "—").
- Si falta el campo, la app muestra sola "aún no publicadas" apuntando a la
  sección que corresponda. **Nunca rellenar a ojo** — mejor dejarlo fuera.
- `meta.actualizado` (opcional, `YYYY-MM-DD`) es el sello "↻ Actualizado" de la
  cabecera. Si falta, se usa `meta.fecha_datos`.
- `meta.provisional: true` marca una jornada publicada **antes de que salgan
  los % LAE**, con pronóstico estimado a mano. La etiqueta de la jornada lleva
  «PROVISIONAL» en el selector, la cabecera y el boleto. En ese caso los campos
  `lae_1`/`lae_x`/`lae_2` **se omiten** (nunca se rellenan con números
  inventados): el panel del partido dice «% LAE pendientes» y los dobles se
  calculan con los porcentajes propios. Cuando salgan los % reales, se rehace
  la jornada y se quita la marca.

## Dobles

La app elige los dobles **sola**, no se ponen en el JSON. Dobla los `N_DOBLES`
partidos donde **el favorito de LAE es más débil**, que son los que de verdad
están abiertos, y cubre con el segundo signo más apostado. Los partidos
suspendidos quedan fuera: su resultado sale por sorteo.

`N_DOBLES` es **3**, elegido probando el sistema contra las jornadas 1 a 4
(45 partidos reales):

| Dobles | Aciertos | Apuestas |
|---|---|---|
| 0 o 1 | 51% | 1-2 |
| 2 | 53% | 4 |
| **3** | **58%** | **8** |
| 4 | 58% | 16 |
| 5 | 60% | 32 |

Tres dobles es donde está el salto; el cuarto no aporta nada y el quinto cuesta
32 apuestas por un punto. Si quieres gastar menos, baja la constante `N_DOBLES`
al principio del `<script>` de `plantilla.html`: con 2 vuelves a 4 apuestas.

## Resultados y aciertos

`resultado` (`"1"`, `"X"` o `"2"`) en cada partido y `resultado_marcador` en el
pleno son **opcionales**: se rellenan el lunes, cuando ya se ha jugado. Fuente:
el escrutinio de eduardolosilla,
`https://www.eduardolosilla.es/quiniela/ayudas/escrutinio/jornada_XX`.

Con solo algunos rellenos, la app trabaja en modo provisional y lo dice. En
cuanto hay resultados aparece:

- Un panel arriba con los **aciertos**, en verde si ≥71%, ámbar si ≥50%, rojo
  por debajo.
- La comparación **boleto real vs boleto simple**, para saber si los dobles han
  servido de algo o han sido dinero tirado.
- Cada tarjeta con borde verde o rojo, el resultado real y, si se falló, qué se
  había pronosticado. Un ✓/✗ en cada línea del boleto.
- El **acumulado histórico** en cuanto haya dos jornadas o más con resultados.

Un doble cuenta como acierto si el resultado real es cualquiera de sus dos
signos. Los partidos sin `resultado` no cuentan ni a favor ni en contra.

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
