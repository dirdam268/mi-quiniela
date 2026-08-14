# CLAUDE.md — Contexto para Claude Code

## El proyecto

App de predicciones de La Quiniela (14 partidos + Pleno al 15) con % LAE
reales. Vanilla JS, sin frameworks, sin bundler, sin dependencias. Nació como
artifact React en Claude.ai (ver `referencia/`) y se portó a HTML plano para
encajar con el resto de apps del autor.

## Regla número uno

**NO INVENTAR DATOS.** Los pronósticos, los % LAE, los lesionados y las
clasificaciones vienen de fuentes reales (eduardolosilla.es, futbolfantasy.com,
jornadaperfecta.com, laliga.com). Si un dato no está confirmado, se pone
`"Sin datos confirmados"` — nunca un número inventado. Los % LAE son *el* dato
diferencial de esta app: si están mal, la app no vale nada.

Esto vale por partida doble para las **alineaciones**. La fuente es siempre
futbolfantasy.com, en concreto las fichas de equipo, que dan el **% de
titularidad de cada jugador**: `/laliga/equipos/<equipo>` para Primera y
`/laliga2/equipos/<equipo>` para Segunda. Se copia lo que publica la página y
solo eso, ordenado de mayor a menor porcentaje: la app enseña los 11 primeros
como once probable y el resto aparte. **No se recorta la lista a 11 a mano ni se
completa un hueco a ojo** — si la página solo da 7 jugadores, se ponen 7. Si un
equipo no tiene porcentajes todavía, se omite el campo y la app lo dice sola.

## Qué fichero se toca

- **Diseño y lógica** → `plantilla.html`
- **Datos de una jornada** → `data/jXX_YY-YY.json`
- **NUNCA** editar `index-src.html` ni `index.html`: los dos son generados.
  `index-src.html` lo produce `construir.ps1`; `index.html` lo produce
  `build-secure.ps1` y está cifrado.

## Comandos

```bash
powershell -ExecutionPolicy Bypass -File construir.ps1
```
```bash
powershell -ExecutionPolicy Bypass -File build-secure.ps1 -Password "TU_CLAVE"
```

Los `.ps1` no arrancan con `.\script.ps1` en esta máquina por la
ExecutionPolicy: usar siempre la forma larga de arriba.

**La contraseña se pide al autor.** Nunca inventarla ni dejarla escrita en
ningún fichero del repo.

## Convenciones de estilo

- **Idioma UI y comentarios**: español (informal, directo)
- **JS**: plano, comillas simples, sin frameworks, sin librerías externas
- **CSS**: variables en `:root`, clases con nombre en español, nada de utilidades
- **Tema**: claro fijo, fondo blanco. No hay modo oscuro y no se pide
- **Cambios pequeños**: preferir edición puntual a reescribir el fichero entero
- **Respuestas al autor**: concisas. Nada de "voy a hacer X, Y y Z" — hazlo y ya

## Paleta

```
BG #ffffff · SFC2 #f8fafc · BRD #e5e7eb · TXT #111827 · MUT #6b7280
pred 1 #16a34a · X #d97706 · 2 #dc2626
1ª div #1d4ed8 · 2ª div #0f766e · Pleno #be185d
accent #1d4ed8 · warn #b45309 · danger #dc2626
```

Los colores de confianza reutilizan los de predicción:
ALTA = verde, MEDIA = ámbar, BAJA = gris muted.

La versión oscura original está en el historial de git, por si hiciera falta.

## Detalles de implementación a tener en cuenta

- El HTML se regenera entero en cada `render()`. Por eso **todos los eventos
  son delegados** sobre `#app`. Si añades un control nuevo, engánchalo en el
  listener delegado, no con `addEventListener` sobre el elemento.
- Los **dobles se calculan solos** en `calcDobles()` y viven en la variable
  `DOBLES`, que `render()` recalcula antes de pintar nada. No se guardan en el
  JSON. Si tocas el pronóstico de un partido, el doble puede moverse solo.
- Hay una **tarea programada** los jueves a las 9:00 (`quiniela-datos-semanales`)
  que prepara el JSON de la jornada y ejecuta `construir.ps1`. El cifrado y la
  subida los hace Enrique a mano, porque hacen falta su contraseña y su cuenta.
- El pleno se pinta con el mismo `tplPartido()` que los demás, marcándolo con
  `div: 'P15'`. Si tocas esa función, comprueba las dos ramas.
- `nombreCorto()` quita siglas de club (FC, CD, RCD, SD, UD…) para el boleto
  compacto. **"Real" no está en la lista a propósito**, para no convertir
  "Real Sociedad" en "Sociedad".
- El botón de copiar tiene respaldo con `execCommand('copy')` porque
  `navigator.clipboard` no existe en `file://` en algunos navegadores.
- `construir.ps1` valida cada JSON con `ConvertFrom-Json` antes de inyectarlo:
  si un fichero está roto, falla ahí y no en el navegador.
- La pantalla de acceso cifrada guarda la clave en `localStorage.qnl_pw`, así
  que **solo se pide una vez por dispositivo**. No cambiar ese comportamiento.
- El sello de verificación del descifrado es `QNL_OK|` (7 bytes). Si se cambia,
  hay que cambiarlo en los dos sitios de `build-secure.ps1`.

## Cosas que NO hacer

- No meter React, Vue, Vite ni ningún bundler. **En esta máquina no hay Node
  instalado y no se quiere instalar.**
- No cargar librerías por CDN: la app tiene que funcionar sin conexión y
  cifrada en un único fichero.
- No usar `fetch()` para los JSON de `data/`: no funciona en `file://` y rompe
  el cifrado en un solo fichero. Los datos se inyectan en build.
- No cambiar el idioma de la UI.
