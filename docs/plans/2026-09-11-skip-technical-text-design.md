# Skip Technical Text — diseño

Fecha: 2026-09-11. Estado: implementado.

## Problema

Al leer texto técnico, el sintetizador pierde tiempo pronunciando URLs,
paths de directorios, código inline y hashes, que no aportan nada al oído.

## Decisiones

- **Modo**: reemplazo por placeholder corto (no omisión total), para
  mantener la coherencia de la frase. Ej: «Cloná https://… en /usr/…» →
  «Cloná enlace en directorio».
- **Qué se filtra**: URLs y emails; paths Unix/Windows y nombres de
  archivo con extensión conocida; código entre backticks, hashes hex
  largos y UUIDs; corridas de símbolos (`-->`, `###`, líneas `----`).
- **Localización**: placeholders en es/en/fr según el idioma que ya
  detecta `NLLanguageRecognizer`; fallback en inglés.
- **UI**: ítem con checkmark «Skip Technical Text» en el menú de la
  barra; persistido en `UserDefaults` (`skipTechnicalText`, default off).
  Aplica a la próxima lectura, no a la que está en curso.

## Arquitectura

- `Sources/SpeakRateCore/TextSanitizer.swift`: función pura
  `sanitize(_:language:)`, en un target de librería nuevo
  (`SpeakRateCore`) para poder testearla.
- `SpeechReader.speak()` sanitiza antes de guardar `currentText`, así el
  tracking de offset para el cambio de velocidad en vivo no se toca.
- Tests: `Tests/SpeakRateCoreTests/TextSanitizerTests.swift` (19 casos,
  incluye guardas de no-sobre-filtrado: texto normal y números/versiones
  quedan intactos).

## Orden de reglas (importa)

1. Líneas separadoras → se eliminan
2. Backticks (pueden contener URLs/paths) → «código»
3. URLs / www → «enlace»
4. Emails → «correo»
5. Paths Windows y Unix → «archivo» o «directorio» según extensión
6. UUIDs y hashes hex ≥ 12 (con al menos una letra) → «código»
7. Archivos sueltos con extensión conocida → «archivo»
8. Corridas de símbolos → se eliminan
9. Limpieza de espacios
