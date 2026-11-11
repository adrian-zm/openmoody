package main

import "testing"

// Especificación del ejercicio 2: implementa classify en detect.go hasta que esto pase.
func TestClassify(t *testing.T) {
	const embed = "https://www.youtube.com/embed/dQw4w9WgXcQ"
	cases := []struct{ in, typ, content string }{
		// texto: lo que no encaja en nada más
		{"hola mundo", "text", "hola mundo"},
		{"3.14", "text", "3.14"},
		{"mira esto https://example.com", "text", "mira esto https://example.com"},
		// seguridad: solo http(s); el resto se queda como texto
		{"javascript:alert(1)", "text", "javascript:alert(1)"},
		{"ftp://example.com/a", "text", "ftp://example.com/a"},
		// color
		{"#fff", "color", "#fff"},
		{"#1E1E1E", "color", "#1E1E1E"},
		{"#ffff", "text", "#ffff"},
		{"#ggg", "text", "#ggg"},
		// url: sin esquema se le añade https:// (el JS rechazaba las que llevan ?query)
		{"https://example.com", "url", "https://example.com"},
		{"example.com", "url", "https://example.com"},
		{"http://example.com/a?b=1&c=2", "url", "http://example.com/a?b=1&c=2"},
		{"  https://example.com\n", "url", "https://example.com"},
		// imagen por URL
		{"https://example.com/foto.PNG", "img", "https://example.com/foto.PNG"},
		{"https://example.com/foto.jpeg", "img", "https://example.com/foto.jpeg"},
		// YouTube: todo acaba en /embed/ID (el JS no convertía youtu.be ni shorts)
		{"https://www.youtube.com/watch?v=dQw4w9WgXcQ", "iframe", embed},
		{"https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=42s", "iframe", embed},
		{"https://youtu.be/dQw4w9WgXcQ?si=abc", "iframe", embed},
		{"youtube.com/shorts/dQw4w9WgXcQ", "iframe", embed},
		{"https://www.youtube.com/embed/dQw4w9WgXcQ", "iframe", embed},
		{"https://www.youtube.com/watch?v=corto", "url", "https://www.youtube.com/watch?v=corto"},
		{"https://notyoutube.com/watch?v=dQw4w9WgXcQ", "url", "https://notyoutube.com/watch?v=dQw4w9WgXcQ"},
	}
	for _, c := range cases {
		typ, content := classify(c.in)
		if typ != c.typ || content != c.content {
			t.Errorf("classify(%q) = (%q, %q), se esperaba (%q, %q)", c.in, typ, content, c.typ, c.content)
		}
	}
}
