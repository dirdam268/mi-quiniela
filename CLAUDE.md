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
- **NUNCA** editar `index.html` a mano: lo genera `construir.ps1` a partir de
  los dos anteriores. Sí se versiona, porque es lo que publica GitHub Pages.

## Comandos

```bash
powershell -ExecutionPolicy Bypass -File construir.ps1
```

Los `.ps1` no arrancan con `.\script.ps1` en esta máquina por la
ExecutionPolicy: usar siempre la forma larga de arriba.

## Publicación

Repo `dirdam268/mi-quiniela`, público, servido en
<https://dirdam268.github.io/mi-quiniela> desde la rama `main`.

**La app va sin contraseña, y es una decisión tomada a propósito.** Se valoró
cifrarla y se descartó: son pronósticos de fútbol, y un fichero cifrado en un
repo público se puede atacar offline sin límite, así que la contraseña acabaría
siendo más riesgo que protección. No volver a proponer cifrado salvo que Enrique
lo pida. El script que lo hacía sigue en el historial: `git show d708ef2:build-secure.ps1`.

## Lo que dicen los datos (jornadas 1 a 4, 45 partidos)

Medido, no opinado. Estas reglas salen del análisis del 05/09/2026 y **mandan
sobre cualquier intuición**:

**1. No apartarse del favorito de LAE.** Nos apartamos 3 veces y acertamos 0;
LAE habría acertado 2 de esas 3. Ahí está la diferencia entre nuestro 47% y el
51% de seguir ciegamente al mercado. El `pred` es **el signo con más % de LAE**.
Solo se puede desviar con un hecho concreto y verificable que el porcentaje no
recoja (una baja confirmada después, un equipo sin nada en juego), y hay que
decirlo en la `razon`. Nunca por olfato.

**2. La Segunda es el agujero: 29% de aciertos (6 de 21).** Pronosticamos el 1
en 17 de 21 partidos, y salió 1×7, X×8, 2×6 — un reparto casi uniforme. El
factor campo en Segunda vale mucho menos de lo que parece.

**3. Cuando el favorito de LAE no llega al 50%, acierta solo el 38%.** Y eso es
más de la mitad del boleto (24 de 45). Ahí no hay pronóstico que valga: es donde
tienen que ir los dobles, y por eso `calcDobles()` los elige por debilidad del
favorito y no por nuestro propio margen.

**4. La confianza sí está calibrada:** ALTA 64%, MEDIA 56%, BAJA 25%. El campo
`conf` funciona, mantenerlo honesto.

**5. Liga F es lo más predecible:** 4 de 4. Los porcentajes de LAE ahí son
extremos (84%, 88%) y se cumplen.

**Expectativa realista: 55-60%.** La quiniela es en su mayor parte azar; el
valor de esta app es ordenar la información y colocar bien los dobles, no
adivinar. No prometer más.

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
- Los aciertos se calculan en `calcAciertos()` / `calcHistorico()`. Solo cuentan
  los partidos con `resultado`, así que una jornada a medias sale como
  provisional. Un doble acierta si el resultado es cualquiera de sus dos signos.
- **Cuidado con `false || (undefined && x)`**: devuelve `undefined`, no `false`.
  Ya rompió una vez el marcado de partidos fallados. Por eso `acertado` pasa por
  `Boolean()` antes de compararse con `false`.
- Hay **una única rutina en la nube** que mantiene la app sola, sin depender del
  ordenador de Enrique: *Quiniela · revisión semanal (martes)*, los martes a las
  15:00 hora española. Cierra la jornada terminada (resultados + aciertos) y
  prepara la siguiente, todo de una pasada. Se gestiona en
  <https://claude.ai/code/routines>.
- **Martes a propósito**: muchas jornadas terminan el lunes por la noche, así
  que el martes es el primer día en que el escrutinio está completo. No moverlo
  antes sin motivo.
- Corre en Linux: usa `construir.sh`, **nunca** `construir.ps1`.
- **La rutina trabaja con las manos atadas** y hay que contar con ello:
  - El cortafuegos de salida del entorno bloquea `eduardolosilla.es`,
    `futbolfantasy.com`, `loteriasyapuestas.es` y otros. Solo le funciona la
    búsqueda web. Cuando eso pasa, tiene orden de **no hacer** esa parte y
    decirlo, nunca de reconstruir los datos a base de titulares.
  - El 25/08/2026 lo hizo y se equivocó: dio el Athletic-Sevilla de la J2 al 2
    cuando el escrutinio decía 1. De ahí la prohibición explícita en su prompt.
  - El `git push` desde la nube requiere que la Claude GitHub App tenga
    `dirdam268/mi-quiniela` en su lista de repos
    (<https://github.com/apps/claude/installations/select_target>). El conector
    de GitHub en claude.ai **no** basta: son permisos distintos.
- **Reparto de trabajo acordado con Enrique:** la rutina hace lo que puede y
  señala lo que no; cuando él abre Claude Code, se completa todo desde aquí,
  que sí llega a las fuentes.
- El cron está en **UTC** (`0 13 * * 2`). Con el horario de verano español
  (CEST) eso son las 15:00 locales; al cambiar la hora en octubre se disparará
  a las 14:00 salvo que se ajuste el cron a `0 14 * * 2`.
- El pleno se pinta con el mismo `tplPartido()` que los demás, marcándolo con
  `div: 'P15'`. Si tocas esa función, comprueba las dos ramas.
- `nombreCorto()` quita siglas de club (FC, CD, RCD, SD, UD…) para el boleto
  compacto. **"Real" no está en la lista a propósito**, para no convertir
  "Real Sociedad" en "Sociedad".
- El botón de copiar tiene respaldo con `execCommand('copy')` porque
  `navigator.clipboard` no existe en `file://` en algunos navegadores.
- `construir.ps1` valida cada JSON con `ConvertFrom-Json` antes de inyectarlo:
  si un fichero está roto, falla ahí y no en el navegador.
- El sello "↻ Actualizado" de la cabecera sale de `meta.actualizado`, con
  `meta.fecha_datos` como respaldo. Rellenarlo siempre al preparar una jornada.

## Cosas que NO hacer

- No meter React, Vue, Vite ni ningún bundler. **En esta máquina no hay Node
  instalado y no se quiere instalar.**
- No cargar librerías por CDN: la app tiene que funcionar sin conexión y
  cifrada en un único fichero.
- No usar `fetch()` para los JSON de `data/`: no funciona en `file://` y rompe
  el cifrado en un solo fichero. Los datos se inyectan en build.
- No cambiar el idioma de la UI.
