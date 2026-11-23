// Especificación del ejercicio 2: escribe classify en src/detect.rs hasta que esto pase.
// Es la tabla de detect_test.go pasada a Rust. Se enlaza al final de src/detect.rs con:
//
//     #[cfg(test)]
//     mod tests;
//
// y se lanza con `cargo test`.
use super::{Kind, classify};

const EMBED: &str = "https://www.youtube.com/embed/dQw4w9WgXcQ";

#[test]
fn classify_sigue_la_tabla() {
    let casos: &[(&str, Kind, &str)] = &[
        // texto: lo que no encaja en nada más
        ("hola mundo", Kind::Text, "hola mundo"),
        ("3.14", Kind::Text, "3.14"),
        ("mira esto https://example.com", Kind::Text, "mira esto https://example.com"),
        // seguridad: solo http(s); el resto se queda como texto
        ("javascript:alert(1)", Kind::Text, "javascript:alert(1)"),
        ("ftp://example.com/a", Kind::Text, "ftp://example.com/a"),
        // color
        ("#fff", Kind::Color, "#fff"),
        ("#1E1E1E", Kind::Color, "#1E1E1E"),
        ("#ffff", Kind::Text, "#ffff"),
        ("#ggg", Kind::Text, "#ggg"),
        // url: sin esquema se le añade https:// (el JS rechazaba las que llevan ?query)
        ("https://example.com", Kind::Url, "https://example.com"),
        ("example.com", Kind::Url, "https://example.com"),
        ("http://example.com/a?b=1&c=2", Kind::Url, "http://example.com/a?b=1&c=2"),
        ("  https://example.com\n", Kind::Url, "https://example.com"),
        // imagen por URL
        ("https://example.com/foto.PNG", Kind::Img, "https://example.com/foto.PNG"),
        ("https://example.com/foto.jpeg", Kind::Img, "https://example.com/foto.jpeg"),
        // YouTube: todo acaba en /embed/ID (el JS no convertía youtu.be ni shorts)
        ("https://www.youtube.com/watch?v=dQw4w9WgXcQ", Kind::Iframe, EMBED),
        ("https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=42s", Kind::Iframe, EMBED),
        ("https://youtu.be/dQw4w9WgXcQ?si=abc", Kind::Iframe, EMBED),
        ("youtube.com/shorts/dQw4w9WgXcQ", Kind::Iframe, EMBED),
        ("https://www.youtube.com/embed/dQw4w9WgXcQ", Kind::Iframe, EMBED),
        ("https://www.youtube.com/watch?v=corto", Kind::Url, "https://www.youtube.com/watch?v=corto"),
        ("https://notyoutube.com/watch?v=dQw4w9WgXcQ", Kind::Url, "https://notyoutube.com/watch?v=dQw4w9WgXcQ"),
    ];

    // Se prueban todos los casos y se enseñan todos los fallos de golpe, no solo el primero
    let mut fallos = Vec::new();
    for &(entrada, tipo, contenido) in casos {
        let obtenido = classify(entrada);
        if obtenido != (tipo, contenido.to_string()) {
            fallos.push(format!("classify({entrada:?}) = {obtenido:?}, se esperaba ({tipo:?}, {contenido:?})"));
        }
    }
    assert!(fallos.is_empty(), "{} de {} casos fallan:\n{}", fallos.len(), casos.len(), fallos.join("\n"));
}
