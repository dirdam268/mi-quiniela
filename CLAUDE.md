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

## Lo que dicen los datos (J1 a J12, 126 partidos con % LAE)

Auditoría del 13/10/2026. **Sustituye a la versión anterior** (J1-J4, 45
partidos), cuyas reglas resultaron ser ruido de muestra pequeña. Cualquier
cifra de aquí lleva su margen de error: con tan pocos partidos, una diferencia
de unos puntos no significa nada.

**Qué es «% LAE».** Según la propia web de eduardolosilla, es el porcentaje de
apuestas **reales del público** validadas en los terminales oficiales,
actualizado una vez al día a primera hora. **No es una probabilidad calculada ni
la opinión de ningún experto.** Seguir al favorito de LAE es seguir a la
mayoría de los apostantes.

**Resultado principal: no hay ventaja medible sobre el mercado.**
- El favorito de LAE acierta el **53% (±9 puntos)**; nuestro criterio, el **52%
  (±9)**. Indistinguibles. (Cifras recalculadas el 18/10/2026 tras corregir
  J2 P1 Athletic-Sevilla, que teníamos mal: los 140 resultados de J1-J12 están
  ya cruzados uno a uno con la casilla oficial del escrutinio.)
- El mercado está razonablemente calibrado: los favoritos del 75% o más aciertan
  el 80%; los de menos del 45%, el 42%.
- No hay sesgo explotable: LAE da de media un 24,2% al empate y salió el 25,4%;
  da un 48,7% al local y salió el 47,6%.

**Reglas de la versión anterior que se retiran** (no las vuelvas a aplicar ni a
meter en prompts):

| Regla antigua | En qué se apoyaba | Con los datos de hoy |
|---|---|---|
| «La Segunda es el agujero, 29%» | 6 de 21 | **48% ±13** (n=54), en línea con 1ª (54% ±14) |
| «Hay sesgo al local, da más peso a la X» | 9 de 14 fallos | Sin sesgo (ver arriba) |
| «Desviarse de LAE falla (0 de 3)» | n=3 | Nada que concluir |
| «3 dobles dan un 58%» | 45 partidos, ajustado a posteriori | Es aritmética, no un hallazgo: cada doble suma ~un tercio de acierto en ese partido a cambio de pagar el doble |
| «`conf` está calibrada (64/56/25)» | n=45 | No se ha vuelto a comprobar: tratarla como no demostrada |

**Qué se hace por defecto.** `pred` = el signo con más % de LAE. No porque esté
demostrado que sea mejor, sino porque es lo más simple y no hay evidencia de que
desviarse mejore. Si te desvías, que sea por un hecho concreto y verificable
(una baja confirmada después de publicarse las cifras) y dilo en la `razon`.

**Los dobles** se calculan solos (ver `calcDobles()`): son pagar más por acertar
más. Compáralos siempre **por apuesta**, nunca una apuesta contra ocho. La app
arranca **sin dobles** porque Enrique lo pidió.

**Expectativas reales:**
- **12 aciertos** son ≈2% por jornada sin dobles y ≈8% con tres. Ninguna jornada
  pasó de 9 aciertos, ni con una apuesta ni con tres dobles; y 10 es el mínimo
  que paga (6,30 € en la J7).
- **El juego devuelve poco.** En la J7, las categorías de 10 a 14 aciertos
  sumaron ≈594.000 € de 1.323.190 € recaudados (≈45%). Es una sola jornada, pero
  el orden de magnitud es el que es: juego de esperanza negativa, presupuesto
  fijo.
- **El Pleno al 15 no es señal.** Con desglose por equipo, acertar el marcador
  más apostado ronda el 25%; fallar 10 seguidas pasa una de cada diez veces.

**Regla de método:** no se cambia de método ni se escribe una regla nueva con
menos de **300 partidos** y sin indicar `n` y el margen. La app muestra el
histórico separado por método (`meta.metodo`: `propio`, `lae`; `provisional` →
`estimado`) y cuenta cuántos partidos llevamos de los 300.

**Pendiente (de la auditoría, aún sin hacer):**
1. Guardar el escrutinio de cada jornada (acertantes y premio por categoría)
   para medir el retorno real y probar si elegir lo que elige la mayoría reduce
   lo que se cobra por acierto.
2. Pasar la parte determinista (partidos, % LAE, resultados) a GitHub Actions:
   ese entorno no tiene el cortafuegos de la nube de Claude y quitaría la
   dependencia de pedir «actualizar».
3. Validaciones automáticas al construir: JSON sin claves duplicadas,
   porcentajes que sumen ~100, signos válidos y marcador del Pleno con formato
   `[0-2M]-[0-2M]`; y guardar una copia del dato crudo de cada fuente.
4. El prompt de la rutina de la nube (pausada) todavía lleva las reglas
   retiradas: reescribirlo antes de reactivarla.

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
- **Ojo con las jornadas entre semana.** La J5 fue de Champions (8-9 de
  septiembre) y cerró antes del martes siguiente, así que nunca se preparó. La
  J6 cerró el viernes 11 a las 20:00 y tampoco llegó a tiempo. No hay datos de
  la J5 en `data/` a propósito: sin los % LAE de antes del cierre no se puede
  reconstruir sin hacer trampa. La J6 se publicó tarde, solo para seguir
  midiendo el sistema.
- Corre en Linux: usa `construir.sh`, **nunca** `construir.ps1`.
- **La rutina trabaja con las manos atadas** y hay que contar con ello:
  - El cortafuegos de salida del entorno bloquea `eduardolosilla.es`,
    `futbolfantasy.com`, `loteriasyapuestas.es` y otros. Solo le funciona la
    búsqueda web. Cuando eso pasa, tiene orden de **no hacer** esa parte y
    decirlo, nunca de reconstruir los datos a base de titulares.
  - El 25/08/2026 reconstruyó resultados a base de búsquedas web, y por eso se
    le prohibió en su prompt. OJO: se creyó que se había equivocado con el
    Athletic-Sevilla de la J2 (dio 2, nosotros pusimos 1), pero el escrutinio
    oficial (1-3, casilla 2) le da la razón: el error era nuestro y se corrigió
    el 18/10/2026. Lección: una lectura resumida por un modelo (WebFetch) no
    vale como verdad; el HTML oficial leído a mano, sí.
  - El `git push` desde la nube requiere que la Claude GitHub App tenga
    `dirdam268/mi-quiniela` en su lista de repos
    (<https://github.com/apps/claude/installations/select_target>). El conector
    de GitHub en claude.ai **no** basta: son permisos distintos.
- **ESTADO ACTUAL (12/09/2026): la rutina está PAUSADA.** Tres martes seguidos
  bloqueada por el cortafuegos, sin hacer nada. Se reactiva desde
  <https://claude.ai/code/routines> si algún día se abre la red del entorno.
- **Cómo se trabaja ahora, acordado con Enrique:** él pide «actualizar» desde
  Claude Code el jueves o el viernes, antes del cierre, y se hace todo desde
  aquí: cerrar la jornada anterior con el escrutinio, preparar la nueva,
  reconstruir y publicar. Sin recordatorios automáticos, lo pidió así. Si pide
  «actualizar» después del cierre, la jornada se publica igual pero marcada como
  tardía, solo para medir el sistema.
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
- **Botón «Actualizar jornada»** (`actualizarDesdeWeb` / `parsearQuiniela`):
  lee eduardolosilla a través de `r.jina.ai` porque no da CORS. Detalles que
  costaron encontrar y conviene no re-descubrir:
  - Cada partido trae **cuatro** tandas de porcentajes (Jugados, LAE, Probables
    y Jugados otra vez). **La buena es la segunda.** Coger otra da números que
    parecen correctos pero no lo son.
  - Los bloques son los **padres directos** de `.c-boleto-multiples-porcentajes__row`;
    buscarlos por clase pilla también contenedores de arriba (90 en vez de 60).
  - Los 14 primeros partidos vienen como `LOCAL - VISITANTE`, pero **el pleno
    separa los equipos en dos líneas**, sin guion.
  - El HTML del servidor (vía jina) trae 15 filas; la web en vivo renderiza 60
    porque Angular duplica bloques. Parsear siempre el de jina.
  - La validación (15 partidos, 60 bloques, tríos que sumen ~100) **ya evitó
    publicar datos mal parseados dos veces**. No quitarla ni relajarla.
  - Lo traído se guarda en `localStorage['quiniela_web_v1']` y las jornadas de
    `data/` siempre mandan sobre él.

## Cosas que NO hacer

- No meter React, Vue, Vite ni ningún bundler. **En esta máquina no hay Node
  instalado y no se quiere instalar.**
- No cargar librerías por CDN: la app tiene que funcionar sin conexión y
  cifrada en un único fichero.
- No usar `fetch()` para los JSON de `data/`: no funciona en `file://` y rompe
  el cifrado en un solo fichero. Los datos se inyectan en build.
- No cambiar el idioma de la UI.
