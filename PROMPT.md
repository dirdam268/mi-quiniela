# Prompt de análisis (QuinielaAI Engine, adaptado a lo que de verdad tenemos)

Este es el prompt del "QuinielaAI Engine" reescrito para los datos que existen.
Lo que el original pedía y **no hay** queda marcado como no disponible: se dice,
no se inventa. Úsalo al preparar cada jornada (el día "actualizar").

## Qué pedía el original y qué hay

| Pide | Hay | De dónde |
|---|---|---|
| Probabilidades 1X2 | % de apuestas LAE (no son probabilidades, es lo que juega el público) | eduardolosilla.es/quiniela |
| xG / xGA | Sí, **solo LaLiga** | Understat (`estadisticas.ps1`) |
| Forma reciente | Sí, últimos 5, **solo LaLiga** | Understat |
| Jugadores clave | Sí, **solo LaLiga**: xG/90 y xA/90 | Understat |
| Pases clave | Sí (`pc90` en el JSON), **solo LaLiga** | Understat |
| Presión | PPDA, **solo LaLiga** | Understat |
| Duelos aéreos | **No** | sin fuente abierta |
| Posesión | **No** | sin fuente abierta |
| Segunda, Liga F, Europa, selecciones | Solo % LAE y alineaciones (Primera/Segunda) | — |
| Alineaciones y bajas | Sí, % de titularidad | futbolfantasy.com |
| Bucle de aprendizaje | Sí, pero con límites (ver reglas) | `calcHistorico()` + `data/escrutinios.json` |

## Reglas que sustituyen a las del original

1. **Pronóstico por defecto = favorito de LAE.** Es lo único probado: acierta
   el 53% (±9) en 126 partidos y nuestro criterio, el 52% (±9). Nadie ha
   demostrado ventaja sobre eso.
2. **Se desvía del favorito solo con una razón concreta y comprobable**
   (baja confirmada de un titular clave, partido suspendido, etc.), y se escribe
   en `razon`. Nunca por intuición ni por estadística avanzada sola: en la
   prueba con 28 partidos de Primera, "gana el de mejor diferencia de xG"
   acertó 46% frente al 54% de LAE (±18 los dos: no concluyente, pero sin
   ventaja).
3. **No hay regla del 10% de empates ni de "fiabilidad del estadio".** Las
   reglas antiguas eran ruido de muestra pequeña. No se introducen ajustes
   automáticos antes de **300 partidos** medidos.
4. **Dobles: 0 por defecto.** Si el usuario pide 2 o 3, van a los partidos con
   el favorito más débil (`calcDobles()`); no a los "que pinten bien".
5. **Datos que faltan = se dicen.** `"bajas": "Sin datos confirmados"`, LAE
   pendiente = `provisional`. Prohibido reconstruir resultados o porcentajes
   de titulares de prensa o búsquedas.
6. **Los resultados salen del escrutinio oficial**, leído del HTML
   (`escrutinio.ps1`, casilla con clase `m-resultado`), nunca de un resumen
   hecho por un modelo. Un partido suspendido consta con 0-0 de relleno y la X.
7. **Aprendizaje honesto:** tras cada jornada se actualiza el histórico por
   método con su margen de error. Una racha corta no cambia el método.

## Salida (campos reales de `data/jNN_26-27.json`, no un JSON inventado)

Por partido: `pred` (1/X/2), `p1`/`px`/`p2` (suman ~100), `lae_1/x/2`,
`conf` (ALTA/MEDIA/BAJA), `razon` (una frase con el motivo real), `bajas`,
`alineaciones`. El bloque de xG/forma/jugadores lo pinta la app sola a partir
de `data/estadisticas_laliga.json` para los partidos de Primera; no se copia a
mano en el JSON de la jornada.

## Cómo refrescar las estadísticas

```
powershell -ExecutionPolicy Bypass -File estadisticas.ps1   # Understat -> data/estadisticas_laliga.json
powershell -ExecutionPolicy Bypass -File construir.ps1      # reconstruye index.html
powershell -ExecutionPolicy Bypass -File backtest.ps1       # ¿aporta algo el xG sobre LAE?
```
