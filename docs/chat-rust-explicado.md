# El chat de clase en Rust, línea a línea

El ejercicio 15 de DWEC es un chat con `fetch`, dos PHP y una tabla SQL. Esta es la misma API en Rust, con axum, tokio y sqlx sobre SQLite. El front no cambia salvo las dos URLs. Usa las mismas piezas que los ejercicios 1, 3 y 5 de la escalera de openmoody (servir la web, conectar con SQLite y una API que lee y escribe), así que sirve para ver el esqueleto antes de empezarlos.

## Qué hace

- `GET /api/mensajes?ultimo=5` devuelve en JSON los mensajes con `id` mayor que 5, ordenados.
- `POST /api/mensajes` con `nick` y `mensaje` en el cuerpo (formulario) guarda un mensaje y responde 201.
- Cualquier otra ruta sirve un fichero de `static/`, que es donde está el front. `/` sirve `index.html`.

El front pregunta cada 2 segundos por los mensajes posteriores al último que tiene, y casi siempre recibe `[]`.

## Carpetas

```
chat-rs/
  Cargo.toml
  .env              DATABASE_URL=sqlite:data/chat.db (lo leen las macros de sqlx al compilar)
  migrations/       el esquema, en SQL
  static/           index.html, script.js, styles.css, bootstrap.css, bootstrap.js
  src/main.rs       todo el servidor
  data/chat.db      la base de datos (no va a git)
```

Solo se sirve `static/`, así que `/Cargo.toml`, `/src/main.rs` o `/data/chat.db` dan 404. Con el montaje típico de PHP es al revés: tanto `php -S` como el Apache de XAMPP sirven todo lo que hay en la carpeta del proyecto. Al probarlo con XAMPP se podía recorrer el directorio entero y descargar cualquier fichero, `chat.sql` incluido; en la versión con SQLite, eso sería la base de datos con todos los mensajes. En PHP se evita igual que aquí: dejando en la carpeta pública solo lo que se quiere servir, como hace Laravel con `public/`. La diferencia la pone el servidor y no el lenguaje: Apache sirve la carpeta entera salvo que se le limite, y axum no sirve nada que no se le añada. Un `ServeDir::new(".")` en Rust expondría lo mismo que XAMPP.

## Cargo.toml

```toml
[dependencies]
axum = "0.8"
serde = { version = "1", features = ["derive"] }
sqlx = { version = "0.9", features = ["runtime-tokio", "sqlite"] }
tokio = { version = "1", features = ["full"] }
tower-http = { version = "0.7", features = ["fs"] }
```

- `axum` es el framework web: rutas, extractores (los parámetros de los handlers) y respuestas.
- `serde` convierte entre structs de Rust y formatos como JSON o un formulario. La feature `derive` permite escribir `#[derive(Deserialize)]` encima de un struct.
- `sqlx` habla con la base de datos y comprueba las consultas al compilar. Con la feature `sqlite` lleva SQLite compilado dentro, así que no hay que instalar nada aparte. `runtime-tokio` le dice qué runtime async usar.
- `tokio` es el runtime async: el que reparte las peticiones entre los núcleos.
- `tower-http` con `fs` trae `ServeDir`, que sirve ficheros de una carpeta.

Las líneas se añaden con `cargo add`, por ejemplo `cargo add tower-http@0.7 --features fs`. sqlx 0.9 necesita rustc 1.94 o más nuevo: con uno más antiguo, `cargo build` se niega a compilar y lo dice.

## El esquema

`migrations/20261117121253_mensajes.sql`:

```sql
CREATE TABLE IF NOT EXISTS mensajes (
  id INTEGER PRIMARY KEY,
  instante TEXT NOT NULL DEFAULT (datetime('now', 'localtime')),
  nick TEXT NOT NULL CHECK (length(nick) <= 16),
  mensaje TEXT NOT NULL CHECK (length(mensaje) <= 256)
);
```

- El número del nombre del fichero es la versión de la migración. sqlx las aplica en ese orden.
- `id INTEGER PRIMARY KEY` tiene que ir escrito exactamente así para que SQLite lo autonumere. Con `INT PRIMARY KEY` no da error, pero los `id` se quedan en `NULL`.
- SQLite no tiene tipo fecha. `instante` es texto con la forma `2026-11-19 10:54:13`, y se rellena solo al insertar. Va en hora local porque así lo mostraba el MySQL del profesor; en un servidor de verdad sería mejor UTC.
- Los `CHECK` son los mismos límites que el `varchar(16)` y el `varchar(256)` del MySQL original. Si alguien manda un nick más largo, la base de datos rechaza el `INSERT`.

La base de datos tiene que existir antes de compilar, porque las macros de sqlx comprueban las consultas contra ella:

```sh
mkdir data
sqlite3 data/chat.db < migrations/*_mensajes.sql
```

Con `sqlx-cli` instalado vale también `sqlx database create` y `sqlx migrate run`.

## main.rs

### Los use

```rust
use axum::{
    Form,
    extract::{Query, State},
    http::{StatusCode, header},
    response::IntoResponse,
    routing::get,
};
use serde::Deserialize;
use sqlx::SqlitePool;
use tokio::net::TcpListener;
use tower_http::services::ServeDir;
```

Cada `use` trae un nombre para poder escribirlo sin la ruta completa. `use tower_http::services;` traería el módulo, y luego habría que escribir `services::ServeDir`. Importar algo que no se usa da un aviso al compilar, y conviene quitarlo.

### El estado compartido

```rust
#[derive(Clone)]
struct AppState {
    pool: SqlitePool,
}
```

Aquí va lo que necesitan los handlers y se crea una sola vez al arrancar. En este chat es solo el pool de conexiones, el equivalente del `$con = new PDO(...)` del PHP. La diferencia es que PHP abre una conexión nueva en cada petición, y aquí las conexiones se quedan abiertas y se reutilizan.

axum le da una copia del estado a cada petición, y por eso hace falta `#[derive(Clone)]`. Copiar un `SqlitePool` es barato: por dentro es un puntero compartido a las mismas conexiones.

El struct va fuera de `main`. Si estuviera dentro, los handlers no podrían nombrarlo, porque un nombre solo existe dentro de las llaves donde se declara.

### Lo que llega de la petición

```rust
#[derive(Deserialize)]
struct Since {
    ultimo: i64,
}
#[derive(Deserialize)]
struct NewMessage {
    nick: String,
    mensaje: String,
}
```

`Since` es lo que viene en la URL (`?ultimo=5`) y `NewMessage` lo que viene en el cuerpo del POST. Los nombres de los campos tienen que coincidir con los que manda el front. Si el campo se llamara `last`, axum no encontraría `last` en `?ultimo=5` y respondería 400.

Los tipos también se comprueban: `ultimo` es un `i64`, así que `?ultimo=abc` da 400 sin que el handler llegue a ejecutarse. En el PHP original, `$_GET['ultimo']` iba pegado a la consulta, y `?ultimo=0 UNION SELECT ...` podía leer cualquier tabla.

### main

```rust
#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let pool = SqlitePool::connect("sqlite:data/chat.db").await?;
    sqlx::migrate!().run(&pool).await?;
    let state = AppState { pool };
    let app = axum::Router::new()
        .route("/api/mensajes", get(get_messages).post(send_message))
        .fallback_service(ServeDir::new("static"))
        .with_state(state);
    let listener = TcpListener::bind("0.0.0.0:8080").await?;
    axum::serve(listener, app).await?;
    Ok(())
}
```

- `#[tokio::main]` arranca el runtime de tokio y ejecuta dentro el `main`, que es `async`.
- `Result<(), Box<dyn std::error::Error>>` significa «no devuelvo nada útil, pero puedo fallar con cualquier tipo de error». Es lo que permite usar `?` dentro de `main`. Si algo falla, el programa termina con un `Error: ...` legible en vez de un pánico.
- `SqlitePool::connect(...)` abre el pool. La ruta es relativa a la carpeta desde la que se lanza el programa, así que `cargo run` va desde `chat-rs/`. Si el fichero no existe, falla: no lo crea.
- `.await` espera a que termine algo `async`. `?` mira el `Result`: si es un error, sale de la función con él, y si no, lo abre y da el valor de dentro. Sin el `?`, `pool` sería un `Result` y no un pool.
- `sqlx::migrate!()` mete en el binario los ficheros de `migrations/` al compilar, y `.run(&pool)` aplica los que falten. Lleva la cuenta en la tabla `_sqlx_migrations`.
- `AppState { pool }` crea el estado. Es la forma corta de `AppState { pool: pool }` cuando la variable se llama igual que el campo. Aquí `pool` se mueve dentro del estado, y a partir de esta línea ya no se puede usar suelto.
- `Router::new()` empieza el router, y los métodos se encadenan en una sola expresión. Cada `Router::new()` sería un router distinto, y a `serve` solo se le pasa uno.
- `.route("/api/mensajes", get(get_messages).post(send_message))` es una ruta con dos métodos. `get_messages` va sin paréntesis porque se pasa la función, no se llama. Es como `addEventListener("click", enviarMensaje)` en JS: axum la llama en cada petición y le rellena los argumentos. `.post` es un método de lo que devuelve `get(...)`, y por eso no hace falta importar la función `post`.
- `.fallback_service(ServeDir::new("static"))` sirve los ficheros de `static/` para cualquier ruta que no sea la de arriba.
- `.with_state(state)` va al final: le da el estado a las rutas definidas antes. Lo que se pasa es la variable `state`, en minúscula. `State` es el extractor de axum y `AppState` es el tipo.
- `TcpListener::bind("0.0.0.0:8080")` escucha en todas las interfaces, así que otros ordenadores de la misma red pueden entrar al chat. Con `127.0.0.1:8080`, solo el propio ordenador.
- `axum::serve(listener, app).await?` atiende peticiones y no vuelve mientras el servidor esté vivo. Sin esta línea, el programa llega al `Ok(())` y termina en cuanto arranca.

### Leer mensajes

```rust
async fn get_messages(
    State(state): State<AppState>,
    Query(from): Query<Since>,
) -> Result<impl IntoResponse, StatusCode> {
    let json = sqlx::query_scalar!(
        r#"SELECT json_group_array(json_object('id', id, 'nick', nick, 'texto', mensaje, 'fecha', instante) ORDER BY id) AS "json!: String"
       FROM mensajes WHERE id > ?"#,
        from.ultimo
    )
    .fetch_one(&state.pool)
    .await
    .map_err(|e| {
        eprintln!("{e}");
        StatusCode::INTERNAL_SERVER_ERROR
    })?;
    Ok(([(header::CONTENT_TYPE, "application/json")], json))
}
```

- Los parámetros son extractores: axum mira el tipo de cada uno y sabe qué sacar de la petición. `State(state): State<AppState>` saca el estado que se le dio con `with_state`. `Query(from): Query<Since>` saca y convierte los parámetros de la URL. El `State(state)` de la izquierda es un patrón: desempaqueta el valor y lo deja en la variable `state`.
- `Result<impl IntoResponse, StatusCode>` quiere decir que, si va bien, devuelve algo que axum sabe convertir en respuesta, y si va mal, un código HTTP. `impl IntoResponse` evita escribir el tipo exacto, que aquí es una tupla larga.
- `query_scalar!` es para consultas que devuelven una sola columna. Al compilar, la macro comprueba el SQL contra `data/chat.db`: si una columna está mal escrita, no compila.
- El SQL va entre `r#"` y `"#`, un string crudo, porque lleva comillas dobles dentro. Con comillas normales, el string se cortaría en `AS "` y la macro daría `no rules expected the token`.
- `json_group_array(json_object(...) ORDER BY id)` hace que SQLite construya el JSON entero y devuelva una sola fila con el array. Con 0 mensajes devuelve `[]`. Los nombres `texto` y `fecha` son los que lee el front. El `ORDER BY` dentro de la función necesita SQLite 3.44 o posterior; el que lleva sqlx lo cumple.
- `AS "json!: String"` es sintaxis de sqlx, no de SQL: le dice a la macro que la columna es un `String` y que nunca es nula (`!`). Cuando una columna sale de una función, sqlx no siempre sabe su tipo ni si puede ser nula.
- El `?` del SQL se rellena con `from.ultimo`, el valor que trajo la URL. Lo pone sqlx como parámetro, y por eso no hay inyección posible.
- `.fetch_one` porque siempre sale una fila. Con `.fetch_all`, el resultado sería un `Vec<String>`, que axum no sabe convertir en respuesta.
- `.map_err(|e| { ... })` convierte el error de sqlx en un 500. `|e| { ... }` es una closure, una función sin nombre que recibe el error en `e` (capítulo 13 del Book). El `eprintln!` escribe el error en la terminal del servidor, porque al cliente solo le llega el 500. El `?` del final sale de la función si hubo error.
- `let json = ...` guarda el resultado. Sin el `let` se perdería, como `strtoupper($s);` en PHP sin asignarlo.
- `Ok(([(header::CONTENT_TYPE, "application/json")], json))` es una tupla de cabeceras y cuerpo, y axum la convierte en la respuesta. La cabecera hace falta porque el texto ya es JSON y no pasa por `Json(...)`.

El JSON lo construye SQLite por rendimiento. sqlx ejecuta cada conexión de SQLite en un hilo propio, y cada fila viaja sola por un canal hasta el handler. Con 50 filas son 50 viajes en cada petición. Con un struct `Message` y `query_as!`, la versión anterior atendía unas 6700 peticiones por segundo; con el JSON hecho en SQLite, unas 23 800, porque cruza una sola fila.

### Enviar un mensaje

```rust
async fn send_message(
    State(state): State<AppState>,
    Form(message): Form<NewMessage>,
) -> Result<StatusCode, StatusCode> {
    sqlx::query!(
        "INSERT INTO mensajes (nick, mensaje) VALUES (?, ?)",
        message.nick,
        message.mensaje
    )
    .execute(&state.pool)
    .await
    .map_err(|e| {
        eprintln!("{e}");
        StatusCode::INTERNAL_SERVER_ERROR
    })?;
    Ok(StatusCode::CREATED)
}
```

- `Form(message): Form<NewMessage>` lee el cuerpo como formulario (`application/x-www-form-urlencoded`). Va el último porque es el extractor que se come el cuerpo, y solo puede haber uno así. Si el front manda `FormData`, viaja como multipart y axum responde 415. Por eso el front usa `URLSearchParams`. Si falta un campo, responde 422.
- `query!` es para consultas que no devuelven filas. Los `?` del SQL se rellenan en orden con los argumentos de detrás. `id` e `instante` los pone SQLite.
- `.execute` devuelve cuántas filas cambiaron, y aquí no hace falta, así que no hay `let`. El `?` sigue ahí para los errores.
- `Result<StatusCode, StatusCode>`: 201 si va bien y 500 si falla. Lo que va dentro del `Ok` tiene que ser del tipo que promete la firma: si se copia la de `get_messages`, el compilador da `mismatched types`.
- Un nick de 17 caracteres lo rechaza el `CHECK` de la tabla y sale como 500. Lo correcto sería comprobarlo antes en Rust y devolver 400. Para contar caracteres hay que usar `chars().count()`: `len()` cuenta bytes, y una `ñ` son 2.

## El front

En `static/script.js` solo cambian las URLs:

```js
const URL_ENVIAR = "/api/mensajes";
const URL_LEER = "/api/mensajes";
```

La misma ruta sirve para leer y para enviar, y lo que cambia es el método. El POST va con `body: new URLSearchParams({ nick: n, mensaje: t })`, y el GET con `URL_LEER + "?ultimo=" + ultimo`.

## Probarlo

```sh
cargo run                                                              # desde chat-rs/
curl 'localhost:8080/api/mensajes?ultimo=0'                            # la lista en JSON
curl -i 'localhost:8080/api/mensajes?ultimo=abc'                       # 400
curl -i -d 'nick=ana&mensaje=hola' localhost:8080/api/mensajes         # 201
curl -i -F nick=ana -F mensaje=hola localhost:8080/api/mensajes        # 415, como FormData
curl -i -d 'nick=ana' localhost:8080/api/mensajes                      # 422, falta mensaje
curl -i localhost:8080/Cargo.toml                                      # 404
```

Y el chat en dos pestañas: lo que se escribe en una aparece en la otra en menos de 2 segundos.

## Conceptos de Rust que salen aquí

- Alcance. Una variable solo existe dentro de las llaves donde se crea, igual que en una función de PHP. Si el pool se crea dentro de una función `connect()`, `main` no lo ve, salvo que la función lo devuelva.
- Mover un valor. Al pasar una variable a una función sin `&`, se le entrega, y después ya no se puede usar. Si se pasa `app` a una función y luego a `serve`, sale `use of moved value`. En PHP los objetos se comparten; en Rust cada valor tiene un solo dueño.
- Tipo frente a valor. `AppState` es el tipo, `state` es el valor y `State` es el extractor de axum. `Since.ultimo` no existe: se escribe `from.ultimo`, el valor que llegó en la petición.
- `Result` y `?`. Un `Result` es una caja que trae el valor o un error. `?` la abre o sale de la función con el error. Funciona solo si el error se puede convertir en el que devuelve la función: por eso hace falta el `map_err` antes del `?` en los handlers.
- Pasar una función frente a llamarla. `get(get_messages)` sin paréntesis.
- Las macros de sqlx miran la base de datos al compilar. Si la tabla no existe todavía, el error sale en `cargo build`, no al ejecutar.

## Errores frecuentes al empezar

| Lo que dice el compilador o el servidor | Qué pasa |
|---|---|
| `rustc 1.93.0 is not supported by ... sqlx@0.9.0 requires rustc 1.94.0` | Hay que actualizar Rust: `brew upgrade rust` o `rustup update`, según cómo se instaló (`which rustc`) |
| `no such table: mensajes` al compilar | La base de datos no existe o no tiene la tabla, o el `.env` no está en la carpeta del proyecto |
| `expected value, found module ...` | Se usa el nombre de un módulo o un tipo donde va una variable |
| `use of moved value` | El valor se entregó a una función en una línea anterior |
| `the trait bound ... Handler<_, _> is not satisfied` | axum no acepta la función como handler. Suele faltar un `#[derive(Deserialize)]` o haber otro error dentro del cuerpo. `#[axum::debug_handler]` encima de la función (feature `macros` de axum) da un mensaje más claro |
| `mismatched types` en el `Ok(...)` | Lo que se devuelve no coincide con lo que promete la firma |
| `no rules expected the token` en `query!` | El SQL lleva comillas dobles y no va en `r#"..."#` |
| `Vec<String>: IntoResponse` no se cumple | `.fetch_all` donde iba `.fetch_one` |
| El programa termina nada más arrancar | Falta `axum::serve(...).await?` |
| 415 en el POST | El front manda `FormData` en vez de `URLSearchParams` |
| 422 en el POST | Los nombres del formulario no coinciden con los campos del struct |

Cuando algo no compila, conviene arreglar solo lo que señala el primer error. Tocar líneas que estaban bien para ver si se arregla suele romper otras cosas.

## Rust frente a PHP

Medido con `ab` y `wrk` en un Mac, con cliente y servidor en la misma máquina. PHP va como en producción: nginx, php-fpm con un proceso por núcleo y OPcache. Las dos versiones usan la misma consulta con `json_group_array`. Peticiones por segundo con 10 y con 50 clientes a la vez:

| Caso | nginx + php-fpm | Rust |
|---|---|---|
| GET de 50 mensajes | 16 726 / 16 320 | 23 784 / 23 426 |
| GET de 50 mensajes, reutilizando la conexión | 25 499 / 26 251 | 36 085 / 31 537 |
| GET sin mensajes nuevos, reutilizando la conexión | 27 119 / 26 179 | 60 951 / 67 270 |
| POST | 1368 / 2266 | 1751 / 3005 |
| Memoria | ~191 MB | 10-13 MB |

- El caso que más se repite es el sondeo sin mensajes nuevos con la conexión reutilizada, que es lo que hace el navegador. Ahí Rust atiende 2,2 y 2,6 veces más, y con 50 clientes su p99 es de 0,95 ms frente a 3,43.
- En el POST manda SQLite, que escribe de una en una. Con 50 clientes Rust saca 1,3 veces más y la mitad de p99 (72 ms frente a 148). Con 10, los resultados varían de una tanda a otra.
- La memoria de php-fpm depende de cuántos procesos se configuren. Aquí son uno por núcleo.
- Con `php -S`, el servidor de desarrollo, PHP rinde bastante menos y no reutiliza conexiones, así que compararse con él da diferencias mayores que no valen como argumento.
- Con un struct y `query_as!`, Rust rendía la mitad que PHP en el GET de 50 mensajes. A PHP, construir el JSON en SQLite casi no le cambió nada; a Rust le multiplicó ese caso por 3,6.

## Qué cambia en openmoody

- Ejercicio 1: en vez de `fallback_service`, una ruta para `/` y otra para `/index.css` con `ServeFile`, y `nest_service("/js", ServeDir::new("js"))`. El front está en la raíz del repo y no en una carpeta aparte.
- Ejercicio 3: la URL de la base de datos sale de `DATABASE_URL`, se crea el fichero si no existe (`create_if_missing`) y se activa WAL, para que las lecturas no esperen a las escrituras.
- Ejercicio 4: un tipo `AppError` que implementa `IntoResponse` y sustituye a los `map_err` repetidos en cada handler.
- Ejercicio 5: `Path` para el token y el id, `Json` para la respuesta y `RETURNING` para devolver el item creado.
- Ejercicio 8: el servidor empuja los cambios con SSE en lugar de que el front pregunte cada 2 segundos.
