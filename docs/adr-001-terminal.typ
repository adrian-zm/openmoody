// ADR-001, versión oscura: colores Tokyo Night (los de tu Neovim) y codly en oscuro.
// La salida del benchmark va en una ventana dibujada como tu terminal: Ghostty translúcido
// sobre el fondo morado y el prompt de dos líneas de starship, con la salida coloreada.
// Necesita Typst 0.15 o posterior (codly 2.0). Pensada para pantalla, no para imprimir.
#import "@preview/codly:2.0.0" as codly
#import "adr-001-contenido.typ": adr, lenguajes

#let fondo = rgb("#1a1b26")
#let fondo-alt = rgb("#1f2335")
#let fondo-3 = rgb("#24283b")
#let claro = rgb("#c0caf5")
#let tenue = rgb("#a9b1d6")
#let comentario = rgb("#565f89")
#let linea = rgb("#3b4261")
#let azul = rgb("#7aa2f7")
#let cian = rgb("#7dcfff")
#let verde = rgb("#9ece6a")
#let magenta = rgb("#bb9af7")
#let naranja = rgb("#ff9e64")

#let sans = ("SF Pro Text", "Helvetica Neue", "Libertinus Sans")
#let mono = ("JetBrains Mono", "SF Mono", "Menlo", "DejaVu Sans Mono")
// En la terminal, la Nerd Font primero para el icono de la rama de git
#let mono-term = ("JetBrainsMono Nerd Font", "JetBrains Mono", "SF Mono", "Menlo", "Symbols Nerd Font Mono")

#set document(
  title: [ADR-001: SQLite over PostgreSQL],
  author: ("David Román López",),
  keywords: ("openmoody", "SQLite", "PostgreSQL", "architecture decision record"),
  date: datetime(year: 2026, month: 11, day: 22),
)

#set page(
  paper: "a4",
  fill: fondo,
  margin: (x: 24mm, top: 26mm, bottom: 24mm),
  header: context {
    if here().page() > 1 {
      set text(font: mono, size: 7.5pt, fill: comentario)
      [openmoody/docs/adr-001 #h(1fr) SQLite over PostgreSQL]
    }
  },
  footer: context {
    set align(right)
    set text(font: mono, size: 7.5pt, fill: comentario)
    counter(page).display("1/1", both: true)
  },
)

#set text(font: sans, size: 10.5pt, fill: claro, lang: "en")
#set par(justify: false, leading: 0.7em, spacing: 1.05em)
#set heading(numbering: "1.1")
#show heading: it => block(above: if it.level == 1 { 2em } else { 1.5em }, below: 0.8em, {
  set text(font: mono, weight: "bold", size: if it.level == 1 { 13pt } else { 11pt }, fill: azul)
  if it.numbering != none {
    text(fill: naranja)[#context counter(heading).display(it.numbering)]
    h(0.7em)
  }
  it.body
})
#show strong: set text(fill: verde)
#show raw: set text(font: mono)
#show raw.where(block: false): set text(size: 0.88em, fill: cian)
#show raw.where(block: false): box.with(fill: fondo-3, inset: (x: 3pt), outset: (y: 2.5pt), radius: 3pt)
#show link: set text(fill: cian)
#set list(indent: 0.2em, body-indent: 0.6em, spacing: 0.8em, marker: text(fill: naranja)[›])
#set enum(indent: 0.2em, body-indent: 0.6em, spacing: 0.8em)
#set terms(separator: [. ], hanging-indent: 1.2em, spacing: 0.8em)

// Tablas con filas alternas y reglas en el color de las líneas del editor
#set table(stroke: none, inset: (x: 7pt, y: 5pt), fill: (x, y) => if y > 0 and calc.even(y) { fondo-alt })
#show table: set text(size: 9.5pt, number-width: "tabular")
#show table: set par(justify: false)
#show table.cell.where(y: 0): set text(font: mono, size: 8.5pt, weight: "bold", fill: magenta)
#set figure(gap: 0.8em)
#show figure: set block(above: 1.6em, below: 1.6em)
#show figure.where(kind: table): set figure.caption(position: top)
#show figure.where(kind: raw): set figure.caption(position: top)
#show figure.where(kind: "terminal"): set figure.caption(position: top)
#show figure.caption: set text(size: 9pt, fill: tenue)
#show figure.caption: set par(justify: false)

// codly en oscuro con el fondo de Tokyo Night, solo en SQL y Rust
#show: codly.theme("dark")
#show: codly.line-set_(fill: (fondo-alt, fondo), stroke: 1pt + linea)
#show: codly.lang-set_(languages: lenguajes)
#show raw.where(block: true): it => if it.lang in ("sql", "rust") { codly.new(it) } else { it }

#let portada(m) = [
  #block(text(font: mono, size: 9pt)[#text(fill: verde)[❯] #text(fill: azul)[\~/openmoody/docs] #text(fill: comentario)[· #m.codigo · v#m.version · #m.etiqueta]])
  #v(10pt)
  #block(text(size: 28pt, weight: "bold", fill: claro, m.titulo))
  #v(2pt)
  #block(text(size: 14pt, fill: tenue, m.subtitulo))
  #v(14pt)
  #block(width: 100%, fill: fondo-alt, radius: 6pt, inset: 12pt, stroke: 0.5pt + linea, grid(
    columns: (1fr, 1fr, 1fr),
    column-gutter: 12pt,
    row-gutter: 10pt,
    ..m.campos.map(((clave, valor)) => stack(
      spacing: 4pt,
      text(font: mono, size: 7.5pt, fill: magenta, lower(clave)),
      text(size: 9.5pt, valor),
    )),
  ))
  #v(10pt)
]

#let resumen(cuerpo) = block(width: 100%, fill: fondo-alt, radius: 6pt, inset: 13pt, stroke: (left: 2pt + naranja), above: 0.8em, below: 1.3em)[
  #text(font: mono, size: 8pt, weight: "bold", fill: naranja)[decision]
  #v(3pt)
  #set text(size: 11pt)
  #cuerpo
]

#let colores = (cian, verde, magenta)
#let cifras(lista) = grid(
  columns: (1fr,) * lista.len(),
  column-gutter: 10pt,
  ..lista.enumerate().map(((i, c)) => block(width: 100%, fill: fondo-alt, radius: 6pt, inset: 13pt, stroke: 0.5pt + linea, stack(
    spacing: 6pt,
    text(font: mono, size: 22pt, weight: "bold", fill: colores.at(calc.rem(i, colores.len())), c.valor),
    text(size: 9pt, fill: tenue, c.texto),
  ))),
)

#let nota(titulo, cuerpo) = block(width: 100%, fill: fondo-alt, radius: 6pt, inset: 13pt, stroke: (left: 2pt + naranja), above: 1.4em, below: 1.4em)[
  #text(font: mono, size: 8pt, weight: "bold", fill: naranja, lower(titulo))
  #v(3pt)
  #cuerpo
]

// Tu terminal, sacada de la captura: texto casi blanco sobre el fondo morado translúcido,
// borde morado redondeado y el prompt de starship, con los colores de ese prompt
#let texto-term = rgb("#e6e6e6")
#let gris-prompt = rgb("#9aa0b8")
#let morado = rgb("#a98bff")
#let turquesa = rgb("#56d4dd")
#let rosa = rgb("#d670d6")
#let lila = rgb("#c792ea")
#let amarillo = rgb("#e5c07b")
#let verde-ok = rgb("#7ee787")

// Colores sobre la salida de compare.sh. Las expresiones no se solapan entre sí:
// cada trozo de texto lo colorea una sola regla
#let colorear-salida(cuerpo) = {
  // Las frases que explican la tabla, apagadas
  show regex("^(Building in release|2000 requests|Rows with -k).*"): set text(fill: gris-prompt, style: "italic")
  // Las filas de la tabla
  show regex("^(GET \\d+ rows( -k)?|POST)"): set text(fill: turquesa, weight: "bold")
  // Cada celda: peticiones por segundo en blanco y el p99 entre paréntesis en lila
  show regex("\\d+ \\([\\d.]+(ms|us)?\\)"): it => {
    let (peticiones, p99) = it.text.split(" ")
    text(weight: "bold", fill: white, peticiones)
    " "
    text(fill: lila, p99)
  }
  show "no reuse": set text(fill: gris-prompt, style: "italic")
  // Los cuatro servidores, en el color de la rama de git
  show regex("php -S|nginx \\+ php-fpm|Rust \\+ SQLite|Rust \\+ Postgres"): set text(fill: rosa, weight: "bold")
  show regex("rust-sqlite|rust-postgres-binary|postgres:|php-fpm-nginx"): set text(fill: rosa)
  // Tamaños en amarillo, como la duración en el prompt
  show regex("\\d+(\\.\\d+)? ?(MB|KB)|\\d+(\\.\\d+)?M\\b"): set text(fill: amarillo, weight: "bold")
  show "OK:": set text(fill: verde-ok, weight: "bold")
  show regex("Memory \\(RSS\\):|Footprint, counting shared memory once:"): set text(weight: "bold")
  cuerpo
}

#let prompt-starship(comando: none) = {
  text(fill: gris-prompt, "╭─")
  text(fill: turquesa, weight: "bold", "js/skel15")
  text(fill: texto-term, " on ")
  text(fill: rosa, weight: "bold", "\u{e0a0} main")
  text(fill: lila, weight: "bold", " [!2?9✓]")
  linebreak()
  text(fill: gris-prompt, "╰─")
  text(fill: morado, weight: "bold", "❯ ")
  if comando != none {
    text(fill: texto-term, comando)
  } else {
    box(width: 0.55em, height: 0.95em, fill: morado, baseline: 0.15em)
  }
}

#let ventana-terminal(comando, salida) = block(
  width: 100%,
  radius: 10pt,
  clip: true,
  stroke: 1.2pt + rgb("#7b61ff"),
  fill: gradient.linear(rgb("#0e1430"), rgb("#1d1842"), rgb("#3b1d5a"), angle: 30deg),
  inset: (x: 12pt, y: 10pt),
  {
    // La figura centra su contenido; en una terminal todo va a la izquierda
    set align(left)
    set text(font: mono-term, size: 6.3pt, fill: texto-term)
    set par(leading: 0.55em, spacing: 0.55em, justify: false, first-line-indent: 0pt)
    show raw: set text(font: mono-term, size: 6.3pt, fill: texto-term)
    prompt-starship(comando: comando)
    colorear-salida(raw(salida, block: true))
    v(4pt)
    prompt-starship()
  },
)

#let sesion(comandos: none, salida: none) = figure(
  kind: "terminal",
  supplement: [Session],
  caption: [Output of `compare.sh` with 50 clients, recorded on 22 November 2026 and shown as it appears in the author's terminal (Ghostty and starship), with colours added for legibility. The messages are translated from Spanish.],
  ventana-terminal("C=50 ./compare.sh", salida),
)

#adr((
  portada: portada,
  resumen: resumen,
  cifras: cifras,
  nota: nota,
  tema: (titulo) => text(weight: "bold", fill: cian)[#titulo.],
  sesion: sesion,
  veredicto: (motor, ratio) => text(weight: "bold", fill: if motor == "SQLite" { verde } else { magenta })[#motor #ratio],
  toprule: table.hline(stroke: 0.8pt + linea),
  midrule: table.hline(stroke: 0.5pt + linea),
  bottomrule: table.hline(stroke: 0.8pt + linea),
))
