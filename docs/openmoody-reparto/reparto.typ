#let sans = ("Avenir Next", "SF Pro", "Libertinus Serif")
#let serif = ("Charter", "Libertinus Serif")
#let tinta = rgb("#1f3a93")
#let gris = luma(110)

#set document(title: [Reparto de tareas de openmoody], author: "David Román López")
#set page(
  paper: "a4",
  margin: (x: 25mm, top: 25mm, bottom: 25mm),
  footer: context align(right, text(font: sans, 9pt, fill: gris, counter(page).display("1 de 1", both: true))),
)
#set text(font: serif, size: 11pt, lang: "es", region: "es")
#set par(justify: true, leading: 0.78em, spacing: 1.1em)
#show heading: set text(font: sans, weight: "bold", fill: tinta)
#show heading.where(level: 1): set text(size: 13pt)
#show heading.where(level: 1): set block(above: 2em, below: 1em)
#show raw: set text(size: 9pt)
#show list: set par(justify: false)

// Cada tarea: (nombre, qué incluye, horas). Los totales se calculan de aquí.
#let javi = (
  ([SQLite y el esquema (ej. 3)], [Esquema con `boards`, `links` e `items`, restricciones `CHECK`, `UNIQUE` y `ON DELETE CASCADE`, migraciones y conexión con sqlx, con el pool en `AppState`.], 8),
  ([Tableros y links (ej. 4)], [Crear tableros, links de ver, editar y administrar, regenerarlos y borrar el tablero. Tokens guardados como hash, un solo extractor (`Access`) que autoriza todas las rutas y los errores en `AppError`.], 18),
  ([Items del tablero (ej. 5)], [Listar, crear y borrar tarjetas, clasificadas con `classify` y protegidas contra IDOR.], 10),
  ([Imágenes pegadas (ej. 7)], [Subida con el formato validado en el servidor, límite de 10 MB, ficheros en disco y borrado en el orden correcto.], 12),
  ([Límite de disco (del ej. 10)], [413 si un tablero pasa de su límite y 507 si lo pasa la instancia.], 3),
  ([Exportar el tablero (ej. 11)], [ZIP con JSON Canvas, Markdown y las imágenes, escrito en streaming.], 12),
  ([Backend de los comentarios], [Tabla y rutas para los comentarios con apodo.], 8),
  ([Documentación de la API], [Rutas, roles que pide cada una y respuestas.], 8),
  ([Pruebas del backend], [], 15),
  ([Aprender Rust], [Los capítulos del Book que pide la escalera y los de Shared state, Channels y Streams del tutorial de Tokio.], 30),
  ([Memoria y bitácora], [], 30),
  ([Defensa], [], 12),
)

#let david = (
  ([Servir la web desde Rust (ej. 1)], [Solo `index.html`, `index.css` y `js/`; el resto de la carpeta da 404.], 3),
  ([Detectar el tipo (ej. 2)], [`classify`, que usa la API de items para saber si lo pegado es texto, enlace, imagen, vídeo o color.], 6),
  ([Tiempo real con SSE (ej. 8)], [Hub con un canal `broadcast` por tablero, `hub::publish` y la ruta de eventos.], 15),
  ([Previews de enlaces (ej. 9)], [Título e imagen de cada URL, descargados en segundo plano y con protección contra SSRF.], 15),
  ([Límites de la instancia (ej. 10)], [Contraseña opcional para crear tableros, límite por IP, caducidad de tableros sin visitas, `noindex` y enlace para denunciar contenido.], 12),
  ([Despliegue (ej. 12)], [Binario con el front dentro (`include_str!`), imagen de Docker, compose, copias continuas de la base de datos con Litestream y de las imágenes a un bucket, Caddy con dominio y HTTPS, GitHub Actions y el manual de administración.], 20),
  ([PWA con `share_target`], [Pegar en Android y compartir desde otras apps al tablero.], 12),
  ([Pruebas de integración, carga y seguridad], [], 25),
  ([Aprender Rust], [Los capítulos del Book que pide la escalera y los de Shared state, Channels y Streams del tutorial de Tokio.], 30),
  ([Memoria y bitácora], [], 30),
  ([Defensa], [], 12),
)

#let adrian = (
  ([Wireframes y guía de estilo], [], 15),
  ([El JS habla con la API (ej. 6)], [Tablero por link en lugar de `localStorage`, y panel de administración para generar los links.], 12),
  ([Lienzo libre], [Mover, escalar y zoom táctil.], 30),
  ([Exportar a PNG y PDF], [], 12),
  ([Paleta automática], [Y exportarla como variables CSS.], 10),
  ([Comentarios con apodo], [La parte del front.], 10),
  ([Responsive y accesibilidad], [], 15),
  ([Pruebas de usabilidad], [], 8),
  ([Memoria y bitácora], [], 30),
  ([Defensa], [], 12),
)

#let total(filas) = filas.map(f => f.at(2)).sum()
#assert.eq(total(javi), 166)
#assert.eq(total(david), 180)
#assert.eq(total(adrian), 154)

#let cabecera(..celdas) = table.header(..celdas.pos().map(c => text(font: sans, size: 9pt, weight: "bold", fill: tinta, c)))
#let lineas = (x, y) => if y == 0 { (bottom: 0.6pt + tinta) } else { (bottom: 0.3pt + luma(205)) }

#let tareas(filas) = {
  set par(justify: false)
  set text(size: 10pt)
  table(
    columns: (35%, 1fr, 13mm),
    stroke: lineas,
    inset: (x: 4pt, y: 5pt),
    align: (x, y) => if x == 2 { right + top } else { left + top },
    cabecera([Tarea], [Qué incluye], [Horas]),
    ..filas.map(f => (f.at(0), f.at(1), str(f.at(2)))).flatten(),
    table.cell(colspan: 2, stroke: none, text(font: sans, weight: "bold")[Total]),
    table.cell(stroke: none, text(font: sans, weight: "bold", str(total(filas)))),
  )
}

#text(font: sans, 20pt, weight: "bold")[Reparto de tareas de openmoody]
#v(5mm, weak: true)
#line(length: 100%, stroke: 0.8pt + tinta)
#v(3mm, weak: true)
#[
  #set text(font: sans, size: 10pt)
  #grid(
    columns: (20mm, 1fr),
    column-gutter: 4mm,
    row-gutter: 2.5mm,
    text(fill: gris)[Proyecto], [openmoody, proyecto intermodular de 2º DAW],
    text(fill: gris)[Grupo], [Adrián, Javi y David],
    text(fill: gris)[Fecha], [Murcia, 16 de noviembre de 2026],
  )
]
#v(3mm, weak: true)
#line(length: 100%, stroke: 0.4pt + gris)
#v(4mm, weak: true)

Esta es la propuesta para repartir openmoody si acaba siendo nuestro proyecto. Cada uno se queda con una parte del código: Javi con la base de datos y la API, David con las piezas que la API llama y con el despliegue, y Adrián con el front. Así nadie edita los ficheros de otro y cada uno puede defender su parte por separado.

El backend va en Rust, con axum, tokio y sqlx, y la base de datos es SQLite. Javi y David lo aprenden desde cero, así que cada uno lleva 30 h para eso. Las horas de cada ejercicio se estimaron para Go, y en Rust pueden alargarse.

Las horas son estimaciones de trabajo hecho a mano e incluyen 30 h de memoria y bitácora y 12 h de defensa por persona. Los números de ejercicio son los de `openmoody-ejercicios-rust.md`.

#[
  #set par(justify: false)
  #set text(size: 10pt)
  #table(
    columns: (25%, 1fr, 13mm),
    stroke: lineas,
    inset: (x: 4pt, y: 5pt),
    align: (x, y) => if x == 2 { right + top } else { left + top },
    cabecera([Persona], [Parte], [Horas]),
    [Javi], [Base de datos, API, imágenes y exportación], str(total(javi)),
    [David], [Tiempo real, previews, límites, PWA, despliegue y pruebas], str(total(david)),
    [Adrián], [Front: lienzo, JS con la API, exportar a imagen, paleta y accesibilidad], str(total(adrian)),
  )
]

= Javi: base de datos y API

#tareas(javi)

= David: piezas de la API, seguridad y despliegue

#tareas(david)

= Adrián: front

#tareas(adrian)

= Cómo encajan las partes

Las piezas de David se llaman desde los handlers de Javi con una línea: `classify` al crear un item, `hub::publish` después de crear o borrar, y la descarga de la preview con `tokio::spawn` cuando el item es una URL. Las capas de límite por IP, `noindex` y contraseña envuelven las rutas sin tocarlas. El JS de Adrián solo habla con las rutas de la API.

Antes de que Javi empiece la base de datos tenemos que acordar:

- el esquema, con las columnas que usan otras partes: `size_bytes` de las imágenes y `title` e `image` de las previews;
- las rutas de la API y lo que devuelve cada una;
- los tipos que comparten todas las partes: `AppState` (el pool, el hub y el cliente de reqwest), `AppError`, el extractor `Access { board_id, role }` y la función `hub::publish(&state, board_id, evento)`. Javi y David escriben juntos sus definiciones, sin implementarlas, antes de que Javi empiece el ejercicio 4.

Con eso, mientras Javi hace la base de datos y las rutas, David puede probar el hub con `curl -N` y las previews con sus tests, y Adrián puede trabajar el lienzo y el JS contra las rutas acordadas.

= Plazos

Entregamos en junio. Antes de las prácticas de marzo tienen que funcionar en Rust los tableros con sus links, los items y el tiempo real (ejercicios 4, 5 y 8). Si no funcionan, volvemos a Go con `openmoody-ejercicios.md`, que tiene los mismos ejercicios, rutas y criterios.

Del ejercicio 4 dependen el 8, el 9 y el 10. Si en febrero sigue sin funcionar, Javi y David lo terminan juntos.

= Pendiente de confirmar

- Cuántas horas por semana puede dedicar cada uno.
- Con el tutor: openmoody no tiene cuentas de usuario (los roles van por link) ni un apartado de IA, y casi todas las fichas del centro llevan las dos cosas. Confirmar también que SQLite le vale como base de datos; otro profesor ya ha dicho que sí.
- La estimación más incierta es el lienzo libre. Si se alarga, revisamos lo que lleva Adrián.
