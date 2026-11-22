// ADR-001, versión Apple: tipografía SF, mucho aire, tarjetas grises redondeadas y codly en github-light.
// Necesita Typst 0.15 o posterior (codly 2.0). Las fuentes SF Pro se descargan de developer.apple.com/fonts;
// sin ellas sale Helvetica Neue.
#import "@preview/codly:2.0.0" as codly
#import "adr-001-contenido.typ": adr, lenguajes

#let texto = ("SF Pro Text", "SF Pro", "Helvetica Neue", "Libertinus Sans")
#let titular = ("SF Pro Display", "SF Pro", "Helvetica Neue", "Libertinus Sans")
#let mono = ("SF Mono", "Menlo", "DejaVu Sans Mono")
#let tinta = rgb("#1d1d1f")
#let secundario = rgb("#6e6e73")
#let azul = rgb("#0066cc")
#let gris-fondo = rgb("#f5f5f7")
#let separador = rgb("#d2d2d7")

#set document(
  title: [ADR-001: SQLite over PostgreSQL],
  author: ("David Román López",),
  keywords: ("openmoody", "SQLite", "PostgreSQL", "architecture decision record"),
  date: datetime(year: 2026, month: 11, day: 22),
)

#set page(
  paper: "a4",
  margin: (x: 24mm, top: 26mm, bottom: 24mm),
  header: context {
    if here().page() > 1 {
      set text(font: texto, size: 8pt, fill: secundario)
      [openmoody #h(1fr) ADR-001 · SQLite over PostgreSQL]
    }
  },
  footer: context {
    set align(center)
    set text(font: texto, size: 8pt, fill: secundario)
    counter(page).display("1")
  },
)

#set text(font: texto, size: 10.5pt, fill: tinta, lang: "en")
#set par(justify: false, leading: 0.7em, spacing: 1.1em)
#set heading(numbering: "1.1")
#show heading: it => block(above: if it.level == 1 { 2.1em } else { 1.6em }, below: 0.8em, {
  set text(font: titular, weight: "semibold", size: if it.level == 1 { 17pt } else { 12.5pt }, tracking: -0.01em)
  if it.numbering != none {
    text(fill: secundario)[#context counter(heading).display(it.numbering)]
    h(0.6em)
  }
  it.body
})
#show raw: set text(font: mono)
#show raw.where(block: false): set text(size: 0.88em)
#show raw.where(block: false): box.with(fill: gris-fondo, inset: (x: 3pt), outset: (y: 2.5pt), radius: 4pt)
#show link: set text(fill: azul)
#set list(indent: 0.2em, body-indent: 0.6em, spacing: 0.8em)
#set enum(indent: 0.2em, body-indent: 0.6em, spacing: 0.8em)
#set terms(separator: [. ], hanging-indent: 1.2em, spacing: 0.8em)

// Tablas como tarjetas blancas: borde fino, cabecera gris claro, primera columna en medium
// y líneas finas solo entre filas del cuerpo
#set table(
  stroke: (x, y) => if y > 1 { (top: 0.5pt + separador) },
  fill: (x, y) => if y == 0 { gris-fondo },
  inset: (x: 10pt, y: 7pt),
)
#show table: it => block(width: 100%, stroke: 0.5pt + separador, radius: 12pt, clip: true, it)
#show table: set text(size: 9.5pt, number-width: "tabular")
#show table: set par(justify: false)
#show table.cell.where(x: 0): set text(weight: "medium")
#show table.cell.where(y: 0): set text(font: titular, size: 8.5pt, weight: "semibold", fill: tinta)
#set figure(gap: 0.8em)
#show figure: set block(above: 1.6em, below: 1.6em)
#show figure.where(kind: table): set figure.caption(position: top)
#show figure.where(kind: raw): set figure.caption(position: top)
#show figure.caption: set text(size: 9pt, fill: secundario)
#show figure.caption: set par(justify: false)

// codly en tema claro, con las esquinas tan redondeadas como las tarjetas
#show: codly.theme("github-light")
#show: codly.set_(radius: 10pt)
#show: codly.lang-set_(languages: lenguajes)
#show raw.where(block: true): it => if it.lang in ("sql", "sh", "rust") { codly.new(it) } else { it }

#let portada(m) = [
  #block(text(font: titular, size: 9.5pt, weight: "semibold", fill: azul)[#m.etiqueta · #m.codigo])
  #v(4pt)
  #block(text(font: titular, size: 32pt, weight: "bold", tracking: -0.02em, m.titulo))
  #v(2pt)
  #block(text(font: titular, size: 15pt, fill: secundario, m.subtitulo))
  #v(14pt)
  #block(width: 100%, fill: gris-fondo, radius: 12pt, inset: 14pt, grid(
    columns: (1fr, 1fr, 1fr),
    column-gutter: 14pt,
    row-gutter: 12pt,
    ..m.campos.map(((clave, valor)) => stack(
      spacing: 4pt,
      text(size: 7.5pt, weight: "semibold", fill: secundario, upper(clave)),
      text(size: 9.5pt, valor),
    )),
  ))
  #v(10pt)
]

#let resumen(cuerpo) = block(width: 100%, above: 0.8em, below: 1.4em)[
  #set text(size: 12.5pt, fill: tinta)
  #set par(leading: 0.75em)
  #cuerpo
]

#let cifras(lista) = grid(
  columns: (1fr,) * lista.len(),
  column-gutter: 10pt,
  ..lista.map(c => block(width: 100%, fill: gris-fondo, radius: 12pt, inset: 14pt, stack(
    spacing: 6pt,
    text(font: titular, size: 26pt, weight: "bold", fill: azul, c.valor),
    text(size: 9pt, fill: secundario, c.texto),
  ))),
)

#let nota(titulo, cuerpo) = block(width: 100%, fill: gris-fondo, radius: 12pt, inset: 14pt, above: 1.4em, below: 1.4em)[
  #text(font: titular, size: 10pt, weight: "semibold", fill: azul, titulo)
  #v(2pt)
  #cuerpo
]

#let sin-regla = table.hline(stroke: none)

// El ganador de cada fila como una píldora del color de su base de datos
#let colores-motor = (SQLite: azul, PostgreSQL: rgb("#5e5ce6"))
#let veredicto(motor, ratio) = box(
  fill: colores-motor.at(motor).lighten(88%),
  radius: 10pt,
  inset: (x: 7pt, y: 2.5pt),
  text(size: 8.5pt, weight: "semibold", fill: colores-motor.at(motor))[#motor #ratio],
)

#adr((
  portada: portada,
  resumen: resumen,
  cifras: cifras,
  nota: nota,
  tema: (titulo) => text(weight: "semibold")[#titulo.],
  sesion: (comandos: none, salida: none) => figure(comandos, caption: [Commands to repeat the measurements.]),
  toprule: sin-regla,
  midrule: sin-regla,
  bottomrule: sin-regla,
  veredicto: veredicto,
))
